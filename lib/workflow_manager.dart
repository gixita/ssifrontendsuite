import 'package:ssifrontendsuite/did.dart';

import 'did_model.dart';
import 'workflow.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'vc_model.dart';

class WorkflowManager {
  // The function return a list of string containing the type of workflow
  // The ojective is to enable testing in the application for the mediated flow
  Future<List<List<String>>> startExchangeSSI(
      String outOfBandInvitation, Did holder) async {
    http.Client client = http.Client();
    Workflow wf = Workflow();
    String exchangeURL = wf.getURLToInitiateExchange(outOfBandInvitation);
    final String issuanceBody = await wf.initiateIssuance(client, exchangeURL);
    var issuanceBodyJson = jsonDecode(issuanceBody);
    String serviceEndpoint = issuanceBodyJson["vpRequest"]["interact"]
        ["service"][0]["serviceEndpoint"];
    final List<String> currentWorflow = wf.getCurrentWorkflow(issuanceBody);
    final String challenge = issuanceBodyJson["vpRequest"]["challenge"];
    String authProofSigned = "";

    if (currentWorflow.contains("issue")) {
      // start authentication
      authProofSigned = await wf.retreiveAuthenticationProofFromOwnSSIServer(
          client, holder, issuanceBodyJson["vpRequest"]["challenge"]);
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
      <String>[authProofSigned]
    ];
  }

  Future<String> finishEchangeSSI(List<List<String>> params, Did holder) async {
    Workflow wf = Workflow();
    http.Client client = http.Client();
    List<String> currentWorkflow = params[0];
    String serviceEndpoint = params[1][0];
    String challenge = params[2][0];
    String authProofSigned = params[3][0];

    if (currentWorkflow.contains("issue")) {
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
      return issuedCredential[1];
    }

    if (currentWorkflow.contains("present")) {
      // Todo import vcs from the db
      List<VC> vcsToPresent = <VC>[];
      String unsignedPresentation = wf.fillInPresentationByMobileAppUnsigned(
          client, vcsToPresent, holder, currentWorkflow, challenge);
      String signedPresentation =
          await wf.provePresentation(client, unsignedPresentation);
      List<String> endOfPresentationResponse =
          await wf.continueWithSignedPresentation(
              client, signedPresentation, serviceEndpoint);
      if (endOfPresentationResponse[0] != "200") {
        throw "Impossible to present proofs to the authority";
      }
    }

    return "";
  }

  // This is a temporary method and should be deleted as soon as the authority portal is released
  void authorityPortalIssueVC(String serviceEndpoint, Did mobileAppDid) async {
    Workflow wf = Workflow();
    http.Client client = http.Client();
    Did authorityPortalDid = await DIDService().createDid();
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
    List<VC> vcs = <VC>[vc];
    String residentCardUnsignedPresentationFilled = wf
        .fillInPresentationForIssuanceUnsigned(client, vcs, authorityPortalDid);

    String residentCardPresentation = await wf.provePresentation(
        client, residentCardUnsignedPresentationFilled);

    await wf.reviewAndSubmitPresentation(
        client, residentCardPresentation, serviceEndpoint);
  }
}
