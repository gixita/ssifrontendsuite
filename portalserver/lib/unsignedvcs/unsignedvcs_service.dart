import 'package:ssifrontendsuite/unsignedvcs.dart';
import 'package:portalserver/common/exceptions/argument_exception.dart';
import 'package:portalserver/users/model/user.dart';
import 'package:sqlite_wrapper/sqlite_wrapper.dart';
import '../users/users_service.dart';

class UnsignedVCSService {
  static String unsignedVCSTable = 'unsignedvcs';

  final SQLiteWrapper db;
  final UsersService usersService;

  UnsignedVCSService({required this.db, required this.usersService});

  Future<UnsignedVCS> createUnsignedVCS(
      {required String email,
      required String unsignedvcs,
      required User user}) async {
    _validateEmailOrThrow(email);

    _validateUnsignedVCSOrThrow(unsignedvcs);

    final vcId = await db.insert(
        {'userid': user.id, 'email': email, 'unsignedvcs': unsignedvcs},
        unsignedVCSTable);

    final result = await db
        .query('SELECT * from $unsignedVCSTable where id=$vcId limit 1');

    final vcRow = result[0];

    final String emailRead = vcRow['email'];
    final String unsignedvcsRead = vcRow['unsignedvcs'];
    final DateTime createdAt = DateTime.parse(vcRow['createdAt']);
    final DateTime updatedAt = DateTime.parse(vcRow['updatedAt']);

    UnsignedVCS unsignedVCS = UnsignedVCS(
        id: vcId.toString(),
        email: emailRead,
        unsignedvcs: unsignedvcsRead,
        userid: user.id.toString(),
        createdAt: createdAt,
        updatedAt: updatedAt);
    return unsignedVCS;
  }

  Future<UnsignedVCS?> getUnsignedVCSById(int vcId) async {
    final result = await db
        .query("SELECT * from $unsignedVCSTable where id = $vcId limit 1");

    if (result.isEmpty) {
      return null;
    }

    final vcRow = result[0];

    final String vcIdRead = vcRow['id'].toString();

    final String userIdRead = vcRow['userid'].toString();
    final String emailRead = vcRow['email'];
    final String unsignedvcsRead = vcRow['unsignedvcs'];
    final DateTime createdAt = DateTime.parse(vcRow['createdAt']);
    final DateTime updatedAt = DateTime.parse(vcRow['updatedAt']);

    return UnsignedVCS(
        id: vcIdRead,
        email: emailRead,
        unsignedvcs: unsignedvcsRead,
        userid: userIdRead,
        createdAt: createdAt,
        updatedAt: updatedAt);
  }

  Future<List<UnsignedVCS>> listUnsignedVCS(
      {required User user, required String by}) async {
    dynamic result;
    if (by == "me") {
      result = await db
          .query("SELECT * from $unsignedVCSTable where userid=${user.id}");
    } else {
      result = await db
          .query("SELECT * from $unsignedVCSTable where email='${user.email}'");
    }
    List<UnsignedVCS> unsignedVCSList = [];

    for (var element in result) {
      UnsignedVCS vc = UnsignedVCS(
          id: element['id'].toString(),
          email: element['email'],
          unsignedvcs: element['unsignedvcs'],
          userid: element['userid'].toString(),
          createdAt: DateTime.parse(element['createdAt']),
          updatedAt: DateTime.parse(element['updatedAt']));
      unsignedVCSList.add(vc);
    }
    return unsignedVCSList;
  }

//https://flutterawesome.com/a-simple-way-to-easily-use-the-sqlite-library-from-dart-and-flutter/
  Future<dynamic> deleteUnsignedVCS({required int id}) async {
    final result = await db.delete({"id": id}, unsignedVCSTable, keys: ["id"]);
    return result > 0 ? true : false;
  }

  void _validateEmailOrThrow(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentException(
          message: 'Email cannot be blank', parameterName: 'email');
    }
  }

  void _validateUnsignedVCSOrThrow(String description) {
    if (description.trim().isEmpty) {
      throw ArgumentException(
          message: 'Unsigned vc cannot be blank', parameterName: 'unsignedvcs');
    }
  }
}
