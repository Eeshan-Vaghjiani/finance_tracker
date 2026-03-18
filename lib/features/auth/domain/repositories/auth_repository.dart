import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserEntity> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  });
  Future<UserEntity> signInWithGoogle();

  Future<void> signOut();

  UserEntity? get currentUser;
}
