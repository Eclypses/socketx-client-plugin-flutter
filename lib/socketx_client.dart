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
import 'dart:typed_data';
import 'socketx_client_platform_interface.dart';

/// A Flutter plugin for secure WebSocket communication using the SocketX protocol.
///
/// This class provides the main public API for establishing secure WebSocket
/// connections with automatic MTE encryption/decryption.
///
/// Example usage:
/// ```dart
/// final socketX = SocketXClient();
///
/// // Set up callbacks
/// socketX.onConnected.listen((_) => print('Connected!'));
/// socketX.onMessage.listen((text) => print('Received: $text'));
/// socketX.onBinaryMessage.listen((data) => print('Received binary: ${data.length} bytes'));
/// socketX.onError.listen((error) => print('Error: $error'));
///
/// // Connect to WebSocket server
/// await socketX.connect(url: 'wss://example.com/socket');
///
/// // Send messages
/// socketX.send(text: 'Hello, server!');
/// socketX.send(binary: Uint8List.fromList([0x01, 0x02, 0x03]));
///
/// // Disconnect when done
/// socketX.disconnect();
/// ```
class SocketXClient {
  // MARK: - Connection Methods

  /// Establishes a secure WebSocket connection to the specified URL.
  ///
  /// [url] The WebSocket URL to connect to (e.g., 'wss://example.com/socket').
  /// [headers] Optional HTTP headers to include in the connection request.
  ///
  /// The connection process includes an MTE handshake for establishing
  /// encryption. The [onConnected] stream will emit when the connection
  /// is fully established and ready for messaging.
  Future<void> connect({required String url, Map<String, String>? headers}) {
    return SocketXClientPlatform.instance.connect(url: url, headers: headers);
  }

  /// Disconnects the current WebSocket connection.
  ///
  /// After disconnecting, you can establish a new connection by calling
  /// [connect] again.
  Future<void> disconnect() {
    return SocketXClientPlatform.instance.disconnect();
  }

  // MARK: - Send Methods

  /// Sends a text message through the secure WebSocket connection.
  ///
  /// [text] The text message to send. The message will be automatically
  /// encrypted before transmission.
  Future<void> send({required String text}) {
    return SocketXClientPlatform.instance.sendText(text);
  }

  /// Sends binary data through the secure WebSocket connection.
  ///
  /// [binary] The binary data to send. The data will be automatically
  /// encrypted before transmission.
  Future<void> sendBinary({required Uint8List binary}) {
    return SocketXClientPlatform.instance.sendBinary(binary);
  }

  // MARK: - Event Streams

  /// Stream that emits when the WebSocket connection is established.
  ///
  /// This fires after the MTE handshake completes and the connection
  /// is ready for secure messaging.
  Stream<void> get onConnected =>
      SocketXClientPlatform.instance.onConnectedStream;

  /// Stream that emits when a text message is received.
  ///
  /// Messages are automatically decrypted before being emitted.
  Stream<String> get onMessage =>
      SocketXClientPlatform.instance.onMessageStream;

  /// Stream that emits when binary data is received.
  ///
  /// Data is automatically decrypted before being emitted.
  Stream<Uint8List> get onBinaryMessage =>
      SocketXClientPlatform.instance.onBinaryMessageStream;

  /// Stream that emits when an error occurs.
  ///
  /// The error message describes what went wrong during connection,
  /// handshake, or messaging.
  Stream<SocketXError> get onError =>
      SocketXClientPlatform.instance.onErrorStream;

  // MARK: - Utility Methods

  /// Returns the platform version string for debugging purposes.
  Future<String?> getPlatformVersion() {
    return SocketXClientPlatform.instance.getPlatformVersion();
  }

  // MARK: - Diagnostics

  /// Enables or disables capturing the native SocketX library's log output to a
  /// file on the device. Off by default — turn it on, reproduce the issue, read
  /// it back with [readLogFile], then turn it off.
  Future<void> enableFileLogging(bool enabled) {
    return SocketXClientPlatform.instance.enableFileLogging(enabled);
  }

  /// Reads the captured native log file, or null when nothing has been captured.
  Future<String?> readLogFile() {
    return SocketXClientPlatform.instance.readLogFile();
  }

  /// Deletes the captured native log file.
  Future<void> clearLogFile() {
    return SocketXClientPlatform.instance.clearLogFile();
  }
}

/// Represents an error that occurred in the SocketX client.
class SocketXError {
  /// The type of error that occurred.
  final SocketXErrorType type;

  /// A human-readable description of the error.
  final String reason;

  const SocketXError({required this.type, required this.reason});

  /// Creates a SocketXError from a map received from native code.
  factory SocketXError.fromMap(Map<dynamic, dynamic> map) {
    final typeString = map['type'] as String? ?? 'unknown';
    final reason = map['reason'] as String? ?? 'Unknown error';

    return SocketXError(
      type: SocketXErrorType.fromString(typeString),
      reason: reason,
    );
  }

  @override
  String toString() => 'SocketXError(${type.name}: $reason)';
}

/// Types of errors that can occur in the SocketX client.
enum SocketXErrorType {
  /// A network-level error (e.g., connection refused, timeout).
  network,

  /// An error during the MTE handshake process.
  handshake,

  /// An error encoding or decoding MTE data.
  codec,

  /// An error in the WebSocket transport layer.
  transport,

  /// An error from the proxy server.
  proxy,

  /// An internal library error.
  internal,

  /// An unknown or unclassified error.
  unknown;

  /// Creates a SocketXErrorType from a string received from native code.
  static SocketXErrorType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'network':
        return SocketXErrorType.network;
      case 'handshake':
        return SocketXErrorType.handshake;
      case 'codec':
        return SocketXErrorType.codec;
      case 'transport':
        return SocketXErrorType.transport;
      case 'proxy':
        return SocketXErrorType.proxy;
      case 'internal':
        return SocketXErrorType.internal;
      default:
        return SocketXErrorType.unknown;
    }
  }
}
