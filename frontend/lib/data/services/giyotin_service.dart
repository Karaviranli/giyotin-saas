class GiyotinService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> hesapla(double width, double height, int quantity) async {
    try {
      final response = await _api.dio.post('/giyotin/calculate', data: {
        "width": width,
        "height": height,
        "quantity": quantity
      });
      return response.data; // Optimizasyon çıktısını döndürür
    } catch (e) {
      throw Exception('Hesaplama başarısız: $e');
    }
  }
}