import 'package:flutter/material.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'dart:convert';
import 'package:ssifrontendsuite/vc.dart';

class VCDetailsPage extends StatefulWidget {
  const VCDetailsPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<VCDetailsPage> createState() => _VCDetailsPageState();
}

Widget setContainerItem(String key, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        key,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      Row(children: [const SizedBox(width: 16), Flexible(child: Text(value))]),
      const Divider(color: Colors.grey),
    ],
  );
}

class _VCDetailsPageState extends State<VCDetailsPage> {
  String errorMessage = "";

  List<Widget> generateDetails(VC vc) {
    List<Widget> details = [];
    vc.type.remove("VerifiableCredential");
    details.add(setContainerItem("Document type(s)", vc.type.join(", ")));
    details.add(setContainerItem("Issuer", vc.issuer));
    details.add(setContainerItem("Issuance date", vc.issuanceDate));
    final Map<String, dynamic> credentialSubject =
        json.decode(json.encode(json.decode(vc.rawVC)['credentialSubject']));
    List<Widget> widgets = [];
    recursiveJsonParsing(widgets, credentialSubject);
    List<Widget> detailsToReturn = [...details, ...widgets];

    return detailsToReturn;
  }

  List<Widget> recursiveJsonParsing(
      List<Widget> widgets, Map<String, dynamic> jsonMap) {
    jsonMap.forEach((key, value) {
      if (value is String) {
        widgets.add(setContainerItem(key, value));
      } else {
        if (value is List<dynamic>) {
          String enumerationOfValues = "";
          for (var element in value) {
            if (element is String) {
              enumerationOfValues += " $element,";
            }
          }
          widgets.add(setContainerItem(key, enumerationOfValues));
        } else {
          String subListString = json.encode(value);
          final Map<String, dynamic> subList = json.decode(subListString);
          recursiveJsonParsing(widgets, subList);
        }
      }
    });
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final vc = ModalRoute.of(context)!.settings.arguments as VC;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: generateDetails(vc)),
          )),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.pushNamed(context, '/qrcode');
            },
            tooltip: 'Give a title',
            child: const Icon(Icons.edit)),
        const SizedBox(
          width: 8,
        ),
        FloatingActionButton(
            heroTag: null,
            onPressed: () {
              showAlertDialog(context, vc);
            },
            tooltip: 'Delete',
            child: const Icon(Icons.delete)),
        const SizedBox(
          width: 8,
        ),
      ]),
    );
  }

  showAlertDialog(BuildContext context, VC vc) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context, false);
      },
    );
    Widget continueButton = TextButton(
      child: const Text(
        "Delete",
        style: TextStyle(color: Colors.red),
      ),
      onPressed: () async {
        VCService().deleteVC(vc.dbId).then(
          (value) {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
        );
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Attention"),
      content: const Text(
          "You are about to delete a document, this action is irreversible."),
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
