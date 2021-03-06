import 'dart:convert';
import 'package:http/http.dart' as http;
import 'did_model.dart';
import 'package:ssifrontendsuite/globalvar.dart';

class DIDHttpService {
  final String baseURL = "${GlobalVar.ssiServerURI}/did";
  final String baseImportURL = "${GlobalVar.ssiServerURI}/key";

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

  Future<Did> getPrivateKeyFromServer(http.Client client, Did holder) async {
    final url = Uri.parse(
        "$baseImportURL/${holder.verificationMethod[0].publicKeyJwk.kid}");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    http.Response res = await client.get(url, headers: requestHeaders);
    var data = json.decode(res.body);
    holder.verificationMethod[0].privateKeyJwk =
        PrivateKeyJwk(d: data['privateKey']['d']);
    if (data['privateKey']['d'] == null) {
      throw "Error : could not retreive private key form the server";
    }
    return holder;
  }

  Future<bool> setPrivateKeyToServer(http.Client client, Did holder) async {
    // Start with importing the key
    final url = Uri.parse(baseImportURL);
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
    };
    final String bodyString = """
{
  "privateKey": {
    "crv": "${holder.verificationMethod[0].publicKeyJwk.crv}",
    "d": "${holder.verificationMethod[0].privateKeyJwk!.d}",
    "x": "${holder.verificationMethod[0].publicKeyJwk.x}",
    "kty": "${holder.verificationMethod[0].publicKeyJwk.kty}"
  },
  "publicKey": {
    "crv": "${holder.verificationMethod[0].publicKeyJwk.crv}",
    "x": "${holder.verificationMethod[0].publicKeyJwk.x}",
    "kty": "${holder.verificationMethod[0].publicKeyJwk.kty}",
    "kid": "${holder.verificationMethod[0].publicKeyJwk.kid}"
  }
}""";
    http.Response res =
        await client.post(url, body: bodyString, headers: requestHeaders);
    if (res.statusCode == 201) {
      // Second step register the key
      final registerUrl = Uri.parse(baseURL);
      final String registerBodyString = """
{
  "method": "key",
  "keyId": "${holder.verificationMethod[0].publicKeyJwk.kid}"
}""";
      http.Response registerRes = await client.post(registerUrl,
          body: registerBodyString, headers: requestHeaders);
      if (registerRes.statusCode == 201) {
        return true;
      } else {
        throw "Not possible to register key on server";
      }
    } else {
      throw "Not possible to import key on server";
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
