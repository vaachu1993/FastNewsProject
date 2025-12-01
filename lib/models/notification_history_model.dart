class NotificationHistoryModel {
  final String id;
  final String title;
  final String body;
  final String? articleId;
  final String? articleLink;
  final String? imageUrl;
  final String source;
  final DateTime timestamp;
  final bool isRead;

  NotificationHistoryModel({
    required this.id,
    required this.title,
    required this.body,
    this.articleId,
    this.articleLink,
    this.imageUrl,
    required this.source,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'articleId': articleId,
      'articleLink': articleLink,
      'imageUrl': imageUrl,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationHistoryModel.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      articleId: json['articleId'] as String?,
      articleLink: json['articleLink'] as String?,
      imageUrl: json['imageUrl'] as String?,
      source: json['source'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  NotificationHistoryModel copyWith({
    String? id,
    String? title,
    String? body,
    String? articleId,
    String? articleLink,
    String? imageUrl,
    String? source,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationHistoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      articleId: articleId ?? this.articleId,
      articleLink: articleLink ?? this.articleLink,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

