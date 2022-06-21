import 'package:flutter/material.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'package:ssifrontendsuite/workflow_manager.dart';
import 'data/dummy_vc.dart';
import 'package:ssifrontendsuite/sql_helper.dart';

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
  String outOfBandIssuanceInvitation = "";
  String outOfBandPresentationInvitation = "";

  Future<bool> storeInDb() async {
    await SQLHelper.db();
    await storeDummyVCS();
    List<VC> localvcs = await VCService().getAllVCs();
    String localOutOfBandIssuanceInvitation =
        await getOutOfBandIssuanceInvitation();
    String localOutOfBandPresentationInvitation =
        await getOutOfBandPresentationInvitation();
    setState(() {
      vcs = localvcs;
      outOfBandIssuanceInvitation = localOutOfBandIssuanceInvitation;
      outOfBandPresentationInvitation = localOutOfBandPresentationInvitation;
    });
    return true;
  }

  Future<String> getOutOfBandIssuanceInvitation() async {
    return await WorkflowManager().getOutOfBandIssuanceInvitation();
  }

  Future<String> getOutOfBandPresentationInvitation() async {
    return await WorkflowManager().getOutOfBandPresentationInvitation();
  }

  @override
  void initState() {
    super.initState();
    vcs = [];
    storeInDb();
  }

  Future<List<VC>> reload() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return VCService().getAllVCs();
  }

  Future<void> refresh() async {
    List<VC> local = await VCService().getAllVCs();
    setState(() {
      vcs = local;
    });
  }

  Widget displayVCs() {
    if (vcs.isEmpty) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Flexible(child: Text("You don't have a verifiable credential yet"))
          ]);
    } else {
      return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [Expanded(child: listViewVCs(vcs))]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              refresh();
            },
          )
        ],
      ),
      body: Center(
          child: Stack(
        children: [displayVCs()],
      )),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.pushNamed(context, '/qrcode').then((T) {
                setState(() {
                  vcs = [];
                });
                refresh();
              });
            },
            tooltip: 'QRCode reader',
            child: const Icon(Icons.qr_code)),
        const SizedBox(
          width: 8,
        ),
        FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.pushNamed(context, '/ssiworkflow',
                      arguments: outOfBandIssuanceInvitation)
                  .then((T) {
                setState(() {
                  vcs = [];
                });
                refresh();
              });
            },
            tooltip: 'Add presentation',
            child: const Icon(Icons.receipt)),
        const SizedBox(
          width: 8,
        ),
        FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.pushNamed(context, '/ssiworkflow',
                  arguments: outOfBandPresentationInvitation);
            },
            tooltip: 'Add presentation',
            child: const Icon(Icons.send)),
      ]),
    );
  }

  Icon displayVCIcon(List<String> types) {
    if (types.contains("PermanentResidentCard")) {
      return const Icon(
        Icons.person,
        size: 40,
      );
    }
    if (types.contains("Battery")) {
      return const Icon(
        Icons.battery_3_bar,
        size: 40,
      );
    }

    return const Icon(
      Icons.album,
      size: 40,
    );
  }

  ListView listViewVCs(List<VC> vcList) {
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
                    leading: displayVCIcon(vcList[index].type),
                    title: Text(vcList[index].type.join(", ").toString()),
                    subtitle: Text('Issuer: ${vcList[index].issuer}'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: const Text('View details'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/vcdetails',
                                  arguments: vcList[index])
                              .then((T) {
                            setState(() {
                              vcs = [];
                            });
                            refresh();
                          });
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
