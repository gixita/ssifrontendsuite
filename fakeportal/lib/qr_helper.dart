import 'package:qr/qr.dart';

class QRtoSVG {
  static String generateSVG(QrCode code, QrImage image) {
    final int unit = code.moduleCount;
    final int canvasSize = unit * 10;
    final int pixelSize = 5;
    String qrRects = '';
    for (var x = 0; x < image.moduleCount; x++) {
      for (var y = 0; y < image.moduleCount; y++) {
        if (image.isDark(y, x)) {
          String posX = (x * pixelSize).toString();
          String posY = (y * pixelSize).toString();
          qrRects +=
              '<rect x="$posX" y="$posY" width="$pixelSize" height="$pixelSize" style="fill:black;fill-opacity:1" />';
        }
      }
    }
    return """<svg width="$canvasSize" height="$canvasSize">
  $qrRects
</svg>""";
  }
}
