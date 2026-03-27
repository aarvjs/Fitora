import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central service for all trainer-follow operations.
/// Scoped to the `follows` top-level Firestore collection.
///
/// Schema of follows/{docId}:
///   followerId : String  — Firebase Auth UID of whoever is following
///   trainerId  : String  — Trainer document ID being followed
///   createdAt  : Timestamp
class FollowService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  // ──────────────────────────────────────────
  // 1. Follow a trainer
  // ──────────────────────────────────────────
  Future<void> follow(String trainerId) async {
    final uid = _currentUid;
    if (uid == null || uid == trainerId) return;

    // Prevent duplicate – only create if not existing
    final existing = await _existingDoc(uid, trainerId);
    if (existing != null) return;

    await _db.collection('follows').add({
      'followerId': uid,
      'trainerId': trainerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ──────────────────────────────────────────
  // 2. Unfollow a trainer
  // ──────────────────────────────────────────
  Future<void> unfollow(String trainerId) async {
    final uid = _currentUid;
    if (uid == null) return;

    final existing = await _existingDoc(uid, trainerId);
    if (existing != null) {
      await _db.collection('follows').doc(existing).delete();
    }
  }

  // ──────────────────────────────────────────
  // 3. Real-time follow state stream
  // ──────────────────────────────────────────
  Stream<bool> isFollowingStream(String trainerId) {
    final uid = _currentUid;
    if (uid == null) return Stream.value(false);

    return _db
        .collection('follows')
        .where('followerId', isEqualTo: uid)
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }

  // ──────────────────────────────────────────
  // 4. Real-time follower count for a trainer
  // ──────────────────────────────────────────
  Stream<int> followerCountStream(String trainerId) {
    return _db
        .collection('follows')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ──────────────────────────────────────────
  // 5. Get list of trainer IDs the current user follows
  // ──────────────────────────────────────────
  Future<List<String>> getFollowedTrainerIds() async {
    final uid = _currentUid;
    if (uid == null) return [];

    final snap = await _db
        .collection('follows')
        .where('followerId', isEqualTo: uid)
        .get();

    return snap.docs
        .map((d) => d.data()['trainerId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  // ──────────────────────────────────────────
  // 6. Real-time stream of follower docs (for followers list screen)
  // Note: no orderBy here to avoid requiring a composite Firestore index.
  // Sorting is done client-side in the screen.
  // ──────────────────────────────────────────
  Stream<QuerySnapshot> getFollowersStream(String trainerId) {
    return _db
        .collection('follows')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots();
  }

  // ──────────────────────────────────────────
  // 7. Real-time stream of trainer IDs the current user follows
  // ──────────────────────────────────────────
  Stream<List<String>> getFollowedTrainerIdsStream() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('follows')
        .where('followerId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data()['trainerId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList());
  }

  // ──────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────
  Future<String?> _existingDoc(String followerId, String trainerId) async {
    final snap = await _db
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('trainerId', isEqualTo: trainerId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }
}
