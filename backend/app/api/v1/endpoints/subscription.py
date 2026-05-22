from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.models.subscription import Subscription
from app.api.v1.endpoints.giyotin import get_current_active_user
from datetime import datetime, timedelta
from app.api.v1.endpoints.auth import mail_conf
from fastapi_mail import FastMail, MessageSchema, MessageType
import iyzipay
from app.core.config import settings

router = APIRouter()

options = {
    "api_key": settings.IYZICO_API_KEY,
    "secret_key": settings.IYZICO_SECRET_KEY,
    "base_url": settings.IYZICO_BASE_URL
}

PLAN_REFERENCE_CODE = "b1234abcd-iyzico-plan-kodu" # Iyzico panelinden alacağınız aylık plan kodu

# Güvenlik için Webhook Secret (İdeal olarak app/core/config.py içinden .env ile alınmalıdır)
WEBHOOK_SECRET = settings.IYZICO_WEBHOOK_SECRET

@router.get("/status")
def get_subscription_status(current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    """Frontend'de abonelik durumunu ve bitiş tarihini göstermek için kullanılır."""
    sub = db.query(Subscription).filter(Subscription.company_id == current_user.company_id).first()
    if not sub:
        return {"is_active": False, "plan_name": "Yok", "end_date": None}
    return {
        "is_active": sub.is_active,
        "plan_name": sub.plan_name,
        "end_date": sub.end_date.isoformat() if sub.end_date else None
    }

@router.post("/checkout-form")
def create_checkout_form(current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    """
    Frontend'in çağıracağı ve iyzico ödeme sayfasının linkini döndüren fonksiyon.
    """
    # Iyzico Abonelik Checkout Formu İsteği
    request = {
        'locale': 'tr',
        'conversationId': f"COMP_{current_user.company_id}",
        'pricingPlanReferenceCode': PLAN_REFERENCE_CODE,
        'subscriptionInitialStatus': 'ACTIVE',
        'customer': {
            'name': current_user.full_name.split()[0],
            'surname': current_user.full_name.split()[-1] if len(current_user.full_name.split()) > 1 else 'Yok',
            'email': current_user.email,
            # Dijital hizmet olduğu için Iyzico'ya varsayılan değerler gönderiliyor.
            'identityNumber': '11111111111', # Iyzico formatı için 11 haneli varsayılan değer
            'shippingAddress': {
                'contactName': current_user.full_name,
                'city': 'Istanbul',
                'country': 'Turkey',
                'address': 'Dijital Hizmet Alimi',
            },
            'billingAddress': {
                'contactName': current_user.full_name,
                'city': 'Istanbul',
                'country': 'Turkey',
                'address': 'Dijital Hizmet Alimi',
            }
        }
    }

    checkout_form_initialize = iyzipay.SubscriptionCheckoutFormInitialize().create(request, options)
    
    if checkout_form_initialize.read().get('status') == 'success':
        # Frontend'e iyzico'nun ödeme sayfasını (token) gönder
        return {"checkout_url": checkout_form_initialize.read().get('checkoutFormContent')}
    else:
        raise HTTPException(status_code=400, detail=checkout_form_initialize.read().get('errorMessage'))

@router.post("/webhook")
async def iyzico_webhook(request: Request, token: str, db: Session = Depends(get_db)):
    """
    Iyzico her ay karttan parayı çektiğinde buraya gizli bir POST atar.
    """
    # 1. GÜVENLİK KONTROLÜ: Gelen token bizim belirlediğimiz şifre ile uyuşmuyor ise reddet
    if token != WEBHOOK_SECRET:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim. Geçersiz webhook token.")

    payload = await request.json()
    
    order_reference_code = payload.get('referenceCode')
    status = payload.get('subscriptionStatus')
    company_id = int(payload.get('conversationId').replace("COMP_", "")) # İstek atarken gönderdiğimiz ID

    sub = db.query(Subscription).filter(Subscription.company_id == company_id).first()
    if sub:
        if status == 'ACTIVE':
            sub.is_active = True
            
            # TODO: Iyzico'daki aboneliği sonradan iptal edebilmek için bu referans kodunu veritabanına kaydetmelisiniz:
            # sub.iyzico_reference_code = order_reference_code
            
            # Mevcut bitiş tarihi gelecekteyse onun üzerine ekle, geçmişse bugünden itibaren ekle
            now = datetime.utcnow()
            if sub.end_date and sub.end_date > now:
                sub.end_date = sub.end_date + timedelta(days=30)
            else:
                sub.end_date = now + timedelta(days=30)
            
            # Yöneticilere başarılı yenileme e-postası at
            admins = db.query(User).filter(
                User.company_id == company_id,
                User.is_company_admin == True
            ).all()
            
            if admins:
                fm = FastMail(mail_conf)
                for admin in admins:
                    message = MessageSchema(
                        subject="Kavira SaaS - Aboneliğiniz Başarıyla Yenilendi",
                        recipients=[admin.email],
                        body=f"Merhaba {admin.full_name},<br><br>Kavira SaaS (<b>{sub.plan_name}</b>) planı için ödemeniz başarıyla alınmış ve aboneliğiniz yenilenmiştir.<br><br>Yeni Bitiş Tarihi: <b>{sub.end_date.strftime('%d.%m.%Y')}</b><br><br>Bizi tercih ettiğiniz için teşekkür ederiz.",
                        subtype=MessageType.html
                    )
                    await fm.send_message(message)
        else:
            sub.is_active = False # Ödeme alınamadı vs.
        db.commit()
    return {"status": "ok"}

@router.post("/cancel")
def cancel_subscription(current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    """Kullanıcının mevcut aboneliğini iptal etmesini sağlar."""
    sub = db.query(Subscription).filter(Subscription.company_id == current_user.company_id).first()
    
    if not sub or not sub.is_active:
        raise HTTPException(status_code=400, detail="İptal edilecek aktif bir abonelik bulunamadı.")

    # --- Iyzico İptal İsteği (Veritabanında referans kodu tutulduğunu varsayarak) ---
    # request_data = {
    #     'locale': 'tr',
    #     'subscriptionReferenceCode': sub.iyzico_reference_code 
    # }
    # cancel_result = iyzipay.SubscriptionCancel().cancel(request_data, options)
    # if cancel_result.read().get('status') != 'success':
    #     raise HTTPException(status_code=400, detail="Ödeme altyapısı iptal hatası: " + cancel_result.read().get('errorMessage'))

    # Yerel veritabanında aboneliği hemen pasife çekiyoruz (İşlem anında erişimi kesilir)
    sub.is_active = False
    db.commit()
    
    return {"message": "Aboneliğiniz başarıyla iptal edildi."}