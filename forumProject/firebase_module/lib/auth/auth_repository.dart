import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_module/models/user_model.dart';

// ──────────────────────────────────────────────
// Abstract contract — depend on this, not the impl
// ──────────────────────────────────────────────

abstract class IAuthRepository {
  /// Stream of auth state changes (null when signed out).
  Stream<UserModel?> get authStateChanges;

  /// Returns the currently signed-in user, or null.
  UserModel? get currentUser;

  /// Signs in with [email] and [password].
  Future<UserModel> signInWithEmail(String email, String password);

  /// Creates a new account with [email], [password] and a [displayName].
  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String displayName,
  );

  /// Signs the current user out.
  Future<void> signOut();
}

// ──────────────────────────────────────────────
// Firebase implementation
// ──────────────────────────────────────────────

class AuthRepository implements IAuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().map(
        (user) => user == null ? null : UserModel.fromFirebaseUser(user),
      );

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return UserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user!.updateDisplayName(displayName.trim());
      // Reload so displayName is populated
      await credential.user!.reload();
      final updated = _auth.currentUser!;
      return UserModel.fromFirebaseUser(updated);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  // ── Helpers ──────────────────────────────────

  Exception _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No account found for that email address.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email.');
      case 'weak-password':
        return Exception('Password must be at least 6 characters.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}
