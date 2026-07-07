# Auto thêm dòng "vỏ" khi bán bình — mapping bình↔vỏ

## Context
Nghiệp vụ: bán bình gas loại nào thì thu về vỏ loại đó với số lượng tương ứng. Hiện ở màn **Nhập bán hàng** mobile (`nhap_ban_hang_screen.dart`), người dùng phải **tự chọn tay** thêm một dòng mặt hàng vỏ sau khi chọn bình. Ta muốn: khi chọn 1 mặt hàng **bình**, app **tự thêm** một dòng mặt hàng **vỏ** tương ứng (đơn vị tính = vỏ) với số lượng bằng số bình.

Cặp bình↔vỏ theo quy ước mã trong `mat_hang`: cùng `nha_cung_cap_id`, `ma_mat_hang` đổi ký tự đầu B→V, giữ phần còn lại (VD `B12CD` ↔ `V12CD`).

**Quyết định của người dùng:**
- Mapping lưu ở **bảng mapping MỚI** (không sửa cấu trúc bảng `mat_hang` hiện có).
- Số lượng vỏ tự thêm: **đặt 1 lần = số bình lúc chọn, cho phép sửa tay** (không khóa liên kết).
- Chỉ áp dụng ở **màn nhập bán hàng mới** (`nhap_ban_hang_screen.dart`), không đụng màn sửa.

Bối cảnh dữ liệu: app đã có sẵn khái niệm dòng vỏ (`_SaleRow.isVo` khi `don_vi_tinh=='vỏ'`, có `loaiVo` thu/bán, `thành tiền=0`, getter `soVoThu/soVoBan`). Toàn bộ mặt hàng đã cache offline ở `cache_mat_hang`. BE dùng SQL Server (PermissionDbContext) **tạo schema bằng script SQL tay**, không EF migration.

---

## Phần A — Backend (`gas_be`): bảng mapping + API

### A1. Entity mới — `OrderService.Domain/Entities/MatHangVoMapping.cs`
Fields: `Id`, `BinhMatHangId` (unique), `VoMatHangId`, `CreatedAt`, `UpdatedAt?`.

### A2. Cấu hình EF (query-only, KHÔNG seed) — `PermissionDbContext.cs`
Thêm `DbSet<MatHangVoMapping>` + block `Entity<MatHangVoMapping>`: `ToTable("mat_hang_vo_mapping")`, cột snake_case, `HasIndex(BinhMatHangId).IsUnique()`, 2 FK tới mat_hang.

### A3. Script tạo bảng — thêm cuối `gas_be/danh-muc-migration.sql`
`CREATE TABLE mat_hang_vo_mapping(id IDENTITY PK, binh_mat_hang_id INT UNIQUE FK, vo_mat_hang_id INT FK, created_at, updated_at)`.

### A4. Repository — `MatHangVoMappingRepository` (+ interface)
`GetAllAsync`, `UpsertAsync(binhId,voId)`, `DeleteByBinhAsync`, `GenerateByConventionAsync()` (quét B*→V* cùng NCC, idempotent). Đăng ký DI.

### A5. API — thêm vào `MatHangController.cs`
- `GET  /api/mat-hang/vo-mapping/all`
- `POST /api/mat-hang/vo-mapping/generate` → `{count}`
- `POST /api/mat-hang/vo-mapping` `{binhMatHangId,voMatHangId}`
- `POST /api/mat-hang/vo-mapping/{binhMatHangId}/delete`

---

## Phần B — Mobile (`quanlygas_mobile`)

### B1. `lib/core/database/local_database.dart`
- version 6→7; `_create` + `_onUpgrade(<7)` tạo `cache_mat_hang_vo(binh_server_id PK, vo_server_id)`.
- `upsertMatHangVoList`, `getVoServerIdForBinh(binhId)→int?`.

### B2. `lib/core/services/sync_service.dart`
Trong `syncCatalog()` thêm block `GET /api/mat-hang/vo-mapping/all` → `upsertMatHangVoList`.

### B3. `lib/features/chuyen_xe/presentation/screens/nhap_ban_hang_screen.dart`
- `_loadCaches()`: nạp `_matHangList` (toàn bộ cache_mat_hang) + `_binhToVo` (map).
- Picker `onTap` nhánh `!isVo`: tra `voId=_binhToVo[binhId]`; nếu có & chưa có dòng vỏ đó → thêm `_SaleRow`(isVo=true, loaiVo='thu', soLuong=số bình hiện tại, label vỏ) + SnackBar. Đặt 1 lần, sửa/xóa tay được.

---

## Verification
1. BE: chạy script tạo bảng; `POST .../generate` → count>0; `GET .../all` đúng cặp.
2. Mobile: pub get; nâng DB v7; sync → cache_mat_hang_vo có data.
3. Nhập bán hàng: chọn bình có mapping → tự thêm dòng vỏ (Vỏ thu, SL=số bình); sửa/xóa được; bình không mapping → không thêm.
4. Lưu đơn → payload có cả dòng bình + vỏ.

## Ngoài phạm vi
Màn sửa bán hàng; đồng bộ số lượng realtime; UI web quản lý mapping.
