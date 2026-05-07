# CHECKLIST CUỐI - APP QUẢN LÝ TÀI CHÍNH GIA ĐÌNH

> **Dành cho người chủ dự án không phải lập trình viên.**
> Làm theo từng bước theo thứ tự. Đọc kỹ trước khi làm.

---

## ✅ TRẠNG THÁI HIỆN TẠI

| Hạng mục | Trạng thái |
|---|---|
| Flutter analyze (0 lỗi) | ✅ HOÀN THÀNH |
| Đăng nhập Email + Google + Sinh trắc học | ✅ HOÀN THÀNH |
| Seed dữ liệu mẫu tự động | ✅ HOÀN THÀNH |
| Dữ liệu realtime (Firestore streams) | ✅ HOÀN THÀNH |
| Phân quyền 3 vai trò (Ba/Mẹ/Con) | ✅ HOÀN THÀNH |
| AndroidManifest.xml đầy đủ permissions | ✅ HOÀN THÀNH |
| Info.plist NSFaceIDUsageDescription | ✅ HOÀN THÀNH |
| Firestore Security Rules | ✅ HOÀN THÀNH |
| Firestore Indexes | ✅ HOÀN THÀNH |
| Build APK debug | ✅ THÀNH CÔNG |

---

## 🔑 BƯỚC 1 — LẤY SHA-1 ĐỂ GOOGLE SIGN-IN HOẠT ĐỘNG

Google Sign-In yêu cầu bạn phải đăng ký SHA-1 fingerprint vào Firebase Console.

### 1.1. Lấy SHA-1 của máy lập trình (debug)

Mở terminal trong thư mục dự án, chạy:

```
cd android
gradlew signingReport
```

Tìm dòng có `Variant: debugAndroidTest` hoặc `Variant: debug`:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Sao chép chuỗi SHA-1 đó.

### 1.2. Thêm SHA-1 vào Firebase Console

1. Truy cập: https://console.firebase.google.com/project/giadinh-ca079/settings/general
2. Cuộn xuống phần **"Ứng dụng của bạn"** → chọn ứng dụng Android
3. Nhấn **"Thêm vân tay"**
4. Dán chuỗi SHA-1 vừa sao chép → nhấn **Lưu**
5. Tải lại file `google-services.json` mới → thay vào `android/app/google-services.json`

---

## 🔥 BƯỚC 2 — TRIỂN KHAI FIRESTORE RULES VÀ INDEXES

⚠️ **PHẢI làm bước này trước khi chạy app lần đầu, nếu không tab Lịch/Gia đình sẽ loading vô tận!**

Cài Firebase CLI nếu chưa có:
```
npm install -g firebase-tools
firebase login
```

Triển khai rules và indexes:
```
cd D:\FlutterProjects\Family
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

**Kiểm tra kết quả:**
- Terminal sẽ hiện `✔  Deploy complete!`
- Nếu có lỗi: xem lại firestore.rules có syntax error không

> **⚠️ NẾU QUÊN DEPLOY RULES:**
> - Tab Lịch sẽ loading mãi
> - Tab Gia đình sẽ loading mãi  
> - VSCode console sẽ hiện `[Family] ❌ streamFamilyMembers error: Permission denied`
> - **Cách fix:** Deploy rules ngay, rồi đăng xuất/đăng nhập lại app

---

## 📱 BƯỚC 3 — CHẠY APP LẦN ĐẦU

Kết nối điện thoại Android qua USB hoặc mở máy ảo (emulator), sau đó:

```
cd D:\FlutterProjects\Family
flutter run
```

Hoặc build APK rồi cài tay:
```
flutter build apk --debug
```
File APK sẽ nằm tại: `build\app\outputs\flutter-apk\app-debug.apk`

---

## 🗺️ BƯỚC 4 — BẢN ĐỒ GIA ĐÌNH (TỐI ƯU CHI PHÍ, ỔN ĐỊNH)

Mục tiêu vận hành:
- Chỉ xem vị trí realtime trong app.
- Chỉ mở Google Maps khi bấm **"Dẫn đường"**.
- Không làm dẫn đường nội bộ trong app.
- Không bật thêm dịch vụ Google tính phí không cần thiết.

Flow đúng khi sử dụng:
1. Mở app.
2. Vào tab **Bản đồ**.
3. Xem vị trí realtime các thành viên.
4. Bấm vào thành viên để xem thông tin (tên, khoảng cách, pin, trạng thái, vị trí gần đúng).
5. Chỉ khi cần đi tới thì bấm **"Dẫn đường"** để mở Google Maps.

Thiết lập Google Cloud tối thiểu (giảm chi phí):
1. Chỉ bật:
  - **Maps SDK for Android**
  - **Maps SDK for iOS**
2. Không bắt buộc bật:
  - Routes API / Directions API
  - Distance Matrix API
  - Geocoding API

Lưu ý:
- Địa chỉ gần đúng trong app dùng geocoder của hệ điều hành và có cơ chế cache để giảm request lặp.
- Nếu thành viên offline hoặc vị trí quá cũ, app sẽ cảnh báo trước khi dẫn đường.

---

## 🌟 LẦN ĐẦU KHỞI CHẠY — NHỮNG GÌ SẼ XẢY RA

1. **Màn hình đăng nhập** xuất hiện.
2. Đăng nhập bằng Email/Password hoặc Google.
3. App tự động tạo hồ sơ gia đình cho bạn với vai trò **Trưởng gia đình (fatherAdmin)**.
4. App tự động tạo **dữ liệu mẫu**:
   - 3 ví: Tiền mặt, Ngân hàng, Momo
   - 10 giao dịch trong tháng này
   - 2 sự kiện lịch hàng ngày
   - 1 quỹ du lịch
   - 1 công nợ mẫu
5. Sinh trắc học (vân tay/Face ID) sẽ kích hoạt tự động nếu thiết bị hỗ trợ.

---

## 👨‍👩‍👧 VAI TRÒ TRONG GIA ĐÌNH

| Vai trò | Quyền hạn |
|---|---|
| **Ba (fatherAdmin)** | Toàn quyền: xem, sửa, xóa, thêm thành viên, quản lý quỹ, công nợ |
| **Mẹ (motherManager)** | Xem báo cáo, quản lý thu chi, quản lý lịch. Không thêm thành viên |
| **Con (childLimited)** | Chỉ xem giao dịch của bản thân, không thấy báo cáo gia đình |

---

## 🔧 PHÂN TÍCH KỸ THUẬT (Dành cho lập trình viên)

### Firebase Project
- **Project ID**: `giadinh-ca079`
- **Android App ID**: `1:10762035761:android:18649c685a13db39ab6b10`
- **Package name**: `com.huluca.family`

### Cấu trúc Firestore
```
users/{uid}
  wallets/{walletId}
  transactions/{txId}

families/{familyId}
  members/{uid}
  events/{eventId}
  funds/{fundId}
  debts/{debtId}
```

### Flutter packages chính
- `firebase_core` 3.15.2, `firebase_auth` 5.7.0, `cloud_firestore` 5.6.12
- `flutter_riverpod` 2.6.1 (StreamProvider.autoDispose)
- `local_auth` 2.3.0 (sinh trắc học)
- `fl_chart` 0.68.0 (biểu đồ)
- `table_calendar` 3.1.3 (lịch)

### Lệnh thường dùng
```bash
# Phân tích code
flutter analyze

# Chạy app
flutter run

# Build APK debug
flutter build apk --debug

# Build APK release (cần keystore)
flutter build apk --release

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes
```

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Google Sign-In sẽ báo lỗi Error 10** nếu chưa thêm SHA-1 vào Firebase Console.
2. **Sinh trắc học** hoạt động tùy thiết bị. Nếu thiết bị không hỗ trợ, app vẫn chạy bình thường.
3. **Dữ liệu mẫu** chỉ được tạo một lần duy nhất (kiểm tra field `isSeeded` trong Firestore).
4. Khi deploy production, cần build release APK và ký với keystore riêng.

---

*Tạo tự động ngày: $(date)*
