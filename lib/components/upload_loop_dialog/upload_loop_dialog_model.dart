import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'upload_loop_dialog_widget.dart' show UploadLoopDialogWidget;
import 'package:flutter/material.dart';

class UploadLoopDialogModel
    extends FlutterFlowModel<UploadLoopDialogWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for title TextField widget.
  FocusNode? titleFocusNode;
  TextEditingController? titleController;
  String? Function(BuildContext, String?)? titleControllerValidator;

  // State field(s) for description TextField widget.
  FocusNode? descriptionFocusNode;
  TextEditingController? descriptionController;
  String? Function(BuildContext, String?)? descriptionControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    titleFocusNode?.dispose();
    titleController?.dispose();
    descriptionFocusNode?.dispose();
    descriptionController?.dispose();
  }
}
