import 'package:flutter/material.dart';
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

  // common logic for exchange
  Future<List<List<String>>> getParams(
      String outOfBandInvitation, Did holder) async {
    return await WorkflowManager()
        .startExchangeSSI(outOfBandInvitation, holder);
  }

  Widget requestStartValidation() {
    return Column(
      children: [
        Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              "You are starting a document exchange, you will disclose your identity to the host. Do you want to proceed?",
              textAlign: TextAlign.center,
            )),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
            onPressed: () {
              outOfBandInvitation =
                  ModalRoute.of(context)!.settings.arguments as String;
              ssiWorkflowMethod();
              setState(() {
                validateStartOfCommunication = true;
              });
            },
            child: const Text("Proceed"))
      ],
    );
  }

  Future<void> ssiWorkflowMethod() async {
    WorkflowManager wfm = WorkflowManager();
    VCService vcService = VCService();
    // try {
    List<dynamic> res = await DIDService().ensureDIDExists(didId: 0);
    Did holder = res[0];
    List<List<String>> params = await getParams(outOfBandInvitation, holder);
    List<String> currentWorkflow = params[0];
    // String serviceEndpoint = params[1][0];
    if (currentWorkflow.contains("present")) {
      var local = await getCompatibleVCs(params);
      setState(() {
        selectVcs = local;
        present = true;
        paramsState = params;
      });
    } else if (currentWorkflow.contains("issue")) {
      // await wfm.authorityPortalIssueVC(serviceEndpoint, holder.id);
      VC receivedVC = await wfm.retreiveSignedVCFromAuthority(params, holder);
      await vcService.storeVC(receivedVC).then((vc) async {
        showSimpleNotification(
          const Text("You received a new vc"),
          background: Colors.green,
        );
        await VCService().getIssuerLabel(vc.issuer).then((label) {
          if (label.isNotEmpty) {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          } else {
            Navigator.pushNamed(context, '/didlabel', arguments: vc.issuer);
          }
        });
      });
    } else {
      throw "This workflow type is not supported yet";
    }
    setState(() {});
    // } catch (error) {
    //   setState(() {
    //     errorMessage = "$error";
    //   });
    // }
  }

  // logic for presentation
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

  Widget signAndSendButton() {
    if (present) {
      if (selectedList.isNotEmpty) {
        return ElevatedButton(
          child: const Text("Sign and send"),
          onPressed: () async {
            Did holder = (await DIDService().ensureDIDExists(didId: 0))[0];
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
  // logic for issuance

  Widget continueSSIWorkflow() {
    if (present == false) {
      return const CircularProgressIndicator();
    } else {
      return generateVCListForSelection(selectVcs, paramsState, context);
    }
  }

  String appBarTitle() {
    if (paramsState.isNotEmpty) {
      List<String> currentWorkflow = paramsState[0];
      if (currentWorkflow.contains("present")) {
        return "Present documents";
      } else if (currentWorkflow.contains("issue")) {
        return "Receive new documents";
      }
    }
    return "Start document exchange";
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
        title: Text(appBarTitle()),
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
}
