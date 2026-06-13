import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:frontend/app_config.dart';
import 'package:frontend/screens/auth_screens.dart';
import 'package:frontend/screens/home_screens.dart';
import 'package:frontend/screens/giyotin_screens.dart';
import 'package:frontend/screens/legal_screens.dart';
import 'package:frontend/screens/admin_screen.dart';
import 'package:frontend/screens/musteri_public_screen.dart';

class AppColors {
  // ── SLATE LIGHT PALETTE — sade, profesyonel aydınlık tema ──
  static const background  = Color(0xFFF6F7F9);  // sayfa zemini (açık gri)
  static const surface     = Color(0xFFFFFFFF);  // kart yüzeyi (beyaz)
  static const surfaceLow  = Color(0xFFFFFFFF);  // nav / header (beyaz, kenarla ayrılır)
  static const surfaceHigh = Color(0xFFEEF1F4);  // hover / yükseltilmiş (açık gri)
  static const surfaceGlass= Color(0xF2FFFFFF);  // hafif şeffaf beyaz

  static const primary = Color(0xFF3A4F6B);   // slate lacivert — tek vurgu
  static const success = Color(0xFF1E9E6A);   // muted emerald
  static const warning = Color(0xFFC77A0A);   // muted amber
  static const danger  = Color(0xFFD14343);   // muted red
  static const info    = Color(0xFF2F6FB0);   // muted blue
  static const accent  = Color(0xFF4E6585);   // ikincil slate (vurgu ailesi)
  static const accent2 = Color(0xFF6B7A90);   // nötr slate gri

  static const text       = Color(0xFF1A1D21);  // ana metin (near-black slate)
  static const textMuted  = Color(0xFF6B7280);  // ikincil metin (slate gri)
  static const border     = Color(0x14000000);  // %8 black — hairline kenar
  static const borderSoft = Color(0x0A000000);  // %4 black

  // ── Gradyanlar — tek-ton, rafine ──
  static const gradientPrimary = LinearGradient(colors: [Color(0xFF44597A), Color(0xFF2E4058)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientSuccess = LinearGradient(colors: [Color(0xFF27A876), Color(0xFF158A5A)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientWarning = LinearGradient(colors: [Color(0xFFD79324), Color(0xFFB36C08)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientAccent  = LinearGradient(colors: [Color(0xFF4E6585), Color(0xFF3A4F6B)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientHero    = LinearGradient(
    colors: [Color(0xFF2E4058), Color(0xFF36495F), Color(0xFF3A4F6B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );
  static const gradientMesh = RadialGradient(
    colors: [Color(0x143A4F6B), Color(0x00000000)],
    radius: 1.2, center: Alignment.topRight,
  );

  // ── Gölgeler — yumuşak, aydınlık ──
  static const cardShadow = [BoxShadow(color: Color(0x0F1A1D21), blurRadius: 16, offset: Offset(0, 6), spreadRadius: -6)];
  static const cardShadowDeep = [
    BoxShadow(color: Color(0x141A1D21), blurRadius: 28, offset: Offset(0, 14), spreadRadius: -10),
  ];
  static List<BoxShadow> glow(Color c) => [
    BoxShadow(color: c.withOpacity(0.16), blurRadius: 22, offset: const Offset(0, 8), spreadRadius: -10),
  ];
}

// ── Premium widget helper'lar ─────────────────────────────────────────────
/// Cam efektli kart — glassmorphism. Üzerine içerik konur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final List<BoxShadow>? shadow;
  final Border? border;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.tint,
    this.shadow,
    this.border,
  });
  @override
  Widget build(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: tint ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: AppColors.border, width: 1),
        boxShadow: shadow ?? AppColors.cardShadow,
      ),
      padding: padding,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  RESPONSIVE TASARIM SİSTEMİ
// ═══════════════════════════════════════════════════════════════════════
enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static const double mobileMax  = 600;
  static const double tabletMax  = 1100;

  static DeviceType of(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < mobileMax) return DeviceType.mobile;
    if (w < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext c)  => of(c) == DeviceType.mobile;
  static bool isTablet(BuildContext c)  => of(c) == DeviceType.tablet;
  static bool isDesktop(BuildContext c) => of(c) == DeviceType.desktop;

  static T val<T>(BuildContext c, {required T mobile, T? tablet, required T desktop}) {
    switch (of(c)) {
      case DeviceType.mobile:  return mobile;
      case DeviceType.tablet:  return tablet ?? desktop;
      case DeviceType.desktop: return desktop;
    }
  }

  static double contentMaxWidth(BuildContext c) =>
      val(c, mobile: double.infinity, tablet: 900, desktop: 1240);
  static double pagePadding(BuildContext c) =>
      val(c, mobile: 16, tablet: 24, desktop: 40);
  static int gridCols(BuildContext c) =>
      val(c, mobile: 2, tablet: 2, desktop: 4);
}

extension ResponsiveCtx on BuildContext {
  DeviceType get device => Responsive.of(this);
  bool get isMobileR  => Responsive.isMobile(this);
  bool get isTabletR  => Responsive.isTablet(this);
  bool get isDesktopR => Responsive.isDesktop(this);
  double get pagePad => Responsive.pagePadding(this);
}

/// Animasyonlu sayı sayacı — 0'dan hedefe smooth artar
class AnimatedCounter extends StatelessWidget {
  final num value;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
  });
  @override
  Widget build(BuildContext ctx) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        '$prefix${v.toStringAsFixed(decimals)}$suffix',
        style: style,
      ),
    );
  }
}

// Global Navigator Key: Context gerektirmeyen navigasyon işlemleri (örn: Interceptor) için.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global ScaffoldMessenger Key: Interceptor içinden SnackBar göstermek için.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global Dio Instance: Tüm uygulama genelinde paylaşılan tek bir HTTP istemcisi. 
// BaseURL tanımlayarak her seferinde tam adresi yazma yükünden kurtuluyoruz.
final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

// Global Theme Notifier: Tema değişikliğini anında tüm uygulamaya bildirir
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// Global User Notifier: Tüm uygulama genelinde kullanıcı bilgilerini tutar
final ValueNotifier<Map<String, dynamic>?> userNotifier = ValueNotifier(null);

// Global Subscription Notifier: Abonelik durumu (sidebar, banner için)
final ValueNotifier<Map<String, dynamic>?> subscriptionNotifier = ValueNotifier(null);

// Kullanıcı ve abonelik bilgisini sunucudan çekip notifier'lara yazar
Future<void> refreshUserAndSubscription() async {
  try {
    final results = await Future.wait([
      dio.get('/api/v1/auth/me'),
      dio.get('/api/v1/subscription/status'),
    ]);
    userNotifier.value = Map<String, dynamic>.from(results[0].data);
    subscriptionNotifier.value = Map<String, dynamic>.from(results[1].data);
  } catch (_) {
    // Sessizce başarısız ol; interceptor zaten 401'i handle ediyor
  }
}

/// TR locale para formatı — örn: `1.234,56 ₺`
String formatTRCurrency(num? value, {bool showSymbol = true, int decimals = 2}) {
  if (value == null) return showSymbol ? '0,00 ₺' : '0,00';
  final isNegative = value < 0;
  final absValue = value.abs();
  final fixed = absValue.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts.length > 1 ? parts[1] : '';
  // Binlik ayırıcı (.) yerleştir
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    final remaining = intPart.length - i;
    buffer.write(intPart[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  final formatted = decimals > 0 ? '${buffer.toString()},$decPart' : buffer.toString();
  final signed = isNegative ? '-$formatted' : formatted;
  return showSymbol ? '$signed ₺' : signed;
}

/// TR locale tam sayı formatı — örn: `1.234`
String formatTRNumber(num? value) {
  if (value == null) return '0';
  return formatTRCurrency(value, showSymbol: false, decimals: 0);
}

/// İsim baş harflerini döner (avatar için): "Ahmet Yılmaz" → "AY"
String getInitials(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '?';
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1)).toUpperCase();
}

/// Abonelik durumunu özetler: {label, color, daysLeft, urgency}
Map<String, dynamic> summarizeSubscription(Map<String, dynamic>? sub) {
  if (sub == null) {
    return {'label': 'Yükleniyor...', 'urgency': 'none', 'daysLeft': null};
  }
  final isActive = sub['is_active'] == true;
  final planName = (sub['plan_name'] ?? 'Yok').toString();
  final endDateStr = sub['end_date']?.toString();
  DateTime? endDate;
  if (endDateStr != null) {
    try { endDate = DateTime.parse(endDateStr); } catch (_) {}
  }
  final daysLeft = endDate != null
      ? endDate.difference(DateTime.now()).inDays
      : null;
  final isTrial = planName.toLowerCase().contains('deneme') || planName.toLowerCase().contains('trial');

  if (!isActive) {
    return {'label': 'Abonelik Sona Erdi', 'urgency': 'expired', 'daysLeft': 0, 'planName': planName};
  }
  if (daysLeft != null && daysLeft <= 3) {
    return {
      'label': isTrial ? 'Deneme: $daysLeft gün kaldı' : 'Yenileme: $daysLeft gün',
      'urgency': daysLeft <= 1 ? 'critical' : 'warning',
      'daysLeft': daysLeft,
      'planName': planName,
    };
  }
  return {
    'label': isTrial ? 'Deneme: $daysLeft gün' : planName,
    'urgency': isTrial ? 'info' : 'ok',
    'daysLeft': daysLeft,
    'planName': planName,
  };
}

// YENİ: Merkezi, yumuşak tasarımlı ve kullanıcı dostu SnackBar Göstericisi
void showCustomSnackBar({required String message, bool isError = true}) {
  scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: (isError ? AppColors.danger : AppColors.success).withOpacity(0.95),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      elevation: 6,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Sade & profesyonel "Slate Light" tema — tüm uygulamada tek tema.
ThemeData _buildSlateTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    canvasColor: AppColors.surface,
    textTheme: base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceLow,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      shadowColor: Color(0x0F000000),
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3),
      iconTheme: IconThemeData(color: AppColors.text),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: const Color(0x0F1A1D21),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F3F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.grey.shade400),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary.withOpacity(0.35) : Colors.grey.shade300),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

void main() async {
  // Eklentileri başlatmak için gerekli
  WidgetsFlutterBinding.ensureInitialized();
  
  // Dio Interceptor Yapılandırması
  dio.interceptors.add(InterceptorsWrapper(
    // 1. Otomatik Token Ekleme: İstek gönderilmeden önce hafızadaki Token'ı başlıklara ekler.
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    // 2. Otomatik 401 Kontrolü: Hata durumunda (örn: token süresi dolunca) login'e yönlendirir.
    onError: (DioException e, handler) async {
      String errorMessage = "Bir hata oluştu.";

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Bağlantı zaman aşımına uğradı.";
      } else if (e.type == DioExceptionType.badResponse) {
        final int? statusCode = e.response?.statusCode;
        
        if (statusCode == 401) {
          errorMessage = "Oturum süresi doldu, lütfen tekrar giriş yapın.";
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('access_token');
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else if (statusCode == 403) {
          // Backend'den gelen 403 hatası abonelikle ilgiliyse özel ekrana yönlendir
          final detail = e.response?.data is Map ? e.response?.data['detail']?.toString() : null;
          if (detail != null && detail.toLowerCase().contains('abonelik')) {
            errorMessage = detail;
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
            );
          } else {
            errorMessage = detail ?? "Bu işlemi yapmaya yetkiniz yok.";
          }
        } else if (statusCode != null && statusCode >= 500) {
          errorMessage = "Sunucu hatası oluştu.";
        } else {
          // Backend'den gelen 'detail' mesajını ayıkla
          if (e.response?.data is Map) {
            errorMessage = e.response?.data['detail']?.toString() ?? errorMessage;
          } else if (e.response?.data is List<int>) {
            // Eğer responseType.bytes istenmişse ama hata JSON olarak döndüyse (PDF İndirme Hataları)
            try {
              final String jsonString = utf8.decode(e.response!.data);
              final decoded = jsonDecode(jsonString);
              if (decoded is Map) {
                errorMessage = decoded['detail']?.toString() ?? errorMessage;
              }
            } catch (_) {}
          }
        }
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = "Sunucuya bağlanılamadı. İnternetinizi kontrol edin.";
      }

      // Merkezi SnackBar gösterimi
      showCustomSnackBar(message: errorMessage, isError: true);

      return handler.next(e);
    },
  ));

  // Hafızadan token'ı kontrol et
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');
  
  // Sade & profesyonel aydınlık tema — tek tema kullanılıyor
  themeNotifier.value = ThemeMode.light;
  
  final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

  final String initialPath = Uri.base.path;

  runApp(KaviraApp(isLoggedIn: token != null, isFirstTime: isFirstTime, initialPath: initialPath));
}

class KaviraApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool isFirstTime;
  final String initialPath;
  const KaviraApp({super.key, required this.isLoggedIn, required this.isFirstTime, this.initialPath = '/'});

  @override
  State<KaviraApp> createState() => _KaviraAppState();
}

class _KaviraAppState extends State<KaviraApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Uygulama açıkken gelen linkleri dinle
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  Widget _resolveInitialScreen() {
    final raw = widget.initialPath;
    final path = raw.replaceFirst(RegExp(r'^/app'), '').replaceFirst(RegExp(r'/$'), '');
    if (path == '/terms')   return const TermsScreen();
    if (path == '/privacy') return const PrivacyScreen();
    if (path == '/refund')  return const RefundScreen();
    if (path == '/musteri') return const MusteriPublicScreen();
    if (path == '/reset-password') {
      final token = Uri.base.queryParameters['token'];
      if (token != null) return ResetPasswordScreen(token: token);
    }
    if (path == '/giyotin') {
      if (widget.isLoggedIn) return const GiyotinScreen();
      return const LoginScreen(redirectTo: '/giyotin');
    }
    if (widget.isLoggedIn) {
      return widget.isFirstTime ? const OnboardingScreen() : const HomeScreen();
    }
    return const LoginScreen();
  }

  void _handleDeepLink(Uri uri) {
    final uriPath = uri.path.replaceFirst(RegExp(r'^/app'), '');
    if (uriPath == '/musteri') {
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const MusteriPublicScreen()),
      );
      return;
    }
    if (uriPath == '/giyotin') {
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const GiyotinScreen()),
      );
      return;
    }
    if (uriPath == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(token: token)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Kavira SaaS',
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          themeMode: currentMode,
          // --- TEK PROFESYONEL AYDINLIK TEMA (Slate Light) ---
          theme: _buildSlateTheme(),
          darkTheme: _buildSlateTheme(),
          home: _resolveInitialScreen(),
          routes: {
            '/terms': (_) => const TermsScreen(),
            '/privacy': (_) => const PrivacyScreen(),
            '/refund': (_) => const RefundScreen(),
            '/admin': (_) => const AdminScreen(),
          },
          debugShowCheckedModeBanner: AppConfig.showDebugBanner,
        );
      },
    );
  }
}