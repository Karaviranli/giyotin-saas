import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/home_screens.dart';
import 'package:frontend/data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final authService = AuthService(dio);
      await authService.login(emailController.text, passwordController.text);

      if (mounted) {
        showCustomSnackBar(message: "Giriş Başarılı! Yönlendiriliyorsunuz...", isError: false);
        // Kullanıcıyı Anasayfaya yönlendiriyoruz
        // pushReplacement kullanıyoruz ki kullanıcı 'Geri' tuşuyla tekrar giriş ekranına düşmesin
        final prefs = await SharedPreferences.getInstance();
        final isFirstTime = prefs.getBool('is_first_time') ?? true;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => isFirstTime ? const OnboardingScreen() : const HomeScreen()),
        );
      }
    } on DioException catch (_) {
      // Hata zaten Interceptor tarafından merkezi olarak yönetiliyor.
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Şifremi Unuttum"),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Kayıtlı E-posta Adresiniz", hintText: "ornek@sirket.com"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await dio.post('/api/v1/auth/forgot-password', data: {"email": emailCtrl.text.trim()});
                if (mounted) showCustomSnackBar(message: "Sıfırlama bağlantısı e-posta adresinize gönderildi.", isError: false);
              } catch (e) {
                // Hatalar interceptor'da yakalanıyor
              }
            },
            child: const Text("Bağlantı Gönder"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Ekranda ortalanmış kutu genişliği
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.architecture, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      const Text("Kavira SaaS", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Lütfen hesabınıza giriş yapın", style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'E-posta boş bırakılamaz';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Geçerli bir e-posta giriniz';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Şifre boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 30),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                            onPressed: login,
                            child: const Text("Giriş Yap"),
                          ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text("Şifremi Unuttum", style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: const Text("Hesabın yok mu? Kayıt Ol", style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  bool isLoading = false;

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
        showCustomSnackBar(message: "Şifreniz başarıyla güncellendi!", isError: false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on DioException catch (_) {
      // Hata Interceptor tarafından yönetiliyor
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Şifre Belirle")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Yeni Şifre', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Şifre gerekli';
                      if (value.length < 8) return 'Şifre en az 8 karakter olmalı';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordConfirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Şifre Tekrar', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value != passwordController.text) return 'Şifreler eşleşmiyor';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          child: const Text("Şifreyi Güncelle"),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    if (!_acceptedTerms) {
      showCustomSnackBar(message: "Lütfen Kullanıcı Sözleşmesi ve KVKK metnini onaylayın.", isError: true);
      setState(() => isLoading = false);
      return;
    }

    try {
      final authService = AuthService(dio);
      final message = await authService.register(
        fullName: nameController.text,
        email: emailController.text,
        companyName: companyController.text,
        password: passwordController.text,
        passwordConfirm: passwordConfirmController.text,
      );

      if (mounted) {
        showCustomSnackBar(message: message, isError: false);
        // Başarılı kayıttan sonra giriş ekranına dön
        Navigator.pop(context);
      }
    } on DioException catch (_) {
      // Hata zaten Interceptor tarafından yönetiliyor.
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Yeni Hesap Oluştur", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Ad Soyad'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Ad soyad gerekli' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'E-posta gerekli';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Geçerli bir e-posta giriniz';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: companyController,
                        decoration: const InputDecoration(labelText: 'Şirket Adı'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Şirket adı gerekli' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Şifre gerekli';
                          if (value.length < 8) return 'Şifre en az 8 karakter olmalı';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordConfirmController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Şifre Tekrar'),
                        validator: (value) {
                          if (value != passwordController.text) return 'Şifreler eşleşmiyor';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _acceptedTerms = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                              child: const Text("Kullanıcı Sözleşmesi'ni ve KVKK Aydınlatma Metni'ni okudum, onaylıyorum.", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                            onPressed: register,
                            child: const Text("Kayıt Ol"),
                          ),
                      const SizedBox(height: 16),
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Zaten hesabım var", style: TextStyle(color: AppColors.textMuted))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}