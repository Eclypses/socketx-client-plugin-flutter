// Tests for FakeSocketXClientPlatform.
//
// Validates our test infrastructure before relying on it in other test files.
// Every behavior of the fake — failure flags, call tracking, stream simulation,
// reset, and dispose — is verified here.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mte_socketx/mte_socketx.dart';

import '../fixtures/test_data.dart';
import 'fake_socketx_client_platform.dart';

void main() {
  late FakeSocketXClientPlatform fake;

  setUp(() {
    fake = FakeSocketXClientPlatform();
  });

  tearDown(() {
    fake.dispose();
  });

  // ---------------------------------------------------------------------------
  // Connection Lifecycle
  // ---------------------------------------------------------------------------

  group('Connection lifecycle', () {
    test('should complete connect successfully by default', () async {
      await expectLater(
        fake.connect(url: TestData.testUrl),
        completes,
      );
    });

    test('should track connect URL', () async {
      await fake.connect(url: TestData.testUrl);

      expect(fake.lastConnectUrl, TestData.testUrl);
    });

    test('should track connect headers', () async {
      await fake.connect(url: TestData.testUrl, headers: TestData.testHeaders);

      expect(fake.lastConnectHeaders, TestData.testHeaders);
    });

    test('should track null headers when none provided', () async {
      await fake.connect(url: TestData.testUrl);

      expect(fake.lastConnectHeaders, isNull);
    });

    test('should increment connect call count', () async {
      await fake.connect(url: TestData.testUrl);
      await fake.connect(url: TestData.testUrlWithRoom);

      expect(fake.connectCallCount, 2);
    });

    test('should complete disconnect successfully by default', () async {
      await expectLater(fake.disconnect(), completes);
    });

    test('should increment disconnect call count', () async {
      await fake.disconnect();
      await fake.disconnect();

      expect(fake.disconnectCallCount, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Failure Modes
  // ---------------------------------------------------------------------------

  group('Failure modes', () {
    test('should throw on connect when shouldFailConnect is true', () async {
      fake.shouldFailConnect = true;

      expect(
        () => fake.connect(url: TestData.testUrl),
        throwsException,
      );
    });

    test('should not increment connect count on failure', () async {
      fake.shouldFailConnect = true;

      try {
        await fake.connect(url: TestData.testUrl);
      } catch (_) {}

      expect(fake.connectCallCount, 0);
    });

    test('should throw on disconnect when shouldFailDisconnect is true',
        () async {
      fake.shouldFailDisconnect = true;

      expect(() => fake.disconnect(), throwsException);
    });

    test('should throw on sendText when shouldFailSendText is true', () async {
      fake.shouldFailSendText = true;

      expect(
        () => fake.sendText(TestData.simpleMessage),
        throwsException,
      );
    });

    test('should not track message on sendText failure', () async {
      fake.shouldFailSendText = true;

      try {
        await fake.sendText(TestData.simpleMessage);
      } catch (_) {}

      expect(fake.sendTextCallCount, 0);
      expect(fake.sentTextMessages, isEmpty);
    });

    test('should throw on sendBinary when shouldFailSendBinary is true',
        () async {
      fake.shouldFailSendBinary = true;

      expect(
        () => fake.sendBinary(TestData.simpleBinary),
        throwsException,
      );
    });

    test('should use custom failure message', () async {
      fake.shouldFailConnect = true;
      fake.failureMessage = 'Custom error';

      expect(
        () => fake.connect(url: TestData.testUrl),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Custom error'),
          ),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Send Text Tracking
  // ---------------------------------------------------------------------------

  group('Send text tracking', () {
    test('should track last sent text message', () async {
      await fake.sendText(TestData.simpleMessage);

      expect(fake.lastSentText, TestData.simpleMessage);
    });

    test('should add to sentTextMessages list', () async {
      await fake.sendText('Message 1');
      await fake.sendText('Message 2');

      expect(fake.sentTextMessages, ['Message 1', 'Message 2']);
    });

    test('should increment sendText call count', () async {
      await fake.sendText('A');
      await fake.sendText('B');
      await fake.sendText('C');

      expect(fake.sendTextCallCount, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // Send Binary Tracking
  // ---------------------------------------------------------------------------

  group('Send binary tracking', () {
    test('should track last sent binary data', () async {
      await fake.sendBinary(TestData.simpleBinary);

      expect(fake.lastSentBinary, TestData.simpleBinary);
    });

    test('should add to sentBinaryMessages list', () async {
      final data1 = Uint8List.fromList([1, 2]);
      final data2 = Uint8List.fromList([3, 4]);
      await fake.sendBinary(data1);
      await fake.sendBinary(data2);

      expect(fake.sentBinaryMessages.length, 2);
      expect(fake.sentBinaryMessages[0], data1);
      expect(fake.sentBinaryMessages[1], data2);
    });

    test('should increment sendBinary call count', () async {
      await fake.sendBinary(TestData.simpleBinary);

      expect(fake.sendBinaryCallCount, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Platform Version
  // ---------------------------------------------------------------------------

  group('getPlatformVersion', () {
    test('should return default platform version', () async {
      final version = await fake.getPlatformVersion();

      expect(version, '1.0.0-test');
    });

    test('should return custom platform version', () async {
      fake.platformVersionResponse = '2.5.0';

      expect(await fake.getPlatformVersion(), '2.5.0');
    });

    test('should return null when configured', () async {
      fake.platformVersionResponse = null;

      expect(await fake.getPlatformVersion(), isNull);
    });

    test('should increment call count', () async {
      await fake.getPlatformVersion();
      await fake.getPlatformVersion();

      expect(fake.getPlatformVersionCallCount, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Stream Simulation
  // ---------------------------------------------------------------------------

  group('Stream simulation', () {
    test('should emit on onConnectedStream when simulateConnected is called',
        () async {
      bool connected = false;
      fake.onConnectedStream.listen((_) => connected = true);

      fake.simulateConnected();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(connected, true);
    });

    test('should emit message on onMessageStream', () async {
      String? received;
      fake.onMessageStream.listen((msg) => received = msg);

      fake.simulateMessage(TestData.simpleMessage);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, TestData.simpleMessage);
    });

    test('should emit binary data on onBinaryMessageStream', () async {
      Uint8List? received;
      fake.onBinaryMessageStream.listen((data) => received = data);

      fake.simulateBinaryMessage(TestData.simpleBinary);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, TestData.simpleBinary);
    });

    test('should emit error on onErrorStream', () async {
      SocketXError? received;
      fake.onErrorStream.listen((error) => received = error);

      final error = TestData.networkError();
      fake.simulateError(error);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, isNotNull);
      expect(received!.type, SocketXErrorType.network);
      expect(received!.reason, 'Connection refused');
    });

    test('should support multiple listeners on broadcast streams', () async {
      String? listener1;
      String? listener2;
      fake.onMessageStream.listen((msg) => listener1 = msg);
      fake.onMessageStream.listen((msg) => listener2 = msg);

      fake.simulateMessage('broadcast test');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(listener1, 'broadcast test');
      expect(listener2, 'broadcast test');
    });

    test('should emit events in order', () async {
      final messages = <String>[];
      fake.onMessageStream.listen(messages.add);

      fake.simulateMessage('first');
      fake.simulateMessage('second');
      fake.simulateMessage('third');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(messages, ['first', 'second', 'third']);
    });
  });

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  group('reset()', () {
    test('should clear all call counts', () async {
      await fake.connect(url: TestData.testUrl);
      await fake.disconnect();
      await fake.sendText('test');
      await fake.sendBinary(TestData.simpleBinary);
      await fake.getPlatformVersion();

      fake.reset();

      expect(fake.connectCallCount, 0);
      expect(fake.disconnectCallCount, 0);
      expect(fake.sendTextCallCount, 0);
      expect(fake.sendBinaryCallCount, 0);
      expect(fake.getPlatformVersionCallCount, 0);
    });

    test('should clear captured arguments', () async {
      await fake.connect(url: TestData.testUrl, headers: TestData.testHeaders);
      await fake.sendText('test');
      await fake.sendBinary(TestData.simpleBinary);

      fake.reset();

      expect(fake.lastConnectUrl, isNull);
      expect(fake.lastConnectHeaders, isNull);
      expect(fake.lastSentText, isNull);
      expect(fake.lastSentBinary, isNull);
      expect(fake.sentTextMessages, isEmpty);
      expect(fake.sentBinaryMessages, isEmpty);
    });

    test('should clear failure flags', () {
      fake.shouldFailConnect = true;
      fake.shouldFailDisconnect = true;
      fake.shouldFailSendText = true;
      fake.shouldFailSendBinary = true;
      fake.failureMessage = 'custom';

      fake.reset();

      expect(fake.shouldFailConnect, false);
      expect(fake.shouldFailDisconnect, false);
      expect(fake.shouldFailSendText, false);
      expect(fake.shouldFailSendBinary, false);
      expect(fake.failureMessage, 'Simulated failure');
    });

    test('should reset platform version response', () async {
      fake.platformVersionResponse = 'custom';
      fake.reset();

      expect(await fake.getPlatformVersion(), '1.0.0-test');
    });

    test('should keep streams functional after reset', () async {
      fake.reset();

      String? received;
      fake.onMessageStream.listen((msg) => received = msg);
      fake.simulateMessage('after reset');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, 'after reset');
    });
  });

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  group('dispose()', () {
    test('should close onConnectedStream', () async {
      bool done = false;
      fake.onConnectedStream.listen((_) {}, onDone: () => done = true);

      fake.dispose();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(done, true);
    });

    test('should close onMessageStream', () async {
      bool done = false;
      fake.onMessageStream.listen((_) {}, onDone: () => done = true);

      fake.dispose();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(done, true);
    });

    test('should close onBinaryMessageStream', () async {
      bool done = false;
      fake.onBinaryMessageStream.listen((_) {}, onDone: () => done = true);

      fake.dispose();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(done, true);
    });

    test('should close onErrorStream', () async {
      bool done = false;
      fake.onErrorStream.listen((_) {}, onDone: () => done = true);

      fake.dispose();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(done, true);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge Cases
  // ---------------------------------------------------------------------------

  group('Edge cases', () {
    test('should handle rapid connect/disconnect cycles', () async {
      for (int i = 0; i < 10; i++) {
        await fake.connect(url: TestData.testUrl);
        await fake.disconnect();
      }

      expect(fake.connectCallCount, 10);
      expect(fake.disconnectCallCount, 10);
    });

    test('should handle empty text message', () async {
      await fake.sendText(TestData.emptyMessage);

      expect(fake.lastSentText, '');
      expect(fake.sendTextCallCount, 1);
    });

    test('should handle empty binary data', () async {
      await fake.sendBinary(TestData.emptyBinary);

      expect(fake.lastSentBinary, TestData.emptyBinary);
      expect(fake.sendBinaryCallCount, 1);
    });

    test('should handle special characters in text', () async {
      await fake.sendText(TestData.specialCharactersMessage);

      expect(fake.lastSentText, TestData.specialCharactersMessage);
    });

    test('should handle large binary payload', () async {
      final largeData = TestData.largeBinary(10000);
      await fake.sendBinary(largeData);

      expect(fake.lastSentBinary!.length, 10000);
    });

    test('should handle high message throughput', () async {
      final messages = TestData.sampleMessages(100);
      for (final msg in messages) {
        await fake.sendText(msg);
      }

      expect(fake.sendTextCallCount, 100);
      expect(fake.sentTextMessages.length, 100);
    });
  });
}
