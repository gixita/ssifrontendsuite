import 'dart:convert';

class UnsignedVCS {
  final String id;
  final String email;
  final String unsignedvcs;
  final String userid;
  final DateTime createdAt;
  final DateTime updatedAt;

  UnsignedVCS(
      {required this.id,
      required this.email,
      required this.unsignedvcs,
      required this.userid,
      required this.createdAt,
      required this.updatedAt});

  UnsignedVCS.fromJson(Map<String, dynamic> json)
      : id = json['unsignedvcs']['id'],
        email = json['unsignedvcs']['email'],
        unsignedvcs = jsonEncode(json['unsignedvcs']['unsignedvcs']),
        userid = json['unsignedvcs']['userid'],
        createdAt = DateTime.parse(json['unsignedvcs']['createdAt']),
        updatedAt = DateTime.parse(json['unsignedvcs']['updatedAt']);

  Map<String, dynamic> toJson() => {
        'unsignedvcs': {
          'id': id,
          'email': email,
          'unsignedvcs': json.decode(unsignedvcs),
          'userid': userid,
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': updatedAt.toIso8601String()
        }
      };
}
