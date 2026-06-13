import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../main.dart';
import 'home_screens.dart' show HomeScreen;

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

  // ── Veri Havuzu (insights) ──
  Map<String, dynamic>? _insights;
  bool _loadingInsights = true;
  String? _insightsError;

  // ── Tedarikçi yönetimi ──
  List<dynamic> _vendors = [];
  Map<int, Map<String, dynamic>> _vendorDetails = {};   // vendor_id → tam detay
  int? _expandedVendorId;
  bool _loadingVendors = true;
  String? _vendorsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Y7: Admin yetkisi olmayanı redirect et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isSuper = userNotifier.value?['is_superuser'] == true;
      if (!isSuper) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu sayfaya erişim yetkiniz yok.'), backgroundColor: Colors.red),
        );
        Navigator.of(context).pushReplacementNamed('/');
        return;
      }
    });
    _loadStats();
    _loadCompanies();
    _loadPromoCodes();
    _loadInsights();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() { _loadingVendors = true; _vendorsError = null; });
    try {
      final res = await dio.get('/api/v1/vendors');
      if (mounted) setState(() {
        _vendors = (res.data['vendors'] as List?) ?? [];
        _loadingVendors = false;
      });
    } catch (e) {
      if (mounted) setState(() { _vendorsError = e.toString(); _loadingVendors = false; });
    }
  }

  Future<void> _loadVendorDetail(int vendorId) async {
    try {
      final res = await dio.get('/api/v1/admin/vendors/$vendorId/detail');
      if (mounted) setState(() {
        _vendorDetails[vendorId] = Map<String, dynamic>.from(res.data);
      });
    } catch (_) {}
  }

  Future<void> _loadInsights() async {
    setState(() { _loadingInsights = true; _insightsError = null; });
    try {
      final res = await dio.get('/api/v1/admin/insights');
      if (mounted) setState(() { _insights = res.data as Map<String, dynamic>; _loadingInsights = false; });
    } catch (e) {
      if (mounted) setState(() { _insightsError = e.toString(); _loadingInsights = false; });
    }
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
    final bgColor = isDark ? const Color(0xFF0F172A) : AppColors.background;

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
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.primary, size: 20),
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
          tooltip: 'Panele Dön',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
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
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white54 : const Color(0xFF64748B),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'İstatistikler'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'Veri Havuzu'),
            Tab(icon: Icon(Icons.factory_rounded, size: 18), text: 'Tedarikçiler'),
            Tab(icon: Icon(Icons.business_rounded, size: 18), text: 'Şirketler'),
            Tab(icon: Icon(Icons.local_offer_rounded, size: 18), text: 'Promo Kodlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(isDark),
          _buildInsightsTab(isDark),
          _buildVendorsTab(isDark),
          _buildCompaniesTab(isDark),
          _buildPromoTab(isDark),
        ],
      ),
    );
  }

  // ── İstatistikler sekmesi ──────────────────
  Widget _buildStatsTab(bool isDark) {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
      color: AppColors.primary,
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
        label: 'Toplam �?irket',
        value: formatTRNumber(s['total_companies']),
        icon: Icons.business_rounded,
        color: AppColors.primary,
        sub: '+${s['new_companies_30']} son 30 gün',
      ),
      _StatCardData(
        label: 'Toplam Kullanıcı',
        value: formatTRNumber(s['total_users']),
        icon: Icons.people_rounded,
        color: AppColors.accent,
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
                        color: AppColors.primary,
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
              _buildSubLegend('Deneme', trial, AppColors.primary, isDark),
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
                              ? AppColors.primary
                              : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                        ),
                      ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: heightFactor > 0 ? (heightFactor * 90).clamp(4.0, 90.0) : 3,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary
                            : (count > 0
                                ? AppColors.primary.withOpacity(0.4)
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
                            ? AppColors.primary
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

  // ── �?irketler sekmesi ──────────────────────
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
              hintText: '�?irket adı ara...',
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
                  : AppColors.background,
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
                  child: CircularProgressIndicator(color: AppColors.primary))
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
              '�?irket bulunamadı',
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
      color: AppColors.primary,
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

          // �?irket kartları
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

  // ═══════════════════════════════════════════════════════════════════
  // TEDARİKÇİ YÖNETİMİ SEKMESİ — vendor + system + profil CRUD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildVendorsTab(bool isDark) {
    if (_loadingVendors) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_vendorsError != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(_vendorsError!, style: TextStyle(color: Colors.red.shade400)),
      ));
    }

    return RefreshIndicator(
      onRefresh: _loadVendors,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Icon(Icons.factory_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text("Tedarikçi Yönetimi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showVendorEditDialog(isDark, null),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text("Yeni Tedarikçi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
          const SizedBox(height: 18),

          // Vendor listesi
          if (_vendors.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text("Henüz tedarikçi yok",
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
            ))
          else for (final v in _vendors) _vendorCard(v as Map<String, dynamic>, isDark),
        ]),
      ),
    );
  }

  Widget _vendorCard(Map<String, dynamic> v, bool isDark) {
    final vId = v['id'] as int;
    final isExpanded = _expandedVendorId == vId;
    final detail = _vendorDetails[vId];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
      ),
      child: Column(children: [
        // ── Üst başlık (tıklanır)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              if (isExpanded) {
                setState(() => _expandedVendorId = null);
              } else {
                setState(() => _expandedVendorId = vId);
                if (detail == null) await _loadVendorDetail(vId);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: v['is_default'] == true
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                      : const LinearGradient(colors: [AppColors.primary, Color(0xFF2E4058)]),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(child: Text(
                    v['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  )),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(v['name'].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (v['is_default'] == true) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("VARSAYILAN",
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (v['is_active'] == false) Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("PASİF",
                        style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text("${v['system_count']} sistem · slug: ${v['slug']}",
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                  ),
                ])),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                  onPressed: () => _showVendorEditDialog(isDark, v),
                  tooltip: 'Düzenle',
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isDark ? Colors.white54 : Colors.black54),
              ]),
            ),
          ),
        ),
        // ── Açıldığında: sistemler + profiller
        if (isExpanded) ...[
          const Divider(height: 1, color: Color(0x14000000)),
          if (detail == null) const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ) else _vendorDetailBody(detail, isDark),
        ],
      ]),
    );
  }

  Widget _vendorDetailBody(Map<String, dynamic> detail, bool isDark) {
    final systems = (detail['systems'] as List?) ?? [];
    final vendorId = detail['id'] as int;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text("Sistemler", style: TextStyle(fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showSystemEditDialog(isDark, vendorId, null),
            icon: const Icon(Icons.add, size: 14),
            label: const Text("Sistem Ekle", style: TextStyle(fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 6),
        if (systems.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text("Sistem yok — ekleyin",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12))),
        for (final s in systems) _systemSection(s as Map<String, dynamic>, vendorId, isDark),
      ]),
    );
  }

  Widget _systemSection(Map<String, dynamic> s, int vendorId, bool isDark) {
    final profiles = (s['profiles'] as List?) ?? [];
    final sysId = s['id'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Icon(Icons.view_module_rounded, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${s['name']} · ${s['sub_category'] ?? '-'}",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87)),
              Text("${profiles.length} profil · stok boy ${s['profile_length_mm']?.toString() ?? '-'}mm · prefix ${s['code_prefix'] ?? '-'}",
                style: TextStyle(fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black54)),
            ])),
            IconButton(
              icon: const Icon(Icons.upload_file, size: 16, color: Color(0xFF8B5CF6)),
              onPressed: () => _showBulkProfilesDialog(isDark, sysId, vendorId),
              tooltip: 'CSV Yükle',
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
              onPressed: () => _showProfileEditDialog(isDark, sysId, vendorId, null),
              tooltip: 'Profil Ekle',
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.amber),
              onPressed: () => _showSystemEditDialog(isDark, vendorId, s),
              tooltip: 'Sistemi Düzenle',
            ),
          ]),
        ),
        if (profiles.isNotEmpty) ...[
          const Divider(height: 1, color: Color(0x14000000)),
          // Profil tablosu
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(children: [
                // Başlık
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                  child: Row(children: [
                    SizedBox(width: 90, child: Text("KOD", style: _thStyle(isDark))),
                    Expanded(flex: 3, child: Text("İSİM", style: _thStyle(isDark))),
                    SizedBox(width: 110, child: Text("ROL", style: _thStyle(isDark))),
                    SizedBox(width: 65, child: Text("KG/M", style: _thStyle(isDark), textAlign: TextAlign.end)),
                    const SizedBox(width: 60),
                  ]),
                ),
                for (final p in profiles) _profileRow(p as Map<String, dynamic>, sysId, vendorId, isDark),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  TextStyle _thStyle(bool isDark) => TextStyle(
    fontSize: 10, fontWeight: FontWeight.w800,
    color: isDark ? Colors.white60 : Colors.black54,
    letterSpacing: 0.4,
  );

  Widget _profileRow(Map<String, dynamic> p, int sysId, int vendorId, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04))),
      ),
      child: Row(children: [
        SizedBox(width: 90, child: Text(p['code'].toString(),
          style: TextStyle(fontFamily: 'monospace', fontSize: 11,
            color: AppColors.primary, fontWeight: FontWeight.w700))),
        Expanded(flex: 3, child: Text(p['name'].toString(),
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87),
          overflow: TextOverflow.ellipsis)),
        SizedBox(width: 110, child: Text(p['role']?.toString() ?? '-',
          style: TextStyle(fontFamily: 'monospace', fontSize: 9,
            color: isDark ? Colors.white60 : Colors.black54),
          overflow: TextOverflow.ellipsis)),
        SizedBox(width: 65, child: Text(p['kg_per_m']?.toString() ?? '0',
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87))),
        SizedBox(width: 60, child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: const Icon(Icons.edit, size: 14, color: Colors.amber),
            onPressed: () => _showProfileEditDialog(isDark, sysId, vendorId, p),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
            onPressed: () => _confirmDeleteProfile(p['id'] as int, p['code'].toString(), vendorId),
          ),
        ])),
      ]),
    );
  }

  // ── DIALOG'LAR ──────────────────────────────────────────────────
  Future<void> _showVendorEditDialog(bool isDark, Map<String, dynamic>? existing) async {
    final slugCtrl = TextEditingController(text: existing?['slug']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final webCtrl = TextEditingController(text: existing?['website']?.toString() ?? '');
    bool isDefault = existing?['is_default'] == true;
    bool isActive = existing?['is_active'] != false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDlg) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(existing == null ? "Yeni Tedarikçi" : "Tedarikçi Düzenle"),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (existing == null) TextField(
            controller: slugCtrl,
            decoration: const InputDecoration(labelText: "Slug (kısa kod)", hintText: "ornek: tumen"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: "Firma Adı", hintText: "Ornek: Tümen Alüminyum"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: webCtrl,
            decoration: const InputDecoration(labelText: "Web Sitesi (opsiyonel)"),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: isDefault, dense: true, contentPadding: EdgeInsets.zero,
            title: const Text("Varsayılan", style: TextStyle(fontSize: 13)),
            subtitle: const Text("Yeni şirketlere otomatik atanır", style: TextStyle(fontSize: 10)),
            onChanged: (v) => setStateDlg(() => isDefault = v),
          ),
          if (existing != null) SwitchListTile(
            value: isActive, dense: true, contentPadding: EdgeInsets.zero,
            title: const Text("Aktif", style: TextStyle(fontSize: 13)),
            onChanged: (v) => setStateDlg(() => isActive = v),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              try {
                if (existing == null) {
                  await dio.post('/api/v1/admin/vendors', data: {
                    'slug': slugCtrl.text.trim(),
                    'name': nameCtrl.text.trim(),
                    'website': webCtrl.text.trim().isEmpty ? null : webCtrl.text.trim(),
                    'is_default': isDefault,
                  });
                } else {
                  await dio.put('/api/v1/admin/vendors/${existing['id']}', data: {
                    'name': nameCtrl.text.trim(),
                    'website': webCtrl.text.trim().isEmpty ? null : webCtrl.text.trim(),
                    'is_default': isDefault, 'is_active': isActive,
                  });
                }
                if (mounted) Navigator.pop(ctx);
                await _loadVendors();
              } catch (_) {}
            },
            child: const Text("Kaydet"),
          ),
        ],
      )),
    );
  }

  Future<void> _showSystemEditDialog(bool isDark, int vendorId, Map<String, dynamic>? existing) async {
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final subCtrl = TextEditingController(text: existing?['sub_category']?.toString() ?? '');
    final prefCtrl = TextEditingController(text: existing?['code_prefix']?.toString() ?? '');
    final lenCtrl = TextEditingController(text: (existing?['profile_length_mm'] ?? 6500).toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(existing == null ? "Yeni Sistem" : "Sistem Düzenle"),
        content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Sistem Adı", hintText: "Klasik Giyotin")),
          const SizedBox(height: 10),
          TextField(controller: subCtrl, decoration: const InputDecoration(labelText: "Alt Kategori (slug)", hintText: "klasik / silinebilir")),
          const SizedBox(height: 10),
          TextField(controller: prefCtrl, decoration: const InputDecoration(labelText: "Kod Prefix (UI gösterim)", hintText: "K-14, V.GY.1, 145")),
          const SizedBox(height: 10),
          TextField(
            controller: lenCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Stok Boy (mm)"),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              try {
                final body = {
                  'name': nameCtrl.text.trim(),
                  'sub_category': subCtrl.text.trim().isEmpty ? null : subCtrl.text.trim(),
                  'code_prefix': prefCtrl.text.trim().isEmpty ? null : prefCtrl.text.trim(),
                  'profile_length_mm': double.tryParse(lenCtrl.text) ?? 6500,
                };
                if (existing == null) {
                  await dio.post('/api/v1/admin/vendors/$vendorId/systems',
                    data: {'category': 'giyotin', ...body});
                } else {
                  await dio.put('/api/v1/admin/systems/${existing['id']}', data: body);
                }
                if (mounted) Navigator.pop(ctx);
                await _loadVendorDetail(vendorId);
              } catch (_) {}
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileEditDialog(bool isDark, int systemId, int vendorId, Map<String, dynamic>? existing) async {
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final roleCtrl = TextEditingController(text: existing?['role']?.toString() ?? '');
    final kgCtrl = TextEditingController(text: (existing?['kg_per_m'] ?? 0).toString());
    final orderCtrl = TextEditingController(text: (existing?['sort_order'] ?? 0).toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(existing == null ? "Yeni Profil" : "Profil Düzenle"),
        content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Kod", hintText: "K-1401, 14506, V.GY.106")),
          const SizedBox(height: 10),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "İsim", hintText: "Motor Kutusu Alt")),
          const SizedBox(height: 10),
          TextField(controller: roleCtrl, decoration: const InputDecoration(
            labelText: "Rol (hesap mantığı için)",
            hintText: "MOTOR_KUTUSU_ALT, ALT_KASA, YAN_KASA, ...",
          )),
          const SizedBox(height: 10),
          TextField(
            controller: kgCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: "Kg/m", hintText: "1.293"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: orderCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Sıra"),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              try {
                final body = {
                  'code': codeCtrl.text.trim(),
                  'name': nameCtrl.text.trim(),
                  'role': roleCtrl.text.trim().isEmpty ? null : roleCtrl.text.trim().toUpperCase(),
                  'kg_per_m': double.tryParse(kgCtrl.text.replaceAll(',', '.')) ?? 0,
                  'sort_order': int.tryParse(orderCtrl.text) ?? 0,
                };
                if (existing == null) {
                  await dio.post('/api/v1/admin/systems/$systemId/profiles', data: body);
                } else {
                  await dio.put('/api/v1/admin/profiles/${existing['id']}', data: body);
                }
                if (mounted) Navigator.pop(ctx);
                await _loadVendorDetail(vendorId);
              } catch (_) {}
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Future<void> _showBulkProfilesDialog(bool isDark, int systemId, int vendorId) async {
    final csvCtrl = TextEditingController(
      text: "code,name,role,kg_per_m,sort_order\n",
    );
    bool replace = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDlg) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text("Toplu Profil Yükle (CSV)"),
        content: SizedBox(
          width: 520,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("CSV formatı (virgül veya tab ile):",
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "code,name,role,kg_per_m,sort_order\nK-1401,Motor Kutusu Alt,MOTOR_KUTUSU_ALT,1.293,0",
                style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: TextField(
                controller: csvCtrl,
                maxLines: null, expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: "code,name,role,kg_per_m,sort_order",
                  filled: true,
                  fillColor: (isDark ? Colors.black : Colors.grey.shade100).withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: replace, dense: true, contentPadding: EdgeInsets.zero,
              title: const Text("Mevcut profilleri sil, baştan yükle",
                style: TextStyle(fontSize: 12)),
              onChanged: (v) => setStateDlg(() => replace = v == true),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              try {
                final r = await dio.post('/api/v1/admin/systems/$systemId/profiles/bulk',
                  data: {'csv_text': csvCtrl.text, 'replace': replace});
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Eklendi: ${r.data['added']}, Güncellendi: ${r.data['updated']}, Hata: ${(r.data['errors'] as List?)?.length ?? 0}"),
                    backgroundColor: Colors.green,
                  ));
                }
                await _loadVendorDetail(vendorId);
              } catch (_) {}
            },
            child: const Text("Yükle"),
          ),
        ],
      )),
    );
  }

  Future<void> _confirmDeleteProfile(int profileId, String code, int vendorId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Sil: $code?"),
        content: const Text("Bu profil silinecek. Geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.delete('/api/v1/admin/profiles/$profileId');
      await _loadVendorDetail(vendorId);
    } catch (_) {}
  }

  // ── Promo Kodlar Sekmesi ───────────────────
  Widget _buildPromoTab(bool isDark) {
    if (_loadingPromo) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_promoError != null) {
      return _buildError(_promoError!, _loadPromoCodes);
    }

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    final bgColor = isDark ? const Color(0xFF0F172A) : AppColors.background;

    return RefreshIndicator(
      onRefresh: _loadPromoCodes,
      color: AppColors.primary,
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
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.primary.withOpacity(0.2),
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
          color: AppColors.primary,
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
          color: AppColors.primary,
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════════════════
  // VERİ HAVUZU SEKMESİ — KVKK uyumlu agregat analitik
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildInsightsTab(bool isDark) {
    if (_loadingInsights) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_insightsError != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Text("İçgörüler yüklenemedi:\n$_insightsError",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInsights,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Tekrar Dene"),
          ),
        ]),
      );
    }
    if (_insights == null) return const SizedBox.shrink();

    final i = _insights!;
    final fin = (i['finansal'] as Map<String, dynamic>?) ?? {};
    final pm = (i['proje_metrikleri'] as Map<String, dynamic>?) ?? {};
    final eng = (i['engagement'] as Map<String, dynamic>?) ?? {};
    final saatlik = (i['saatlik_aktivite'] as List?)?.cast<num>().toList() ?? List.filled(24, 0);
    final sisDist = (i['sistem_dagilim'] as List?)?.cast<dynamic>() ?? [];
    final topProf = (i['top_profiller'] as List?)?.cast<dynamic>() ?? [];
    final yaklasan = (i['yaklasan_bitisler'] as List?)?.cast<dynamic>() ?? [];
    final bitenler = (i['son_bitenler'] as List?)?.cast<dynamic>() ?? [];
    final weekly = (i['haftalik_buyume'] as List?)?.cast<dynamic>() ?? [];

    return RefreshIndicator(
      onRefresh: _loadInsights,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(children: [
              Icon(Icons.analytics_rounded, color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              Text("Veri Havuzu",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: const Text("KVKK Uyumlu Agregat",
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _loadInsights,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ]),
            const SizedBox(height: 20),

            // ── FİNANSAL 4'lü ──
            _insightSectionTitle("💰 Finansal Performans", isDark),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (ctx, c) {
              final wide = c.maxWidth > 700;
              final items = [
                _insightMetric("Ortalama Proje Maliyeti", "${_fmtMoney(fin['ortalama_maliyet_tl'])} ₺",
                    Icons.payments_outlined, const Color(0xFF10B981), isDark),
                _insightMetric("Toplam Hesaplanan", "${_fmtMoney(fin['toplam_hesaplanmis_maliyet_tl'])} ₺",
                    Icons.summarize_rounded, AppColors.primary, isDark),
                _insightMetric("Son 30 Gün Hacmi", "${_fmtMoney(fin['son_30g_hesaplanmis_maliyet_tl'])} ₺",
                    Icons.calendar_month_rounded, const Color(0xFFF59E0B), isDark),
                _insightMetric("Ortalama Fire Payı", "%${fin['ortalama_fire_yuzde'] ?? 0}",
                    Icons.percent_rounded, const Color(0xFFEC4899), isDark),
              ];
              if (wide) {
                return Row(children: [for (int k = 0; k < items.length; k++)
                  ...[ if (k > 0) const SizedBox(width: 12), Expanded(child: items[k]) ]
                ]);
              }
              return Column(children: [for (int k = 0; k < items.length; k++)
                ...[ if (k > 0) const SizedBox(height: 10), items[k] ]
              ]);
            }),
            const SizedBox(height: 28),

            // ── PROJE METRİKLERİ ──
            _insightSectionTitle("📐 Proje Metrikleri", isDark),
            const SizedBox(height: 12),
            _insightCard(isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _kvRow("Ortalama Genişlik", "${pm['ort_genislik'] ?? 0} mm", isDark),
              _kvRow("Ortalama Yükseklik", "${pm['ort_yukseklik'] ?? 0} mm", isDark),
              _kvRow("Ortalama Sistem Adedi", "${pm['ort_adet'] ?? 0}", isDark),
              _kvRow("Maks Genişlik (rekor)", "${pm['max_genislik'] ?? 0} mm", isDark),
              _kvRow("Maks Yükseklik (rekor)", "${pm['max_yukseklik'] ?? 0} mm", isDark),
              _kvRow("Toplam Sistem (tüm zamanlar)", "${pm['toplam_sistem_adet'] ?? 0} adet", isDark, last: true),
            ])),
            const SizedBox(height: 28),

            // ── ENGAGEMENT SEGMENTS ──
            _insightSectionTitle("👥 Kullanıcı Segmentleri", isDark),
            const SizedBox(height: 12),
            _insightCard(isDark, child: Column(children: [
              _segmentRow("⚡ Power User (10+ hesap)", eng['power_users'] ?? 0,
                  eng['toplam_firma'] ?? 1, const Color(0xFFEC4899), isDark),
              _segmentRow("✅ Aktif (3-9 hesap)", eng['aktif'] ?? 0,
                  eng['toplam_firma'] ?? 1, const Color(0xFF10B981), isDark),
              _segmentRow("🌱 Yeni / Casual (1-2 hesap)", eng['casual'] ?? 0,
                  eng['toplam_firma'] ?? 1, AppColors.primary, isDark),
              _segmentRow("🧊 Sessiz (hiç hesap yok)", eng['sessiz'] ?? 0,
                  eng['toplam_firma'] ?? 1, const Color(0xFF94A3B8), isDark),
            ])),
            const SizedBox(height: 28),

            // ── SİSTEM TÜRÜ DA�?ILIMI ──
            if (sisDist.isNotEmpty) ...[
              _insightSectionTitle("🪟 Sistem Türü Dağılımı", isDark),
              const SizedBox(height: 12),
              _insightCard(isDark, child: Column(children: [
                for (final s in sisDist.take(8))
                  _segmentRow(
                    (s['sistem'] ?? 'Belirsiz').toString(),
                    s['adet'] ?? 0,
                    sisDist.fold<int>(0, (sum, e) => sum + ((e['adet'] ?? 0) as int)),
                    AppColors.accent, isDark),
              ])),
              const SizedBox(height: 28),
            ],

            // ── TOP PROFİLLER ──
            if (topProf.isNotEmpty) ...[
              _insightSectionTitle("🏆 En Çok Kullanılan Profiller (Top 10)", isDark),
              const SizedBox(height: 12),
              _insightCard(isDark, child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in topProf)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(p['kod']?.toString() ?? '-',
                          style: TextStyle(fontWeight: FontWeight.w700,
                              color: AppColors.primary, fontSize: 12)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("${p['frekans']}",
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
              ])),
              const SizedBox(height: 28),
            ],

            // ── SAATLİK AKTİVİTE ──
            _insightSectionTitle("⏰ Saatlik Aktivite (Son 30 Gün)", isDark),
            const SizedBox(height: 12),
            _insightCard(isDark, child: SizedBox(
              height: 140,
              child: _saatlikChart(saatlik, isDark),
            )),
            const SizedBox(height: 28),

            // ── HAFTALIK BÜYÜME ──
            if (weekly.isNotEmpty) ...[
              _insightSectionTitle("📈 Haftalık Büyüme (12 Hafta)", isDark),
              const SizedBox(height: 12),
              _insightCard(isDark, child: SizedBox(
                height: 160,
                child: _haftalikChart(weekly, isDark),
              )),
              const SizedBox(height: 28),
            ],

            // ── YAKLA�?AN BİTİ�?LER ──
            _insightSectionTitle("⏳ Yaklaşan Süre Bitişleri (7 gün)", isDark),
            const SizedBox(height: 12),
            if (yaklasan.isEmpty)
              _insightCard(isDark, child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text(
                  "Bu hafta süresi dolacak abonelik yok g�?�",
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                )),
              ))
            else
              _insightCard(isDark, child: Column(children: [
                for (final s in yaklasan)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business_rounded, size: 14, color: Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text("Firma #${s['company_id']}",
                          style: TextStyle(fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87))),
                      Text("${s['gun_kaldi']} gün",
                          style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                    ]),
                  ),
              ])),
            const SizedBox(height: 20),

            // ── YAKIN ZAMANDA SÜRESİ DOLANLAR ──
            _insightSectionTitle("g��? Son 7 Gün İçinde Süresi Dolanlar", isDark),
            const SizedBox(height: 12),
            if (bitenler.isEmpty)
              _insightCard(isDark, child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text(
                  "Yakın zamanda süresi dolan yok",
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                )),
              ))
            else
              _insightCard(isDark, child: Column(children: [
                for (final s in bitenler)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.access_time_rounded, size: 14, color: Colors.red),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text("Firma #${s['company_id']}",
                          style: TextStyle(fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87))),
                      Text("${s['gun_once']} gün önce",
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ]),
                  ),
              ])),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──
  String _fmtMoney(dynamic v) {
    final n = v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '0') ?? 0);
    if (n.abs() >= 1000000) return "${(n / 1000000).toStringAsFixed(2)}M";
    if (n.abs() >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toStringAsFixed(0);
  }

  Widget _insightSectionTitle(String t, bool isDark) => Text(t,
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : Colors.black87));

  Widget _insightCard(bool isDark, {required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
    ),
    child: child,
  );

  Widget _insightMetric(String label, String value, IconData icon, Color color, bool isDark) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87)),
      ]),
    );

  Widget _kvRow(String k, String v, bool isDark, {bool last = false}) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Column(children: [
      Row(children: [
        Expanded(child: Text(k, style: TextStyle(fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black54))),
        Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87)),
      ]),
      if (!last) Padding(padding: const EdgeInsets.only(top: 8), child: Divider(
        height: 1, color: (isDark ? Colors.white : Colors.black).withOpacity(0.08))),
    ]),
  );

  Widget _segmentRow(String name, int count, int total, Color color, bool isDark) {
    final pct = total > 0 ? (count / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87))),
          Text("$count", style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
          const SizedBox(width: 6),
          Text("(%${pct.toStringAsFixed(0)})", style: TextStyle(fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(
          value: pct / 100,
          backgroundColor: color.withOpacity(0.1),
          color: color,
          minHeight: 6,
        )),
      ]),
    );
  }

  Widget _saatlikChart(List<num> saatlik, bool isDark) {
    final maxV = saatlik.isEmpty ? 1 : saatlik.reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(builder: (ctx, c) {
      final barW = c.maxWidth / 24 - 2;
      return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (int h = 0; h < 24; h++)
          Container(
            width: barW,
            margin: const EdgeInsets.only(right: 2),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                height: maxV > 0 ? (saatlik[h] / maxV * 100).toDouble().clamp(2, 100) : 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (h % 3 == 0) ...[
                const SizedBox(height: 4),
                Text("$h", style: TextStyle(fontSize: 9,
                    color: isDark ? Colors.white54 : Colors.black45)),
              ] else const SizedBox(height: 14),
            ]),
          ),
      ]);
    });
  }

  Widget _haftalikChart(List<dynamic> weekly, bool isDark) {
    final maxRec = weekly.fold<int>(0, (m, w) {
      final v = (w['kayit'] ?? 0) as int;
      return v > m ? v : m;
    });
    return LayoutBuilder(builder: (ctx, c) {
      final barW = c.maxWidth / weekly.length - 4;
      return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final w in weekly)
          Container(
            width: barW,
            margin: const EdgeInsets.only(right: 4),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text("${w['kayit']}",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 2),
              Container(
                height: maxRec > 0
                  ? ((w['kayit'] ?? 0) / maxRec * 120).toDouble().clamp(2, 120)
                  : 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text("${w['hafta']}", style: TextStyle(fontSize: 9,
                  color: isDark ? Colors.white54 : Colors.black45)),
            ]),
          ),
      ]);
    });
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
//  �?irket Kartı
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
      statusColor = AppColors.primary;
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
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  getInitials(data['name'] as String?),
                  style: const TextStyle(
                    color: AppColors.primary,
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
