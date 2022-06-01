import 'dart:convert';
import 'package:http/http.dart' as http;
import 'did_model.dart';

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
