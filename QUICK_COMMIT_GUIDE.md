# 🚀 HƯỚNG DẪN COMMIT & PUSH LÊN GITHUB

## ⚡ NHANH CHÓNG - BẠN ĐÃ CÓ REPO

Vì bạn đã có repository GitHub, chỉ cần làm theo các bước sau:

---

## 📋 BƯỚC 1: KIỂM TRA AN TOÀN

Mở **Command Prompt** hoặc **Terminal** trong VS Code và chạy:

```bash
cd D:\DoAnChuyenNganh\FastNewsProject

# Kiểm tra google-services.json có được bảo vệ không
git check-ignore android/app/google-services.json
```

**Kết quả mong đợi:**
```
android/app/google-services.json
```

✅ Nếu hiển thị đường dẫn → **AN TOÀN**, tiếp tục bước 2  
❌ Nếu KHÔNG hiển thị gì → **NGUY HIỂM**, DỪNG LẠI và báo tôi!

---

## 📋 BƯỚC 2: THÊM FILE VÀO GIT

```bash
# Thêm tất cả file (trừ những file trong .gitignore)
git add .
```

---

## 📋 BƯỚC 3: KIỂM TRA LẦN CUỐI

```bash
# Xem danh sách file sẽ được commit
git status
```

**QUAN TRỌNG - Kiểm tra output:**

✅ **KHÔNG THẤY** các file này:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`
- `android/local.properties`

❌ **NẾU THẤY** bất kỳ file nào ở trên → **DỪNG LẠI NGAY!**

---

## 📋 BƯỚC 4: COMMIT

```bash
git commit -m "Update FastNews app with Firebase integration"
```

Hoặc message chi tiết hơn:

```bash
git commit -m "Add Firebase Auth, Firestore, Google Sign In and bookmark features"
```

---

## 📋 BƯỚC 5: PUSH LÊN GITHUB

### **Nếu đã có remote origin:**

```bash
git push
```

Hoặc:

```bash
git push origin main
```

### **Nếu chưa có remote origin (lần đầu):**

```bash
# Thay YOUR_USERNAME và YOUR_REPO bằng thông tin repo của bạn
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

---

## 🎯 TÓM TẮT LỆNH - COPY & PASTE

```bash
# Bước 1: Kiểm tra
cd D:\DoAnChuyenNganh\FastNewsProject
git check-ignore android/app/google-services.json

# Bước 2: Add files
git add .

# Bước 3: Kiểm tra
git status

# Bước 4: Commit
git commit -m "Update FastNews app with Firebase integration"

# Bước 5: Push
git push
```

---

## ⚠️ NẾU GẶP LỖI

### **Lỗi: "Your branch is behind"**

```bash
# Pull về trước, sau đó push
git pull
git push
```

### **Lỗi: "rejected - non-fast-forward"**

```bash
# Pull với rebase
git pull --rebase
git push
```

### **Lỗi: "Permission denied"**

**Giải pháp 1:** Dùng GitHub Personal Access Token

1. Vào GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Chọn scopes: `repo`
4. Copy token
5. Khi push, dùng token làm password:
   ```
   Username: your-username
   Password: ghp_xxxxxxxxxxxxx (token vừa copy)
   ```

**Giải pháp 2:** Dùng GitHub Desktop (đơn giản hơn)

1. Download GitHub Desktop
2. Sign in
3. Add repository → chọn folder project
4. Commit & Push qua GUI

---

## ✅ SAU KHI PUSH THÀNH CÔNG

1. Vào repository trên GitHub
2. Kiểm tra file `android/app/google-services.json` **KHÔNG NÊN** có trong repo
3. Nếu thấy file này → XÓA REPOSITORY NGAY và báo tôi!

---

## 🔐 CUỐI CÙNG

Sau khi push xong:

1. ✅ Vào GitHub repo → File explorer
2. ✅ Kiểm tra **KHÔNG có** `google-services.json`
3. ✅ Kiểm tra **CÓ** các file: `lib/`, `android/build.gradle.kts`, `pubspec.yaml`, `README.md`
4. ✅ Set repo là **Private** (Settings → Danger Zone → Change visibility)

---

**BÂY GIỜ HÃY MỞ TERMINAL VÀ CHẠY CÁC LỆNH TRÊN!** 🚀

Nếu có vấn đề gì, dừng lại và hỏi tôi!

