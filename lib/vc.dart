import 'package:ssifrontendsuite/sql_helper.dart';
import 'vc_model.dart';

class VCService {
  VC parseGenericVC(String rawVC) {
    VC resultVC = VC.fromJson(rawVC);
    return resultVC;
  }

  Future<VC> storeVC(VC vc) async {
    await SQLHelper.storeVC(vc);
    return vc;
  }

  Future<bool> storeIssuerLabel(String label, String did) async {
    return await SQLHelper.storeIssuerLabel(label, did);
  }

  Future<List<Map<String, dynamic>>> getIssuerLabel(String did) async {
    return await SQLHelper.getIssuerLabel(did);
  }

  Future<VC> getVCById(int id) async {
    List<Map<String, dynamic>> vcListOfMap = await SQLHelper.getVCById(id);
    VC vc;
    if (vcListOfMap.isNotEmpty) {
      vc = VCService().parseGenericVC(vcListOfMap[0]['rawVC']);
      vcListOfMap[0]['id'] != null
          ? vc.dbId = vcListOfMap[0]['id']
          : vc.dbId = 0;
    } else {
      throw "There is no VC with that id";
    }
    return vc;
  }

  Future<List<VC>> getReceivedVCs(String myDid) async {
    List<Map<String, dynamic>> receivedVCList =
        await SQLHelper.getReceivedVCs(myDid);
    List<VC> vcList = <VC>[];
    for (var element in receivedVCList) {
      var vc = VCService().parseGenericVC(element['rawVC']);
      element['id'] != null ? vc.dbId = element['id'] : vc.dbId = 0;
      vcList.add(vc);
    }
    return vcList;
  }

  Future<List<VC>> getAllVCs() async {
    List<Map<String, dynamic>> vcList = await SQLHelper.getAllVCs();
    List<VC> vcListToReturn = <VC>[];
    for (var element in vcList) {
      var vc = VCService().parseGenericVC(element['rawVC']);

      element['id'] != null ? vc.dbId = element['id'] : vc.dbId = 0;
      List<Map<String, dynamic>> issuerData =
          await SQLHelper.getIssuerLabel(vc.issuer);
      if (issuerData.isNotEmpty) {
        vc.issuer = issuerData[0]['label'];
      }
      vcListToReturn.add(vc);
    }
    return vcListToReturn;
  }

  Future<void> deleteVC(int id) async {
    await SQLHelper.deleteVC(id);
  }

  Future<List<VC>> getSelfSignedVCs(String myDid) async {
    List<Map<String, dynamic>> receivedVCList =
        await SQLHelper.getSelfSignedVCs(myDid);
    List<VC> vcList = <VC>[];
    for (var element in receivedVCList) {
      vcList.add(VCService().parseGenericVC(element['rawVC']));
    }
    return vcList;
  }

  Future<List<VC>> getVCsByTypes(List<String> types) async {
    List<Map<String, dynamic>> receivedVCList =
        await SQLHelper.getVCsByTypes(types);
    List<VC> vcList = <VC>[];
    for (var element in receivedVCList) {
      vcList.add(VCService().parseGenericVC(element['rawVC']));
    }
    return vcList;
  }
}
