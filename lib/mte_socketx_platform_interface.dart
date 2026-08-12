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

import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'mte_socketx.dart';
import 'mte_socketx_method_channel.dart';

/// The platform interface for the SocketX client plugin.
///
/// This abstract class defines the contract that platform-specific
/// implementations must fulfill. The default implementation uses
/// method channels to communicate with native code.
abstract class SocketXClientPlatform extends PlatformInterface {
  SocketXClientPlatform() : super(token: _token);

  static final Object _token = Object();

  static SocketXClientPlatform _instance = MethodChannelSocketXClient();

  /// The current platform implementation instance.
  static SocketXClientPlatform get instance => _instance;

  /// Sets the platform implementation to use.
  ///
  /// This is primarily used for testing to inject mock implementations.
  static set instance(SocketXClientPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // MARK: - Event Streams

  /// Stream that emits when the WebSocket connection is established.
  Stream<void> get onConnectedStream;

  /// Stream that emits when a text message is received.
  Stream<String> get onMessageStream;

  /// Stream that emits when binary data is received.
  Stream<Uint8List> get onBinaryMessageStream;

  /// Stream that emits when an error occurs.
  Stream<SocketXError> get onErrorStream;

  // MARK: - Connection Methods

  /// Establishes a WebSocket connection.
  Future<void> connect({required String url, Map<String, String>? headers}) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  /// Disconnects the current WebSocket connection.
  Future<void> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  // MARK: - Send Methods

  /// Sends a text message.
  Future<void> sendText(String text) {
    throw UnimplementedError('sendText() has not been implemented.');
  }

  /// Sends binary data.
  Future<void> sendBinary(Uint8List data) {
    throw UnimplementedError('sendBinary() has not been implemented.');
  }

  // MARK: - Utility Methods

  /// Returns the platform version string.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  // MARK: - Diagnostics

  /// Enables or disables capturing the native SocketX library's log output to a
  /// file on the device.
  Future<void> enableFileLogging(bool enabled) {
    throw UnimplementedError('enableFileLogging() has not been implemented.');
  }

  /// Reads the captured native log file, or null when there is nothing captured.
  Future<String?> readLogFile() {
    throw UnimplementedError('readLogFile() has not been implemented.');
  }

  /// Deletes the captured native log file.
  Future<void> clearLogFile() {
    throw UnimplementedError('clearLogFile() has not been implemented.');
  }
}
