@Skip(
    "SQL test are not supported so skipped in flutter test (did_db_test.dart)")
import 'package:ssifrontendsuite/did.dart';
import 'package:test/test.dart' as test;
import 'package:flutter_test/flutter_test.dart';
import 'package:ssifrontendsuite/did_model.dart';
import 'package:ssifrontendsuite/sql_helper.dart';

void main() {
  String rawDid = r"""{
    "id": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
    "verificationMethod": [
        {
            "id": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A#z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
            "type": "Ed25519VerificationKey2018",
            "controller": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
            "publicKeyJwk": {
                "crv": "Ed25519",
                "x": "7qB2-hwO1ajv4CaLjfK7iB13JPUdGLObB8JGjy95KI0",
                "kty": "OKP",
                "kid": "i9CHqa1zwV23F8sxGszjXB53SnB-gKO7aL9hDcmA-ho"
            }
        }
    ]
}""";
  // test.test('Check if did exist', () async {
  //   TestWidgetsFlutterBinding.ensureInitialized();
  //   await SQLHelper.deleteAllDid();
  //   Did did = didFromJson(rawDid);
  //   await SQLHelper.createDid(did);

  //   expect(1, 1);
  // });
  test.test('Get Did from DB', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await SQLHelper.deleteAllDid();
    Did did = didFromJson(rawDid);
    await SQLHelper.createDid(did);
    Did didFromDb = await DIDService().getDid();

    expect(didFromDb, isA<Did>());
  });

  // test.test('Store new did in db from the real API', () async {
  //   TestWidgetsFlutterBinding.ensureInitialized();
  //   await SQLHelper.deleteAllDid();
  //   await DIDService().createDid();
  //   Did didFromDb = await DIDService().getDid();

  //   expect(didFromDb, isA<Did>());
  // });
  // test.test('Init database', () async {
  //   TestWidgetsFlutterBinding.ensureInitialized();
  //   await SQLHelper.db();
  // });
}
