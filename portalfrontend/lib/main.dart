import 'package:flutter/material.dart';
import 'login.dart';
import 'vcdetailspage.dart';
import 'vcissuedtome.dart';
import 'outofbandinvitation.dart';
import 'selectvctoissue.dart';
import 'issueidentitypage.dart';
import 'electricvehiculeissuepage.dart';

// https://realto.readme.io/docs/entities-and-energy-devices
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Portal SSI',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(title: "Login"),
          '/register': (context) => const LoginPage(title: "Register"),
          '/vcdetails': (context) => const VCDetailsPage(title: "View details"),
          '/issueidentity': (context) =>
              const IssueIdentityPage(title: "Issue an identity document"),
          '/electricvehicule': (context) => const ElectricVehiculeIssuePage(
              title: "Issue an electric vehicule document"),
          '/selectvctype': (context) =>
              const SelectVCToIssuePage(title: "Select VC type to issue"),
          '/qrcode': (context) =>
              const OutOfBandInvitationPage(title: "Scan the QR Code"),
          '/vcissued': (context) =>
              const VCIssuedToMePage(title: "Documents issued by "),
        });
  }
}
