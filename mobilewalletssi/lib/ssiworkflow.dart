import 'package:flutter/material.dart';
import 'package:ssifrontendsuite/vc.dart';
import 'package:ssifrontendsuite/vc_model.dart';
import 'data/dummy_vc.dart';

// usage of flutter builder described in this tutorial
// https://www.woolha.com/tutorials/flutter-using-futurebuilder-widget-examples

class SSIWorkflowPage extends StatefulWidget {
  const SSIWorkflowPage({Key? key}) : super(key: key);

  @override
  State<SSIWorkflowPage> createState() => _SSIWorkflowPageState();
}

class _SSIWorkflowPageState extends State<SSIWorkflowPage> {
  String errorMessage = "";
  List<VC> selectVcs = [];
  List<int> selectedList = [];

  Future<List<VC>> getVCs() async {
    List<VC> localSelectVcs = await VCService().getAllVCs();
    setState(() {
      selectVcs = localSelectVcs;
    });
    return selectVcs;
  }

  Future<bool> storeInDb() async {
    await storeDummyVCS();
    List<VC> localSelectVcs = await VCService().getAllVCs();
    setState(() {
      selectVcs = localSelectVcs;
    });
    return true;
  }

  @override
  void initState() {
    super.initState();
    selectedList = [];
    getVCs();
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
      body: selectItemWidget(),
    );
  }

  FutureBuilder<List<VC>> selectItemWidget() {
    return FutureBuilder<List<VC>>(
      future: Future<List<VC>>.value(selectVcs),
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
                          onPressed: () {
                            List<VC> sendVCList = [];
                            for (var i in selectedList) {
                              sendVCList.add(snapshot.data![i]);
                            }
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
