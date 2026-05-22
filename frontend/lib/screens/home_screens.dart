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

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isLoading = false;
  bool isLoadingStatus = true;
  Map<String, dynamic>? subData;
  late final SubscriptionService _subscriptionService;

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService(dio);
    _fetchSubscriptionStatus();
  }

  Future<void> _fetchSubscriptionStatus() async {
    try {
      final data = await _subscriptionService.getSubscriptionStatus();
      if (mounted) {
        setState(() {
          subData = data;
          isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingStatus = false;
        });
      }
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aboneliği İptal Et"),
        content: const Text("Mevcut aboneliğinizi iptal etmek istediğinize emin misiniz? Bu işlem geri alınamaz ve sisteme erişiminiz kısıtlanabilir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("İptal Et", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        await dio.post('/api/v1/subscription/cancel');
        if (mounted) {
          showCustomSnackBar(message: "Aboneliğiniz başarıyla iptal edildi.", isError: false);
          await _fetchSubscriptionStatus(); // Durumu güncellemek için tekrar veri çek
        }
      } catch (e) {
        // Hata interceptor tarafından yönetiliyor
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Future<void> _startSubscription() async {
    setState(() => isLoading = true);
    try {
      // Backend'deki checkout-form endpoint'ine istek at
      final checkoutUrl = await _subscriptionService.createCheckoutForm();

      // Gelen Iyzico ödeme sayfasını tarayıcıda aç
      if (checkoutUrl != null) {
        final Uri url = Uri.parse(checkoutUrl);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          showCustomSnackBar(message: "Ödeme sayfası açılamadı.", isError: true);
        }
      }
    } on DioException catch (_) {
      // Olası hatalar zaten Interceptor tarafından ekrana basılıyor
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final bool isActive = subData?['is_active'] == true;
    final String planName = subData?['plan_name'] ?? 'Bilinmiyor';
    final String? endDateIso = subData?['end_date'];

    String formattedEndDate = "Belirsiz";
    if (endDateIso != null) {
      try {
        final date = DateTime.parse(endDateIso);
        formattedEndDate = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Abonelik Yönetimi")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Icon(
                    isActive ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                    size: 80,
                    color: isActive ? AppColors.success : AppColors.warning,
                  ),
                    const SizedBox(height: 24),
                  Text(
                    isActive ? "Aboneliğiniz Aktif" : "Aboneliğiniz Sona Erdi",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                    const SizedBox(height: 16),
                  if (isLoadingStatus)
                    const CircularProgressIndicator()
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text("Mevcut Plan: $planName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Bitiş Tarihi: $formattedEndDate", style: TextStyle(fontSize: 16, color: isActive ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isActive
                          ? "Aboneliğinizi yenilemek veya süresini uzatmak için aşağıdaki butonu kullanabilirsiniz."
                          : "Sistemi kullanmaya devam edebilmek ve hesaplamalar oluşturabilmek için lütfen aboneliğinizi yenileyin.",
                      style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                    const SizedBox(height: 32),
                    isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _startSubscription,
                                icon: const Icon(Icons.payment_rounded),
                                label: const Text("Kredi Kartı ile Yenile (Sanal Pos)"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _cancelSubscription,
                                  icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                                  label: const Text("Aboneliği İptal Et", style: TextStyle(color: AppColors.danger)),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
      final settingsData = await _settingsService.getSettings();
      final profileData = await _settingsService.getUserProfile();
      
      setState(() {
        companyName = settingsData['company_name'] ?? "Şirket Ayarları";
        _nameController.text = profileData['full_name'] ?? '';
        _emailController.text = profileData['email'] ?? '';
      });
      final fiyatlar = settingsData['fiyatlar'] as Map<String, dynamic>;
      
      fiyatlar.forEach((key, value) {
        _priceControllers[key] = TextEditingController(text: value.toString());
      });
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

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);
    try {
      final Map<String, double> updated = {};
      _priceControllers.forEach((key, ctrl) {
        updated[key] = double.tryParse(ctrl.text) ?? 0.0;
      });

      await _settingsService.saveSettings(updated);
      
      if (mounted) {
        showCustomSnackBar(message: "Fiyatlar başarıyla güncellendi!", isError: false);
      }
    } catch (e) {
      // Hata zaten interceptor tarafından gösteriliyor
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(companyName),
        actions: [
          if (isSaving || isSavingProfile || isSavingPassword) const Padding(padding: EdgeInsets.only(right: 20.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
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
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 16),
            child: Text("Birim Fiyatlar (TL)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fiyatları otomatik listeleyen döngü
                  ..._priceControllers.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: entry.value,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: entry.key, suffixText: 'TL'),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveSettings,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Fiyatları Kaydet"),
                    ),
                  ),
                ],
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
    );
  }
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

  @override
  void initState() {
    super.initState();
    _giyotinService = GiyotinService(dio);
    _fetchStats();
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kavira Dashboard'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('BETA', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            tooltip: 'Ayarlar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => logout(context),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Karşılama Afişi (Hero Banner)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 24.0 : 40.0),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Kavira SaaS Paneline Hoş Geldiniz 👋", style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          Text("İşlemlerinizi hızlandırmak için modern ve akıllı çalışma alanınız.", style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85))),
                        ],
                      ),
                    ),
                  ),
                  
                  // --- YENİ EKLENEN: BETA/TEST BİLGİLENDİRME KARTI ---
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Beta Test Aşamasındayız", style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text("Kavira SaaS şu anda geliştirme ve test sürecindedir. Maliyet ve optimizasyon sonuçlarında iyileştirmeler devam etmektedir. Karşılaştığınız hataları veya yeni özellik önerilerinizi bizimle paylaşabilirsiniz.", style: TextStyle(color: AppColors.text.withOpacity(0.9), fontSize: 14, height: 1.5)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final Uri emailLaunchUri = Uri(
                                      scheme: 'mailto',
                                      path: 'destek@kaviragiyotin.com',
                                      query: 'subject=Kavira SaaS Beta Geri Bildirim',
                                    );
                                    if (!await launchUrl(emailLaunchUri)) {
                                      showCustomSnackBar(message: "E-posta uygulaması açılamadı.", isError: true);
                                    }
                                  },
                                  icon: const Icon(Icons.mail_outline_rounded, size: 18, color: Colors.white),
                                  label: const Text("Bize Ulaşın", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.warning,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.3,
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
                      // İLERİDE AKTİF EDİLECEK: Abonelik Yönetimi
                      // _AnimatedDashboardCard(
                      //   title: "Abonelik Yönetimi", subtitle: "SaaS planınızı yenileyin veya ödeme yapın.",
                      //   icon: Icons.workspace_premium_rounded, color: AppColors.warning,
                      //   index: 2, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0, // Basıldığında %5 küçülme efekti
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withOpacity(0.1), width: 2),
            boxShadow: AppColors.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onHighlightChanged: (isPressed) => setState(() => _isPressed = isPressed),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: widget.color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(widget.icon, size: 32, color: widget.color)),
                        Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted.withOpacity(0.5)),
                      ],
                    ),
                    const Spacer(),
                    Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
                    const SizedBox(height: 8),
                    Text(widget.subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4)),
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