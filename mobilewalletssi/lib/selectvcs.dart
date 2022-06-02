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

class SelectVCsPage extends StatefulWidget {
  const SelectVCsPage({Key? key}) : super(key: key);

  @override
  State<SelectVCsPage> createState() => _SelectVCsPageState();
}

class _SelectVCsPageState extends State<SelectVCsPage> {
  String errorMessage = "";
  List<VC> selectVcs = [];
  List<int> selectedList = [];

  @override
  void initState() {
    super.initState();
    selectedList = [];
  }

  void selectItem(int index) {
    setState(() {
      if (!selectedList.contains(index)) {
        selectedList.add(index);
      } else {
        selectedList.remove(index);
      }
    });
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
        title: const Text("Select documents to send"),
      ),
      body: selectItemWidget(params),
    );
  }

  Future<List<VC>> getCompatibleVCs(List<List<String>> params) async {
    return await WorkflowManager().selectVCs(params);
  }

  FutureBuilder<List<VC>> selectItemWidget(List<List<String>> params) {
    return FutureBuilder<List<VC>>(
      // This will trigger the retreive the vc from db each time a user is ticking a selection
      // TODO only call the db once
      future: getCompatibleVCs(params),
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
              return Column(
                children: [
                  Expanded(
                      child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: snapshot.data!.length,
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
                                    title: Text(snapshot.data![index].type
                                        .join(", ")
                                        .toString()),
                                    subtitle: Text(
                                        'Issuer: ${snapshot.data![index].issuer}'),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                ],
                              ),
                            );
                          })),
                  selectedList.isNotEmpty
                      ? ElevatedButton(
                          child: const Text("Sign and send"),
                          onPressed: () async {
                            List<VC> sendVCList = [];
                            for (var i in selectedList) {
                              sendVCList.add(snapshot.data![i]);
                            }
                            Did holder = await DIDService().getDid();
                            bool result = await WorkflowManager()
                                .sendVCs(params, holder, sendVCList);
                            if (result) {
                              showSimpleNotification(
                                const Text("Your documents are send"),
                                background: Colors.green,
                              );
                              // ignore: use_build_context_synchronously
                              // Navigator.popUntil(
                              //     context, ModalRoute.withName('/'));
                            } else {
                              showSimpleNotification(
                                const Text(
                                    "An error occured, please try again"),
                                background: Colors.red,
                              );
                              //ignore: use_build_context_synchronously
                              Navigator.popUntil(
                                  context, ModalRoute.withName('/'));
                            }
                            // Send list to server
                            //redirect to home screen
                            // make notification if it worked
                          },
                        )
                      : const ElevatedButton(
                          onPressed: null, child: Text("Sign and send"))
                ],
              );
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
