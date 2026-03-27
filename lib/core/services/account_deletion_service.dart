import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitora/core/utils/cloudinary_upload.dart';

class AccountDeletionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Deletes a Member's data entirely from the platform.
  static Future<void> deleteMemberData(String uid) async {
    try {
      // 1. Fetch user doc to extract media URLs
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final profileImage = data['profileImage'] as String?;
        final backgroundImage = data['backgroundImage'] as String?;

        // 2. Delete media from Cloudinary
        if (profileImage != null && profileImage.isNotEmpty) {
          await CloudinaryService.deleteMedia(profileImage);
        }
        if (backgroundImage != null && backgroundImage.isNotEmpty) {
          await CloudinaryService.deleteMedia(backgroundImage);
        }
      }

      // 3. Delete user's comments
      final commentsSnap = await _db.collectionGroup('comments').where('authorId', isEqualTo: uid).get();
      final batch = _db.batch();
      for (var doc in commentsSnap.docs) {
        batch.delete(doc.reference);
      }

      // 4. Delete user's follows
      final followsSnap = await _db.collection('follows').where('followerId', isEqualTo: uid).get();
      for (var doc in followsSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // 5. Delete the user document
      await _db.collection('users').doc(uid).delete();

      // 6. Delete Firebase Auth User
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete member account: $e');
    }
  }

  /// Deletes an Owner's data, their Gym, AND cascades deletion to all Members registered under the gym.
  static Future<void> deleteOwnerAndGymData(String ownerUid, String gymId) async {
    try {
      // 1. Fetch and process all members registered under this Gym
      final membersSnap = await _db.collection('users').where('gymId', isEqualTo: gymId).where('role', isEqualTo: 'member').get();
      
      final batch = _db.batch();

      for (var memberDoc in membersSnap.docs) {
        final mData = memberDoc.data();
        final mProfile = mData['profileImage'] as String?;
        final mBg = mData['backgroundImage'] as String?;

        // Delete member media
        if (mProfile != null && mProfile.isNotEmpty) {
          await CloudinaryService.deleteMedia(mProfile);
        }
        if (mBg != null && mBg.isNotEmpty) {
          await CloudinaryService.deleteMedia(mBg);
        }

        // We batch delete the member document
        batch.delete(memberDoc.reference);

        // Best effort clean member follows & comments 
        // Note: Doing too many cross-collection queries per member can hit limits, 
        // but for a small gym it operates within Firestore batch limit (500).
      }

      // 2. Fetch Owner Data and delete their Cloudinary media
      final ownerDoc = await _db.collection('users').doc(ownerUid).get();
      if (ownerDoc.exists) {
        final data = ownerDoc.data()!;
        final oProfile = data['profileImage'] as String?;
        final oBg = data['backgroundImage'] as String?;

        if (oProfile != null && oProfile.isNotEmpty) {
          await CloudinaryService.deleteMedia(oProfile);
        }
        if (oBg != null && oBg.isNotEmpty) {
          await CloudinaryService.deleteMedia(oBg);
        }
      }

      // 3. Delete Owner's Gym Document
      if (gymId.isNotEmpty) {
        batch.delete(_db.collection('gyms').doc(gymId));
      }

      // 4. Delete Owner Document
      batch.delete(_db.collection('users').doc(ownerUid));

      // Commit the massive deletion batch
      await batch.commit();

      // 5. Finally, Delete Firebase Auth Owner User
      await _auth.currentUser?.delete();
      
    } catch (e) {
      throw Exception('Failed to delete owner account and cascading data: $e');
    }
  }
}
