import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// États d'authentification
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticating extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _firebaseAuth;

  AuthCubit(this._firebaseAuth) : super(AuthInitial());

  // Se connecter
  Future<void> signIn(String email, String password) async {
    try {
      emit(AuthAuthenticating());
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(userCredential.user);
      emit(AuthAuthenticated(userCredential.user!));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // S'inscrire
  Future<void> signUp(String email, String password) async {
    try {
      emit(AuthAuthenticating());
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(userCredential.user!)); // État d'authentification réussie
    } catch (e) {
      emit(AuthError(e.toString())); // Gestion des erreurs
    }
  }

  // Se déconnecter
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    emit(AuthUnauthenticated());
  }

  // Vérifier le statut de l'authentification
  Future<void> checkAuthStatus() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
