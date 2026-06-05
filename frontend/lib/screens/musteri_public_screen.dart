import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/app_config.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/auth_screens.dart';

/// /app/musteri — Giriş gerektirmeyen hızlı teklif ekranı.
/// Müşteriler ölçü girip anında fiyat tahmini alabilir.
class MusteriPublicScreen extends StatefulWidget {
  const MusteriPublicScreen({super.key});

  @override
  State<MusteriPublicScreen> createState() => _MusteriPublicScreenState();
}

class _MusteriPublicScreenState extends State<MusteriPublicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();
  final _qCtrl = TextEditingController(text: '1');

  bool _loading = false;
  String _error = '';
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _hesapla() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; _result = null; });

    final _publicDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
    try {
      final res = await _publicDio.post('/api/v1/giyotin/public-quote', data: {
        'width':    double.parse(_wCtrl.text.replaceAll(',', '.')),
        'height':   double.parse(_hCtrl.text.replaceAll(',', '.')),
        'quantity': int.parse(_qCtrl.text),
      });
      setState(() { _result = Map<String, dynamic>.from(res.data); _loading = false; });
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Hesaplama hatası.';
      if (data is Map) {
        final detail = data['detail'];
        msg = detail is List ? detail.map((e) => e['msg']).join(', ') : detail?.toString() ?? msg;
      }
      setState(() { _error = msg; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Sunucuya bağlanılamadı. Lütfen tekrar deneyin.'; _loading = false; });
    }
  }

  void _yenidenHesapla() => setState(() { _result = null; _error = ''; });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.background : const Color(0xFFF1F5F9);
    final card   = isDark ? AppColors.surface    : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Icon(Icons.window_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text('Kavira',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 1)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Hızlı Teklif',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Giriş Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Hero
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calculate_outlined, color: Colors.white70, size: 28),
                      const SizedBox(height: 10),
                      const Text('Anlık Fiyat Tahmini',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'Giyotin cam sisteminizin ölçülerini girin, saniyeler içinde fiyat alın.',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form veya Sonuç
                if (_result == null) _formCard(card) else _resultCard(card),

                // Hata
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                      GestureDetector(
                        onTap: () => setState(() => _error = ''),
                        child: const Icon(Icons.close, color: AppColors.danger, size: 16),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 24),
                // CTA
                _ctaCard(card),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard(Color card) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: card, borderRadius: BorderRadius.circular(16),
      boxShadow: AppColors.cardShadow,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Sistem Ölçüleri',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Ölçüleri milimetre (mm) cinsinden girin.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _numField(_wCtrl, 'Genişlik (mm)', min: 150, max: 10000)),
            const SizedBox(width: 12),
            Expanded(child: _numField(_hCtrl, 'Yükseklik (mm)', min: 264, max: 10000)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            child: _numField(_qCtrl, 'Sistem Adedi', isInt: true, min: 1, max: 50),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _hesapla,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.bolt, size: 18),
              label: Text(_loading ? 'Hesaplanıyor...' : 'FİYAT AL',
                  style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _numField(TextEditingController ctrl, String label,
      {bool isInt = false, double min = 0, double max = double.infinity}) =>
    TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Zorunlu';
        final n = double.tryParse(v.replaceAll(',', '.'));
        if (n == null) return 'Sayı girin';
        if (n < min) return 'Min: ${min.toInt()}';
        if (n > max) return 'Max: ${max.toInt()}';
        return null;
      },
    );

  Widget _resultCard(Color card) {
    final r = _result!;
    final kdvHaric   = (r['kdv_haric_tl']    as num?)?.toDouble() ?? 0;
    final kdvTl      = (r['kdv_tl']           as num?)?.toDouble() ?? 0;
    final toplam     = (r['genel_toplam_tl']  as num?)?.toDouble() ?? 0;
    final birim      = (r['birim_fiyat_tl']   as num?)?.toDouble() ?? 0;
    final qty        = int.tryParse(_qCtrl.text) ?? 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            const SizedBox(width: 8),
            const Text('Fiyat Tahmininiz Hazır',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.success)),
          ]),
          const SizedBox(height: 4),
          Text(
            '${_wCtrl.text} × ${_hCtrl.text} mm  ·  $qty sistem',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          _fiyatSatir('Teklif fiyatı (KDV hariç)', formatTRCurrency(kdvHaric)),
          const Divider(height: 20),
          _fiyatSatir('KDV (%20)', formatTRCurrency(kdvTl)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Genel Toplam',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(formatTRCurrency(toplam),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
              ],
            ),
          ),
          if (qty > 1) ...[
            const SizedBox(height: 8),
            Center(
              child: Text('Sistem başı: ${formatTRCurrency(birim)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '* Bu fiyat piyasa varsayılan fiyatlarıyla hesaplanmış tahmini bir değerdir. '
              'Kesin fiyat için hesabınıza giriş yapın.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _yenidenHesapla,
            child: const Text('YENİDEN HESAPLA'),
          ),
        ],
      ),
    );
  }

  Widget _fiyatSatir(String label, String val) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    ],
  );

  Widget _ctaCard(Color card) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: card, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        const Text('Daha Fazlası İçin',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        const Text(
          'Kesim planı, Excel raporu, kayıt ve geçmiş için ücretsiz hesap açın.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Giriş Yap'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Ücretsiz Dene'),
            ),
          ),
        ]),
      ],
    ),
  );
}
