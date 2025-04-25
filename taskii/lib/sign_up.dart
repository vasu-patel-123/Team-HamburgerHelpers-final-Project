import 'package:flutter/material.dart';
import 'terms_conditions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class SignUpPage extends StatelessWidget {

  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
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

              // Sign Up Form
              //Name box
              const SizedBox(height: 48),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Name',
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

              //email box
              const SizedBox(height: 16),
              TextField(
                controller: emailController, 
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

            //password box
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
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

            //disclaimer
            const SizedBox(height: 16),
            const Text(
                  'By signing up you agree to our terms and conditions',
                  style: TextStyle(
                    color: Color.fromARGB(255, 31, 31, 31),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
              ),
            ),
            //terms and conditions button
            const SizedBox(height: 16),
            TextButton(
                onPressed: () {
                  debugPrint('Terms and conditions pressed');
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsConditions()),
                );
                },
                style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View terms and conditions',
                  style: TextStyle(
                    color:  Color.fromARGB(255, 31, 31, 31),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            //signup button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {


                  // Retrieve email and password from the text fields
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  if (email.isEmpty || password.isEmpty) {
                    debugPrint('Email and password cannot be empty.');
                    return;
                  }

                  try {
                    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    debugPrint('User signed up successfully: ${credential.user?.email}');
                    MaterialPageRoute(builder: (context) => const HomePage());
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'weak-password') {
                      debugPrint('The password provided is too weak.');
                    } else if (e.code == 'email-already-in-use') {
                      debugPrint('The account already exists for that email.');
                    } else {
                      debugPrint('Error: ${e.message}');
                    }
                  } catch (e) {
                    debugPrint('An unexpected error occurred: $e');
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

             // Return to sign in
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                debugPrint('Return to Sign In Pressed');
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Return to Sign In',
                style: TextStyle(
                  color: Color(0xFF525252),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}