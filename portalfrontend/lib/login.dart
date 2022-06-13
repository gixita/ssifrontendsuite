import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'globalvar.dart';

class AuthUtils {
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? local = prefs.getString('token');
    if (local == null) {
      return "";
    } else {
      return local;
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String errorMessage = "";
  Future<bool> attemptLogIn(String username, String password) async {
    var body = json.encode({
      "user": {"email": username, "password": password}
    });
    var res = await http.post(Uri.parse("${GlobalVar.host}/api/users/login"),
        body: body);
    if (res.statusCode == 200) {
      var resData = json.decode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', resData['user']['token']);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: loginController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    hintText: 'Enter valid email'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter a strong password'),
              ),
            ),
            Text(errorMessage),
            const SizedBox(
              height: 25,
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: ElevatedButton(
                onPressed: () async {
                  if (await attemptLogIn(
                      loginController.text, passwordController.text)) {
                    Navigator.pushNamed(context, '/vcissued');
                  } else {
                    setState(() {
                      errorMessage = "Invalid credentials";
                    });
                  }
                },
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
            const SizedBox(
              height: 130,
            ),
            const Text('New User? Create Account')
          ],
        ),
      ),
    );
  }
}
