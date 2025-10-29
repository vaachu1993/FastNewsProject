# 📰 FastNews - Ứng Dụng Tin Tức Flutter

Ứng dụng đọc tin tức nhanh chóng với tích hợp Firebase Authentication, Cloud Firestore và RSS Feed từ các báo lớn Việt Nam.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 Screenshots

<!-- Thêm screenshots của app ở đây -->

---

## ✨ Tính Năng Chính

### 🔐 Xác Thực Người Dùng
- Đăng ký/Đăng nhập bằng Email & Password
- Đăng nhập nhanh với Google Sign-In
- Quản lý thông tin cá nhân
- Đăng xuất an toàn

### 📰 Tin Tức
- RSS Feed realtime từ **VnExpress**, **Tuổi Trẻ**, **Thanh Niên**
- Phân loại theo danh mục: Thể thao, Công nghệ, Kinh doanh, Sức khỏe, Chính trị, Đời sống
- Pull-to-refresh để cập nhật tin mới
- Đọc nội dung đầy đủ bài viết

### ⭐ Bookmark
- Lưu bài viết yêu thích
- Đồng bộ realtime với Cloud Firestore
- Quản lý bookmark dễ dàng
- Xóa bookmark đơn giản

### 🎨 Giao Diện
- Material Design 3
- Responsive trên nhiều kích thước màn hình
- Smooth animations & transitions
- Loading states tối ưu
- Dark/Light theme (coming soon)

---

## 🚀 Bắt Đầu

### Yêu Cầu

- Flutter SDK: `>=3.9.2`
- Dart SDK: `>=3.9.2`
- Android Studio hoặc VS Code
- Tài khoản Firebase (miễn phí)

### Cài Đặt

1. **Clone repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/FastNewsProject.git
   cd FastNewsProject
   ```

2. **Cài đặt dependencies**
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase**
   
   > ⚠️ **Quan trọng**: File `google-services.json` không được commit lên Git vì lý do bảo mật.
   
   - Tạo Firebase project tại [Firebase Console](https://console.firebase.google.com)
   - Thêm Android app với package name: `com.example.fastnews`
   - Download `google-services.json` và đặt vào `android/app/`
   - Enable **Authentication** (Email/Password + Google)
   - Tạo **Firestore Database** với rules từ file `firestore.rules`

4. **Chạy ứng dụng**
   ```bash
   flutter run
   ```

---

## 📁 Cấu Trúc Dự Án

```
lib/
├── main.dart                      # Entry point, khởi tạo Firebase
├── models/
│   └── article_model.dart         # Model dữ liệu bài viết
├── screens/
│   ├── login_screen.dart          # Màn hình đăng nhập
│   ├── signup_screen.dart         # Màn hình đăng ký
│   ├── main_screen.dart           # Bottom navigation
│   ├── home_screen.dart           # Trang chủ - tin tức
│   ├── discover_screen.dart       # Khám phá
│   ├── bookmark_screen.dart       # Tin đã lưu
│   ├── profile_screen.dart        # Thông tin cá nhân
│   └── article_detail_screen.dart # Chi tiết bài viết
├── services/
│   ├── auth_service.dart          # Firebase Authentication
│   ├── firestore_service.dart     # Cloud Firestore
│   └── rss_service.dart           # Lấy RSS feeds
├── utils/
│   └── date_formatter.dart        # Format ngày tháng
└── widgets/
    └── article_card_horizontal.dart # Card hiển thị bài viết
```

---

## 🔧 Tech Stack

| Công Nghệ | Phiên Bản | Mục Đích |
|-----------|-----------|----------|
| Flutter | 3.9.2 | UI Framework |
| Firebase Auth | 5.3.1 | Xác thực người dùng |
| Cloud Firestore | 5.4.4 | Database NoSQL |
| Google Sign-In | 6.2.1 | Đăng nhập Google |
| HTTP | 1.2.0 | Networking |
| XML Parser | 6.3.0 | Parse RSS feeds |
| Crypto | 3.0.3 | Hash generation |

---

## 📊 Cấu Trúc Firestore

```
users/
  └── {userId}/
       ├── name: string
       ├── email: string
       ├── photoUrl: string (optional)
       ├── createdAt: timestamp
       ├── loginMethod: "email" | "google"
       └── bookmarks/
            └── {articleHash}/
                 ├── title: string
                 ├── link: string
                 ├── description: string
                 ├── imageUrl: string
                 ├── source: string
                 ├── pubDate: string
                 └── bookmarkedAt: timestamp
```

---

## 🔒 Bảo Mật

### File Được Bảo Vệ (Không Commit)

- `android/app/google-services.json` - Firebase config cho Android
- `ios/Runner/GoogleService-Info.plist` - Firebase config cho iOS
- `lib/firebase_options.dart` - Auto-generated Firebase options
- `.env` files - Environment variables

### Firestore Security Rules

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

---

## 📖 Hướng Dẫn Sử Dụng

### Đăng Ký Tài Khoản
1. Mở app → Nhấn "Sign up"
2. Nhập thông tin: Tên, Email, Mật khẩu
3. Nhấn "Sign up" → Tự động đăng nhập

### Đăng Nhập
- **Email/Password**: Nhấn "Sign in with password"
- **Google**: Nhấn "Continue with Google"

### Lưu Bookmark
1. Chọn bài viết → Nhấn icon Bookmark ở góc phải
2. Icon đổi màu xanh = Đã lưu
3. Xem trong tab "Saved"

### Đăng Xuất
1. Vào tab "Profile"
2. Nhấn icon Logout → Xác nhận

---

## 🐛 Troubleshooting

<details>
<summary><b>Lỗi: "google-services.json not found"</b></summary>

**Giải pháp:**
1. Download file từ Firebase Console
2. Đặt vào `android/app/google-services.json`
3. Chạy `flutter clean && flutter pub get`
</details>

<details>
<summary><b>Lỗi: "PlatformException(sign_in_failed)" khi đăng nhập Google</b></summary>

**Nguyên nhân:** Thiếu SHA-1 certificate

**Giải pháp:**
```bash
cd android
gradlew.bat signingReport
```
Copy SHA-1 → Thêm vào Firebase Console → Download lại `google-services.json`
</details>

<details>
<summary><b>Lỗi: "Permission denied" trong Firestore</b></summary>

**Nguyên nhân:** Firestore Rules chưa được cấu hình

**Giải pháp:** Copy rules từ phần "Bảo Mật" ở trên → Paste vào Firestore Rules → Publish
</details>

---

## 🚀 Roadmap

- [ ] Dark mode
- [ ] Đa ngôn ngữ (Tiếng Việt/English)
- [ ] Notification cho tin mới
- [ ] Tìm kiếm bài viết
- [ ] Chia sẻ bài viết
- [ ] Offline mode
- [ ] iOS support

---

## 🤝 Đóng Góp

Mọi đóng góp đều được chào đón! Vui lòng:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit thay đổi (`git commit -m 'Add AmazingFeature'`)
4. Push lên branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

---

## 📄 License

Dự án này được phát hành dưới giấy phép MIT. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

## 👨‍💻 Tác Giả

**[Tên của bạn]**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

---

## 🙏 Cảm Ơn

- [Firebase](https://firebase.google.com) - Backend services
- [VnExpress](https://vnexpress.net), [Tuổi Trẻ](https://tuoitre.vn), [Thanh Niên](https://thanhnien.vn) - RSS feeds
- [Flutter](https://flutter.dev) - Amazing UI framework
- [Flutter Community](https://flutter.dev/community) - Support & packages

---

## 📞 Liên Hệ & Hỗ Trợ

Nếu gặp vấn đề:
- 📧 Email: your.email@example.com
- 🐛 [Tạo Issue](https://github.com/yourusername/FastNewsProject/issues)
- 💬 [Discussions](https://github.com/yourusername/FastNewsProject/discussions)

---

<div align="center">

**⭐ Nếu thấy hữu ích, hãy cho dự án một ngôi sao! ⭐**

Made with ❤️ using Flutter & Firebase

</div>

