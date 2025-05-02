import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> sendPasswordResetEmail({
  required BuildContext context,
  required String email,
}) async {
  final emailTrimmed = email.trim();

  if (emailTrimmed.isEmpty) {
    _showSnackBar(context, 'Please enter your email address');
    return;
  }

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(emailTrimmed)) {
    _showSnackBar(context, 'Please enter a valid email address');
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: emailTrimmed);
    _showSnackBar(context, 'Password reset email sent!', isError: false);
  } on FirebaseAuthException catch (e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with that email';
        break;
      case 'invalid-email':
        message = 'Invalid email address';
        break;
      default:
        message = 'Error sending reset email: ${e.message}';
    }
    _showSnackBar(context, message);
  } catch (e) {
    _showSnackBar(context, 'Unexpected error: ${e.toString()}');
  }
}

void _showSnackBar(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
}
