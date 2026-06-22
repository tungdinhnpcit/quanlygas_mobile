// lib/features/lich_tuan/domain/repositories/lich_tuan_repository.dart
import '../entities/lich_tuan_entity.dart';

abstract class LichTuanRepository {
  Future<List<LichTuanEntity>> getLichTuan({
    required DateTime start,
    required DateTime end,
  });
}
