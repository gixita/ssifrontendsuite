import 'package:ssifrontendsuite/did.dart';
import 'package:ssifrontendsuite/did_model.dart';

Future<Did> ensureDIDExists() async {
  var didExist = await DIDService().didExists();
  if (didExist) {
    return await DIDService().getDid();
  }
  return await DIDService().createDid();
}
