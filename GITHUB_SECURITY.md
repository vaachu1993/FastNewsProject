# 🔐 BẢO MẬT FIREBASE KHI PUSH LÊN GITHUB

## ⚠️ CẢNH BÁO QUAN TRỌNG

**CÁC FILE SAU CHỨA THÔNG TIN NHẠY CẢM - TUYỆT ĐỐI KHÔNG ĐƯỢC COMMIT:**

### 🚨 **File cực kỳ nguy hiểm:**

1. **`android/app/google-services.json`**
   - ❌ Chứa: API Key, Project ID, OAuth Client ID
   - ❌ Nếu bị lộ: Hacker có thể truy cập Firebase của bạn
   - ❌ Hậu quả: Đọc/ghi Firestore, truy cập Auth, tốn tiền

2. **`ios/Runner/GoogleService-Info.plist`**
   - ❌ Tương tự google-services.json cho iOS
   - ❌ Chứa API Key và thông tin nhạy cảm

3. **`lib/firebase_options.dart`** (nếu có)
   - ❌ Auto-generated file chứa config
   - ❌ Chứa toàn bộ Firebase keys

---

## ✅ ĐÃ BẢO VỆ

Tôi đã thêm các file sau vào `.gitignore`:

```gitignore
# Firebase Configuration - DO NOT COMMIT!
google-services.json
GoogleService-Info.plist
firebase_options.dart
.firebase/
firebase.json
.firebaserc

# API Keys and Secrets
*.env
.env
.env.local
.env.*.local
secrets.json
api_keys.dart

# Local configuration
android/local.properties
ios/Flutter/flutter_export_environment.sh
```

---

## 🔍 KIỂM TRA TRƯỚC KHI PUSH

### **Bước 1: Khởi tạo Git (nếu chưa có)**

```bash
cd D:\DoAnChuyenNganh\FastNewsProject
git init
```

### **Bước 2: Kiểm tra file nhạy cảm**

```bash
# Liệt kê tất cả file sẽ được commit
git add -n .
```

**Tìm kiếm trong output:**
- ❌ Nếu thấy `android/app/google-services.json` → NGUY HIỂM!
- ❌ Nếu thấy `ios/Runner/GoogleService-Info.plist` → NGUY HIỂM!
- ✅ Không thấy các file trên → An toàn

### **Bước 3: Xác nhận .gitignore hoạt động**

```bash
# Kiểm tra google-services.json có bị ignore không
git check-ignore android/app/google-services.json
```

**Kết quả mong đợi:**
```
android/app/google-services.json
```

✅ Nếu hiển thị đường dẫn → File đã được ignore  
❌ Nếu không hiển thị gì → File CHƯA được ignore → NGUY HIỂM!

---

## 🚀 CÁCH PUSH AN TOÀN LÊN GITHUB

### **Bước 1: Khởi tạo Git**

```bash
cd D:\DoAnChuyenNganh\FastNewsProject
git init
```

### **Bước 2: Thêm file vào staging**

```bash
git add .
```

### **Bước 3: Kiểm tra lần cuối**

```bash
git status
```

**Kiểm tra output:**
- ✅ Không thấy `google-services.json` → OK
- ✅ Không thấy `GoogleService-Info.plist` → OK
- ❌ Nếu thấy các file này → DỪNG LẠI!

### **Bước 4: Commit**

```bash
git commit -m "Initial commit - FastNews App"
```

### **Bước 5: Tạo repository trên GitHub**

1. Vào https://github.com
2. Click **"New repository"**
3. Tên: `FastNewsProject` hoặc `fast-news-app`
4. **Private** hoặc **Public** (khuyến nghị Private nếu có Firebase)
5. **KHÔNG** chọn "Initialize with README" (đã có rồi)
6. Click **"Create repository"**

### **Bước 6: Kết nối và push**

```bash
# Thay YOUR_USERNAME bằng username GitHub của bạn
git remote add origin https://github.com/YOUR_USERNAME/FastNewsProject.git
git branch -M main
git push -u origin main
```

---

## 🛡️ BẢO VỆ TĂNG CƯỜNG

### **Option 1: Tạo file mẫu (Template)**

Tạo file `android/app/google-services.json.example`:

```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "your-project-id",
    "storage_bucket": "your-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "YOUR_MOBILE_SDK_APP_ID",
        "android_client_info": {
          "package_name": "com.example.fastnews"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "YOUR_API_KEY_HERE"
        }
      ],
      "services": {}
    }
  ],
  "configuration_version": "1"
}
```

**Commit file này** - không chứa thông tin thật.

### **Option 2: Tạo README hướng dẫn setup**

Tạo file `SETUP.md`:

```markdown
# Setup Instructions

## Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or use existing project
3. Add Android app with package name: `com.example.fastnews`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`
6. Enable Authentication → Email/Password and Google Sign-In
7. Create Firestore Database
8. Copy Firestore Rules from project documentation
```

---

## ⚡ NẾU ĐÃ COMMIT NHẦm google-services.json

### **Cách 1: Xóa khỏi Git history (Nếu chưa push)**

```bash
# Remove file from git but keep local copy
git rm --cached android/app/google-services.json

# Commit the removal
git commit -m "Remove google-services.json from git"
```

### **Cách 2: Nếu đã push lên GitHub**

**⚠️ NGUY HIỂM - CẦN LÀM NGAY:**

1. **Xóa repository trên GitHub ngay lập tức**
2. **Tạo project Firebase mới** (vì API key đã bị lộ)
3. **Download google-services.json mới**
4. **Thêm vào .gitignore**
5. **Tạo repository mới**
6. **Push lại**

### **Cách 3: Rewrite Git history (Nâng cao)**

```bash
# CẢNH BÁO: Lệnh này xóa toàn bộ lịch sử của file
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch android/app/google-services.json" \
  --prune-empty --tag-name-filter cat -- --all

# Force push
git push origin --force --all
```

**Sau đó:**
- Rotate API Keys trên Firebase Console
- Tạo project mới (an toàn nhất)

---

## 📋 CHECKLIST TRƯỚC KHI PUSH

- [ ] File `.gitignore` đã được cập nhật
- [ ] Chạy `git check-ignore android/app/google-services.json` → có output
- [ ] Chạy `git status` → không thấy `google-services.json`
- [ ] Chạy `git add -n .` → không thấy `google-services.json`
- [ ] Repository GitHub set là **Private** (khuyến nghị)
- [ ] Đã tạo file `README.md` với hướng dẫn setup
- [ ] Đã tạo file `.example` cho các config nhạy cảm

---

## 🔐 FIREBASE SECURITY RULES

**Lưu ý:** Firestore Rules KHÔNG là bí mật, có thể commit lên Git.

Tạo file `firestore.rules`:

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

✅ File này AN TOÀN để commit lên Git.

---

## 📊 SO SÁNH: AN TOÀN vs NGUY HIỂM

### ✅ **AN TOÀN - Có thể commit:**

```
✅ lib/ (tất cả source code)
✅ android/build.gradle.kts
✅ android/app/build.gradle.kts
✅ pubspec.yaml
✅ README.md
✅ .gitignore
✅ firestore.rules
✅ assets/
✅ test/
✅ android/app/src/main/AndroidManifest.xml
```

### ❌ **NGUY HIỂM - TUYỆT ĐỐI KHÔNG commit:**

```
❌ android/app/google-services.json
❌ ios/Runner/GoogleService-Info.plist
❌ lib/firebase_options.dart
❌ .env (nếu có)
❌ android/local.properties
❌ ios/Flutter/flutter_export_environment.sh
❌ Bất kỳ file nào có chứa API key
```

---

## 🎯 BEST PRACTICES

### **1. Sử dụng Environment Variables**

Thay vì hard-code API keys, dùng `.env`:

```dart
// lib/config/api_keys.dart (KHÔNG commit)
class ApiKeys {
  static const String googleApiKey = 'YOUR_KEY_HERE';
  static const String firebaseApiKey = 'YOUR_KEY_HERE';
}
```

Thêm vào `.gitignore`:
```
lib/config/api_keys.dart
```

### **2. Sử dụng Firebase App Check**

Bảo vệ Firebase APIs khỏi abuse:
- Enable App Check trong Firebase Console
- Thêm reCAPTCHA hoặc SafetyNet

### **3. Restrict API Keys**

Trong Firebase Console → Project Settings → API Keys:
- Restrict Android key chỉ cho package `com.example.fastnews`
- Restrict Web key theo domain
- Enable only required APIs

### **4. Monitor Usage**

Firebase Console → Usage and billing:
- Set up budget alerts
- Monitor for unusual activity
- Review Authentication logs

---

## 🚨 DẤU HIỆU API KEY BỊ LỘ

Nếu bạn thấy:
- 📈 Spike đột ngột trong Firebase Usage
- 🔴 Firestore reads/writes tăng bất thường
- 👤 User lạ được tạo trong Authentication
- 💰 Firebase bill tăng cao

**→ API Key có thể đã bị lộ!**

**Hành động ngay:**
1. Xóa repository public
2. Rotate tất cả API keys
3. Tạo Firebase project mới
4. Review Firestore Rules
5. Enable App Check

---

## ✅ TÓM TẮT

### **Đã làm:**
- ✅ Cập nhật `.gitignore` để bảo vệ `google-services.json`
- ✅ Thêm rules cho các file nhạy cảm khác
- ✅ Hướng dẫn chi tiết cách push an toàn

### **Bạn cần làm:**
1. Chạy `git check-ignore android/app/google-services.json`
2. Xác nhận file được ignore
3. Tạo repository **Private** trên GitHub
4. Push code lên
5. Tạo README với hướng dẫn setup Firebase

---

## 📞 LIÊN HỆ H�� TRỢ

Nếu đã commit nhầm:
- GitHub Security: https://github.com/security
- Firebase Support: https://firebase.google.com/support

---

**LUÔN NHỚ: Tốt hơn là KHÔNG push, còn hơn push SAI!** 🔐

**Kiểm tra kỹ trước khi `git push`!** ✅

