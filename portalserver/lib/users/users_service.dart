import 'package:portalserver/common/exceptions/already_exists_exception.dart';
import 'package:portalserver/common/exceptions/argument_exception.dart';
import 'package:portalserver/common/exceptions/not_found_exception.dart';
import 'package:portalserver/users/model/user.dart';
import 'package:email_validator/email_validator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class UsersService {
  static String usersTable = 'users';

  final Database db;

  UsersService({required this.db});

  Future<User> createUser(
      {required String username,
      required String email,
      required String password}) async {
    await _validateUsernameOrThrow(username);

    await _validateEmailOrThrow(email);

    _validatePasswordOrThrow(password);

    final digest = sha256.convert(utf8.encode(password)).toString();

    final result = await db.insert(usersTable, <String, Object?>{
      'username': username,
      'email': email,
      'password_hash': password
    });

    final userInserted =
        await db.query(usersTable, where: "id = $result", limit: 1);

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
    final result = await db.query(usersTable,
        where: "id = ?", whereArgs: [userId], limit: 1);

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
    final result = await db.query(usersTable,
        where: "email = ?", whereArgs: [email], limit: 1);
    if (result.isEmpty) {
      return null;
    }

    final userId = result[0]['id'];

    return await getUserById(userId.toString());
  }

  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final digest = sha256.convert(utf8.encode(password));
    final result = await db.query(usersTable,
        where: "email = ?, password_hash = ?",
        whereArgs: [email, digest],
        limit: 1);
    if (result.isEmpty) {
      return null;
    }

    final userId = result[0]['id'];

    return await getUserById(userId.toString());
  }

  Future<User?> getUserByUsername(String username) async {
    final result = await db.query(usersTable,
        where: "username = ?", whereArgs: [username], limit: 1);

    if (result.isEmpty) {
      return null;
    }

    final userId = result[0][0];

    return await getUserById(userId.toString());
  }

  Future<User> updateUserByEmail(String email,
      {String? username,
      String? emailForUpdate,
      String? password,
      String? bio,
      String? image}) async {
    final user = await getUserByEmail(email);

    if (user == null) {
      throw NotFoundException(message: 'User not found');
    }

    final initialSql = 'UPDATE $usersTable';

    var sql = initialSql;

    if (username != null && username != user.username) {
      await _validateUsernameOrThrow(username);

      if (sql == initialSql) {
        sql = sql + ' SET username = @username';
      } else {
        sql = sql + ', username = @username';
      }
    }

    if (emailForUpdate != null && emailForUpdate != user.email) {
      await _validateEmailOrThrow(emailForUpdate);

      if (sql == initialSql) {
        sql = sql + ' SET email = @emailForUpdate';
      } else {
        sql = sql + ', email = @emailForUpdate';
      }
    }

    if (password != null) {
      _validatePasswordOrThrow(password);

      if (sql == initialSql) {
        sql = sql + " SET password_hash = crypt(@password, gen_salt('bf'))";
      } else {
        sql = sql + ", password_hash = crypt(@password, gen_salt('bf'))";
      }
    }

    if (bio != null && bio != user.bio) {
      if (sql == initialSql) {
        sql = sql + ' SET bio = @bio';
      } else {
        sql = sql + ', bio = @bio';
      }
    }

    if (image != null && image != user.image) {
      _validateImageOrThrow(image);

      if (sql == initialSql) {
        sql = sql + ' SET image = @image';
      } else {
        sql = sql + ', image = @image';
      }
    }

    var updatedEmail = email;

    if (sql != initialSql) {
      sql = sql + ', updated_at = current_timestamp';
      sql = sql + ' WHERE email = @email RETURNING email;';

      // Replace with SQLite
      // final result = await connectionPool.query(sql, substitutionValues: {
      //   'email': email,
      //   'username': username,
      //   'emailForUpdate': emailForUpdate,
      //   'password': password,
      //   'bio': bio,
      //   'image': image
      // });

      // updatedEmail = result[0][0];
    }

    final updatedUser = await getUserByEmail(updatedEmail);

    if (updatedUser == null) {
      throw AssertionError(
          "User cannot be null at this point. Email: $email. Updated Email: $updatedEmail");
    }

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

  void _validateImageOrThrow(String image) {
    final imageUri = Uri.tryParse(image);

    if (imageUri == null ||
        !(imageUri.isScheme('HTTP') || imageUri.isScheme('HTTPS'))) {
      throw ArgumentException(
          message: 'image must be a HTTP/HTTPS URL', parameterName: 'image');
    }
  }
}
