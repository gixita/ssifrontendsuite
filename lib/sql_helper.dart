// import 'package:flutter/foundation.dart';
import 'package:sqlite_wrapper/sqlite_wrapper.dart';
import 'did_model.dart';
import 'vc_model.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';

class SQLHelper {
  static final SQLHelper _singleton = SQLHelper._internal();
  factory SQLHelper() {
    return _singleton;
  }

  SQLHelper._internal();

  static Future<void> createTables() async {
    await SQLiteWrapper().execute("""CREATE TABLE dids(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        did TEXT,
        verification_method TEXT,
        type TEXT,
        controller TEXT,
        crv TEXT,
        x TEXT,
        kty TEXT,
        kid TEXT,
        d Text,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
    await SQLiteWrapper().execute("""CREATE TABLE vcs(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        issuer TEXT,
        issuanceDate TEXT,
        expirationDate TEXT,
        rawVC TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
    await SQLiteWrapper().execute("""CREATE TABLE vcs_types(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        vcs_id INTEGER NOT NULL,
        type TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
    await SQLiteWrapper().execute("""CREATE TABLE issuers (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        did TEXT,
        label TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
    await SQLiteWrapper().execute("""CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        didId INTEGER,
        username TEXT,
        email TEXT,
        password_hash TEXT,
        bio TEXT,
        image TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
    await SQLiteWrapper().execute("""CREATE TABLE unsignedvcs(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        email TEXT,
        unsignedvcs TEXT,
        userid INTEGER,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
    await SQLiteWrapper().execute("""CREATE TABLE exchangeids(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        vc_id INTEGER,
        exchangeid TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
  }

  static Future<SQLiteWrapper> db({inMemory = true}) async {
    String dbPath = inMemoryDatabasePath;
    if (!inMemory) {
      // final docDir = await getApplicationDocumentsDirectory();
      // if (!await docDir.exists()) {
      //   await docDir.create(recursive: true);
      // }
      // dbPath = p.join(docDir.path, "TADADatabase3.sqlite");
    }
    // final DatabaseInfo dbInfo =
    await SQLiteWrapper().openDB(dbPath, version: 1, onCreate: () async {
      await createTables();
    });
    // Print where the database is stored
    return SQLiteWrapper();
  }

  static Future<int> createDid(Did did) async {
    final data = {
      'did': did.id,
      'verification_method': did.verificationMethod[0].id,
      'type': did.verificationMethod[0].type,
      'controller': did.verificationMethod[0].controller,
      'crv': did.verificationMethod[0].publicKeyJwk.crv,
      'x': did.verificationMethod[0].publicKeyJwk.x,
      'kty': did.verificationMethod[0].publicKeyJwk.kty,
      'kid': did.verificationMethod[0].publicKeyJwk.kid,
      'd': did.verificationMethod[0].privateKeyJwk!.d,
    };
    final id = await SQLiteWrapper().insert(data, 'dids');
    return id;
  }

  static Future<bool> storeIssuerLabel(String label, String did) async {
    final data = {
      'did': did,
      'label': label,
    };
    int? countDid = await SQLiteWrapper().query(
        "SELECT count(*) from issuers where did='$did'",
        singleResult: true);
    if (countDid! < 1) {
      await SQLiteWrapper().insert(data, 'issuers');
      return true;
    } else {
      return false;
    }
  }

  static Future<void> deleteVC(int id) async {
    var data = {"id": id};
    await SQLiteWrapper().delete(data, 'vcs', keys: const ['id']);
  }

  static Future<List<Map<String, dynamic>>> getIssuerLabel(String did) async {
    return await SQLiteWrapper()
        .query("SELECT * from issuers where did = '$did' limit 1");
  }

  static Future<List<Map<String, dynamic>>> getDids() async {
    return await SQLiteWrapper().query("SELECT * from dids where 1");
  }

  static Future<List<Map<String, dynamic>>> getDid() async {
    int? countDid = await SQLiteWrapper()
        .query("SELECT count(*) from dids", singleResult: true);
    if (countDid! < 1) {
      throw "Trying to fetch a non existing DID";
    }
    return await SQLiteWrapper()
        .query("SELECT * from dids where id = 1 limit 1");
  }

  static Future<bool> didExists() async {
    int? countDid = await SQLiteWrapper()
        .query("SELECT count(*) from dids", singleResult: true);
    if (countDid! < 1) {
      return false;
    }
    return true;
  }

  // static Future<int> updateItem(
  //     int id, String title, String? descrption) async {

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
    // try {
    //   await db.delete("dids", where: "1");
    // } catch (err) {
    //   debugPrint("Something went wrong when deleting an item: $err");
    // }
  }

  static Future<VC> storeVC(VC vc) async {
    // final db = await SQLHelper.db();
    final vcData = {
      'issuer': vc.issuer,
      'issuanceDate': vc.issuanceDate,
      'expirationDate': vc.expirationDate,
      'rawVC': vc.rawVC,
    };

    final id = await SQLiteWrapper().insert(vcData, 'vcs');
    for (var element in vc.type) {
      final typeData = {
        'vcs_id': id,
        'type': element,
      };
      await SQLiteWrapper().insert(typeData, 'vcs_types');
    }
    return vc;
  }

  static Future<List<Map<String, dynamic>>> getVCById(int id) async {
    return await SQLiteWrapper()
        .query("SELECT * from vcs where id = $id limit 1");
  }

  static Future<List<Map<String, dynamic>>> getReceivedVCs(String myDid) async {
    return await SQLiteWrapper()
        .query("SELECT * from vcs where issuer = '$myDid'");
  }

  static Future<List<Map<String, dynamic>>> getAllVCs() async {
    return await SQLiteWrapper().query("SELECT * from vcs where 1");
  }

  static Future<List<Map<String, dynamic>>> getSelfSignedVCs(
      String myDid) async {
    return await SQLiteWrapper()
        .query("SELECT * from vcs where issuer = '$myDid'");
  }

  static Future<List<Map<String, dynamic>>> getVCsByTypes(
      List<String> types) async {
    String typeString = "";
    if (types.isNotEmpty) {
      typeString = "'${types[0]}'";
      types.removeAt(0);
    }
    for (var element in types) {
      typeString += ",'$element'";
    }

    return await SQLiteWrapper().query(
        'SELECT vcs.*, type FROM vcs LEFT JOIN vcs_types ON vcs.id = vcs_types.vcs_id where vcs_types.type in ($typeString)');
  }
}
