import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mixer_model.dart';
export 'mixer_model.dart';

class MixerWidget extends StatefulWidget {
  const MixerWidget({super.key});

  static String routeName = 'mixer';
  static String routePath = '/mixer';

  @override
  State<MixerWidget> createState() => _MixerWidgetState();
}

class _MixerWidgetState extends State<MixerWidget> {
  late MixerModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MixerModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF0A0A0A),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Header fijo arriba
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    begin: AlignmentDirectional(1.0, 0.0),
                    end: AlignmentDirectional(-1.0, 0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MixMaster Pro',
                            style: FlutterFlowTheme.of(context).headlineMedium.override(
                                  fontFamily: 'Outfit',
                                  color: Color(0xFF00D4FF),
                                  fontWeight: FontWeight.bold,
                                )),
                        Text('Professional DJ Mixer',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Manrope',
                                  color: Color(0xFF7F8C8D),
                                )),
                      ],
                    ),
                    Icon(Icons.settings, color: Color(0xFF00D4FF)),
                  ],
                ),
              ),
              // Contenido con Scroll para evitar overflow
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildTrackCard(context, 'Track A', 'Electronic Dreams', Color(0xFF1E3C72)),
                      SizedBox(height: 16),
                      _buildTrackCard(context, 'Track B', 'Deep House Vibes', Color(0xFF8E44AD)),
                      SizedBox(height: 16),
                      _buildCrossfader(context),
                      SizedBox(height: 16),
                      _buildMasterControls(context),
                      SizedBox(height: 32), // Espacio extra al final
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackCard(BuildContext context, String label, String title, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('03:24', style: TextStyle(color: Colors.white70)),
            ],
          ),
          Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),
          Slider(value: 0.5, onChanged: (v) {}, activeColor: Colors.cyan),
        ],
      ),
    );
  }

  Widget _buildCrossfader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(0xFF1A252F), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text('Crossfader', style: TextStyle(color: Colors.white)),
          Slider(value: 0.5, onChanged: (v) {}),
        ],
      ),
    );
  }

  Widget _buildMasterControls(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(0xFF2C3E50), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.fiber_manual_record, color: Colors.red, size: 32),
          Icon(Icons.play_arrow, color: Colors.green, size: 32),
          Icon(Icons.loop, color: Colors.orange, size: 32),
        ],
      ),
    );
  }
}
