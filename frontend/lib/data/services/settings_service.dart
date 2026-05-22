import 'package:dio/dio.dart';

class SettingsService {
  final Dio _dio;

  SettingsService(this._dio);

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _dio.get('/api/v1/giyotin/settings');
    return response.data;
  }

  Future<void> saveSettings(Map<String, double> settings) async {
    await _dio.post('/api/v1/giyotin/settings', data: settings);
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get('/api/v1/auth/me');
    return response.data;
  }

  Future<void> updateUserProfile(String fullName, String email) async {
    await _dio.put('/api/v1/auth/me', data: {'full_name': fullName, 'email': email});
  }

  Future<void> updatePassword(String currentPassword, String newPassword, String confirmPassword) async {
    await _dio.put('/api/v1/auth/me/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'password_confirm': confirmPassword,
    });
  }
}