import 'package:http/http.dart' as http;
import 'did_model.dart';
import 'sql_helper.dart';
import 'did_http.dart';

class DIDService {
  Future<bool> didExistsLocally() async {
    return await SQLHelper.didExists();
  }

  Future<Did> getDid(int didId) async {
    var did = await SQLHelper.getDid();
    return didFromJsonString(did[didId]);
  }

  Did didFromJsonString(Map<String, dynamic> didFromDb) {
    String rawDid = """{
    "id": "${didFromDb['did']}",
    "verificationMethod": [
        {
            "id": "${didFromDb['verification_method']}",
            "type": "${didFromDb['type']}",
            "controller": "${didFromDb['controller']}",
            "publicKeyJwk": {
                "crv": "${didFromDb['crv']}",
                "x": "${didFromDb['x']}",
                "kty": "${didFromDb['kty']}",
                "kid": "${didFromDb['kid']}"
            }
        }
    ]
}
""";
    Did myDid = didFromJson(rawDid);
    return myDid;
  }

  Future<List<dynamic>> createDid() async {
    // get did from API
    final didHttp = DIDHttpService();
    final Did did = await didHttp.getNewDid(http.Client());
    final Did didWithPrivateKey =
        await didHttp.getPrivateKeyFromServer(http.Client(), did);
    // Store did in database
    int didId = await SQLHelper.createDid(didWithPrivateKey);
    return [didWithPrivateKey, didId];
  }

  Future<List<dynamic>> ensureDIDExists({int didId = 0}) async {
    final didHttp = DIDHttpService();
    var client = http.Client();
    var didExistLocally = await didExistsLocally();
    Did did;
    if (didExistLocally) {
      did = await getDid(0);
      var didExistRemotely = await didHttp.isDidOnServer(client, did.id);
      if (didExistRemotely) {
        return [did, 0];
      } else {
        didHttp.setPrivateKeyToServer(client, did);
      }
    }
    return await createDid();
  }
}
