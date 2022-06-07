import 'package:flutter/foundation.dart';
import 'package:sqlite_wrapper/sqlite_wrapper.dart';
import 'did_model.dart';
import 'vc_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  }

  static db({inMemory = true}) async {
    String dbPath = inMemoryDatabasePath;
    if (!inMemory) {
      final docDir = await getApplicationDocumentsDirectory();
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }
      dbPath = p.join(docDir.path, "todoDatabase3.sqlite");
    }
    final DatabaseInfo dbInfo =
        await SQLiteWrapper().openDB(dbPath, version: 1, onCreate: () async {
      await createTables();
    });
    // Print where the database is stored
    debugPrint("Database path: ${dbInfo.path}");
  }

  // static Future<sql.Database> db() async {
  //   sqfliteFfiInit();

  //   var databaseFactory = databaseFactoryFfi;
  //   var db = await databaseFactory.openDatabase(inMemoryDatabasePath);

  //   return openDatabase(
  //     sql.inMemoryDatabasePath,
  //     // 'kindacode.db',
  //     version: 1,
  //     onCreate: (sql.Database database, int version) async {
  //       await createTables(database);
  //     },
  //   );
  // }

  static Future<int> createDid(Did did) async {
    // final db = await SQLHelper.db();
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
    int? countDid = await SQLiteWrapper()
        .query("SELECT count(*) from dids", singleResult: true);
    if (countDid! > 0) {
      throw "There is already a DID for this user.";
    }
    final id = await SQLiteWrapper().insert(data, 'dids');
    return id;
  }

  static Future<bool> storeIssuerLabel(String label, String did) async {
    // final db = await SQLHelper.db();
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

  static Future<List<Map<String, dynamic>>> getIssuerLabel(String did) async {
    // final db = await SQLHelper.db();

    return await SQLiteWrapper()
        .query("SELECT * from issuers where did = '$did' limit 1");
  }

  static Future<List<Map<String, dynamic>>> getDids() async {
    // final db = await SQLHelper.db();
    return await SQLiteWrapper().query("SELECT * from dids where 1");
  }

  static Future<List<Map<String, dynamic>>> getDid() async {
    // final db = await SQLHelper.db();
    int? countDid = await SQLiteWrapper()
        .query("SELECT count(*) from dids", singleResult: true);
    if (countDid! < 1) {
      throw "Trying to fetch a non existing DID";
    }
    return await SQLiteWrapper()
        .query("SELECT * from dids where id = 1 limit 1");
  }

  static Future<bool> didExists() async {
    // final db = await SQLHelper.db();
    int? countDid = await SQLiteWrapper()
        .query("SELECT count(*) from dids", singleResult: true);
    if (countDid! < 1) {
      return false;
    }
    return true;
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
    // final db = await SQLHelper.db();
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
    // final db = await SQLHelper.db();
    return await SQLiteWrapper()
        .query("SELECT * from vcs where id = $id limit 1");
  }

  static Future<List<Map<String, dynamic>>> getReceivedVCs(String myDid) async {
    // final db = await SQLHelper.db();
    return await SQLiteWrapper()
        .query("SELECT * from vcs where issuer = '$myDid'");
  }

  static Future<List<Map<String, dynamic>>> getAllVCs() async {
    // final db = await SQLHelper.db();
    return await SQLiteWrapper().query("SELECT * from vcs where 1");
  }

  static Future<List<Map<String, dynamic>>> getSelfSignedVCs(
      String myDid) async {
    // final db = await SQLHelper.db();
    return await SQLiteWrapper()
        .query("SELECT * from vcs where issuer = '$myDid'");
  }

  static Future<List<Map<String, dynamic>>> getVCsByTypes(
      List<String> types) async {
    // final db = await SQLHelper.db();
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
