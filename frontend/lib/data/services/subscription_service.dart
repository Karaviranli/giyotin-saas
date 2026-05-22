import 'package:dio/dio.dart';

class SubscriptionService {
  final Dio _dio;

  SubscriptionService(this._dio);

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final response = await _dio.get('/api/v1/subscription/status');
    return response.data;
  }

  Future<String?> createCheckoutForm() async {
    final response = await _dio.post('/api/v1/subscription/checkout-form');
    return response.data['checkout_url'];
  }
}