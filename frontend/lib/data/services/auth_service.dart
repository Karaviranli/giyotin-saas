import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login', 
        data: {
          "username": email,
          "password": password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        return true;
      }
      return false;
    } catch (e) {
      print("Login Hatası: $e");
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<bool> register(String fullName, String email, String password, String companyName) async {
    try {
      // Backend'deki kayıt endpointine istek atıyoruz (Endpoint adını backendine göre ayarlayabilirsin)
      final response = await _apiClient.dio.post(
        '/auth/register', // veya /users/register
        data: {
          "email": email,
          "password": password,
          "full_name": fullName,
          "company_name": companyName, // Eğer backend şirket adı bekliyorsa
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; // Kayıt başarılı
      }
      return false;
    } catch (e) {
      print("Kayıt Hatası: $e");
      return false;
    }
  }
}