import 'package:flutter/material.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'package:ssifrontendsuite/workflow_manager.dart';
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
  var vcs;
  String outOfBandIssuanceInvitation = "";
  String outOfBandPresentationInvitation = "";

  Future<bool> storeInDb() async {
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
    vcs = null;
    // SQLHelper.db(); // Loading the diary when the app starts
    storeInDb();
    refresh();
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
        children: [
          if (vcs != null)
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [listViewVCs(vcs)])
          else
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [CircularProgressIndicator()])
        ],
      )),
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
              Navigator.pushNamed(context, '/ssiworkflow',
                      arguments: outOfBandIssuanceInvitation)
                  .then((T) {
                setState(() {
                  vcs = null;
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
                    leading: const Icon(Icons.album),
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
                              arguments: vcList[index]);
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