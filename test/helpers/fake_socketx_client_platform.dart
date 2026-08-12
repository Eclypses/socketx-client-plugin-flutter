// Hand-written fake implementation of SocketXClientPlatform for testing.
//
// Provides full control over connection behavior, stream events, and failure
// modes without requiring a mocking framework. Follows the same pattern used
// in the SocketX Sales Demo's FakeConnectionManager.
//
// Usage:
//   final fake = FakeSocketXClientPlatform();
//   SocketXClientPlatform.instance = fake;
//
//   // Simulate events
//   fake.simulateConnected();
//   fake.simulateMessage('Hello');
//   fake.simulateError(TestData.networkError());
//
//   // Control failures
//   fake.shouldFailConnect = true;  // connect() will throw

import 'dart:async';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mte_socketx/mte_socketx.dart';
import 'package:mte_socketx/mte_socketx_platform_interface.dart';

/// A controllable fake implementation of [SocketXClientPlatform] for testing.
///
/// This fake provides:
/// - **Failure flags**: Toggle failures for connect, disconnect, send, etc.
/// - **Call tracking**: Counts and last-argument capture for all operations.
/// - **Stream simulation**: Manually fire events on all 4 event streams.
/// - **Lifecycle management**: Reset state between tests, dispose streams.
class FakeSocketXClientPlatform extends SocketXClientPlatform
    with MockPlatformInterfaceMixin {
  // ---------------------------------------------------------------------------
  // Failure Flags
  // ---------------------------------------------------------------------------

  /// When true, [connect] throws an exception.
  bool shouldFailConnect = false;

  /// When true, [disconnect] throws an exception.
  bool shouldFailDisconnect = false;

  /// When true, [sendText] throws an exception.
  bool shouldFailSendText = false;

  /// When true, [sendBinary] throws an exception.
  bool shouldFailSendBinary = false;

  /// The error message used when a failure flag is triggered.
  String failureMessage = 'Simulated failure';

  // ---------------------------------------------------------------------------
  // Call Tracking
  // ---------------------------------------------------------------------------

  /// Number of times [connect] was called successfully.
  int connectCallCount = 0;

  /// Number of times [disconnect] was called successfully.
  int disconnectCallCount = 0;

  /// Number of times [sendText] was called successfully.
  int sendTextCallCount = 0;

  /// Number of times [sendBinary] was called successfully.
  int sendBinaryCallCount = 0;

  /// Number of times [getPlatformVersion] was called.
  int getPlatformVersionCallCount = 0;

  /// The URL passed to the most recent [connect] call.
  String? lastConnectUrl;

  /// The headers passed to the most recent [connect] call.
  Map<String, String>? lastConnectHeaders;

  /// The text passed to the most recent [sendText] call.
  String? lastSentText;

  /// The binary data passed to the most recent [sendBinary] call.
  Uint8List? lastSentBinary;

  /// All text messages sent via [sendText], in order.
  final List<String> sentTextMessages = [];

  /// All binary messages sent via [sendBinary], in order.
  final List<Uint8List> sentBinaryMessages = [];

  // ---------------------------------------------------------------------------
  // Configurable Responses
  // ---------------------------------------------------------------------------

  /// The value returned by [getPlatformVersion]. Default: '1.0.0-test'.
  String? platformVersionResponse = '1.0.0-test';

  // ---------------------------------------------------------------------------
  // Stream Controllers
  // ---------------------------------------------------------------------------

  final StreamController<void> _onConnectedController =
      StreamController<void>.broadcast();

  final StreamController<String> _onMessageController =
      StreamController<String>.broadcast();

  final StreamController<Uint8List> _onBinaryMessageController =
      StreamController<Uint8List>.broadcast();

  final StreamController<SocketXError> _onErrorController =
      StreamController<SocketXError>.broadcast();

  // ---------------------------------------------------------------------------
  // Stream Getters (SocketXClientPlatform overrides)
  // ---------------------------------------------------------------------------

  @override
  Stream<void> get onConnectedStream => _onConnectedController.stream;

  @override
  Stream<String> get onMessageStream => _onMessageController.stream;

  @override
  Stream<Uint8List> get onBinaryMessageStream =>
      _onBinaryMessageController.stream;

  @override
  Stream<SocketXError> get onErrorStream => _onErrorController.stream;

  // ---------------------------------------------------------------------------
  // Connection Methods (SocketXClientPlatform overrides)
  // ---------------------------------------------------------------------------

  @override
  Future<void> connect({
    required String url,
    Map<String, String>? headers,
  }) async {
    if (shouldFailConnect) {
      throw Exception(failureMessage);
    }
    lastConnectUrl = url;
    lastConnectHeaders = headers;
    connectCallCount++;
  }

  @override
  Future<void> disconnect() async {
    if (shouldFailDisconnect) {
      throw Exception(failureMessage);
    }
    disconnectCallCount++;
  }

  // ---------------------------------------------------------------------------
  // Send Methods (SocketXClientPlatform overrides)
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendText(String text) async {
    if (shouldFailSendText) {
      throw Exception(failureMessage);
    }
    lastSentText = text;
    sentTextMessages.add(text);
    sendTextCallCount++;
  }

  @override
  Future<void> sendBinary(Uint8List data) async {
    if (shouldFailSendBinary) {
      throw Exception(failureMessage);
    }
    lastSentBinary = data;
    sentBinaryMessages.add(data);
    sendBinaryCallCount++;
  }

  // ---------------------------------------------------------------------------
  // Utility Methods (SocketXClientPlatform overrides)
  // ---------------------------------------------------------------------------

  @override
  Future<String?> getPlatformVersion() async {
    getPlatformVersionCallCount++;
    return platformVersionResponse;
  }

  // ---------------------------------------------------------------------------
  // Stream Simulation Methods
  // ---------------------------------------------------------------------------

  /// Simulates a successful connection event on [onConnectedStream].
  void simulateConnected() {
    _onConnectedController.add(null);
  }

  /// Simulates receiving a text [message] on [onMessageStream].
  void simulateMessage(String message) {
    _onMessageController.add(message);
  }

  /// Simulates receiving binary [data] on [onBinaryMessageStream].
  void simulateBinaryMessage(Uint8List data) {
    _onBinaryMessageController.add(data);
  }

  /// Simulates an [error] event on [onErrorStream].
  void simulateError(SocketXError error) {
    _onErrorController.add(error);
  }

  // ---------------------------------------------------------------------------
  // Test Lifecycle
  // ---------------------------------------------------------------------------

  /// Resets all state: call counts, captured arguments, failure flags, and
  /// sentMessages lists. Does NOT close stream controllers (they remain usable).
  void reset() {
    // Failure flags
    shouldFailConnect = false;
    shouldFailDisconnect = false;
    shouldFailSendText = false;
    shouldFailSendBinary = false;
    failureMessage = 'Simulated failure';

    // Call tracking
    connectCallCount = 0;
    disconnectCallCount = 0;
    sendTextCallCount = 0;
    sendBinaryCallCount = 0;
    getPlatformVersionCallCount = 0;

    // Captured arguments
    lastConnectUrl = null;
    lastConnectHeaders = null;
    lastSentText = null;
    lastSentBinary = null;
    sentTextMessages.clear();
    sentBinaryMessages.clear();

    // Configurable responses
    platformVersionResponse = '1.0.0-test';
  }

  /// Closes all stream controllers. After calling this, stream simulation
  /// methods will throw. Use [reset] for between-test cleanup instead.
  void dispose() {
    _onConnectedController.close();
    _onMessageController.close();
    _onBinaryMessageController.close();
    _onErrorController.close();
  }
}
