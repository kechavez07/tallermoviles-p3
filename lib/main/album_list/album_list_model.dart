import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'album_list_widget.dart' show AlbumListWidget;
import 'package:flutter/material.dart';

class AlbumListModel extends FlutterFlowModel<AlbumListWidget> {
  ///  State fields for stateful widgets in this page.

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
