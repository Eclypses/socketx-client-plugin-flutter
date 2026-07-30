// Tests for SocketXClient (the public API).
//
// Validates that the public API correctly delegates to the platform interface.
// Uses FakeSocketXClientPlatform to verify behavior without native code.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:socketx_client/socketx_client.dart';
import 'package:socketx_client/socketx_client_platform_interface.dart';

import 'fixtures/test_data.dart';
import 'helpers/fake_socketx_client_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSocketXClientPlatform fake;
  late SocketXClient client;

  // Store original so we can restore it.
  final originalInstance = SocketXClientPlatform.instance;

  setUp(() {
    fake = FakeSocketXClientPlatform();
    SocketXClientPlatform.instance = fake;
    client = SocketXClient();
  });

  tearDown(() {
    fake.dispose();
    SocketXClientPlatform.instance = originalInstance;
  });

  // ---------------------------------------------------------------------------
  // connect()
  // ---------------------------------------------------------------------------

  group('connect()', () {
    test('should delegate to platform with url', () async {
      await client.connect(url: TestData.testUrl);

      expect(fake.connectCallCount, 1);
      expect(fake.lastConnectUrl, TestData.testUrl);
    });

    test('should delegate to platform with url and headers', () async {
      await client.connect(
        url: TestData.testUrl,
        headers: TestData.testHeaders,
      );

      expect(fake.lastConnectUrl, TestData.testUrl);
      expect(fake.lastConnectHeaders, TestData.testHeaders);
    });

    test('should pass null headers when not provided', () async {
      await client.connect(url: TestData.testUrl);

      expect(fake.lastConnectHeaders, isNull);
    });

    test('should propagate platform exceptions', () async {
      fake.shouldFailConnect = true;

      expect(
        () => client.connect(url: TestData.testUrl),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // disconnect()
  // ---------------------------------------------------------------------------

  group('disconnect()', () {
    test('should delegate to platform', () async {
      await client.disconnect();

      expect(fake.disconnectCallCount, 1);
    });

    test('should propagate platform exceptions', () async {
      fake.shouldFailDisconnect = true;

      expect(() => client.disconnect(), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // send()
  // ---------------------------------------------------------------------------

  group('send()', () {
    test('should delegate to platform sendText', () async {
      await client.send(text: TestData.simpleMessage);

      expect(fake.sendTextCallCount, 1);
      expect(fake.lastSentText, TestData.simpleMessage);
    });

    test('should handle empty text', () async {
      await client.send(text: TestData.emptyMessage);

      expect(fake.lastSentText, '');
    });

    test('should handle special characters', () async {
      await client.send(text: TestData.specialCharactersMessage);

      expect(fake.lastSentText, TestData.specialCharactersMessage);
    });

    test('should propagate platform exceptions', () async {
      fake.shouldFailSendText = true;

      expect(
        () => client.send(text: TestData.simpleMessage),
        throwsException,
      );
    });

    test('should track multiple sends in order', () async {
      await client.send(text: 'Message 1');
      await client.send(text: 'Message 2');
      await client.send(text: 'Message 3');

      expect(fake.sentTextMessages, ['Message 1', 'Message 2', 'Message 3']);
    });
  });

  // ---------------------------------------------------------------------------
  // sendBinary()
  // ---------------------------------------------------------------------------

  group('sendBinary()', () {
    test('should delegate to platform sendBinary', () async {
      await client.sendBinary(binary: TestData.simpleBinary);

      expect(fake.sendBinaryCallCount, 1);
      expect(fake.lastSentBinary, TestData.simpleBinary);
    });

    test('should handle empty binary data', () async {
      await client.sendBinary(binary: TestData.emptyBinary);

      expect(fake.lastSentBinary, TestData.emptyBinary);
    });

    test('should handle large binary data', () async {
      final largeData = TestData.largeBinary(10000);
      await client.sendBinary(binary: largeData);

      expect(fake.lastSentBinary!.length, 10000);
    });

    test('should propagate platform exceptions', () async {
      fake.shouldFailSendBinary = true;

      expect(
        () => client.sendBinary(binary: TestData.simpleBinary),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getPlatformVersion()
  // ---------------------------------------------------------------------------

  group('getPlatformVersion()', () {
    test('should return platform version', () async {
      final version = await client.getPlatformVersion();

      expect(version, '1.0.0-test');
    });

    test('should return null when platform returns null', () async {
      fake.platformVersionResponse = null;

      final version = await client.getPlatformVersion();

      expect(version, isNull);
    });

    test('should return custom version', () async {
      fake.platformVersionResponse = 'Android 14';

      final version = await client.getPlatformVersion();

      expect(version, 'Android 14');
    });
  });

  // ---------------------------------------------------------------------------
  // Event Streams
  // ---------------------------------------------------------------------------

  group('onConnected stream', () {
    test('should route events from platform', () async {
      bool connected = false;
      client.onConnected.listen((_) => connected = true);

      fake.simulateConnected();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(connected, true);
    });

    test('should support multiple listeners', () async {
      int count = 0;
      client.onConnected.listen((_) => count++);
      client.onConnected.listen((_) => count++);

      fake.simulateConnected();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(count, 2);
    });
  });

  group('onMessage stream', () {
    test('should route text messages from platform', () async {
      String? received;
      client.onMessage.listen((msg) => received = msg);

      fake.simulateMessage(TestData.simpleMessage);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, TestData.simpleMessage);
    });

    test('should deliver messages in order', () async {
      final messages = <String>[];
      client.onMessage.listen(messages.add);

      fake.simulateMessage('first');
      fake.simulateMessage('second');
      fake.simulateMessage('third');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(messages, ['first', 'second', 'third']);
    });
  });

  group('onBinaryMessage stream', () {
    test('should route binary data from platform', () async {
      Uint8List? received;
      client.onBinaryMessage.listen((data) => received = data);

      fake.simulateBinaryMessage(TestData.simpleBinary);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, TestData.simpleBinary);
    });
  });

  group('onError stream', () {
    test('should route errors from platform', () async {
      SocketXError? received;
      client.onError.listen((error) => received = error);

      fake.simulateError(TestData.networkError());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, isNotNull);
      expect(received!.type, SocketXErrorType.network);
      expect(received!.reason, 'Connection refused');
    });

    test('should route all error types', () async {
      final errors = <SocketXError>[];
      client.onError.listen(errors.add);

      fake.simulateError(TestData.networkError());
      fake.simulateError(TestData.handshakeError());
      fake.simulateError(TestData.codecError());
      await Future.delayed(const Duration(milliseconds: 10));

      expect(errors.length, 3);
      expect(errors[0].type, SocketXErrorType.network);
      expect(errors[1].type, SocketXErrorType.handshake);
      expect(errors[2].type, SocketXErrorType.codec);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge Cases / Integration Scenarios
  // ---------------------------------------------------------------------------

  group('Edge cases', () {
    test('should handle connect then send workflow', () async {
      await client.connect(url: TestData.testUrl);
      await client.send(text: TestData.simpleMessage);

      expect(fake.connectCallCount, 1);
      expect(fake.sendTextCallCount, 1);
    });

    test('should handle connect then disconnect then reconnect', () async {
      await client.connect(url: TestData.testUrl);
      await client.disconnect();
      await client.connect(url: TestData.testUrlWithRoom);

      expect(fake.connectCallCount, 2);
      expect(fake.disconnectCallCount, 1);
      expect(fake.lastConnectUrl, TestData.testUrlWithRoom);
    });

    test('should handle rapid sends', () async {
      for (int i = 0; i < 50; i++) {
        await client.send(text: 'Message $i');
      }

      expect(fake.sendTextCallCount, 50);
      expect(fake.sentTextMessages.length, 50);
    });

    test('should handle interleaved text and binary sends', () async {
      await client.send(text: 'text1');
      await client.sendBinary(binary: TestData.simpleBinary);
      await client.send(text: 'text2');
      await client.sendBinary(binary: TestData.singleByteBinary);

      expect(fake.sendTextCallCount, 2);
      expect(fake.sendBinaryCallCount, 2);
      expect(fake.sentTextMessages, ['text1', 'text2']);
    });
  });
}
