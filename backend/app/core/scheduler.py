from apscheduler.schedulers.asyncio import AsyncIOScheduler
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.db.database import engine
from app.models.subscription import Subscription
from app.models.user import User

# E-posta gönderimi için auth.py'da tanımladığımız ayarları kullanıyoruz
from app.api.v1.endpoints.auth import mail_conf
from fastapi_mail import FastMail, MessageSchema, MessageType

scheduler = AsyncIOScheduler()

async def check_expiring_subscriptions():
    """Bitişine 3 gün kalmış abonelikleri bulup adminlere uyarı maili atar."""
    db = Session(bind=engine)
    try:
        now = datetime.utcnow()
        # Bugünden tam 3 gün sonrası ile 4 gün sonrası arasındaki pencere
        target_start = now + timedelta(days=3)
        target_end = now + timedelta(days=4)

        expiring_subs = db.query(Subscription).filter(
            Subscription.is_active == True,
            Subscription.end_date >= target_start,
            Subscription.end_date < target_end
        ).all()

        if not expiring_subs:
            return

        fm = FastMail(mail_conf)

        for sub in expiring_subs:
            # Bu aboneliğe sahip şirketin admin yetkili kullanıcılarını bul
            admins = db.query(User).filter(
                User.company_id == sub.company_id,
                User.is_company_admin == True
            ).all()

            for admin in admins:
                try:
                    message = MessageSchema(
                        subject="Kavira SaaS - Aboneliğiniz Yakında Sona Eriyor",
                        recipients=[admin.email],
                        body=f"Merhaba {admin.full_name},<br><br>"
                             f"Kavira SaaS (<b>{sub.plan_name}</b>) aboneliğinizin süresi <b>3 gün sonra</b> dolacaktır.<br><br>"
                             f"Hesaplamalarınıza kesintisiz devam edebilmek için lütfen sistem üzerinden aboneliğinizi yenileyiniz.",
                        subtype=MessageType.html
                    )
                    await fm.send_message(message)
                except Exception as e:
                    print(f"[{datetime.utcnow()}] E-Posta gonderim hatasi (Uyari) - {admin.email}: {e}")
    finally:
        db.close()

async def deactivate_expired_subscriptions():
    """Süresi tamamen dolmuş abonelikleri tespit edip otomatik olarak pasif duruma çeker."""
    db = Session(bind=engine)
    try:
        now = datetime.utcnow()
        
        # Bitiş tarihi şu andan geçmiş ve hala veritabanında aktif görünenleri bul
        expired_subs = db.query(Subscription).filter(
            Subscription.is_active == True,
            Subscription.end_date < now
        ).all()

        if expired_subs:
            fm = FastMail(mail_conf)
            for sub in expired_subs:
                sub.is_active = False
            
                # Bu aboneliğe sahip şirketin admin yetkili kullanıcılarını bul
                admins = db.query(User).filter(
                    User.company_id == sub.company_id,
                    User.is_company_admin == True
                ).all()

                for admin in admins:
                    try:
                        message = MessageSchema(
                            subject="Kavira SaaS - Aboneliğiniz Sona Erdi",
                            recipients=[admin.email],
                            body=f"Merhaba {admin.full_name},<br><br>"
                                 f"Kavira SaaS (<b>{sub.plan_name}</b>) aboneliğinizin süresi dolmuş ve hesabınız pasif duruma geçmiştir.<br><br>"
                                 f"Hesaplamalarınıza devam edebilmek için lütfen panele giriş yaparak aboneliğinizi yenileyiniz.",
                            subtype=MessageType.html
                        )
                        await fm.send_message(message)
                    except Exception as e:
                        print(f"[{datetime.utcnow()}] E-Posta gonderim hatasi (Iptal) - {admin.email}: {e}")

            db.commit()
    finally:
        db.close()

def start_scheduler():
    # GEÇİCİ OLARAK ABONELİK E-POSTALARI VE KONTROLLERİ DEVRE DIŞI BIRAKILDI (Kullanıcı toplama aşaması)
    # scheduler.add_job(check_expiring_subscriptions, 'cron', hour=9, minute=0)
    # scheduler.add_job(deactivate_expired_subscriptions, 'cron', hour=0, minute=1)
    # scheduler.start()
    pass