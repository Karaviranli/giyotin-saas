import 'package:dio/dio.dart';

class GiyotinService {
  final Dio _dio;

  GiyotinService(this._dio);

  Future<Map<String, dynamic>> hesapla({
    required String projectName,
    required String systemType,
    required double width,
    required double height,
    required int quantity,
    double stockLength = 6500.0,
    double kerf = 5.0,
  }) async {
    try {
      final response = await _dio.post('/api/v1/giyotin/calculate', data: {
        "project_name": projectName,
        "system_type": systemType,
        "width": width,
        "height": height,
        "quantity": quantity,
        "stock_length": stockLength,
        "kerf": kerf,
      });
      return response.data; // Optimizasyon çıktısını döndürür
    } catch (e) {
      rethrow; // Hatayı interceptor'ın yakalaması için yukarı fırlatıyoruz
    }
  }

  Future<List<dynamic>> getRecords() async {
    final response = await _dio.get('/api/v1/giyotin/records');
    return response.data;
  }

  Future<void> deleteRecord(int recordId) async {
    await _dio.delete('/api/v1/giyotin/records/$recordId');
  }

  Future<List<int>> getPdfReport(int recordId) async {
    final response = await _dio.get(
      '/api/v1/giyotin/report/$recordId',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }
}