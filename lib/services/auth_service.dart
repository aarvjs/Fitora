import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simulate a phone based email for Firebase Email/Password auth
  String _getPhoneEmail(String phone) {
    // Basic sanitization
    final sanitizedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return '$sanitizedPhone@fitora.app';
  }

  // Generate a random 6 character alphanumeric Gym ID
  String _generateGymId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  // Generate a unique Gym ID (ensures no collision, though rare)
  Future<String> _getUniqueGymId() async {
    String gymId = _generateGymId();
    bool exists = true;
    while (exists) {
      final doc = await _firestore.collection('gyms').doc(gymId).get();
      if (!doc.exists) {
        exists = false;
      } else {
        gymId = _generateGymId();
      }
    }
    return gymId;
  }

  // === Owner Registration ===
  Future<String?> registerOwner({
    required String gymName,
    required String phone,
    required String password,
  }) async {
    try {
      final email = _getPhoneEmail(phone);
      
      // 1. Create Auth User
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String gymId = await _getUniqueGymId();
      final String uid = cred.user!.uid;

      // 2. Save Gym Document
      await _firestore.collection('gyms').doc(gymId).set({
        'gymId': gymId,
        'name': gymName,
        'ownerId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Save User Document
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'phone': phone,
        'role': 'owner',
        'gymId': gymId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return gymId; // Return gym ID to show to the owner
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('An account with this phone number already exists.');
      }
      if (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed') {
        throw Exception('Email/Password sign-in is not enabled in Firebase Console.\nGo to: Authentication → Sign-in method → Email/Password → Enable');
      }
      throw Exception(e.message ?? 'Registration failed (code: ${e.code})');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // === Member Registration ===
  Future<void> registerMember({
    required String name,
    required String phone,
    required String password,
    required String gymId,
  }) async {
    try {
      // 1. Verify Gym ID exists
      final gymDoc = await _firestore.collection('gyms').doc(gymId).get();
      if (!gymDoc.exists) {
        throw Exception('Invalid Gym ID. Please check and try again.');
      }

      final email = _getPhoneEmail(phone);

      // 2. Create Auth User
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = cred.user!.uid;

      // 3. Save User Document
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'phone': phone,
        'role': 'member',
        'gymId': gymId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('An account with this phone number already exists.');
      }
      if (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed') {
        throw Exception('Email/Password sign-in is not enabled in Firebase Console.\nGo to: Authentication → Sign-in method → Email/Password → Enable');
      }
      throw Exception(e.message ?? 'Registration failed (code: ${e.code})');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // === Login ===
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    try {
      final email = _getPhoneEmail(phone);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Invalid phone number or password.');
      }
      if (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed') {
        throw Exception('Email/Password sign-in is not enabled in Firebase Console.\nGo to: Authentication → Sign-in method → Email/Password → Enable');
      }
      throw Exception(e.message ?? 'Login failed (code: ${e.code})');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // === Forgot Password: Send OTP ===
  Future<void> sendPasswordResetOtp({
    required String phone,
    required Function(String verificationId) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
  }) async {
    // Format should include country code for Phone Auth
    // Assuming the UI handles "+countrycode" or it's added here
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        verificationFailed(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // === Forgot Password: Reset using OTP ===
  Future<void> verifyOtpAndResetPassword({
    required String verificationId,
    required String smsCode,
    required String newPassword,
    required String phone, // Original phone used to derive fake email
  }) async {
    try {
      // 1. Verify OTP
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // We sign in temporarily to verify the OTP and have the permission to update password
      // Since we use Email/Auth for the actual app login, the phone credential 
      // might link or create a new user. To avoid messing up the existing email user:
      // Actually, updating the password of the email user requires signing in as that email user.
      // Firebase doesn't allow changing an email user's password using a phone credential 
      // unless they are linked to the same account.
      
      // Let's link them if not linked, or just use the Admin SDK logic via Cloud Functions (unavailable here).
      // Workaround for pure client-side: 
      // - Sign in with Phone Auth (creates/logs into phone user)
      // - We cannot update the password of the `+phone@fitora.app` user while logged in as Phone user!
      // THIS IS A LIMITATION OF CLIENT-SIDE FIREBASE!
      
      // Better Workaround:
      // We don't change the Firebase Auth password. We just reset it using `sendPasswordResetEmail` if they had a real email.
      // BUT we used a fake email. 
      // So... we'll just have to login to the fake email user using a bypass? NO.
      // Instead, we can delete the old auth user and recreate it? No, UID would change, breaking Firestore relations.
      
      // To bypass this for a purely client-side prototype:
      // Wait, we can't easily do it securely client-side without Cloud Functions.
      // I will just throw an exception stating Cloud Functions is needed for this specific hybrid flow, or use a pseudo-auth approach.
      // Wait! If they verify their phone number, we can save their new password directly to Firestore as a "reset_request"? No.
      
      // Alternative simple approach since this is a Flutter prototype:
      // When the user verifies OTP, we sign in with Phone Auth.
      // But they need to login using Phone+Password next time.
      throw Exception("Password reset via OTP requires Firebase Cloud Functions to update the Email auth user. "
          "Since this is a client-side only app, please implement a Cloud Function or use native Phone Auth for all logins.");
          
    } catch (e) {
      throw Exception('Verification failed: $e');
    }
  }

  // Safe signOut
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
