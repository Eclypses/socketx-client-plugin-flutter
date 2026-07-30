// The MIT License (MIT)
//
// Copyright (c) Eclypses, Inc.
//
// All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'socketx_client.dart';
import 'socketx_client_platform_interface.dart';

/// Method channel implementation of [SocketXClientPlatform].
///
/// This class handles communication with native iOS and Android code
/// via Flutter's method channel mechanism.
class MethodChannelSocketXClient extends SocketXClientPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('socketx_client');

  /// Constructor initializes the method call handler for callbacks from native.
  MethodChannelSocketXClient() {
    methodChannel.setMethodCallHandler(_handleNativeCallback);
  }

  // MARK: - Stream Controllers

  final StreamController<void> _onConnectedController =
      StreamController<void>.broadcast();

  final StreamController<String> _onMessageController =
      StreamController<String>.broadcast();

  final StreamController<Uint8List> _onBinaryMessageController =
      StreamController<Uint8List>.broadcast();

  final StreamController<SocketXError> _onErrorController =
      StreamController<SocketXError>.broadcast();

  // MARK: - Stream Getters

  @override
  Stream<void> get onConnectedStream => _onConnectedController.stream;

  @override
  Stream<String> get onMessageStream => _onMessageController.stream;

  @override
  Stream<Uint8List> get onBinaryMessageStream =>
      _onBinaryMessageController.stream;

  @override
  Stream<SocketXError> get onErrorStream => _onErrorController.stream;

  // MARK: - Native Callback Handler

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onConnected':
        _onConnectedController.add(null);
        return null;

      case 'onMessage':
        final String message = call.arguments as String;
        _onMessageController.add(message);
        return null;

      case 'onBinaryMessage':
        final Uint8List data = call.arguments as Uint8List;
        _onBinaryMessageController.add(data);
        return null;

      case 'onError':
        final Map<dynamic, dynamic> errorMap =
            call.arguments as Map<dynamic, dynamic>;
        final error = SocketXError.fromMap(errorMap);
        _onErrorController.add(error);
        return null;

      default:
        developer.log(
          'Unknown method call from native: ${call.method}',
          name: 'SocketX',
          level: 900, // WARNING
        );
        return null;
    }
  }

  // MARK: - Connection Methods

  @override
  Future<void> connect({required String url, Map<String, String>? headers}) async {
    await methodChannel.invokeMethod('connect', {
      'url': url,
      'headers': headers,
    });
  }

  @override
  Future<void> disconnect() async {
    await methodChannel.invokeMethod('disconnect');
  }

  // MARK: - Send Methods

  @override
  Future<void> sendText(String text) async {
    await methodChannel.invokeMethod('sendText', {'text': text});
  }

  @override
  Future<void> sendBinary(Uint8List data) async {
    await methodChannel.invokeMethod('sendBinary', {'data': data});
  }

  // MARK: - Utility Methods

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  // MARK: - Diagnostics

  @override
  Future<void> enableFileLogging(bool enabled) async {
    await methodChannel.invokeMethod('enableFileLogging', {'enabled': enabled});
  }

  @override
  Future<String?> readLogFile() async {
    return await methodChannel.invokeMethod<String>('readLogFile');
  }

  @override
  Future<void> clearLogFile() async {
    await methodChannel.invokeMethod('clearLogFile');
  }
}
