import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';
import 'forgotpassword.dart';
import 'sign_up.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseAndRun();
}

Future<void> initializeFirebaseAndRun() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    //webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    // androidProvider: AndroidProvider.playIntegrity,   ::For Production
    // appleProvider: AppleProvider.appAttest,           ::For Production 
  );

  // Disable reCAPTCHA for testing
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
    phoneNumber: null,
    smsCode: null,
    forceRecaptchaFlow: false,
  );

  runApp(const Taskii());
}

class Taskii extends StatelessWidget {
  final FirebaseAuth? firebaseAuth;
  const Taskii({super.key, this.firebaseAuth});

  @override
  Widget build(BuildContext context) {
    final auth = firebaseAuth ?? FirebaseAuth.instance;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/':
            (context) => StreamBuilder<User?>(
              stream: auth.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData) {
                  return const HomePage();
                }
                return const LoginPageSignUp();
              },
            ),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class LoginPageSignUp extends StatefulWidget {
  const LoginPageSignUp({super.key});

  @override
  State<LoginPageSignUp> createState() => _LoginPageSignUpState();
}

class _LoginPageSignUpState extends State<LoginPageSignUp> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  late SharedPreferences _prefs;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLockoutState();
  }

  Future<void> _loadLockoutState() async {
    final lockoutTime = _prefs.getInt('lockout_time');
    if (lockoutTime != null) {
      _lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutTime);
      if (!_isLockedOut()) {
        _lockoutUntil = null;
        _failedAttempts = 0;
        await _prefs.remove('lockout_time');
        await _prefs.remove('failed_attempts');
      } else {
        _failedAttempts = _prefs.getInt('failed_attempts') ?? 0;
      }
    }
  }

  Future<void> _saveLockoutState() async {
    if (_lockoutUntil != null) {
      await _prefs.setInt(
        'lockout_time',
        _lockoutUntil!.millisecondsSinceEpoch,
      );
      await _prefs.setInt('failed_attempts', _failedAttempts);
    } else {
      await _prefs.remove('lockout_time');
      await _prefs.remove('failed_attempts');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isLockedOut() {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  String _getLockoutMessage() {
    if (_lockoutUntil == null) return '';
    final remainingMinutes =
        _lockoutUntil!.difference(DateTime.now()).inMinutes;
    final remainingSeconds =
        _lockoutUntil!.difference(DateTime.now()).inSeconds % 60;
    return 'Account locked. Please try again in $remainingMinutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _signIn() async {
    if (_isLockedOut()) {
      _showSnackBar(_getLockoutMessage());
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      _showSnackBar('Password must be at least 6 characters long');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint(
        'Attempting to sign in with email: ${_emailController.text.trim()}',
      );

      // Sign in and wait for user to be fully initialized
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Ensure we have a valid user
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Failed to initialize user after sign in',
        );
      }

      // Wait for the user to be fully loaded
      await user.reload();

      debugPrint('Sign in successful for user: ${user.email}');

      _failedAttempts = 0;
      _lockoutUntil = null;
      await _saveLockoutState();

      if (mounted) {
        setState(() {
          _errorMessage = '';
          _isLoading = false;
        });
        _showSnackBar('Successfully signed in!', isError: false);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FirebaseAuthException during sign in: ${e.code} - ${e.message}',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          _failedAttempts++;
          if (_failedAttempts >= 10) {
            _lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
            errorMessage =
                'Too many failed attempts. Account locked for 5 minutes.';
            await _saveLockoutState();
          } else {
            errorMessage =
                'Wrong password. ${10 - _failedAttempts} attempts remaining.';
            await _prefs.setInt('failed_attempts', _failedAttempts);
          }
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection and try again.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many sign-in attempts. Please try again later.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Email/password sign-in is not enabled. Please contact support.';
          break;
        case 'null-user':
          errorMessage =
              'Failed to initialize user after sign in. Please try again.';
          break;
        default:
          errorMessage = 'An error occurred during sign in: ${e.message}';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
        _showSnackBar(errorMessage);
        debugPrint('Sign in error message: $errorMessage');
      }
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
        _showSnackBar(_errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100),
                  const Text(
                    'Welcome to Taskii',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: Text(_isLoading ? 'Signing in...' : 'Sign In'),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Forgot Password
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      sendPasswordResetEmail(
                        context: context,
                        email: _emailController.text,
                      );
                      debugPrint('Forgot password pressed');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color(0xFF525252),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  // Sign Up Section
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Color(0xFF525252),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      debugPrint('Sign up pressed');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// Simple loading dialog
void showLoadingDialog(BuildContext context, {String message = "Loading..."}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
  );
}
