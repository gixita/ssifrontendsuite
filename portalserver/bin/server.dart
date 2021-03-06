import 'dart:async';
import 'dart:io';
//https://github.com/marcusmonteirodesouza/dart-shelf-realworld-example-app/blob/master/bin/server.dart
import 'package:portalserver/api_router.dart';
import 'package:portalserver/unsignedvcs/unsignedvcs_router.dart';
import 'package:portalserver/unsignedvcs/unsignedvcs_service.dart';
import 'package:portalserver/ssiworkflow/ssiworkflow_service.dart';
import 'package:portalserver/ssiworkflow/ssiworkflow_router.dart';
import 'package:portalserver/common/middleware/auth.dart';

import 'package:portalserver/users/jwt_service.dart';
import 'package:portalserver/users/users_router.dart';
import 'package:portalserver/users/users_service.dart';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:sqlite_wrapper/sqlite_wrapper.dart';
import 'package:ssifrontendsuite/sql_helper.dart';

Future main(List<String> args) async {
  var environment = Platform.environment['ENVIRONMENT'] ?? 'local';

  environment = environment.trim().toLowerCase();

  if (environment == 'local') {
    load();
  }

  final authSecretKey = env['AUTH_SECRET_KEY'];
  final authIssuer = env['AUTH_ISSUER'];

  if (authSecretKey == null) {
    throw StateError('Environment variable AUTH_SECRET_KEY is required');
  }

  if (authIssuer == null) {
    throw StateError('Environment variable AUTH_ISSUER is required');
  }

  SQLiteWrapper db = await SQLHelper.db();

  final usersService = UsersService(db: db);
  final jwtService = JwtService(issuer: authIssuer, secretKey: authSecretKey);
  final unsignedVCSService =
      UnsignedVCSService(db: db, usersService: usersService);
  final ssiWorkflowService = SSIWorkflowService(db: db);

  final authProvider =
      AuthProvider(usersService: usersService, jwtService: jwtService);

  final usersRouter = UsersRouter(
      usersService: usersService,
      jwtService: jwtService,
      authProvider: authProvider);

  final unsignedVCSRouter = UnsignedVCSRouter(
      unsignedVCSService: unsignedVCSService,
      usersService: usersService,
      authProvider: authProvider);

  final ssiWorkflowRouter = SSIWorkflowRouter(
      unsignedVCSService: unsignedVCSService,
      usersService: usersService,
      authProvider: authProvider,
      ssiWorkflowService: ssiWorkflowService);

  final apiRouter = ApiRouter(
          usersRouter: usersRouter,
          unsignedVCSRouter: unsignedVCSRouter,
          ssiWorkflowRouter: ssiWorkflowRouter)
      .router;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(apiRouter);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final server = await serve(handler, InternetAddress.anyIPv4, port);

  print('Server listening at http://${server.address.host}:${server.port}');

  await terminateRequestFuture();

  // await db.close();

  await server.close();
}

/// Returns a [Future] that completes when the process receives a
/// [ProcessSignal] requesting a shutdown.
///
/// [ProcessSignal.sigint] is listened to on all platforms.
///
/// [ProcessSignal.sigterm] is listened to on all platforms except Windows.
Future<void> terminateRequestFuture() {
  final completer = Completer<bool>.sync();

  // sigIntSub is copied below to avoid a race condition - ignoring this lint
  // ignore: cancel_subscriptions
  StreamSubscription? sigIntSub, sigTermSub;

  Future<void> signalHandler(ProcessSignal signal) async {
    print('Received signal $signal - closing');

    final subCopy = sigIntSub;
    if (subCopy != null) {
      sigIntSub = null;
      await subCopy.cancel();
      sigIntSub = null;
      if (sigTermSub != null) {
        await sigTermSub!.cancel();
        sigTermSub = null;
      }
      completer.complete(true);
    }
  }

  sigIntSub = ProcessSignal.sigint.watch().listen(signalHandler);

  // SIGTERM is not supported on Windows. Attempting to register a SIGTERM
  // handler raises an exception.
  if (!Platform.isWindows) {
    sigTermSub = ProcessSignal.sigterm.watch().listen(signalHandler);
  }

  return completer.future;
}
