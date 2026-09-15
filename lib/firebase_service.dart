// lib/firebase_service.dart
//
// BUG FIX: this file used to contain a second, independent copy of
// `FirebaseService` with a corrupted first line -
//   import 'package:firebase_auth/firebase_auth me';
// - which is not a valid package URI. That's a syntax error, so every file
// that imported this one (lib/screens/chatbot_screen.dart and
// lib/services/chatbot_service.dart both do `import '../firebase_service.dart'`)
// failed to compile, breaking the whole app build.
//
// On top of the syntax error, having two separate `FirebaseService` classes
// (this one and lib/services/firebase_service.dart, which is the one
// AppController actually talks to for login/signup) meant the two copies
// could silently drift apart, as they already had: this copy had bug fixes
// (trimmed input, resilient Firestore writes, Arabic error messages) that
// the "real" one used by the auth screen did not.
//
// Fix: remove the duplicate class entirely and re-export the single,
// canonical implementation so every part of the app - chatbot included -
// shares the exact same FirebaseService singleton and auth logic.
export 'services/firebase_service.dart';
