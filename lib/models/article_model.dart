import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/html_utils.dart';

class ArticleModel {
  final String id; // Unique ID for tracking
  final String title;
  final String source;
  final String time;
  final String imageUrl;
  final String link;
  final String? description;

  ArticleModel({
    String? id,
    required String title,
    required this.source,
    required this.time,
    required this.imageUrl,
    required this.link,
    String? description,
  }) : id = id ?? _generateId(link),
       title = _decodeHtmlEntities(title),
       description = description != null ? _decodeHtmlEntities(description) : null;

  // Generate unique ID from link
  static String _generateId(String link) {
    var bytes = utf8.encode(link);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Decode HTML entities like &quot;, &#39;, &amp;, etc.
  static String _decodeHtmlEntities(String text) {
    try {
      // Use HtmlUtils for comprehensive HTML entity decoding
      return HtmlUtils.decodeHtmlEntities(text);
    } catch (e) {
      // If decoding fails, return original text
      return text;
    }
  }

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'source': source,
    'time': time,
    'imageUrl': imageUrl,
    'link': link,
    'description': description,
  };

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
    id: json['id'],
    title: json['title'],
    source: json['source'],
    time: json['time'],
    imageUrl: json['imageUrl'],
    link: json['link'],
    description: json['description'],
  );
}
