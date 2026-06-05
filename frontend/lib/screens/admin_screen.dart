import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../main.dart';

// ─────────────────────────────────────────────
//  Admin Ekranı
// ─────────────────────────────────────────────
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _companiesData;
  List<Map<String, dynamic>> _promoCodes = [];

  bool _loadingStats = true;
  bool _loadingCompanies = true;
  bool _loadingPromo = true;
  String? _statsError;
  String? _companiesError;
  String? _promoError;

  int _currentPage = 1;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Promo form
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _durationDays = 30;
  int? _maxUses;
  bool _creatingPromo = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
    _loadCompanies();
    _loadPromoCodes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    try {
      final res = await dio.get('/api/v1/admin/stats');
      setState(() => _stats = Map<String, dynamic>.from(res.data));
    } catch (e) {
      setState(() => _statsError = _extractError(e));
    } finally {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadPromoCodes() async {
    setState(() { _loadingPromo = true; _promoError = null; });
    try {
      final res = await dio.get('/api/v1/admin/promo-codes');
      setState(() => _promoCodes = (res.data as List).cast<Map<String, dynamic>>());
    } catch (e) {
      setState(() => _promoError = _extractError(e));
    } finally {
      setState(() => _loadingPromo = false);
    }
  }

  Future<void> _createPromoCode() async {
    final code = _codeCtrl.text.trim().toUpperCase(); // boş olabilir — backend otomatik üretir
    setState(() => _creatingPromo = true);
    try {
      final res = await dio.post('/api/v1/admin/promo-codes', data: {
        'code': code.isEmpty ? null : code,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'duration_days': _durationDays,
        'max_uses': _maxUses,
      });
      final createdCode = res.data['code'] as String? ?? code;
      _codeCtrl.clear();
      _descCtrl.clear();
      setState(() { _durationDays = 30; _maxUses = null; });
      showCustomSnackBar(message: 'Kod oluşturuldu: $createdCode', isError: false);
      await _loadPromoCodes();
    } on DioException catch (_) {
    } finally {
      if (mounted) setState(() => _creatingPromo = false);
    }
  }

  Future<void> _deactivatePromoCode(int id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kodu Devre Dışı Bırak'),
        content: Text('"$code" kodunu devre dışı bırakmak istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Devre Dışı Bırak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await dio.delete('/api/v1/admin/promo-codes/$id');
      showCustomSnackBar(message: '$code devre dışı bırakıldı.', isError: false);
      await _loadPromoCodes();
    } on DioException catch (_) {}
  }

  Future<void> _loadCompanies({int page = 1}) async {
    setState(() {
      _loadingCompanies = true;
      _companiesError = null;
    });
    try {
      final res = await dio.get('/api/v1/admin/companies', queryParameters: {
        'page': page,
        'per_page': 20,
        'q': _searchQuery,
      });
      setState(() {
        _companiesData = Map<String, dynamic>.from(res.data);
        _currentPage = page;
      });
    } catch (e) {
      setState(() => _companiesError = _extractError(e));
    } finally {
      setState(() => _loadingCompanies = false);
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      return e.response?.data?['detail']?.toString() ?? e.message ?? 'Hata oluştu';
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Color(0xFF3B82F6), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Admin Paneli',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6)),
            tooltip: 'Yenile',
            onPressed: () {
              _loadStats();
              _loadCompanies(page: _currentPage);
              _loadPromoCodes();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: isDark ? Colors.white54 : const Color(0xFF64748B),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'İstatistikler'),
            Tab(icon: Icon(Icons.business_rounded, size: 18), text: 'Şirketler'),
            Tab(icon: Icon(Icons.local_offer_rounded, size: 18), text: 'Promo Kodlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(isDark),
          _buildCompaniesTab(isDark),
          _buildPromoTab(isDark),
        ],
      ),
    );
  }

  // ── İstatistikler sekmesi ──────────────────
  Widget _buildStatsTab(bool isDark) {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }
    if (_statsError != null) {
      return _buildError(_statsError!, _loadStats);
    }
    if (_stats == null) return const SizedBox();

    final s = _stats!;
    final subs = s['subscriptions'] as Map<String, dynamic>;
    final dailyRecords = (s['daily_records'] as List).cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFF3B82F6),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet kartlar
            _buildSectionTitle('Genel Bakış', isDark),
            const SizedBox(height: 10),
            _buildOverviewGrid(s, subs, isDark),
            const SizedBox(height: 24),

            // Abonelik dağılımı
            _buildSectionTitle('Abonelik Durumu', isDark),
            const SizedBox(height: 10),
            _buildSubscriptionBreakdown(subs, isDark),
            const SizedBox(height: 24),

            // 14 günlük trend
            _buildSectionTitle('Son 14 Gün — Hesaplama Trendi', isDark),
            const SizedBox(height: 10),
            _buildDailyChart(dailyRecords, isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(Map<String, dynamic> s, Map<String, dynamic> subs, bool isDark) {
    final items = [
      _StatCardData(
        label: 'Toplam Şirket',
        value: formatTRNumber(s['total_companies']),
        icon: Icons.business_rounded,
        color: const Color(0xFF3B82F6),
        sub: '+${s['new_companies_30']} son 30 gün',
      ),
      _StatCardData(
        label: 'Toplam Kullanıcı',
        value: formatTRNumber(s['total_users']),
        icon: Icons.people_rounded,
        color: const Color(0xFF8B5CF6),
        sub: '${s['total_companies']} şirkette',
      ),
      _StatCardData(
        label: 'Aktif Ödeme',
        value: formatTRNumber(subs['active_paid']),
        icon: Icons.verified_rounded,
        color: const Color(0xFF10B981),
        sub: '${subs['active_trial']} deneme sürümü',
      ),
      _StatCardData(
        label: 'Son 30 Gün Kayıt',
        value: formatTRNumber(s['records_last_30']),
        icon: Icons.content_cut_rounded,
        color: const Color(0xFFF59E0B),
        sub: '${s['records_last_7']} son 7 gün',
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 600 ? 4 : 2;
      final spacing = 12.0;
      final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items
            .map((item) => SizedBox(width: w, child: _StatCard(data: item, isDark: isDark)))
            .toList(),
      );
    });
  }

  Widget _buildSubscriptionBreakdown(Map<String, dynamic> subs, bool isDark) {
    final paid = (subs['active_paid'] as num).toInt();
    final trial = (subs['active_trial'] as num).toInt();
    final expired = (subs['expired'] as num).toInt();
    final total = paid + trial + expired;

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (paid > 0)
                    Expanded(
                      flex: paid,
                      child: Container(
                        height: 20,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  if (trial > 0)
                    Expanded(
                      flex: trial,
                      child: Container(
                        height: 20,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  if (expired > 0)
                    Expanded(
                      flex: expired,
                      child: Container(
                        height: 20,
                        color: const Color(0xFFEF4444).withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              _buildSubLegend('Aktif Ödeme', paid, const Color(0xFF10B981), isDark),
              const SizedBox(width: 16),
              _buildSubLegend('Deneme', trial, const Color(0xFF3B82F6), isDark),
              const SizedBox(width: 16),
              _buildSubLegend('Süresi Dolmuş', expired, const Color(0xFFEF4444), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubLegend(String label, int count, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyChart(List<Map<String, dynamic>> dailyRecords, bool isDark) {
    if (dailyRecords.isEmpty) {
      return const SizedBox();
    }

    final maxCount = dailyRecords
        .map((d) => (d['count'] as num).toInt())
        .reduce((a, b) => a > b ? a : b);

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: dailyRecords.map((d) {
            final count = (d['count'] as num).toInt();
            final heightFactor = maxCount > 0 ? count / maxCount : 0.0;
            final date = d['date'] as String;
            final isToday = dailyRecords.last == d;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (count > 0)
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? const Color(0xFF3B82F6)
                              : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                        ),
                      ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: heightFactor > 0 ? (heightFactor * 90).clamp(4.0, 90.0) : 3,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF3B82F6)
                            : (count > 0
                                ? const Color(0xFF3B82F6).withOpacity(0.4)
                                : (isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFE2E8F0))),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 8,
                        color: isToday
                            ? const Color(0xFF3B82F6)
                            : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Şirketler sekmesi ──────────────────────
  Widget _buildCompaniesTab(bool isDark) {
    return Column(
      children: [
        // Arama
        Container(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Şirket adı ara...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B)),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _loadCompanies(page: 1);
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onSubmitted: (v) {
              setState(() => _searchQuery = v.trim());
              _loadCompanies(page: 1);
            },
          ),
        ),

        // Liste
        Expanded(
          child: _loadingCompanies
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : _companiesError != null
                  ? _buildError(_companiesError!, () => _loadCompanies(page: _currentPage))
                  : _buildCompaniesList(isDark),
        ),
      ],
    );
  }

  Widget _buildCompaniesList(bool isDark) {
    if (_companiesData == null) return const SizedBox();
    final companies = (_companiesData!['companies'] as List)
        .cast<Map<String, dynamic>>();
    final total = _companiesData!['total'] as int;
    final pages = _companiesData!['pages'] as int;

    if (companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'Şirket bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCompanies(page: _currentPage),
      color: const Color(0xFF3B82F6),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Toplam bilgisi
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '$total şirket',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),

          // Şirket kartları
          ...companies.map((c) => _CompanyCard(data: c, isDark: isDark)),

          // Sayfalama
          if (pages > 1) ...[
            const SizedBox(height: 16),
            _buildPagination(pages, isDark),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Promo Kodlar Sekmesi ───────────────────
  Widget _buildPromoTab(bool isDark) {
    if (_loadingPromo) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }
    if (_promoError != null) {
      return _buildError(_promoError!, _loadPromoCodes);
    }

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return RefreshIndicator(
      onRefresh: _loadPromoCodes,
      color: const Color(0xFF3B82F6),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Yeni kod oluştur ──────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: AppColors.warning, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Yeni Kod Oluştur',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Kod girişi
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _PromoTextField(
                          controller: _codeCtrl,
                          label: 'Kod',
                          hint: 'Boş bırak → otomatik',
                          isDark: isDark,
                          bgColor: bgColor,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: _PromoTextField(
                          controller: _descCtrl,
                          label: 'Açıklama (isteğe bağlı)',
                          isDark: isDark,
                          bgColor: bgColor,
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Süre
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Süre (gün): $_durationDays',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                )),
                            Slider(
                              value: _durationDays.toDouble(),
                              min: 7,
                              max: 365,
                              divisions: 51,
                              activeColor: AppColors.warning,
                              inactiveColor: AppColors.warning.withOpacity(0.2),
                              onChanged: (v) => setState(() => _durationDays = v.round()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Max kullanım
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kullanım limiti: ${_maxUses == null ? "Sınırsız" : "$_maxUses kez"}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            Slider(
                              value: (_maxUses ?? 0).toDouble(),
                              min: 0,
                              max: 500,
                              divisions: 50,
                              activeColor: const Color(0xFF3B82F6),
                              inactiveColor: const Color(0xFF3B82F6).withOpacity(0.2),
                              onChanged: (v) => setState(() {
                                _maxUses = v == 0 ? null : v.round();
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _creatingPromo ? null : _createPromoCode,
                      icon: _creatingPromo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Kod Oluştur', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Mevcut kodlar ─────────────────────────
            Text(
              '${_promoCodes.length} kod',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            if (_promoCodes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.local_offer_outlined,
                          size: 48,
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz promosyon kodu yok',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._promoCodes.map((c) => _PromoCodeCard(
                    data: c,
                    isDark: isDark,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onDeactivate: () => _deactivatePromoCode(c['id'] as int, c['code'] as String),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int pages, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1
              ? () => _loadCompanies(page: _currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
          color: const Color(0xFF3B82F6),
        ),
        Text(
          '$_currentPage / $pages',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        IconButton(
          onPressed: _currentPage < pages
              ? () => _loadCompanies(page: _currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
          color: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white70 : const Color(0xFF475569),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Yardımcı veri sınıfı
// ─────────────────────────────────────────────
class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
  });
}

// ─────────────────────────────────────────────
//  İstatistik Kartı
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _StatCardData data;
  final bool isDark;

  const _StatCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.sub,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Şirket Kartı
// ─────────────────────────────────────────────
class _CompanyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _CompanyCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final sub = data['subscription'] as Map<String, dynamic>?;

    final isActivePaid = sub != null &&
        sub['is_active'] == true &&
        !['Deneme', 'Deneme Sürümü'].contains(sub['plan_name']);
    final isTrial = sub != null &&
        sub['is_active'] == true &&
        ['Deneme', 'Deneme Sürümü'].contains(sub['plan_name']);
    final isExpired = sub == null || sub['is_active'] == false;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isActivePaid) {
      statusColor = const Color(0xFF10B981);
      statusLabel = sub!['plan_name'] as String;
      statusIcon = Icons.verified_rounded;
    } else if (isTrial) {
      statusColor = const Color(0xFF3B82F6);
      statusLabel = 'Deneme';
      statusIcon = Icons.hourglass_bottom_rounded;
    } else {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Süresi Dolmuş';
      statusIcon = Icons.block_rounded;
    }

    final lastActivity = data['last_activity'] as String?;
    String lastActivityStr = 'Hiç kayıt yok';
    if (lastActivity != null) {
      try {
        final dt = DateTime.parse(lastActivity).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inDays == 0) {
          lastActivityStr = 'Bugün';
        } else if (diff.inDays == 1) {
          lastActivityStr = 'Dün';
        } else {
          lastActivityStr = '${diff.inDays} gün önce';
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  getInitials(data['name'] as String?),
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] as String? ?? '-',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data['admin_email'] as String? ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Durum badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 11, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Alt bilgiler
          Row(
            children: [
              _InfoChip(
                icon: Icons.people_outline_rounded,
                label: '${data['user_count']} kullanıcı',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.content_cut_rounded,
                label: '${data['record_count']} kayıt',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: lastActivityStr,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Promo Kod TextField
// ─────────────────────────────────────────────
class _PromoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isDark;
  final Color bgColor;
  final Color borderColor;

  const _PromoTextField({
    required this.controller,
    required this.label,
    this.hint,
    required this.isDark,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1E293B),
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.warning, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Promo Kod Kartı
// ─────────────────────────────────────────────
class _PromoCodeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onDeactivate;

  const _PromoCodeCard({
    required this.data,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = data['is_active'] == true;
    final code = data['code'] as String;
    final description = data['description'] as String?;
    final durationDays = data['duration_days'] as int;
    final maxUses = data['max_uses'];
    final usedCount = data['used_count'] as int;
    final expiresAt = data['expires_at'] as String?;

    String expiresStr = 'Süresiz';
    if (expiresAt != null) {
      try {
        final dt = DateTime.parse(expiresAt).toLocal();
        expiresStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }

    final usageStr = maxUses == null
        ? '$usedCount kullanım'
        : '$usedCount / $maxUses kullanım';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? borderColor : AppColors.danger.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Kod badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.warning.withOpacity(0.12)
                  : AppColors.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: TextStyle(
                color: isActive ? AppColors.warning : AppColors.danger,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 10,
                  children: [
                    Text(
                      '$durationDays gün',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      usageStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      'Bitiş: $expiresStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Durum + deactivate
          if (!isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Devre Dışı',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.block_rounded, color: AppColors.danger, size: 18),
              tooltip: 'Devre Dışı Bırak',
              onPressed: onDeactivate,
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}
