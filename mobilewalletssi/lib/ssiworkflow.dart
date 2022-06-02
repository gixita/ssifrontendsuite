import 'package:flutter/material.dart';
import 'package:mobilewallet/ssi.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'package:ssifrontendsuite/did.dart';
import 'package:ssifrontendsuite/did_model.dart';
import 'package:ssifrontendsuite/workflow_manager.dart';
import 'package:overlay_support/overlay_support.dart';

// usage of flutter builder described in this tutorial
// https://www.woolha.com/tutorials/flutter-using-futurebuilder-widget-examples

class SSIWorkflowPage extends StatefulWidget {
  const SSIWorkflowPage({Key? key}) : super(key: key);

  @override
  State<SSIWorkflowPage> createState() => _SSIWorkflowPageState();
}

class _SSIWorkflowPageState extends State<SSIWorkflowPage> {
  String errorMessage = "";
  String outOfBandInvitation = "";
  bool validateStartOfCommunication = false;
  bool present = false;
  List<VC> selectVcs = [];
  List<int> selectedList = [];
  List<List<String>> paramsState = [[]];
  List<VC> sendVCList = [];

  @override
  void initState() {
    super.initState();
    validateStartOfCommunication = false;
  }

  void selectItem(int index) {
    setState(() {
      if (!selectedList.contains(index)) {
        selectedList.add(index);
      } else {
        selectedList.remove(index);
      }
      sendVCList = [];
      for (var i in selectedList) {
        sendVCList.add(selectVcs[i]);
      }
    });
  }

  Future<List<VC>> getCompatibleVCs(List<List<String>> params) async {
    return await WorkflowManager().selectVCs(params);
  }

  Future<void> ssiWorkflowMethod() async {
    WorkflowManager wfm = WorkflowManager();
    VCService vcService = VCService();
    try {
      Did holder = await ensureDIDExists();
      List<List<String>> params = await getParams(outOfBandInvitation, holder);
      List<String> currentWorkflow = params[0];
      String serviceEndpoint = params[1][0];
      if (currentWorkflow.contains("present")) {
        var local = await getCompatibleVCs(params);
        setState(() {
          selectVcs = local;
          present = true;
          paramsState = params;
        });
      } else if (currentWorkflow.contains("issue")) {
        await wfm.authorityPortalIssueVC(serviceEndpoint, holder);
        VC receivedVC = await wfm.retreiveSignedVCFromAuthority(params, holder);
        await vcService.storeVC(receivedVC).then((vc) {
          showSimpleNotification(
            const Text("You received a new vc"),
            background: Colors.green,
          );
          Navigator.of(context).pop();
        });
      } else {
        throw "This workflow type is not supported yet";
      }
      setState(() {});
    } catch (error) {
      setState(() {
        errorMessage = "$error";
      });
    }
  }

  Widget requestStartValidation() {
    return Column(
      children: [
        const Text(
            "You are starting a document exchange, you will disclose your identity to the host. Do you want to proceed?"),
        ElevatedButton(
            onPressed: () {
              outOfBandInvitation =
                  ModalRoute.of(context)!.settings.arguments as String;
              ssiWorkflowMethod();
              setState(() {
                validateStartOfCommunication = true;
              });
            },
            child: const Text("proceed"))
      ],
    );
  }

  Widget continueSSIWorkflow() {
    if (present == false) {
      return const CircularProgressIndicator();
    } else {
      return generateVCListForSelection(selectVcs, paramsState, context);
    }
  }

  Widget signAndSendButton() {
    if (present) {
      if (selectedList.isNotEmpty) {
        return ElevatedButton(
          child: const Text("Sign and send"),
          onPressed: () async {
            Did holder = await DIDService().getDid();
            await WorkflowManager()
                .sendVCs(paramsState, holder, sendVCList)
                .then((result) {
              if (result) {
                showSimpleNotification(
                  const Text("Your documents are send"),
                  background: Colors.green,
                );
                Navigator.of(context).pop();
              } else {
                showSimpleNotification(
                  const Text("An error occured, please try again"),
                  background: Colors.red,
                );
                Navigator.of(context).pop();
              }
            });
          },
        );
      } else {
        return const ElevatedButton(
            onPressed: null, child: Text("Sign and send"));
      }
    }
    return const SizedBox(
      width: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (!validateStartOfCommunication)
          requestStartValidation()
        else
          continueSSIWorkflow(),
        signAndSendButton(),
      ])),
    );
  }

  Future<List<List<String>>> getParams(
      String outOfBandInvitation, Did holder) async {
    return await WorkflowManager()
        .startExchangeSSI(outOfBandInvitation, holder);
  }

  Widget generateVCListForSelection(
      List<VC> listVC, List<List<String>> params, BuildContext context) {
    return Expanded(
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: listVC.length,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: selectedList.contains(index)
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                            )
                          : const Icon(
                              Icons.circle_outlined,
                              color: Colors.grey,
                            ),
                      onTap: () {
                        selectItem(index);
                      },
                      title: Text(listVC[index].type.join(", ").toString()),
                      subtitle: Text('Issuer: ${listVC[index].issuer}'),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                  ],
                ),
              );
            }));
  }

  // FutureBuilder<List<List<String>>> startSSIWorkflow(
  //     String outOfBandInvitation) {
  //   return FutureBuilder<List<List<String>>>(
  //     future: getParams(outOfBandInvitation),
  //     builder: (
  //       BuildContext context,
  //       AsyncSnapshot<List<List<String>>> snapshot,
  //     ) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const CircularProgressIndicator();
  //       } else if (snapshot.connectionState == ConnectionState.done) {
  //         if (snapshot.hasError) {
  //           return const Text('Error');
  //         } else if (snapshot.hasData) {
  //           if (snapshot.data != null) {
  //             List<String> currentWorkflow = snapshot.data![0];
  //             if (currentWorkflow.contains("present")) {
  //               return ElevatedButton(
  //                   onPressed: () {
  //                     Navigator.pushNamed(context, '/selectvcs',
  //                         arguments: snapshot.data);
  //                   },
  //                   child: const Text("continue"));
  //             } else {
  //               return ElevatedButton(
  //                   onPressed: () {
  //                     Navigator.pushNamed(context, '/receivevc',
  //                         arguments: snapshot.data);
  //                   },
  //                   child: const Text("continue"));
  //               // Future.delayed(Duration(seconds: 1), () {
  //               //   Navigator.pushNamed(context, '/receiveVC');
  //               // });
  //               // return const Text("");
  //             }
  //           }
  //           return const Text("No vc to display");
  //           // return generateCards(snapshot.data);
  //         } else {
  //           return const Text('Empty data');
  //         }
  //       } else {
  //         return Text('State: ${snapshot.connectionState}');
  //       }
  //     },
  //   );
  // }
}
