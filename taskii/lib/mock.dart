// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseCoreMocks() {
  // Pigeon channel for Firebase Core (latest versions)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.firebase_core.FirebaseCoreHostApi.initializeCore',
    (_) async => null,
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.firebase_core.FirebaseCoreHostApi.initializeApp',
    (_) async => null,
  );

  // For older method channel compatibility
  const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_core');
  channel.setMockMethodCallHandler((MethodCall call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': 'test',
          'options': {
            'apiKey': 'test',
            'appId': 'test',
            'messagingSenderId': 'test',
            'projectId': 'test',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }
    return null;
  });
}

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

Future<T> neverEndingFuture<T>() async {
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
  }
}