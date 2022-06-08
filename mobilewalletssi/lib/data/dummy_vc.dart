// ignore: unused_import
import 'package:ssifrontendsuite/vc.dart';
// ignore: unused_import
import 'package:ssifrontendsuite/vc_parsing.dart';
// ignore: unused_import
import 'package:ssifrontendsuite/vc_model.dart';

Future<bool> storeDummyVCS() async {
  // ignore: unused_local_variable
  String vc1String = r"""{
    "@context": [
        "https://www.w3.org/2018/credentials/v1",
        "https://w3id.org/citizenship/v1"
    ],
    "id": "https://issuer.oidp.uscis.gov/credentials/83627465",
    "type": [
        "VerifiableCredential",
        "PermanentResidentCard"
    ],
    "credentialSubject": {
        "id": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
        "gender": "Male",
        "commuterClassification": "C1",
        "birthDate": "1958-07-17",
        "image": "data:image/png;base64,iVBORw0KGgo...kJggg==",
        "residentSince": "2015-01-01",
        "givenName": "JOHN",
        "type": [
            "PermanentResident",
            "Person"
        ],
        "lprCategory": "C09",
        "birthCountry": "Bahamas",
        "lprNumber": "999-999-999",
        "familyName": "SMITH"
    },
    "issuer": "did:key:z6MkjB8kjJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL",
    "issuanceDate": "2019-12-03T12:19:52Z",
    "proof": {
        "type": "Ed25519Signature2018",
        "proofPurpose": "assertionMethod",
        "verificationMethod": "did:key:z6MkjB8kjJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL#z6MkjB8kjJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL",
        "created": "2022-04-29T09:53:23.786Z",
        "jws": "eyJhbGciOiJFZERTQSIsImNyaXQiOlsiYjY0Il0sImI2NCI6ZmFsc2V9..slzsK4BoLyMHX18MtnVlwF9JqKj4BvVC46cjyVBPFPwrjpzGhbLLbAV3x_j-_B4ZUZuQBa5a-yq6CiW6sJ26AA"
    },
    "expirationDate": "2029-12-03T12:19:52Z"
}""";

  // ignore: unused_local_variable
  String vc2String = r"""{
    "@context": [
        "https://www.w3.org/2018/credentials/v1",
        "https://w3id.org/citizenship/v1"
    ],
    "id": "https://issuer.oidp.uscis.gov/credentials/83627465",
    "type": [
        "VerifiableCredential",
        "HomeBattery"
    ],
    "credentialSubject": {
        "id": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
        "capacity": "17",
        "maxdischargerate": "11"
    },
    "issuer": "did:key:z6MkjB8kjJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL",
    "issuanceDate": "2019-12-03T12:19:52Z",
    "proof": {
        "type": "Ed25519Signature2018",
        "proofPurpose": "assertionMethod",
        "verificationMethod": "did:key:z6MkjB8kjJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL#z6MkjB8kjJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL",
        "created": "2022-04-29T09:53:23.786Z",
        "jws": "eyJhbGciOiJFZERTQSIsImNyaXQiOlsiYjY0Il0sImI2NCI6ZmFsc2V9..slzsK4BoLyMHX18MtnVlwF9JqKj4BvVC46cjyVBPFPwrjpzGhbLLbAV3x_j-_B4ZUZuQBa5a-yq6CiW6sJ26AA"
    },
    "expirationDate": "2029-12-03T12:19:52Z"
}""";
  VC vc1 = VCParsing().parseGenericVC(vc1String);
  // VC vc2 = VCParsing().parseGenericVC(vc2String);
  await VCService().storeVC(vc1);
  await VCService().storeVC(vc1);
  // await VCService().storeVC(vc1);
  // await VCService().storeVC(vc1);
  // await VCService().storeVC(vc1);
  // await VCService().storeVC(vc2);
  // await VCService().storeVC(vc1);
  // await VCService().storeVC(vc1);
  // await VCService().storeVC(vc2);
  return true;
}
