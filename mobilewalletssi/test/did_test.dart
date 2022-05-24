import 'package:test/test.dart';
import 'package:mobilewallet/did.dart';
import 'package:mobilewallet/did_model.dart';
import 'package:http/http.dart' as http;

// import 'package:mobilewallet/sql_helper.dart';

// class MockClient extends Mock implements http.Client {}

void main() {
//   test('Mock DID creation', () async {
//     final didHttp = DIDHttpService();
//     final client = MockClient((request) async {
//       return http.Response(r"""{
//     "id": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
//     "verificationMethod": [
//         {
//             "id": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A#z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
//             "type": "Ed25519VerificationKey2018",
//             "controller": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
//             "publicKeyJwk": {
//                 "crv": "Ed25519",
//                 "x": "7qB2-hwO1ajv4CaLjfK7iB13JPUdGLObB8JGjy95KI0",
//                 "kty": "OKP",
//                 "kid": "i9CHqa1zwV23F8sxGszjXB53SnB-gKO7aL9hDcmA-ho"
//             }
//         }
//     ]
// }""", 201);
//     });

  //   expect(await didHttp.getNewDid(client), isA<Did>());
  // }, skip: true);

  // Run the test against the real API
  test('Real API call for DID creation', () async {
    final didHttp = DIDHttpService();
    final did = await didHttp.getNewDid(http.Client());
    expect(did, isA<Did>());
  }, skip: true);

  test('store string into did', () {
    Map<String, dynamic> didMap = {
      'did': "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
      'verification_method':
          "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A#z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
      'type': "Ed25519VerificationKey2018",
      'controller': "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
      'crv': "Ed25519",
      'x': "7qB2-hwO1ajv4CaLjfK7iB13JPUdGLObB8JGjy95KI0",
      'kty': "OKP",
      'kid': "i9CHqa1zwV23F8sxGszjXB53SnB-gKO7aL9hDcmA-ho"
    };
    expect(DIDService().didFromJsonString(didMap), isA<Did>());
  }, skip: true);
}
