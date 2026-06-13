import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/auth_screens.dart';
import 'package:frontend/screens/giyotin_screens.dart';
import 'package:frontend/data/services/settings_service.dart';
import 'package:frontend/data/services/subscription_service.dart';
import 'package:frontend/data/services/giyotin_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Kavira'ya Hoş Geldiniz! 👋",
      "desc": "Giyotin cam sistemleri için özel tasarlanmış olan Kavira ile saniyeler içinde hatasız maliyet ve kesim hesabı yapın.",
      "icon": Icons.architecture_rounded,
      "color": AppColors.primary,
    },
    {
      "title": "Kârınızı Güvenceye Alın 💰",
      "desc": "Ayarlar menüsünden güncel alüminyum, cam ve motor fiyatlarınızı belirleyin. Her projede net kârlılığınızı otomatik görün.",
      "icon": Icons.query_stats_rounded,
      "color": AppColors.success,
    },
    {
      "title": "Görsel Kesim Simülasyonu ✂️",
      "desc": "Ustanız için hazırlanmış renkli barlarla kesim planı. Hangi profilden kaç parça çıkacağını görün, fire oranını anında minimize edin.",
      "icon": Icons.content_cut_rounded,
      "color": AppColors.warning,
    },
    {
      "title": "Toplu Birleştirme & Tasarruf 🔄",
      "desc": "Geçmiş işlerinizi tek bir havuza aktarın. Bin-packing optimizasyonu sayesinde tüm parçaları birleştirip profilden ciddi tasarruf sağlayın!",
      "icon": Icons.merge_type_rounded,
      "color": AppColors.info,
    },
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false); // Kullanıcı eğitimi tamamladı
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        key: ValueKey(index),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: page['color'].withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: page['color'].withOpacity(0.2),
                                    blurRadius: 40 * value,
                                    spreadRadius: 10 * value,
                                  )
                                ]
                              ),
                              child: Icon(page['icon'], size: 100, color: page['color']),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 64),
                      AnimatedOpacity(
                        opacity: _currentPage == index ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          page['title'],
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _currentPage == index ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          page['desc'],
                          style: const TextStyle(fontSize: 16, color: AppColors.textMuted, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == _pages.length - 1 ? "Uygulamaya Başla" : "Sonraki",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sağ üstte atla butonu
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text("Atla", style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Beta süresi bitince gösterilen iletişim ekranı.
// Şu an ödeme almıyoruz — kullanıcıya WhatsApp/mail ile ulaşması için CTA, ve elinde
// promo kod varsa yapıştırabileceği kutu.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isLoadingStatus = true;
  Map<String, dynamic>? subData;

  static const String _supportPhone = "905015517407"; // WhatsApp numarası (90 ile başla, + işareti yok)
  static const String _supportMail  = "kavirasoftware@gmail.com";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final res = await dio.get('/api/v1/subscription/status');
      if (mounted) setState(() { subData = res.data as Map<String, dynamic>?; isLoadingStatus = false; });
    } catch (_) {
      if (mounted) setState(() => isLoadingStatus = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final email = (userNotifier.value?["email"] ?? "").toString();
    final msg = Uri.encodeComponent(
      "Merhaba 👋\nKavira Giyotin deneme sürem doldu, kullanmaya devam etmek istiyorum.\nKayıtlı mailim: $email"
    );
    final uri = Uri.parse("https://wa.me/$_supportPhone?text=$msg");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showCustomSnackBar(message: "WhatsApp açılamadı.", isError: true);
    }
  }

  Future<void> _openMail() async {
    final email = (userNotifier.value?["email"] ?? "").toString();
    final uri = Uri(
      scheme: 'mailto',
      path: _supportMail,
      query: 'subject=${Uri.encodeComponent("Kavira Giyotin — Süre Uzatma Talebi")}'
        '&body=${Uri.encodeComponent("Merhaba, deneme sürem doldu, kullanmaya devam etmek istiyorum.\n\nKayıtlı mail: $email")}',
    );
    if (!await launchUrl(uri)) {
      showCustomSnackBar(message: "E-posta uygulaması açılamadı.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isActive = subData?["is_active"] == true;
    final endDateIso = subData?["end_date"]?.toString();
    String endFmt = "";
    if (endDateIso != null && endDateIso.isNotEmpty) {
      try {
        final d = DateTime.parse(endDateIso);
        endFmt = "${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}";
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Beta Deneme Durumu")),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Hero kart ─────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: isActive ? AppColors.gradientSuccess : AppColors.gradientWarning,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.cardShadowDeep,
                  ),
                  child: Column(children: [
                    Icon(
                      isActive ? Icons.workspace_premium_rounded : Icons.hourglass_disabled_rounded,
                      size: 64, color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isActive ? "Beta Erişimin Aktif" : "Beta Deneme Süresi Doldu",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (endFmt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        isActive ? "Bitiş tarihi: $endFmt" : "Sona erdi: $endFmt",
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 24),

                if (isLoadingStatus)
                  const CircularProgressIndicator()
                else if (!isActive) ...[
                  // ── Süresi dolan kullanıcı — promo iletişim akışı ──
                  const Text(
                    "Kavira Giyotin'i kullanmaya devam etmek ister misiniz?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Şu an erken erişim sürecindeyiz, ödeme almıyoruz. Devam etmek isteyen kullanıcılarımıza özel promosyon kodu ile süre uzatması veriyoruz.\n\nWhatsApp veya mail ile bize ulaşın — birkaç saat içinde kodunuzu gönderelim.",
                    style: TextStyle(fontSize: 14, color: AppColors.text.withOpacity(0.78), height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openWhatsApp,
                      icon: const Icon(Icons.chat_rounded, color: Colors.white),
                      label: const Text("WhatsApp ile Ulaş", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openMail,
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: const Text("E-posta Gönder"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: BorderSide(color: AppColors.text.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PromoCodeBox(),
                ] else ...[
                  // ── Aktif beta kullanıcı için bilgi ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Hoş geldin 👋", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
                      const SizedBox(height: 8),
                      Text(
                        "Şu an erken erişim sürecindeyiz, sistem tamamen ücretsiz. Geri bildirimlerin bizim için altın değerinde — destek hattından ulaşabilirsin.",
                        style: TextStyle(fontSize: 13, color: AppColors.text.withOpacity(0.7), height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text("Destek / Öneri Hattı"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text,
                          side: BorderSide(color: AppColors.text.withOpacity(0.3)),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const _PromoCodeBox(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Promo kod giriş kutusu — admin/destek kullanıcıya kod gönderdiğinde
/// kullanıcı buraya yapıştırır → süresi uzar.
/// Promo kod giriş dialogu — sidebar tile'ı veya dashboard banner'ından çağrılır.
/// Beta sürecinde KAVIRA-HOSGELDIN gibi kodlarla bir yıl ücretsiz erişim alınır.
Future<void> showPromoCodeDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadowDeep,
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.confirmation_number_outlined,
                      color: AppColors.warning, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text("Promosyon Kodu",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                "Destekten aldığın kodu buraya gir — abonelik süren otomatik uzatılır.",
                style: TextStyle(fontSize: 13, color: AppColors.text.withOpacity(0.65), height: 1.45),
              ),
              const SizedBox(height: 18),
              const _PromoCodeBox(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PromoCodeBox extends StatefulWidget {
  const _PromoCodeBox();
  @override
  State<_PromoCodeBox> createState() => _PromoCodeBoxState();
}

class _PromoCodeBoxState extends State<_PromoCodeBox> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  Future<void> _redeem() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await dio.post('/api/v1/subscription/redeem', data: {'code': code});
      if (!mounted) return;
      final msg = (res.data is Map ? res.data["message"] : null)?.toString() ?? "Kod uygulandı 🎉";
      showCustomSnackBar(message: msg, isError: false);
      _ctrl.clear();
      await refreshUserAndSubscription();
    } catch (_) {
      // interceptor zaten gösteriyor
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.confirmation_number_outlined, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Text("Promosyon Kodu", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
        ]),
        const SizedBox(height: 6),
        Text("Destekten aldığın kodu buraya yapıştır.", style: TextStyle(fontSize: 12, color: AppColors.text.withOpacity(0.6))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "PROMO-XXXX-XXXX",
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _loading ? null : _redeem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Uygula", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = true;
  bool isSaving = false;
  bool isSavingProfile = false;
  bool isSavingPassword = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final Map<String, TextEditingController> _priceControllers = {};
  // Gruplu v2 ayarlar: grup adı → [{key, label, unit, controller}]
  List<Map<String, dynamic>> _settingGroups = [];
  final Map<String, TextEditingController> _v2Controllers = {};
  bool _useV2 = false;
  String companyName = "Şirket Ayarları";
  late final SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService(dio);
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final profileData = await _settingsService.getUserProfile();
      setState(() {
        _nameController.text = profileData['full_name'] ?? '';
        _emailController.text = profileData['email'] ?? '';
      });

      // Önce v2 gruplu ayarları dene
      try {
        final v2 = await dio.get('/api/v1/giyotin/settings/v2');
        final gruplar = (v2.data['gruplar'] as List?) ?? [];
        companyName = v2.data['company_name'] ?? "Şirket Ayarları";
        final List<Map<String, dynamic>> groups = [];
        for (final g in gruplar) {
          final gm = g as Map<String, dynamic>;
          final alanlar = (gm['alanlar'] as List?) ?? [];
          final fields = <Map<String, dynamic>>[];
          for (final a in alanlar) {
            final am = a as Map<String, dynamic>;
            final key = am['key'].toString();
            _v2Controllers[key] = TextEditingController(
              text: (am['value'] as num).toString(),
            );
            fields.add({
              "key": key, "label": am['label'], "unit": am['unit'],
            });
          }
          groups.add({"isim": gm['isim'], "alanlar": fields});
        }
        _settingGroups = groups;
        _useV2 = true;
      } catch (_) {
        // v2 yoksa eski endpoint'e düş
        final settingsData = await _settingsService.getSettings();
        companyName = settingsData['company_name'] ?? "Şirket Ayarları";
        final fiyatlar = settingsData['fiyatlar'] as Map<String, dynamic>;
        fiyatlar.forEach((key, value) {
          _priceControllers[key] = TextEditingController(text: value.toString());
        });
        _useV2 = false;
      }
    } catch (e) {
      showCustomSnackBar(message: "Ayarlar yüklenemedi: $e", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      showCustomSnackBar(message: "Ad soyad ve e-posta boş bırakılamaz!", isError: true);
      return;
    }
    setState(() => isSavingProfile = true);
    try {
      await _settingsService.updateUserProfile(_nameController.text, _emailController.text);
      if (mounted) showCustomSnackBar(message: "Profil başarıyla güncellendi!", isError: false);
    } catch (e) {
      // Hata interceptor tarafından yönetiliyor
    } finally {
      if (mounted) setState(() => isSavingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      showCustomSnackBar(message: "Tüm şifre alanlarını doldurun!", isError: true);
      return;
    }
    setState(() => isSavingPassword = true);
    try {
      await _settingsService.updatePassword(_currentPasswordController.text, _newPasswordController.text, _confirmPasswordController.text);
      if (mounted) {
        showCustomSnackBar(message: "Şifreniz başarıyla güncellendi!", isError: false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      // Hata interceptor tarafından yönetiliyor
    } finally {
      if (mounted) setState(() => isSavingPassword = false);
    }
  }

  Widget _v2Field(Map<String, dynamic> alan) {
    final key = alan['key'].toString();
    final label = alan['label'].toString();
    final unit = alan['unit'].toString();
    final ctrl = _v2Controllers[key];
    final isPercent = unit == '%';
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        isDense: true,
        prefixIcon: isPercent
          ? Icon(Icons.percent_rounded, size: 16, color: AppColors.success)
          : null,
        suffixStyle: TextStyle(
          color: isPercent ? AppColors.success : AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);
    try {
      if (_useV2) {
        final Map<String, dynamic> updated = {};
        _v2Controllers.forEach((key, ctrl) {
          updated[key] = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0;
        });
        await dio.post('/api/v1/giyotin/settings/v2', data: updated);
      } else {
        final Map<String, double> updated = {};
        _priceControllers.forEach((key, ctrl) {
          updated[key] = double.tryParse(ctrl.text) ?? 0.0;
        });
        await _settingsService.saveSettings(updated);
      }
      if (mounted) {
        showCustomSnackBar(message: "Fiyatlar başarıyla güncellendi! ✓", isError: false);
      }
    } catch (e) {
      // interceptor gösteriyor
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hesabı Kalıcı Olarak Sil"),
        content: const Text("Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hesabımı Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Backend'e "DELETE /api/v1/auth/me" isteği atılacak servis eklenecek
      // Şimdilik sadece frontend'den çıkış yaptırıp yönlendiriyoruz
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      if (mounted) {
        showCustomSnackBar(message: "Hesabınız başarıyla silindi.", isError: false);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  void dispose() {
    for (var ctrl in _priceControllers.values) {
      ctrl.dispose();
    }
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileR;
    return AppShell(
      activeRoute: "settings",
      title: "Ayarlar",
      actions: [
        if (isSaving || isSavingProfile || isSavingPassword)
          const Padding(padding: EdgeInsets.only(right: 12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ],
      child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Center(child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
            child: ListView(
        padding: EdgeInsets.all(Responsive.pagePadding(context)),
        children: [
          Card(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                return SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  title: const Text("Karanlık Mod", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Uygulama temasını değiştirin"),
                  secondary: Icon(currentMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                  value: currentMode == ThemeMode.dark,
                  activeColor: AppColors.primary,
                  onChanged: (bool isDark) async {
                    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
                    themeNotifier.value = newMode; // Tüm uygulamada temayı anında değiştirir
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('theme_mode', isDark ? 'dark' : 'light'); // Seçimi hafızaya yazar
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 16),
            child: Text("Profil Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Ad Soyad')),
                  const SizedBox(height: 16),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-posta')),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: isSavingProfile ? null : _saveProfile,
                      icon: isSavingProfile ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.person_rounded),
                      label: const Text("Profili Güncelle"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 16),
            child: Text("Güvenlik (Şifre Değiştir)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: _currentPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mevcut Şifre')),
                  const SizedBox(height: 16),
                  TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni Şifre')),
                  const SizedBox(height: 16),
                  TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)')),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: isSavingPassword ? null : _savePassword,
                      icon: isSavingPassword ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_rounded),
                      label: const Text("Şifreyi Güncelle"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text("Fiyat & Hesaplama Ayarları",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 16),
            child: Text("Bu değerler tüm giyotin hesaplamalarında kullanılır. Kâr marjı ve KDV satış fiyatını belirler.",
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          if (_useV2)
            // ── GRUPLU AYARLAR (v2) ──
            ..._settingGroups.map((grup) {
              final isim = grup['isim'].toString();
              final alanlar = (grup['alanlar'] as List).cast<Map<String, dynamic>>();
              final IconData ikon = {
                "Fiyatlandırma": Icons.percent_rounded,
                "Temel Malzeme": Icons.layers_rounded,
                "Motor Sistemi": Icons.settings_input_component_rounded,
                "Aksesuarlar": Icons.handyman_rounded,
                "Fitiller": Icons.linear_scale_rounded,
                "Zincir Sistemi": Icons.link_rounded,
              }[isim] ?? Icons.folder_rounded;
              final Color renk = isim == "Fiyatlandırma" ? AppColors.success : AppColors.primary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: renk.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(ikon, color: renk, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(isim, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
                      ]),
                      const SizedBox(height: 16),
                      // Alanları 2 sütunlu grid
                      LayoutBuilder(builder: (ctx, c) {
                        final twoCol = c.maxWidth > 480;
                        if (twoCol) {
                          final rows = <Widget>[];
                          for (int i = 0; i < alanlar.length; i += 2) {
                            rows.add(Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                Expanded(child: _v2Field(alanlar[i])),
                                const SizedBox(width: 12),
                                Expanded(child: i + 1 < alanlar.length ? _v2Field(alanlar[i + 1]) : const SizedBox()),
                              ]),
                            ));
                          }
                          return Column(children: rows);
                        }
                        return Column(children: alanlar.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 12), child: _v2Field(a))).toList());
                      }),
                    ]),
                  ),
                ),
              );
            }).toList()
          else
            // ── ESKİ DÜZ LİSTE (fallback) ──
            Card(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                ..._priceControllers.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(controller: entry.value,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: entry.key, suffixText: 'TL')),
                )).toList(),
              ]))),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : _saveSettings,
              icon: isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
              label: const Text("Tüm Ayarları Kaydet"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Card(
            color: AppColors.danger.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              title: const Text("Hesabımı Sil", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
              subtitle: const Text("Tüm verileriniz ve aboneliğiniz kalıcı olarak silinir.", style: TextStyle(color: AppColors.textMuted)),
              trailing: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
              onTap: _deleteAccount,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    )),
    );
  }
}

// Global çıkış fonksiyonu
Future<void> appLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  if (context.mounted) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  APP SHELL — responsive navigasyon iskeleti
//  Desktop: kalıcı sidebar | Tablet: ikon rail | Mobil: drawer + üst bar
// ═══════════════════════════════════════════════════════════════════════
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String routeKey;
  const NavItem(this.icon, this.activeIcon, this.label, this.routeKey);
}

const List<NavItem> kNavItems = [
  NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, "Panel", "dashboard"),
  NavItem(Icons.calculate_outlined, Icons.calculate_rounded, "Giyotin Hesapla", "giyotin"),
  NavItem(Icons.history_outlined, Icons.history_rounded, "Geçmiş İşler", "history"),
  NavItem(Icons.settings_outlined, Icons.settings_rounded, "Ayarlar", "settings"),
];

class AppShell extends StatelessWidget {
  final Widget child;
  final String activeRoute;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  const AppShell({super.key, required this.child, required this.activeRoute, this.title, this.actions, this.floatingActionButton});

  void _navigate(BuildContext ctx, String key) {
    if (key == activeRoute) {
      Navigator.maybePop(ctx); // drawer'ı kapat
      return;
    }
    Widget? target;
    switch (key) {
      case "dashboard": target = const HomeScreen(); break;
      case "giyotin":   target = const GiyotinScreen(); break;
      case "history":   target = const GiyotinHistoryScreen(); break;
      case "settings":  target = const SettingsScreen(); break;
      case "admin":     Navigator.pushReplacementNamed(ctx, '/admin'); return;
    }
    if (target != null) {
      Navigator.pushReplacement(ctx, PageRouteBuilder(
        pageBuilder: (_, a, __) => target!,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 250),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = Responsive.of(context);
    // userNotifier'ı dinle — kullanıcı bilgisi geç gelirse (cold start/refresh)
    // admin paneli butonu otomatik olarak rebuild ile görünür hale gelir.
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: userNotifier,
      builder: (context, user, _) {
        final isSuper = user?['is_superuser'] == true;
        if (device == DeviceType.mobile) {
          return _buildMobile(context, isSuper);
        }
        return _buildDesktopTablet(context, device, isSuper);
      },
    );
  }

  // ── MOBİL: üst bar + drawer + bottom nav ──
  Widget _buildMobile(BuildContext context, bool isSuper) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLow,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          _logoMark(28),
          const SizedBox(width: 8),
          Text(title ?? "Kavira", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(width: 6),
          _betaChip(),
        ]),
        actions: actions,
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surfaceLow,
        child: SafeArea(child: _sidebarContent(context, isSuper, expanded: true)),
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: child),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _bottomNav(BuildContext context) {
    final idx = kNavItems.indexWhere((n) => n.routeKey == activeRoute);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(kNavItems.length, (i) {
              final n = kNavItems[i];
              final active = i == idx;
              return Expanded(child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _navigate(context, n.routeKey),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(active ? n.activeIcon : n.icon, size: 22,
                        color: active ? AppColors.primary : AppColors.textMuted),
                    const SizedBox(height: 3),
                    Text(n.label.split(' ').first, style: TextStyle(
                        fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AppColors.primary : AppColors.textMuted)),
                  ]),
                ),
              ));
            }),
          ),
        ),
      ),
    );
  }

  // ── DESKTOP / TABLET: sidebar + content ──
  Widget _buildDesktopTablet(BuildContext context, DeviceType device, bool isSuper) {
    final isRail = device == DeviceType.tablet;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: Row(children: [
        // Sidebar
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isRail ? 80 : 256,
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(child: _sidebarContent(context, isSuper, expanded: !isRail)),
        ),
        // İçerik
        Expanded(child: Column(children: [
          // Üst bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow.withOpacity(0.6),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Text(title ?? _routeTitle(), style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
              const Spacer(),
              if (actions != null) ...actions!,
            ]),
          ),
          Expanded(child: child),
        ])),
      ]),
    );
  }

  String _routeTitle() {
    final n = kNavItems.where((x) => x.routeKey == activeRoute);
    return n.isNotEmpty ? n.first.label : "Kavira";
  }

  // ── SIDEBAR İÇERİĞİ ──
  Widget _sidebarContent(BuildContext context, bool isSuper, {required bool expanded}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Logo
      Padding(
        padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0, vertical: 22),
        child: Row(
          mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            _logoMark(34),
            if (expanded) ...[
              const SizedBox(width: 12),
              const Text("Kavira", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5)),
              const SizedBox(width: 6),
              _betaChip(),
            ],
          ],
        ),
      ),
      const SizedBox(height: 8),
      // Nav items
      ...kNavItems.map((n) => _navTile(context, n, expanded)),
      if (isSuper) _navTile(context,
          const NavItem(Icons.shield_outlined, Icons.shield_rounded, "Admin Panel", "admin"),
          expanded, gradient: true),
      const Spacer(),
      // Promo kod erişimi — her kullanıcı için, her zaman görünür
      _promoTile(context, expanded),
      // Kullanıcı kartı + çıkış
      Padding(
        padding: EdgeInsets.all(expanded ? 12 : 8),
        child: Column(children: [
          if (expanded) _userCard(context),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => appLogout(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0, vertical: 12),
              child: Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Text("Çıkış Yap", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  /// Sidebar'da Çıkış Yap'tan hemen önce duran "Promo Kod" tile'ı.
  /// Her kullanıcıda her zaman görünür; tıklayınca _PromoCodeBox dialog'u açar.
  Widget _promoTile(BuildContext context, bool expanded) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showPromoCodeDialog(context),
          child: Tooltip(
            message: expanded ? '' : 'Promo Kod',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 20, color: AppColors.warning),
                  if (expanded) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Promo Kod", style: TextStyle(
                          color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 13.5,
                        )),
                        Text("Süre uzat / hediye kod", style: TextStyle(
                          color: AppColors.text.withOpacity(0.55), fontSize: 11,
                        )),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navTile(BuildContext context, NavItem n, bool expanded, {bool gradient = false}) {
    final active = n.routeKey == activeRoute;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigate(context, n.routeKey),
          child: Tooltip(
            message: expanded ? '' : n.label,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0, vertical: 12),
              decoration: BoxDecoration(
                gradient: active
                  ? (gradient ? AppColors.gradientAccent : AppColors.gradientPrimary)
                  : null,
                color: active ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: active ? [BoxShadow(
                  color: (gradient ? AppColors.accent : AppColors.primary).withOpacity(0.35),
                  blurRadius: 16, offset: const Offset(0, 4))] : null,
              ),
              child: Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(active ? n.activeIcon : n.icon, size: 20,
                      color: active ? Colors.white : (gradient ? AppColors.accent : AppColors.textMuted)),
                  if (expanded) ...[
                    const SizedBox(width: 14),
                    Text(n.label, style: TextStyle(
                        color: active ? Colors.white : (gradient ? AppColors.accent : AppColors.text.withOpacity(0.85)),
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13.5)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userCard(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: userNotifier,
      builder: (_, user, __) {
        final name = user?['full_name']?.toString() ?? 'Kullanıcı';
        final email = user?['email']?.toString() ?? '';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'K';
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
              child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 12), overflow: TextOverflow.ellipsis),
              Text(email, style: TextStyle(color: AppColors.textMuted, fontSize: 10), overflow: TextOverflow.ellipsis),
            ])),
          ]),
        );
      },
    );
  }

  Widget _logoMark(double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
    child: const Center(child: Text("K", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
  );

  Widget _betaChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.18), borderRadius: BorderRadius.circular(99)),
    child: const Text("BETA", style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _recentRecords = [];
  bool _isLoadingStats = true;
  late final GiyotinService _giyotinService;

  // Kullanıcı içgörüleri
  Map<String, dynamic>? _myInsights;
  bool _loadingMyInsights = true;
  bool _insightsExpanded = false;

  // Aktif tedarikçi
  Map<String, dynamic>? _activeVendor;
  Map<String, dynamic>? _activeSystem;
  List<dynamic> _allVendors = [];

  @override
  void initState() {
    super.initState();
    _giyotinService = GiyotinService(dio);
    _fetchStats();
    _fetchMyInsights();
    _fetchActiveVendor();
    _fetchAllVendors();
  }

  Future<void> _fetchActiveVendor() async {
    try {
      final res = await dio.get('/api/v1/vendors/my-active');
      if (mounted) setState(() {
        _activeVendor = res.data['vendor'] as Map<String, dynamic>?;
        _activeSystem = res.data['system'] as Map<String, dynamic>?;
      });
      await _checkMissingRoles();
    } catch (_) {}
  }

  // Eksik rol kontrolü — sistem profillerini tarayıp temel role yoksa uyarı sayar
  int _missingRolesCount = 0;
  Future<void> _checkMissingRoles() async {
    final slug = _activeVendor?['slug']?.toString();
    final sub  = _activeSystem?['sub_category']?.toString();
    if (slug == null || sub == null) {
      if (mounted) setState(() => _missingRolesCount = 0);
      return;
    }
    try {
      final r = await dio.get('/api/v1/vendors/$slug/systems/$sub/profiles');
      final profs = (r.data['profiles'] as List?) ?? [];
      final mevcutRoller = profs.map((p) => (p['role'] ?? '').toString()).where((r) => r.isNotEmpty).toSet();
      const temel = {
        "MOTOR_KUTUSU_ALT", "ALT_KASA", "YAN_DIKME_ANA",
        "KENET_CEKME", "HAREKETLI_UST_KUPESTE",
      };
      final eksik = temel.difference(mevcutRoller);
      if (mounted) setState(() => _missingRolesCount = eksik.length);
    } catch (_) {
      if (mounted) setState(() => _missingRolesCount = 0);
    }
  }

  Future<void> _fetchAllVendors() async {
    try {
      final res = await dio.get('/api/v1/vendors');
      if (mounted) setState(() {
        _allVendors = (res.data['vendors'] as List?) ?? [];
      });
    } catch (_) {}
  }

  Future<void> _showVendorPicker() async {
    if (_allVendors.isEmpty) await _fetchAllVendors();
    if (!mounted) return;

    // Her vendor için sistemleri yükle (eğer henüz yüklenmemişse)
    Map<String, List<dynamic>> systemsByVendor = {};
    for (final v in _allVendors) {
      try {
        final r = await dio.get('/api/v1/vendors/${v['slug']}/systems');
        systemsByVendor[v['slug']] = (r.data['systems'] as List?) ?? [];
      } catch (_) {}
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _VendorPickerSheet(
        vendors: _allVendors,
        systemsByVendor: systemsByVendor,
        activeSlug: _activeVendor?['slug']?.toString(),
        activeSub: _activeSystem?['sub_category']?.toString(),
        onSelect: (slug, sub) async {
          try {
            await dio.put('/api/v1/vendors/my-active',
                data: {'vendor_slug': slug, 'sub_category': sub});
            await _fetchActiveVendor();
            if (mounted) {
              Navigator.pop(ctx);
              showCustomSnackBar(
                message: "Tedarikçi güncellendi ✓",
                isError: false,
              );
            }
          } catch (e) {
            if (mounted) {
              showCustomSnackBar(message: "Güncellenemedi", isError: true);
            }
          }
        },
        onAddCustom: () {
          Navigator.pop(ctx);
          _showCustomVendorDialog();
        },
      ),
    );
  }

  // ── Kendi tedarikçimi ekle dialog ─────────────────────────────────
  Future<void> _showCustomVendorDialog() async {
    final nameCtrl = TextEditingController();
    final sysCtrl = TextEditingController(text: "Klasik Giyotin");
    final prefCtrl = TextEditingController();
    final lenCtrl = TextEditingController(text: "6500");

    int step = 0;
    int? createdVendorId;
    int? createdSystemId;
    Map<String, dynamic>? createdVendor;

    final csvCtrl = TextEditingController(text:
      "code,name,role,kg_per_m,sort_order\n"
      "ABC-101,Motor Kutusu,MOTOR_KUTUSU_ALT,1.293,0\n"
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(children: [
          Icon(Icons.factory_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Text(step == 0 ? "Kendi Tedarikçim" : "Profillerini Yükle",
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        ]),
        content: SizedBox(width: 480, child: step == 0
          ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Kullanmakta olduğun firmayı listeye ekle. Sadece şirketin görür.",
                style: TextStyle(fontSize: 12, color: AppColors.text.withOpacity(0.7))),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(
                labelText: "Firma Adı", hintText: "Örn. Murat Alüminyum")),
              const SizedBox(height: 10),
              TextField(controller: sysCtrl, decoration: const InputDecoration(
                labelText: "Sistem Adı", hintText: "Klasik Giyotin")),
              const SizedBox(height: 10),
              TextField(controller: prefCtrl, decoration: const InputDecoration(
                labelText: "Kod Prefix (opsiyonel)", hintText: "M-, MUR-")),
              const SizedBox(height: 10),
              TextField(
                controller: lenCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stok Boy (mm)", hintText: "6500"),
              ),
            ])
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Sistemden hangi profiller var? CSV formatında yapıştır:",
                style: TextStyle(fontSize: 12, color: AppColors.text.withOpacity(0.8))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "code,name,role,kg_per_m,sort_order\n"
                  "M-1401,Motor Kutusu,MOTOR_KUTUSU_ALT,1.29,0",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                ),
                child: Text(
                  "Roller (hesaplama anahtarı): MOTOR_KUTUSU_ALT, ALT_KASA, YAN_DIKME_ANA, "
                  "YAN_KUTU_BAZA, YAN_DIKEY_KAPAK, VASISTAS_UST_BAZA, FONKSIYONEL_BAZA, "
                  "ISPANYOLET_BAZA, KENET_CEKME, HAREKETLI_UST_KUPESTE",
                  style: TextStyle(fontSize: 10, color: AppColors.warning, height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: TextField(
                  controller: csvCtrl,
                  maxLines: null, expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: AppColors.background.withOpacity(0.5),
                  ),
                ),
              ),
            ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () async {
              if (step == 0) {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  final r = await dio.post('/api/v1/vendors/custom', data: {
                    'name': nameCtrl.text.trim(),
                    'system_name': sysCtrl.text.trim().isEmpty ? "Klasik Giyotin" : sysCtrl.text.trim(),
                    'code_prefix': prefCtrl.text.trim().isEmpty ? null : prefCtrl.text.trim(),
                    'profile_length_mm': double.tryParse(lenCtrl.text) ?? 6500,
                  });
                  createdVendor = r.data['vendor'] as Map<String, dynamic>?;
                  createdVendorId = createdVendor?['id'] as int?;
                  createdSystemId = (r.data['system'] as Map<String, dynamic>?)?['id'] as int?;
                  setSt(() => step = 1);
                } catch (_) {}
              } else {
                if (createdSystemId == null) return;
                try {
                  final r = await dio.post(
                    '/api/v1/vendors/custom/systems/$createdSystemId/profiles/bulk',
                    data: {'csv_text': csvCtrl.text, 'replace': false},
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    showCustomSnackBar(
                      message: "Eklendi: ${r.data['added']}. Şimdi seç ve hesaplayabilirsin.",
                      isError: false,
                    );
                    // Listeyi yenile ve yeni vendor'ı aktif yap
                    await _fetchAllVendors();
                    if (createdVendor != null) {
                      await dio.put('/api/v1/vendors/my-active', data: {
                        'vendor_slug': createdVendor!['slug'],
                        'sub_category': 'klasik',
                      });
                      await _fetchActiveVendor();
                    }
                  }
                } catch (_) {}
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(step == 0 ? "Devam: Profiller →" : "Yükle ve Aktif Et"),
          ),
        ],
      )),
    );
  }

  Future<void> _fetchMyInsights() async {
    try {
      final res = await dio.get('/api/v1/giyotin/my-insights');
      if (mounted) setState(() {
        _myInsights = res.data as Map<String, dynamic>;
        _loadingMyInsights = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMyInsights = false);
    }
  }

  Future<void> _fetchStats() async {
    try {
      final data = await _giyotinService.getRecords();
      if (mounted) {
        setState(() {
          // Son 7 kaydı alıp, grafikte soldan sağa yeni tarihe doğru sıralamak için ters çeviriyoruz
          _recentRecords = data.take(7).toList().reversed.toList();
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  // Çıkış yapma (Token'ı silip Login ekranına dönme) fonksiyonu
  void logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileR;
    return AppShell(
      activeRoute: "dashboard",
      title: "Panel",
      child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.pagePadding(context)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── PREMIUM HERO (animated mesh gradient + glassmorphism) ──
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _buildPremiumHero(isMobile),
                  ),
                  const SizedBox(height: 16),
                  // ── AKTİF TEDARİKÇİ BANNER ──────────────────────────────
                  _buildVendorBanner(isMobile),
                  const SizedBox(height: 24),
                  // ── KPI SATIRI ──────────────────────────────────────────
                  _buildKpiRow(isMobile),

                  // ── İÇGÖRÜLERİN paneli (genişletilebilir) ──
                  const SizedBox(height: 28),
                  _buildMyInsightsPanel(isMobile),

                  // ── BETA bilgilendirme — premium glassmorphism ──
                  Container(
                    margin: const EdgeInsets.only(top: 28),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.warning.withOpacity(0.16),
                        AppColors.accent2.withOpacity(0.08),
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.warning.withOpacity(0.35), width: 1),
                      boxShadow: AppColors.cardShadowDeep,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientWarning,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppColors.glow(AppColors.warning),
                          ),
                          child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Text("Beta Test Aşamasındayız", style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 16)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text("BETA", style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                "Kavira SaaS geliştirme sürecinde. Geri bildirimleriniz ile sistemi sizin için mükemmelleştiriyoruz.",
                                style: TextStyle(color: AppColors.text.withOpacity(0.78), fontSize: 13, height: 1.5),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final emailLaunchUri = Uri(
                                    scheme: 'mailto',
                                    path: 'destek@kaviragiyotin.com',
                                    query: 'subject=Kavira SaaS Beta Geri Bildirim',
                                  );
                                  if (!await launchUrl(emailLaunchUri)) {
                                    showCustomSnackBar(message: "E-posta uygulaması açılamadı.", isError: true);
                                  }
                                },
                                icon: const Icon(Icons.mail_outline_rounded, size: 16, color: Colors.white),
                                label: const Text("Geri Bildirim Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // --- YENİ EKLENEN MALİYET GRAFİĞİ BÖLÜMÜ ---
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _buildCostChart(),
                  ),
                  if (!_isLoadingStats && _recentRecords.isNotEmpty) const SizedBox(height: 48),
                  Text("Hızlı Erişim Modülleri", style: TextStyle(fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: isMobile ? 16 : 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: Responsive.val(context, mobile: 1, tablet: 2, desktop: 3),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: Responsive.val(context, mobile: 1.6, tablet: 1.4, desktop: 1.5),
                    children: [
                      _AnimatedDashboardCard(
                        title: "Giyotin Hesaplama", subtitle: "Yeni bir maliyet analizi ve kesim planı oluşturun.",
                        icon: Icons.calculate_rounded, color: AppColors.primary,
                        index: 0, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiyotinScreen())),
                      ),
                      _AnimatedDashboardCard(
                        title: "Geçmiş İşler", subtitle: "Önceki hesaplamalarınızı inceleyin ve rapor indirin.",
                        icon: Icons.history_rounded, color: AppColors.success,
                        index: 1, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiyotinHistoryScreen())),
                      ),
                      _AnimatedDashboardCard(
                        title: "Tedarikçi Seç", subtitle: "Katar, Saray, Zahit ve daha fazlası. Profillere göre hesapla.",
                        icon: Icons.factory_rounded, color: AppColors.accent,
                        index: 2, onTap: _showVendorPicker,
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

  // ── AKTİF TEDARİKÇİ BANNER ──────────────────────────────────────────────
  Widget _buildVendorBanner(bool isMobile) {
    final hasVendor = _activeVendor != null;
    final name = _activeVendor?['name']?.toString() ?? 'Tedarikçi seçilmedi';
    final systemName = _activeSystem?['name']?.toString() ?? '';
    final codePrefix = _activeSystem?['code_prefix']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasVendor
            ? [AppColors.primary.withOpacity(0.12), AppColors.accent.withOpacity(0.06)]
            : [AppColors.warning.withOpacity(0.12), AppColors.warning.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasVendor
            ? AppColors.primary.withOpacity(0.25)
            : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showVendorPicker,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: hasVendor ? AppColors.gradientPrimary : AppColors.gradientWarning,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: AppColors.glow(hasVendor ? AppColors.primary : AppColors.warning),
                ),
                child: const Icon(Icons.factory_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(
                      hasVendor ? "Tedarikçi: " : "Tedarikçi seçimi yapılmadı",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasVendor) Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text,
                      ),
                    ),
                  ]),
                  if (hasVendor && systemName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          systemName,
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      if (codePrefix.isNotEmpty)
                        Text("Kod: $codePrefix...",
                          style: TextStyle(
                            fontSize: 10, color: AppColors.text.withOpacity(0.5),
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (_missingRolesCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.warning_amber_rounded, size: 10, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text("$_missingRolesCount eksik rol",
                              style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w800,
                                color: AppColors.warning,
                              ),
                            ),
                          ]),
                        ),
                    ]),
                  ] else if (!hasVendor) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Doğru hesap için tedarikçinizi seçin",
                      style: TextStyle(fontSize: 11, color: AppColors.warning),
                    ),
                  ],
                ]),
              ),
              const Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted, size: 18),
              const SizedBox(width: 4),
              Text("Değiştir", style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHero(bool isMobile) {
    final saat = DateTime.now().hour;
    final greeting = saat < 6 ? "İyi geceler" : saat < 12 ? "Günaydın" : saat < 18 ? "Tünaydın" : "İyi akşamlar";
    final userName = userNotifier.value?['full_name']?.toString().split(' ').first ?? 'Kullanıcı';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradientHero,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadowDeep,
      ),
      child: Stack(
        children: [
          // Mesh decoration — sağ üstte parlayan daire
          Positioned(
            right: -40, top: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent.withOpacity(0.45), AppColors.accent.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -60, bottom: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withOpacity(0.35), AppColors.primary.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          // İçerik
          Padding(
            padding: EdgeInsets.all(isMobile ? 24.0 : 36.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live durum chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22D3EE), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text("$greeting, $userName", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 18),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFCBD5E1)],
                  ).createShader(b),
                  child: Text(
                    "Kavira çalışma alanın hazır",
                    style: TextStyle(
                      fontSize: isMobile ? 26 : 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Hesapla, optimize et, kâr et. Modern üretim için yapay zekâ destekli SaaS.",
                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.78), height: 1.5),
                ),
                const SizedBox(height: 22),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiyotinScreen())),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text("Yeni Hesaplama", style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiyotinHistoryScreen())),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text("Geçmiş İşler"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI ROW ───────────────────────────────────────────────────────────────
  Widget _buildKpiRow(bool isMobile) {
    // Hesaplamalar — son kayıtlardan toplam, ortalama, max
    double toplam = 0, mx = 0;
    int adet = _recentRecords.length;
    for (var r in _recentRecords) {
      final c = (r['cost_details']?['total_cost'] as num?)?.toDouble() ?? 0;
      toplam += c;
      if (c > mx) mx = c;
    }
    final ort = adet > 0 ? toplam / adet : 0;

    final kpiler = [
      _KpiData("Toplam Proje", adet.toDouble(), "adet", Icons.layers_rounded, AppColors.primary, AppColors.gradientPrimary),
      _KpiData("Toplam Maliyet", toplam, "₺", Icons.payments_rounded, AppColors.success, AppColors.gradientSuccess, currency: true),
      _KpiData("Ortalama / Proje", ort.toDouble(), "₺", Icons.show_chart_rounded, AppColors.accent, AppColors.gradientAccent, currency: true),
      _KpiData("En Yüksek", mx, "₺", Icons.trending_up_rounded, AppColors.warning, AppColors.gradientWarning, currency: true),
    ];

    if (isMobile) {
      return Column(children: [
        for (int i = 0; i < kpiler.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildKpiCard(kpiler[i], i),
        ]
      ]);
    }
    return Row(children: [
      for (int i = 0; i < kpiler.length; i++) ...[
        if (i > 0) const SizedBox(width: 16),
        Expanded(child: _buildKpiCard(kpiler[i], i)),
      ]
    ]);
  }

  Widget _buildKpiCard(_KpiData d, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        tint: AppColors.surface.withOpacity(0.65),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: d.gradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppColors.glow(d.color),
                ),
                child: Icon(d.icon, size: 18, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: d.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("son 7", style: TextStyle(color: d.color, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 14),
            Text(d.label, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              if (d.currency)
                AnimatedCounter(
                  value: d.value,
                  prefix: '₺',
                  decimals: d.value > 999 ? 0 : 2,
                  style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                )
              else
                AnimatedCounter(
                  value: d.value,
                  suffix: ' ${d.unit}',
                  style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── İÇGÖRÜLERİN — Kullanıcı bazlı detaylı panel (collapse/expand) ──────
  Widget _buildMyInsightsPanel(bool isMobile) {
    if (_loadingMyInsights) {
      return _glassWrap(child: const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ));
    }
    if (_myInsights == null) return const SizedBox.shrink();

    final i = _myInsights!;
    final fin = (i['finansal'] as Map<String, dynamic>?) ?? {};
    final topSis = (i['top_sistemler'] as List?)?.cast<dynamic>() ?? [];
    final topPrf = (i['top_profiller'] as List?)?.cast<dynamic>() ?? [];
    final saatlik = (i['saatlik_aktivite'] as List?)?.cast<num>().toList() ?? List.filled(24, 0);
    final gunler = (i['gun_aktivite'] as List?)?.cast<num>().toList() ?? List.filled(7, 0);
    final sub = i['subscription'] as Map<String, dynamic>?;
    final toplam = i['toplam_proje'] ?? 0;
    final s30 = i['son_30_gun'] ?? 0;
    final s7 = i['son_7_gun'] ?? 0;

    final gunKaldi = sub?['gun_kaldi'] as int?;
    final showSubChip = gunKaldi != null && gunKaldi >= 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface.withOpacity(0.85), AppColors.surfaceLow.withOpacity(0.9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadowDeep,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Üst başlık + toggle
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(() => _insightsExpanded = !_insightsExpanded),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.glow(AppColors.accent),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("İçgörülerin",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 2),
                Text("$toplam toplam proje · $s30 son 30 gün · $s7 son 7 gün",
                    style: TextStyle(fontSize: 12, color: AppColors.text.withOpacity(0.6))),
              ])),
              if (showSubChip) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: gunKaldi <= 3 ? AppColors.danger.withOpacity(0.18) : AppColors.success.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: (gunKaldi <= 3 ? AppColors.danger : AppColors.success).withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.hourglass_top_rounded, size: 12,
                        color: gunKaldi <= 3 ? AppColors.danger : AppColors.success),
                    const SizedBox(width: 4),
                    Text("$gunKaldi gün",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: gunKaldi <= 3 ? AppColors.danger : AppColors.success)),
                  ]),
                ),
                const SizedBox(width: 8),
              ],
              Icon(_insightsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.text.withOpacity(0.6)),
            ]),
          ),
        ),
        // Genişletilmiş içerik
        if (_insightsExpanded) ...[
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Mali kutu (3'lü)
              LayoutBuilder(builder: (ctx, c) {
                final wide = c.maxWidth > 600;
                final items = [
                  _miniFinKart("Ortalama Maliyet",
                      formatTRCurrency((fin['ortalama_proje_maliyeti_tl'] as num?) ?? 0),
                      Icons.payments_outlined, AppColors.primary),
                  _miniFinKart("En Yüksek Proje",
                      formatTRCurrency((fin['en_yuksek_proje_tl'] as num?) ?? 0),
                      Icons.trending_up_rounded, AppColors.warning),
                  _miniFinKart("Ort. Fire Payı",
                      "%${fin['ortalama_fire_yuzde'] ?? 0}",
                      Icons.percent_rounded, AppColors.accent2),
                ];
                return wide
                  ? Row(children: [for (int k = 0; k < items.length; k++)
                      ...[ if (k > 0) const SizedBox(width: 10), Expanded(child: items[k]) ]])
                  : Column(children: [for (int k = 0; k < items.length; k++)
                      ...[ if (k > 0) const SizedBox(height: 8), items[k] ]]);
              }),
              const SizedBox(height: 18),

              // Top sistem
              if (topSis.isNotEmpty) ...[
                Text("En Çok Kullandığın Sistem Türleri",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.text.withOpacity(0.85))),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in topSis)
                    _chipMetric(s['isim']?.toString() ?? '-', s['adet'].toString(), AppColors.primary),
                ]),
                const SizedBox(height: 18),
              ],

              // Top profil
              if (topPrf.isNotEmpty) ...[
                Text("Sık Kullandığın Profiller",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.text.withOpacity(0.85))),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in topPrf)
                    _chipMetric(p['kod']?.toString() ?? '-', p['frekans'].toString(), AppColors.accent),
                ]),
                const SizedBox(height: 18),
              ],

              // Saatlik aktivite mini-bar
              Text("En Üretken Saatlerin (tüm zamanlar)",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.text.withOpacity(0.85))),
              const SizedBox(height: 8),
              SizedBox(height: 70, child: _miniSaatChart(saatlik)),
              const SizedBox(height: 14),

              // Gün aktivitesi
              Text("Haftalık Düzenin",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.text.withOpacity(0.85))),
              const SizedBox(height: 8),
              _haftaGunBar(gunler),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _glassWrap({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.7),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );

  Widget _miniFinKart(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.text.withOpacity(0.65), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
        ])),
      ]),
    );
  }

  Widget _chipMetric(String name, String count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
        child: Text(count, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ),
    ]),
  );

  Widget _miniSaatChart(List<num> data) {
    final mx = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth / 24 - 2;
      return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (int h = 0; h < 24; h++) Container(
          width: w, margin: const EdgeInsets.only(right: 2),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Container(
              height: mx > 0 ? (data[h] / mx * 50).toDouble().clamp(2, 50) : 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (h % 6 == 0) ...[
              const SizedBox(height: 3),
              Text("$h", style: TextStyle(fontSize: 8, color: AppColors.text.withOpacity(0.5))),
            ] else const SizedBox(height: 11),
          ]),
        ),
      ]);
    });
  }

  Widget _haftaGunBar(List<num> data) {
    final mx = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return Row(children: [
      for (int i = 0; i < 7; i++) Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(children: [
          Container(
            height: mx > 0 ? (data[i] / mx * 36).toDouble().clamp(3, 36) : 3,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Text(labels[i], style: TextStyle(fontSize: 10, color: AppColors.text.withOpacity(0.55))),
          Text("${data[i]}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)),
        ]),
      )),
    ]);
  }

  Widget _buildCostChart() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentRecords.isEmpty) {
      return const SizedBox.shrink(); // Veri yoksa alanı gizle
    }

    double maxCost = 0;
    double totalCost = 0;
    for (var r in _recentRecords) {
      final costDetails = r['cost_details'] ?? {};
      final cost = (costDetails['total_cost'] as num?)?.toDouble() ?? 0.0;
      if (cost > maxCost) maxCost = cost;
      totalCost += cost;
    }
    if (maxCost == 0) maxCost = 1; // Sıfıra bölünme hatasını önle

    // Izgara çizgileri için mantıklı bir üst sınır (topValue) hesaplama
    int order = maxCost.ceil().toString().length - 1;
    double multiplier = math.pow(10, order > 0 ? order : 1).toDouble();
    if (multiplier > 10) multiplier /= 10; // Daha hassas ızgara adımları için

    double topValue = ((maxCost / multiplier).ceil()) * multiplier;
    // En yüksek çubuğun tavana sıfır dayanmaması için %20'lik pay bırakıyoruz
    if (maxCost / topValue > 0.8) {
      topValue += multiplier;
    }
    if (topValue == 0) topValue = 100;

    List<double> gridValues = [topValue, topValue * 0.75, topValue * 0.5, topValue * 0.25, 0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Son 7 Projenin Maliyet Analizi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Text(
                "Toplam Hacim: ${totalCost.toStringAsFixed(0)} ₺",
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 280,
          padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              // Y Ekseni (Grid Değerleri)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: gridValues.map((v) => Text(
                  v >= 1000 ? "${(v/1000).toStringAsFixed(1)}k" : v.toStringAsFixed(0),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                )).toList(),
              ),
              const SizedBox(width: 16),
              // Grafik Alanı (Arkaplan çizgileri ve Sütunlar)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Arkaplan Grid Çizgileri
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: gridValues.map((v) => Container(
                              height: 1,
                              color: AppColors.textMuted.withOpacity(0.08),
                            )).toList(),
                          ),
                          // Barlar
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _recentRecords.map((r) {
                                  final costDetails = r['cost_details'] ?? {};
                                  final cost = (costDetails['total_cost'] as num?)?.toDouble() ?? 0.0;
                                  final projectName = r['project_name']?.toString() ?? '-';
                                  return Expanded(
                                    child: _AnimatedChartBar(
                                      cost: cost,
                                      maxCost: topValue,
                                      maxHeight: constraints.maxHeight,
                                      projectName: projectName,
                                    ),
                                  );
                                }).toList(),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // X-Axis Labels (Proje İsimleri)
                    Row(
                      children: _recentRecords.map((r) {
                        final projectName = r['project_name']?.toString() ?? '-';
                        return Expanded(
                          child: Tooltip(
                            message: projectName,
                            child: Text(
                              projectName.length > 6 ? "${projectName.substring(0, 5)}." : projectName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── KPI data wrapper ─────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final bool currency;
  _KpiData(this.label, this.value, this.unit, this.icon, this.color, this.gradient, {this.currency = false});
}

class _AnimatedChartBar extends StatefulWidget {
  final double cost;
  final double maxCost;
  final double maxHeight;
  final String projectName;

  const _AnimatedChartBar({
    required this.cost,
    required this.maxCost,
    required this.maxHeight,
    required this.projectName,
  });

  @override
  State<_AnimatedChartBar> createState() => _AnimatedChartBarState();
}

class _AnimatedChartBarState extends State<_AnimatedChartBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double ratio = widget.maxCost == 0 ? 0 : widget.cost / widget.maxCost;
    // Çubuk minimum 4 piksel görünsün
    final double barHeight = (ratio * widget.maxHeight).clamp(4.0, widget.maxHeight);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Sütun (Bar)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            height: barHeight + (_isHovered ? 8 : 0), // Hover'da hafifçe yukarı esner
            width: _isHovered ? 40 : 32, // Hover'da hafifçe genişler
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), // Düz alt, oval üst
              boxShadow: _isHovered ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 2))] : [],
            ),
          ),
          // Hover Balonu (Fiyat Etiketi)
          Positioned(
            bottom: barHeight + (_isHovered ? 8 : 0) + 8, // Çubuğun hemen üzerinde belirir
            child: AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.text, // Açık renkli baloncuk arka planı
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Text(
                  widget.cost >= 1000 ? "${(widget.cost / 1000).toStringAsFixed(1)}k" : widget.cost.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: AppColors.background, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int index;
  final VoidCallback onTap;

  const _AnimatedDashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<_AnimatedDashboardCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit:  (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -6.0 : 0.0)..scale(_isPressed ? 0.97 : 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(_isHovered ? 0.22 : 0.10),
                AppColors.surface.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isHovered ? widget.color.withOpacity(0.55) : AppColors.border,
              width: 1,
            ),
            boxShadow: _isHovered
              ? [
                  BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 32, spreadRadius: -4, offset: const Offset(0, 12)),
                  const BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
                ]
              : AppColors.cardShadowDeep,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onHighlightChanged: (isPressed) => setState(() => _isPressed = isPressed),
              onTap: widget.onTap,
              splashColor: widget.color.withOpacity(0.15),
              highlightColor: widget.color.withOpacity(0.05),
              child: Stack(children: [
                // Üst köşede parlama efekti
                Positioned(
                  right: -50, top: -50,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isHovered ? 0.7 : 0.35,
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [widget.color.withOpacity(0.35), widget.color.withOpacity(0.0)]),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.65)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isHovered ? AppColors.glow(widget.color) : [],
                            ),
                            child: Icon(widget.icon, size: 26, color: Colors.white),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            transform: Matrix4.identity()..translate(_isHovered ? 6.0 : 0.0, 0.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isHovered ? widget.color : AppColors.surfaceHigh.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Icon(Icons.arrow_forward_rounded, size: 16, color: _isHovered ? Colors.white : AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.3)),
                      const SizedBox(height: 6),
                      Text(widget.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════════
//  TEDARİKÇİ SEÇİM SHEET — bottom sheet ile vendor + sub_category seçimi
// ═══════════════════════════════════════════════════════════════════════
class _VendorPickerSheet extends StatelessWidget {
  final List<dynamic> vendors;
  final Map<String, List<dynamic>> systemsByVendor;
  final String? activeSlug;
  final String? activeSub;
  final Future<void> Function(String slug, String? sub) onSelect;
  final VoidCallback? onAddCustom;

  const _VendorPickerSheet({
    required this.vendors,
    required this.systemsByVendor,
    required this.activeSlug,
    required this.activeSub,
    required this.onSelect,
    this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.factory_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text(
                "Tedarikçi Seç",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
              )),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "Hangi alüminyum firmasının profillerini kullanıyorsun? Hesaplama buna göre yapılacak.",
              style: TextStyle(
                fontSize: 12, color: AppColors.text.withOpacity(0.65), height: 1.4,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: vendors.length,
              itemBuilder: (ctx, i) {
                final v = vendors[i] as Map<String, dynamic>;
                final slug = v['slug'].toString();
                final isSelected = slug == activeSlug;
                final systems = systemsByVendor[slug] ?? [];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Vendor başlık
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.gradientPrimary : null,
                              color: isSelected ? null : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(
                              v['name'].toString().substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppColors.text,
                              ),
                            )),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(v['name'].toString(),
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              if (v['is_default'] == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text("Varsayılan",
                                    style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 2),
                            Text("${systems.length} sistem",
                              style: TextStyle(fontSize: 11, color: AppColors.text.withOpacity(0.55)),
                            ),
                          ])),
                          if (isSelected) Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 20),
                        ]),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      // Sistemler (alt-kategoriler)
                      if (systems.isEmpty) Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text("Sistem yok", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      )
                      else ...systems.map((s) {
                        final sMap = s as Map<String, dynamic>;
                        final sub = sMap['sub_category']?.toString();
                        final sysSelected = isSelected && sub == activeSub;
                        return InkWell(
                          onTap: () => onSelect(slug, sub),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(children: [
                              Icon(
                                sysSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: sysSelected ? AppColors.primary : AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(sMap['name'].toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: sysSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text("${sMap['profile_count']} profil · Kod: ${sMap['code_prefix'] ?? '-'}",
                                  style: TextStyle(
                                    fontSize: 10, color: AppColors.text.withOpacity(0.5),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ])),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                            ]),
                          ),
                        );
                      }).toList(),
                    ]),
                  ),
                );
              },
            ),
          ),
          // ── Kendi tedarikçini ekle CTA ──
          if (onAddCustom != null) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddCustom,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text("Listede yok — Kendi Tedarikçimi Ekle",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
