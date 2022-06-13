import 'dart:convert';

VC vcFromJson(String str) => VC.fromJson(str);

String vcToJson(VC data) => json.encode(data.toJson());

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
