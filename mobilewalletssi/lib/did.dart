import 'dart:convert';
import 'package:http/http.dart' as http;
import 'did_model.dart';
import 'sql_helper.dart';

class DIDHttpService {
  final String baseURL = "https://vc-api-dev.energyweb.org/did";

  Future<Did> getNewDid(http.Client client) async {
    final url = Uri.parse(baseURL);
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    final body = jsonEncode({'method': 'key'});

    http.Response res =
        await client.post(url, body: body, headers: requestHeaders);
    if (res.statusCode == 201) {
      return Did.fromJson(jsonDecode(res.body));
    } else {
      throw "Unable to retrieve an new did.";
    }
  }

  Future<bool> isDidOnServer(http.Client client, String did) async {
    String didForURL = did.replaceAll(":", "%3A");
    final url = Uri.parse("$baseURL/$didForURL");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };

    http.Response res = await client.get(url, headers: requestHeaders);
    if (res.statusCode == 200) {
      if (res.body.isNotEmpty) {
        return true;
      }
      return false;
    } else {
      throw "Unable to retrieve a existing did.";
    }
  }
}

class DIDService {
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
}
