import 'package:flutter/material.dart';
import 'package:mobilewallet/ssi.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'package:ssifrontendsuite/did.dart';
import 'package:ssifrontendsuite/did_model.dart';
import 'package:ssifrontendsuite/workflow_manager.dart';

// usage of flutter builder described in this tutorial
// https://www.woolha.com/tutorials/flutter-using-futurebuilder-widget-examples

class SSIWorkflowPage extends StatefulWidget {
  const SSIWorkflowPage({Key? key}) : super(key: key);

  @override
  State<SSIWorkflowPage> createState() => _SSIWorkflowPageState();
}

class _SSIWorkflowPageState extends State<SSIWorkflowPage> {
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final outOfBandInvitation =
        ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              Navigator.popUntil(context, ModalRoute.withName('/')),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text("Select documents to send"),
      ),
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[startSSIWorkflow(outOfBandInvitation)])),
    );
  }

  Future<List<List<String>>> getParams(String outOfBandInvitation) async {
    Did holder = await ensureDIDExists();
    return await WorkflowManager()
        .startExchangeSSI(outOfBandInvitation, holder);
  }

  FutureBuilder<List<List<String>>> startSSIWorkflow(
      String outOfBandInvitation) {
    return FutureBuilder<List<List<String>>>(
      future: getParams(outOfBandInvitation),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<List<String>>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Text('Error');
          } else if (snapshot.hasData) {
            if (snapshot.data != null) {
              List<String> currentWorkflow = snapshot.data![0];
              if (currentWorkflow.contains("present")) {
                return ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/selectvcs',
                          arguments: snapshot.data);
                    },
                    child: const Text("continue"));
              } else {
                return ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/receivevc',
                          arguments: snapshot.data);
                    },
                    child: const Text("continue"));
                // Future.delayed(Duration(seconds: 1), () {
                //   Navigator.pushNamed(context, '/receiveVC');
                // });
                // return const Text("");
              }
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
