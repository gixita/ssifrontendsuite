@Skip("SQL test are not supported so skipped in flutter test (vc_db_test.dart)")

import 'package:test/test.dart' as test;
import 'package:flutter_test/flutter_test.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/vc_model.dart';

void main() {
  String rawVc = r"""{
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
  // test.test('Test VC to database with SQLHelper, storage, getById', () async {
  //   TestWidgetsFlutterBinding.ensureInitialized();
  //   VC vc = VCService().parseGenericVC(rawVc);
  //   await SQLHelper.storeVC(vc);
  //   var vcListFromDb = await SQLHelper.getVCById(1);
  //   VC vcFromDb = VCService().parseGenericVC(vcListFromDb[0]['rawVC']);
  //   expect(vcFromDb, isA<VC>());
  //   var receivedVCs = await SQLHelper.getReceivedVCs(
  //       "did:key:notmejJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL");
  //   var selfSignedVCs = await SQLHelper.getSelfSignedVCs(
  //       "did:key:z6MkjB8kjJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL");
  //   var selfSignedVCShoudBeEmpty = await SQLHelper.getSelfSignedVCs(
  //       "did:key:notmejJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL");
  //   //test with one type
  //   List<String> notExistingType = <String>['test'];
  //   var byTypeVCShouldBeEmpty = await SQLHelper.getVCsByTypes(notExistingType);
  //   //test with two types
  //   List<String> notExistingTypes = <String>['test', 'test2'];
  //   var byTypesVCShouldBeEmpty =
  //       await SQLHelper.getVCsByTypes(notExistingTypes);
  //   List<String> existingType = <String>['PermanentResidentCard'];
  //   var byTypeVC = await SQLHelper.getVCsByTypes(existingType);

  //   expect(receivedVCs.isNotEmpty, true);
  //   expect(selfSignedVCs.isNotEmpty, true);
  //   expect(selfSignedVCShoudBeEmpty.isEmpty, true);
  //   expect(byTypeVCShouldBeEmpty.isEmpty, true);
  //   expect(byTypesVCShouldBeEmpty.isEmpty, true);
  //   expect(byTypeVC.isNotEmpty, true);
  // });

  // todo the same with VCService
  test.test('Test VC to database with VCService, storage, getById', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    VC vc = VCService().parseGenericVC(rawVc);
    await VCService().storeVC(vc);
    VC vcFromDb = await VCService().getVCById(1);
    expect(vcFromDb, isA<VC>());
    List<VC> receivedVCs = await VCService().getReceivedVCs(
        "did:key:notmejJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL");
    List<VC> selfSignedVCs = await VCService().getSelfSignedVCs(
        "did:key:z6MkjB8kjJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL");
    List<VC> selfSignedVCShoudBeEmpty = await VCService().getSelfSignedVCs(
        "did:key:notmejJee3JoJ9WmzTG2vXhWJ9KtwPtWLtEec17iFNiEL");
    //test with one type
    List<String> notExistingType = <String>['test'];
    List<VC> byTypeVCShouldBeEmpty =
        await VCService().getVCsByTypes(notExistingType);
    //test with two types
    List<String> notExistingTypes = <String>['test', 'test2'];
    List<VC> byTypesVCShouldBeEmpty =
        await VCService().getVCsByTypes(notExistingTypes);
    List<String> existingType = <String>['PermanentResidentCard'];
    List<VC> byTypeVC = await VCService().getVCsByTypes(existingType);

    expect(receivedVCs.isNotEmpty, true);
    expect(selfSignedVCs.isNotEmpty, true);
    expect(selfSignedVCShoudBeEmpty.isEmpty, true);
    expect(byTypeVCShouldBeEmpty.isEmpty, true);
    expect(byTypesVCShouldBeEmpty.isEmpty, true);
    expect(byTypeVC.isNotEmpty, true);
  });
}
