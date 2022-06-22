import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'vcpage.dart';
import 'qrviewexample.dart';
import 'ssiworkflow.dart';
import 'vcdetailspage.dart';
import 'defineissuerlabel.dart';
import 'diddetailspage.dart';

class MobileWalletSSIElia extends StatelessWidget {
  const MobileWalletSSIElia({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
        child: MaterialApp(
      title: 'SSI Wallet Elia Group',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const VCPage(title: 'SSI Wallet Elia Group'),
        '/qrcode': (context) => const QRViewExample(),
        '/ssiworkflow': (context) => const SSIWorkflowPage(),
        '/didlabel': (context) => const DefineIssuerLabelPage(),
        '/vcdetails': (context) =>
            const VCDetailsPage(title: 'Documents details'),
        '/diddetails': (context) =>
            const DidDetailsPage(title: 'My DID details'),
      },
    ));
  }
}
