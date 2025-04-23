import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sign_up.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_settings.dart';
import 'package:firebase_database/firebase_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // First, try to get the default app
    try {
      Firebase.app();
      // If we get here, Firebase is already initialized
      debugPrint('Firebase already initialized');
    } catch (e) {
      // If getting the default app fails, initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Initialize App Check
      await FirebaseAppCheck.instance.activate(
        androidProvider: const bool.fromEnvironment('dart.vm.product')
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
        appleProvider: const bool.fromEnvironment('dart.vm.product')
            ? AppleProvider.appAttest
            : AppleProvider.debug,
      );
      debugPrint('Firebase initialized successfully');
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // If we get a duplicate app error, try to get the existing app
      try {
        Firebase.app();
        debugPrint('Using existing Firebase app');
      } catch (e) {
        debugPrint('Error accessing existing Firebase app: $e');
      }
    } else {
      debugPrint('Firebase initialization error: $e');
    }
  }

  // Set up system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Enable hardware acceleration for better performance
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Run the app
  runApp(const Taskii());
}

class Taskii extends StatelessWidget {
  const Taskii({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasData) {
              return const HomePage();
            }
            return const Scaffold(
              body: SafeArea(
                child: LoginPageSignUp(),
              ),
            );
          },
        ),
        '/profile': (context) => const ProfileSettingsPage(),
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

  Future<void> _createTask() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('You must be logged in to create tasks');
        return;
      }
      
      print('Creating task for user: ${user.uid}');
      
      final taskRef = FirebaseDatabase.instance.ref('tasks/${user.uid}').push();
      await taskRef.set({
        'title': 'My Task',
        'description': 'Task Description',
        'dueDate': '2025-04-23',
        'priority': 'High',
        'isComplete': false
      });
      
      _showSnackBar('Task created successfully!', isError: false);
    } catch (e) {
      _showSnackBar('Failed to create task: $e');
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
          ],
        ),
      ),
    );
  }
}

