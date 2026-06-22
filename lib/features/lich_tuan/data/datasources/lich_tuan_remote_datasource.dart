// lib/features/lich_tuan/data/datasources/lich_tuan_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/lich_tuan_model.dart';

class LichTuanRemoteDatasource {
  LichTuanRemoteDatasource()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;
  final _fmt = DateFormat('yyyy-MM-dd');

  Future<List<LichTuanModel>> fetchLichTuan({
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _dio.get(
      AppConstants.lichTuanApiUrl,
      queryParameters: {
        'Madviqly': AppConstants.lichTuanMaDviqly,
        'start': _fmt.format(start),
        'end': _fmt.format(end),
        'nvid': AppConstants.lichTuanNvid,
        'xacthuc': AppConstants.lichTuanXacThuc,
      },
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => LichTuanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
