import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sign_up.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black, // navigation bar color
    statusBarColor: Colors.white, // status bar color
    statusBarIconBrightness: Brightness.dark, // status bar icon color
    systemNavigationBarIconBrightness: Brightness.dark, // color of navigation controls
  ));
  runApp(const Taskii());
}

class Taskii extends StatelessWidget {
  const Taskii({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: const Scaffold(
        body: SafeArea(
          child: LoginPageSignUp(),
        ),
      ),
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
        // If lockout has expired, clear it
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
      await _prefs.setInt('lockout_time', _lockoutUntil!.millisecondsSinceEpoch);
      await _prefs.setInt('failed_attempts', _failedAttempts);
    } else {
      await _prefs.remove('lockout_time');
      await _prefs.remove('failed_attempts');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
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
    final remainingMinutes = _lockoutUntil!.difference(DateTime.now()).inMinutes;
    final remainingSeconds = _lockoutUntil!.difference(DateTime.now()).inSeconds % 60;
    return 'Account locked. Please try again in $remainingMinutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _signIn() async {
    // Check if account is locked
    if (_isLockedOut()) {
      _showSnackBar(_getLockoutMessage());
      return;
    }

    // Check for empty fields
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    // Validate password length
    if (_passwordController.text.trim().length < 6) {
      _showSnackBar('Password must be at least 6 characters long');
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Reset failed attempts on successful login
      _failedAttempts = 0;
      _lockoutUntil = null;
      await _saveLockoutState();
      if (mounted) {
        setState(() {
          _errorMessage = '';
        });
        _showSnackBar('Successfully signed in!', isError: false);
        // Navigate to homepage after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          _failedAttempts++;
          if (_failedAttempts >= 10) {
            _lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
            errorMessage = 'Too many failed attempts. Account locked for 5 minutes.';
            await _saveLockoutState();
          } else {
            errorMessage = 'Wrong password. ${10 - _failedAttempts} attempts remaining.';
            await _prefs.setInt('failed_attempts', _failedAttempts);
          }
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        default:
          errorMessage = 'An error occurred during sign in: ${e.message}';
      }
      setState(() {
        _errorMessage = errorMessage;
      });
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('An unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            // Status Bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                ],
              ),
            ),
            // Logo and Title
            const SizedBox(height: 80),
            const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Color(0xFF171717),
            ),
            const SizedBox(height: 16),
            const Text(
              'Taskii',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            // Login Form
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(
                  color: Color(0xFFADAEBC),
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(
                  color: Color(0xFFADAEBC),
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _signIn,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF171717),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Forgot Password
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
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
            const Text(
              "Don't have an account?",
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                debugPrint('Sign up pressed');
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
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
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                debugPrint('Home page navigation');
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Develeper go to home page',
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
    );
  }
}

