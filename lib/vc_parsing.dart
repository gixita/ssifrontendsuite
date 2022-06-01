import 'vc_model.dart';

class VCParsing {
  VC parseGenericVC(String rawVC) {
    VC resultVC = VC.fromJson(rawVC);
    return resultVC;
  }
}
