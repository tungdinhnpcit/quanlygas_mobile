[DONE - 2026-07-13, kiến trúc đổi sang Backend lưu DB + mã hoá server-side, xem plan mới tại C:\Users\tungdt\.claude\plans\d-gasmanager-quan-ly-gas-app-plans-ghi-c-iridescent-pinwheel.md]

# Plan: Chức năng "Ghi chú bảo mật" (lưu tài khoản/mật khẩu theo từng user, mã hoá bằng key tự định nghĩa)

## Context (Vì sao làm)

Cần màn hình mobile để lưu **ghi chú kèm tài khoản/mật khẩu**. Yêu cầu chốt:
- Nhập **tiêu đề**, **tài khoản (username)**, **mật khẩu**, **ghi chú**.
- Dữ liệu **gắn theo username đang đăng nhập** — mỗi user chỉ thấy ghi chú của chính mình.
- **Mật khẩu mã hoá lưu xuống SQLite**, dùng **key do mình tự định nghĩa (cố định trong code)**,
  **giải mã ngược được** bằng đúng key đó.
- **Danh sách** có **tìm kiếm tiếng Việt không dấu**.

Feature **hoàn toàn cục bộ (offline)** — không gọi backend. Lưu SQLite `gasmanager.db`.

Tận dụng sẵn:
- `removeDiacritics()` — `lib/core/utils/vietnamese_text.dart` (bỏ dấu để tìm kiếm).
- `LocalDatabase` (singleton sqflite) — `lib/core/database/local_database.dart`.
- Username đang đăng nhập: `FlutterSecureStorage().read(key: 'username')` (xem `lib/core/providers/user_info_provider.dart`).
- Pattern feature-first + Riverpod theo mẫu `lib/features/khach_hang/...`.

---

## Kiến trúc mã hoá (điểm khác biệt quan trọng)

- Dùng package [`encrypt`](https://pub.dev/packages/encrypt) (AES-256-CBC).
- **KEY do mình tự định nghĩa** — 1 chuỗi bí mật hằng số trong code. Từ chuỗi này băm SHA-256
  ra khoá AES 256-bit cố định. Vì key cố định, **giải mã ngược bất cứ lúc nào** miễn có đúng key.
- IV ngẫu nhiên mỗi bản ghi, lưu kèm ciphertext (cột `mat_khau_iv`). Key vẫn là bí mật duy nhất.
- Chỉ **mật khẩu** cần mã hoá. `tieu_de`, `tai_khoan`, `ghi_chu` để plaintext (cần cho tìm kiếm/hiển thị).

> ⚠️ Đặt key ở hằng số trong code là "mã hoá đối xứng cố định" — chống được việc mở thẳng file
> `.db`, nhưng ai đọc được source vẫn có key. Nếu cần mạnh hơn: sau này chuyển key sang biến môi
> trường build-time (`--dart-define`). Ở bước này giữ theo đúng yêu cầu: **key tự định nghĩa, dịch ngược được**.

---

## Các bước thực hiện

### Bước 1 — Thêm dependency

`pubspec.yaml` → mục `dependencies`:

```yaml
  # Mã hoá AES cho ghi chú bảo mật
  encrypt: ^5.0.3
```

Chạy `flutter pub get`.

---

### Bước 2 — Service mã hoá (key tự định nghĩa)

Tạo `lib/features/ghi_chu/data/crypto_service.dart`:

```dart
// lib/features/ghi_chu/data/crypto_service.dart
import 'package:crypto/crypto.dart';       // encrypt đã kéo sẵn crypto
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

/// Mã hoá / giải mã mật khẩu bằng AES-256-CBC với KEY tự định nghĩa (cố định).
/// Đổi _secretPassphrase thành chuỗi bí mật của bạn. Cùng key -> giải mã ngược được.
class NoteCryptoService {
  // 🔑 ĐỔI CHUỖI NÀY thành key bí mật của bạn (giữ nguyên sau khi đã có dữ liệu,
  //    đổi key sẽ khiến các bản ghi cũ không giải mã được).
  static const String _secretPassphrase = 'GAS_MANAGER_2026_DOI_KEY_CUA_BAN';

  // Khoá AES 256-bit = SHA-256(passphrase) -> luôn ra 32 byte cố định.
  static final Key _key =
      Key(Uint8ListFromHash(sha256.convert(utf8.encode(_secretPassphrase)).bytes));

  static final Encrypter _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  /// Trả về (cipherBase64, ivBase64). Chuỗi rỗng -> trả về ('','').
  (String cipher, String iv) encrypt(String plain) {
    if (plain.isEmpty) return ('', '');
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plain, iv: iv);
    return (encrypted.base64, iv.base64);
  }

  /// Giải mã ngược. Trả về '' nếu thiếu dữ liệu / sai key (tránh crash UI).
  String decrypt(String cipherB64, String ivB64) {
    if (cipherB64.isEmpty || ivB64.isEmpty) return '';
    try {
      return _encrypter.decrypt64(cipherB64, iv: IV.fromBase64(ivB64));
    } catch (_) {
      return '';
    }
  }
}

// Helper nhỏ: chuyển List<int> -> Uint8List cho Key.
// Có thể thay bằng `Uint8List.fromList(...)` trực tiếp (import 'dart:typed_data').
Key _dummy() => _key; // giữ chỗ, xoá nếu không cần
```

> **Đơn giản hoá:** thay `Uint8ListFromHash(...)` bằng:
> ```dart
> import 'dart:typed_data';
> static final Key _key =
>     Key(Uint8List.fromList(sha256.convert(utf8.encode(_secretPassphrase)).bytes));
> ```
> và bỏ hàm `_dummy()`. Đây là cách gọn nhất — dùng bản này.

**Bản gọn khuyến nghị dùng luôn:**

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class NoteCryptoService {
  static const String _secretPassphrase = 'GAS_MANAGER_2026_DOI_KEY_CUA_BAN'; // 🔑 đổi key của bạn

  static final Key _key =
      Key(Uint8List.fromList(sha256.convert(utf8.encode(_secretPassphrase)).bytes));
  static final Encrypter _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  (String cipher, String iv) encrypt(String plain) {
    if (plain.isEmpty) return ('', '');
    final iv = IV.fromSecureRandom(16);
    return (_encrypter.encrypt(plain, iv: iv).base64, iv.base64);
  }

  String decrypt(String cipherB64, String ivB64) {
    if (cipherB64.isEmpty || ivB64.isEmpty) return '';
    try {
      return _encrypter.decrypt64(cipherB64, iv: IV.fromBase64(ivB64));
    } catch (_) {
      return '';
    }
  }
}
```

---

### Bước 3 — Bảng SQLite (có cột owner_username)

File `lib/core/database/local_database.dart`:

**3a.** Trong `_open()` đổi `version: 8` → `version: 9`.

**3b.** Thêm hằng SQL (đặt trong class, ví dụ ngay trên hàm `_create`):

```dart
  static const _createGhiChuSql = '''
    CREATE TABLE IF NOT EXISTS ghi_chu_bao_mat (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_username TEXT NOT NULL,
      tieu_de        TEXT NOT NULL,
      tai_khoan      TEXT,
      mat_khau_enc   TEXT,
      mat_khau_iv    TEXT,
      ghi_chu        TEXT,
      created_at     TEXT,
      updated_at     TEXT
    )
  ''';
```

**3c.** Cuối hàm `_create` (trước dấu `}`), thêm:

```dart
    await db.execute(_createGhiChuSql);
```

**3d.** Cuối hàm `_onUpgrade` (sau khối `if (oldVersion < 8)`), thêm:

```dart
    if (oldVersion < 9) {
      await db.execute(_createGhiChuSql);
    }
```

**3e.** Thêm CRUD (cuối class `LocalDatabase`, có lọc theo `owner_username`):

```dart
  // ── Ghi chú bảo mật (theo user) ──────────────────────────────────────────
  Future<int> insertGhiChu(Map<String, dynamic> data) async {
    final d = await db;
    return d.insert('ghi_chu_bao_mat', data);
  }

  Future<int> updateGhiChu(int id, Map<String, dynamic> data) async {
    final d = await db;
    return d.update('ghi_chu_bao_mat', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGhiChu(int id) async {
    final d = await db;
    return d.delete('ghi_chu_bao_mat', where: 'id = ?', whereArgs: [id]);
  }

  /// Chỉ lấy ghi chú của user đang đăng nhập.
  Future<List<Map<String, dynamic>>> getGhiChuList(String ownerUsername) async {
    final d = await db;
    return d.query(
      'ghi_chu_bao_mat',
      where: 'owner_username = ?',
      whereArgs: [ownerUsername],
      orderBy: 'updated_at DESC, id DESC',
    );
  }
```

---

### Bước 4 — Model

Tạo `lib/features/ghi_chu/data/models/ghi_chu_model.dart`:

```dart
// lib/features/ghi_chu/data/models/ghi_chu_model.dart
class GhiChuModel {
  final int? id;          // null khi tạo mới
  final String tieuDe;
  final String taiKhoan;
  final String matKhau;   // plaintext trong bộ nhớ (đã giải mã)
  final String ghiChu;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GhiChuModel({
    this.id,
    required this.tieuDe,
    this.taiKhoan = '',
    this.matKhau = '',
    this.ghiChu = '',
    this.createdAt,
    this.updatedAt,
  });

  GhiChuModel copyWith({
    int? id,
    String? tieuDe,
    String? taiKhoan,
    String? matKhau,
    String? ghiChu,
  }) =>
      GhiChuModel(
        id: id ?? this.id,
        tieuDe: tieuDe ?? this.tieuDe,
        taiKhoan: taiKhoan ?? this.taiKhoan,
        matKhau: matKhau ?? this.matKhau,
        ghiChu: ghiChu ?? this.ghiChu,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
```

---

### Bước 5 — Repository (nối DB + mã hoá + lấy username hiện tại)

Tạo `lib/features/ghi_chu/data/repositories/ghi_chu_repository.dart`:

```dart
// lib/features/ghi_chu/data/repositories/ghi_chu_repository.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/database/local_database.dart';
import '../crypto_service.dart';
import '../models/ghi_chu_model.dart';

class GhiChuRepository {
  final _db = LocalDatabase.instance;
  final _crypto = NoteCryptoService();
  static const _storage = FlutterSecureStorage();

  Future<String> _currentUsername() async =>
      await _storage.read(key: 'username') ?? '';

  /// Danh sách ghi chú của user đang đăng nhập, đã giải mã mật khẩu.
  Future<List<GhiChuModel>> getAll() async {
    final owner = await _currentUsername();
    final rows = await _db.getGhiChuList(owner);
    return rows.map((r) {
      final matKhau = _crypto.decrypt(
        (r['mat_khau_enc'] as String?) ?? '',
        (r['mat_khau_iv'] as String?) ?? '',
      );
      return GhiChuModel(
        id: r['id'] as int,
        tieuDe: (r['tieu_de'] as String?) ?? '',
        taiKhoan: (r['tai_khoan'] as String?) ?? '',
        matKhau: matKhau,
        ghiChu: (r['ghi_chu'] as String?) ?? '',
        createdAt: DateTime.tryParse((r['created_at'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((r['updated_at'] as String?) ?? ''),
      );
    }).toList();
  }

  Future<void> save(GhiChuModel m) async {
    final owner = await _currentUsername();
    final (cipher, iv) = _crypto.encrypt(m.matKhau);
    final now = DateTime.now().toIso8601String();
    final data = {
      'owner_username': owner,
      'tieu_de': m.tieuDe.trim(),
      'tai_khoan': m.taiKhoan.trim(),
      'mat_khau_enc': cipher,
      'mat_khau_iv': iv,
      'ghi_chu': m.ghiChu.trim(),
      'updated_at': now,
    };
    if (m.id == null) {
      data['created_at'] = now;
      await _db.insertGhiChu(data);
    } else {
      await _db.updateGhiChu(m.id!, data);
    }
  }

  Future<void> delete(int id) => _db.deleteGhiChu(id);
}
```

---

### Bước 6 — Provider

Tạo `lib/features/ghi_chu/presentation/providers/ghi_chu_provider.dart`:

```dart
// lib/features/ghi_chu/presentation/providers/ghi_chu_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ghi_chu_model.dart';
import '../../data/repositories/ghi_chu_repository.dart';

final ghiChuRepositoryProvider =
    Provider<GhiChuRepository>((_) => GhiChuRepository());

class GhiChuListNotifier extends StateNotifier<AsyncValue<List<GhiChuModel>>> {
  final GhiChuRepository _repo;
  GhiChuListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<void> save(GhiChuModel m) async {
    await _repo.save(m);
    await load();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final ghiChuListProvider = StateNotifierProvider.autoDispose<GhiChuListNotifier,
    AsyncValue<List<GhiChuModel>>>(
  (ref) => GhiChuListNotifier(ref.watch(ghiChuRepositoryProvider)),
);
```

---

### Bước 7 — Màn danh sách (tìm kiếm không dấu)

Tạo `lib/features/ghi_chu/presentation/screens/ghi_chu_list_screen.dart`.
**Sao chép cấu trúc** từ `lib/features/khach_hang/presentation/screens/khach_hang_list_screen.dart`
(TextField + `Timer` debounce 1000ms + `_filterQuery` + filter bằng `removeDiacritics`). Khác biệt:

- `initState`: `Future.microtask(() => ref.read(ghiChuListProvider.notifier).load());`
- `ref.watch(ghiChuListProvider)` cho danh sách.
- Filter (KHÔNG lọc theo mật khẩu):

```dart
final items = _filterQuery.isEmpty
    ? allItems
    : allItems.where((g) {
        final t = removeDiacritics(g.tieuDe);
        final a = removeDiacritics(g.taiKhoan);
        final c = removeDiacritics(g.ghiChu);
        return t.contains(_filterQuery) ||
            a.contains(_filterQuery) ||
            c.contains(_filterQuery);
      }).toList();
```

- `hintText`: `'Tìm theo tiêu đề, tài khoản, ghi chú...'`.
- Mỗi item `Card`: hiện `tieuDe` (đậm) + `taiKhoan` (phụ). **Không hiện mật khẩu ở list.**
- `onTap`: `context.push(AppRoutes.ghiChuForm, extra: items[i])` rồi `load()` lại sau khi pop.
- FAB "Thêm ghi chú": `context.push(AppRoutes.ghiChuForm)` (extra null = tạo mới), sau pop `load()` lại.

---

### Bước 8 — Màn form thêm/sửa/xoá

Tạo `lib/features/ghi_chu/presentation/screens/ghi_chu_form_screen.dart`:

- `ConsumerStatefulWidget` nhận `GhiChuModel? item` (null = tạo mới).
- 4 `TextEditingController` (`tieuDe`, `taiKhoan`, `matKhau`, `ghiChu`), khởi tạo từ `item` trong `initState`.
- Ô mật khẩu: `obscureText: _obscure` + `IconButton` con mắt bật/tắt `_obscure`.
- (Tuỳ chọn) nút copy mật khẩu: `Clipboard.setData(ClipboardData(text: _matKhauCtrl.text))`
  (`import 'package:flutter/services.dart'`).
- Nút "Lưu": validate `tieuDe` không rỗng rồi:

```dart
await ref.read(ghiChuListProvider.notifier).save(
  (widget.item ?? const GhiChuModel(tieuDe: '')).copyWith(
    tieuDe: _tieuDeCtrl.text,
    taiKhoan: _taiKhoanCtrl.text,
    matKhau: _matKhauCtrl.text,
    ghiChu: _ghiChuCtrl.text,
  ),
);
if (context.mounted) context.pop();
```

- Nếu `item != null`: nút xoá (AppBar action) → `AlertDialog` xác nhận →
  `await ref.read(ghiChuListProvider.notifier).remove(widget.item!.id!);` → `context.pop()`.

---

### Bước 9 — Đăng ký route

`lib/core/router/app_routes.dart` thêm:

```dart
  static const String ghiChuList = '/ghi-chu';
  static const String ghiChuForm = '/ghi-chu/form';
```

`lib/core/router/app_router.dart`:

- Import 2 screen mới + model `GhiChuModel` ở đầu file.
- `ghiChuForm` (full-screen) đặt trong nhóm `parentNavigatorKey: _rootNavigatorKey`:

```dart
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: AppRoutes.ghiChuForm,
  pageBuilder: (_, state) => CupertinoPage(
    key: state.pageKey,
    child: GhiChuFormScreen(item: state.extra as GhiChuModel?),
  ),
),
```

- `ghiChuList` đặt trong `ShellRoute` (cạnh các route list khác):

```dart
GoRoute(
  path: AppRoutes.ghiChuList,
  builder: (_, __) => const GhiChuListScreen(),
),
```

- Trong map `_featureTitles` của `_MainShellState` thêm:
  `AppRoutes.ghiChuList: 'Ghi chú bảo mật',`

---

### Bước 10 — Lối vào từ màn Cài đặt

`lib/features/cai_dat/presentation/screens/cai_dat_screen.dart` — chèn trước mục "Đăng xuất":

```dart
_SettingTile(
  icon: Icons.sticky_note_2_outlined,
  title: 'Ghi chú bảo mật',
  subtitle: 'Lưu tài khoản, mật khẩu (đã mã hoá)',
  onTap: () => context.push(AppRoutes.ghiChuList),
),
const Divider(height: 1, indent: 56),
```

---

## Cấu trúc thư mục tạo mới

```
lib/features/ghi_chu/
├── data/
│   ├── crypto_service.dart
│   ├── models/ghi_chu_model.dart
│   └── repositories/ghi_chu_repository.dart
└── presentation/
    ├── providers/ghi_chu_provider.dart
    └── screens/
        ├── ghi_chu_list_screen.dart
        └── ghi_chu_form_screen.dart
```
File sửa: `pubspec.yaml`, `local_database.dart`, `app_routes.dart`, `app_router.dart`, `cai_dat_screen.dart`.

---

## Kiểm thử (Verification)

1. `flutter pub get` → `flutter run` (hoặc `run-usb.ps1`).
2. Đăng nhập user A → Cài đặt → Ghi chú bảo mật → thêm vài ghi chú.
3. List hiện đúng, **không** thấy mật khẩu; mở form → bấm hiện mật khẩu → đúng giá trị (giải mã ngược OK).
4. Tìm không dấu: gõ `gmail ca nhan` ra "Gmail cá nhân".
5. Đăng xuất, đăng nhập user B → **không thấy** ghi chú của user A (lọc theo `owner_username`).
6. Kill app mở lại → dữ liệu còn, mật khẩu vẫn giải mã đúng (key cố định trong code).
7. (Tuỳ chọn) pull `gasmanager.db`, xem bảng `ghi_chu_bao_mat`: cột `mat_khau_enc` là base64 rối,
   không phải plaintext → xác nhận đã mã hoá.
8. Sửa & xoá hoạt động đúng.

## Lưu ý

- **Đổi key = mất dữ liệu cũ:** đổi `_secretPassphrase` sau khi đã có dữ liệu sẽ khiến các bản ghi cũ
  giải mã ra '' (repository nuốt lỗi, không crash). Giữ nguyên key sau khi phát hành.
- Cân nhắc chuyển key sang `--dart-define` (build-time) nếu không muốn để lộ trong source.
- Không log/`debugPrint` mật khẩu.
```
