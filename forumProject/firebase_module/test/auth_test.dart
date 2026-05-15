import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_module/auth/auth_repository.dart';
import 'package:firebase_module/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_test.mocks.dart';

// Run: flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([FirebaseAuth, UserCredential, User])
void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late AuthRepository authRepository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    authRepository = AuthRepository(firebaseAuth: mockFirebaseAuth);

    // Shared user stubs
    when(mockUser.uid).thenReturn('test-uid-123');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.displayName).thenReturn('Test User');
    when(mockUserCredential.user).thenReturn(mockUser);
  });

  // ─────────────────────────────────────────────────
  group('AuthRepository — signInWithEmail', () {
    test('returns UserModel on successful sign-in', () async {
      when(
        mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => mockUserCredential);

      final result =
          await authRepository.signInWithEmail('test@example.com', 'pass123');

      expect(result, isA<UserModel>());
      expect(result.uid, 'test-uid-123');
      expect(result.email, 'test@example.com');
      expect(result.displayName, 'Test User');
    });

    test('throws mapped Exception on user-not-found', () async {
      when(
        mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(
        FirebaseAuthException(code: 'user-not-found'),
      );

      expect(
        () => authRepository.signInWithEmail('ghost@example.com', 'pass'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No account found'),
          ),
        ),
      );
    });

    test('throws mapped Exception on wrong-password', () async {
      when(
        mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(
        FirebaseAuthException(code: 'wrong-password'),
      );

      expect(
        () => authRepository.signInWithEmail('test@example.com', 'wrong'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Incorrect password'),
          ),
        ),
      );
    });
  });

  // ─────────────────────────────────────────────────
  group('AuthRepository — registerWithEmail', () {
    test('returns UserModel after successful registration', () async {
      when(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => mockUserCredential);
      when(mockUser.updateDisplayName(any)).thenAnswer((_) async {});
      when(mockUser.reload()).thenAnswer((_) async {});
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

      final result = await authRepository.registerWithEmail(
        'new@example.com',
        'password123',
        'New User',
      );

      expect(result, isA<UserModel>());
      expect(result.uid, 'test-uid-123');
    });

    test('throws Exception when email already in use', () async {
      when(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(
        FirebaseAuthException(code: 'email-already-in-use'),
      );

      expect(
        () => authRepository.registerWithEmail(
            'existing@example.com', 'pass123', 'User'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already exists'),
          ),
        ),
      );
    });
  });

  // ─────────────────────────────────────────────────
  group('AuthRepository — currentUser', () {
    test('returns UserModel when Firebase has a current user', () {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

      final result = authRepository.currentUser;
      expect(result, isNotNull);
      expect(result!.uid, 'test-uid-123');
    });

    test('returns null when no user is signed in', () {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      final result = authRepository.currentUser;
      expect(result, isNull);
    });
  });

  // ─────────────────────────────────────────────────
  group('AuthRepository — signOut', () {
    test('calls FirebaseAuth.signOut()', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await authRepository.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
    });
  });
}
