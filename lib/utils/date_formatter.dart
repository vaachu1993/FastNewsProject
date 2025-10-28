/// Utility class để format ngày tháng
class DateFormatter {
  /// Format thời gian từ pubDate sang dd/MM/yyyy
  static String formatDateTime(String pubDate) {
    try {
      // Parse pubDate format: "Tue, 28 Oct 2025 14:36:55 +0700"
      DateTime dateTime = DateTime.parse(pubDate);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      // Nếu không parse được, thử cách khác
      try {
        final parts = pubDate.split(' ');
        if (parts.length >= 4) {
          final day = parts[1];
          final month = _getMonthNumber(parts[2]);
          final year = parts[3];
          return '$day/$month/$year';
        }
      } catch (e2) {
        // Nếu vẫn lỗi, trả về chuỗi gốc
        return pubDate;
      }
      return pubDate;
    }
  }

  /// Chuyển tên tháng tiếng Anh sang số
  static String _getMonthNumber(String month) {
    const months = {
      'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
      'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
      'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
    };
    return months[month] ?? '01';
  }
}

