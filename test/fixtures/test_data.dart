// Test data and factory functions for socketx_client tests.
//
// Provides centralized, reusable test data to keep tests clean and consistent.
// All test data is defined as constants or static methods — no mutable state.

import 'dart:typed_data';

import 'package:mte_socketx/mte_socketx.dart';

/// Centralized test data for socketx_client tests.
class TestData {
  // ---------------------------------------------------------------------------
  // URLs
  // ---------------------------------------------------------------------------

  static const testUrl = 'wss://dev-socketx-server.eclypses.com';
  static const testUrlWithRoom = 'wss://dev-socketx-server.eclypses.com/dogs';
  static const testUrlWithPort = 'wss://example.com:8080/socket';

  // ---------------------------------------------------------------------------
  // Headers
  // ---------------------------------------------------------------------------

  static const testHeaders = {
    'Authorization': 'Bearer test-token-123',
    'X-Custom-Header': 'custom-value',
  };

  static const emptyHeaders = <String, String>{};

  static const singleHeader = {
    'Authorization': 'Bearer token',
  };

  // ---------------------------------------------------------------------------
  // Text Messages
  // ---------------------------------------------------------------------------

  static const simpleMessage = 'Hello, SocketX!';
  static const emptyMessage = '';
  static const specialCharactersMessage = 'Héllo! @#\$%^&*() 你好 🌍';
  static final longMessage = 'A' * 10000;
  static const jsonMessage = '{"type":"chat","payload":"Hello"}';
  static const multilineMessage = 'Line 1\nLine 2\nLine 3';

  /// A list of sample messages for batch/throughput testing.
  static List<String> sampleMessages(int count) {
    return List.generate(count, (i) => 'Message $i');
  }

  // ---------------------------------------------------------------------------
  // Binary Data
  // ---------------------------------------------------------------------------

  static Uint8List get simpleBinary => Uint8List.fromList([0x01, 0x02, 0x03]);
  static Uint8List get emptyBinary => Uint8List(0);
  static Uint8List get singleByteBinary => Uint8List.fromList([0xFF]);

  /// Creates a binary payload of [size] bytes for stress/performance testing.
  static Uint8List largeBinary(int size) {
    return Uint8List.fromList(List.generate(size, (i) => i % 256));
  }

  // ---------------------------------------------------------------------------
  // Error Maps (as received from native code)
  // ---------------------------------------------------------------------------

  static const networkErrorMap = {
    'type': 'network',
    'reason': 'Connection refused',
  };

  static const handshakeErrorMap = {
    'type': 'handshake',
    'reason': 'MTE handshake failed',
  };

  static const codecErrorMap = {
    'type': 'codec',
    'reason': 'Failed to encode message',
  };

  static const transportErrorMap = {
    'type': 'transport',
    'reason': 'WebSocket closed unexpectedly',
  };

  static const proxyErrorMap = {
    'type': 'proxy',
    'reason': 'Proxy authentication required',
  };

  static const internalErrorMap = {
    'type': 'internal',
    'reason': 'Unexpected internal state',
  };

  static const unknownErrorMap = {
    'type': 'unknown',
    'reason': 'Something went wrong',
  };

  // Edge case error maps
  static const errorMapMissingType = {
    'reason': 'No type provided',
  };

  static const errorMapMissingReason = {
    'type': 'network',
  };

  static const errorMapEmpty = <String, dynamic>{};

  static const errorMapUnrecognizedType = {
    'type': 'nonexistent_error_type',
    'reason': 'Unrecognized error type',
  };

  static const errorMapUpperCaseType = {
    'type': 'NETWORK',
    'reason': 'Upper case type',
  };

  static const errorMapMixedCaseType = {
    'type': 'HaNdShAkE',
    'reason': 'Mixed case type',
  };

  /// All valid error maps, one per error type.
  static const allErrorMaps = [
    networkErrorMap,
    handshakeErrorMap,
    codecErrorMap,
    transportErrorMap,
    proxyErrorMap,
    internalErrorMap,
    unknownErrorMap,
  ];

  // ---------------------------------------------------------------------------
  // SocketXError Factory Helpers
  // ---------------------------------------------------------------------------

  static SocketXError networkError([String reason = 'Connection refused']) {
    return SocketXError(type: SocketXErrorType.network, reason: reason);
  }

  static SocketXError handshakeError(
      [String reason = 'MTE handshake failed']) {
    return SocketXError(type: SocketXErrorType.handshake, reason: reason);
  }

  static SocketXError codecError([String reason = 'Failed to encode']) {
    return SocketXError(type: SocketXErrorType.codec, reason: reason);
  }

  static SocketXError transportError(
      [String reason = 'WebSocket closed unexpectedly']) {
    return SocketXError(type: SocketXErrorType.transport, reason: reason);
  }

  static SocketXError unknownError([String reason = 'Something went wrong']) {
    return SocketXError(type: SocketXErrorType.unknown, reason: reason);
  }
}
