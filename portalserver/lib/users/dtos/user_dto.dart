class UserDto {
  final int didId;
  final String username;
  final String email;
  final String token;
  final String? bio;
  final String? image;

  UserDto(
      {required this.didId,
      required this.username,
      required this.email,
      required this.token,
      this.bio,
      this.image});

  UserDto.fromJson(Map<String, dynamic> json)
      : didId = json['user']['didId'],
        username = json['user']['username'],
        email = json['user']['email'],
        token = json['user']['token'],
        bio = json['user']['bio'],
        image = json['user']['image'];

  Map<String, dynamic> toJson() => {
        'user': {
          'didId': didId,
          'username': username,
          'email': email,
          'token': token,
          'bio': bio,
          'image': image
        }
      };
}
