import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:args/args.dart';
// import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:ssifrontendsuite/did_http.dart';
import 'package:ssifrontendsuite/did_model.dart';

import 'api.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = 'localhost';

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8081';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }
  http.Client client = http.Client();
  Did authorityPortalDid = await DIDHttpService().getNewDid(client);

  var server = await io.serve(Api(authorityPortalDid).handler, _hostname, port);
  // ignore: avoid_print
  print('Serving at http://${server.address.host}:${server.port}');
}

// shelf.Response _echoRequest(shelf.Request request) =>
//     shelf.Response.ok('Request for "${request.url}"');
