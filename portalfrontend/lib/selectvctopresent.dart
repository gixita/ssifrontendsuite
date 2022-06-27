import 'package:flutter/material.dart';
import 'navbar.dart';
import 'login.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ssifrontendsuite/globalvar.dart';
import 'package:http/http.dart' as http;

class SelectVCToPresentPage extends StatefulWidget {
  const SelectVCToPresentPage({Key? key, required this.title})
      : super(key: key);
  final String title;

  @override
  State<SelectVCToPresentPage> createState() => _SelectVCToPresentPageState();
}

class _SelectVCToPresentPageState extends State<SelectVCToPresentPage> {
  String errorMessage = "";
  String? token;
  List<String> vcTypes = [
    "Permanent resident card",
    "Electric vehicule",
    "Home battery",
  ];
  List<String> presentationVCType = [
    "PermanentResidentCard",
    "ElectricalVehicule",
    "issueidentity",
  ];

  Future<String?> getToken() async {
    String? local = await AuthUtils.getToken();
    setState(() {
      token = local;
    });
    return token;
  }

  @override
  void initState() {
    super.initState();
    getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(children: [
          Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Expanded(child: listViewVCs(vcTypes, presentationVCType))
          ])
        ]),
      ),
      drawer: const NavBar(),
    );
  }

  ListView listViewVCs(List<String> vcTypes, List<String> presentationVCType) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: vcTypes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.person, size: 40),
                    title: Text(vcTypes[index]),
                    // subtitle: Text('text'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: const Text('Make presentation'),
                        onPressed: () async {
                          String body = """{
                            "types": ["${presentationVCType[index]}"]
                          }""";
                          var res = await http.post(
                              Uri.parse(
                                  "${GlobalVar.host}/api/startpresentation"),
                              headers: {'Authorization': 'Token $token'},
                              body: body);
                          if (res.statusCode == 200) {
                            showAlertDialog(context, res.body);
                          } else {
                            showAlertDialog(context, "Error");
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  showAlertDialog(BuildContext context, String presentationInvitation) {
    // set up the buttons

    Widget continueButton = TextButton(
      child: const Text("Ok"),
      onPressed: () async {
        Navigator.pop(context, false);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Presentation"),
      content: presentationInvitation == "Error"
          ? const Text("Error")
          : CustomPaint(
              size: const Size.square(280),
              painter: QrPainter(
                data: presentationInvitation,
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xff128760),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Color(0xff1a5441),
                ),
                // size: 320.0,
              ),
            ),
      actions: [
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
