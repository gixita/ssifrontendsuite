import 'package:flutter/material.dart';
import 'package:mobilewallet/ssi.dart';
import 'package:ssifrontendsuite/did.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'package:ssifrontendsuite/did_model.dart';
import 'package:ssifrontendsuite/workflow_manager.dart';
import 'package:overlay_support/overlay_support.dart';

// usage of flutter builder described in this tutorial
// https://www.woolha.com/tutorials/flutter-using-futurebuilder-widget-examples

class ReceiveVCPage extends StatefulWidget {
  const ReceiveVCPage({Key? key}) : super(key: key);

  @override
  State<ReceiveVCPage> createState() => _ReceiveVCPageState();
}

class _ReceiveVCPageState extends State<ReceiveVCPage> {
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final params =
        ModalRoute.of(context)!.settings.arguments as List<List<String>>;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              Navigator.popUntil(context, ModalRoute.withName('/')),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text("Receive VC for issuer"),
      ),
      body: selectItemWidget(params),
    );
  }

  Future<String> receiveVC(List<List<String>> params) async {
    WorkflowManager wfm = WorkflowManager();
    VCService vcService = VCService();
    String serviceEndpoint = params[1][0];
    Did holder = await DIDService().getDid();
    try {
      await wfm.authorityPortalIssueVC(serviceEndpoint, holder);
    } catch (e) {
      throw "Unable for the portal to send signed data -- Error : $e";
    }
    try {
      VC receivedVC = await wfm.retreiveSignedVCFromAuthority(params, holder);
      await vcService.storeVC(receivedVC);
      return receivedVC.rawVC;
    } catch (e) {
      throw "Unable to receive issued VC -- Error : $e";
    }
  }

  FutureBuilder<String> selectItemWidget(List<List<String>> params) {
    return FutureBuilder<String>(
      // This will trigger the retreive the vc from db each time a user is ticking a selection
      // TODO only call the db once
      future: receiveVC(params),
      builder: (
        BuildContext context,
        AsyncSnapshot<String> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Text('Error');
          } else if (snapshot.hasData) {
            if (snapshot.data != null) {
              // showSimpleNotification(
              //   const Text("An error occured, please try again"),
              //   background: Colors.red,
              // );
              //ignore: use_build_context_synchronously
              return ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  },
                  child: const Text("continue"));
            }
            return const Text("No vc to display");
            // return generateCards(snapshot.data);
          } else {
            return const Text('Empty data');
          }
        } else {
          return Text('State: ${snapshot.connectionState}');
        }
      },
    );
  }
}
