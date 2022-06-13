import 'dart:convert';

import 'package:portalserver/unsignedvcs/unsignedvcs_service.dart';

import 'package:ssifrontendsuite/unsignedvcs.dart';
import 'package:portalserver/common/errors/dtos/error_dto.dart';
import 'package:portalserver/common/exceptions/already_exists_exception.dart';
import 'package:portalserver/common/exceptions/argument_exception.dart';
import 'package:portalserver/users/users_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../common/middleware/auth.dart';
import '../users/model/user.dart';

class UnsignedVCSRouter {
  final UnsignedVCSService unsignedVCSService;
  final UsersService usersService;
  final AuthProvider authProvider;

  UnsignedVCSRouter(
      {required this.unsignedVCSService,
      required this.usersService,
      required this.authProvider});

  Future<Response> _createUnsignedVCS(Request request) async {
    final user = request.context['user'] as User;

    final requestBody = await request.readAsString();

    final requestData = json.decode(requestBody);

    final unsignedVCSData = requestData['unsignedvcs'];

    if (unsignedVCSData == null) {
      return Response(422,
          body: jsonEncode(ErrorDto(errors: ['unsignedVCSData is required'])));
    }

    final email = unsignedVCSData['email'].toString();
    final unsignedvcs = json.encode(unsignedVCSData['unsignedvcs']);

    if (email == "") {
      return Response(422,
          body: jsonEncode(ErrorDto(errors: ['email is required'])));
    }

    if (unsignedvcs == "") {
      return Response(422,
          body: jsonEncode(ErrorDto(errors: ['unsignedvcs is required'])));
    }

    UnsignedVCS unsignedVCS;

    try {
      unsignedVCS = await unsignedVCSService.createUnsignedVCS(
          email: email, unsignedvcs: unsignedvcs, user: user);
    } on ArgumentException catch (e) {
      return Response(422, body: jsonEncode(ErrorDto(errors: [e.message])));
    } on AlreadyExistsException catch (e) {
      return Response(409, body: jsonEncode(ErrorDto(errors: [e.message])));
    }
    String jsonBody = json.encode(unsignedVCS.toJson());
    return Response(201, body: jsonBody);
  }

  // Retrieve the list of self issued VCS for the installer
  Future<Response> _listUnsignedVCS(Request request) async {
    User? user;
    if (request.context['user'] != null) {
      user = request.context['user'] as User;
    }
    List<UnsignedVCS> unsignedVCSList = [];
    if (user != null) {
      unsignedVCSList =
          await unsignedVCSService.listUnsignedVCS(user: user, by: "me");
      var jsonList = [];
      for (var element in unsignedVCSList) {
        jsonList.add(element.toJson());
      }
      return Response.ok(jsonEncode(jsonList));
    } else {
      return Response.ok("Error while retrieving VCs");
    }
  }

  // Retrieve the list of self issued VCS for the installer
  Future<Response> _listUnsignedVCSIssuedToMe(Request request) async {
    User? user;
    if (request.context['user'] != null) {
      user = request.context['user'] as User;
    }
    List<UnsignedVCS> unsignedVCSList = [];
    if (user != null) {
      unsignedVCSList =
          await unsignedVCSService.listUnsignedVCS(user: user, by: "others");
      var jsonList = [];
      for (var element in unsignedVCSList) {
        jsonList.add(element.toJson());
      }
      return Response.ok(jsonEncode(jsonList));
    } else {
      return Response.ok("Error while retrieving VCs");
    }
  }

  // Retrieve the list of self issued VCS for the installer
  Future<Response> _deleteUnsignedVCS(Request request) async {
    final requestBody = await request.readAsString();

    final requestData = json.decode(requestBody);

    final unsignedVCSId = requestData['id'];
    var deleted = await unsignedVCSService.deleteUnsignedVCS(
        id: int.parse(unsignedVCSId));

    return Response.ok(jsonEncode(deleted));
  }

  // Future<Response> _updateArticle(Request request) async {
  //   final user = request.context['user'] as User;
  //   return Response.ok(jsonEncode(articleDto));
  // }

  // Future<Response> _deleteArticle(Request request) async {
  //   final user = request.context['user'] as User;
  //   final slug = request.params['slug'];
  //   return Response(204);
  // }

  Handler get router {
    final router = Router();

    router.post(
        '/unsignedvcs',
        Pipeline()
            .addMiddleware(authProvider.requireAuth())
            .addHandler(_createUnsignedVCS));

    router.delete(
        '/unsignedvcs',
        Pipeline()
            .addMiddleware(authProvider.requireAuth())
            .addHandler(_deleteUnsignedVCS));

    router.get(
        '/unsignedvcs',
        Pipeline()
            .addMiddleware(authProvider.requireAuth())
            .addHandler(_listUnsignedVCS));

    router.get(
        '/unsignedvcsissuedtome',
        Pipeline()
            .addMiddleware(authProvider.requireAuth())
            .addHandler(_listUnsignedVCSIssuedToMe));

    // router.put(
    //     '/articles/<slug>',
    //     Pipeline()
    //         .addMiddleware(authProvider.requireAuth())
    //         .addHandler(_updateArticle));

    // router.delete(
    //     '/articles/<slug>',
    //     Pipeline()
    //         .addMiddleware(authProvider.requireAuth())
    //         .addHandler(_deleteArticle));
    return router;
  }
}
