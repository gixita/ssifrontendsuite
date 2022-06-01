import 'package:ssifrontendsuite/did.dart';
import 'package:ssifrontendsuite/did_model.dart';

Future<Did> ensureDIDExists() async {
  // In the future, we would need to get the did in the database if it exists
  // and repopulate the SSI server with the private key.
  return await DIDService().createDid();
}
