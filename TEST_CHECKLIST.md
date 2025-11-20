# ✅ Checklist Kiểm tra - Lọc Bài báo theo Topics

## 🎯 Mục tiêu
Sau khi đăng ký và chọn topics, Home screen CHỈ hiển thị bài báo từ topics đã chọn.

---

## 📋 Test Steps

### ✅ Step 1: Đăng ký User Mới
- [ ] Mở app
- [ ] Đăng ký tài khoản mới (hoặc login)
- [ ] Màn hình Topics Selection xuất hiện

### ✅ Step 2: Chọn Topics
- [ ] Chọn 2-3 topics (ví dụ: **Công nghệ**, **Thể thao**)
- [ ] Thấy counter: "2 selected"
- [ ] Nhấn "Continue"

### ✅ Step 3: Kiểm tra Home Screen
**Expected:**
- [ ] Chỉ thấy tabs: "Tất cả", "Công nghệ", "Thể thao"
- [ ] KHÔNG thấy: "Chính trị", "Kinh doanh", "Sức khỏe", "Đời sống"
- [ ] Tab "Tất cả": Hiển thị bài từ Công nghệ + Thể thao
- [ ] Tab "Công nghệ": Chỉ bài Công nghệ
- [ ] Tab "Thể thao": Chỉ bài Thể thao

### ✅ Step 4: Kiểm tra Console Logs
Mở console/logcat, tìm các logs:
```
✅ Loaded user favorite topics: [Công nghệ, Thể thao]
📰 Loading news for favorite topics...
💖 User has favorite topics: [Công nghệ, Thể thao]
📰 Loading news from ALL favorite topics
  - Fetching news for: Công nghệ
  - Got XX articles for Công nghệ
  - Fetching news for: Thể thao
  - Got XX articles for Thể thao
✅ Total articles from favorite topics: XX
```

### ✅ Step 5: Kiểm tra Firestore
- [ ] Mở Firebase Console
- [ ] Vào Firestore → Collection `users`
- [ ] Tìm document của user vừa đăng ký
- [ ] Verify có fields:
  ```json
  {
    "selectedTopics": ["Công nghệ", "Thể thao"],
    "favoriteTopics": ["Công nghệ", "Thể thao"]
  }
  ```

### ✅ Step 6: Pull to Refresh
- [ ] Kéo màn hình xuống
- [ ] Thấy loading indicator
- [ ] Bài báo được refresh
- [ ] Vẫn chỉ hiển thị bài từ topics yêu thích

### ✅ Step 7: Chuyển đổi Tabs
- [ ] Nhấn vào tab "Công nghệ"
- [ ] Chỉ thấy bài về Công nghệ
- [ ] Nhấn vào tab "Thể thao"
- [ ] Chỉ thấy bài về Thể thao
- [ ] Nhấn vào tab "Tất cả"
- [ ] Thấy bài từ cả 2 topics

### ✅ Step 8: Phần "Chủ đề Yêu thích"
- [ ] Cuộn xuống thấy phần "❤️ Chủ đề Yêu thích"
- [ ] Thấy chips: 💻 Công nghệ, ⚽ Thể thao
- [ ] Thấy 10 bài báo từ các topics yêu thích
- [ ] Nhấn nút refresh → bài báo thay đổi

---

## 🐛 Common Issues & Solutions

### ❌ Issue 1: Vẫn thấy tất cả bài báo
**Check:**
- Console logs có hiển thị favorite topics?
- Firestore có lưu selectedTopics không?

**Fix:**
- Logout và login lại
- Clear app data và test lại

### ❌ Issue 2: Console logs không xuất hiện
**Check:**
- Có chạy trong debug mode không?
- Console/logcat có mở không?

**Fix:**
- Run với `flutter run -v`
- Mở Android Studio → Logcat

### ❌ Issue 3: Topics không lưu vào Firestore
**Check:**
- Firestore rules có cho phép write?
- User đã login chưa?

**Fix:**
- Check Firestore rules
- Verify authentication

### ❌ Issue 4: Build error
**Check:**
- Null safety issues?
- Missing imports?

**Fix:**
- Run `flutter pub get`
- Run `flutter clean`
- Build lại

---

## 📊 Expected Results Summary

| Scenario | Expected Behavior | ✅/❌ |
|----------|-------------------|-------|
| User chọn 2 topics | Chỉ 2 tabs hiển thị (+ "Tất cả") | [ ] |
| Tab "Tất cả" | Bài từ cả 2 topics | [ ] |
| Tab riêng lẻ | Chỉ bài của topic đó | [ ] |
| Không chọn topics | Hiển thị tất cả | [ ] |
| Pull to refresh | Vẫn lọc đúng | [ ] |
| Console logs | Hiển thị đầy đủ | [ ] |
| Firestore | Lưu đúng data | [ ] |

---

## 🎉 Success Criteria

**✅ PASS nếu:**
1. User chọn topics → CHỈ thấy bài từ topics đó
2. Không thấy bài từ topics khác
3. Tabs chỉ hiển thị topics đã chọn
4. Console logs hiển thị đúng
5. Firestore lưu đúng data
6. Pull-to-refresh hoạt động
7. Không có crash hoặc lỗi

**❌ FAIL nếu:**
- Vẫn thấy bài từ tất cả topics
- Tabs hiển thị không đúng
- App crash
- Data không lưu vào Firestore

---

## 📝 Notes

- Test với nhiều user khác nhau
- Test với nhiều tổ hợp topics khác nhau
- Test cả trường hợp không chọn topics
- Test logout/login lại

**Date:** November 21, 2025  
**Tester:** _____________  
**Result:** ⭕ PENDING / ✅ PASS / ❌ FAIL  

