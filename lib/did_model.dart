import 'dart:convert';

Did didFromJson(String str) => Did.fromJson(json.decode(str));

String didToJson(Did data) => json.encode(data.toJson());

class Did {
  Did({
    required this.id,
    required this.verificationMethod,
  });

  String id;
  List<VerificationMethod> verificationMethod;

  factory Did.fromJson(Map<String, dynamic> json) => Did(
        id: json["id"],
        verificationMethod: List<VerificationMethod>.from(
            json["verificationMethod"]
                .map((x) => VerificationMethod.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "verificationMethod":
            List<dynamic>.from(verificationMethod.map((x) => x.toJson())),
      };
}

class VerificationMethod {
  VerificationMethod({
    required this.id,
    required this.type,
    required this.controller,
    required this.publicKeyJwk,
    this.privateKeyJwk,
  });

  String id;
  String type;
  String controller;
  PublicKeyJwk publicKeyJwk;
  PrivateKeyJwk? privateKeyJwk;

  factory VerificationMethod.fromJson(Map<String, dynamic> json) =>
      VerificationMethod(
        id: json["id"],
        type: json["type"],
        controller: json["controller"],
        publicKeyJwk: PublicKeyJwk.fromJson(json["publicKeyJwk"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "controller": controller,
        "publicKeyJwk": publicKeyJwk.toJson(),
      };
}

class PublicKeyJwk {
  PublicKeyJwk({
    required this.crv,
    required this.x,
    required this.kty,
    required this.kid,
  });

  String crv;
  String x;
  String kty;
  String kid;

  factory PublicKeyJwk.fromJson(Map<String, dynamic> json) => PublicKeyJwk(
        crv: json["crv"],
        x: json["x"],
        kty: json["kty"],
        kid: json["kid"],
      );

  Map<String, dynamic> toJson() => {
        "crv": crv,
        "x": x,
        "kty": kty,
        "kid": kid,
      };
}

class PrivateKeyJwk {
  PrivateKeyJwk({
    required this.d,
  });

  String d;

  factory PrivateKeyJwk.fromJson(Map<String, dynamic> json) =>
      PrivateKeyJwk(d: json["d"]);

  Map<String, dynamic> toJson() => {"d": d};
}
