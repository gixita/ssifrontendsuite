import 'package:http/http.dart' as http;
import 'dart:convert';
import 'did_model.dart';
import 'vc_model.dart';
import 'vc_parsing.dart';
import 'dart:math';
import 'package:ssifrontendsuite/globalvar.dart';

class Workflow {
  final String baseURL = "${GlobalVar.ssiServerURI}/";

  // Fake the portal generate a UUID for the exchange id
  String generateRandomEchangeId() {
    var rng = Random();
    String randomNumber = rng.nextInt(100000000).toString();
    return randomNumber;
  }

  Future<http.Response> configureCredentialExchange(
      http.Client client, String configuration) async {
    final url = Uri.parse("${baseURL}vc-api/exchanges");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    final body = configuration;
    http.Response res =
        await client.post(url, body: body, headers: requestHeaders);

    return res;
  }

  // Fake the authority portal
  // After the SSI server is configure, the authority portal use the exchange id
  // from the configuration string to provide the qr to the mobile wallet
  String authorityReturnExchangeInvitation(
      String configuration, String credentialType) {
    final dynamic configurationJson = jsonDecode(configuration);
    String credentialTypeAvailable = "";
    if (credentialType.isNotEmpty) {
      credentialTypeAvailable = '"credentialTypeAvailable": "$credentialType",';
    }
    final String exchangeId = configurationJson['exchangeId'];
    String outOfBandInvitation = """{
    "outOfBandInvitation": { 
        "type": "https://energyweb.org/out-of-band-invitation/vc-api-exchange",
        "body": { 
            $credentialTypeAvailable
            "url": "${GlobalVar.ssiServerURI}/vc-api/exchanges/$exchangeId" 
        }
    }
} """;
    return outOfBandInvitation;
  }

  // by the mobile wallet
  // The mobile wallet receive through a QR code the URL to post the request
  // to initiate the exchange
  String getURLToInitiateExchange(String configureCredentialExchangeResult) {
    final dynamic configureCredentialExchangeResultJson =
        jsonDecode(configureCredentialExchangeResult);
    return configureCredentialExchangeResultJson['outOfBandInvitation']['body']
            ['url']
        .toString();
  }

  // made by the wallet
  // The wallet initiate the exchange and will receive an endpoint and
  // a challenge
  Future<String> initiateIssuance(
      http.Client client, String urlFromOutOfBandInvitation) async {
    final url = Uri.parse(urlFromOutOfBandInvitation);
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    // Maybe the headers should not be provided
    http.Response res = await client.post(url, headers: requestHeaders);
    // example of response:
//     {
//     "errors": [],
//     "vpRequest": {
//         "challenge": "8c08e4a3-a273-4105-981f-5100d188510c",
//         "query": [],
//         "interact": {
//             "service": [
//                 {
//                     "type": "MediatedHttpPresentationService2021",
//                     "serviceEndpoint": "${GlobalVar.ssiServerURI}/vc-api/exchanges/resident-card-issuance/65512ccb-5bbc-4e54-858f-5e2f0e728d41"
//                 }
//             ]
//         }
//     }
// }
    return res.body;
  }

  List<String> getCurrentWorkflow(String initializedExchange) {
    final initJson = jsonDecode(initializedExchange);
    var credentialQuery = initJson['vpRequest']['query'];
    String interactType =
        initJson['vpRequest']['interact']['service'][0]['type'];

    if (interactType == "UnmediatedHttpPresentationService2021") {
      for (var query in credentialQuery) {
        if (query["type"] == "PresentationDefinition") {
          return ["present"];
        }
      }
    } else if (interactType == "MediatedHttpPresentationService2021") {
      for (var query in credentialQuery) {
        if (query["type"] == "DIDAuth") {
          return ["issue"];
        }
      }
    }
    return <String>[];
  }

  // This search for compatible vc is only using the VC types as criteria
  List<String> getTypesFromExchangeDefinition(String exchangeDefinition) {
    var exchange = jsonDecode(exchangeDefinition);
    List<String> types = [];
    if (exchange["vpRequest"]["query"] != null) {
      for (var queries in exchange["vpRequest"]["query"]) {
        if (queries["type"] == "PresentationDefinition") {
          if (queries["credentialQuery"] != null) {
            for (var credentialQuery in queries["credentialQuery"]) {
              if (credentialQuery["presentationDefinition"]
                      ["input_descriptors"] !=
                  null) {
                for (var descriptors
                    in credentialQuery["presentationDefinition"]
                        ["input_descriptors"]) {
                  if (descriptors["constraints"]["fields"] != null) {
                    for (var fields in descriptors["constraints"]["fields"]) {
                      if (fields["path"] != null) {
                        List<String> paths =
                            (fields["path"] as List<dynamic>).cast<String>();
                        if (paths.contains("\$.type")) {
                          if (fields["filter"]["contains"]["const"] != null) {
                            types.add(fields["filter"]["contains"]["const"]
                                .toString());
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    if (types.isEmpty) {
      throw "Error there is not types defines for the presentation query";
    }
    return types;
  }

  // The mobile wallet creates a proof on its own ssi server
  // He uses his own DID and send the following payload :
  //   {
  //     "did": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
  //     "options": {
  //         "verificationMethod": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A#z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
  //         "proofPurpose": "authentication",
  //         "challenge": "c2e806b4-35ed-409b-bc3a-b849d7c2b204"
  //     }
  // }
  // to the address : /vc-api/presentations/prove/authentication
  Future<String> retreiveAuthenticationProofFromOwnSSIServer(
      http.Client client, Did myDid, String challenge) async {
    final url =
        Uri.parse("${baseURL}vc-api/presentations/prove/authentication");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    final String body = """{
    "did": "${myDid.id}",
    "options": {
        "verificationMethod": "${myDid.verificationMethod[0].id}",
        "proofPurpose": "authentication",
        "challenge": "$challenge"
    }
}""";
    // Maybe the headers should not be provided
    http.Response res =
        await client.post(url, body: body, headers: requestHeaders);

    // example of response:
    // {
    //     "@context": [
    //         "https://www.w3.org/2018/credentials/v1"
    //     ],
    //     "type": "VerifiablePresentation",
    //     "proof": {
    //         "type": "Ed25519Signature2018",
    //         "proofPurpose": "authentication",
    //         "challenge": "c2e806b4-35ed-409b-bc3a-b849d7c2b204",
    //         "verificationMethod": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A#z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A",
    //         "created": "2022-04-29T09:25:55.969Z",
    //         "jws": "eyJhbGciOiJFZERTQSIsImNyaXQiOlsiYjY0Il0sImI2NCI6ZmFsc2V9..51vek0DLAcdL2DxMRQlOFfFz306Y-EDvqhWYzCInU9UYFT_HQZHW2udSeX2w35Nn-JO4ouhJFeiM8l3e2sEEBQ"
    //     },
    //     "holder": "did:key:z6MkvWkza1fMBWhKnYE3CgMgxHem62YkEw4JbdmEZeFTEZ7A"
    // }
    return res.body;
  }

  // Manage a static DID for the mobile app
  Did retreiveStaticDidForMA() {
    String data =
        '{"id":"did:key:z6Mkf48uvEfsirJyLbLB16xd5yiSiQAiGRYrfW4mKUCMXsAf","verificationMethod":[{"id":"did:key:z6Mkf48uvEfsirJyLbLB16xd5yiSiQAiGRYrfW4mKUCMXsAf#z6Mkf48uvEfsirJyLbLB16xd5yiSiQAiGRYrfW4mKUCMXsAf","type":"Ed25519VerificationKey2018","controller":"did:key:z6Mkf48uvEfsirJyLbLB16xd5yiSiQAiGRYrfW4mKUCMXsAf","publicKeyJwk":{"kty":"OKP","crv":"Ed25519","x":"CO9DiXUEhoVgUlxyyO88oe3xDUf0SfpFn8yd4yM8Ssg","kid":"_AZZykFrCsKbp6o-AmUtfhp87p0Jo5OuVHMlmR_d0ng"}}]}';
    Did maDid = Did.fromJson(jsonDecode(data));
    return maDid;
  }

  // Manage a static DID for the fake portal
  Did retreiveStaticDidForAP() {
    String data =
        '{"id":"did:key:z6MkfmiE71dafyipLL7PtWEKYfzoJqGwXuorWfZiDU7ytDvD","verificationMethod":[{"id":"did:key:z6MkfmiE71dafyipLL7PtWEKYfzoJqGwXuorWfZiDU7ytDvD#z6MkfmiE71dafyipLL7PtWEKYfzoJqGwXuorWfZiDU7ytDvD","type":"Ed25519VerificationKey2018","controller":"did:key:z6MkfmiE71dafyipLL7PtWEKYfzoJqGwXuorWfZiDU7ytDvD","publicKeyJwk":{"kty":"OKP","crv":"Ed25519","x":"E5W-pxT49jN5_mt1EX0W9ZNxVnRRiuYpGZfTeNuRXLY","kid":"smWYkk4WlN4QkMHmsZrBkcC33IhrxFykK71vG6yoaHo"}}]}';
    Did apDid = Did.fromJson(jsonDecode(data));
    return apDid;
  }

  // Mobile wallet submit the authentication proof to the service endpoint
  Future<bool> submitAuthenticationOnAPSSIServer(
      http.Client client, String authPayload, String serviceEndpoint) async {
    final url = Uri.parse(serviceEndpoint);
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    final String body = authPayload;
    // Maybe the headers should not be provided
    http.Response res =
        await client.put(url, body: body, headers: requestHeaders);

    var jsonResponse = jsonDecode(res.body);
    if (jsonResponse['errors'] == null) {
      return false;
    }
    if (jsonResponse['errors'].isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  // Authority portal after getting notified of authentication being ready
  // will sign a VC
  Future<VC> signVCOnAPSSIServer(http.Client client, String unsignedVC) async {
    final url = Uri.parse("${baseURL}vc-api/credentials/issue");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    final String body = unsignedVC;
    // Maybe the headers should not be provided
    http.Response res =
        await client.post(url, body: body, headers: requestHeaders);
    VC vc = VCParsing().parseGenericVC(res.body);
    if (res.statusCode == 201) {
      return vc;
    } else {
      throw "Unable to sign a VC on the SSI server";
    }
  }

  // Authority portal generate a VP unsigned
  String fillInPresentationForIssuanceUnsigned(
      http.Client client, List<VC> vcs, Did authorityPortalDID) {
    String vcsString = "";
    if (vcs.isNotEmpty) {
      vcsString = '[${vcs[0].rawVC}';
      vcs.removeAt(0);
    }
    for (var element in vcs) {
      vcsString += ',$element.rawVC';
    }
    vcsString += ']';
    final String unsignedPresentation = """  {
    "presentation": {
        "@context": ["https://www.w3.org/2018/credentials/v1"],
        "type": ["VerifiablePresentation"],
        "verifiableCredential": $vcsString
    },
    "options": {
        "verificationMethod": "${authorityPortalDID.verificationMethod[0].id}"
    }
}""";
    return unsignedPresentation;
  }

  // Mobile app generate a VP unsigned
  String fillInPresentationByMobileAppUnsigned(http.Client client, List<VC> vcs,
      Did holderDID, List<String> currentWorkflow, String challenge) {
    // Prepare the VCs to be embedded in the VP
    String vcsString = "";
    if (vcs.isNotEmpty) {
      vcsString = '[${vcs[0].rawVC}';
      vcs.removeAt(0);
    }
    for (var element in vcs) {
      vcsString += ',${element.rawVC}';
    }
    vcsString += ']';
    String holder = '';
    String extraOptions = '';
    if (currentWorkflow.contains("present")) {
      holder = ',"holder": "${holderDID.id}"';
      extraOptions = ''',
        "proofPurpose": "authentication",
        "challenge": "$challenge"''';
    }
    final String unsignedPresentation = """  {
    "presentation": {
        "@context": ["https://www.w3.org/2018/credentials/v1"],
        "type": ["VerifiablePresentation"],
        "verifiableCredential": $vcsString
        $holder
    },
    "options": {
        "verificationMethod": "${holderDID.verificationMethod[0].id}"
        $extraOptions
    }
}""";
    return unsignedPresentation;
  }

  // Authority portal generate a VP unsigned
  Future<String> provePresentation(
      http.Client client, String unsignedPresentation) async {
    final url = Uri.parse("${baseURL}vc-api/presentations/prove");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };

    // Maybe the headers should not be provided
    http.Response res = await client.post(url,
        body: unsignedPresentation, headers: requestHeaders);
    if (res.statusCode == 201) {
      return res.body;
    } else {
      throw "Unable to prove a presentation on the SSI server";
    }
  }

  // Authority portal review a presentation for submission
  Future<http.Response> reviewAndSubmitPresentation(http.Client client,
      String signedPresentation, String serviceEndpoint) async {
    final url = Uri.parse("$serviceEndpoint/review");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    final String body = """{
    "result": "approved",
    "vp": $signedPresentation
}""";

    // Maybe the headers should not be provided
    http.Response res =
        await client.post(url, body: body, headers: requestHeaders);
    if (res.statusCode == 201) {
      return res;
    } else {
      throw "Unable to review and submit presentation on the SSI server";
    }
  }

  // Mobile app is requesting the VP from the SSI server
  // If the VP is ready, the SSI server return the VP signed by the autority portal
  // Authority portal review a presentation for submission
  Future<List<String>> continueWithSignedPresentation(
      http.Client client, String payload, String serviceEndpoint) async {
    final url = Uri.parse(serviceEndpoint);
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    final String body = payload;
    // Maybe the headers should not be provided
    http.Response res =
        await client.put(url, body: body, headers: requestHeaders);

    return <String>[res.statusCode.toString(), res.body];
  }
}
