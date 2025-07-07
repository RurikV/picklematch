import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'home_screen.dart';
import 'verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailLinkController = TextEditingController();
  bool _isLogin = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Tab controller for the login tabs
  late TabController _tabController;

  // Tab indices
  static const int _googleTabIndex = 0;
  static const int _emailPasswordTabIndex = 1;
  static const int _emailLinkTabIndex = 2;

  // Show a detailed help dialog for SHA-1 fingerprint issues (error code 10)
  void _showSha1HelpDialog() {
    print('LoginScreen: Showing SHA-1 help dialog');

    // Command to get SHA-1 fingerprint
    const String keytoolCommand = 'keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android';

    // Current SHA-1 fingerprint from google-services.json
    const String currentSha1 = '601648ba29d0a97b2bdd4aabd35fb388ab553c2e';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Google Sign-In Error (Code 10)'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'What is Error Code 10?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Error code 10 means the app is missing the required SHA-1 fingerprint in Firebase console. '
                  'This is a common issue during development and testing.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Follow these steps to fix the issue:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStepItem(1, 'Run this command in your terminal:'),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        keytoolCommand,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(const ClipboardData(text: keytoolCommand));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Command copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStepItem(2, 'Look for "SHA1:" in the output and copy the fingerprint'),
                _buildStepItem(3, 'Go to Firebase Console > Project Settings > Your Apps > Android App'),
                _buildStepItem(4, 'Add the SHA-1 fingerprint you copied'),
                _buildStepItem(5, 'Download the updated google-services.json file'),
                _buildStepItem(6, 'Replace the existing file in your project\'s android/app/ directory'),
                _buildStepItem(7, 'Rebuild your app'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Current Configuration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'SHA-1 in google-services.json:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(const ClipboardData(text: currentSha1));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SHA-1 fingerprint copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currentSha1,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Make sure this matches the SHA-1 of your development environment.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• This is a development configuration issue, not an app problem\n'
                        '• Each developer needs their own SHA-1 fingerprint added to Firebase\n'
                        '• For release builds, you\'ll need to add the release certificate fingerprint',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logDebugInfo();
              },
              child: const Text('Show Debug Info'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build a step item in the help dialog
  Widget _buildStepItem(int stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  // Debug method to log additional information about the device and app configuration
  void _logDebugInfo() {
    print('\n======== DEBUG INFORMATION ========');
    print('LoginScreen: Debug button pressed');

    // Log device information
    print('Device Information:');
    print('- Platform: ${Theme.of(context).platform}');

    // Log app information
    print('App Information:');
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    print('- Screen size: ${mediaQuery.size.width}x${mediaQuery.size.height}');
    print('- Device pixel ratio: ${mediaQuery.devicePixelRatio}');
    print('- Text scale factor: ${mediaQuery.textScaleFactor}');
    print('- Package name: app.vercel.picklematch.picklematch');

    // Log build information
    print('Build Information:');
    print('- Flutter version: ${PlatformDispatcher.instance.views.first.platformDispatcher.semanticsEnabled ? "Semantics Enabled" : "Semantics Disabled"}');
    print('- Is debug: ${!const bool.fromEnvironment("dart.vm.product")}');

    // Log Firebase configuration
    print('Firebase Configuration:');
    print('- SHA-1 in google-services.json: 601648ba29d0a97b2bdd4aabd35fb388ab553c2e');
    print('- To get your debug SHA-1, run:');
    print('  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android');

    // Log Google Sign-In information
    print('Google Sign-In Information:');
    print('- Error code 10 means: The application is misconfigured');
    print('- Common causes:');
    print('  1. SHA-1 fingerprint missing in Firebase console');
    print('  2. Package name mismatch between app and Firebase console');
    print('  3. Google Sign-In API not enabled in Google Cloud Console');
    print('- Verification steps:');
    print('  1. Check that the SHA-1 fingerprint in Firebase console matches your development environment');
    print('  2. Verify that the package name in google-services.json matches your app\'s package name');
    print('  3. Make sure Google Sign-In API is enabled in Google Cloud Console');

    // Log auth state
    final authState = context.read<AuthBloc>().state;
    print('Auth State:');
    print('- Current state: ${authState.runtimeType}');
    if (authState is AuthFailure) {
      print('- Error message: ${authState.error}');
      print('- Contains "ApiException: 10": ${authState.error.contains("ApiException: 10")}');
      print('- Contains "code 10": ${authState.error.contains("code 10")}');
      print('- Contains "SHA-1 fingerprint": ${authState.error.contains("SHA-1 fingerprint")}');
    }

    // Log tab controller state
    print('Tab Controller:');
    print('- Current tab index: ${_tabController.index}');
    print('- Tab count: ${_tabController.length}');
    print('- Current tab: ${_tabController.index == _googleTabIndex ? "Google Sign-In" : _tabController.index == _emailPasswordTabIndex ? "Email/Password" : "Email Link"}');

    // Log form state
    print('Form State:');
    print('- Is login mode: $_isLogin');
    print('- Email field (Email/Password tab): ${_emailController.text.isNotEmpty ? "Has text" : "Empty"}');
    print('- Password field: ${_passwordController.text.isNotEmpty ? "Has text" : "Empty"}');
    print('- Email field (Email Link tab): ${_emailLinkController.text.isNotEmpty ? "Has text" : "Empty"}');

    // Show a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug information logged to console. Check logs for detailed information.'),
        duration: Duration(seconds: 3),
      ),
    );

    print('======== END DEBUG INFORMATION ========\n');

    // Log a special message to help users find the debug information in the logs
    print('\n[DEBUG_LOG] If you\'re looking for the debug information, search for "DEBUG INFORMATION" in the logs.');
    print('[DEBUG_LOG] The most important information is in the "Google Sign-In Information" section.');
    print('[DEBUG_LOG] Follow the steps in the SHA-1 help dialog to fix the issue.\n');
  }

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();

    // Initialize tab controller with 3 tabs
    _tabController = TabController(length: 3, vsync: this);

    // Listen for tab changes to update animation
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailLinkController.dispose();
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_isLogin) {
        context.read<AuthBloc>().add(
          LoginRequested(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
      } else {
        context.read<AuthBloc>().add(
          RegisterRequested(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
      }
    }
  }

  void _submitEmailLink() {
    if (_emailLinkController.text.isNotEmpty) {
      if (RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailLinkController.text)) {
        context.read<AuthBloc>().add(
          EmailLinkRequested(
            email: _emailLinkController.text,
          ),
        );

        // Show a snackbar to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email for a sign-in link'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
        ),
      );
    }
  }

  // Google Sign In Tab
  Widget _buildGoogleSignInTab() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sign in with your Google account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: state is AuthLoading
                  ? null
                  : () {
                      print('LoginScreen: Google Sign-In button clicked');
                      print('LoginScreen: Current tab index: ${_tabController.index}');
                      print('LoginScreen: Current auth state: ${context.read<AuthBloc>().state.runtimeType}');
                      context.read<AuthBloc>().add(GoogleSignInRequested());
                      print('LoginScreen: GoogleSignInRequested event dispatched to AuthBloc');
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              icon: const Icon(Icons.g_mobiledata, size: 24),
              label: const Text('Sign in with Google'),
            ),
          ],
        );
      },
    );
  }

  // Email/Password Tab
  Widget _buildEmailPasswordTab() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!_isLogin && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24.0),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state is AuthLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: state is AuthLoading
                    ? const CircularProgressIndicator()
                    : Text(_isLogin ? 'Login' : 'Register'),
              );
            },
          ),
          const SizedBox(height: 16.0),
          TextButton(
            onPressed: _toggleMode,
            child: Text(
              _isLogin
                  ? 'Don\'t have an account? Register'
                  : 'Already have an account? Login',
            ),
          ),
        ],
      ),
    );
  }

  // Email Link Tab
  Widget _buildEmailLinkTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Enter your email to receive a sign-in link',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24.0),
        TextField(
          controller: _emailLinkController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24.0),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: state is AuthLoading ? null : _submitEmailLink,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: state is AuthLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Sign-In Link'),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print('LoginScreen: BlocListener received state: ${state.runtimeType}');
          print('LoginScreen: Current tab index: ${_tabController.index}');

          if (state is AuthAuthenticated) {
            print('LoginScreen: Received AuthAuthenticated state, navigating to HomeScreen');
            print('LoginScreen: User details - Email: ${state.user.email}, UID: ${state.user.uid}, Active: ${state.user.isActive}, Role: ${state.user.role}');
            print('LoginScreen: Token: ${state.token}');

            try {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
              print('LoginScreen: Navigation to HomeScreen completed successfully');
            } catch (e) {
              print('LoginScreen: Error during navigation to HomeScreen: $e');
            }
          } else if (state is AuthVerificationNeeded || state is RegistrationSuccess) {
            print('LoginScreen: Received ${state.runtimeType} state, navigating to VerificationScreen');

            if (state is AuthVerificationNeeded) {
              print('LoginScreen: User needs verification - Email: ${state.user.email}, UID: ${state.user.uid}');
            } else if (state is RegistrationSuccess) {
              print('LoginScreen: Registration successful - Email: ${state.user.email}, UID: ${state.user.uid}');
            }

            try {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const VerificationScreen()),
              );
              print('LoginScreen: Navigation to VerificationScreen completed successfully');
            } catch (e) {
              print('LoginScreen: Error during navigation to VerificationScreen: $e');
            }
          } else if (state is AuthFailure) {
            print('LoginScreen: Received AuthFailure state');
            print('LoginScreen: Error message: ${state.error}');
            print('LoginScreen: Error type: ${state.error.contains('ApiException') ? 'ApiException' : 'Other'}');

            // Special handling for error code 10
            if (state.error.contains('ApiException: 10') || 
                state.error.contains('code 10') || 
                state.error.contains('SHA-1 fingerprint')) {
              print('LoginScreen: Detected ApiException with error code 10 (Developer error)');

              // Show a detailed help dialog for error code 10
              _showSha1HelpDialog();

              // Also show a snackbar with a brief message
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google Sign-In configuration error. See dialog for instructions.'),
                    duration: Duration(seconds: 5),
                  ),
                );
                print('LoginScreen: Displayed error message in SnackBar and showing help dialog');
              } catch (e) {
                print('LoginScreen: Error displaying SnackBar: $e');
              }
            } else if (state.error.contains('Unknown calling package name')) {
              print('LoginScreen: Detected "Unknown calling package name" error');

              // Show a snackbar with the error message
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
                print('LoginScreen: Displayed error message in SnackBar');
              } catch (e) {
                print('LoginScreen: Error displaying SnackBar: $e');
              }
            } else {
              // For other errors, just show a snackbar
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
                print('LoginScreen: Displayed error message in SnackBar');
              } catch (e) {
                print('LoginScreen: Error displaying SnackBar: $e');
              }
            }
          } else if (state is RegistrationFailure) {
            print('LoginScreen: Received RegistrationFailure state: ${state.error}');

            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
              print('LoginScreen: Displayed registration error message in SnackBar');
            } catch (e) {
              print('LoginScreen: Error displaying SnackBar: $e');
            }
          } else if (state is AuthLoading) {
            print('LoginScreen: Received AuthLoading state');
            print('LoginScreen: Showing loading indicator');
          } else {
            print('LoginScreen: Received unhandled state: ${state.runtimeType}');
            print('LoginScreen: Full state details: $state');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade700,
                Colors.blue.shade900,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16.0),
                        Image.asset(
                          'assets/logo.png',
                          height: 80.0,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.sports_tennis,
                              size: 80.0,
                              color: Colors.blue,
                            );
                          },
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          'Welcome to Pickle Match',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24.0),

                        // Tab Bar
                        TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(context).primaryColor,
                          tabs: const [
                            Tab(text: 'Google'),
                            Tab(text: 'Email/Pwd'),
                            Tab(text: 'Email Link'),
                          ],
                        ),

                        // Debug buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _showSha1HelpDialog();
                              },
                              child: const Text(
                                'SHA-1 Help',
                                style: TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _logDebugInfo();
                              },
                              child: const Text(
                                'Debug',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24.0),

                        // Tab Bar View
                        SizedBox(
                          height: 400, // Increased height for the tab content to prevent overflow
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Google Sign In Tab
                              _buildGoogleSignInTab(),

                              // Email/Password Tab
                              _buildEmailPasswordTab(),

                              // Email Link Tab
                              _buildEmailLinkTab(),
                            ],
                          ),
                        ),
                      ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ) );
  }
}
