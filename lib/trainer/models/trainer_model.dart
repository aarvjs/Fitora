import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerModel {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String profileImage;
  final String? coverImage;
  final String? bio;
  final String? experience;
  final String? address;
  final String? certifications;
  final List<String>? certificateImages;
  final Map<String, String>? socialLinks;
  final DateTime createdAt;

  TrainerModel({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.profileImage,
    this.coverImage,
    this.bio,
    this.experience,
    this.address,
    this.certifications,
    this.certificateImages,
    this.socialLinks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'bio': bio,
      'experience': experience,
      'address': address,
      'certifications': certifications,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TrainerModel.fromMap(Map<String, dynamic> map, String id) {
    return TrainerModel(
      id: id,
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      coverImage: map['coverImage'],
      bio: map['bio'],
      experience: map['experience'],
      address: map['address'],
      certifications: map['certifications'],
      certificateImages: (map['certificateImages'] as List?)?.map((e) => e.toString()).toList(),
      socialLinks: (map['socialLinks'] as Map?)?.cast<String, String>(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
