import 'package:portalserver/unsignedvcs/unsignedvcs_router.dart';
import 'package:portalserver/common/middleware/json_content_type_response.dart';
import 'package:portalserver/users/users_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiRouter {
  final UsersRouter usersRouter;
  final UnsignedVCSRouter unsignedVCSRouter;

  ApiRouter({required this.usersRouter, required this.unsignedVCSRouter});

  Handler get router {
    final router = Router();
    final prefix = '/api';

    router.mount(prefix, usersRouter.router);
    router.mount(prefix, unsignedVCSRouter.router);

    return Pipeline()
        .addMiddleware(corsHeaders())
        .addMiddleware(jsonContentTypeResponse())
        .addHandler(router);
  }
}
