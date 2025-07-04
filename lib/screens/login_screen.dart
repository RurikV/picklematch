import 'package:flutter/material.dart';
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
                      context.read<AuthBloc>().add(GoogleSignInRequested());
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
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
          if (state is AuthAuthenticated) {
            print('LoginScreen: Received AuthAuthenticated state, navigating to HomeScreen');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
            print('LoginScreen: Navigation to HomeScreen completed');
          } else if (state is AuthVerificationNeeded || state is RegistrationSuccess) {
            print('LoginScreen: Received ${state.runtimeType} state, navigating to VerificationScreen');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const VerificationScreen()),
            );
          } else if (state is AuthFailure) {
            print('LoginScreen: Received AuthFailure state: ${state.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is RegistrationFailure) {
            print('LoginScreen: Received RegistrationFailure state: ${state.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is AuthLoading) {
            print('LoginScreen: Received AuthLoading state');
          } else {
            print('LoginScreen: Received unhandled state: ${state.runtimeType}');
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

                        const SizedBox(height: 24.0),

                        // Tab Bar View
                        SizedBox(
                          height: 300, // Fixed height for the tab content
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
