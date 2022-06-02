import 'package:ssifrontendsuite/did.dart';
import 'package:ssifrontendsuite/vc.dart';

import 'did_model.dart';
import 'did_http.dart';
import 'workflow.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'vc_model.dart';

class WorkflowManager {
  /*
  For a presentation, the following methods should be triggered:
  - startExchangeSSI
  - selectVCs
  - signAndSendVCs

  For an issuance, the following methods should be triggered:
  - startExchangeSSI
  - authorityPortalIssueVC
  - retreiveSignedVCFromAuthority
   */

  // The function return a list of string containing the type of workflow
  // The ojective is to enable testing in the application for the mediated flow
  Future<List<List<String>>> startExchangeSSI(
      String outOfBandInvitation, Did holder) async {
    http.Client client = http.Client();
    Workflow wf = Workflow();
    String exchangeURL = wf.getURLToInitiateExchange(outOfBandInvitation);
    final String exchangeDefinition =
        await wf.initiateIssuance(client, exchangeURL);
    var exchangeDefinitionJson = jsonDecode(exchangeDefinition);
    String serviceEndpoint = exchangeDefinitionJson["vpRequest"]["interact"]
        ["service"][0]["serviceEndpoint"];
    final List<String> currentWorflow =
        wf.getCurrentWorkflow(exchangeDefinition);
    final String challenge = exchangeDefinitionJson["vpRequest"]["challenge"];
    String authProofSigned = "";

    if (currentWorflow.contains("issue")) {
      // start authentication
      authProofSigned = await wf.retreiveAuthenticationProofFromOwnSSIServer(
          client, holder, exchangeDefinitionJson["vpRequest"]["challenge"]);
      bool isAuthenticated = await wf.submitAuthenticationOnAPSSIServer(
          client, authProofSigned, serviceEndpoint);
      if (!isAuthenticated) {
        throw "The mobile could not authenticate on the server";
      }
    }
    print("auth proof signed");
    print(authProofSigned);
    return [
      currentWorflow,
      <String>[serviceEndpoint],
      <String>[challenge],
      <String>[authProofSigned],
      <String>[exchangeDefinition]
    ];
  }

  Future<VC> retreiveSignedVCFromAuthority(
      List<List<String>> params, Did holder) async {
    Workflow wf = Workflow();
    http.Client client = http.Client();
    String serviceEndpoint = params[1][0];
    String authProofSigned = params[3][0];

    String retreiveCredentialStatusCode = "429";
    int retry = 0;
    List<String> testRetrieveCredential = <String>[];
    List<String> issuedCredential = <String>[];
    while (retry < 14) {
      print("retry $retry before getting the issued cred");
      testRetrieveCredential = await wf.continueWithSignedPresentation(
          client, authProofSigned, serviceEndpoint);
      retry += 1;
      retreiveCredentialStatusCode = testRetrieveCredential[0];
      if (retreiveCredentialStatusCode == "200") {
        issuedCredential = testRetrieveCredential;
        retry = 20;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    print("issued cred");
    print(issuedCredential[1]);
    var receivedVCJson = jsonDecode(issuedCredential[1]);
    VC receivedVC = VCService().parseGenericVC(
        jsonEncode(receivedVCJson['vp']['verifiableCredential'][0]));
    return receivedVC;
  }

  Future<List<VC>> selectVCs(List<List<String>> params) async {
    Workflow wf = Workflow();
    VCService vcService = VCService();
    String exchangeDefinition = params[4][0];

    return await vcService
        .getVCsByTypes(wf.getTypesFromExchangeDefinition(exchangeDefinition));
  }

  // In the presentation workflow, we finish by sending the VCs to the authority portal
  Future<bool> sendVCs(
      List<List<String>> params, Did holder, List<VC> vcsToPresent) async {
    Workflow wf = Workflow();
    http.Client client = http.Client();
    List<String> currentWorkflow = params[0];
    String serviceEndpoint = params[1][0];
    String challenge = params[2][0];

    String unsignedPresentation = wf.fillInPresentationByMobileAppUnsigned(
        client, vcsToPresent, holder, currentWorkflow, challenge);
    print("unsigned presentation----");
    print(unsignedPresentation);

    String signedPresentation =
        await wf.provePresentation(client, unsignedPresentation);
    print("signed presentation ----");
    print(signedPresentation);
    List<String> endOfPresentationResponse =
        await wf.continueWithSignedPresentation(
            client, signedPresentation, serviceEndpoint);
    if (endOfPresentationResponse[0] != "200") {
      return false;
      // throw "Impossible to present proofs to the authority";
    } else {
      return true;
    }
  }

  // This is a temporary method and should be deleted as soon as the authority portal is released
  Future<void> authorityPortalIssueVC(
      String serviceEndpoint, Did mobileAppDid) async {
    Workflow wf = Workflow();
    final didHttp = DIDHttpService();
    http.Client client = http.Client();
    Did authorityPortalDid = await didHttp.getNewDid(client);
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
    print("before signing");
    VC vc = await wf.signVCOnAPSSIServer(client, residentCardUnsigned);
    List<VC> vcs = <VC>[vc];
    print("before fill preseentation");
    String residentCardUnsignedPresentationFilled = wf
        .fillInPresentationForIssuanceUnsigned(client, vcs, authorityPortalDid);
    print("before prove presentation");
    String residentCardPresentation = await wf.provePresentation(
        client, residentCardUnsignedPresentationFilled);
    print("before review and submit");
    await wf.reviewAndSubmitPresentation(
        client, residentCardPresentation, serviceEndpoint);
    print("after review and submit");
  }

  // Temporary method to configure server for issuance
  Future<String> getOutOfBandIssuanceInvitation() async {
    http.Client client = http.Client();
    Workflow wf = Workflow();

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
    // Get the outofband exchange invitation for the mobile wallet
    String credentialType = "PermanentResidentCard";
    String outOfBandInvitation = wf.authorityReturnExchangeInvitation(
        issuanceFakeConfiguration, credentialType);
    return outOfBandInvitation;
  }

  // Temporary method to configure server for presentation
  Future<String> getOutOfBandPresentationInvitation() async {
    http.Client client = http.Client();
    Workflow wf = Workflow();

    String uuidEchangeId = wf.generateRandomEchangeId();
    String issuanceFakeConfiguration = """{
   "exchangeId":"$uuidEchangeId",
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
    String resConf =
        await wf.configureCredentialExchange(client, issuanceFakeConfiguration);
    var resConfJson = jsonDecode(resConf);
    // Get the outofband exchange invitation for the mobile wallet
    String credentialType = "";
    String outOfBandInvitation = wf.authorityReturnExchangeInvitation(
        issuanceFakeConfiguration, credentialType);
    return outOfBandInvitation;
  }
}
