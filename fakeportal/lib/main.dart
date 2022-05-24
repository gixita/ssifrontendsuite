import 'package:flutter/material.dart';
import 'package:ssifrontendsuite/workflow.dart';
import 'package:ssifrontendsuite/did_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fake portal for SSI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Fake portal to test SSI in NEO'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Did? holder;

  @override
  initState() {
    super.initState();
    holder = Workflow().retreiveStaticDidForMA();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'super',
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(holder?.id ?? 'Did not set'),
          ],
        ),
      ),
    );
  }
}
