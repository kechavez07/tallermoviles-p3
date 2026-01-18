import '/components/lyrics_widget.dart';
import '/components/player_up_bar/player_up_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'player_widget.dart' show PlayerWidget;
import 'package:flutter/material.dart';

class PlayerModel extends FlutterFlowModel<PlayerWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Slider widget.
  double? sliderValue;
  // Model for PlayerUpBar component.
  late PlayerUpBarModel playerUpBarModel;
  // Model for Lyrics component.
  late LyricsModel lyricsModel;

  @override
  void initState(BuildContext context) {
    playerUpBarModel = createModel(context, () => PlayerUpBarModel());
    lyricsModel = createModel(context, () => LyricsModel());
  }

  @override
  void dispose() {
    playerUpBarModel.dispose();
    lyricsModel.dispose();
  }
}
