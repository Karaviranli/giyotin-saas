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
  static const background = Color(0xFF0F172A); // slate-900
  static const surface = Color(0xFF1E293B);    // slate-800
  static const primary = Color(0xFF3B82F6);    // blue-500
  static const success = Color(0xFF10B981);    // emerald-500
  static const warning = Color(0xFFF59E0B);    // amber-500
  static const danger = Color(0xFFEF4444);     // red-500
  static const info = Color(0xFF0EA5E9);       // sky-500
  static const text = Color(0xFFF8FAFC);       // slate-50
  static const textMuted = Color(0xFF94A3B8);  // slate-400

  // Ultra High-End UI için Gradients ve Gölgeler
  static const gradientPrimary = LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradientSuccess = LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const cardShadow = [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8))];
}

// Global Navigator Key: Context gerektirmeyen navigasyon işlemleri (örn: Interceptor) için.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global ScaffoldMessenger Key: Interceptor içinden SnackBar göstermek için.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global Dio Instance: Tüm uygulama genelinde paylaşılan tek bir HTTP istemcisi. 
// BaseURL tanımlayarak her seferinde tam adresi yazma yükünden kurtuluyoruz.
final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

// Global Theme Notifier: Tema değişikliğini anında tüm uygulamaya bildirir
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

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
  
  // Hafızadan kayıtlı temayı oku (Yoksa varsayılan karanlık mod başlar)
  final String? savedTheme = prefs.getString('theme_mode');
  if (savedTheme == 'light') {
    themeNotifier.value = ThemeMode.light;
  }
  
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
          // --- AYDINLIK MOD TEMA AYARLARI ---
          theme: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF0F172A)),
              bodyMedium: TextStyle(color: Color(0xFF0F172A)),
              bodySmall: TextStyle(color: Color(0xFF64748B)),
              titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
              titleMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              labelLarge: TextStyle(color: Color(0xFF0F172A)),
            ),
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
              onBackground: Color(0xFF0F172A),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0F172A),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), letterSpacing: 1),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFEFF2F7),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              labelStyle: const TextStyle(color: Color(0xFF64748B)),
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            dividerColor: const Color(0xFFE2E8F0),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.grey.shade400),
              trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade300),
            ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
          ),
          // --- KARANLIK MOD TEMA AYARLARI ---
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.primary,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.surface,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 1),
            ),
            cardTheme: CardThemeData(
              color: AppColors.surface,
              elevation: 0,
              shadowColor: Colors.black38,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              labelStyle: const TextStyle(color: AppColors.textMuted),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
          ),
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