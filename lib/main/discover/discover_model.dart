import '/components/discover_component/discover_component_widget.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'discover_widget.dart' show DiscoverWidget;
import 'package:flutter/material.dart';

class DiscoverModel extends FlutterFlowModel<DiscoverWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for DiscoverComponent component.
  late DiscoverComponentModel discoverComponentModel;

  // Stream for music loops
  Stream<List<MusicLoopRecord>>? musicLoopsStream;

  @override
  void initState(BuildContext context) {
    discoverComponentModel =
        createModel(context, () => DiscoverComponentModel());
    
    // Initialize music loops stream
    musicLoopsStream = queryMusicLoopRecordCollection(
      queryBuilder: (musicLoopRecord) => musicLoopRecord.orderBy('created_at', descending: true),
    );
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    discoverComponentModel.dispose();
  }
}
