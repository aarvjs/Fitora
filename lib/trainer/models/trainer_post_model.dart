import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerPostModel {
  final String id;
  final String trainerId;
  final String mediaUrl;
  final String type; // 'image' or 'video'
  final String description;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;

  TrainerPostModel({
    required this.id,
    required this.trainerId,
    required this.mediaUrl,
    required this.type,
    required this.description,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trainerId': trainerId,
      'mediaUrl': mediaUrl,
      'type': type,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
    };
  }

  factory TrainerPostModel.fromMap(Map<String, dynamic> map, String id) {
    return TrainerPostModel(
      id: id,
      trainerId: map['trainerId'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      type: map['type'] ?? 'image',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
    );
  }
}
