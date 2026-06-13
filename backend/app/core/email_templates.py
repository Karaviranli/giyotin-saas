"""
Kavira SaaS - HTML E-posta Şablonları
"""

_BASE = """<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{subject}</title>
</head>
<body style="margin:0;padding:0;background-color:#F1F5F9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;">

        <!-- HEADER -->
        <tr>
          <td align="center" style="background:linear-gradient(135deg,#1E293B 0%,#0F172A 100%);padding:36px 40px 28px;border-radius:16px 16px 0 0;">
            <div style="display:inline-flex;align-items:center;gap:10px;">
              <div style="width:36px;height:36px;background:#3B82F6;border-radius:10px;display:inline-block;vertical-align:middle;"></div>
              <span style="font-size:22px;font-weight:800;color:#F8FAFC;letter-spacing:-0.5px;vertical-align:middle;">Kavira</span>
              <span style="font-size:12px;color:#64748B;vertical-align:middle;margin-left:4px;">Giyotin SaaS</span>
            </div>
          </td>
        </tr>

        <!-- BODY -->
        <tr>
          <td style="background:#FFFFFF;padding:40px 48px;border-radius:0 0 16px 16px;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
            {body}
          </td>
        </tr>

        <!-- FOOTER -->
        <tr>
          <td align="center" style="padding:28px 0 8px;">
            <p style="margin:0 0 8px;font-size:12px;color:#94A3B8;">Bu e-posta Kavira SaaS platformu tarafından otomatik olarak gönderilmiştir.</p>
            <p style="margin:0;font-size:12px;color:#94A3B8;">
              <a href="https://kaviragiyotin.online/terms" style="color:#3B82F6;text-decoration:none;">Kullanım Koşulları</a>
              &nbsp;·&nbsp;
              <a href="https://kaviragiyotin.online/privacy" style="color:#3B82F6;text-decoration:none;">Gizlilik</a>
              &nbsp;·&nbsp;
              <a href="https://kaviragiyotin.online/refund" style="color:#3B82F6;text-decoration:none;">İade Politikası</a>
            </p>
            <p style="margin:12px 0 0;font-size:11px;color:#CBD5E1;">© 2025 Kavira Software · kavirasoftware@gmail.com</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>"""

_BUTTON = """<a href="{url}" style="display:inline-block;background:linear-gradient(135deg,#3B82F6,#1D4ED8);color:#FFFFFF;text-decoration:none;font-size:15px;font-weight:700;padding:14px 32px;border-radius:10px;margin:8px 0;">{label}</a>"""

_DIVIDER = """<hr style="border:none;border-top:1px solid #E2E8F0;margin:28px 0;">"""

_GREETING = """<p style="margin:0 0 8px;font-size:24px;font-weight:800;color:#0F172A;letter-spacing:-0.5px;">{title}</p>
<p style="margin:0 0 28px;font-size:15px;color:#64748B;line-height:1.6;">{subtitle}</p>"""

_PARAGRAPH = """<p style="margin:0 0 16px;font-size:15px;color:#334155;line-height:1.7;">{text}</p>"""

_INFO_BOX = """<div style="background:#F8FAFC;border:1px solid #E2E8F0;border-left:4px solid #3B82F6;border-radius:8px;padding:16px 20px;margin:20px 0;">
  <p style="margin:0;font-size:14px;color:#334155;line-height:1.6;">{text}</p>
</div>"""

_WARNING_BOX = """<div style="background:#FEF3C7;border:1px solid #FDE68A;border-left:4px solid #F59E0B;border-radius:8px;padding:16px 20px;margin:20px 0;">
  <p style="margin:0;font-size:14px;color:#92400E;line-height:1.6;">{text}</p>
</div>"""

_DANGER_BOX = """<div style="background:#FEF2F2;border:1px solid #FECACA;border-left:4px solid #EF4444;border-radius:8px;padding:16px 20px;margin:20px 0;">
  <p style="margin:0;font-size:14px;color:#991B1B;line-height:1.6;">{text}</p>
</div>"""


def _render(subject: str, body: str) -> str:
    return _BASE.format(subject=subject, body=body)


def welcome_email(full_name: str, trial_days: int = 7) -> str:
    body = (
        _GREETING.format(
            title=f"Hoş geldiniz, {full_name.split()[0]}! 🎉",
            subtitle="Kavira Giyotin SaaS hesabınız başarıyla oluşturuldu."
        )
        + _PARAGRAPH.format(text="Artık giyotin cam sistemi hesaplamaları, kesim planları ve maliyet analizleri yapabilirsiniz. Aşağıdaki butona tıklayarak hemen başlayın.")
        + _INFO_BOX.format(text=f"<strong>🎁 {trial_days} Günlük Ücretsiz Deneme</strong><br>Tüm özellikler {trial_days} gün boyunca ücretsiz kullanımınıza açık. Deneme süreniz dolmadan abonelik planı seçerek kesintisiz erişim sağlayabilirsiniz.")
        + "<div style='text-align:center;margin:28px 0;'>"
        + _BUTTON.format(url="https://kaviragiyotin.online", label="Platforma Git →")
        + "</div>"
        + _DIVIDER
        + _PARAGRAPH.format(text="Sorularınız için <a href='mailto:kavirasoftware@gmail.com' style='color:#3B82F6;'>kavirasoftware@gmail.com</a> adresinden bize ulaşabilirsiniz.")
    )
    return _render("Kavira SaaS'a Hoş Geldiniz!", body)


def reset_password_email(full_name: str, reset_link: str) -> str:
    body = (
        _GREETING.format(
            title="Şifre Sıfırlama Talebi",
            subtitle=f"Merhaba {full_name.split()[0]}, şifrenizi sıfırlamak için talepte bulundunuz."
        )
        + _PARAGRAPH.format(text="Aşağıdaki butona tıklayarak yeni şifrenizi belirleyebilirsiniz.")
        + "<div style='text-align:center;margin:28px 0;'>"
        + _BUTTON.format(url=reset_link, label="Şifremi Sıfırla")
        + "</div>"
        + _WARNING_BOX.format(text="⏱ Bu bağlantı <strong>15 dakika</strong> içinde geçerliliğini yitirecektir. Eğer bu talebi siz yapmadıysanız bu e-postayı görmezden gelebilirsiniz.")
        + _DIVIDER
        + _PARAGRAPH.format(text="Güvenliğiniz için şifrenizi kimseyle paylaşmayın.")
    )
    return _render("Şifre Sıfırlama Talebi - Kavira SaaS", body)


def account_deleted_email(full_name: str) -> str:
    body = (
        _GREETING.format(
            title="Hesabınız Silindi",
            subtitle=f"Merhaba {full_name.split()[0]}, hesabınız başarıyla kapatıldı."
        )
        + _PARAGRAPH.format(text="Kavira SaaS'ı kullandığınız için teşekkür ederiz. Hesabınıza ait tüm veriler sistemimizden kaldırılmıştır.")
        + _DANGER_BOX.format(text="Bu işlem geri alınamaz. Hesabınıza ait kayıtlar, kesim planları ve abonelik bilgileri kalıcı olarak silinmiştir.")
        + _PARAGRAPH.format(text="Gelecekte tekrar kullanmak isterseniz <a href='https://kaviragiyotin.online' style='color:#3B82F6;'>kaviragiyotin.online</a> adresinden yeni bir hesap açabilirsiniz.")
        + _DIVIDER
        + _PARAGRAPH.format(text="Her türlü soru için: <a href='mailto:kavirasoftware@gmail.com' style='color:#3B82F6;'>kavirasoftware@gmail.com</a>")
    )
    return _render("Hesabınız Kapatıldı - Kavira SaaS", body)


def verification_code_email(code: str, expire_minutes: int = 10) -> str:
    body = (
        _GREETING.format(
            title="E-posta Doğrulama Kodu",
            subtitle="Kavira SaaS hesabınızı oluşturmak için aşağıdaki kodu kullanın."
        )
        + "<div style='text-align:center;margin:32px 0;'>"
        + f"<div style='display:inline-block;background:#F8FAFC;border:2px solid #3B82F6;border-radius:16px;padding:20px 48px;'>"
        + f"<p style='margin:0;font-size:42px;font-weight:900;color:#0F172A;letter-spacing:12px;font-family:monospace;'>{code}</p>"
        + "</div></div>"
        + _WARNING_BOX.format(text=f"⏱ Bu kod <strong>{expire_minutes} dakika</strong> içinde geçerliliğini yitirecektir. Bu kodu kimseyle paylaşmayın.")
        + _PARAGRAPH.format(text="Eğer bu talebi siz yapmadıysanız bu e-postayı görmezden gelebilirsiniz.")
    )
    return _render("E-posta Doğrulama Kodu - Kavira SaaS", body)


def subscription_activated_email(full_name: str, end_date: str) -> str:
    body = (
        _GREETING.format(
            title="Aboneliğiniz Aktif! ✅",
            subtitle=f"Merhaba {full_name.split()[0]}, ödemeniz başarıyla alındı."
        )
        + _INFO_BOX.format(text=f"<strong>Aylık Plan</strong> aktif edildi.<br>Bir sonraki yenileme tarihiniz: <strong>{end_date}</strong>")
        + "<div style='text-align:center;margin:28px 0;'>"
        + _BUTTON.format(url="https://kaviragiyotin.online", label="Platforma Git →")
        + "</div>"
        + _DIVIDER
        + _PARAGRAPH.format(text="Aboneliğinizi dilediğiniz zaman platform üzerinden yönetebilirsiniz.")
    )
    return _render("Aboneliğiniz Aktif - Kavira SaaS", body)


def subscription_cancelled_email(full_name: str, access_until: str) -> str:
    body = (
        _GREETING.format(
            title="Aboneliğiniz İptal Edildi",
            subtitle=f"Merhaba {full_name.split()[0]}, aboneliğiniz iptal edildi."
        )
        + _WARNING_BOX.format(text=f"Platform erişiminiz <strong>{access_until}</strong> tarihine kadar devam edecektir. Bu tarihten sonra hesaplama yapabilmek için yeni bir abonelik satın almanız gerekecektir.")
        + "<div style='text-align:center;margin:28px 0;'>"
        + _BUTTON.format(url="https://kaviragiyotin.online", label="Aboneliği Yenile →")
        + "</div>"
        + _DIVIDER
        + _PARAGRAPH.format(text="Bizi tercih ettiğiniz için teşekkür ederiz. Sorularınız için <a href='mailto:kavirasoftware@gmail.com' style='color:#3B82F6;'>kavirasoftware@gmail.com</a> adresine yazabilirsiniz.")
    )
    return _render("Aboneliğiniz İptal Edildi - Kavira SaaS", body)


def payment_failed_email(full_name: str) -> str:
    body = (
        _GREETING.format(
            title="Ödeme Başarısız",
            subtitle=f"Merhaba {full_name.split()[0]}, ödemeniz işlenemedi."
        )
        + _DANGER_BOX.format(text="Abonelik yenileme ödemesi alınamadı. Hesabınıza erişim geçici olarak askıya alınmıştır.")
        + _PARAGRAPH.format(text="Lütfen ödeme bilgilerinizi güncelleyerek tekrar deneyin. Sorun devam ederse bizimle iletişime geçin.")
        + "<div style='text-align:center;margin:28px 0;'>"
        + _BUTTON.format(url="https://kaviragiyotin.online", label="Ödeme Bilgilerini Güncelle →")
        + "</div>"
        + _DIVIDER
        + _PARAGRAPH.format(text="Yardım için: <a href='mailto:kavirasoftware@gmail.com' style='color:#3B82F6;'>kavirasoftware@gmail.com</a>")
    )
    return _render("Ödeme Başarısız - Kavira SaaS", body)
