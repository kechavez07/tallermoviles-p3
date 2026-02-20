import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
    _model.loginEmailTextController ??= TextEditingController();
    _model.loginEmailFocusNode ??= FocusNode();
    _model.loginPasswordTextController ??= TextEditingController();
    _model.loginPasswordFocusNode ??= FocusNode();
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: Image.asset('assets/images/iPhone_13_&_14_-_28.png').image,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24.0, 42.0, 24.0, 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      'Welcome Back',
                      style: FlutterFlowTheme.of(context).displaySmall.override(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to continue your musical journey',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Outfit',
                            color: Color(0xFFE0E0E0),
                          ),
                    ),
                    const SizedBox(height: 44),
                    
                    // Email Field
                    TextFormField(
                      controller: _model.loginEmailTextController,
                      focusNode: _model.loginEmailFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        filled: true,
                        fillColor: Color(0x33FFFFFF),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    TextFormField(
                      controller: _model.loginPasswordTextController,
                      focusNode: _model.loginPasswordFocusNode,
                      obscureText: !_model.loginPasswordVisibility,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Color(0x33FFFFFF),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        suffixIcon: InkWell(
                          onTap: () => setState(() => _model.loginPasswordVisibility = !_model.loginPasswordVisibility),
                          child: Icon(
                            _model.loginPasswordVisibility ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Login Button
                    FFButtonWidget(
                      onPressed: () async {
                        GoRouter.of(context).prepareAuthEvent();
                        
                        if (_model.loginEmailTextController.text.isEmpty || 
                            _model.loginPasswordTextController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in all fields')),
                          );
                          return;
                        }

                        final user = await authManager.signInWithEmail(
                          context,
                          _model.loginEmailTextController.text,
                          _model.loginPasswordTextController.text,
                        );
                        
                        if (user != null) {
                          // Éxito: Navegar a Home
                          context.goNamedAuth(HomeWidget.routeName, context.mounted);
                        }
                      },
                      text: 'Sign In',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 54.0,
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 18,
                            ),
                        elevation: 3.0,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New here? ', style: TextStyle(color: Colors.white70)),
                        InkWell(
                          onTap: () => context.pushNamed(SignUpWidget.routeName),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
