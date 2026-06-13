import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/home_screens.dart' show AppShell, HomeScreen;
import 'package:frontend/data/services/giyotin_service.dart';

class GiyotinHistoryScreen extends StatefulWidget {
  const GiyotinHistoryScreen({super.key});

  @override
  State<GiyotinHistoryScreen> createState() => _GiyotinHistoryScreenState();
}

class _GiyotinHistoryScreenState extends State<GiyotinHistoryScreen> {
  List<dynamic> records = [];
  List<dynamic> filteredRecords = [];
  bool isLoading = true;
  late final GiyotinService _giyotinService;
  final TextEditingController _searchController = TextEditingController();
  Set<int> selectedIds = {};
  bool isSelectionMode = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _giyotinService = GiyotinService(dio);
    _fetchHistory();
    _searchController.addListener(_filterRecords);
    _checkHintStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkHintStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hideHint = prefs.getBool('hide_history_hint') ?? false;
    if (!hideHint && mounted) {
      setState(() => _showHint = true);
    }
  }

  void _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_history_hint', true);
    setState(() => _showHint = false);
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredRecords = records;
      } else {
        filteredRecords = records.where((record) {
          final projectName = record['project_name']?.toString().toLowerCase() ?? '';
          final systemType = record['system_type']?.toString().toLowerCase() ?? '';
          return projectName.contains(query) || systemType.contains(query);
        }).toList();
      }
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
      isSelectionMode = selectedIds.isNotEmpty;
    });
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await _giyotinService.getRecords();
      if (mounted) {
        setState(() {
          records = data;
          filteredRecords = data;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteRecord(int recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kaydı Sil"),
        content: const Text("Bu geçmiş hesaplama kaydını silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        await _giyotinService.deleteRecord(recordId);
        showCustomSnackBar(message: "Kayıt başarıyla silindi.", isError: false);
        _fetchHistory(); // Listeyi günceller
      } catch (_) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileR;
    return AppShell(
      activeRoute: "history",
      title: "Geçmiş İşler",
      actions: [
        if (records.isNotEmpty)
          IconButton(
            icon: Icon(isSelectionMode ? Icons.close_rounded : Icons.checklist_rounded),
            tooltip: isSelectionMode ? "Seçimi İptal Et" : "Çoklu Seçim",
            onPressed: () {
              setState(() {
                if (isSelectionMode) {
                  isSelectionMode = false;
                  selectedIds.clear();
                } else {
                  isSelectionMode = true;
                }
              });
            },
          ),
      ],
      floatingActionButton: selectedIds.length > 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final selectedRecords = records.where((r) => selectedIds.contains(r['id'])).toList();
                final castedRecords = selectedRecords.map((e) => Map<String, dynamic>.from(e)).toList();
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CombinedCutSimulationScreen(selectedRecords: castedRecords)));
                // Eğer kayıt başarılı olduysa (result == true), listeyi yenileyip seçimleri kaldır
                if (result == true) {
                  setState(() {
                    selectedIds.clear();
                    isSelectionMode = false;
                  });
                  _fetchHistory();
                }
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.merge_type, color: Colors.white),
              label: Text("${selectedIds.length} İşi Birleştir", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text("Henüz bir hesaplama kaydı bulunmuyor.", style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_showHint && records.isNotEmpty)
                      Container(
                        margin: EdgeInsets.all(isMobile ? 16.0 : 24.0).copyWith(bottom: 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.info),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("İpucu: Toplu Kesim Optimizasyonu", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.info, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text("Birden fazla işi seçerek 'Birleşik Kesim' yapabilir ve profilden tasarruf edebilirsiniz. Başlamak için kartlara basılı tutun veya üstteki 'Çoklu Seçim' butonuna tıklayın.", style: TextStyle(fontSize: 13, color: AppColors.text.withOpacity(0.9), height: 1.4)),
                                ],
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.info),
                              onPressed: _dismissHint,
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Proje veya Sistem Türü Ara...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredRecords.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  const Text("Aradığınız kritere uygun kayıt bulunamadı.", style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredRecords.length,
                              itemBuilder: (context, index) {
                                final record = filteredRecords[index];
                                return _buildHistoryCard(record);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    final isCombined = record['system_type'] == "BİRLEŞİK KESİM";
    final iconColor = isCombined ? AppColors.info : AppColors.primary;
    final iconData = isCombined ? Icons.merge_type_rounded : Icons.assignment_turned_in_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(record['id']);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GiyotinDetailScreen(record: record)));
              }
            },
            onLongPress: () => _toggleSelection(record['id']),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  if (isSelectionMode) ...[
                    Checkbox(
                      value: selectedIds.contains(record['id']),
                      onChanged: (val) => _toggleSelection(record['id']),
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(iconData, color: iconColor)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record['project_name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        isCombined ? const Text("Toplu Optimizasyon Raporu", style: TextStyle(fontSize: 13, color: AppColors.info, fontWeight: FontWeight.bold))
                            : Text("${record['width']} x ${record['height']} mm  •  ${record['quantity']} Sistem", style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_rounded, color: AppColors.primary),
                        tooltip: "PDF Önizle",
                        splashRadius: 24,
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(recordId: record['id'], projectName: record['project_name']))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                        tooltip: "Sil",
                        splashRadius: 24,
                        onPressed: () => _deleteRecord(record['id']),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CombinedCutSimulationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedRecords;
  const CombinedCutSimulationScreen({super.key, required this.selectedRecords});

  @override
  State<CombinedCutSimulationScreen> createState() => _CombinedCutSimulationScreenState();
}

class _CombinedCutSimulationScreenState extends State<CombinedCutSimulationScreen> {
  final TextEditingController stockController = TextEditingController(text: "6500");
  final TextEditingController kerfController = TextEditingController(text: "5");
  Map<String, dynamic>? _cutOptimization;
  int _originalTotalStock = 0;
  double _originalTotalProfileCost = 0.0;
  bool _isSaving = false;

  final List<Color> _barRenkleri = const [
    Color(0xFF3498db), Color(0xFFe74c3c), Color(0xFF9b59b6),
    Color(0xFF1abc9c), Color(0xFFf1c40f), Color(0xFFe67e22), Color(0xFF34495e),
  ];

  @override
  void initState() {
    super.initState();
    _calculateOriginalStats();
    _optimize();
  }

  void _calculateOriginalStats() {
    int total = 0;
    double cost = 0.0;
    for (var r in widget.selectedRecords) {
      final opt = r['cut_optimization'] ?? {};
      total += (opt['toplam_stok'] as num?)?.toInt() ?? 0;
      final costDetails = r['cost_details'] ?? {};
      cost += (costDetails['total_profile_cost'] as num?)?.toDouble() ?? 0.0;
    }
    _originalTotalStock = total;
    _originalTotalProfileCost = cost;
  }

  void _optimize() {
    final double stockLength = double.tryParse(stockController.text) ?? 6500.0;
    final double kerf = double.tryParse(kerfController.text) ?? 5.0;

    Map<String, List<Map<String, dynamic>>> groupedPieces = {};

    // Tüm seçili işlerin profillerini havuza topla
    for (var record in widget.selectedRecords) {
      final String projName = record['project_name']?.toString() ?? 'İsimsiz';
      final cutOpt = record['cut_optimization'] ?? {};
      final kodlar = cutOpt['kodlar'] as Map<String, dynamic>? ?? {};

      for (var entry in kodlar.entries) {
        final kod = entry.key;
        final rapor = entry.value as Map<String, dynamic>;
        final bins = rapor['bins'] as List<dynamic>? ?? [];

        for (var bin in bins) {
          final pieces = bin['pieces'] as List<dynamic>? ?? [];
          for (var p in pieces) {
            final newP = Map<String, dynamic>.from(p);
            newP['project_name'] = projName; // Parçaya proje adını iliştir
            groupedPieces.putIfAbsent(kod, () => []).add(newP);
          }
        }
      }
    }

    Map<String, dynamic> newKodlar = {};
    int newTotalStock = 0;
    double newTotalFire = 0.0;

    // Havuzdaki parçaları 1D Bin Packing ile grupla
    for (var entry in groupedPieces.entries) {
      final kod = entry.key;
      final pieces = entry.value;

      final bins = _run1DBinPacking(pieces, stockLength, kerf);
      final stokSayisi = bins.length;
      final kodFire = bins.fold(0.0, (sum, b) => sum + (b['waste'] as num));

      newKodlar[kod] = {
        "bins": bins,
        "stok_adedi": stokSayisi,
        "fire_mm": double.parse(kodFire.toStringAsFixed(2))
      };

      newTotalStock += stokSayisi;
      newTotalFire += kodFire;
    }

    setState(() {
      _cutOptimization = {
        "kodlar": newKodlar,
        "toplam_stok": newTotalStock,
        "toplam_fire": newTotalFire
      };
    });
  }

  List<Map<String, dynamic>> _run1DBinPacking(List<Map<String, dynamic>> pieces, double stockLength, double kerf) {
    pieces.sort((a, b) => (b['length'] as num).compareTo(a['length'] as num));
    List<List<Map<String, dynamic>>> bins = [];

    for (var p in pieces) {
      double pTotal = (p['length'] as num).toDouble() + kerf;
      int fit = -1;
      double minL = double.infinity;

      for (int i = 0; i < bins.length; i++) {
        double binTotal = bins[i].fold(0.0, (sum, item) => sum + (item['length'] as num).toDouble() + kerf);
        double l = stockLength - (binTotal + pTotal);
        if (l >= 0 && l < minL) {
          minL = l;
          fit = i;
        }
      }

      if (fit != -1) {
        bins[fit].add(p);
      } else {
        bins.add([p]);
      }
    }

    List<Map<String, dynamic>> res = [];
    for (var b in bins) {
      double waste = stockLength - b.fold(0.0, (sum, item) => sum + (item['length'] as num).toDouble() + kerf);
      b.sort((a, b) => (b['length'] as num).compareTo(a['length'] as num));
      res.add({
        'pieces': b,
        'waste': double.parse(waste.toStringAsFixed(2))
      });
    }

    res.sort((a, b) => (a['waste'] as num).compareTo(b['waste'] as num));
    return res;
  }

  Future<void> _saveCombinedRecord() async {
    if (_cutOptimization == null) return;

    final controller = TextEditingController(text: "Birleşik Proje (${widget.selectedRecords.length} İş)");
    final projectName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Birleşik İşi Kaydet"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Proje Adı"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );

    if (projectName == null || projectName.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      double totalAcc = 0, cam = 0, overhead = 0;
      for(var r in widget.selectedRecords) {
         final c = r['cost_details'] ?? {};
         totalAcc += (c['total_accessory_cost'] as num?)?.toDouble() ?? 0;
         cam += (c['cam_cost'] as num?)?.toDouble() ?? 0;
         overhead += (c['overhead'] as num?)?.toDouble() ?? 0;
      }

      final int newTotalStock = _cutOptimization!['toplam_stok'] ?? 0;
      final int savedStock = _originalTotalStock - newTotalStock;
      final double avgCostPerStock = _originalTotalStock > 0 ? _originalTotalProfileCost / _originalTotalStock : 0.0;
      final double savedTL = savedStock * avgCostPerStock;

      final newProfileCost = _originalTotalProfileCost - savedTL;
      final newTotalCost = newProfileCost + totalAcc + cam + overhead;

      final combinedCostDetails = {
        "total_profile_cost": double.parse(newProfileCost.toStringAsFixed(2)),
        "total_accessory_cost": double.parse(totalAcc.toStringAsFixed(2)),
        "cam_cost": double.parse(cam.toStringAsFixed(2)),
        "overhead": double.parse(overhead.toStringAsFixed(2)),
        "total_cost": double.parse(newTotalCost.toStringAsFixed(2)),
      };

      await dio.post('/api/v1/giyotin/save-combined', data: {
        "project_name": projectName,
        "cost_details": combinedCostDetails,
        "cut_optimization": _cutOptimization,
      });

      if (mounted) {
        showCustomSnackBar(message: "Birleşik proje başarıyla kaydedildi!", isError: false);
        Navigator.pop(context, true); 
      }
    } catch (e) {
      // Hata zaten Interceptor tarafından gösteriliyor
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final double stockLength = double.tryParse(stockController.text) ?? 6500.0;
    final kodlar = _cutOptimization?['kodlar'] as Map<String, dynamic>? ?? {};
    final int newTotalStock = _cutOptimization?['toplam_stok'] ?? 0;
    final int savedStock = _originalTotalStock - newTotalStock;
    
    final double avgCostPerStock = _originalTotalStock > 0 ? _originalTotalProfileCost / _originalTotalStock : 0.0;
    final double savedTL = savedStock * avgCostPerStock;
    final double savingsPercent = _originalTotalStock > 0 ? (savedStock / _originalTotalStock) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Birleşik Kesim Optimizasyonu (${widget.selectedRecords.length} İş)"),
        actions: [
          if (_cutOptimization != null)
            _isSaving
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                : IconButton(
                    icon: const Icon(Icons.save_rounded),
                    tooltip: "Projeyi Kaydet",
                    onPressed: _saveCombinedRecord,
                  ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: TextFormField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok Boyu (mm)', isDense: true))),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(controller: kerfController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bıçak Fire (mm)', isDense: true))),
                      const SizedBox(width: 16),
                      ElevatedButton(onPressed: _optimize, child: const Text("Yeniden Hesapla"))
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 240, 
                      child: _buildStatCard("Ayrı Kesilseydi", "$_originalTotalStock Profil\n${_originalTotalProfileCost.toStringAsFixed(0)} ₺", Icons.inventory_2_outlined, AppColors.textMuted)
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 240, 
                      child: _buildStatCard("Toplu Optimize", "$newTotalStock Profil\n${(_originalTotalProfileCost - savedTL).toStringAsFixed(0)} ₺", Icons.check_circle_outline, AppColors.info)
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 240, 
                      child: _buildStatCard(
                        "Tasarruf (%${savingsPercent.toStringAsFixed(1)})", 
                        "$savedStock Profil\n+${savedTL.toStringAsFixed(0)} ₺ Kar", 
                        Icons.savings_outlined, 
                        savedStock > 0 ? AppColors.success : AppColors.warning
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...kodlar.entries.map((entry) {
                  final kod = entry.key;
                  final rapor = entry.value as Map<String, dynamic>;
                  final bins = rapor['bins'] as List<dynamic>? ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text(kod, style: const TextStyle(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Text("${rapor['stok_adedi']} Profil", style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...bins.asMap().entries.map((binEntry) {
                          final binIndex = binEntry.key + 1;
                          final waste = (binEntry.value['waste'] as num).toDouble();
                          final pieces = binEntry.value['pieces'] as List<dynamic>? ?? [];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.textMuted.withOpacity(0.2))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text("BAR #$binIndex", style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text("${pieces.length} parça", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (waste < stockLength * 0.05 ? AppColors.success : (waste < stockLength * 0.20 ? AppColors.warning : AppColors.danger)).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text("Fire: ${waste.toStringAsFixed(0)} mm  (%${(waste / stockLength * 100).toStringAsFixed(0)})",
                                        style: TextStyle(color: waste < stockLength * 0.05 ? AppColors.success : (waste < stockLength * 0.20 ? AppColors.warning : AppColors.danger), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ]),
                                const SizedBox(height: 10),
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.textMuted.withOpacity(0.25))),
                                  clipBehavior: Clip.antiAlias,
                                  child: LayoutBuilder(
                                    builder: (ctx, c) {
                                      final oran = c.maxWidth / stockLength;
                                      final wasteW = waste * oran;
                                      return Row(
                                        children: [
                                          ...pieces.asMap().entries.map((pEntry) {
                                            final lenVal = (pEntry.value['length'] as num).toDouble();
                                            // minimum 14px görünürlük garanti
                                            final w = (lenVal * oran).clamp(14.0, c.maxWidth);
                                            final renk = _barRenkleri[pEntry.key % _barRenkleri.length];
                                            final projectName = pEntry.value['project_name'] ?? '';
                                            return Tooltip(
                                              message: "${projectName.isNotEmpty ? 'Proje: $projectName\n' : ''}Ölçü: ${lenVal.toStringAsFixed(0)} mm",
                                              child: Container(
                                                width: w,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(colors: [renk, renk.withOpacity(0.75)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                                  border: Border(right: BorderSide(color: AppColors.background, width: 1.5)),
                                                ),
                                                alignment: Alignment.center,
                                                child: w > 40
                                                    ? Text("${lenVal.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, shadows: [Shadow(color: Colors.black45, blurRadius: 2)]))
                                                    : (w > 18 ? RotatedBox(quarterTurns: 0, child: Text("${(lenVal/100).toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))) : null),
                                              ),
                                            );
                                          }).toList(),
                                          // Fire bölümü — taranmış görünüm
                                          if (wasteW > 1) Expanded(
                                            child: Tooltip(
                                              message: "Fire (artık): ${waste.toStringAsFixed(0)} mm",
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.danger.withOpacity(0.10),
                                                ),
                                                alignment: Alignment.center,
                                                child: wasteW > 50 ? Text("fire", style: TextStyle(color: AppColors.danger.withOpacity(0.7), fontSize: 9, fontStyle: FontStyle.italic)) : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GiyotinDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  const GiyotinDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final costDetails = record['cost_details'] ?? {};
    final cutOptimization = record['cut_optimization'] ?? {};
    final kodlar = cutOptimization['kodlar'] as Map<String, dynamic>? ?? {};
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget buildAnimatedSection(Widget child, int index) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 150)),
        curve: Curves.easeOutCubic,
        builder: (context, value, wrappedChild) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(opacity: value, child: wrappedChild),
          );
        },
        child: child,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Hesaplama Detayı")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(recordId: record['id'], projectName: record['project_name'] ?? 'Rapor'))),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.visibility_rounded, color: Colors.white),
        label: const Text("PDF Önizle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildAnimatedSection(
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 24 : 32),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(record['project_name'] ?? 'İsimsiz Proje', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: Colors.white))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text(record['system_type'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(record['system_type'] == "BİRLEŞİK KESİM"
                            ? "Çoklu proje optimizasyonundan elde edilen verilerdir."
                            : "Ölçüler: ${record['width']} x ${record['height']} mm   •   Sistem Adedi: ${record['quantity']}", style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                        const SizedBox(height: 4),
                        Text("Tarih: ${record['created_at']?.toString().split('T').first ?? '-'}", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),
                0),
                const SizedBox(height: 32),
                // ── FİYATLANDIRMA HERO (4 KPI) ──
                if (costDetails['pricing'] != null) ...[
                  buildAnimatedSection(
                    _buildPricingHero(isMobile, costDetails['pricing'] as Map<String, dynamic>),
                  1),
                  const SizedBox(height: 24),
                  // ── FİYAT DÖKÜMÜ ──
                  buildAnimatedSection(
                    _buildPriceBreakdown(isMobile,
                      costDetails['pricing'] as Map<String, dynamic>,
                      (costDetails['maliyet_dagilim'] as List?) ?? []),
                  2),
                  const SizedBox(height: 24),
                ] else
                  buildAnimatedSection(
                    _buildDetailCard(isMobile, "Maliyet Analizi", Icons.payments_rounded, [
                      _buildInfoRow("Profil Maliyeti", "${costDetails['total_profile_cost']?.toStringAsFixed(2)} ₺"),
                      _buildInfoRow("Aksesuar & Motor", "${costDetails['total_accessory_cost']?.toStringAsFixed(2)} ₺"),
                      _buildInfoRow("Cam Maliyeti", "${costDetails['cam_cost']?.toStringAsFixed(2)} ₺"),
                      _buildInfoRow("Genel Gider", "${costDetails['overhead']?.toStringAsFixed(2)} ₺"),
                      const SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                        decoration: BoxDecoration(gradient: AppColors.gradientSuccess, borderRadius: BorderRadius.circular(16)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("TOPLAM MALİYET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("${costDetails['total_cost']?.toStringAsFixed(2)} ₺", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                      ),
                    ]),
                  1),
                const SizedBox(height: 24),
                // ── FİRE & VERİMLİLİK ──
                if (costDetails['fire_analizi'] != null) ...[
                  buildAnimatedSection(
                    _buildFireAnalysis(isMobile, costDetails['fire_analizi'] as Map<String, dynamic>),
                  3),
                  const SizedBox(height: 24),
                ],
                // ── MALZEME ÖZETİ ──
                if ((costDetails['malzeme_ozeti'] as List?)?.isNotEmpty ?? false) ...[
                  buildAnimatedSection(
                    _buildMaterialSummary(isMobile, costDetails['malzeme_ozeti'] as List),
                  4),
                  const SizedBox(height: 24),
                ],
                // ── İMALAT LİSTESİ — tedarikçinin reçetesindeki tüm profiller ──
                if ((costDetails['imalat_listesi'] as List?)?.isNotEmpty ?? false) ...[
                  buildAnimatedSection(
                    _buildDetailCard(isMobile, "İmalat Listesi", Icons.list_alt_rounded, [
                      // Üst başlık — vendor bilgisi
                      if (costDetails['vendor'] != null) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Icon(Icons.factory_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            "${costDetails['vendor']['vendor_name']} · ${costDetails['vendor']['system_name']}",
                            style: const TextStyle(
                              color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700,
                            ),
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              "${(costDetails['imalat_listesi'] as List).length} kalem",
                              style: TextStyle(
                                color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      // ÖLÇÜ UYARILARI (çok kısa parça vs)
                      if ((costDetails['olcu_uyarilari'] as List?)?.isNotEmpty ?? false) Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.report_problem_rounded, color: AppColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Text("⚠️ Şüpheli ölçüler", style: TextStyle(
                              color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 12)),
                          ]),
                          const SizedBox(height: 6),
                          ...(costDetails['olcu_uyarilari'] as List).map((u) {
                            final m = u as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text("• ${m['kod']} ${m['isim']}: sadece ${m['olcu_mm']}mm",
                                style: TextStyle(color: AppColors.danger, fontSize: 11)),
                            );
                          }).toList(),
                          const SizedBox(height: 4),
                          Text("Pencere ölçülerini kontrol et — büyük ihtimalle yanlış birim girdin.",
                            style: TextStyle(color: AppColors.danger.withOpacity(0.85), fontSize: 10)),
                        ]),
                      ),
                      // Eksik rol uyarısı (varsa)
                      if ((costDetails['eksik_roller'] as List?)?.isNotEmpty ?? false) Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            "Bu vendor'da ${(costDetails['eksik_roller'] as List).length} temel rol eksik — sonuç tam olmayabilir",
                            style: TextStyle(color: AppColors.warning, fontSize: 11),
                          )),
                        ]),
                      ),
                      // Tablo başlığı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(children: const [
                          SizedBox(width: 80, child: Text("KOD",
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                          Expanded(flex: 3, child: Text("PROFİL",
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                          SizedBox(width: 70, child: Text("ÖLÇÜ",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                          SizedBox(width: 45, child: Text("ADET",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                          SizedBox(width: 55, child: Text("KG/M",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      ...(costDetails['imalat_listesi'] as List).map((item) {
                        final m = item as Map<String, dynamic>;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(children: [
                            SizedBox(width: 80, child: Text(
                              m['kod']?.toString() ?? '-',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppColors.primary, fontFamily: 'monospace'),
                            )),
                            Expanded(flex: 3, child: Text(
                              m['isim']?.toString() ?? '-',
                              style: const TextStyle(fontSize: 11, color: AppColors.text),
                              overflow: TextOverflow.ellipsis,
                            )),
                            SizedBox(width: 70, child: Text(
                              "${m['olcu_mm']?.toString() ?? '0'} mm",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 11, color: AppColors.text.withOpacity(0.8)),
                            )),
                            SizedBox(width: 45, child: Text(
                              "${m['adet'] ?? 0}",
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text),
                            )),
                            SizedBox(width: 55, child: Text(
                              (m['kg_per_m'] as num?)?.toStringAsFixed(3) ?? '-',
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                            )),
                          ]),
                        );
                      }).toList(),
                    ]),
                  2),
                  const SizedBox(height: 32),
                ],
                // ── AKSESUAR LİSTESİ ──
                if ((costDetails['aksesuar_listesi'] as List?)?.isNotEmpty ?? false) ...[
                  buildAnimatedSection(
                    _buildDetailCard(isMobile, "Aksesuar Listesi", Icons.handyman_rounded, [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            "Köşe takozları, fitiller, kapaklar — sistemin tüm aksesuarı",
                            style: TextStyle(fontSize: 11, color: AppColors.text.withOpacity(0.8)),
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              "${(costDetails['aksesuar_listesi'] as List).length} kalem",
                              style: TextStyle(
                                color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(children: const [
                          Expanded(flex: 4, child: Text("AKSESUAR",
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                          SizedBox(width: 70, child: Text("MİKTAR",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                          SizedBox(width: 70, child: Text("BİRİM ₺",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                          SizedBox(width: 80, child: Text("TOPLAM ₺",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.textMuted, letterSpacing: 0.5))),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      ...(costDetails['aksesuar_listesi'] as List).map((item) {
                        final m = item as Map<String, dynamic>;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(children: [
                            Expanded(flex: 4, child: Text(
                              m['isim']?.toString() ?? '-',
                              style: const TextStyle(fontSize: 11, color: AppColors.text),
                              overflow: TextOverflow.ellipsis,
                            )),
                            SizedBox(width: 70, child: Text(
                              "${(m['miktar'] as num?)?.toStringAsFixed(m['birim'] == 'metre' ? 2 : 0) ?? '0'} ${m['birim'] ?? ''}",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 11, color: AppColors.text.withOpacity(0.85)),
                            )),
                            SizedBox(width: 70, child: Text(
                              "₺${(m['birim_tl'] as num?)?.toStringAsFixed(2) ?? '0'}",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                            )),
                            SizedBox(width: 80, child: Text(
                              "₺${(m['tl'] as num?)?.toStringAsFixed(2) ?? '0'}",
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                            )),
                          ]),
                        );
                      }).toList(),
                    ]),
                  3),
                  const SizedBox(height: 32),
                ],
                buildAnimatedSection(
                  _buildDetailCard(isMobile, "Kesim Planı & Optimizasyon", Icons.content_cut_rounded, [
                    isMobile 
                      ? Column(
                          children: [
                            _buildMiniStat("Toplam Profil", "${cutOptimization['toplam_stok'] ?? 0} Adet", Icons.inventory_2_outlined, AppColors.info),
                            const SizedBox(height: 16),
                            _buildMiniStat("Toplam Fire", "${cutOptimization['toplam_fire']?.toStringAsFixed(1) ?? '0'} mm", Icons.delete_outline, AppColors.danger),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildMiniStat("Toplam Profil", "${cutOptimization['toplam_stok'] ?? 0} Adet", Icons.inventory_2_outlined, AppColors.info)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildMiniStat("Toplam Fire", "${cutOptimization['toplam_fire']?.toStringAsFixed(1) ?? '0'} mm", Icons.delete_outline, AppColors.danger)),
                          ],
                        ),
                    const Divider(height: 32, color: AppColors.border),
                    ...kodlar.entries.map((entry) {
                      final kod = entry.key;
                      final rapor = entry.value as Map<String, dynamic>;
                      final bins = rapor['bins'] as List<dynamic>? ?? [];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(kod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                Text("${rapor['stok_adedi']} Profil", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...bins.asMap().entries.map((binEntry) {
                              final bin = binEntry.value;
                              final pieces = bin['pieces'] as List<dynamic>? ?? [];
                              final detay = pieces.map((p) {
                                final length = p['length'].toString();
                                final proj = p['project_name'];
                              }).join(' + ');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
                                      child: Text("#${binEntry.key + 1}", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(detay, style: const TextStyle(fontSize: 14, color: AppColors.text))),
                                    Text("Fire: ${bin['waste']}mm", style: TextStyle(fontSize: 13, color: (bin['waste'] as num) < 50 ? AppColors.success : AppColors.warning)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  ]),
                2),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(bool isMobile, String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PREMIUM ÜRETİM FİŞİ BİLEŞENLERİ
  // ═══════════════════════════════════════════════════════════════════
  static String _money(num? v, {int dec = 0}) {
    final n = (v ?? 0).toDouble();
    final neg = n < 0;
    final s = n.abs().toStringAsFixed(dec);
    final parts = s.split('.');
    final intp = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intp.length; i++) {
      if (i > 0 && (intp.length - i) % 3 == 0) buf.write('.');
      buf.write(intp[i]);
    }
    final res = dec > 0 ? '${buf.toString()},${parts[1]}' : buf.toString();
    return neg ? '-$res' : res;
  }

  // ── FİYATLANDIRMA HERO — 4 büyük KPI kartı ──
  Widget _buildPricingHero(bool isMobile, Map<String, dynamic> pricing) {
    final maliyet = (pricing['maliyet_tl'] as num?)?.toDouble() ?? 0;
    final kar = (pricing['kar_tl'] as num?)?.toDouble() ?? 0;
    final karY = (pricing['kar_yuzde'] as num?)?.toDouble() ?? 0;
    final satis = (pricing['satis_kdv_dahil_tl'] as num?)?.toDouble() ?? 0;
    final m2 = (pricing['m2_birim_fiyat_tl'] as num?)?.toDouble() ?? 0;

    final cards = [
      _PriceKpi("MALİYET", "₺${_money(maliyet)}", "üretim maliyeti",
          Icons.account_balance_wallet_rounded, AppColors.info, AppColors.gradientPrimary),
      _PriceKpi("KÂR (%${karY.toStringAsFixed(0)})", "₺${_money(kar)}", "brüt kazanç",
          Icons.trending_up_rounded, AppColors.success, AppColors.gradientSuccess),
      _PriceKpi("SATIŞ FİYATI", "₺${_money(satis)}", "KDV dahil",
          Icons.sell_rounded, AppColors.warning, AppColors.gradientWarning),
      _PriceKpi("m² BİRİM", "₺${_money(m2)}", "metrekare fiyatı",
          Icons.crop_square_rounded, AppColors.accent, AppColors.gradientAccent),
    ];

    Widget kpiCard(_PriceKpi d, int i) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + i * 110),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - v)), child: Opacity(opacity: v, child: child)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: d.color.withOpacity(0.28)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: d.gradient, borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: d.color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))]),
            child: Icon(d.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(d.label, style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(d.value, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
          const SizedBox(height: 2),
          Text(d.sub, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ]),
      ),
    );

    if (isMobile) {
      return Column(children: [
        Row(children: [Expanded(child: kpiCard(cards[0], 0)), const SizedBox(width: 12), Expanded(child: kpiCard(cards[1], 1))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: kpiCard(cards[2], 2)), const SizedBox(width: 12), Expanded(child: kpiCard(cards[3], 3))]),
      ]);
    }
    return Row(children: [
      for (int i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(width: 14),
        Expanded(child: kpiCard(cards[i], i)),
      ]
    ]);
  }

  // ── FİYAT DÖKÜMÜ — maliyet → kâr → KDV → satış (waterfall) ──
  Widget _buildPriceBreakdown(bool isMobile, Map<String, dynamic> pricing,
      List<dynamic> maliyetDagilim) {
    Widget satir(String l, String v, {Color? c, bool bold = false, bool big = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: bold ? 6 : 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(color: c ?? AppColors.text.withOpacity(0.85),
            fontSize: big ? 15 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
        Text(v, style: TextStyle(color: c ?? AppColors.text,
            fontSize: big ? 17 : 14, fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
      ]),
    );

    return _buildDetailCard(isMobile, "Fiyat Dökümü", Icons.receipt_long_rounded, [
      // Maliyet dağılımı çubukları
      ...maliyetDagilim.map((d) {
        final m = d as Map<String, dynamic>;
        final yuzde = (m['yuzde'] as num?)?.toDouble() ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("${m['label']}", style: TextStyle(color: AppColors.text.withOpacity(0.8), fontSize: 12)),
              Text("₺${_money(m['tl'])}  (%${yuzde.toStringAsFixed(0)})",
                  style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: yuzde / 100, minHeight: 5,
                  backgroundColor: AppColors.primary.withOpacity(0.08), color: AppColors.primary)),
          ]),
        );
      }).toList(),
      const Divider(height: 28, color: AppColors.border),
      satir("Toplam Maliyet", "₺${_money(pricing['maliyet_tl'])}", bold: true),
      satir("+ Kâr (%${(pricing['kar_yuzde'] as num?)?.toStringAsFixed(0)})",
          "₺${_money(pricing['kar_tl'])}", c: AppColors.success),
      satir("= Satış (KDV hariç)", "₺${_money(pricing['satis_kdv_haric_tl'])}", bold: true),
      satir("+ KDV (%${(pricing['kdv_yuzde'] as num?)?.toStringAsFixed(0)})",
          "₺${_money(pricing['kdv_tl'])}", c: AppColors.textMuted),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(gradient: AppColors.gradientSuccess,
            borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("MÜŞTERİ SATIŞ FİYATI", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          Text("₺${_money(pricing['satis_kdv_dahil_tl'])}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _miniMetric("Sistem Başı", "₺${_money(pricing['sistem_birim_fiyat_tl'])}", Icons.window_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _miniMetric("m² Birim", "₺${_money(pricing['m2_birim_fiyat_tl'])}", Icons.crop_square_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _miniMetric("Toplam Cam", "${_money(pricing['toplam_m2'], dec: 1)} m²", Icons.grid_view_rounded)),
      ]),
    ]);
  }

  Widget _miniMetric(String l, String v, IconData ic) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(ic, size: 14, color: AppColors.primary),
      const SizedBox(height: 6),
      Text(l, style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
      const SizedBox(height: 1),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(v, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w800))),
    ]),
  );

  // ── FİRE ANALİZİ — verimlilik göstergesi ──
  Widget _buildFireAnalysis(bool isMobile, Map<String, dynamic> fa) {
    final fy = (fa['ortalama_fire_yuzde'] as num?)?.toDouble() ?? 0;
    // Fire değerlendirme: <8 mükemmel, <12 iyi, <18 normal, üstü kötü
    final Color fc;
    final String etiket;
    if (fy < 8) { fc = AppColors.success; etiket = "Mükemmel"; }
    else if (fy < 12) { fc = AppColors.success; etiket = "İyi"; }
    else if (fy < 18) { fc = AppColors.warning; etiket = "Normal"; }
    else { fc = AppColors.danger; etiket = "Yüksek"; }

    return _buildDetailCard(isMobile, "Fire & Verimlilik Analizi", Icons.recycling_rounded, [
      Row(children: [
        // Fire % gauge
        SizedBox(
          width: 110, height: 110,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 110, height: 110,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (fy / 30).clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
                builder: (_, v, __) => CircularProgressIndicator(
                  value: v, strokeWidth: 10, backgroundColor: fc.withOpacity(0.12), color: fc),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text("%${fy.toStringAsFixed(1)}", style: TextStyle(color: fc, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(etiket, style: TextStyle(color: fc, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(children: [
          _fireRow("Satın Alınan", "${_money(fa['toplam_satin_alinan_m'], dec: 1)} m", "${fa['toplam_bar']} bar", AppColors.info),
          const Divider(height: 16, color: AppColors.border),
          _fireRow("Kullanılan", "${_money(fa['toplam_kullanilan_m'], dec: 1)} m", "${_money(fa['toplam_profil_kg'], dec: 1)} kg", AppColors.success),
          const Divider(height: 16, color: AppColors.border),
          _fireRow("Fire (Ziyan)", "${_money(fa['toplam_fire_m'], dec: 1)} m", "${_money(fa['fire_kg'], dec: 1)} kg", fc),
        ])),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fc.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fc.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(Icons.payments_outlined, color: fc, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text("Fire kaynaklı malzeme kaybı",
              style: TextStyle(color: AppColors.text.withOpacity(0.85), fontSize: 12))),
          Text("₺${_money(fa['fire_maliyet_tl'])}",
              style: TextStyle(color: fc, fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
      ),
    ]);
  }

  Widget _fireRow(String l, String v1, String v2, Color c) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(color: AppColors.text.withOpacity(0.8), fontSize: 12)),
      Row(children: [
        Text(v1, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Container(width: 1, height: 12, color: AppColors.textMuted.withOpacity(0.3)),
        const SizedBox(width: 8),
        SizedBox(width: 64, child: Text(v2, textAlign: TextAlign.end,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
      ]),
    ],
  );

  // ── MALZEME ÖZETİ — profil başı tablo (fire% renkli) ──
  Widget _buildMaterialSummary(bool isMobile, List<dynamic> ozet) {
    Color fireColor(double f) {
      if (f < 12) return AppColors.success;
      if (f < 20) return AppColors.warning;
      return AppColors.danger;
    }
    return _buildDetailCard(isMobile, "Malzeme Özeti", Icons.inventory_2_rounded, [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(6)),
        child: Row(children: const [
          SizedBox(width: 78, child: Text("KOD", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
          Expanded(child: Text("PROFİL", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
          SizedBox(width: 38, child: Text("BAR", textAlign: TextAlign.end, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
          SizedBox(width: 58, child: Text("KG", textAlign: TextAlign.end, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
          SizedBox(width: 50, child: Text("FİRE", textAlign: TextAlign.end, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
        ]),
      ),
      const SizedBox(height: 4),
      ...ozet.map((it) {
        final m = it as Map<String, dynamic>;
        final f = (m['fire_yuzde'] as num?)?.toDouble() ?? 0;
        final fcol = fireColor(f);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            SizedBox(width: 78, child: Text(m['kod']?.toString() ?? '-',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'monospace'))),
            Expanded(child: Text(m['isim']?.toString() ?? '-',
                style: const TextStyle(fontSize: 11, color: AppColors.text), overflow: TextOverflow.ellipsis)),
            SizedBox(width: 38, child: Text("${m['bar_adedi']}", textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text))),
            SizedBox(width: 58, child: Text("${_money(m['kg'], dec: 1)}", textAlign: TextAlign.end,
                style: TextStyle(fontSize: 11, color: AppColors.text.withOpacity(0.85)))),
            SizedBox(width: 50, child: Container(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: fcol.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text("%${f.toStringAsFixed(0)}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fcol)),
              ),
            )),
          ]),
        );
      }).toList(),
    ]);
  }
}

// Fiyat KPI veri sınıfı
class _PriceKpi {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final Gradient gradient;
  _PriceKpi(this.label, this.value, this.sub, this.icon, this.color, this.gradient);
}

class GiyotinScreen extends StatefulWidget {
  const GiyotinScreen({super.key});

  @override
  State<GiyotinScreen> createState() => _GiyotinScreenState();
}

class _GiyotinScreenState extends State<GiyotinScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController projectController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController stockController = TextEditingController(text: "6500");
  final TextEditingController kerfController = TextEditingController(text: "5");
  
  bool isLoading = false;
  String resultMessage = "";
  int? _calculatedRecordId;
  Map<String, dynamic>? _costDetails;
  Map<String, dynamic>? _cutOptimization;
  String _selectedSystemType = "3LÜ TEMİZLENİR";
  final List<String> _systemTypes = ["3LÜ TEMİZLENİR"]; // Şimdilik sadece 3'lü sistem aktif bırakıldı
  late final GiyotinService _giyotinService;
  final List<Color> _barRenkleri = const [
    Color(0xFF3498db), Color(0xFFe74c3c), Color(0xFF9b59b6),
    Color(0xFF1abc9c), Color(0xFFf1c40f), Color(0xFFe67e22), Color(0xFF34495e),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDraft();
    _giyotinService = GiyotinService(dio);
    projectController.addListener(_saveDraft);
    widthController.addListener(_saveDraft);
    heightController.addListener(_saveDraft);
    quantityController.addListener(_saveDraft);
    stockController.addListener(_saveDraft);
    kerfController.addListener(_saveDraft);
  }

  @override
  void dispose() {
    _tabController.dispose();
    projectController.removeListener(_saveDraft); projectController.dispose();
    widthController.removeListener(_saveDraft); widthController.dispose();
    heightController.removeListener(_saveDraft); heightController.dispose();
    quantityController.removeListener(_saveDraft); quantityController.dispose();
    stockController.removeListener(_saveDraft); stockController.dispose();
    kerfController.removeListener(_saveDraft); kerfController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      projectController.text = prefs.getString('giyotin_draft_project') ?? "";
      widthController.text = prefs.getString('giyotin_draft_width') ?? "";
      heightController.text = prefs.getString('giyotin_draft_height') ?? "";
      quantityController.text = prefs.getString('giyotin_draft_quantity') ?? "1";
      stockController.text = prefs.getString('giyotin_draft_stock') ?? "6500";
      kerfController.text = prefs.getString('giyotin_draft_kerf') ?? "5";
      
      final savedSystem = prefs.getString('giyotin_draft_system');
      if (savedSystem != null && _systemTypes.contains(savedSystem)) {
        _selectedSystemType = savedSystem;
      }
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('giyotin_draft_project', projectController.text);
    await prefs.setString('giyotin_draft_width', widthController.text);
    await prefs.setString('giyotin_draft_height', heightController.text);
    await prefs.setString('giyotin_draft_quantity', quantityController.text);
    await prefs.setString('giyotin_draft_system', _selectedSystemType);
    await prefs.setString('giyotin_draft_stock', stockController.text);
    await prefs.setString('giyotin_draft_kerf', kerfController.text);
  }

  Future<void> _clearDraft() async {
    setState(() {
      projectController.clear();
      widthController.clear();
      heightController.clear();
      quantityController.text = "1";
      stockController.text = "6500";
      kerfController.text = "5";
      _selectedSystemType = "3LÜ TEMİZLENİR";
      resultMessage = "";
      _calculatedRecordId = null;
      _costDetails = null;
      _cutOptimization = null;
    });
    _tabController.animateTo(0);
  }

  void calculate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      resultMessage = "Hesaplanıyor...";
      _costDetails = null;
      _cutOptimization = null;
    });

    final wMm = double.tryParse(widthController.text) ?? 0;
    final hMm = double.tryParse(heightController.text) ?? 0;
    // Birim hatası önleme: 200 mm altı tipik giyotin için anlamsız
    if (wMm < 500 || hMm < 1000) {
      if (mounted) {
        setState(() => isLoading = false);
        showCustomSnackBar(
          message: "Pencere boyutları çok küçük görünüyor. Genişlik en az 500mm, yükseklik 1000mm olmalı. Ölçüleri MM cinsinden girdiğinizden emin olun.",
          isError: true,
        );
      }
      return;
    }

    try {
      final responseData = await _giyotinService.hesapla(
        projectName: projectController.text,
        systemType: _selectedSystemType,
        width: wMm,
        height: hMm,
        quantity: int.tryParse(quantityController.text) ?? 1,
        stockLength: double.tryParse(stockController.text) ?? 6500.0,
        kerf: double.tryParse(kerfController.text) ?? 5.0,
      );

      if (mounted) {
        final recordId = responseData['record_id'];
        setState(() {
          _calculatedRecordId = recordId;
          _costDetails = responseData['cost_details'];
          _cutOptimization = responseData['cut_optimization'];
          resultMessage = "✅ Hesaplama Başarılı!";
        });
        // Zengin üretim fişini aç
        final recordMap = {
          'id': recordId,
          'project_name': projectController.text,
          'system_type': _selectedSystemType,
          'width': wMm,
          'height': hMm,
          'quantity': int.tryParse(quantityController.text) ?? 1,
          'created_at': DateTime.now().toIso8601String(),
          'cost_details': responseData['cost_details'],
          'cut_optimization': responseData['cut_optimization'],
        };
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => GiyotinDetailScreen(record: recordMap),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _calculatedRecordId = null);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildCostBadge(String label, dynamic value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("${value?.toString() ?? '0'} ₺", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFormGroup(bool isMobile, String title, IconData icon, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }

  /// Masaüstünde form + canlı önizleme yan yana; mobil/tablette tek sütun.
  Widget _formResponsive(BuildContext context, List<Widget> formChildren) {
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: formChildren,
    );
    if (!context.isDesktopR) return form;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: form),
        const SizedBox(width: 28),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildLivePreviewPanel(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreviewPanel(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widthController, heightController, quantityController]),
      builder: (context, _) {
        final w = double.tryParse(widthController.text) ?? 0;
        final h = double.tryParse(heightController.text) ?? 0;
        final qty = int.tryParse(quantityController.text) ?? 1;
        final m2 = (w * h) / 1000000.0;
        final hasDim = w > 0 && h > 0;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceHigh, AppColors.surface],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Text("Canlı Önizleme", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: AspectRatio(
                  aspectRatio: hasDim ? (w / h).clamp(0.32, 2.4) : 0.78,
                  child: CustomPaint(
                    painter: _GiyotinPreviewPainter(width: w, height: h),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _previewStat("Ölçü (G × Y)", hasDim ? "${w.toInt()} × ${h.toInt()} mm" : "— × — mm"),
              _previewStat("Birim Alan", m2 > 0 ? "${m2.toStringAsFixed(2)} m²" : "— m²"),
              _previewStat("Sistem Türü", _selectedSystemType),
              _previewStat("Sistem Adedi", "$qty adet"),
              if (m2 > 0) _previewStat("Toplam Cam Alanı", "${(m2 * qty).toStringAsFixed(2)} m²", highlight: true),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "3 panelli giyotin — ölçüler değiştikçe önizleme güncellenir.",
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _previewStat(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 15 : 13.5,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileR;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            }
          },
        ),
        title: const Text("Giyotin Hesaplama"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          isScrollable: isMobile,
          tabs: const [
            Tab(icon: Icon(Icons.edit_document), text: "Form Girdisi"),
            Tab(icon: Icon(Icons.analytics_outlined), text: "Maliyet Özeti"),
            Tab(icon: Icon(Icons.content_cut_rounded), text: "Kesim Simülasyonu"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(context.pagePad),
            child: Center(child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.isDesktopR ? 1120 : 580),
              child: Form(
                key: _formKey,
                child: _formResponsive(context, [
                      _buildFormGroup(isMobile, "Genel Bilgiler", Icons.assignment_outlined, [
                          TextFormField(
                            controller: projectController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Proje / Müşteri Adı'),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Proje adı gereklidir' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSystemType,
                            decoration: const InputDecoration(labelText: 'Sistem Türü'),
                            dropdownColor: AppColors.surface,
                            items: _systemTypes.map((String type) {
                              return DropdownMenuItem<String>(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedSystemType = newValue);
                                _saveDraft();
                              }
                            },
                          ),
                      ]),
                      _buildFormGroup(isMobile, "Sistem Ölçüleri", Icons.straighten_outlined, [
                          isMobile
                              ? Column(
                                  children: [
                                    TextFormField(
                                      controller: widthController,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Genişlik (mm)'),
                                      validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Geçerli bir değer girin' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: heightController,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Yükseklik (mm)'),
                                      validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Geçerli bir değer girin' : null,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: widthController,
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Genişlik (mm)'),
                                        validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Geçerli bir değer girin' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: heightController,
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Yükseklik (mm)'),
                                        validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Geçerli bir değer girin' : null,
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: quantityController,
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Sistem Adedi'),
                            validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Geçerli bir adet girin' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Stok Boyu (mm)'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: kerfController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Bıçak Fire (mm)'),
                                ),
                              ),
                            ],
                          ),
                      ]),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : calculate,
                        icon: isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.calculate_rounded),
                        label: Text(isLoading ? "Hesaplanıyor..." : "Hesapla ve Kaydet"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: isLoading ? null : _clearDraft,
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text("Taslağı Temizle"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(resultMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ListView(
                  children: [
                    if (_costDetails == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50.0),
                          child: Text(
                            "Henüz hesaplama yapılmadı.\nLütfen 'Form Girdisi' sekmesinden formu doldurup hesaplayın.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                          ),
                        ),
                      ),
                    if (_costDetails != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.payments_outlined, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text("Maliyet Özeti", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                              ],
                            ),
                            const Divider(height: 24, color: AppColors.border),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildCostBadge("Profil", _costDetails!['total_profile_cost'], AppColors.primary),
                                _buildCostBadge("Aks. & Motor", _costDetails!['total_accessory_cost'], AppColors.warning),
                                _buildCostBadge("Cam", _costDetails!['cam_cost'], AppColors.info),
                                _buildCostBadge("Genel Gider", _costDetails!['overhead'], AppColors.danger),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(gradient: AppColors.gradientSuccess, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("TOPLAM MALİYET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text("${_costDetails!['total_cost']} ₺", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_calculatedRecordId != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(recordId: _calculatedRecordId!, projectName: projectController.text))),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text("Raporu Önizle (PDF)"),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
            _buildCutSimulationTab(isMobile),
        ],
      ),
    );
  }

  Widget _buildCutSimulationTab(bool isMobile) {
    if (_cutOptimization == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50.0),
          child: Text(
            "Henüz hesaplama yapılmadı.\nLütfen 'Form Girdisi' sekmesinden hesaplayın.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
        ),
      );
    }

    final double stockLength = double.tryParse(stockController.text) ?? 6500.0;
    final kodlar = _cutOptimization!['kodlar'] as Map<String, dynamic>? ?? {};

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(child: _buildCostBadge("Toplam Profil", "${_cutOptimization!['toplam_stok'] ?? 0} Adet", AppColors.info)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCostBadge("Toplam Fire", "${_cutOptimization!['toplam_fire']?.toStringAsFixed(1) ?? '0'} mm", AppColors.warning)),
                ],
              ),
              const SizedBox(height: 24),
              ...kodlar.entries.map((entry) {
                final kod = entry.key;
                final rapor = entry.value as Map<String, dynamic>;
                final bins = rapor['bins'] as List<dynamic>? ?? [];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(kod, style: const TextStyle(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Text("${rapor['stok_adedi']} Profil", style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...bins.asMap().entries.map((binEntry) {
                        final binIndex = binEntry.key + 1;
                        final bin = binEntry.value;
                        final pieces = bin['pieces'] as List<dynamic>? ?? [];
                        final waste = (bin['waste'] as num).toDouble();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("PROFİL #$binIndex", style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text("Fire: ${waste.toStringAsFixed(0)} mm", style: TextStyle(color: waste < 100 ? AppColors.success : AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
                                ),
                                child: LayoutBuilder(
                                  builder: (ctx, c) {
                                    final oran = c.maxWidth / stockLength;
                                    return Row(
                                      children: pieces.asMap().entries.map((pEntry) {
                                        final pIndex = pEntry.key;
                                        final p = pEntry.value;
                                        final w = (p['length'] as num).toDouble() * oran;
                                        final renk = _barRenkleri[pIndex % _barRenkleri.length];
                                        return Tooltip(
                                          message: "${p['length']} mm",
                                          child: Container(
                                            width: w,
                                            decoration: BoxDecoration(color: renk, border: Border.all(color: AppColors.background)),
                                            alignment: Alignment.center,
                                            child: w > 35
                                                ? Text("${p['length']}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                                : null,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class PdfPreviewScreen extends StatefulWidget {
  final int recordId;
  final String projectName;
  const PdfPreviewScreen({super.key, required this.recordId, required this.projectName});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String _errorMessage = "";
  late final GiyotinService _giyotinService;

  @override
  void initState() {
    super.initState();
    _giyotinService = GiyotinService(dio);
    _fetchPdf();
  }

  Future<void> _fetchPdf() async {
    try {
      final pdfData = await _giyotinService.getPdfReport(widget.recordId);
      if (mounted) {
        setState(() {
          _pdfBytes = Uint8List.fromList(pdfData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "PDF yüklenemedi: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _downloadPdf() async {
    if (_pdfBytes == null) return;
    try {
      showCustomSnackBar(message: "PDF indiriliyor...", isError: false);
      await FileSaver.instance.saveFile(
        name: 'Kavira_Kesim_Plani_${widget.recordId}',
        bytes: _pdfBytes!,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      showCustomSnackBar(message: "PDF başarıyla indirildi!", isError: false);
    } catch (e) {
      showCustomSnackBar(message: "PDF indirilemedi: $e", isError: true);
    }
  }

  void _sharePdf() async {
    if (_pdfBytes == null) return;
    try {
      final xFile = XFile.fromData(
        _pdfBytes!,
        mimeType: 'application/pdf',
        name: 'Kavira_Kesim_Plani_${widget.recordId}.pdf',
      );
      await Share.shareXFiles([xFile], text: '${widget.projectName} - Kesim Planı Raporu');
    } catch (e) {
      showCustomSnackBar(message: "Paylaşılamadı: $e", isError: true);
    }
  }

  void _printPdf() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => _pdfBytes!,
        name: '${widget.projectName}_Raporu',
      );
    } catch (e) {
      showCustomSnackBar(message: "Yazdırılamadı: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.projectName} - Rapor"),
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: "Paylaş",
              onPressed: _sharePdf,
            ),
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: "Yazdır",
              onPressed: _printPdf,
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: "PDF İndir",
              onPressed: _downloadPdf,
            ),
          ]
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: AppColors.danger)))
              : PdfPreview(
                  build: (format) async => _pdfBytes!,
                  useActions: false, // Yukarıda kendi AppBar butonlarımız olduğu için kendi araç çubuğunu gizliyoruz
                ),
    );
  }
}

/// Giyotin penceresinin canlı şematik önizlemesini çizer (3 panelli + motor kutusu).
class _GiyotinPreviewPainter extends CustomPainter {
  final double width;
  final double height;
  _GiyotinPreviewPainter({required this.width, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    const Color frame = Color(0xFF9AA6B8);      // açık slate-gri çerçeve
    const Color frameDark = Color(0xFF6B7686);  // koyu çerçeve
    const Color glassTop = Color(0xFF3A4F6B);   // slate cam (üst)
    const Color glassBottom = Color(0xFF2A3A4F);// slate cam (alt)
    const Color primary = Color(0xFF3A4F6B);    // slate vurgu

    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = RRect.fromRectAndRadius(outer, const Radius.circular(8));

    // Dış kasa
    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [frame, frameDark],
        ).createShader(outer),
    );

    // Motor kutusu (üst bant)
    final motorH = size.height * 0.085;
    final motorRect = Rect.fromLTWH(0, 0, size.width, motorH);
    canvas.drawRRect(
      RRect.fromRectAndCorners(motorRect, topLeft: const Radius.circular(8), topRight: const Radius.circular(8)),
      Paint()..color = frameDark,
    );
    // Motor kutusu üzerinde ince accent çizgi
    canvas.drawLine(
      Offset(size.width * 0.12, motorH * 0.5),
      Offset(size.width * 0.88, motorH * 0.5),
      Paint()
        ..color = primary.withOpacity(0.5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // İç cam alanı
    final inset = size.width * 0.06;
    final glassArea = Rect.fromLTWH(
      inset,
      motorH + inset * 0.5,
      size.width - inset * 2,
      size.height - motorH - inset * 1.5,
    );

    // 3 panel
    const panelCount = 3;
    final gap = size.height * 0.012;
    final panelH = (glassArea.height - gap * (panelCount - 1)) / panelCount;
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [glassTop, glassBottom],
      ).createShader(glassArea);
    final mullion = Paint()
      ..color = frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (int i = 0; i < panelCount; i++) {
      final top = glassArea.top + i * (panelH + gap);
      final pr = Rect.fromLTWH(glassArea.left, top, glassArea.width, panelH);
      final prr = RRect.fromRectAndRadius(pr, const Radius.circular(3));
      canvas.drawRRect(prr, glassPaint);
      canvas.drawRRect(prr, mullion);
      // Cam yansıması (diyagonal parlama)
      final reflect = Path()
        ..moveTo(pr.left + pr.width * 0.12, pr.bottom)
        ..lineTo(pr.left + pr.width * 0.34, pr.bottom)
        ..lineTo(pr.left + pr.width * 0.62, pr.top)
        ..lineTo(pr.left + pr.width * 0.40, pr.top)
        ..close();
      canvas.drawPath(reflect, Paint()..color = Colors.white.withOpacity(0.04));
    }
  }

  @override
  bool shouldRepaint(covariant _GiyotinPreviewPainter old) =>
      old.width != width || old.height != height;
}
