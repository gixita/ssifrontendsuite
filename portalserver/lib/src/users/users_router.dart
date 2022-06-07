import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UsersRouter {
  Response _registerUser() {
    return Response.ok("");
  }

  Response _loginUser() {
    return Response.ok("");
  }

  Handler get router {
    final router = Router();

    router.post('/users', _registerUser);

    router.post('/users/login', _loginUser);

    // router.get(
    //     '/user',
    //     Pipeline()
    //         .addMiddleware(authorize(usersService, jwtService))
    //         .addHandler(_getCurrentUserHandler));

    // router.put(
    //     '/user',
    //     Pipeline()
    //         .addMiddleware(authorize(usersService, jwtService))
    //         .addHandler(_updateUserHandler));

    return router;
  }
}
