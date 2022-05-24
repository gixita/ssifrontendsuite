import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/utils/utils.dart';
import 'did_model.dart';
import 'package:mobilewallet/vc_model.dart';

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE dids(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        did TEXT,
        verification_method TEXT,
        type TEXT,
        controller TEXT,
        crv TEXT,
        x TEXT,
        kty TEXT,
        kid TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
    await database.execute("""CREATE TABLE vcs(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        issuer TEXT,
        issuanceDate TEXT,
        expirationDate TEXT,
        rawVC TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
    await database.execute("""CREATE TABLE vcs_types(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        vcs_id INTEGER NOT NULL,
        type TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      sql.inMemoryDatabasePath,
      // 'kindacode.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<int> createDid(Did did) async {
    final db = await SQLHelper.db();
    final data = {
      'did': did.id,
      'verification_method': did.verificationMethod[0].id,
      'type': did.verificationMethod[0].type,
      'controller': did.verificationMethod[0].controller,
      'crv': did.verificationMethod[0].publicKeyJwk.crv,
      'x': did.verificationMethod[0].publicKeyJwk.x,
      'kty': did.verificationMethod[0].publicKeyJwk.kty,
      'kid': did.verificationMethod[0].publicKeyJwk.kid
    };
    int? countDid =
        firstIntValue(await db.rawQuery("SELECT count(*) from dids"));
    if (countDid! > 0) {
      throw "There is already a DID for this user.";
    }
    final id = await db.insert('dids', data);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getDids() async {
    final db = await SQLHelper.db();
    return db.query('dids', orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> getDid() async {
    final db = await SQLHelper.db();
    int? countDid =
        firstIntValue(await db.rawQuery("SELECT count(*) from dids"));
    if (countDid! < 1) {
      throw "Trying to fetch a non existing DID";
    }
    return await db.query('dids', where: "id = 1", limit: 1);
  }

  // static Future<int> updateItem(
  //     int id, String title, String? descrption) async {
  //   final db = await SQLHelper.db();

  //   final data = {
  //     'title': title,
  //     'description': descrption,
  //     'createdAt': DateTime.now().toString()
  //   };

  //   final result =
  //       await db.update('items', data, where: "id = ?", whereArgs: [id]);
  //   return result;
  // }

  static Future<void> deleteAllDid() async {
    final db = await SQLHelper.db();
    try {
      await db.delete("dids", where: "1");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  static Future<VC> storeVC(VC vc) async {
    final db = await SQLHelper.db();
    final vcData = {
      'issuer': vc.issuer,
      'issuanceDate': vc.issuanceDate,
      'expirationDate': vc.expirationDate,
      'rawVC': vc.rawVC,
    };

    final id = await db.insert('vcs', vcData);
    for (var element in vc.type) {
      final typeData = {
        'vcs_id': id,
        'type': element,
      };
      await db.insert('vcs_types', typeData);
    }
    return vc;
  }

  static Future<List<Map<String, dynamic>>> getVCById(int id) async {
    final db = await SQLHelper.db();
    return await db.query('vcs', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<List<Map<String, dynamic>>> getReceivedVCs(String myDid) async {
    final db = await SQLHelper.db();
    return await db.query('vcs',
        where: "issuer != ?", whereArgs: [myDid], limit: 1);
  }

  static Future<List<Map<String, dynamic>>> getSelfSignedVCs(
      String myDid) async {
    final db = await SQLHelper.db();
    return await db.query('vcs',
        where: "issuer = ?", whereArgs: [myDid], limit: 1);
  }

  static Future<List<Map<String, dynamic>>> getVCsByTypes(
      List<String> types) async {
    final db = await SQLHelper.db();
    String typeString = "";
    if (types.isNotEmpty) {
      typeString = "'${types[0]}'";
      types.removeAt(0);
    }
    for (var element in types) {
      typeString += ",'$element'";
    }

    return await db.rawQuery(
        'SELECT vcs.*, type FROM vcs LEFT JOIN vcs_types ON vcs.id = vcs_types.vcs_id where vcs_types.type in ($typeString)');
  }
}
