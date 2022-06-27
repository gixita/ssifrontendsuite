import 'dart:convert';

import 'package:portalserver/ssiworkflow/ssiworkflow_service.dart';
import 'package:portalserver/users/users_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:ssifrontendsuite/workflow.dart';
import 'package:ssifrontendsuite/did_model.dart';
import 'package:ssifrontendsuite/did.dart';
import 'package:ssifrontendsuite/workflow_manager.dart';
import 'package:ssifrontendsuite/unsignedvcs.dart';

import 'package:portalserver/common/exceptions/not_found_exception.dart';
import 'package:portalserver/common/exceptions/unauthorized_exception.dart';

import '../common/middleware/auth.dart';
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
    print(requestBody);
    final requestData = json.decode(requestBody);
    if (requestData['id'] == null) {
      throw "You must provide the id of a vc";
    }
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

  Future<Response> _getOutOfBandPresentationInvitation(Request request) async {
    WorkflowManager wfm = WorkflowManager();

    final requestBody = await request.readAsString();
    print(requestBody);
    final requestData = json.decode(requestBody);
    if (requestData['types'] == null) {
      throw "You must provide the type of vc to present";
    }
    return Response.ok(await wfm.getOutOfBandPresentationInvitation(
        (requestData['types'] as List<dynamic>).cast<String>()));
  }

  // Currently only support simple issuance, need to implement conditionnal issuance
  Future<Response> _issueVC(Request request) async {
    WorkflowManager wfm = WorkflowManager();

    final requestBody = await request.readAsString();
    final requestData = json.decode(requestBody);

    // params should never be null otherwise the framework would return a Route not found
    int vcId = await ssiWorkflowService.getUnsignedVCIdByExchangeId(
        exchangeId: request.params['exchangeid']!);
    UnsignedVCS? unsignedVC = await unsignedVCSService.getUnsignedVCSById(vcId);
    // UnsignedVCS? unsignedVC = await unsignedVCSService.getUnsignedVCSById(1);
    if (unsignedVC != null) {
      String serviceEndpoint =
          requestData['vpRequest']['interact']['service'][0]['serviceEndpoint'];
      String holder = requestData['presentationSubmission']['vp']['holder'];
      print(unsignedVC.unsignedvcs);
      User? issuerUser = await usersService.getUserById(unsignedVC.userid);
      Did issuerDid;
      if (issuerUser != null) {
        issuerDid =
            (await DIDService().ensureDIDExists(didId: issuerUser.didId))[0];
      } else {
        throw "The issuer should never be null";
      }
      await wfm.authorityPortalIssueVC(
          serviceEndpoint, holder, unsignedVC.unsignedvcs, issuerDid);
      return Response.ok("");
    }
    return Response.notFound({"error": "Unsigned vc not found"});
  }

  Handler get router {
    final router = Router();

    router.post(
        '/startissuance',
        Pipeline()
            .addMiddleware(authProvider.requireAuth())
            .addHandler(_getOutOfBandIssuanceInvitation));

    router.post(
        '/issuevc/<exchangeid>',
        Pipeline()
            // .addMiddleware(authProvider.requireAuth())
            .addHandler(_issueVC));

    router.post(
        '/startpresentation',
        Pipeline()
            .addMiddleware(authProvider.requireAuth())
            .addHandler(_getOutOfBandPresentationInvitation));

    return router;
  }
}
