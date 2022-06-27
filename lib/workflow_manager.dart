import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/globalvar.dart';

import 'did_model.dart';
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
    var receivedVCJson = jsonDecode(issuedCredential[1]);
    VC receivedVC = VCService().parseGenericVC(
        jsonEncode(receivedVCJson['vp']['verifiableCredential'][0]));
    return receivedVC;
  }

  Future<List<VC>> selectVCs(List<List<String>> params) async {
    Workflow wf = Workflow();
    VCService vcService = VCService();
    String exchangeDefinition = params[4][0];
    print("here");

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
    String signedPresentation =
        await wf.provePresentation(client, unsignedPresentation);
    prettyPrintJson(signedPresentation);
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

  void prettyPrintJson(String input) {
    const JsonDecoder decoder = JsonDecoder();
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final dynamic object = decoder.convert(input);
    final dynamic prettyString = encoder.convert(object);
    // ignore: avoid_print
    prettyString.split('\n').forEach((dynamic element) => print(element));
  }

  // This is a temporary method and should be deleted as soon as the authority portal is released
  Future<void> authorityPortalIssueVC(String serviceEndpoint,
      String mobileAppDid, String unsignedVC, Did authorityPortalDid) async {
    Workflow wf = Workflow();
    http.Client client = http.Client();
    unsignedVC = unsignedVC.replaceAll("<---mobileAppDid--->", mobileAppDid);
    unsignedVC = unsignedVC.replaceAll(
        "<---authorityPortalDid.id--->", authorityPortalDid.id);
    unsignedVC = unsignedVC.replaceAll(
        "<---authorityPortalDid.verificationMethod--->",
        authorityPortalDid.verificationMethod[0].id);

    // ignore: unused_local_variable
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
      "issuer":"<---authorityPortalDid.id--->",
      "issuanceDate":"2019-12-03T12:19:52Z",
      "expirationDate":"2029-12-03T12:19:52Z",
      "credentialSubject":{
          "id":"<---mobileAppDid--->",
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
        "verificationMethod": "<---authorityPortalDid.verificationMethod--->",
        "proofPurpose": "assertionMethod"
    }
}""";
    VC vc = await wf.signVCOnAPSSIServer(client, unsignedVC);
    List<VC> vcs = <VC>[vc];
    String residentCardUnsignedPresentationFilled = wf
        .fillInPresentationForIssuanceUnsigned(client, vcs, authorityPortalDid);
    String residentCardPresentation = await wf.provePresentation(
        client, residentCardUnsignedPresentationFilled);
    http.Response res = await wf.reviewAndSubmitPresentation(
        client, residentCardPresentation, serviceEndpoint);
  }

  // Temporary method to configure server for issuance
  Future<String> getOutOfBandIssuanceInvitation(
      {String exchangeId = ""}) async {
    http.Client client = http.Client();
    Workflow wf = Workflow();
    final String uuidEchangeId =
        exchangeId != "" ? exchangeId : wf.generateRandomEchangeId();
    // String uuidEchangeId = wf.generateRandomEchangeId();
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
        "url": "${GlobalVar.host}/api/issuevc/$uuidEchangeId"
      }
    ]
}""";
    // Fake Authority portal configure the SSI server for mediated issuance
    await wf.configureCredentialExchange(client, issuanceFakeConfiguration);
    // Get the outofband exchange invitation for the mobile wallet
    String credentialType = "PermanentResidentCard";
    String outOfBandInvitation = wf.authorityReturnExchangeInvitation(
        issuanceFakeConfiguration, credentialType);
    return outOfBandInvitation;
  }

  // Temporary method to configure server for presentation
  Future<String> getOutOfBandPresentationInvitation(List<String> types) async {
    http.Client client = http.Client();
    Workflow wf = Workflow();
    List<String> inputDescriptors = [];
    for (var element in types) {
      inputDescriptors.add("""{
                          "id":"$element",
                          "name":"$element",
                          "purpose":"$element",
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
                                    "const":"$element"
                                  }
                                }
                              }
                            ]
                          }
                        }""");
    }
    final String inputDescriptorsString = inputDescriptors.join(", ");
    String uuidEchangeId = wf.generateRandomEchangeId();
    String presentationConfiguration = """{
   "exchangeId":"$uuidEchangeId",
   "query":[
      {
         "type":"PresentationDefinition",
         "credentialQuery":[
            {
               "presentationDefinition":{
                    "id":"286bc1e0-f1bd-488a-a873-8d71be3c690e",
                    "input_descriptors":[
                        $inputDescriptorsString
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
   "callback":[{
        "url": "https://ptsv2.com/t/uuu96-1653299746/post"
      }]
}""";
    // Fake Authority portal configure the SSI server for mediated issuance
    http.Response res =
        await wf.configureCredentialExchange(client, presentationConfiguration);
    if (res.statusCode == 201) {
      String credentialType = "";
      String outOfBandInvitation = wf.authorityReturnExchangeInvitation(
          presentationConfiguration, credentialType);

      return outOfBandInvitation;
    } else {
      throw "It was not possible to configure the server for a presentation";
    }
  }
}
