// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Add the correct channel names for Firebase Core 3.x
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.firebase_core.FirebaseCoreHostApi.initializeCore',
    (message) async {
      return StandardMethodCodec().encodeSuccessEnvelope([
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
      ]);
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.firebase_core.FirebaseCoreHostApi.initializeApp',
    (message) async {
      return StandardMethodCodec().encodeSuccessEnvelope({
        'name': 'test',
        'options': {
          'apiKey': 'test',
          'appId': 'test',
          'messagingSenderId': 'test',
          'projectId': 'test',
        },
        'pluginConstants': {},
      });
    },
  );
}

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

Future<T> neverEndingFuture<T>() async {
  // Keep your existing code here
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
  }
}