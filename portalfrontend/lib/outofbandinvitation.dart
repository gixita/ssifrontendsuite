import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OutOfBandInvitationPage extends StatefulWidget {
  const OutOfBandInvitationPage({Key? key, required this.title})
      : super(key: key);
  final String title;

  @override
  State<OutOfBandInvitationPage> createState() =>
      _OutOfBandInvitationPageState();
}

class _OutOfBandInvitationPageState extends State<OutOfBandInvitationPage> {
  String errorMessage = "";
  String qrCode = "";

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
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(
          children: [
            CustomPaint(
              size: const Size.square(280),
              painter: QrPainter(
                data: outOfBandInvitation,
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xff128760),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Color(0xff1a5441),
                ),
                // size: 320.0,
              ),
            )
          ],
        ),
      ),
    );
  }
}
