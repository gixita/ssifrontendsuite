import 'package:flutter/material.dart';
import 'navbar.dart';
import 'login.dart';

class SelectVCToIssuePage extends StatefulWidget {
  const SelectVCToIssuePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<SelectVCToIssuePage> createState() => _SelectVCToIssuePageState();
}

class _SelectVCToIssuePageState extends State<SelectVCToIssuePage> {
  String errorMessage = "";
  String? token;
  List<String> vcTypes = [
    "Permanent resident card",
    "Electric vehicule",
    "Home battery",
  ];
  List<String> issuanceLinks = [
    "/issueidentity",
    "/electricvehicule",
    "/issueidentity",
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
          Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Expanded(child: listViewVCs(vcTypes, issuanceLinks))])
        ]),
      ),
      drawer: const NavBar(),
    );
  }

  ListView listViewVCs(List<String> vcTypes, List<String> issueLinks) {
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
                        child: const Text('Issue'),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            issueLinks[index],
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
