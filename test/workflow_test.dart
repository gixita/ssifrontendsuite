import 'dart:convert';
import 'package:ssifrontendsuite/did_http.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/workflow.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:ssifrontendsuite/did_model.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'package:ssifrontendsuite/workflow_manager.dart';

void main() {
  test("RealApi : issuance workflow mediated", () async {
    http.Client client = http.Client();
    Workflow wf = Workflow();
    DIDHttpService didService = DIDHttpService();
    // if the SSI server restart, you need to recreate a new DID until it is possible
    // to generate a DID from the private key
    // retrieve a new one with the following commented code and modify workflow.dart
    Did mobileAppDid = await didService.getNewDid(client);
    Did authorityPortalDid = await didService.getNewDid(client);
    // Did mobileAppDid = wf.retreiveStaticDidForMA();
    expect(await DIDHttpService().isDidOnServer(client, mobileAppDid.id), true);
    // Did authorityPortalDid = wf.retreiveStaticDidForAP();
    expect(await DIDHttpService().isDidOnServer(client, authorityPortalDid.id),
        true);
    String uuidEchangeId = wf.generateRandomEchangeId();
    String issuanceFakeConfiguration = """{
    "exchangeId": "$uuidEchangeId",
    "query": [
      {
        "type": "DIDAuth",
        "credentialQuery": []
      }
    ],
    "interactServices": [
      {
        "type": "MediatedHttpPresentationService2021"
      }
    ],
    "isOneTime": true,
    "callback": [
      {
        "url": "https://ptsv2.com/t/uuu96-1653299746/post"
      }
    ]
}""";
    // Fake Authority portal configure the SSI server for mediated issuance
    String resConf =
        await wf.configureCredentialExchange(client, issuanceFakeConfiguration);
    var resConfJson = jsonDecode(resConf);
    expect(resConfJson['errors'].isEmpty, true);
    // Get the outofband exchange invitation for the mobile wallet
    String credentialType = "PermanentResidentCard";
    String outOfBandInvitation = wf.authorityReturnExchangeInvitation(
        issuanceFakeConfiguration, credentialType);
    expect(outOfBandInvitation.isNotEmpty, true);
    String exchangeURL = wf.getURLToInitiateExchange(outOfBandInvitation);
    final Uri url = Uri.parse(exchangeURL);
    expect(url, isA<Uri>());
    // Mobile app initiate issuance workflow on the SSI server
    // The SSI server will notify but the fake authority portal (we continue as we would have recieved it)
    final String issuanceBody = await wf.initiateIssuance(client, exchangeURL);

    var issuanceBodyJson = jsonDecode(issuanceBody);
    String serviceEndpoint = issuanceBodyJson["vpRequest"]["interact"]
        ["service"][0]["serviceEndpoint"];
    expect(serviceEndpoint.isNotEmpty, true);
    expect(issuanceBodyJson["errors"].isEmpty, true);
    // The mobile wallet creates a proof on its own ssi server
    String authProofSigned =
        await wf.retreiveAuthenticationProofFromOwnSSIServer(
            client, mobileAppDid, issuanceBodyJson["vpRequest"]["challenge"]);
    expect(jsonDecode(authProofSigned)["proof"].isNotEmpty, true);
    bool isAuthenticated = await wf.submitAuthenticationOnAPSSIServer(
        client, authProofSigned, serviceEndpoint);
    expect(isAuthenticated, true);
    String residentCardUnsigned = """{
  "credential": {
      "@context":[
          "https://www.w3.org/2018/credentials/v1",
          "https://w3id.org/citizenship/v1"
      ],
      "id":"https://issuer.oidp.uscis.gov/credentials/83627465",
      "type":[
          "VerifiableCredential",
          "PermanentResidentCard"
      ],
      "issuer":"${authorityPortalDid.id}",
      "issuanceDate":"2019-12-03T12:19:52Z",
      "expirationDate":"2029-12-03T12:19:52Z",
      "credentialSubject":{
          "id":"${mobileAppDid.id}",
          "type":[
            "PermanentResident",
            "Person"
          ],
          "givenName":"JOHN",
          "familyName":"SMITH",
          "gender":"Male",
          "image":"data:image/png;base64,iVBORw0KGgo...kJggg==",
          "residentSince":"2015-01-01",
          "lprCategory":"C09",
          "lprNumber":"999-999-999",
          "commuterClassification":"C1",
          "birthCountry":"Bahamas",
          "birthDate":"1958-07-17"
      }
    },
    "options": {
        "verificationMethod": "${authorityPortalDid.verificationMethod[0].id}",
        "proofPurpose": "assertionMethod"
    }
}""";

    VC vc = await wf.signVCOnAPSSIServer(client, residentCardUnsigned);
    expect(vc, isA<VC>());
    List<VC> vcs = <VC>[vc];
    String residentCardUnsignedPresentationFilled = wf
        .fillInPresentationForIssuanceUnsigned(client, vcs, authorityPortalDid);

    expect(residentCardUnsignedPresentationFilled.isNotEmpty, true);
    String residentCardPresentation = await wf.provePresentation(
        client, residentCardUnsignedPresentationFilled);
    expect(residentCardPresentation.isNotEmpty, true);

    String submitVPResult = await wf.reviewAndSubmitPresentation(
        client, residentCardPresentation, serviceEndpoint);
    expect(jsonDecode(submitVPResult)['errors'].isEmpty, true);
    // Mobile app is requesting the vp back
    List<String> residentCardVPForMA = await wf.continueWithSignedPresentation(
        client, authProofSigned, serviceEndpoint);
    var residentCardVPForMAJson = jsonDecode(residentCardVPForMA[1]);
    VC vcToStoreByMA = VCService().parseGenericVC(
        jsonEncode(residentCardVPForMAJson['vp']['verifiableCredential'][0]));
    expect(vcToStoreByMA, isA<VC>());

    // //////////////////////////////////////////////
    // Start the presentation of the credential
    // //////////////////////////////////////////////

    String uuidEchangeId4P = wf.generateRandomEchangeId();
    String issuanceFakeConfiguration4P = """{
   "exchangeId":"$uuidEchangeId4P",
   "query":[
      {
         "type":"PresentationDefinition",
         "credentialQuery":[
            {
               "presentationDefinition":{
                    "id":"286bc1e0-f1bd-488a-a873-8d71be3c690e",
                    "input_descriptors":[
                        {
                          "id":"permanent_resident_card",
                          "name":"Permanent Resident Card",
                          "purpose":"We can only allow permanent residents into the application",
                          "constraints": {
                            "fields":[
                              {
                                "path":[
                                  "\$.type"
                                ],
                                "filter":{
                                  "type":"array",
                                  "contains":{
                                    "type":"string",
                                    "const":"PermanentResidentCard"
                                  }
                                }
                              }
                            ]
                          }
                        }
                    ]
                }
            }
         ]
      }
   ],
   "interactServices":[
      {
         "type":"UnmediatedHttpPresentationService2021"
      }
   ],
   "isOneTime":true,
   "callback":[]
}""";
    // Fake Authority portal configure the SSI server for mediated issuance
    String resConf4P = await wf.configureCredentialExchange(
        client, issuanceFakeConfiguration4P);
    var resConfJson4P = jsonDecode(resConf4P);
    expect(resConfJson4P['errors'].isEmpty, true);
    // Get the outofband exchange invitation for the mobile wallet
    String credentialType4P = "";
    String outOfBandInvitation4P = wf.authorityReturnExchangeInvitation(
        issuanceFakeConfiguration4P, credentialType4P);

    expect(outOfBandInvitation4P.isNotEmpty, true);
    String exchangeURL4P = wf.getURLToInitiateExchange(outOfBandInvitation4P);
    final Uri url4P = Uri.parse(exchangeURL4P);
    expect(url4P, isA<Uri>());
    // Mobile app initiate issuance workflow on the SSI server
    // The SSI server will notify but the fake authority portal (we continue as we would have recieved it)
    final String issuanceBody4P =
        await wf.initiateIssuance(client, exchangeURL4P);

    final List<String> currentWorflow4P = wf.getCurrentWorkflow(issuanceBody4P);
    var issuanceBodyJson4P = jsonDecode(issuanceBody4P);
    String serviceEndpoint4P = issuanceBodyJson4P["vpRequest"]["interact"]
        ["service"][0]["serviceEndpoint"];
    expect(serviceEndpoint4P.isNotEmpty, true);
    expect(issuanceBodyJson4P["errors"].isEmpty, true);

    final String challenge4P = issuanceBodyJson4P["vpRequest"]["challenge"];

    List<VC> vcs4P = <VC>[vcToStoreByMA];
    String residentCardUnsignedPresentationFilled4P =
        wf.fillInPresentationByMobileAppUnsigned(
            client, vcs4P, mobileAppDid, currentWorflow4P, challenge4P);

    expect(residentCardUnsignedPresentationFilled4P.isNotEmpty, true);

    String residentCardPresentation4P = await wf.provePresentation(
        client, residentCardUnsignedPresentationFilled4P);
    expect(residentCardPresentation4P.isNotEmpty, true);

//     // Mobile app sends the VP signed
    List<String> endOfPresentationResponse =
        await wf.continueWithSignedPresentation(
            client, residentCardPresentation4P, serviceEndpoint4P);
    expect(endOfPresentationResponse[0] == "200", true);
  }, skip: true);

  test("Test workflow issuance with workflow manager", () async {
    http.Client client = http.Client();
    Workflow wf = Workflow();
    DIDHttpService didService = DIDHttpService();
    // if the SSI server restart, you need to recreate a new DID until it is possible
    // to generate a DID from the private key
    // retrieve a new one with the following commented code and modify workflow.dart
    Did mobileAppDid = await didService.getNewDid(client);
    Did authorityPortalDid = await didService.getNewDid(client);
    // Did mobileAppDid = wf.retreiveStaticDidForMA();
    expect(await DIDHttpService().isDidOnServer(client, mobileAppDid.id), true);
    // Did authorityPortalDid = wf.retreiveStaticDidForAP();
    expect(await DIDHttpService().isDidOnServer(client, authorityPortalDid.id),
        true);
    String uuidEchangeId = wf.generateRandomEchangeId();
    String issuanceFakeConfiguration = """{
    "exchangeId": "$uuidEchangeId",
    "query": [
      {
        "type": "DIDAuth",
        "credentialQuery": []
      }
    ],
    "interactServices": [
      {
        "type": "MediatedHttpPresentationService2021"
      }
    ],
    "isOneTime": true,
    "callback": [
      {
        "url": "https://ptsv2.com/t/uuu96-1653299746/post"
      }
    ]
}""";
    // Fake Authority portal configure the SSI server for mediated issuance
    String resConf =
        await wf.configureCredentialExchange(client, issuanceFakeConfiguration);
    var resConfJson = jsonDecode(resConf);
    expect(resConfJson['errors'].isEmpty, true);
    // Get the outofband exchange invitation for the mobile wallet
    String credentialType = "PermanentResidentCard";
    String outOfBandInvitation = wf.authorityReturnExchangeInvitation(
        issuanceFakeConfiguration, credentialType);
    expect(outOfBandInvitation.isNotEmpty, true);

    // Use Workflow manager
    List<List<String>> params = await WorkflowManager()
        .startExchangeSSI(outOfBandInvitation, mobileAppDid);
    String serviceEndpoint = params[1][0];
    String residentCardUnsigned = """{
  "credential": {
      "@context":[
          "https://www.w3.org/2018/credentials/v1",
          "https://w3id.org/citizenship/v1"
      ],
      "id":"https://issuer.oidp.uscis.gov/credentials/83627465",
      "type":[
          "VerifiableCredential",
          "PermanentResidentCard"
      ],
      "issuer":"${authorityPortalDid.id}",
      "issuanceDate":"2019-12-03T12:19:52Z",
      "expirationDate":"2029-12-03T12:19:52Z",
      "credentialSubject":{
          "id":"${mobileAppDid.id}",
          "type":[
            "PermanentResident",
            "Person"
          ],
          "givenName":"JOHN",
          "familyName":"SMITH",
          "gender":"Male",
          "image":"data:image/png;base64,iVBORw0KGgo...kJggg==",
          "residentSince":"2015-01-01",
          "lprCategory":"C09",
          "lprNumber":"999-999-999",
          "commuterClassification":"C1",
          "birthCountry":"Bahamas",
          "birthDate":"1958-07-17"
      }
    },
    "options": {
        "verificationMethod": "${authorityPortalDid.verificationMethod[0].id}",
        "proofPurpose": "assertionMethod"
    }
}""";

    VC vc = await wf.signVCOnAPSSIServer(client, residentCardUnsigned);
    expect(vc, isA<VC>());
    List<VC> vcs = <VC>[vc];
    String residentCardUnsignedPresentationFilled = wf
        .fillInPresentationForIssuanceUnsigned(client, vcs, authorityPortalDid);

    expect(residentCardUnsignedPresentationFilled.isNotEmpty, true);
    String residentCardPresentation = await wf.provePresentation(
        client, residentCardUnsignedPresentationFilled);
    expect(residentCardPresentation.isNotEmpty, true);

    String submitVPResult = await wf.reviewAndSubmitPresentation(
        client, residentCardPresentation, serviceEndpoint);
    expect(jsonDecode(submitVPResult)['errors'].isEmpty, true);
    // Finish with worflow manager
    String issuedCredential =
        await WorkflowManager().finishEchangeSSI(params, mobileAppDid);
    var issuedCredentialJson = jsonDecode(issuedCredential);
    VC vcToStoreByMA = VCService().parseGenericVC(
        jsonEncode(issuedCredentialJson['vp']['verifiableCredential'][0]));
    expect(vcToStoreByMA, isA<VC>());
  }, skip: false);
  test("RealApi : presentation workflow unmediated", () async {}, skip: true);
  test("MockApi : presentation workflow unmediated", () {});
}
