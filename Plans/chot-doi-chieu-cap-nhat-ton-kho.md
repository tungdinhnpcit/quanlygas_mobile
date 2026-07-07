# Mobile: Nút "Chốt đối chiếu & cập nhật tồn kho"

## Context
Màn đối chiếu kiểm kê trên app Flutter (`kiem_ke_doi_chieu_screen.dart`) hiện chỉ **hiển thị** bảng so sánh số kế toán (KT) vs số suy ra từ bán hàng lái xe (LX), **không có nút hành động nào**. Trên web (`gas_fe`) đã có nút **"Chốt đối chiếu & cập nhật tồn kho"** gọi 1 endpoint duy nhất để vừa chốt biên bản vừa ghi bút toán điều chỉnh tồn kho. Mobile đang thiếu chức năng này — sau khi đối chiếu, kế toán trên app không thể chốt và cập nhật tồn kho, phải quay lại web.

Mục tiêu: thêm nút vào màn đối chiếu để, sau khi xem đối chiếu, kế toán bấm **một nút** là chốt đối chiếu đồng thời cập nhật tồn kho — đúng hành vi như web.

## Hợp đồng API (đã có sẵn ở BE, không cần sửa BE)
- `POST /api/kiem-ke/{kiemKeId}/chot` — không body. Trả `KiemKeChuyenXeDto` (`daChot=true`, `chotAt`, `nguoiChot`). Lỗi 400/404 trả `{ "message": "..." }`. **Idempotent**: chốt → ghi bút toán net vào tồn kho.
- Xác nhận nguồn: web gọi `chotKiemKe` tại `gas_fe/lib/api/kiem-ke-chuyen-xe.ts:155`; handler BE tại `gas_be/OrderService.API/Controllers/KiemKeController.cs:196-211`.
- **Lưu ý khóa chính**: endpoint cần `kiemKeId`, còn màn đối chiếu chỉ có `chuyenXeId`. Lấy `kiemKeId` qua `getKiemKe(chuyenXeId).id` (đã có sẵn trong repo).

## Thay đổi

### 1. Repository — thêm 1 method
File: `quanlygas_mobile/lib/features/chuyen_xe/data/repositories/chuyen_xe_repository.dart`
Thêm (đặt cạnh `lienKetChuyen`, ~dòng 498), mirror y hệt pattern các method mutating hiện có:
```dart
/// Chốt đối chiếu → ghi bút toán net vào tồn kho (idempotent). Trả phiếu đã chốt.
Future<KiemKeChuyenXeModel> chotKiemKe(int kiemKeId) async {
  final res = await ApiClient.instance.dio.post('/api/kiem-ke/$kiemKeId/chot');
  return KiemKeChuyenXeModel.fromJson(res.data as Map<String, dynamic>);
}
```

### 2. Màn đối chiếu — nạp thêm phiếu kiểm kê + thêm nút
File: `quanlygas_mobile/lib/features/kiem_ke/presentation/screens/kiem_ke_doi_chieu_screen.dart`

**State mới:** thêm `KiemKeChuyenXeModel? _kiemKe;` và `bool _choting = false;` vào `_KiemKeDoiChieuScreenState`. Import `kiem_ke_model.dart`.

**`_load()`:** gọi song song thêm `getKiemKe(widget.chuyenXeId)` để lấy `_kiemKe` (chứa `id` = kiemKeId và `daChot`). Dùng `Future.wait([...])` cho gọn; nếu `getKiemKe` trả null thì `_kiemKe = null` (nút sẽ không hiện).

**`build()`:** thêm `bottomNavigationBar: _buildBottomBar()` vào `Scaffold` (mẫu lấy từ `kiem_ke_nhap_so_mang_ve_screen.dart:356-395`).

**`_buildBottomBar()`** (mới): trả `null` khi `_loading`/`_error != null`/`_data == null`/`_kiemKe == null` (không có gì để chốt). Ngược lại:
- Nếu `_kiemKe!.daChot == true` → hiện badge **"✓ Đã chốt đối chiếu"** (nền teal nhạt, không bấm được) — mirror web.
- Nếu chưa chốt → nút full-width `ElevatedButton.icon` teal `0xFF00897B`, nhãn **"Chốt đối chiếu & cập nhật tồn kho"**, icon `Icons.inventory_2_outlined` (hoặc `check_circle_outline`), spinner khi `_choting`. `onPressed: _choting ? null : _onChot`. Bọc `SafeArea` + `Padding` như mẫu.

**`_onChot()`** (mới) — mirror handler web `onChot` + pattern `_luu`/bắt lỗi Dio của `kiem_ke_chon_chuyen_screen.dart`:
1. `showDialog` xác nhận: "Chốt đối chiếu và cập nhật tồn kho? Tồn kho sẽ được điều chỉnh theo số kế toán chốt." (nếu `_data!.coChenhLech` → thêm dòng cảnh báo còn chênh lệch). Hủy → return.
2. `setState(_choting = true)`; `try { final saved = await _repo.chotKiemKe(_kiemKe!.id); setState(_kiemKe = saved; _choting = false); }`
3. Thành công → `SnackBar('Đã chốt đối chiếu & cập nhật tồn kho')`; reload đối chiếu (`_load()`) để phản ánh trạng thái.
4. `on DioException` → lấy `e.response?.data['message']` hiển thị SnackBar đỏ; `finally` đảm bảo `_choting=false` + `if(!mounted) return`.

## Điều cần quyết định khi làm (mặc định đã chọn)
- **Vị trí nút**: `bottomNavigationBar` (đồng bộ màn "nhập số mang về"), không dùng AppBar action.
- **Cho chốt khi còn chênh lệch**: cho phép (kèm cảnh báo trong dialog) — đúng như web; BE điều chỉnh tồn kho theo số kế toán.
- **Sau chốt**: giữ nguyên màn, đổi nút thành badge "Đã chốt" + reload; không tự pop.

## Verification (chạy thật, không chỉ build)
1. Build: `flutter analyze` trong `quanlygas_mobile` (không lỗi mới); app đã pull code mới nên chạy `flutter pub get` trước.
2. Chạy app (`flutter run`), đăng nhập tài khoản kế toán, BE dev đang chạy (OrderService :5001 + Gateway :5000).
3. Mở 1 chuyến đã hoàn thành có kiểm kê → vào màn **Đối chiếu kiểm kê**:
   - Thấy nút "Chốt đối chiếu & cập nhật tồn kho" ở đáy.
   - Bấm → hiện dialog xác nhận → đồng ý → thấy SnackBar thành công, nút đổi thành badge "✓ Đã chốt".
4. Kiểm chứng tồn kho thực sự đổi: xem màn Tổng quan → Tồn kho (`/api/bao-cao/ton-kho`) hoặc trên web `ton-kho` trước/sau khi chốt.
5. Idempotent: bấm chốt lần 2 (nếu còn nút do chưa reload) không làm sai tồn kho; chốt phiếu chưa liên kết chuyến → BE trả 400 → SnackBar đỏ hiển thị message.

## Ngoài phạm vi
- Không sửa BE (endpoint đã có).
- Không đụng logic tính bút toán tồn kho (nằm ở BE `ChotKiemKeDoiChieuCommand`).
- Không thêm chức năng "bỏ chốt"/hoàn tác (web cũng không có; chốt là một chiều, idempotent).
