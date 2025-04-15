import 'package:flutter/material.dart';


const String  terms = '''Terms and ConditionsLast Updated: April 3, 2025

Welcome to Taskii! These Terms and Conditions ("Terms") govern your use of our task management application ("App"). By accessing or using the App, you agree to be bound by these Terms. If you do not agree, please do not use the App.


1. Use of the App

1.1 You must be at least 18 years old or have parental consent to use the App.
1.2 You agree to use the App only for lawful purposes and in accordance with these Terms.
1.3 We reserve the right to suspend or terminate your access if you violate these Terms.


2. User Accounts

2.1 You may be required to create an account to access certain features.
2.2 You are responsible for maintaining the confidentiality of your account credentials.
2.3 You agree to notify us immediately of any unauthorized use of your account.


3. Subscription and Payments

3.1 Some features of the App may require a paid subscription.
3.2 All payments are non-refundable unless required by law.
3.3 We reserve the right to modify subscription fees with prior notice.


4. Privacy Policy

4.1 Your use of the App is also governed by our Privacy Policy.
4.2 By using the App, you consent to our data collection and usage practices.


5. Intellectual Property

5.1 All content, trademarks, and intellectual property within the App belong to Taskii Inc..
5.2 You may not copy, modify, distribute, or reproduce any content without our permission.


6. Limitation of Liability

6.1 The App is provided "as is" without warranties of any kind.
6.2 We are not liable for any damages resulting from your use of the App.
6.3 We do not guarantee the App will be error-free or uninterrupted.


7. Changes to Terms

7.1 We reserve the right to modify these Terms at any time.
7.2 Continued use of the App after changes means you accept the new Terms.


8. Governing Law

8.1 These Terms are governed by the laws of [Jurisdiction].
8.2 Any disputes will be resolved in the courts of [Jurisdiction].


9. Contact Us

If you have any questions about these Terms, please contact us at [Contact Email].

By using the App, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.

''';

class Termsconditions extends StatelessWidget {
  const Termsconditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
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


             // Return to sign Up
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                print('Return to Sign UP Pressed');
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Return to Sign Up',
                style: TextStyle(
                  color: Color(0xFF525252),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const Text(
                terms,
                style: TextStyle(
                  color: Color(0xFF525252),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            
            ],
          ),
        ),
      ),
    );
  }
}