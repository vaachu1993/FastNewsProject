# 📰 FastNews - Flutter News App

Ứng dụng tin tức nhanh với Firebase Authentication, Firestore, và RSS Feed.

## ✨ Tính năng

- 🔐 **Xác thực người dùng**
  - Đăng ký/Đăng nhập bằng Email & Password
  - Đăng nhập bằng Google
  - Quản lý profile

- 📰 **Tin tức**
  - RSS Feed từ VnExpress, Tuổi Trẻ, Thanh Niên
  - Phân loại theo danh mục (Thể thao, Công nghệ, Kinh doanh, v.v.)
  - Refresh để cập nhật tin mới

- ⭐ **Bookmark**
  - Lưu bài viết yêu thích
  - Realtime sync với Firestore
  - Quản lý bookmark dễ dàng

- 🎨 **UI/UX**
  - Material Design 3
  - Responsive design
  - Loading states & animations

---

## 🚀 Cài đặt

### **Yêu cầu:**

- Flutter SDK: `^3.9.2`
- Dart SDK: `^3.9.2`
- Android Studio / VS Code
- Firebase account

### **Bước 1: Clone repository**

```bash
git clone https://github.com/YOUR_USERNAME/FastNewsProject.git
cd FastNewsProject
```

### **Bước 2: Cài đặt dependencies**

```bash
flutter pub get
```

### **Bước 3: Cấu hình Firebase**

#### 3.1. Tạo Firebase Project

1. Vào [Firebase Console](https://console.firebase.google.com)
2. Click **"Add project"** hoặc chọn project có sẵn
3. Tên project: `fastnews-app` (hoặc tên bạn muốn)
4. Enable Google Analytics (tùy chọn)
5. Click **"Create project"**

#### 3.2. Thêm Android App

1. Trong Firebase project → Click **"Add app"** → Chọn **Android**
2. **Android package name**: `com.example.fastnews`
3. **App nickname**: `FastNews` (tùy chọn)
4. **Debug signing certificate SHA-1**: 
   ```bash
   cd android
   gradlew.bat signingReport
   ```
   Hoặc:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
   Copy SHA-1 và paste vào Firebase

5. Click **"Register app"**

#### 3.3. Download google-services.json

1. Download file `google-services.json`
2. Đặt vào: `android/app/google-services.json`
3. **⚠️ QUAN TRỌNG**: File này đã được thêm vào `.gitignore` - KHÔNG commit lên Git!

#### 3.4. Enable Authentication

1. Firebase Console → **Authentication** → **Get started**
2. Tab **Sign-in method**:
   - Enable **Email/Password**
   - Enable **Google**
     - Chọn support email
     - Click Save

#### 3.5. Tạo Firestore Database

1. Firebase Console → **Firestore Database** → **Create database**
2. Chọn **Production mode**
3. Location: `asia-southeast1` (Singapore) hoặc `asia-east1` (Taiwan)
4. Click **Enable**

#### 3.6. Cấu hình Firestore Rules

1. Trong Firestore Database → Tab **Rules**
2. Paste rules sau:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /bookmarks/{bookmarkId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. Click **Publish**

### **Bước 4: Chạy app**

```bash
flutter run
```

Hoặc chọn device trong IDE và nhấn **Run**.

---

## 📁 Cấu trúc project

```
lib/
├── main.dart                          # Entry point
├── models/
│   └── article_model.dart             # Article data model
├── screens/
│   ├── login_screen.dart              # Đăng nhập
│   ├── signup_screen.dart             # Đăng ký
│   ├── main_screen.dart               # Bottom navigation
│   ├── home_screen.dart               # Trang chủ
│   ├── discover_screen.dart           # Khám phá
│   ├── bookmark_screen.dart           # Tin đã lưu
│   ├── profile_screen.dart            # Trang cá nhân
│   └── article_detail_screen.dart     # Chi tiết bài viết
├── services/
│   ├── auth_service.dart              # Firebase Auth service
│   ├── firestore_service.dart         # Firestore service
│   └── rss_service.dart               # RSS feed service
├── utils/
│   └── date_formatter.dart            # Date formatting utilities
└── widgets/
    └── article_card_horizontal.dart   # Article card component

android/
└── app/
    ├── google-services.json           # ⚠️ KHÔNG commit file này!
    └── build.gradle.kts               # Android build config

ios/
└── Runner/
    └── GoogleService-Info.plist       # ⚠️ KHÔNG commit file này!
```

---

## 🔧 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  google_sign_in: ^6.2.1
  
  # Networking & RSS
  http: ^1.2.0
  xml: ^6.3.0
  html: ^0.15.4
  crypto: ^3.0.3
  
  # Others
  url_launcher: ^6.2.2
  cupertino_icons: ^1.0.8
```

---

## 🎯 Sử dụng

### **Đăng ký tài khoản**

1. Mở app → Màn hình Login
2. Nhấn **"Don't have an account? Sign up"**
3. Nhập: Full Name, Email, Password
4. Nhấn **"Sign up"**
5. Tự động chuyển sang màn hình chính

### **Đăng nhập**

**Cách 1: Email & Password**
1. Nhấn **"Sign in with password"**
2. Nhập email và password
3. Nhấn **"Đăng nhập"**

**Cách 2: Google**
1. Nhấn **"Continue with Google"**
2. Chọn tài khoản Google
3. Tự động đăng nhập

### **Bookmark bài viết**

1. Vào **Home** → Chọn bài viết
2. Trong chi tiết bài viết → Nhấn icon **Bookmark** (góc phải AppBar)
3. Icon đổi màu xanh → Đã lưu
4. Vào tab **"Saved"** để xem danh sách bookmark

### **Đăng xuất**

1. Vào tab **"Profile"**
2. Nhấn icon **Logout** (góc phải AppBar)
3. Confirm → Quay về màn hình Login

---

## 🔐 Bảo mật

### **File KHÔNG được commit:**

❌ `android/app/google-services.json`  
❌ `ios/Runner/GoogleService-Info.plist`  
❌ `lib/firebase_options.dart`  
❌ `.env` files

File `.gitignore` đã được cấu hình để bảo vệ các file này.

### **Kiểm tra trước khi push:**

```bash
# Kiểm tra google-services.json có được ignore không
git check-ignore android/app/google-services.json

# Output mong đợi: android/app/google-services.json
```

---

## 🐛 Troubleshooting

### **Lỗi: "google-services.json not found"**

**Giải pháp:**
1. Download `google-services.json` từ Firebase Console
2. Đặt vào `android/app/google-services.json`
3. Chạy `flutter clean && flutter pub get`

### **Lỗi: "PlatformException(sign_in_failed)"**

**Nguyên nhân:** Thiếu SHA-1 certificate

**Giải pháp:**
1. Lấy SHA-1: `cd android && gradlew.bat signingReport`
2. Thêm SHA-1 vào Firebase Console
3. Download lại `google-services.json`
4. `flutter clean && flutter run`

### **Lỗi: "Permission denied" trong Firestore**

**Nguyên nhân:** Firestore Rules chưa được cấu hình

**Giải pháp:**
1. Vào Firestore Database → Rules
2. Copy rules từ phần "Cấu hình Firestore Rules" ở trên
3. Nhấn Publish

---

## 📊 Firebase Structure

```
Firestore:
  users (collection)
    ├── {userId} (document)
         ├── name: string
         ├── email: string
         ├── photoUrl: string (optional)
         ├── createdAt: timestamp
         ├── loginMethod: string ("email" or "google")
         └── bookmarks (subcollection)
              └── {articleHash} (document)
                   ├── title: string
                   ├── link: string
                   ├── description: string
                   ├── imageUrl: string
                   ├── source: string
                   ├── pubDate: string
                   └── bookmarkedAt: timestamp
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)

---

## 🙏 Acknowledgments

- [Firebase](https://firebase.google.com) - Backend services
- [VnExpress](https://vnexpress.net), [Tuổi Trẻ](https://tuoitre.vn), [Thanh Niên](https://thanhnien.vn) - RSS feeds
- [Flutter](https://flutter.dev) - UI framework

---

## 📞 Support

Nếu gặp vấn đề:
1. Kiểm tra [Troubleshooting](#-troubleshooting)
2. Xem [Issues](https://github.com/yourusername/FastNewsProject/issues)
3. Tạo issue mới nếu chưa có

---

**Made with ❤️ using Flutter & Firebase**

