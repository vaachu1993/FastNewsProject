import 'package:crypto/crypto.dart';
import 'dart:convert';

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
    required this.title,
    required this.source,
    required this.time,
    required this.imageUrl,
    required this.link,
    this.description,
  }) : id = id ?? _generateId(link);

  // Generate unique ID from link
  static String _generateId(String link) {
    var bytes = utf8.encode(link);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
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
