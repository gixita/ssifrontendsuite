import 'dart:convert';

VC vcFromJson(String str) => VC.fromJson(str);

String vcToJson(VC data) => json.encode(data.toJson());

// class VC {
//   Map<String, String> parseGenericVC(rawVC) {
//     Map<String, dynamic> decodedVC = jsonDecode(rawVC);
//     Map<String, String> resultVC = {
//       "type": decodedVC['type'].toString(),
//       "issuer": decodedVC['issuer'].toString(),
//       "issuanceDate": decodedVC['issuanceDate'].toString(),
//       "expirationDate": decodedVC['expirationDate'].toString(),
//       "rawVC": rawVC,
//     };
//     return resultVC;
//   }

class VC {
  VC({
    required this.type,
    required this.issuer,
    required this.issuanceDate,
    required this.expirationDate,
    required this.rawVC,
  });

  List<String> type;
  String issuer;
  String issuanceDate;
  String expirationDate;
  String rawVC;

  factory VC.fromJson(String str) {
    Map<String, dynamic> json = jsonDecode(str);
    final List<String> types = json["type"].cast<String>();
    VC result = VC(
      type: types,
      issuer: json["issuer"],
      issuanceDate: json["issuanceDate"],
      expirationDate: json["expirationDate"],
      rawVC: str,
    );
    return result;
  }

  Map<String, dynamic> toJson() => jsonDecode(rawVC);
}
