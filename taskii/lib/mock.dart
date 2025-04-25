// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

    setupFirebaseCoreMocks();
  }
  void setupFirebaseCoreMocks() {
    // Add mock implementation for Firebase core methods if needed.
    const MethodChannel('plugins.flutter.io/firebase_core').setMockMethodCallHandler((MethodCall methodCall) async {
      return null; // Return mock responses for Firebase core methods.
    });
}

Future<T> neverEndingFuture<T>() async {
  // ignore: literal_only_boolean_expressions
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
  }
}