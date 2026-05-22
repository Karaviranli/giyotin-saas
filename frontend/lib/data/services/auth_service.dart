import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<void> login(String email, String password) async {
    final formData = FormData.fromMap({
      'username': email,
      'password': password,
    });

    final response = await _dio.post('/api/v1/auth/login', data: formData);
    final token = response.data['access_token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<String> register({
    required String fullName,
    required String email,
    required String companyName,
    required String password,
    required String passwordConfirm,
  }) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'full_name': fullName,
      'email': email,
      'company_name': companyName,
      'password': password,
      'password_confirm': passwordConfirm,
    });
    return response.data is Map ? (response.data['message'] ?? "Kayıt Başarılı!") : "Kayıt Başarılı!";
  }

  Future<void> resetPassword({required String token, required String newPassword, required String passwordConfirm}) async {
    await _dio.post('/api/v1/auth/reset-password', data: {
      'token': token,
      'new_password': newPassword,
      'password_confirm': passwordConfirm,
    });
  }
}