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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geçmiş Hesaplamalar"),
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
      ),
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
      body: isLoading
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
                                Row(children: [Text("PROFİL #$binIndex", style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)), const Spacer(), Text("Fire: ${waste.toStringAsFixed(0)} mm", style: TextStyle(color: waste < 100 ? AppColors.success : AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold))]),
                                const SizedBox(height: 10),
                                Container(
                                  height: 42,
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.textMuted.withOpacity(0.3))),
                                  child: LayoutBuilder(
                                    builder: (ctx, c) {
                                      final oran = c.maxWidth / stockLength;
                                      return Row(
                                        children: pieces.asMap().entries.map((pEntry) {
                                          final w = (pEntry.value['length'] as num).toDouble() * oran;
                                          final renk = _barRenkleri[pEntry.key % _barRenkleri.length];
                                          final projectName = pEntry.value['project_name'] ?? '';
                                          return Tooltip(
                                            message: "Proje: $projectName\nÖlçü: ${pEntry.value['length']} mm",
                                            child: Container(
                                              width: w,
                                              decoration: BoxDecoration(color: renk, border: Border.all(color: AppColors.background)),
                                              alignment: Alignment.center,
                                              child: w > 45 
                                                  ? Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text("${pEntry.value['length']}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        Text(projectName, style: const TextStyle(color: Colors.white70, fontSize: 8), overflow: TextOverflow.ellipsis, maxLines: 1),
                                                      ],
                                                    )
                                                  : (w > 25 ? Text("${pEntry.value['length']}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)) : null),
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
                buildAnimatedSection(
                  _buildDetailCard(isMobile, "Maliyet Analizi", Icons.payments_rounded, [
                    _buildInfoRow("Profil Maliyeti", "${costDetails['total_profile_cost']?.toStringAsFixed(2)} ₺"),
                    _buildInfoRow("Aksesuar & Motor", "${costDetails['total_accessory_cost']?.toStringAsFixed(2)} ₺"),
                    _buildInfoRow("Cam Maliyeti", "${costDetails['cam_cost']?.toStringAsFixed(2)} ₺"),
                    _buildInfoRow("Genel Gider", "${costDetails['overhead']?.toStringAsFixed(2)} ₺"),
                    const SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientSuccess,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOPLAM MALİYET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("${costDetails['total_cost']?.toStringAsFixed(2)} ₺", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ]),
                1),
                const SizedBox(height: 32),
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
                    const Divider(height: 32, color: AppColors.background),
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
          const Divider(height: 32, color: AppColors.background),
          ...children,
        ],
      ),
    );
  }
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

    try {
      final responseData = await _giyotinService.hesapla(
        projectName: projectController.text,
        systemType: _selectedSystemType,
        width: double.tryParse(widthController.text) ?? 0,
        height: double.tryParse(heightController.text) ?? 0,
        quantity: int.tryParse(quantityController.text) ?? 1,
        stockLength: double.tryParse(stockController.text) ?? 6500.0,
        kerf: double.tryParse(kerfController.text) ?? 5.0,
      );

      if (mounted) {
        setState(() {
          final recordId = responseData['record_id'];
          _calculatedRecordId = recordId;
          _costDetails = responseData['cost_details'];
          _cutOptimization = responseData['cut_optimization'];
          resultMessage = "✅ Hesaplama Başarılı!\nKayıt ID: $recordId";
        });
        _tabController.animateTo(1);
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
          const Divider(height: 32, color: AppColors.background),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giyotin Maliyet Hesaplama"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
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
          Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
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
                            const Divider(height: 24, color: AppColors.background),
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
