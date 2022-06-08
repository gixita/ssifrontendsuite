import 'dart:convert';

import 'package:portalserver/ssiworflow/ssiworkflow_service.dart';
import 'package:portalserver/users/users_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:ssifrontendsuite/workflow.dart';
import 'package:ssifrontendsuite/workflow_manager.dart';
import 'package:portalserver/common/exceptions/not_found_exception.dart';
import 'package:portalserver/common/exceptions/unauthorized_exception.dart';

import '../common/middleware/auth.dart';
import '../unsignedvcs/model/unsignedvcs.dart';
import '../unsignedvcs/unsignedvcs_service.dart';
import '../users/model/user.dart';

class SSIWorkflowRouter {
  final UsersService usersService;
  final UnsignedVCSService unsignedVCSService;
  final SSIWorkflowService ssiWorkflowService;
  final AuthProvider authProvider;
  SSIWorkflowRouter(
      {required this.usersService,
      required this.authProvider,
      required this.ssiWorkflowService,
      required this.unsignedVCSService});

  Future<Response> _getOutOfBandIssuanceInvitation(Request request) async {
    Workflow wf = Workflow();
    WorkflowManager wfm = WorkflowManager();
    String uuidEchangeId = wf.generateRandomEchangeId();
    final user = request.context['user'] as User;
    final requestBody = await request.readAsString();
    final requestData = json.decode(requestBody);
    final int vcId = int.parse(requestData['id']);
    UnsignedVCS? unsignedVC = await unsignedVCSService.getUnsignedVCSById(vcId);
    if (unsignedVC != null) {
      if (user.id == unsignedVC.userid || user.email == unsignedVC.email) {
        await ssiWorkflowService.createExchangeId(
            vcId: vcId, exchangeId: uuidEchangeId);
        String outOfBandInvitation =
            await wfm.getOutOfBandIssuanceInvitation(exchangeId: uuidEchangeId);
        return Response.ok(outOfBandInvitation);
      } else {
        throw UnauthorizedException();
      }
    } else {
      throw NotFoundException(message: 'Unsigned VC not found');
    }
  }

  // Currently only support simple issuance, need to implement conditionnal issuance
  Future<Response> _issueVC(Request request) async {
    // TODO
    return Response.ok("Ok");
  }

  Handler get router {
    final router = Router();

    router.post(
        '/startissuance',
        Pipeline()
            .addMiddleware(authProvider.requireAuth())
            .addHandler(_getOutOfBandIssuanceInvitation));

    router.post(
        '/issuevc',
        Pipeline()
            .addMiddleware(authProvider.requireAuth())
            .addHandler(_issueVC));

    return router;
  }
}
