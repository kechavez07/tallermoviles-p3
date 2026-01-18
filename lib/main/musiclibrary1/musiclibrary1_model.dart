import '/components/musiclibrary/musiclibrary_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'musiclibrary1_widget.dart' show Musiclibrary1Widget;
import 'package:flutter/material.dart';

class Musiclibrary1Model extends FlutterFlowModel<Musiclibrary1Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for Musiclibrary component.
  late MusiclibraryModel musiclibraryModel;

  @override
  void initState(BuildContext context) {
    musiclibraryModel = createModel(context, () => MusiclibraryModel());
  }

  @override
  void dispose() {
    musiclibraryModel.dispose();
  }
}
