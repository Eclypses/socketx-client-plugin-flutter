// Tests for SocketXError and SocketXErrorType.
//
// Covers the error model classes: construction, factory methods, enum parsing,
// and toString formatting. These are pure Dart — no platform interaction.

import 'package:flutter_test/flutter_test.dart';
import 'package:socketx_client/socketx_client.dart';

import 'fixtures/test_data.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SocketXErrorType.fromString
  // ---------------------------------------------------------------------------

  group('SocketXErrorType.fromString', () {
    test('should parse "network" to SocketXErrorType.network', () {
      expect(SocketXErrorType.fromString('network'), SocketXErrorType.network);
    });

    test('should parse "handshake" to SocketXErrorType.handshake', () {
      expect(
        SocketXErrorType.fromString('handshake'),
        SocketXErrorType.handshake,
      );
    });

    test('should parse "codec" to SocketXErrorType.codec', () {
      expect(SocketXErrorType.fromString('codec'), SocketXErrorType.codec);
    });

    test('should parse "transport" to SocketXErrorType.transport', () {
      expect(
        SocketXErrorType.fromString('transport'),
        SocketXErrorType.transport,
      );
    });

    test('should parse "proxy" to SocketXErrorType.proxy', () {
      expect(SocketXErrorType.fromString('proxy'), SocketXErrorType.proxy);
    });

    test('should parse "internal" to SocketXErrorType.internal', () {
      expect(
        SocketXErrorType.fromString('internal'),
        SocketXErrorType.internal,
      );
    });

    test('should parse "unknown" to SocketXErrorType.unknown', () {
      expect(SocketXErrorType.fromString('unknown'), SocketXErrorType.unknown);
    });

    test('should be case-insensitive for uppercase', () {
      expect(SocketXErrorType.fromString('NETWORK'), SocketXErrorType.network);
    });

    test('should be case-insensitive for mixed case', () {
      expect(
        SocketXErrorType.fromString('HaNdShAkE'),
        SocketXErrorType.handshake,
      );
    });

    test('should return unknown for unrecognized type', () {
      expect(
        SocketXErrorType.fromString('nonexistent'),
        SocketXErrorType.unknown,
      );
    });

    test('should return unknown for empty string', () {
      expect(SocketXErrorType.fromString(''), SocketXErrorType.unknown);
    });

    test('should return unknown for random text', () {
      expect(
        SocketXErrorType.fromString('foobar_garbage'),
        SocketXErrorType.unknown,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SocketXError Constructor
  // ---------------------------------------------------------------------------

  group('SocketXError constructor', () {
    test('should store type and reason', () {
      const error = SocketXError(
        type: SocketXErrorType.network,
        reason: 'Connection refused',
      );

      expect(error.type, SocketXErrorType.network);
      expect(error.reason, 'Connection refused');
    });

    test('should support const construction', () {
      const error1 = SocketXError(
        type: SocketXErrorType.codec,
        reason: 'test',
      );
      const error2 = SocketXError(
        type: SocketXErrorType.codec,
        reason: 'test',
      );

      // Const instances with same values are identical
      expect(identical(error1, error2), true);
    });
  });

  // ---------------------------------------------------------------------------
  // SocketXError.fromMap
  // ---------------------------------------------------------------------------

  group('SocketXError.fromMap', () {
    test('should parse network error map', () {
      final error = SocketXError.fromMap(TestData.networkErrorMap);

      expect(error.type, SocketXErrorType.network);
      expect(error.reason, 'Connection refused');
    });

    test('should parse handshake error map', () {
      final error = SocketXError.fromMap(TestData.handshakeErrorMap);

      expect(error.type, SocketXErrorType.handshake);
      expect(error.reason, 'MTE handshake failed');
    });

    test('should parse codec error map', () {
      final error = SocketXError.fromMap(TestData.codecErrorMap);

      expect(error.type, SocketXErrorType.codec);
      expect(error.reason, 'Failed to encode message');
    });

    test('should parse transport error map', () {
      final error = SocketXError.fromMap(TestData.transportErrorMap);

      expect(error.type, SocketXErrorType.transport);
      expect(error.reason, 'WebSocket closed unexpectedly');
    });

    test('should parse proxy error map', () {
      final error = SocketXError.fromMap(TestData.proxyErrorMap);

      expect(error.type, SocketXErrorType.proxy);
      expect(error.reason, 'Proxy authentication required');
    });

    test('should parse internal error map', () {
      final error = SocketXError.fromMap(TestData.internalErrorMap);

      expect(error.type, SocketXErrorType.internal);
      expect(error.reason, 'Unexpected internal state');
    });

    test('should parse unknown error map', () {
      final error = SocketXError.fromMap(TestData.unknownErrorMap);

      expect(error.type, SocketXErrorType.unknown);
      expect(error.reason, 'Something went wrong');
    });

    test('should default type to unknown when type key is missing', () {
      final error = SocketXError.fromMap(TestData.errorMapMissingType);

      expect(error.type, SocketXErrorType.unknown);
      expect(error.reason, 'No type provided');
    });

    test('should default reason when reason key is missing', () {
      final error = SocketXError.fromMap(TestData.errorMapMissingReason);

      expect(error.type, SocketXErrorType.network);
      expect(error.reason, 'Unknown error');
    });

    test('should handle empty map', () {
      final error = SocketXError.fromMap(TestData.errorMapEmpty);

      expect(error.type, SocketXErrorType.unknown);
      expect(error.reason, 'Unknown error');
    });

    test('should handle unrecognized type string', () {
      final error = SocketXError.fromMap(TestData.errorMapUnrecognizedType);

      expect(error.type, SocketXErrorType.unknown);
      expect(error.reason, 'Unrecognized error type');
    });

    test('should handle upper case type from native', () {
      final error = SocketXError.fromMap(TestData.errorMapUpperCaseType);

      expect(error.type, SocketXErrorType.network);
    });

    test('should handle mixed case type from native', () {
      final error = SocketXError.fromMap(TestData.errorMapMixedCaseType);

      expect(error.type, SocketXErrorType.handshake);
    });
  });

  // ---------------------------------------------------------------------------
  // SocketXError.toString
  // ---------------------------------------------------------------------------

  group('SocketXError.toString', () {
    test('should format as SocketXError(type: reason)', () {
      const error = SocketXError(
        type: SocketXErrorType.network,
        reason: 'Connection refused',
      );

      expect(error.toString(), 'SocketXError(network: Connection refused)');
    });

    test('should include type name for all error types', () {
      for (final type in SocketXErrorType.values) {
        final error = SocketXError(type: type, reason: 'test');
        expect(error.toString(), contains(type.name));
      }
    });

    test('should handle empty reason in toString', () {
      const error = SocketXError(type: SocketXErrorType.unknown, reason: '');

      expect(error.toString(), 'SocketXError(unknown: )');
    });

    test('should handle special characters in reason', () {
      const error = SocketXError(
        type: SocketXErrorType.transport,
        reason: 'Error: "quotes" & <brackets>',
      );

      expect(error.toString(), contains('Error: "quotes" & <brackets>'));
    });
  });
}
