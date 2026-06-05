import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/home_screens.dart';
import 'package:frontend/screens/giyotin_screens.dart';
import 'package:frontend/data/services/auth_service.dart';

// ─────────────────────────────────────────────
//  Yasal metinler
// ─────────────────────────────────────────────

const _kTermsTitle = 'Kullanıcı Sözleşmesi';
const _kTermsContent = '''
Son güncelleme: Mayıs 2026

1. TARAFLAR
Bu sözleşme, Kavira Software ("Şirket") ile Kavira SaaS platformuna kayıt olan kişi veya kuruluş ("Kullanıcı") arasında akdedilmiştir.

2. HİZMET KAPSAMI
Kavira SaaS, giyotin cam sistemi hesaplama, maliyet analizi ve kesim planı oluşturma hizmetleri sunar. Platform yalnızca yasal amaçlar için kullanılabilir.

3. HESAP GÜVENLİĞİ
Kullanıcı, hesap bilgilerinin (e-posta, şifre) gizliliğinden tamamen sorumludur. Yetkisiz erişim tespitinde derhal Kavira'yı bilgilendirmek zorunludur.

4. ABONELIK VE ÖDEME
• Abonelik ücretleri Paddle altyapısı aracılığıyla tahsil edilir.
• Deneme süresi bittikten sonra seçilen plan ücreti otomatik tahsil edilir.
• İptal talepleri bir sonraki faturalama döneminden itibaren geçerlidir.
• Abonelik iptalinden sonra mevcut dönem sona erene kadar erişim devam eder.

5. VERİ GİZLİLİĞİ
Kullanıcı verileri KVKK kapsamında işlenir. Veriler üçüncü taraflarla paylaşılmaz; yalnızca ödeme altyapısı (Paddle) için gerekli minimum veri iletilir.

6. FİKRİ MÜLKİYET
Platform, arayüzü, algoritmaları ve yazılımı Kavira Software'e aittir. İzinsiz kopyalama, dağıtım veya tersine mühendislik yasaktır.

7. HİZMET KESİNTİLERİ
Kavira, planlı bakım veya beklenmedik durumlar nedeniyle hizmeti geçici olarak durdurma hakkını saklı tutar.

8. UYUŞMAZLIK ÇÖZÜMÜ
Uyuşmazlıklarda Türk Hukuku uygulanır; yetkili mahkeme İstanbul Mahkemeleridir.

9. İLETİŞİM
kavirasoftware@gmail.com
''';

const _kKvkkTitle = 'KVKK Aydınlatma Metni';
const _kKvkkContent = '''
6698 Sayılı Kişisel Verilerin Korunması Kanunu kapsamında Kavira Software olarak kişisel verilerinizi aşağıda açıklanan amaçlarla işlemekteyiz.

VERİ SORUMLUSU
Kavira Software | kavirasoftware@gmail.com

İŞLENEN KİŞİSEL VERİLER
• Ad, soyad, e-posta adresi
• Şirket/firma adı
• Kullanım verileri, hesaplama geçmişi
• Ödeme işlemi için gerekli fatura bilgileri (Paddle üzerinden)

İŞLEME AMAÇLARI
• Hizmetin sunulması ve sürdürülmesi
• Fatura ve abonelik yönetimi
• Güvenlik ve sahtekârlık önleme
• Yasal yükümlülüklerin yerine getirilmesi
• İyileştirme ve kullanıcı desteği

HUKUKİ DAYANAK
• Sözleşmenin kurulması ve ifası (KVKK m. 5/2-c)
• Meşru menfaat (KVKK m. 5/2-f)
• Açık rıza (gerektiğinde)

VERİLERİN AKTARIMI
Kişisel verileriniz; ödeme altyapısı (Paddle Inc.) ve yasal zorunluluk durumlarında yetkili kamu kurumlarıyla paylaşılabilir. Yurt dışına aktarım yalnızca yeterli koruma güvencesi bulunan ülkelere yapılır.

VERİ SAKLAMA SÜRESİ
Hesap silme talebinden itibaren yasal saklama süreleri (5-10 yıl) dışındaki veriler 30 gün içinde silinir.

HAKLARINIZ (KVKK m. 11)
• Verilerinizin işlenip işlenmediğini öğrenme
• İşlenen verilere erişim talep etme
• Yanlış verilerin düzeltilmesini isteme
• Verilerin silinmesini talep etme
• İşlemeye itiraz etme
• Otomatik sistemler aracılığıyla aleyhte karar oluşmasına itiraz etme

Haklarınızı kullanmak için: kavirasoftware@gmail.com
''';

void _showLegalDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text(content, style: const TextStyle(fontSize: 13, height: 1.7)),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  Shared design tokens / helpers
// ─────────────────────────────────────────────

const _kBrandDark = Color(0xFF0A0F1E);
const _kBrandDarker = Color(0xFF0D1424);
const _kBrandAccent = Color(0xFF3B82F6);
const _kBrandAccentDeep = Color(0xFF1D4ED8);

// ──────────────────────────────────────────────────────────────
//  _BrandPanel  –  Left decorative panel (desktop only)
// ──────────────────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  final String tagline;
  const _BrandPanel({this.tagline = 'Giyotin hesaplamalarını\nakıllı yönetin'});

  @override
  Widget build(BuildContext context) {
    final features = [
      'Anlık maliyet & kesim analizi',
      'Görsel bin-packing optimizasyonu',
      'Geçmiş iş kayıtları ve PDF rapor',
      'Güvenli SaaS altyapısı',
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBrandDark, _kBrandDarker],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative blurred circles
          Positioned(
            top: -80,
            left: -80,
            child: _GlowCircle(color: _kBrandAccent.withOpacity(0.12), size: 340),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _GlowCircle(color: _kBrandAccentDeep.withOpacity(0.10), size: 300),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kBrandAccent, _kBrandAccentDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _kBrandAccent.withOpacity(0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.architecture_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Kavira',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tagline,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 17,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _kBrandAccent.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: _kBrandAccent.withOpacity(0.35)),
                          ),
                          child: const Icon(Icons.check_rounded, color: _kBrandAccent, size: 13),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          f,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  '© 2026 Kavira. Tüm hakları saklıdır.',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _KInput  –  Premium styled text field
// ──────────────────────────────────────────────────────────────

class _KInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final Iterable<String>? autofillHints;

  const _KInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.textInputAction,
    this.onEditingComplete,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      validator: validator,
      autofillHints: autofillHints,
      style: TextStyle(
        color: isDark ? AppColors.text : const Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, color: AppColors.textMuted, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _KButton  –  Full-width gradient primary button
// ──────────────────────────────────────────────────────────────

class _KButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  const _KButton({required this.label, required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading || onTap == null
              ? const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)])
              : AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading || onTap == null
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isLoading ? null : onTap,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  LoginScreen
// ──────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final String? redirectTo;
  const LoginScreen({super.key, this.redirectTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Business logic (unchanged) ────────────────────────────
  void login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final authService = AuthService(dio);
      await authService.login(emailController.text, passwordController.text);

      if (mounted) {
        // Tarayıcıya "bu alanlar başarıyla dolduruldu, kaydetmek ister misin?" sinyali ver
        TextInput.finishAutofillContext();
        showCustomSnackBar(message: "Giriş Başarılı! Yönlendiriliyorsunuz...", isError: false);
        // Giriş sonrası kullanıcı + abonelik bilgisini önden yükle
        refreshUserAndSubscription();
        final prefs = await SharedPreferences.getInstance();
        final isFirstTime = prefs.getBool('is_first_time') ?? true;
        Widget nextScreen;
        if (widget.redirectTo == '/giyotin') {
          nextScreen = const GiyotinScreen();
        } else {
          nextScreen = isFirstTime ? const OnboardingScreen() : const HomeScreen();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } on DioException catch (_) {
      // Interceptor yönetiyor
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => _ForgotPasswordDialog(emailCtrl: emailCtrl),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ForgotPasswordSheet(emailCtrl: emailCtrl),
      );
    }
  }
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Left brand panel – 42%
            Expanded(
              flex: 42,
              child: const _BrandPanel(),
            ),
            // Right form panel – 58%
            Expanded(
              flex: 58,
              child: _LoginFormPanel(
                formKey: _formKey,
                emailController: emailController,
                passwordController: passwordController,
                obscurePassword: _obscurePassword,
                isLoading: isLoading,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onLogin: login,
                onForgotPassword: _showForgotPasswordDialog,
                onGoRegister: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile layout ───────────────────────────────────────
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBrandDark, Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // Logo + brand
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kBrandAccent, _kBrandAccentDeep],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _kBrandAccent.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.architecture_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kavira',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hesabınıza giriş yapın',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Form card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _KInput(
                              controller: emailController,
                              label: 'E-posta',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'E-posta boş bırakılamaz';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                  return 'Geçerli bir e-posta giriniz';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _KInput(
                              controller: passwordController,
                              label: 'Şifre',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: login,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Şifre boş bırakılamaz' : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Şifremi Unuttum',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _KButton(
                              label: 'Giriş Yap',
                              isLoading: isLoading,
                              onTap: login,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hesabınız yok mu?',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.only(left: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Kayıt Olun',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _LegalFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Desktop login form panel (extracted widget) ────────────

class _LoginFormPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoRegister;

  const _LoginFormPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onGoRegister,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.background : Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AutofillGroup(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tekrar hoş geldiniz 👋',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hesabınıza giriş yaparak devam edin.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    _KInput(
                      controller: emailController,
                      label: 'E-posta adresi',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'E-posta boş bırakılamaz';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                          return 'Geçerli bir e-posta giriniz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _KInput(
                      controller: passwordController,
                      label: 'Şifre',
                      icon: Icons.lock_outline_rounded,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onEditingComplete: onLogin,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        onPressed: onTogglePassword,
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Şifre boş bırakılamaz' : null,
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Şifremi Unuttum',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _KButton(
                    label: 'Giriş Yap',
                    isLoading: isLoading,
                    onTap: onLogin,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'veya',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Outline register button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onGoRegister,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Yeni hesap oluştur',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _LegalFooter(),
                ],
              ),   // Column
            ),     // Form
          ),       // AutofillGroup
        ),         // ConstrainedBox
      ),           // SingleChildScrollView
    ),             // Center
  );               // Container
  }
}

// ──────────────────────────────────────────────────────────────
//  Legal footer links
// ──────────────────────────────────────────────────────────────

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 11,
      color: AppColors.textMuted,
    );
    final linkStyle = TextStyle(
      fontSize: 11,
      color: AppColors.primary,
      decoration: TextDecoration.underline,
    );
    return Column(
      children: [
        Text('Platform\'ı kullanarak aşağıdakileri kabul etmiş sayılırsınız:', style: textStyle, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/terms'),
              child: Text('Kullanım Koşulları', style: linkStyle),
            ),
            Text('·', style: textStyle),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/privacy'),
              child: Text('Gizlilik Politikası', style: linkStyle),
            ),
            Text('·', style: textStyle),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/refund'),
              child: Text('İade Politikası', style: linkStyle),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Forgot-password dialogs
// ──────────────────────────────────────────────────────────────

class _ForgotPasswordDialog extends StatelessWidget {
  final TextEditingController emailCtrl;
  const _ForgotPasswordDialog({required this.emailCtrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surface : Colors.white,
      title: const Text(
        'Şifre Sıfırlama',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kayıtlı e-posta adresinizi girin. Şifre sıfırlama bağlantısı gönderilecektir.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            _KInput(
              controller: emailCtrl,
              label: 'E-posta',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () async {
            if (emailCtrl.text.trim().isEmpty) return;
            Navigator.pop(context);
            try {
              await dio.post(
                '/api/v1/auth/forgot-password',
                data: {"email": emailCtrl.text.trim()},
              );
              showCustomSnackBar(
                message: "Sıfırlama bağlantısı e-posta adresinize gönderildi.",
                isError: false,
              );
            } catch (_) {}
          },
          child: const Text(
            'Bağlantı Gönder',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  final TextEditingController emailCtrl;
  const _ForgotPasswordSheet({required this.emailCtrl});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  bool _isLoading = false;

  Future<void> _sendLink() async {
    if (widget.emailCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await dio.post(
        '/api/v1/auth/forgot-password',
        data: {"email": widget.emailCtrl.text.trim()},
      );
      if (mounted) {
        Navigator.pop(context);
        showCustomSnackBar(
          message: "Eğer bu adres kayıtlıysa, sıfırlama bağlantısı gönderildi.",
          isError: false,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Şifre Sıfırlama',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kayıtlı e-posta adresinizi girin.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _KInput(
            controller: widget.emailCtrl,
            label: 'E-posta',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _KButton(
            label: 'Bağlantı Gönder',
            isLoading: _isLoading,
            onTap: _isLoading ? null : _sendLink,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  RegisterScreen
// ──────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  bool _acceptedTerms = false;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // OTP adımı
  bool _codeSent = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    companyController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // Adım 1: Doğrulama kodu gönder
  void _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      showCustomSnackBar(message: "Lütfen Kullanıcı Sözleşmesi ve KVKK metnini onaylayın.", isError: true);
      return;
    }
    setState(() => isLoading = true);
    try {
      await dio.post('/api/v1/auth/send-verification-code', data: {'email': emailController.text.trim()});
      if (mounted) {
        setState(() { _codeSent = true; isLoading = false; });
        showCustomSnackBar(message: "Doğrulama kodu e-posta adresinize gönderildi.", isError: false);
      }
    } on DioException catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Adım 2: Hesap oluştur
  void register() async {
    if (_codeController.text.trim().length != 6) {
      showCustomSnackBar(message: "Lütfen 6 haneli doğrulama kodunu girin.", isError: true);
      return;
    }
    setState(() => isLoading = true);
    try {
      final authService = AuthService(dio);
      final message = await authService.register(
        fullName: nameController.text,
        email: emailController.text,
        companyName: companyController.text,
        password: passwordController.text,
        passwordConfirm: passwordConfirmController.text,
        kvkkAccepted: _acceptedTerms,
        verificationCode: _codeController.text.trim(),
      );
      if (mounted) {
        showCustomSnackBar(message: message, isError: false);
        Navigator.pop(context);
      }
    } on DioException catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  // ─────────────────────────────────────────────────────────

  Widget _buildForm({required bool isDesktop}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _KInput(
                    controller: nameController,
                    label: 'Ad Soyad',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Ad soyad gerekli' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _KInput(
                    controller: companyController,
                    label: 'Şirket Adı',
                    icon: Icons.business_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Şirket adı gerekli' : null,
                  ),
                ),
              ],
            )
          else ...[
            _KInput(
              controller: nameController,
              label: 'Ad Soyad',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ad soyad gerekli' : null,
            ),
            const SizedBox(height: 14),
            _KInput(
              controller: companyController,
              label: 'Şirket Adı',
              icon: Icons.business_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Şirket adı gerekli' : null,
            ),
          ],
          const SizedBox(height: 14),
          _KInput(
            controller: emailController,
            label: 'E-posta',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'E-posta gerekli';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Geçerli bir e-posta giriniz';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _KInput(
            controller: passwordController,
            label: 'Şifre',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre gerekli';
              if (v.length < 8) return 'Şifre en az 8 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _KInput(
            controller: passwordConfirmController,
            label: 'Şifre Tekrar',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onEditingComplete: register,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) =>
                (v != passwordController.text) ? 'Şifreler eşleşmiyor' : null,
          ),
          const SizedBox(height: 16),
          // Terms checkbox
          GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _acceptedTerms,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (v) =>
                        setState(() => _acceptedTerms = v ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    children: [
                      GestureDetector(
                        onTap: () => _showLegalDialog(context, _kTermsTitle, _kTermsContent),
                        child: const Text(
                          "Kullanıcı Sözleşmesi'ni",
                          style: TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline, height: 1.5),
                        ),
                      ),
                      const Text(" ve ", style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
                      GestureDetector(
                        onTap: () => _showLegalDialog(context, _kKvkkTitle, _kKvkkContent),
                        child: const Text(
                          "KVKK Aydınlatma Metni'ni",
                          style: TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline, height: 1.5),
                        ),
                      ),
                      const Text(" okudum, onaylıyorum.", style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (!_codeSent) ...[
            _KButton(label: 'Doğrulama Kodu Gönder', isLoading: isLoading, onTap: _sendCode),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('E-posta Doğrulama', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('${emailController.text} adresine gönderilen 6 haneli kodu girin.', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '------',
                      hintStyle: TextStyle(fontSize: 24, letterSpacing: 8, color: AppColors.textMuted.withOpacity(0.4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: isLoading ? null : _sendCode,
                    child: const Text('Kodu tekrar gönder', style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _KButton(label: 'Hesap Oluştur', isLoading: isLoading, onTap: register),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            Expanded(
              flex: 42,
              child: const _BrandPanel(
                tagline: 'İlk hesabınızı oluşturun\nve ücretsiz deneyin',
              ),
            ),
            Expanded(
              flex: 58,
              child: Container(
                color: isDark ? AppColors.background : Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 64, vertical: 48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hesap Oluşturun',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Birkaç saniyede başlamaya hazır olun.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildForm(isDesktop: true),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Zaten hesabınız var mı?',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.only(left: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Giriş Yapın',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile layout ──────────────────────────────────────
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBrandDark, Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kBrandAccent, _kBrandAccentDeep],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: _kBrandAccent.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.architecture_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Hesap Oluşturun',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: _buildForm(isDesktop: false),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Zaten hesabınız var mı?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.only(left: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Giriş Yapın',
                        style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  ResetPasswordScreen
// ──────────────────────────────────────────────────────────────

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController =
      TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  // ── Business logic (unchanged) ────────────────────────────
  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final authService = AuthService(dio);
      await authService.resetPassword(
        token: widget.token,
        newPassword: passwordController.text,
        passwordConfirm: passwordConfirmController.text,
      );
      if (mounted) {
        showCustomSnackBar(
          message: "Şifreniz başarıyla güncellendi!",
          isError: false,
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on DioException catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Yeni Şifre Belirle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Yeni Şifre Belirle',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yeni şifrenizi aşağıya girin.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.06),
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _KInput(
                          controller: passwordController,
                          label: 'Yeni Şifre',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Şifre gerekli';
                            if (v.length < 8)
                              return 'Şifre en az 8 karakter olmalı';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _KInput(
                          controller: passwordConfirmController,
                          label: 'Şifre Tekrar',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _resetPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) => (v != passwordController.text)
                              ? 'Şifreler eşleşmiyor'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        _KButton(
                          label: 'Şifreyi Güncelle',
                          isLoading: isLoading,
                          onTap: _resetPassword,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
