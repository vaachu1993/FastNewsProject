# 🔥 Firebase Database Structure - FastNews App

## 📊 Collection: `users`

Mỗi user sẽ có một document với `userId` (Firebase Auth UID) làm document ID.

### 📝 User Document Structure:

```json
{
  "displayName": "Nguyen Van A",           // Tên hiển thị của user
  "email": "user@example.com",             // Email đăng nhập
  "photoURL": "https://...",               // URL ảnh đại diện (Google photo hoặc upload)
  "loginMethod": "google",                 // Phương thức đăng nhập: "email" | "google" | "facebook"
  "createdAt": Timestamp,                  // Thời gian tạo tài khoản
  "updatedAt": Timestamp,                  // Thời gian cập nhật gần nhất
  "lastLoginAt": Timestamp,                // Thời gian đăng nhập gần nhất
  "selectedTopics": [                      // Danh sách topics user quan tâm (chọn sau khi đăng ký)
    "technology",
    "business",
    "sports",
    "entertainment"
  ],
  "bookmarks": []                          // Danh sách ID bài viết đã bookmark
}
```

## 🎯 Available Topics (selectedTopics)

User có thể chọn từ các topics sau:

1. **technology** - 💻 Technology
2. **business** - 💼 Business
3. **sports** - ⚽ Sports
4. **entertainment** - 🎬 Entertainment
5. **health** - 🏥 Health
6. **science** - 🔬 Science
7. **world** - 🌍 World
8. **politics** - 🏛️ Politics
9. **food** - 🍔 Food
10. **travel** - ✈️ Travel
11. **fashion** - 👗 Fashion
12. **education** - 📚 Education

## 🔄 User Flow & Database Updates

### 1️⃣ **Đăng ký mới (Sign Up with Email)**
```
User đăng ký → AuthService.signUpWithEmail() 
→ Tạo document trong Firestore với:
  - displayName, email, loginMethod: "email"
  - createdAt, updatedAt, bookmarks: []
  - selectedTopics: chưa có (sẽ thêm ở màn hình tiếp theo)
```

### 2️⃣ **Đăng nhập Google lần đầu**
```
User đăng nhập Google → AuthService.signInWithGoogle()
→ Check if new user → Tạo document trong Firestore với:
  - displayName, email, photoURL, loginMethod: "google"
  - createdAt, updatedAt, bookmarks: []
  - selectedTopics: chưa có
```

### 3️⃣ **Chọn Topics (sau đăng ký/đăng nhập lần đầu)**
```
User chọn topics → TopicsSelectionScreen._saveTopicsAndContinue()
→ Update document với:
  - selectedTopics: ["technology", "business", ...]
  - updatedAt: Timestamp
  - Thêm displayName, email, photoURL nếu chưa có
```

### 4️⃣ **Đăng nhập lại (User đã tồn tại)**
```
User đăng nhập lại → LoginScreen._checkAndNavigate()
→ Check selectedTopics trong Firestore:
  - Nếu có selectedTopics → MainScreen
  - Nếu chưa có → TopicsSelectionScreen
→ Update lastLoginAt, updatedAt
```

## 🔐 Firebase Security Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // User chỉ có thể đọc và chỉnh sửa document của chính mình
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow read for authenticated users (để hiển thị thông tin user khác)
      allow read: if request.auth != null;
    }
  }
}
```

## 📱 Example Usage in Code

### Lấy user topics để personalize feed:
```dart
final userId = FirebaseAuth.instance.currentUser?.uid;
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

List<String> topics = [];
if (userDoc.exists) {
  topics = List<String>.from(userDoc.data()?['selectedTopics'] ?? []);
}
// Sử dụng topics để filter news
```

### Update bookmarks:
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
  'bookmarks': FieldValue.arrayUnion([articleId]),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### Remove bookmark:
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
  'bookmarks': FieldValue.arrayRemove([articleId]),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

## 🎨 Firestore Console Example

```
📁 users (collection)
  ├── 📄 abc123xyz... (document - userId)
  │   ├── displayName: "John Doe"
  │   ├── email: "john@gmail.com"
  │   ├── photoURL: "https://..."
  │   ├── loginMethod: "google"
  │   ├── selectedTopics: ["technology", "sports", "business"]
  │   ├── bookmarks: []
  │   ├── createdAt: December 10, 2024 at 10:30:00 AM
  │   └── updatedAt: December 10, 2024 at 10:35:00 AM
  │
  └── 📄 def456uvw... (document - userId)
      ├── displayName: "Jane Smith"
      ├── email: "jane@example.com"
      ├── loginMethod: "email"
      └── ...
```

## 🚀 Next Steps

Có thể mở rộng thêm:
- **Reading History**: Lưu lịch sử đọc bài viết
- **Preferences**: Lưu cài đặt app (theme, font size, language)
- **Notifications**: Lưu FCM token để push notifications
- **Social**: Lưu thông tin social (followers, following, etc.)

