import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_up_widget.dart' show SignUpWidget;
import 'package:flutter/material.dart';

class SignUpModel extends FlutterFlowModel<SignUpWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for SingUpEmail widget.
  FocusNode? singUpEmailFocusNode;
  TextEditingController? singUpEmailTextController;
  String? Function(BuildContext, String?)? singUpEmailTextControllerValidator;
  // State field(s) for SignUpPassword widget.
  FocusNode? signUpPasswordFocusNode;
  TextEditingController? signUpPasswordTextController;
  late bool signUpPasswordVisibility;
  String? Function(BuildContext, String?)?
      signUpPasswordTextControllerValidator;
  // State field(s) for SignUpPasswordConfirm widget.
  FocusNode? signUpPasswordConfirmFocusNode;
  TextEditingController? signUpPasswordConfirmTextController;
  late bool signUpPasswordConfirmVisibility;
  String? Function(BuildContext, String?)?
      signUpPasswordConfirmTextControllerValidator;

  @override
  void initState(BuildContext context) {
    signUpPasswordVisibility = false;
    signUpPasswordConfirmVisibility = false;
  }

  @override
  void dispose() {
    singUpEmailFocusNode?.dispose();
    singUpEmailTextController?.dispose();

    signUpPasswordFocusNode?.dispose();
    signUpPasswordTextController?.dispose();

    signUpPasswordConfirmFocusNode?.dispose();
    signUpPasswordConfirmTextController?.dispose();
  }
}
