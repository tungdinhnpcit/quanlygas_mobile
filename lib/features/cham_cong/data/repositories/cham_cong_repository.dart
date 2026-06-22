// lib/features/cham_cong/data/repositories/cham_cong_repository.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/cham_cong_model.dart';

// Lấy danh sách chấm công theo tháng/năm, lọc theo lái xe (nếu admin)
class ChamCongRepository {
  Future<List<ChamCongModel>> getThang({
    required int thang,
    required int nam,
    int? nhanVienId,
  }) async {
    try {
      final resp = await ApiClient.instance.dio.get('/api/cham-cong',
        queryParameters: {
          'thang': thang,
          'nam': nam,
          if (nhanVienId != null && nhanVienId > 0) 'nhanVienId': nhanVienId,
        },
      );

      // Response là mảng phẳng (không có wrapper items)
      if (resp.data is List) {
        return (resp.data as List)
            .map((e) => ChamCongModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cham cong: $e');
      rethrow;
    }
  }
}

final chamCongRepositoryProvider = Provider<ChamCongRepository>((_) {
  return ChamCongRepository();
});
