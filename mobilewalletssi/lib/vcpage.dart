import 'package:flutter/material.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'data/dummy_vc.dart';

// usage of flutter builder described in this tutorial
// https://www.woolha.com/tutorials/flutter-using-futurebuilder-widget-examples

class VCPage extends StatefulWidget {
  const VCPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<VCPage> createState() => _VCPageState();
}

class _VCPageState extends State<VCPage> {
  String errorMessage = "";
  List<VC> vcs = [];

  Future<List<VC>> getVCs() async {
    vcs = await VCService().getAllVCs();
    return vcs;
  }

  Future<bool> storeInDb() async {
    await storeDummyVCS();
    List<VC> localvcs = await VCService().getAllVCs();
    setState(() {
      vcs = localvcs;
    });
    return true;
  }

  @override
  void initState() {
    super.initState();
    // SQLHelper.db(); // Loading the diary when the app starts
    storeInDb();
    getVCs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<VC>>(
        future: Future<List<VC>>.value(vcs),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<VC>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return const Text('Error');
            } else if (snapshot.hasData) {
              if (snapshot.data != null) {
                return ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.album),
                                title: Text(snapshot.data![index].type
                                    .join(", ")
                                    .toString()),
                                subtitle: Text(
                                    'Issuer: ${snapshot.data![index].issuer}'),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  TextButton(
                                    child: const Text('View details'),
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/vcdetails',
                                          arguments: snapshot.data![index]);
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
              return const Text("No vc to display");
            } else {
              return const Text('Empty data');
            }
          } else {
            return Text('State: ${snapshot.connectionState}');
          }
        },
      ),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.pushNamed(context, '/qrcode');
            },
            tooltip: 'QRCode reader',
            child: const Icon(Icons.qr_code)),
        const SizedBox(
          width: 8,
        ),
        FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.pushNamed(context, '/ssiworkflow');
            },
            tooltip: 'Add presentation',
            child: const Icon(Icons.add)),
      ]),
    );
  }
}
