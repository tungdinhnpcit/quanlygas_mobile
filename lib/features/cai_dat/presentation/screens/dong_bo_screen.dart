// lib/features/cai_dat/presentation/screens/dong_bo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/sync_service.dart';

class DongBoScreen extends ConsumerStatefulWidget {
  const DongBoScreen({super.key});

  @override
  ConsumerState<DongBoScreen> createState() => _DongBoScreenState();
}

class _DongBoScreenState extends ConsumerState<DongBoScreen> {
  int _pendingKH = 0;
  int _pendingCX = 0;
  int _pendingBH = 0;
  String? _lastSyncDate;
  bool _syncing = false;
  bool _catalogSyncing = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final db = LocalDatabase.instance;
    final d = await db.db;
    final kh = (await d.rawQuery(
            'SELECT COUNT(*) as c FROM khach_hang_local WHERE is_synced = 0'))
        .first['c'] as int;
    final cx = (await d.rawQuery(
            'SELECT COUNT(*) as c FROM chuyen_xe_offline WHERE is_synced = 0'))
        .first['c'] as int;
    final bh = (await d.rawQuery(
            'SELECT COUNT(*) as c FROM ban_hang_offline WHERE is_synced = 0'))
        .first['c'] as int;

    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_catalog_sync_date');

    if (mounted) {
      setState(() {
        _pendingKH = kh;
        _pendingCX = cx;
        _pendingBH = bh;
        _lastSyncDate = lastSync;
      });
    }
  }

  Future<void> _uploadPending() async {
    setState(() {
      _syncing = true;
      _lastResult = null;
    });
    try {
      final result =
          await ref.read(syncNotifierProvider.notifier).uploadPending();
      final total = result.khCount + result.cxCount + result.bhCount;
      setState(() {
        _lastResult = total > 0
            ? 'Đã đồng bộ: ${result.khCount} KH, ${result.cxCount} chuyến xe, ${result.bhCount} bán hàng.'
            : 'Không có dữ liệu mới để đồng bộ.';
        if (result.hasErrors) {
          _lastResult = '${_lastResult!} Lỗi: ${result.errors.length} mục.';
        }
      });
      await _loadCounts();
    } catch (e) {
      setState(() => _lastResult = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _syncCatalog() async {
    setState(() {
      _catalogSyncing = true;
      _lastResult = null;
    });
    try {
      final result = await SyncService.instance.syncCatalog();
      await SyncService.instance.markSyncedToday();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _lastSyncDate = prefs.getString('last_catalog_sync_date');
        _lastResult = result.hasNewItems ? result.summary : 'Catalog đã cập nhật.';
      });
    } catch (e) {
      setState(() => _lastResult = 'Lỗi cập nhật catalog: $e');
    } finally {
      if (mounted) setState(() => _catalogSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Upload offline ─────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dữ liệu chưa đồng bộ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _CountRow(icon: Icons.people, label: 'Khách hàng offline', count: _pendingKH),
                  _CountRow(icon: Icons.directions_car, label: 'Chuyến xe offline', count: _pendingCX),
                  _CountRow(icon: Icons.receipt_long, label: 'Bán hàng offline', count: _pendingBH),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_syncing || (_pendingKH + _pendingCX + _pendingBH == 0))
                          ? null
                          : _uploadPending,
                      icon: _syncing
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(_syncing ? 'Đang đồng bộ...' : 'Đồng bộ lên server'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Catalog sync ───────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cập nhật danh mục',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    _lastSyncDate != null
                        ? 'Lần cuối: $_lastSyncDate'
                        : 'Chưa cập nhật lần nào',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _catalogSyncing ? null : _syncCatalog,
                      icon: _catalogSyncing
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download_rounded),
                      label: Text(_catalogSyncing ? 'Đang cập nhật...' : 'Cập nhật ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Kết quả ───────────────────────────────────────────────────
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_lastResult!,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  const _CountRow({required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: count > 0 ? const Color(0xFFFF9800) : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? Colors.white : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
