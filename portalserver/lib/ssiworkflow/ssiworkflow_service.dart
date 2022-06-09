import 'package:sqlite_wrapper/sqlite_wrapper.dart';

class SSIWorkflowService {
  static String exchangeIdsTable = 'exchangeids';

  final SQLiteWrapper db;

  SSIWorkflowService({required this.db});

  Future<int> createExchangeId(
      {required int vcId, required String exchangeId}) async {
    return await db
        .insert({"vc_id": vcId, "exchangeid": exchangeId}, exchangeIdsTable);
  }

  Future<int> getUnsignedVCIdByExchangeId({required String exchangeId}) async {
    var vcId = await db.query(
        "SELECT vc_id from $exchangeIdsTable where exchangeid='$exchangeId' limit 1",
        singleResult: true);
    if (vcId == null) {
      return 0;
    } else {
      return vcId;
    }
  }

  Future<String> getUnsignedVCByExchangeId({required String exchangeId}) async {
    final int vcId = int.parse(await db.query(
        "SELECT vc_id from $exchangeIdsTable where exchangeid = '$exchangeId' limit 1",
        singleResult: true));
    return await db.query(
        "SELECT unsignedvcs from unsignedvcs where id=$vcId limit 1",
        singleResult: true);
  }
}
