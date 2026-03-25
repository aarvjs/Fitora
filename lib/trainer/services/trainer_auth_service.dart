import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trainer_model.dart';

class TrainerAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convert username to a dummy email for Firebase Auth
  String _getEmailFromUsername(String username) {
    return '${username.toLowerCase().trim()}@trainer.app';
  }

  // Check if username is already taken
  Future<bool> isUsernameAvailable(String username) async {
    final querySnapshot = await _firestore
        .collection('trainers')
        .where('username', isEqualTo: username.toLowerCase().trim())
        .get();
    return querySnapshot.docs.isEmpty;
  }

  // Register a new Trainer
  Future<UserCredential?> registerTrainer({
    required String name,
    required String username,
    required String phone,
    required String password,
    required String profileImageUrl,
  }) async {
    final formattedUsername = username.toLowerCase().trim();
    
    // Validate username rules (lowercase, no spaces)
    if (formattedUsername.contains(' ')) {
      throw Exception('Username cannot contain spaces');
    }

    // Check username uniqueness
    bool isAvailable = await isUsernameAvailable(formattedUsername);
    if (!isAvailable) {
      throw Exception('Username already taken');
    }

    // Create Firebase Auth user
    try {
      final String email = _getEmailFromUsername(formattedUsername);
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save Trainer data to Firestore
      final TrainerModel newTrainer = TrainerModel(
        id: userCredential.user!.uid,
        name: name,
        username: formattedUsername,
        phone: phone,
        profileImage: profileImageUrl,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('trainers')
          .doc(userCredential.user!.uid)
          .set(newTrainer.toMap());

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('This username is already taken. Please choose another one.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Login Trainer
  Future<UserCredential?> loginTrainer({
    required String username,
    required String password,
  }) async {
    final formattedUsername = username.toLowerCase().trim();
    if (formattedUsername.isEmpty) {
      throw Exception('Username cannot be empty');
    }

    try {
      final String email = _getEmailFromUsername(formattedUsername);
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verify the user actually exists in the trainers collection
      final docSnap = await _firestore.collection('trainers').doc(userCredential.user!.uid).get();
      if (!docSnap.exists) {
         // They might be a standard user using a strange email format?
         await _auth.signOut();
         throw Exception('Trainer account not found');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        throw Exception('Trainer account not found (Invalid username)');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get Current Trainer Data
  Future<TrainerModel?> getCurrentTrainer() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('trainers').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return TrainerModel.fromMap(doc.data()!, doc.id);
      }
    }
    return null;
  }
}
