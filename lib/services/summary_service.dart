import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firestore_service.dart';

class SummaryService {
  final FirestoreService _firestore = FirestoreService();

  /// Hàm chính: lấy tóm tắt (từ cache hoặc tạo mới bằng AI)
  Future<String?> getSummaryForArticle({
    required String? articleId,
    required String title,
    required String content,
  }) async {
    final key = articleId ?? _generateKeyFromTitle(title);

    // 1. Kiểm tra cache trong Firestore
    print('🔍 Đang kiểm tra cache cho article: $key');
    final cached = await _firestore.getArticleSummary(key);
    if (cached != null && cached.isNotEmpty) {
      print('✅ Lấy tóm tắt từ cache: ${cached.substring(0, cached.length > 50 ? 50 : cached.length)}...');
      return cached;
    }

    // 2. Gọi AI để tạo tóm tắt mới
    print('🤖 Không có cache - Đang tạo tóm tắt mới với AI...');
    final summary = await _callAiToSummarize(title: title, content: content);

    if (summary != null && summary.isNotEmpty) {
      // 3. Lưu vào cache
      await _firestore.saveArticleSummary(key, summary);
      print('💾 Đã lưu tóm tắt vào cache');
      return summary;
    } else {
      print('❌ Không thể tạo tóm tắt');
      return null;
    }
  }

  /// Tạo key từ title khi không có articleId
  String _generateKeyFromTitle(String title) {
    return title.hashCode.abs().toString();
  }

  /// Gọi API AI để tóm tắt (OpenAI GPT)
  Future<String?> _callAiToSummarize({
    required String title,
    required String content,
  }) async {
    try {
      // Cắt ngắn content nếu quá dài (giới hạn 3000 ký tự để tiết kiệm token)
      String truncatedContent = content;
      if (content.length > 3000) {
        // Lấy 3000 ký tự đầu tiên
        truncatedContent = content.substring(0, 3000);
        print('⚠️ Content quá dài (${content.length} chars) - Đã cắt xuống 3000 chars');
      }

      // ⚠️ QUAN TRỌNG: API key được lấy từ file .env
      // Thêm OPENAI_API_KEY vào file .env (đã có template)
      // Lấy key từ: https://platform.openai.com/api-keys
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

      if (apiKey.isEmpty || apiKey == 'YOUR_OPENAI_API_KEY_HERE') {
        print('❌ Chưa cấu hình API key! Vui lòng thêm OpenAI API key vào file .env');
        return 'Chức năng tóm tắt chưa được cấu hình. Vui lòng thêm OPENAI_API_KEY vào file .env';
      }

      const endpoint = 'https://api.openai.com/v1/chat/completions';

      final prompt = '''
Hãy tóm tắt bài báo sau đây thành 3-5 câu ngắn gọn, rõ ràng bằng tiếng Việt.
Chỉ sử dụng thông tin có trong bài báo, không thêm thông tin bên ngoài.
Tập trung vào những điểm chính quan trọng nhất để người đọc hiểu nhanh nội dung.

Tiêu đề:
$title

Nội dung:
$truncatedContent

Tóm tắt (3-5 câu, tiếng Việt, súc tích):
''';

      final body = {
        "model": "gpt-4o-mini", // Hoặc "gpt-3.5-turbo" để tiết kiệm chi phí hơn
        "messages": [
          {
            "role": "system",
            "content": "Bạn là trợ lý tóm tắt tin tức chuyên nghiệp. Hãy tạo tóm tắt ngắn gọn, rõ ràng, dễ hiểu."
          },
          {
            "role": "user",
            "content": prompt
          }
        ],
        "temperature": 0.3, // Giảm temperature để có kết quả ổn định hơn
        "max_tokens": 300
      };

      print('📡 Đang gọi OpenAI API...');
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final summary = map['choices'][0]['message']['content']?.toString().trim();
        print('✅ Đã nhận được tóm tắt từ AI: ${summary?.substring(0, summary.length > 50 ? 50 : summary.length)}...');
        return summary;
      } else {
        print('❌ Lỗi API OpenAI (${res.statusCode}): ${res.body}');

        // Parse error message
        try {
          final errorMap = jsonDecode(res.body);
          final errorMessage = errorMap['error']?['message'] ?? 'Unknown error';
          print('❌ Chi tiết lỗi: $errorMessage');
        } catch (e) {
          // Ignore JSON parse error
        }

        return null;
      }
    } catch (e) {
      print('❌ Exception khi gọi AI: $e');
      return null;
    }
  }
}

