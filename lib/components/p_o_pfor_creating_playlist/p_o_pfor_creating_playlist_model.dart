import '/flutter_flow/flutter_flow_util.dart';
import 'p_o_pfor_creating_playlist_widget.dart'
    show POPforCreatingPlaylistWidget;
import 'package:flutter/material.dart';

class POPforCreatingPlaylistModel
    extends FlutterFlowModel<POPforCreatingPlaylistWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
