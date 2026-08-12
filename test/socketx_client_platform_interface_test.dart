// Tests for SocketXClientPlatform (the abstract platform interface).
//
// Validates the platform interface contract: default instance type,
// instance setter with token verification, and UnimplementedError defaults
// for all methods.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mte_socketx/mte_socketx.dart';
import 'package:mte_socketx/mte_socketx_method_channel.dart';
import 'package:mte_socketx/mte_socketx_platform_interface.dart';

import 'helpers/fake_socketx_client_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Store the original instance so we can restore it after tests.
  final originalInstance = SocketXClientPlatform.instance;

  tearDown(() {
    // Restore original platform instance after each test.
    SocketXClientPlatform.instance = originalInstance;
  });

  // ---------------------------------------------------------------------------
  // Default Instance
  // ---------------------------------------------------------------------------

  group('Default instance', () {
    test('should be MethodChannelSocketXClient', () {
      expect(
        SocketXClientPlatform.instance,
        isA<MethodChannelSocketXClient>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Instance Setter
  // ---------------------------------------------------------------------------

  group('Instance setter', () {
    test('should accept a valid fake with MockPlatformInterfaceMixin', () {
      final fake = FakeSocketXClientPlatform();

      // Should not throw
      SocketXClientPlatform.instance = fake;

      expect(SocketXClientPlatform.instance, same(fake));
    });

    test('should accept a subclass that extends SocketXClientPlatform', () {
      // Subclasses that extend (not implement) SocketXClientPlatform are valid
      // because the super constructor stores the token. The token verification
      // is designed to catch `implements` (which skips the constructor).
      final sub = _ValidSubclass();
      SocketXClientPlatform.instance = sub;

      expect(SocketXClientPlatform.instance, same(sub));
    });
  });

  // ---------------------------------------------------------------------------
  // UnimplementedError Defaults
  // ---------------------------------------------------------------------------

  group('UnimplementedError defaults', () {
    // We need a "bare" subclass that doesn't override the methods.
    // The base class methods should all throw UnimplementedError.
    late _BarePlatform bare;

    setUp(() {
      bare = _BarePlatform();
    });

    test('connect() should throw UnimplementedError', () {
      expect(
        () => bare.connect(url: 'wss://example.com'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('disconnect() should throw UnimplementedError', () {
      expect(
        () => bare.disconnect(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('sendText() should throw UnimplementedError', () {
      expect(
        () => bare.sendText('hello'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('sendBinary() should throw UnimplementedError', () {
      expect(
        () => bare.sendBinary(Uint8List(0)),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('getPlatformVersion() should throw UnimplementedError', () {
      expect(
        () => bare.getPlatformVersion(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}

// A subclass of SocketXClientPlatform that only implements the required
// abstract stream getters but does NOT override any methods.
// This lets us test that the base class methods throw UnimplementedError.
class _BarePlatform extends SocketXClientPlatform
    with MockPlatformInterfaceMixin {
  @override
  Stream<void> get onConnectedStream => const Stream.empty();

  @override
  Stream<String> get onMessageStream => const Stream.empty();

  @override
  Stream<Uint8List> get onBinaryMessageStream => const Stream.empty();

  @override
  Stream<SocketXError> get onErrorStream => const Stream.empty();
}

// An implementation that extends SocketXClientPlatform without using
// MockPlatformInterfaceMixin. This is valid because extends calls the
// super constructor which stores the token.
class _ValidSubclass extends SocketXClientPlatform {
  @override
  Stream<void> get onConnectedStream => const Stream.empty();

  @override
  Stream<String> get onMessageStream => const Stream.empty();

  @override
  Stream<Uint8List> get onBinaryMessageStream => const Stream.empty();

  @override
  Stream<SocketXError> get onErrorStream => const Stream.empty();
}
