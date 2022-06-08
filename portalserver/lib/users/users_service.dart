import 'package:portalserver/common/exceptions/already_exists_exception.dart';
import 'package:portalserver/common/exceptions/argument_exception.dart';
import 'package:portalserver/users/model/user.dart';
import 'package:email_validator/email_validator.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:sqlite_wrapper/sqlite_wrapper.dart';

class UsersService {
  static String usersTable = 'users';

  final SQLiteWrapper db;

  UsersService({required this.db});

  Future<User> createUser(
      {required String username,
      required String email,
      required String password}) async {
    await _validateUsernameOrThrow(username);

    await _validateEmailOrThrow(email);

    _validatePasswordOrThrow(password);

    final digest = sha256.convert(utf8.encode(password)).toString();
    print(digest);
    final result = await db.insert(<String, Object?>{
      'username': username,
      'email': email,
      'password_hash': digest
    }, usersTable);

    final userInserted =
        await db.query("SELECT * from $usersTable where id = $result limit 1");

    final userId = userInserted[0]['id'];
    final createdAt = userInserted[0]['createdAt'];
    final updatedAt = userInserted[0]['updatedAt'];

    return User(
        id: userId.toString(),
        username: username,
        email: email,
        createdAt: DateTime.parse(createdAt.toString()),
        updatedAt: DateTime.parse(updatedAt.toString()));
  }

  Future<User?> getUserById(String userId) async {
    final result = await db
        .query("SELECT * from $usersTable where id = '$userId' limit 1");

    if (result.isEmpty) {
      return null;
    }

    final userRow = result[0];

    final email = userRow['email'];
    final username = userRow['username'];
    final bio = userRow['bio'];
    final image = userRow['image'];
    final createdAt = userRow['createdAt'];
    final updatedAt = userRow['updatedAt'];

    return User(
        id: userId,
        username: username.toString(),
        email: email.toString(),
        bio: bio.toString(),
        image: image.toString(),
        createdAt: DateTime.parse(createdAt.toString()),
        updatedAt: DateTime.parse(updatedAt.toString()));
  }

  Future<User?> getUserByEmail(String email) async {
    final result = await db
        .query("SELECT * from $usersTable where email = '$email' limit 1");
    if (result.isEmpty) {
      return null;
    }

    final userId = result[0]['id'];

    return await getUserById(userId.toString());
  }

  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final digest = sha256.convert(utf8.encode(password)).toString();
    final result = await db.query(
        "SELECT * from $usersTable where email = '$email' AND password_hash = '$digest' limit 1");

    if (result.isEmpty) {
      return null;
    }

    final userId = result[0]['id'];

    return await getUserById(userId.toString());
  }

  Future<User?> getUserByUsername(String username) async {
    final result = await db.query(
        "SELECT * from $usersTable where username = '$username' limit 1");

    if (result.isEmpty) {
      return null;
    }

    final userId = result[0][0];

    return await getUserById(userId.toString());
  }

  Future<User?> updateUserByEmail(String email,
      {String? username,
      String? emailForUpdate,
      String? password,
      String? bio,
      String? image}) async {
    final updatedUser = await getUserByEmail("");
    return updatedUser;
  }

  Future _validateUsernameOrThrow(String username) async {
    if (username.trim().isEmpty) {
      throw ArgumentException(
          message: 'username cannot be blank', parameterName: 'username');
    }

    if ((await getUserByUsername(username)) != null) {
      throw AlreadyExistsException(message: 'Username is taken');
    }
  }

  Future _validateEmailOrThrow(String email) async {
    if (!EmailValidator.validate(email)) {
      throw ArgumentException(
          message: 'Invalid email: $email', parameterName: 'email');
    }

    if ((await getUserByEmail(email)) != null) {
      throw AlreadyExistsException(message: 'Email is taken');
    }
  }

  void _validatePasswordOrThrow(String password) {
    // See https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html#implement-proper-password-strength-controls
    final passwordMinLength = 8;
    final passwordMaxLength = 64;

    if (password.length < passwordMinLength) {
      throw ArgumentException(
          message:
              'Password length must be greater than or equal to $passwordMinLength',
          parameterName: 'password');
    }

    if (password.length > passwordMaxLength) {
      throw ArgumentException(
          message:
              'Password length must be less than or equal to $passwordMaxLength',
          parameterName: 'password');
    }
  }
}
