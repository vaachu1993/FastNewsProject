# 📰 FastNews - Ứng Dụng Tin Tức Flutter

Ứng dụng đọc tin tức nhanh chóng với tích hợp Firebase Authentication, Cloud Firestore và RSS Feed từ các báo lớn Việt Nam.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Tính Năng Chính

### 🔐 Xác Thực Người Dùng
- Đăng ký/Đăng nhập bằng Email & Password
- Đăng nhập nhanh với Google Sign-In
- Quản lý thông tin cá nhân
- Đăng xuất an toàn

### 📰 Tin Tức
- RSS Feed realtime từ **VnExpress**, **Tuổi Trẻ**, **Thanh Niên**
- Phân loại theo danh mục: Thể thao, Công nghệ, Kinh doanh, Sức khỏe, Chính trị, Đời sống, Giải trí, Giáo dục, Du lịch, Thế giới
- Pull-to-refresh để cập nhật tin mới
- Đọc nội dung đầy đủ bài viết
- Lọc nội dung trùng lặp thông minh

### ⭐ Bookmark & Chia Sẻ
- Lưu bài viết yêu thích
- Đồng bộ realtime với Cloud Firestore
- Chia sẻ bài viết lên các nền tảng khác

### 🎨 Giao Diện
- Material Design 3
- Hỗ trợ Dark Mode & Light Mode
- Đa ngôn ngữ (Tiếng Việt/English)
- Responsive trên nhiều kích thước màn hình
- Smooth animations & transitions

### 🔔 Thông Báo
- Push notification cho tin tức mới
- Thông báo theo danh mục quan tâm

---

## 🚀 Hướng Dẫn Chạy Dự Án

### Yêu Cầu Hệ Thống

- Flutter SDK: `>=3.9.2`
- Dart SDK: `>=3.9.2`
- Android Studio hoặc VS Code
- Tài khoản Firebase (miễn phí)

### Các Bước Cài Đặt

#### 1. Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/FastNewsProject.git
cd FastNewsProject
```

#### 2. Cài Đặt Dependencies
```bash
flutter pub get
```

#### 3. Cấu Hình Firebase

> ⚠️ **Quan trọng**: File `google-services.json` không được commit lên Git vì lý do bảo mật.

**Bước 1: Tạo Firebase Project**
- Truy cập [Firebase Console](https://console.firebase.google.com)
- Nhấn "Add project" và làm theo hướng dẫn
- Tên project: `FastNews` (hoặc tên bạn muốn)

**Bước 2: Thêm Android App**
- Trong Firebase Console, chọn "Add app" → Android
- Package name: `com.example.fastnews`
- Download file `google-services.json`
- Đặt file vào thư mục `android/app/`

**Bước 3: Cấu Hình Authentication**
- Trong Firebase Console, vào **Authentication** → **Sign-in method**
- Enable **Email/Password**
- Enable **Google Sign-In**

**Bước 4: Cấu Hình Firestore Database**
- Trong Firebase Console, vào **Firestore Database**
- Chọn "Create database" → Start in **test mode**
- Copy rules từ file `firestore.rules` trong dự án
- Paste vào Firestore Rules và Publish

**Bước 5: Lấy SHA-1 Certificate (cho Google Sign-In)**
```bash
cd android
gradlew.bat signingReport
```
- Copy SHA-1 từ kết quả
- Vào Firebase Console → Project Settings → Your apps
- Thêm SHA-1 certificate fingerprint
- Download lại `google-services.json` mới và thay thế

#### 4. Chạy Ứng Dụng

**Chạy trên emulator/device:**
```bash
flutter run
```

**Build APK:**
```bash
flutter build apk --release
```

**Build App Bundle:**
```bash
flutter build appbundle --release
```

---

## 🐛 Xử Lý Lỗi Thường Gặp

### Lỗi: "google-services.json not found"

**Nguyên nhân:** Thiếu file cấu hình Firebase

**Giải pháp:**
1. Download file từ Firebase Console
2. Đặt vào `android/app/google-services.json`
3. Chạy:
```bash
flutter clean
flutter pub get
```

### Lỗi: "PlatformException(sign_in_failed)" khi đăng nhập Google

**Nguyên nhân:** Thiếu SHA-1 certificate

**Giải pháp:**
```bash
cd android
gradlew.bat signingReport
```
Copy SHA-1 → Thêm vào Firebase Console → Download lại `google-services.json`

### Lỗi: "Permission denied" trong Firestore

**Nguyên nhân:** Firestore Rules chưa được cấu hình đúng

**Giải pháp:** 
- Vào Firestore Console
- Copy rules từ file `firestore.rules`
- Paste vào Firestore Rules → Publish

### Lỗi Build

```bash
flutter clean
flutter pub get
cd android
gradlew.bat clean
cd ..
flutter run
```

---

## 📞 Liên Hệ & Hỗ Trợ

Nếu gặp vấn đề khi chạy dự án:
- 🐛 [Tạo Issue](https://github.com/yourusername/FastNewsProject/issues)
- 📧 Email: your.email@example.com

---

<div align="center">

**⭐ Nếu thấy hữu ích, hãy cho dự án một ngôi sao! ⭐**

Made with ❤️ using Flutter & Firebase

</div>

