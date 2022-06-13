import 'package:flutter/material.dart';
import 'globalvar.dart';
import 'navbar.dart';
import 'login.dart';
import 'package:http/http.dart' as http;
import 'package:ssifrontendsuite/unsignedvcs.dart';
import 'dart:convert';

class VCIssuedToMePage extends StatefulWidget {
  const VCIssuedToMePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<VCIssuedToMePage> createState() => _VCIssuedToMePageState();
}

class _VCIssuedToMePageState extends State<VCIssuedToMePage> {
  String errorMessage = "";
  String? token;
  List<UnsignedVCS> unsignedToMeVCS = [];
  List<UnsignedVCS> unsignedByMeVCS = [];

  Future<String?> getToken() async {
    String? local = await AuthUtils.getToken();
    List<UnsignedVCS> localToMeVCS = await getVCIssuedToMe(local);
    setState(() {
      token = local;
      unsignedToMeVCS = localToMeVCS;
    });
    return token;
  }

  Future<List<UnsignedVCS>> getVCIssuedToMe(String? tokenLocal) async {
    var res = await http.get(
        Uri.parse("${GlobalVar.host}/api/unsignedvcsissuedtome"),
        headers: {'Authorization': 'Token $tokenLocal'});
    if (res.statusCode == 200) {
      for (var element in json.decode(res.body)) {
        unsignedToMeVCS.add(UnsignedVCS.fromJson(element));
      }
      return unsignedToMeVCS;
    }
    return [];
  }

  Future<List<UnsignedVCS>> getVCIssuedByMe(String? tokenLocal) async {
    var res = await http.get(Uri.parse("${GlobalVar.host}/api/unsignedvcs"),
        headers: {'Authorization': 'Token $tokenLocal'});
    if (res.statusCode == 200) {
      for (var element in json.decode(res.body)) {
        unsignedByMeVCS.add(UnsignedVCS.fromJson(element));
      }
      return unsignedByMeVCS;
    }
    return [];
  }

  Future<String> generateQRCode(String vcId) async {
    Map<String, String> body = {'id': vcId};
    var res = await http.post(Uri.parse("${GlobalVar.host}/api/startissuance"),
        headers: {'Authorization': 'Token $token'}, body: json.encode(body));
    if (res.statusCode == 200) {
      return res.body;
    }

    return "";
  }

  @override
  void initState() {
    super.initState();
    getToken();
  }

  Widget displayVCs(String by) {
    List<UnsignedVCS> unsignedVCS;
    if (by == "me") {
      unsignedVCS = unsignedByMeVCS;
    } else {}
    unsignedVCS = unsignedToMeVCS;
    if (unsignedVCS.isEmpty) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Flexible(child: Text("You don't have a verifiable credential yet"))
          ]);
    } else {
      return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [Expanded(child: listViewVCs(unsignedVCS))]);
    }
  }

  @override
  Widget build(BuildContext context) {
    String by = "others";
    if (ModalRoute.of(context) != null) {
      if (ModalRoute.of(context)!.settings.arguments != null) {
        by = ModalRoute.of(context)!.settings.arguments as String;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(
          children: [displayVCs(by)],
        ),
      ),
      drawer: const NavBar(),
    );
  }

  String getTypeFromUnsignedVC(String types) {
    List<String> list = json.decode(types)['credential']['type'].cast<String>();
    list.removeAt(0);
    return list.join(", ");
  }

  ListView listViewVCs(List<UnsignedVCS> vcList) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: vcList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.person, size: 40),
                    title:
                        Text(getTypeFromUnsignedVC(vcList[index].unsignedvcs)),
                    // subtitle: Text('text'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: const Text('View details'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/vcdetails',
                              arguments: vcList[index]);
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        child: const Text('Store in my wallet'),
                        onPressed: () async {
                          await generateQRCode(vcList[index].id).then(
                            (value) {
                              Navigator.pushNamed(context, '/qrcode',
                                  arguments: value);
                            },
                          );
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
}
