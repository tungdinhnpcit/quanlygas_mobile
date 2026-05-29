// lib/features/chuyen_xe/presentation/providers/chuyen_xe_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/chuyen_xe_model.dart';
import '../../data/repositories/chuyen_xe_repository.dart';

final chuyenXeRepositoryProvider = Provider<ChuyenXeRepository>(
  (_) => ChuyenXeRepository(),
);

/// Notifier tải danh sách chuyến xe của lái xe, hỗ trợ filter trạng thái và khoảng ngày.
/// Lazy load — không gọi API trong constructor, chờ screen truyền nhanVienId qua load().
class ChuyenXeListNotifier extends StateNotifier<AsyncValue<List<ChuyenXeModel>>> {
  final ChuyenXeRepository _repo;

  int       _nhanVienId = 0;
  String?   _trangThai;
  DateTime? _tuNgay;
  DateTime? _denNgay;

  ChuyenXeListNotifier(this._repo) : super(const AsyncValue.data([]));

  /// Tải (hoặc làm mới) danh sách chuyến xe. Lần đầu phải truyền nhanVienId.
  Future<void> load({int? nhanVienId}) async {
    if (nhanVienId != null) _nhanVienId = nhanVienId;
    if (_nhanVienId <= 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.getList(
        nhanVienId: _nhanVienId,
        trangThai:  _trangThai,
        tuNgay:     _tuNgay,
        denNgay:    _denNgay,
        pageSize:   100,
      ),
    );
  }

  /// Áp dụng filter (trạng thái, ngày từ, ngày đến) rồi load lại danh sách.
  void setFilter({String? trangThai, DateTime? tuNgay, DateTime? denNgay}) {
    _trangThai = trangThai;
    _tuNgay    = tuNgay;
    _denNgay   = denNgay;
    if (_nhanVienId > 0) load();
  }

  /// Xoá toàn bộ filter về trạng thái mặc định (hiện tất cả).
  void clearFilter() => setFilter();
}

/// Provider chính: danh sách chuyến xe — autoDispose để giải phóng khi rời màn hình.
final chuyenXeListProvider =
    StateNotifierProvider.autoDispose<ChuyenXeListNotifier, AsyncValue<List<ChuyenXeModel>>>(
  (ref) => ChuyenXeListNotifier(ref.watch(chuyenXeRepositoryProvider)),
);

/// Provider chi tiết một chuyến xe theo ID — dùng ở màn hình detail.
final chuyenXeDetailProvider =
    FutureProvider.family<ChuyenXeModel, int>((ref, id) {
  final repo = ref.watch(chuyenXeRepositoryProvider);
  return repo.getById(id);
});

/// Provider action upload ảnh: nhận (chuyenXeId, XFile) → trả URL ảnh.
final uploadPhotoProvider = Provider<Future<String> Function(int, XFile)>((ref) {
  final repo = ref.watch(chuyenXeRepositoryProvider);
  return (chuyenXeId, photo) => repo.uploadPhoto(chuyenXeId, photo);
});
