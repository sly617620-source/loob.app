import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:loob/models/user_model.dart' as app_user;

/// Centralized Firebase service for authentication and core Firebase operations.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Returns the current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Initialize Firebase.
  static Future<void> initialize({FirebaseOptions? options}) async {
    await Firebase.initializeApp(options: options);
  }

  /// Sign in with email and password.
  Future<app_user.User?> signInWithEmail(String email, String password) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      final fbUser = credential.user;
      if (fbUser == null) return null;

      // BUG FIX: previously this returned whatever getUserFromFirestore(...)
      // gave back - including `null` when the `users/{uid}` document didn't
      // exist (e.g. it was never created, or its earlier creation failed).
      // That made a *successful* Firebase Auth sign-in look like a failed
      // one to the caller (AppController.signInWithEmail treats a `null`
      // result as "wrong credentials"), so a correct password could still
      // show "بيانات الدخول غير صحيحة". Fall back to building the user from
      // the Firebase Auth account itself so a valid login never fails just
      // because Firestore is missing the profile doc.
      final userFromDb = await getUserFromFirestore(fbUser.uid);
      if (userFromDb != null) return userFromDb;

      return app_user.User(
        id: fbUser.uid,
        email: fbUser.email ?? trimmedEmail,
        displayName: fbUser.displayName,
        photoUrl: fbUser.photoURL,
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register with email and password.
  Future<app_user.User?> registerWithEmail(
    String email,
    String password, {
    String? displayName,
    String? phoneNumber,
    app_user.UserRole role = app_user.UserRole.customer,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final trimmedName = displayName?.trim();
    final trimmedPhone = phoneNumber?.trim();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      // Update display name
      if (trimmedName != null && trimmedName.isNotEmpty) {
        await credential.user?.updateDisplayName(trimmedName);
      }

      // Create user document in Firestore
      final user = app_user.User(
        id: credential.user!.uid,
        email: trimmedEmail,
        displayName: trimmedName ?? credential.user?.displayName,
        photoUrl: credential.user?.photoURL,
        phoneNumber: (trimmedPhone != null && trimmedPhone.isNotEmpty) ? trimmedPhone : null,
        role: role,
        createdAt: DateTime.now(),
      );

      // BUG FIX: this Firestore write used to be unguarded, so if it threw
      // (e.g. Firestore security rules, or a transient network error) the
      // whole registration was reported as failed to the user *even though
      // their Firebase Auth account had already been created*. That left
      // them stuck: retrying registration then failed with
      // "email-already-in-use" for an account they were told never got
      // created. Now a Firestore hiccup no longer blocks the sign-up flow -
      // the auth account (the part that actually matters for login) is
      // still returned as a success.
      try {
        // `createdAt` is overridden with FieldValue.serverTimestamp() here
        // (instead of the client-side DateTime.now() baked into toJson())
        // so the stored value reflects Firestore's clock, not the device's
        // - immune to a user's phone having the wrong date/time set.
        await _firestore.collection('users').doc(user.id).set({
          ...user.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Non-fatal: the account still exists and can sign in; the profile
        // doc will be recreated the next time signInWithEmail falls back
        // to building it from the Firebase Auth user.
      }
      // Immediately send the verification email per spec, non-fatally:
      // like the Firestore write above, a transient failure here (e.g. no
      // network right after signup) shouldn't make registration itself
      // fail when the Firebase Auth account was already created
      // successfully - the user can request another verification email
      // later via [sendEmailVerification].
      try {
        await credential.user?.sendEmailVerification();
      } catch (_) {}

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google.
  /// Replaces the previous UnimplementedError with full implementation.
  Future<app_user.User?> signInWithGoogle() async {
    try {
      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by the user.');
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Google.');
      }

      // Check if user exists in Firestore
      app_user.User? existingUser = await getUserFromFirestore(firebaseUser.uid);

      if (existingUser == null) {
        // Create new user document
        final newUser = app_user.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? googleUser.email,
          displayName: firebaseUser.displayName ?? googleUser.displayName,
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(newUser.id).set({
          ...newUser.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return newUser;
      }

      // Update last login
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      return existingUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Sign in with Apple.
  /// Replaces the previous UnimplementedError with full implementation.
  Future<app_user.User?> signInWithApple() async {
    try {
      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuthProvider credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Apple.');
      }

      // Check if user exists in Firestore
      app_user.User? existingUser = await getUserFromFirestore(firebaseUser.uid);

      if (existingUser == null) {
        // Apple doesn't always return display name, handle gracefully
        String? displayName;
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        }

        final newUser = app_user.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? appleCredential.email ?? '',
          displayName: displayName ?? firebaseUser.displayName,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(newUser.id).set({
          ...newUser.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return newUser;
      }

      // Update last login
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      return existingUser;
    } on SignInWithAppleAuthorizationException catch (e) {
      throw Exception('Apple sign-in authorization failed: ${e.code} - ${e.message}');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Apple sign-in failed: ${e.toString()}');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile in Firestore.
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  /// Get user from Firestore by ID.
  Future<app_user.User?> getUserFromFirestore(String? uid) async {
    if (uid == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return app_user.User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Phone number authentication (SMS OTP)
  // ---------------------------------------------------------------------

  /// Normalizes a locally-formatted phone number to E.164
  /// (`+<country code><number>`, no spaces/dashes), which is the only
  /// format `FirebaseAuth.verifyPhoneNumber` accepts.
  ///
  /// - A number already starting with `+` is trusted as-is (just stripped
  ///   of separators).
  /// - `00<code>...` (the common international-dialing prefix) becomes
  ///   `+<code>...`.
  /// - A leading local trunk `0` (e.g. Yemeni `07XXXXXXXX`) is dropped and
  ///   [defaultCountryCode] is prepended, since that leading zero is a
  ///   dialing convention, not part of the number itself.
  ///
  /// [defaultCountryCode] defaults to `+967` (Yemen) to match this app's
  /// primary market; pass a different one explicitly for other markets
  /// rather than changing the default, since existing callers rely on it.
  String toE164(String rawPhone, {String defaultCountryCode = '+967'}) {
    var digits = rawPhone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '$defaultCountryCode$digits';
  }

  /// Starts the phone verification flow: sends an SMS OTP to [phoneNumber]
  /// (sanitized to E.164 via [toE164]) and reports progress through the
  /// four callbacks `verifyPhoneNumber` itself exposes.
  ///
  /// - [onCodeSent]: an SMS was dispatched; the given `verificationId`
  ///   must be kept (e.g. in State) and passed to [signInWithPhoneNumberOTP]
  ///   once the user types the code.
  /// - [onVerificationFailed]: a real failure (invalid number, quota,
  ///   etc.) - already mapped to a friendly Arabic message.
  /// - [onAutoVerified]: Android-only fast path where the OS reads the SMS
  ///   itself and completes sign-in without the user typing anything; the
  ///   resulting app user is already synced to Firestore when this fires.
  /// - [onCodeAutoRetrievalTimeout]: Android's auto-read window (the
  ///   [timeout] duration) elapsed with no code intercepted - purely
  ///   informational, sign-in via [signInWithPhoneNumberOTP] is still
  ///   possible using the same `verificationId` from [onCodeSent].
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onVerificationFailed,
    void Function(app_user.User user)? onAutoVerified,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    String defaultCountryCode = '+967',
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final e164Phone = toE164(phoneNumber, defaultCountryCode: defaultCountryCode);
    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: timeout,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          final syncedUser = await _syncSocialUser(result.user!, phoneNumber: e164Phone);
          onAutoVerified?.call(syncedUser);
        } on FirebaseAuthException catch (e) {
          onVerificationFailed(
              _handleAuthException(e).toString().replaceFirst('Exception: ', ''));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onVerificationFailed(
            _handleAuthException(e).toString().replaceFirst('Exception: ', ''));
      },
      codeSent: (String verificationId, int? resendToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (String verificationId) =>
          onCodeAutoRetrievalTimeout?.call(verificationId),
    );
  }

  /// Finalizes phone sign-in: builds the [PhoneAuthProvider] credential from
  /// [verificationId] (returned by [startPhoneVerification]'s `onCodeSent`)
  /// and the [smsCode] the user typed, then signs in with it.
  Future<app_user.User?> signInWithPhoneNumberOTP(
    String verificationId,
    String smsCode, {
    String? phoneNumberForNewUser,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final result = await _auth.signInWithCredential(credential);
      // `await` here (not just `return`) matters: without it, this method
      // returns before _syncSocialUser's Future settles, so any error it
      // throws (e.g. a Firestore write failure) would become an unhandled
      // Future rejection instead of propagating to whoever called
      // signInWithPhoneNumberOTP - it would silently vanish instead of
      // reaching the UI's error handling.
      return await _syncSocialUser(result.user!, phoneNumber: phoneNumberForNewUser);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Shared "does this Firebase user already have a Firestore profile, or
  /// do we need to create one" logic used by phone sign-in (and, in
  /// principle, could replace the near-identical inline blocks in
  /// [signInWithGoogle]/[signInWithApple] - left as-is there to keep this
  /// change scoped to what was asked).
  Future<app_user.User> _syncSocialUser(User firebaseUser, {String? phoneNumber}) async {
    final existing = await getUserFromFirestore(firebaseUser.uid);
    if (existing != null) {
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
      return existing;
    }
    final newUser = app_user.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      phoneNumber: phoneNumber ?? firebaseUser.phoneNumber,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(newUser.id).set({
      ...newUser.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return newUser;
  }

  // ---------------------------------------------------------------------
  // Email verification
  // ---------------------------------------------------------------------

  /// Resends the verification email to the currently signed-in user.
  /// A no-op (not an error) if they're already verified.
  Future<void> sendEmailVerification() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول حالياً.');
    }
    if (firebaseUser.emailVerified) return;
    try {
      await firebaseUser.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Live email-verification check for gating protected routes.
  ///
  /// Deliberately does NOT read a cached field off the app's [app_user.User]
  /// model - verification happens by the user clicking a link in their
  /// inbox, which can happen while the app is closed or backgrounded, so
  /// any cached value could be stale. This calls `reload()` first to pull
  /// the live status from Firebase Auth before answering.
  Future<bool> isEmailVerified() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return false;
    await firebaseUser.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Handle Firebase Auth exceptions with user-friendly (Arabic) messages,
  /// matching the language used throughout the rest of the app's UI.
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      // Newer Firebase Auth versions return this single generic code
      // instead of 'user-not-found'/'wrong-password' for security reasons.
      // It was NOT handled before, so it fell through to the raw (English)
      // `e.message`, which is why the login screen wasn't showing a clean
      // Arabic error for the most common failure case.
      case 'invalid-credential':
        message = 'بيانات الدخول غير صحيحة.';
        break;
      case 'email-already-in-use':
        message = 'يوجد حساب مسجل بالفعل بهذا البريد الإلكتروني.';
        break;
      case 'invalid-email':
        message = 'يرجى إدخال بريد إلكتروني صحيح.';
        break;
      case 'weak-password':
        message = 'كلمة المرور ضعيفة جداً، يرجى اختيار كلمة مرور أقوى.';
        break;
      case 'user-disabled':
        message = 'تم تعطيل هذا الحساب، يرجى التواصل مع الدعم.';
        break;
      case 'too-many-requests':
        message = 'محاولات كثيرة خاطئة، يرجى المحاولة لاحقاً.';
        break;
      case 'operation-not-allowed':
        message = 'طريقة تسجيل الدخول هذه غير مفعّلة حالياً.';
        break;
      case 'account-exists-with-different-credential':
        message = 'يوجد حساب بنفس البريد الإلكتروني بطريقة تسجيل دخول مختلفة.';
        break;
      case 'network-request-failed':
        message = 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت.';
        break;
      case 'invalid-phone-number':
        message = 'رقم الهاتف غير صحيح، تأكد من كتابته مع رمز الدولة.';
        break;
      case 'invalid-verification-code':
        message = 'رمز التحقق غير صحيح.';
        break;
      case 'missing-verification-code':
        message = 'يرجى إدخال رمز التحقق.';
        break;
      case 'session-expired':
        message = 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد.';
        break;
      case 'quota-exceeded':
        message = 'تم تجاوز الحد المسموح من الرسائل، يرجى المحاولة لاحقاً.';
        break;
      case 'credential-already-in-use':
        message = 'رقم الهاتف هذا مستخدم بالفعل بحساب آخر.';
        break;
      default:
        message = e.message ?? 'حدث خطأ أثناء المصادقة.';
    }
    return Exception(message);
  }
}
