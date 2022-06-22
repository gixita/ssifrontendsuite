import 'package:flutter/material.dart';
import 'package:ssifrontendsuite/did_model.dart';

class DidDetailsPage extends StatefulWidget {
  const DidDetailsPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<DidDetailsPage> createState() => _DidDetailsPageState();
}

class _DidDetailsPageState extends State<DidDetailsPage> {
  String errorMessage = "";
  String didPrivateKey = "";

  @override
  Widget build(BuildContext context) {
    final did = ModalRoute.of(context)!.settings.arguments as Did;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My main identifier",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(did.id),
            const SizedBox(
              height: 16,
            ),
            const Text(
              "My DID controller key",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(did.verificationMethod[0].controller),
            const SizedBox(
              height: 16,
            ),
            const Text(
              "My DID signature algorithm",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(did.verificationMethod[0].publicKeyJwk.crv),
            const SizedBox(
              height: 16,
            ),
            const Text(
              "My DID private key",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8,
            ),
            didPrivateKey == ""
                ? ElevatedButton(
                    onPressed: () {
                      showAlertDialog(context, did);
                    },
                    child: const Text("Show private key"))
                : Text(didPrivateKey),
          ],
        ),
      ),
    );
  }

  showAlertDialog(BuildContext context, Did did) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context, false);
      },
    );
    Widget continueButton = TextButton(
      child: const Text(
        "Show",
        style: TextStyle(color: Colors.red),
      ),
      onPressed: () async {
        setState(() {
          if (did.verificationMethod[0].privateKeyJwk == null) {
            throw "Error : the private key is null";
          } else {
            didPrivateKey = did.verificationMethod[0].privateKeyJwk!.d;
          }
          Navigator.pop(context, false);
        });
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Attention", style: TextStyle(color: Colors.red)),
      content: const Text(
          "You are about to show your private key, it should remain secret. Do not disclose it to anyone."),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
