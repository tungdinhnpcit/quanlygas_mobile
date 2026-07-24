# Xây dựng chức năng Thần số học trên app mobile (quanlygas_mobile)

## Context

Người dùng ban đầu muốn thêm chức năng Thần số học vào web frontend `gas_fe` (plan cũ đã lưu tại `D:\Work\Gasmanager\gas_fe\THAN_SO_HOC_PLAN.md` và đã commit/push), nhưng sau đó đổi ý: **xây trên app mobile Flutter `D:\Work\Gasmanager\quanlygas_mobile` thay vì web**. Plan này thay thế hoàn toàn cho hướng web.

Công thức tính toán lấy từ `D:\Work\ThanSoHoc\CONG-THUC-THAN-SO-HOC.md`, trích từ file Excel gốc `RIVERSIDE CALCULATION.xlsx` (engine tính toán) và `TSH Hiền Mira _ Tổng hợp thông tin các chỉ số.xlsx` (bảng tra ý nghĩa). Đây vẫn là tính năng độc lập, không liên quan nghiệp vụ gas, tính toán thuần phía client — không cần gọi API cho việc tính toán.

Quyết định đã chốt với người dùng:
- **Nền tảng**: Flutter mobile app `quanlygas_mobile`, không phải web.
- **Điểm truy cập**: Tile động trên **Trang chủ** (Home screen), giống các chức năng khác — nghĩa là CẦN thêm một bản ghi menu ở backend `gas_be` (chỉ 1 dòng dữ liệu, không cần code/API mới).
- **Phạm vi tính năng**: đầy đủ toàn bộ tài liệu công thức (đã chốt từ trước, giữ nguyên) — 6 chỉ số chính, nội cảm/thiếu/lặp, trưởng thành, cân bằng, Danh đồ/Sinh đồ + 8 mũi tên, Năm/Tháng/Ngày cá nhân, 4 đỉnh cao, 4 thử thách, 3 giai đoạn cuộc đời.

## Đã xác minh bằng dữ liệu thật (không đổi so với phân tích trước — vẫn áp dụng cho engine Dart)

Đã dùng thư viện `xlsx` đọc trực tiếp công thức + giá trị cache trong sheet `xm` của `RIVERSIDE CALCULATION.xlsx` để xác minh các điểm mập mờ trong tài liệu `.md`. Golden test case dùng để đối chiếu khi viết engine:

- Họ tên: `NGUYEN THI HANG`, Ngày sinh: 10/10/1997, Ngày lập lá số: 10/12/2023.
- Kỳ vọng: Ngày sinh=1, Thái độ=2, Nhân cách=9 (raw 54), Đường đời=1 (raw 28), Linh hồn=9 (raw 18), Sứ mệnh=9 (raw 72), Trưởng thành=1 (raw 100), Tuổi bắt đầu trưởng thành=35, Nội cảm="5 7", |Đường đời−Sứ mệnh| rút gọn=8, |Linh hồn−Nhân cách| rút gọn=0, Chỉ số thiếu="4 6", Chỉ lặp trong 6 CS chính=9, 4 đỉnh cao=2/9/11/9 (tuổi bắt đầu 35/44/53/62), 4 thử thách=0/7/7/7.

Hai phát hiện quan trọng, không nêu rõ (hoặc nêu sai) trong file `.md`, phải cài đúng:

1. **Quy tắc chữ Y (nguyên âm/phụ âm) là theo vị trí, xử lý tuần tự trái→phải, KHÔNG phải cờ thủ công toàn cục.** Dò công thức Excel thực tế cho thấy điều kiện kiểm tra ô LIỀN TRƯỚC (không phải một ô cờ cố định). Quy tắc đúng: A/E/I/O/U luôn là nguyên âm; mọi phụ âm khác luôn là phụ âm; riêng **Y**: nếu ký tự ngay trước nó là nguyên âm → Y là **phụ âm**; ngược lại (trước là phụ âm/khoảng trắng, hoặc Y là ký tự đầu) → Y là **nguyên âm**. Giá trị số của Y luôn là 7. Verify khớp 100% với Z3=18 (nguyên âm) và Z5=54 (phụ âm) của golden case.
2. **Chỉ số cân bằng**: tài liệu mô tả đúng ý định là cộng giá trị Pythagoras của chữ cái đầu MỌI từ trong tên. Bản Excel mẫu bị lệch (7 thay vì 6) do lỗi nhập liệu ở ô phân cách từ (khoảng trắng thật thay vì ô trống) — lỗi riêng của file mẫu, không phải chủ ý thuật toán. **Cài đặt đúng theo tài liệu** (cộng chữ cái đầu của TẤT CẢ các từ), golden case sẽ cho kết quả = 6 (rút gọn từ 15), không phải 7.

Hàm "rút gọn" (chuỗi cột K/L/M/N trong Excel) đơn giản hóa thành 2 hàm thuần lặp tới khi ổn định — tương đương toán học, đã verify khớp mọi giá trị M/N trong golden case:
- `reduceKeepMaster(x)`: lặp `x = x~/10 + x%10` tới khi `x < 10` hoặc `x ∈ {11,22,33}`.
- `reduceFull(x)`: lặp như trên, bỏ qua số chủ đạo, luôn về 1 chữ số.

## Kiến trúc mobile đã khảo sát (quanlygas_mobile)

- Flutter/Dart, state management **Riverpod** (nhưng tính năng này không cần shared state — dùng `StatefulWidget`/`ConsumerStatefulWidget` cục bộ là đủ), router **go_router** (`lib/core/router/app_router.dart`, `app_routes.dart`), tổ chức theo feature (`lib/features/<feature>/presentation/screens|providers`, `data/`).
- Form: `Form` + `GlobalKey<FormState>` + `TextFormField` + `validator` (không có package form riêng) — theo mẫu `lib/features/ghi_chu/presentation/screens/ghi_chu_form_screen.dart`.
- Ngày sinh: dùng `showDatePicker` có sẵn của Flutter (theo mẫu `lib/features/kiem_ke/presentation/screens/kiem_ke_nhap_screen.dart`), không cần thêm package date-picker.
- Bỏ dấu tiếng Việt: tái sử dụng `removeDiacritics()` tại `lib/core/utils/vietnamese_text.dart` (hàm hiện có sẵn, có đủ bảng ánh xạ dấu tiếng Việt kể cả `đ`/`ñ`/`ç`) — vì hàm gốc trả về chữ thường để phục vụ tìm kiếm, tính năng này cần thêm `.toUpperCase()` sau khi gọi (bảng Pythagoras chỉ có A-Z không dấu).
- Logic tính toán thuần (không phụ thuộc Flutter) đặt tại `lib/core/utils/` theo đúng convention đã có (nơi này hiện chỉ có 3 file utils, không có Flutter widget deps).
- **Trang chủ lấy tile từ menu server-driven** (`menuProvider` → `AuthRepository().getSavedMenus()`, đọc từ `flutter_secure_storage`, được lưu lúc login/refresh) — lọc `mobileRoute != null && (platform == 'mobile' || platform == 'both')`. Vì người dùng chọn hiển thị trên Trang chủ, cần thêm 1 dòng ở bảng `sys_menu` bên `gas_be` (xem mục dưới).
- Icon cho tile: `lib/core/utils/menu_icon_mapper.dart` (`mapMenuIcon`) — nếu không thêm case cho `THAN_SO_HOC` sẽ tự fallback icon mặc định (`Icons.apps_rounded`); nên thêm 1 case đẹp hơn (VD `Icons.auto_awesome_rounded`).

## Thay đổi backend cần thiết (tối thiểu, chỉ 1 dòng dữ liệu — KHÔNG viết code/API mới)

Đã khảo sát: menu mobile hoàn toàn điều khiển bởi bảng SQL `sys_menu` (thuộc `OrderService`, EF mapping tại `OrderService.Infrastructure/Data/PermissionDbContext.cs`, entity `OrderService.Domain/Entities/Permission/SysMenu.cs`). Repo không dùng EF Core migrations cho bảng này — các thay đổi được áp bằng script SQL thủ công trong thư mục `gas_be/migrations/` (chạy tay trên DB Manager, theo tiền lệ `2026-07-16-lich-tuan-da-gui.sql`).

Thêm file mới `gas_be/migrations/2026-07-24-menu-than-so-hoc.sql`:
```sql
IF NOT EXISTS (SELECT 1 FROM sys_menu WHERE menu_code = 'THAN_SO_HOC')
BEGIN
    INSERT INTO sys_menu (menu_code, menu_name, web_url, mobile_route, icon, parent_id, right_code, sort_order, platform, is_active)
    VALUES ('THAN_SO_HOC', N'Thần số học', NULL, '/than-so-hoc', N'🔢', NULL, NULL, 15, 'mobile', 1);
END
GO
```
- `right_code = NULL` → hiển thị cho mọi user đã đăng nhập, không cần thêm quyền/role.
- `platform = 'mobile'`, `web_url = NULL` → chỉ hiện trên mobile, không ảnh hưởng `gas_fe`.
- Idempotent (guard bằng `IF NOT EXISTS`), an toàn chạy lại nhiều lần/nhiều môi trường.
- **Lưu ý vận hành**: menu chỉ được nạp lại vào `flutter_secure_storage` lúc login hoặc lúc token refresh (`AuthService.BuildResponseAsync`) — user đang đăng nhập sẵn sẽ KHÔNG thấy tile mới ngay, cần đăng xuất/đăng nhập lại hoặc đợi refresh token tự nhiên. Không cần sửa code Flutter cho việc này.

## Cấu trúc file cần tạo/sửa trong `quanlygas_mobile`

**Logic tính toán thuần (Dart, không import `material.dart`, dễ unit test), theo đúng mục 2–7 của tài liệu công thức:**
- `lib/core/utils/numerology/types.dart` — class input (`NumerologyInput`: họ tên, ngày/tháng/năm sinh, ngày lập lá số) và output (`NumerologyResult` chứa toàn bộ chỉ số).
- `lib/core/utils/numerology/reduce.dart` — `reduceKeepMaster`, `reduceFull`, `sumDigits`.
- `lib/core/utils/numerology/pythagoras.dart` — bảng nguyên âm/phụ âm (mục 2 tài liệu), hàm phân loại từng ký tự theo quy tắc Y đã verify, hàm lấy giá trị Pythagoras của 1 ký tự.
- `lib/core/utils/numerology/calculate.dart` — hàm `calculateNumerology(input)` tính toàn bộ mục 4 (6 chỉ số chính, nội cảm, kết nối ĐĐ-SM, kết nối LH-NC, trưởng thành + tuổi bắt đầu, chỉ số thiếu, chỉ lặp, cân bằng) và mục 6-7 (Năm/Tháng/Ngày cá nhân, 4 đỉnh cao + tuổi bắt đầu mỗi đỉnh, 4 thử thách, 3 giai đoạn).
- `lib/core/utils/numerology/grid.dart` — Danh đồ/Sinh đồ: đếm tần suất digit 1-9 (mục 5), lưới 3×3, xác định 8 mũi tên theo đúng bảng vị trí trong tài liệu.

**Dữ liệu ý nghĩa (từ `TSH Hiền Mira...xlsx`, chỉ có cho 4 chỉ số: Đường đời 1–11/22/33, Ngày sinh 1–31, Tên khai sinh/Sứ mệnh 1–11, Thái độ 1–11/22/33):**
- `scripts/extract-numerology-meanings.mjs` (script Node một lần, chạy ngoài Flutter, dùng package `xlsx` — có thể chạy trong `gas_fe` hoặc bất kỳ máy có Node vì chỉ là bước tạo dữ liệu tĩnh) → xuất JSON, rồi tạo `lib/core/utils/numerology/meanings_data.dart` (const map tra theo chỉ số). Một số ô nguồn bị trống (Ngày sinh thiếu 9/31 mục, Thái độ thiếu vài mục) → UI hiển thị fallback "Chưa có dữ liệu diễn giải cho chỉ số này". Các chỉ số còn lại không có bảng tra ý nghĩa (đúng theo mục 8 tài liệu) — chỉ hiển thị số/nhãn.

**UI (theo đúng convention đã khảo sát: feature-based folder, `Form`+`TextFormField`, `showDatePicker`, Material 3 `Card`/`FilledButton`, chữ tiếng Việt trực tiếp không qua l10n):**
- `lib/features/than_so_hoc/presentation/screens/than_so_hoc_screen.dart` — 1 màn hình gồm form nhập (Họ tên, Ngày/Tháng/Năm sinh qua `showDatePicker`, Ngày lập lá số mặc định hôm nay có thể sửa) và hiển thị kết quả ngay dưới form sau khi bấm tính (không cần trang riêng, không cần Riverpod provider vì không có state dùng chung). Chuẩn hoá tên trước khi tính bằng `removeDiacritics(name).toUpperCase()` từ `lib/core/utils/vietnamese_text.dart`, vẫn hiển thị tên gốc có dấu trên UI.
- `lib/features/than_so_hoc/presentation/widgets/` — các widget con hiển thị kết quả nếu cần tách nhỏ: bảng 6 chỉ số chính kèm ý nghĩa, lưới Danh đồ/Sinh đồ với mũi tên, bảng 4 đỉnh cao/4 thử thách/3 giai đoạn, thẻ Năm-Tháng-Ngày cá nhân.

**Định tuyến:**
- `lib/core/router/app_routes.dart` — thêm `static const String thanSoHoc = '/than-so-hoc'`.
- `lib/core/router/app_router.dart` — thêm `GoRoute` cho route trên vào trong `ShellRoute` hiện có (để có sẵn bottom-nav/back button), thêm entry vào map `_featureTitles` (`AppRoutes.thanSoHoc: 'Thần số học'`).
- `lib/core/utils/menu_icon_mapper.dart` — thêm case `'THAN_SO_HOC' => Icons.auto_awesome_rounded` (tuỳ chọn, chỉ để đẹp hơn icon mặc định).

## Kiểm thử / xác minh

1. Viết `test/core/utils/numerology/calculate_test.dart` dùng `flutter_test` (`test()`/`group()`/`expect()`, engine thuần Dart không cần `testWidgets`) chạy `calculateNumerology` với golden case, so khớp toàn bộ giá trị kỳ vọng đã liệt kê ở trên (kể cả lưu ý Cân bằng = 6, không phải 7). Đây sẽ là unit test thật đầu tiên của repo (hiện `test/widget_test.dart` chỉ là placeholder).
2. Chạy `flutter analyze` trong `quanlygas_mobile`.
3. Chạy migration SQL thêm menu (thủ công trên DB theo quy trình hiện có của team), đăng xuất/đăng nhập lại app để nạp menu mới, xác nhận tile "Thần số học" xuất hiện trên Trang chủ và điều hướng đúng route.
4. Nhập golden case trực tiếp trên màn hình, đối chiếu số hiển thị khớp danh sách kỳ vọng.
