import 'dart:convert';
import 'dart:io';
import 'package:fakeportal/qr_helper.dart';
import 'package:ssifrontendsuite/workflow.dart';
import 'package:ssifrontendsuite/did_model.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:qr/qr.dart';

class Api {
  List data = jsonDecode(File('friends.json').readAsStringSync())['users'];
  Did authorityPortalDid;
  Api(this.authorityPortalDid);

  Handler get handler {
    final router = Router();
    String startPageHtml =
        """<!DOCTYPE html><html><body><h1>SSI portal</h1>Fake portal to demonstrate the capabilities of the SSI stack <br>
        Current Decentralised Identifier (DID) of the portal: ${authorityPortalDid.id}<br><br>
        I want to get a proof of my identity: <a href="/identityproof">Get an indentity proof</a>

        </body></html>""";

    router.get('/', (Request request) {
      return Response.ok(startPageHtml, headers: {"Content-type": "text/html"});
    });

    router.get('/identityproof', (Request request) async {
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
      await wf.configureCredentialExchange(client, issuanceFakeConfiguration);
      // Get the outofband exchange invitation for the mobile wallet
      String credentialType = "PermanentResidentCard";
      String outOfBandInvitation = wf.authorityReturnExchangeInvitation(
          issuanceFakeConfiguration, credentialType);
      final qrCode = QrCode(20, QrErrorCorrectLevel.L)
        ..addData(outOfBandInvitation);
      final qrImage = QrImage(qrCode);
      String qrCodeSVG = QRtoSVG.generateSVG(qrCode, qrImage);
      String identityProofPageHtml =
          """<!DOCTYPE html><html><body><h1>Identity proof issuance workflow</h1>Current Decentralised Identifier (DID) of the portal: ${authorityPortalDid.id}<br><br>
Scan the QR code to start the issuance workflow.<br>
        $qrCodeSVG

        </body></html>""";
      return Response.ok(identityProofPageHtml,
          headers: {"Content-type": "text/html"});
    });

    router.post('/api/issuecredential/<exchangeid>',
        (Request request, String exchangeid) async {
      http.Client client = http.Client();
      Workflow wf = Workflow();
      final payload = jsonDecode(await request.readAsString());
      // TODO Modify service endpoint to come from the payload
      String serviceEndpoint =
          payload["vpRequest"]["interact"]["service"][0]["serviceEndpoint"];
      String mobileAppDid = payload["presentationSubmission"]["vp"]["holder"];
      // TODO retrieve mobile app did from the payload
      String residentCardUnsigned =
          SSIData.getUnsignedResidentCard(authorityPortalDid, mobileAppDid);
      VC vc = await wf.signVCOnAPSSIServer(client, residentCardUnsigned);

      List<VC> vcs = <VC>[vc];
      String residentCardUnsignedPresentationFilled =
          wf.fillInPresentationForIssuanceUnsigned(
              client, vcs, authorityPortalDid);

      String residentCardPresentation = await wf.provePresentation(
          client, residentCardUnsignedPresentationFilled);

      String submitVPResult = await wf.reviewAndSubmitPresentation(
          client, residentCardPresentation, serviceEndpoint);
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-type': 'application/json'},
      );
    });

    return router;
  }
}

class SSIData {
  static String getUnsignedResidentCard(
      Did authorityPortalDid, String mobileAppDid) {
    return """{
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
          "id":"$mobileAppDid",
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
  }
}
