import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/auth_config.dart';

class AuthService {
  AuthService._internal() {
    if (!kIsWeb) {
      try {
        GoogleSignIn.instance.initialize(
          serverClientId: AuthConfig.serverClientId.isNotEmpty
              ? AuthConfig.serverClientId
              : null,
        );
      } catch (e) {
        debugPrint('GoogleSignIn initialize warning: $e');
      }
    }
  }
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// تدفق حالة تسجيل الدخول للمستخدم
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// المستخدم الحالي إن وجد
  User? get currentUser => _auth.currentUser;

  /// معرف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// تسجيل الدخول باستخدام حساب Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      debugPrint('Error during Google signOut: $e');
    }
    await _auth.signOut();
  }

  /// ترجمة الأخطاء إلى رسائل عربية واضحة
  static String getErrorMessage(dynamic error) {
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.description?.contains('serverClientId') == true) {
        return 'يرجى ربط بصمة SHA-1 في Firebase أو ضبط serverClientId في auth_config.dart.';
      }
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'تم إلغاء عملية تسجيل الدخول.';
      }
      return error.description ?? 'حدث خطأ أثناء تسجيل الدخول بـ Google.';
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'لم يتم العثور على حساب بهذا البريد الإلكتروني.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'كلمة المرور أو البريد الإلكتروني غير صحيح.';
        case 'invalid-email':
          return 'صيغة البريد الإلكتروني غير صحيحة.';
        case 'user-disabled':
          return 'تم تعطيل هذا الحساب من قبل الإدارة.';
        case 'too-many-requests':
          return 'تمت محاولة تسجيل الدخول عدة مرات بشكل خاطئ. يرجى المحاولة لاحقاً.';
        case 'network-request-failed':
          return 'تعذر الاتصال بالإنترنت، يرجى التحقق من الشبكة.';
        case 'account-exists-with-different-credential':
          return 'يوجد حساب مسجل بالفعل ببيانات اعتماد مختلفة لهذا البريد.';
        default:
          return error.message ?? 'حدث خطأ أثناء المصادقة، يرجى المحاولة لاحقاً.';
      }
    }
    return 'حدث خطأ غير متوقع: ${error.toString()}';
  }
}
