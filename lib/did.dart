import 'package:http/http.dart' as http;
import 'did_model.dart';
import 'sql_helper.dart';
import 'did_http.dart';

class DIDService {
  Future<bool> didExists() async {
    return await SQLHelper.didExists();
  }

  Future<Did> getDid() async {
    var did = await SQLHelper.getDid();
    return didFromJsonString(did[0]);
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

  Future<Did> createDid() async {
    // get did from API
    final didHttp = DIDHttpService();
    final Did did = await didHttp.getNewDid(http.Client());
    // Store did in database
    await SQLHelper.createDid(did);
    return did;
  }

  Future<Did> ensureDIDExists() async {
    var didExist = await didExists();
    if (didExist) {
      return await getDid();
    }
    return await createDid();
  }
}
