# 🔥 Firebase Console Setup Guide - FastNews App

## ✅ Checklist: Những gì cần cấu hình trên Firebase Console

### 1️⃣ **Firestore Database** (QUAN TRỌNG NHẤT)

#### 📍 Tạo Firestore Database:
1. Vào Firebase Console: https://console.firebase.google.com/
2. Chọn project: **fastnews-app-f18fe**
3. Vào **Build** → **Firestore Database**
4. Click **"Create database"**
5. Chọn location: **asia-southeast1** (Singapore - gần Việt Nam nhất)
6. Chọn mode:
   - **Test mode** (cho development - cho phép read/write tự do trong 30 ngày)
   - Hoặc **Production mode** (cần setup Security Rules ngay)

#### 🔐 Setup Security Rules (Bắt buộc nếu chọn Production mode):

Vào **Firestore Database** → **Rules** → Paste code sau:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Rules cho collection 'users'
    match /users/{userId} {
      // Cho phép user đọc và ghi document của chính mình
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Cho phép tất cả user đã đăng nhập đọc thông tin user khác
      // (để hiển thị tên, avatar trong comments/social features)
      allow read: if request.auth != null;
      
      // Validate dữ liệu khi write
      allow create: if request.auth != null 
                    && request.auth.uid == userId
                    && request.resource.data.keys().hasAll(['email', 'displayName'])
                    && request.resource.data.email is string
                    && request.resource.data.displayName is string;
      
      allow update: if request.auth != null 
                    && request.auth.uid == userId;
    }
    
    // Rules mặc định: không cho phép truy cập các collection khác
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Click **"Publish"** để lưu rules.

#### 📊 Tạo Index (Tùy chọn - nếu cần query phức tạp):
- Firestore sẽ tự động yêu cầu tạo index khi bạn chạy query phức tạp
- Khi app báo lỗi index, copy link trong error message và paste vào browser để tạo index tự động

---

### 2️⃣ **Authentication** (ĐÃ SETUP)

✅ Bạn đã có `google-services.json` → Authentication đã được cấu hình

#### Kiểm tra lại:
1. Vào **Build** → **Authentication**
2. Vào tab **Sign-in method**
3. Đảm bảo đã enable:
   - ✅ **Email/Password** (nếu dùng email login)
   - ✅ **Google** (đã enable - thấy trong google-services.json)

#### Cấu hình Google Sign-In (nếu chưa):
1. Enable **Google** provider
2. Điền **Project support email**: email của bạn
3. Click **Save**

---

### 3️⃣ **Storage** (Tùy chọn - nếu cần upload ảnh user)

Nếu bạn muốn user upload avatar:

1. Vào **Build** → **Storage**
2. Click **"Get started"**
3. Chọn location: **asia-southeast1**
4. Setup Security Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Cho phép user upload avatar của chính mình
    match /avatars/{userId}/{allPaths=**} {
      allow read: if true; // Public read
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Default: deny all
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

### 4️⃣ **App Check** (Tùy chọn - Bảo mật nâng cao)

App Check giúp bảo vệ backend khỏi abuse:

1. Vào **Build** → **App Check**
2. Click **"Get started"**
3. Chọn provider:
   - **Play Integrity** (cho Android production)
   - **Debug provider** (cho development)
4. Register app và follow hướng dẫn

---

### 5️⃣ **Project Settings** (Kiểm tra)

1. Vào **Project settings** (icon ⚙️)
2. Tab **General**:
   - ✅ Kiểm tra **Project ID**: `fastnews-app-f18fe`
   - ✅ Kiểm tra **Web API Key**: `AIzaSyB0-vgsZ63dtnNt-xj48hRcbjZl4OZr-NY`
   - ✅ Có app Android đã register

3. Tab **Cloud Messaging** (nếu muốn push notifications):
   - Enable **Firebase Cloud Messaging API (V1)**
   - Lưu **Server key** để send notifications

---

## 🚀 Quick Start - Setup trong 5 phút:

### ⚡ Setup tối thiểu để app chạy:

1. **Tạo Firestore Database** (Test mode)
   ```
   Firebase Console → Firestore Database → Create Database
   → Chọn Test mode → Location: asia-southeast1 → Enable
   ```

2. **Enable Authentication methods**
   ```
   Firebase Console → Authentication → Sign-in method
   → Enable Email/Password
   → Enable Google
   ```

3. **Done!** 🎉 App có thể chạy ngay

---

## 📋 Test Checklist:

Sau khi setup xong, test các chức năng:

- [ ] ✅ Đăng ký với Email/Password
- [ ] ✅ Đăng nhập với Email/Password
- [ ] ✅ Đăng nhập với Google
- [ ] ✅ Chọn Topics → Lưu vào Firestore
- [ ] ✅ Kiểm tra Firestore Console → Collection `users` → Document được tạo
- [ ] ✅ Đăng nhập lại → Skip Topics Selection (vì đã có topics)
- [ ] ✅ Bookmark article → Lưu vào Firestore

---

## 🔍 Monitoring & Analytics:

### Setup Google Analytics (Tùy chọn):
1. Vào **Project settings** → **Integrations**
2. Click **Google Analytics** → Link account
3. Theo dõi user behavior, crashes, performance

### Setup Crashlytics (Khuyên dùng):
```dart
// Add to pubspec.yaml:
dependencies:
  firebase_crashlytics: ^4.1.3

// Setup in main.dart:
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
```

---

## 🎯 Production Checklist (Trước khi release):

Trước khi publish app lên Google Play:

- [ ] Chuyển Firestore từ **Test mode** sang **Production mode** với Security Rules
- [ ] Setup **App Check** với Play Integrity
- [ ] Enable **Firebase Analytics**
- [ ] Setup **Crashlytics** để track errors
- [ ] Review **Security Rules** kỹ lưỡng
- [ ] Setup **Backup** cho Firestore
- [ ] Giới hạn **API quotas** để tránh abuse
- [ ] Add **Terms of Service** và **Privacy Policy**

---

## 🆘 Troubleshooting:

### Lỗi: "Cloud Firestore is not enabled"
→ Vào Firestore Database → Create Database

### Lỗi: "Missing or insufficient permissions"
→ Check Security Rules → Đảm bảo user có quyền read/write

### Lỗi: "The query requires an index"
→ Click vào link trong error message để tạo index tự động

### Google Sign-In không hoạt động:
→ Check SHA-1 certificate trong Firebase Console → Project settings → Add SHA-1

---

## 📞 Support:

- Firebase Documentation: https://firebase.google.com/docs
- FlutterFire Documentation: https://firebase.flutter.dev/
- Stack Overflow: Tag `firebase` + `flutter`

---

## 🔗 Useful Links:

- **Firebase Console**: https://console.firebase.google.com/project/fastnews-app-f18fe
- **Firestore Data Viewer**: https://console.firebase.google.com/project/fastnews-app-f18fe/firestore
- **Authentication Users**: https://console.firebase.google.com/project/fastnews-app-f18fe/authentication/users
- **Project Settings**: https://console.firebase.google.com/project/fastnews-app-f18fe/settings/general

