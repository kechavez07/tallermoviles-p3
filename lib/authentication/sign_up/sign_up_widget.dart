import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_up_model.dart';
export 'sign_up_model.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  static String routeName = 'SignUp';
  static String routePath = '/signUp';

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  late SignUpModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignUpModel());
    _model.singUpEmailTextController ??= TextEditingController();
    _model.singUpEmailFocusNode ??= FocusNode();
    _model.signUpPasswordTextController ??= TextEditingController();
    _model.signUpPasswordFocusNode ??= FocusNode();
    _model.signUpPasswordConfirmTextController ??= TextEditingController();
    _model.signUpPasswordConfirmFocusNode ??= FocusNode();
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
                    Text(
                      'Create Account',
                      style: FlutterFlowTheme.of(context).headlineSmall.override(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Email
                    TextFormField(
                      controller: _model.singUpEmailTextController,
                      focusNode: _model.singUpEmailFocusNode,
                      decoration: _inputDecoration('Email Address'),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password
                    TextFormField(
                      controller: _model.signUpPasswordTextController,
                      focusNode: _model.signUpPasswordFocusNode,
                      obscureText: !_model.signUpPasswordVisibility,
                      decoration: _inputDecoration('Password', isPassword: true, visible: _model.signUpPasswordVisibility, onToggle: () => setState(() => _model.signUpPasswordVisibility = !_model.signUpPasswordVisibility)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password
                    TextFormField(
                      controller: _model.signUpPasswordConfirmTextController,
                      focusNode: _model.signUpPasswordConfirmFocusNode,
                      obscureText: !_model.signUpPasswordConfirmVisibility,
                      decoration: _inputDecoration('Confirm Password', isPassword: true, visible: _model.signUpPasswordConfirmVisibility, onToggle: () => setState(() => _model.signUpPasswordConfirmVisibility = !_model.signUpPasswordConfirmVisibility)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Email Sign Up Button
                    FFButtonWidget(
                      onPressed: () async {
                        if (_model.signUpPasswordTextController.text != _model.signUpPasswordConfirmTextController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
                          return;
                        }
                        final user = await authManager.createAccountWithEmail(
                          context,
                          _model.singUpEmailTextController.text,
                          _model.signUpPasswordTextController.text,
                        );
                        if (user != null) context.goNamedAuth(GetStartedWidget.routeName, context.mounted);
                      },
                      text: 'Create Account',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 50,
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text('OR', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    
                    // GOOGLE SIGN UP BUTTON
                    InkWell(
                      onTap: () async {
                        GoRouter.of(context).prepareAuthEvent();
                        final user = await authManager.signInWithGoogle(context);
                        if (user != null) {
                          context.goNamedAuth(HomeWidget.routeName, context.mounted);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Sign Up with Google',
                              style: GoogleFonts.outfit(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Back to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: Colors.white70)),
                        InkWell(
                          onTap: () => context.pushNamed(LoginWidget.routeName),
                          child: Text(
                            'Login',
                            style: TextStyle(color: FlutterFlowTheme.of(context).primary, fontWeight: FontWeight.bold),
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

  InputDecoration _inputDecoration(String label, {bool isPassword = false, bool visible = false, VoidCallback? onToggle}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0x33FFFFFF),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: isPassword ? InkWell(onTap: onToggle, child: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.white70)) : null,
    );
  }
}
