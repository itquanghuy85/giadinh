# Tài liệu kiến trúc & luồng ứng dụng — Family Finance (Tiếng Việt)

Phiên bản: 1.0
Ngày tạo: 2026-05-08
Người viết: GitHub Copilot (hướng dẫn cho người mới đọc code)

Mục lục
- Tổng quan dự án
- Công nghệ chính & packages
- Cấu trúc thư mục (chi tiết)
- Theme / Typography / Màu sắc / Khoảng cách
- Navigation & Routes
- State management (Riverpod) — pattern và providers chính
- Services & Repositories (Firestore service, Location, Finance, Photo, Debt, Fund)
- Model dữ liệu (fields chi tiết cho mỗi collection)
- Luồng nghiệp vụ chính (Add Transaction, Transfer, Deposit/Withdraw quỹ, Pay Debt, Share Location, Photo upload)
- Mô tả chi tiết từng màn hình (view) + actions + dữ liệu + provider liên quan
- Quy tắc đặt tên, format ngày giờ và tiền tệ
- Chạy, debug, phân nhánh git và hướng dẫn push lên GitHub
- Phụ lục: file quan trọng, gợi ý test và checklist

---

## 1) Tổng quan dự án
Family Finance là một ứng dụng quản lý tài chính gia đình kèm tính năng chia sẻ vị trí và kỷ niệm.
Mục tiêu: theo dõi ví cá nhân/ví gia đình, ghi giao dịch (income/expense/transfer), quản lý quỹ, công nợ, lịch sự kiện/kỷ niệm, ảnh gia đình, và chia sẻ vị trí thành viên.

Ứng dụng dùng Flutter (Material 3), Riverpod, Firestore, Google Maps.

## 2) Công nghệ chính & packages
- Flutter (>= 3.x)
- Dart (null-safe)
- Riverpod 2.x (StateProvider, StreamProvider.autoDispose, Provider)
- Firebase: Firestore, Auth, Storage
- Packages chính:
  - google_maps_flutter
  - geolocator ^13.0.4
  - url_launcher
  - cached_network_image
  - table_calendar
  - share_plus
  - flutter_local_notifications
  - intl
  - google_fonts

## 3) Cấu trúc thư mục (chi tiết)
(đây là tóm tắt thư mục quan trọng — mở file để xem code cụ thể)

- `lib/`
  - `app/`
    - `routes/app_routes.dart` : hằng số route (ví dụ `/memories`)
    - `routes/app_router.dart` : onGenerateRoute
    - `theme/app_colors.dart` : mã màu dùng trong app
    - `theme/app_space.dart` : spacing + radius
    - `theme/app_theme.dart` : ThemeData (light/dark) — typography, button styles
  - `features/`
    - `auth/` : đăng nhập/đăng ký, provider `auth_provider.dart`
    - `transaction/` : giao dịch, màn hình `add_transaction_screen.dart`, dịch vụ `finance_service.dart` (batch writes)
    - `wallet/` : ví, wallet dialog
    - `family/` : giao diện gia đình, bản đồ, thành viên, ảnh, kỷ niệm
    - `calendar/` : calendar screen, providers
    - `fund/` : quỹ gia đình (nạp/rút)
    - `debt/` : công nợ
    - `report/` : báo cáo
  - `shared/`
    - `models/` : model domain (WalletModel, TransactionModel, FamilyPhoto, Anniversary, DebtModel, FundModel, FamilyEvent...)
    - `services/` : firestore_service.dart, photo_upload_service.dart, location_sharing_service.dart, transaction_notification_handler, etc.
    - `widgets/` : app shell, secure money text, back button, role guard...

Gợi ý: đọc lần lượt `shared/services/firestore_service.dart` để thấy các query & path Firestore.

## 4) Theme / Typography / Màu sắc / Khoảng cách
Ứng dụng sử dụng `GoogleFonts.interTextTheme()` (Inter) trong `AppTheme`.

- Font chính: Inter (GoogleFonts)
- Các kích thước text mapping (từ `lib/app/theme/app_theme.dart`):
  - `headlineLarge` 26 (w700)
  - `headlineMedium` 22
  - `titleLarge` 18
  - `titleMedium` 15
  - `titleSmall` 13
  - `bodyLarge` 14
  - `bodyMedium` 13
  - `bodySmall` 12
  - `labelLarge` 13
  - `labelMedium` 12
  - `labelSmall` 11

- Màu sắc chính trong `AppColors` (`lib/app/theme/app_colors.dart`):
  - `primary`: #2F5BD3
  - `income`: #0B8F65
  - `expense`: #D94141
  - `warning`: #E68A00
  - `transfer`: #2778D8
  - `background`: #F2F4F8
  - `surface`: #FFFFFF
  - `border`: #D9E0EA
  - `subtle`: #E9EEF6
  - `textPrimary`: #0F1722
  - `textSecondary`: #5A6678
  - `textMuted`: #8B97A8

- Spacing (`AppSpace`): xs=4, sm=8, md=12, lg=16, xl=20, xxl=24
- Radii (`AppRadius`): sm=8, md=10, lg=12, xl=14
- Buttons: FilledButton default background `AppColors.primary`, height ~40, rounding `AppRadius.md`.
- Input fields: `filled: true`, fillColor = `AppColors.surface`, focused border color `AppColors.primary` width 1.5.

Ghi chú: Dark theme có palette riêng (tham khảo `AppTheme.dark()`)

## 5) Navigation & Routes
- `AppRoutes` chứa các route name, ví dụ: `/login`, `/wallet-detail`, `/debt`, `/fund`, `/family`, `/family-map-members`, `/family-map-view`, `/memories`.
- `AppRouter.onGenerateRoute` khởi tạo màn hình theo `settings.name`.
- Truy cập màn hình thường dùng `Navigator.pushNamed(context, AppRoutes.memories)` hoặc `Navigator.push(MaterialPageRoute(...))` khi cần fullscreen dialog.

## 6) State management (Riverpod) — pattern & providers chính
- Dùng `Provider`, `StreamProvider.autoDispose`, `StateProvider.autoDispose`.
- Quy ước: providers ở `features/*/providers/*.dart`.
- Một số provider chung: `firestoreServiceProvider`, `authControllerProvider`, `photoUploadServiceProvider`, `financeServiceProvider`.
- Luồng data: màn hình lắng nghe provider (ref.watch(...)) → hiển thị async snapshots → thao tác gọi `ref.read(serviceProvider).method(...)` để thực hiện hành động (không trực tiếp thao tác Firestore từ UI).

## 7) Services & Repositories (chi tiết)
- `firestore_service.dart` (shared/services)
  - Bao gồm query/stream/CRUD cho: transactions, wallets, family members, events, debts, funds, photos, live_locations, notifications.
  - Key methods: `streamEvents`, `getEventsByDate`, `streamWalletTransactions`, `transferBetweenWallets`, `markDebtPaid`, `depositToFund`, `withdrawFromFund`, v.v.

- `finance_service.dart` (features/transaction/data)
  - Mục đích: tập trung tất cả luồng tài chính bằng batch write (addIncome, addExpense, addTransfer, editTransaction, deleteTransaction, depositToFund, withdrawFromFund, payDebt, adjustBalance).
  - Luồng: luôn dùng batch commit để cập nhật balance + tạo/xóa transaction docs.

- `location_sharing_service.dart`
  - Chia sẻ vị trí: lưu document trong `families/{familyId}/live_locations` hoặc `users/{uid}/sharedLocation` (tùy impl). Field: lat, lng, updatedAt, displayName, expiresAt.

- `photo_upload_service.dart`
  - Upload ảnh lên Firebase Storage và lưu metadata vào `families/{familyId}/photos` với fields: imageUrl, thumbnailUrl, uploadedBy, uploadedAt, takenAt, caption.

- `debt_service`, `fund_service` — wrapper CRUD + batch khi cần.

## 8) Firestore structure và field chi tiết
(Lưu ý: dựa trên code; các field có thể khác nhỏ, kiểm tra model file nếu cần.)

- `users/{uid}`
  - user profile fields: `uid`, `email`, `displayName`, `familyId`, `role` (fatherAdmin/motherManager/childLimited), `createdAt`...
  - Subcollections:
    - `wallets/{walletId}`
      - `id` (doc id), `name` (String), `balance` (double), `colorHex` (String), `ownerUid` (String), `isShared` (bool)
    - `transactions/{txId}`
      - `walletId` (String)
      - `destWalletId` or `sourceWalletId` (String) for transfer pairs
      - `amount` (double)
      - `type` (String): 'income'|'expense'|'transfer'
      - `category` (String)
      - `note` (String)
      - `createdAt` (Timestamp)
      - `createdBy` (uid)
      - `ownerUid` (uid)

- `families/{familyId}`
  - `members/{uid}`: Family member profiles: `uid`, `displayName`, `email`, `role`, `joinedAt`.
  - `events/{eventId}` (FamilyEvent)
    - `title`, `startAt` (Timestamp), `assignee` (String), `repeat` (String), `colorHex`, `description`, `createdBy`, `createdAt`.
  - `photos/{photoId}` (FamilyPhoto)
    - `imageUrl`, `thumbnailUrl`, `uploadedBy`, `uploadedAt`, `takenAt` (optional), `caption`.
  - `anniversaries/{id}` (Anniversary)
    - `title`, `date` (Timestamp), `type` ('birthday'/'wedding'/'custom'), `isAnnual`, `createdBy`, `createdAt`.
  - `funds/{fundId}` (FundModel)
    - `name`, `goalAmount`, `currentAmount`, `createdBy`, `createdAt`.
  - `debts/{debtId}` (DebtModel)
    - `title`, `amount`, `dueDate`, `status` ('open'/'paid'), `lenderUid`/`borrowerUid` etc.
  - `live_locations` (or per-user docs): lat, lng, updatedAt, displayName, expiresAt.
  - `notifications/{id}`: `title`, `body`, `at` (timestamp)

Gợi ý xác thực: mở `shared/models/*.dart` để thấy mapping fromMap/toMap chi tiết.

## 9) Models chính (ví dụ, fields cụ thể)
- `TransactionModel` (ví dụ trong `shared/models/transaction.dart`)
  - id: String
  - walletId: String
  - amount: double
  - type: String ('income'|'expense'|'transfer')
  - category: String
  - note: String
  - createdAt: DateTime
  - createdBy: String
  - ownerUid: String
  - optional: destWalletId, sourceWalletId

- `WalletModel` (shared/models/wallet.dart)
  - id, name, balance (double), colorHex, ownerUid, isShared(bool)

- `FamilyEvent`, `FamilyPhoto`, `Anniversary`, `FundModel`, `DebtModel` — mở từng file model để xem đầy đủ mapping (fromMap/toMap).

## 10) Luồng nghiệp vụ quan trọng (mô tả step-by-step)
### A) Thêm giao dịch (income/expense)
1. Người dùng mở `AddTransactionScreen` và nhập dữ liệu.
2. UI gọi `ref.read(financeServiceProvider).addIncome(...)` hoặc `addExpense(...)`.
3. `FinanceService` tạo `WriteBatch`:
   - Cập nhật `wallet.balance` bằng FieldValue.increment(+amount or -amount)
   - Tạo document trong `users/{uid}/transactions` với dữ liệu tx (amount, type, category, createdAt,...)
   - Ghi commit batch.
4. UI nhận kết quả (try/catch), hiển thị SnackBar; không đóng form nếu lỗi.

### B) Chuyển tiền (transfer)
1. UI gửi `addTransfer(uid, sourceWalletId, destWalletId, amount, note, createdBy)`.
2. `FinanceService` kiểm tra số dư source >= amount; nếu ok thì batch:
   - update source.balance += -amount
   - update dest.balance += amount
   - tạo 2 transaction docs: one for transfer (out), one for income (Nhận chuyển khoản) for dest
   - commit batch

### C) Chỉnh sửa giao dịch (`editTransaction`)
- Luồng: đọc transaction cũ, đảo ngược tác động lên wallet(s) (increment/decrement) rồi áp dụng bản mới, cập nhật document tx trong batch.

### D) Xóa giao dịch (`deleteTransaction`)
- Nếu là transfer: tìm cặp chuyển (source/dest), điều chỉnh balance cho wallet(s) đảo ngược, xóa cả hai doc nếu cần.
- Luồng dùng batch.

### E) Nạp/rút quỹ (Fund)
- `depositToFund`: trừ ví (wallet.balance -= amount), cộng fund.currentAmount += amount, tạo expense tx ghi chú 'Nạp quỹ'.
- `withdrawFromFund`: kiểm tra fund đủ tiền, giảm fund.currentAmount, cộng vào wallet, tạo income tx 'Rút quỹ'.

### F) Trả nợ (Debt)
- `payDebt(uid, familyId, debt, createdBy, walletId)`: batch cập nhật debt.status='paid', cập nhật wallet (theo hướng nợ/lend), tạo tx tương ứng.

### G) Chia sẻ vị trí
- `LocationSharingService.shareMyLocation(uid, name)`:
  - Lấy vị trí thiết bị (Geolocator)
  - Lưu vào Firestore doc (ví dụ `families/{familyId}/live_locations/{uid}` hoặc `users/{uid}/sharedLocation`) với fields: lat, lng, updatedAt, displayName, expiresAt (24 giờ)
- Màn hình `FamilyMapMembersScreen` lắng nghe stream vị trí từng member thông qua `LocationSharingService.watchMemberLocation(uid)`.

### H) Ảnh kỷ niệm
- Upload storage + lưu metadata collection `families/{familyId}/photos`.
- `family_screen` hiển thị preview 2 ảnh; `memories_screen` có grid đầy đủ.

## 11) Mô tả từng màn hình (view) — file liên quan, provider & actions
Lưu ý: đây là checklist để người mới đọc code theo thứ tự.

- `HomeScreen` (`lib/features/home/presentation/home_screen.dart`)
  - Hiển thị tổng quan: balance, xu hướng 7 ngày, shortcut đến ví, lịch, gia đình.
  - Providers: `walletsProvider`, `transactionsProvider`.
  - Actions: mở Wallet, xem báo cáo, chuyển nhanh.

- `WalletScreen` / `WalletDetailScreen`
  - Xem danh sách ví, chi tiết 1 ví, danh sách giao dịch (streamWalletTransactions)
  - Actions: Thêm chỉnh sửa ví, điều chỉnh số dư (gọi `financeService.adjustBalance`), thêm giao dịch.

- `AddTransactionScreen` (`features/transaction/presentation/add_transaction_screen.dart`)
  - Trường: amount, wallet, type, category, note, date
  - Gọi `financeService` tương ứng.

- `FamilyScreen` (`features/family/presentation/family_screen.dart`)
  - Sections: Thành viên, Ảnh kỷ niệm (preview 2), Sự kiện sắp tới (preview 3), Kỷ niệm, Quỹ gia đình, Công nợ.
  - Providers: `familyMembersProvider`, `familyPhotosPreviewProvider`, `familyUpcomingEventsProvider`, `familyAnniversariesProvider`, `familyFundsProvider`, `familyDebtsProvider`.
  - Actions: mở `memories`, mở `FamilyMapMembersScreen`, thêm ảnh, thêm kỷ niệm, thêm thành viên (role-guarded).

- `FamilyMapMembersScreen` (`features/family/presentation/family_map_members_screen.dart`)
  - List thành viên + status dot (isSharing), distance (nếu có vị trí mình), FAB chia sẻ/xóa vị trí.
  - Provider: `_memberLocationProvider` (StreamProvider.family), `LocationSharingService`.
  - ModalBottomSheet: xem bản đồ, dẫn đường, đóng.

- `FamilyMapViewScreen` (`features/family/presentation/family_map_view_screen.dart`)
  - Hiển thị GoogleMap với 2 marker (member đỏ, tôi xanh).
  - Camera fit 2 marker; nút Dẫn đường full-width (màu #534AB7) mở `google.navigation:` hoặc fallback `https://www.google.com/maps/dir`.

- `MemoriesScreen` (mới)
  - Tab 1: PhotoMemoriesTab (grid)
  - Tab 2: AnniversaryTab (grouped list)

- `CalendarScreen`
  - Bảng lịch (`TableCalendar`), eventLoader dùng `familyEventsProvider` để đánh dấu
  - `selectedDayEventsProvider` bây giờ query Firestore theo ngày (streamEventsByDate)
  - Phần 'Tháng này: X sự kiện' dùng `monthlyEventCountProvider`.

- `FundScreen`, `DebtScreen`
  - Gọi `financeService.depositToFund`, `withdrawFromFund`, `payDebt` theo logic.

## 12) Quy tắc tiền tệ & định dạng
- Sử dụng `intl` để format ngày và tiền tệ.
- Trong UI: tiền thường hiển thị số nguyên (no decimals) hoặc format tuỳ màn hình; áp dụng `MoneyFormatter` helper nếu có.

## 13) Chạy, commit và push lên GitHub (hướng dẫn)
Tôi đã tạo file tài liệu tại `docs/APP_ARCHITECTURE_AND_FLOW_VN.md` trong repo.

Để commit và push lên GitHub (nếu bạn muốn tôi thực hiện tự động, cung cấp URL remote hoặc đảm bảo `origin` đã cấu hình), các lệnh mẫu:

```bash
# commit file
git add docs/APP_ARCHITECTURE_AND_FLOW_VN.md
git commit -m "docs: add detailed architecture & flow (Vietnamese)"

# nếu đã có remote origin
git push origin main

# nếu chưa có remote — ví dụ tạo repo trên GitHub rồi:
git remote add origin git@github.com:yourusername/yourrepo.git
git push -u origin main
```

Nếu bạn muốn tôi thử push từ môi trường này, cho tôi biết `git remote` (URL) hoặc cho phép tôi `git remote add` với URL bạn cung cấp.

## 14) Gợi ý test & checklist cho người mới
- Mở app, kiểm tra flows sau:
  - Đăng ký/Đăng nhập
  - Tạo ví + nạp tiền (sử dụng adjustBalance)
  - Thêm giao dịch income/expense/transfer — kiểm tra balance cập nhật
  - Tạo quỹ, nạp/rút quỹ
  - Tạo/cập nhật/xóa sự kiện, kiểm tra Calendar
  - Upload ảnh, kiểm tra `memories`
  - Chia sẻ vị trí: bật quyền location → chia sẻ → xem map
- Chạy `flutter analyze` và fix warnings theo guideline (dùng `const` nơi cần)

## 15) Phụ lục — file tham chiếu nhanh
- `lib/shared/services/firestore_service.dart` — index các query Firestore
- `lib/features/transaction/data/finance_service.dart` — batch tài chính
- `lib/app/theme/app_theme.dart` — typography & styles
- `lib/app/theme/app_colors.dart` — palette
- `lib/features/family/presentation/family_screen.dart` — family overview
- `lib/features/family/presentation/family_map_members_screen.dart` — map members
- `lib/features/family/presentation/family_map_view_screen.dart` — map view
- `lib/features/calendar/providers/calendar_provider.dart` — provider ngày đã chỉnh

---

Nếu bạn muốn, tôi sẽ:
- mở rộng thêm phần Model bằng extract tự động từ `lib/shared/models/*.dart` để liệt kê đầy đủ fields (tự động),
- hoặc tự động push file này lên GitHub nếu bạn cung cấp URL repo (hoặc cho phép dùng remote hiện có).

Bạn muốn tiếp theo là tôi:
- [A] tự động extract mọi model fields vào phần "Models chính" (tạo bảng chi tiết),
- [B] thử commit + push file này (yêu cầu remote URL hoặc quyền),
- [C] tạo checklist PR template / CONTRIBUTING.md để hậu kiểm?"