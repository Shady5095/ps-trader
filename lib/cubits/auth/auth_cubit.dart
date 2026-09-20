import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  StreamSubscription? _authSubscription;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService.instance,
        super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // سيتم انبعاث Authenticated تلقائياً عبر authStateChanges
    } catch (e) {
      emit(AuthFailure(AuthService.getErrorMessage(e)));
      // إذا كان المستخدم لا يزال غير مسجل دخول، نعيده لحالة Unauthenticated بعد إظهار الخطأ
      emit(const Unauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        // المستخدم ألغى النافذة
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(AuthService.getErrorMessage(e)));
      emit(const Unauthenticated());
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _authService.signOut();
    } catch (e) {
      emit(AuthFailure(AuthService.getErrorMessage(e)));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
