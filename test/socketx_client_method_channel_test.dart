// Tests for MethodChannelSocketXClient.
//
// Validates the method channel implementation by mocking the native side.
// Tests both outgoing method calls (Dart → Native) and incoming callbacks
// (Native → Dart) using Flutter's TestDefaultBinaryMessengerBinding.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mte_socketx/mte_socketx.dart';
import 'package:mte_socketx/mte_socketx_method_channel.dart';

import 'fixtures/test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelSocketXClient platform;

  // Track method calls made from Dart to native
  final List<MethodCall> nativeCalls = [];

  // Configurable response from native side
  dynamic nativeResponse;

  setUp(() {
    platform = MethodChannelSocketXClient();
    nativeCalls.clear();
    nativeResponse = null;

    // Mock the native side of the method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platform.methodChannel,
      (MethodCall methodCall) async {
        nativeCalls.add(methodCall);
        return nativeResponse;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, null);
  });

  // ---------------------------------------------------------------------------
  // Helper: Simulate a native callback (Native → Dart)
  // ---------------------------------------------------------------------------

  /// Simulates the native platform calling back into Dart via the method
  /// channel. This is how native code notifies Dart of events like
  /// onConnected, onMessage, onBinaryMessage, and onError.
  Future<void> simulateNativeCallback(String method,
      [dynamic arguments]) async {
    final ByteData message =
        const StandardMethodCodec().encodeMethodCall(
      MethodCall(method, arguments),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'socketx_client',
      message,
      (ByteData? reply) {},
    );
  }

  // ---------------------------------------------------------------------------
  // Outgoing Calls: connect
  // ---------------------------------------------------------------------------

  group('connect()', () {
    test('should invoke native connect with url', () async {
      await platform.connect(url: TestData.testUrl);

      expect(nativeCalls.length, 1);
      expect(nativeCalls.first.method, 'connect');
      expect(nativeCalls.first.arguments['url'], TestData.testUrl);
    });

    test('should include headers when provided', () async {
      await platform.connect(
        url: TestData.testUrl,
        headers: TestData.testHeaders,
      );

      expect(nativeCalls.first.arguments['headers'], TestData.testHeaders);
    });

    test('should pass null headers when not provided', () async {
      await platform.connect(url: TestData.testUrl);

      expect(nativeCalls.first.arguments['headers'], isNull);
    });

    test('should pass empty headers map when provided', () async {
      await platform.connect(
        url: TestData.testUrl,
        headers: TestData.emptyHeaders,
      );

      expect(nativeCalls.first.arguments['headers'], TestData.emptyHeaders);
    });
  });

  // ---------------------------------------------------------------------------
  // Outgoing Calls: disconnect
  // ---------------------------------------------------------------------------

  group('disconnect()', () {
    test('should invoke native disconnect', () async {
      await platform.disconnect();

      expect(nativeCalls.length, 1);
      expect(nativeCalls.first.method, 'disconnect');
    });
  });

  // ---------------------------------------------------------------------------
  // Outgoing Calls: sendText
  // ---------------------------------------------------------------------------

  group('sendText()', () {
    test('should invoke native sendText with text argument', () async {
      await platform.sendText(TestData.simpleMessage);

      expect(nativeCalls.length, 1);
      expect(nativeCalls.first.method, 'sendText');
      expect(nativeCalls.first.arguments['text'], TestData.simpleMessage);
    });

    test('should handle empty text', () async {
      await platform.sendText(TestData.emptyMessage);

      expect(nativeCalls.first.arguments['text'], '');
    });

    test('should handle special characters', () async {
      await platform.sendText(TestData.specialCharactersMessage);

      expect(
        nativeCalls.first.arguments['text'],
        TestData.specialCharactersMessage,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Outgoing Calls: sendBinary
  // ---------------------------------------------------------------------------

  group('sendBinary()', () {
    test('should invoke native sendBinary with data argument', () async {
      await platform.sendBinary(TestData.simpleBinary);

      expect(nativeCalls.length, 1);
      expect(nativeCalls.first.method, 'sendBinary');
      expect(nativeCalls.first.arguments['data'], TestData.simpleBinary);
    });

    test('should handle empty binary data', () async {
      await platform.sendBinary(TestData.emptyBinary);

      expect(nativeCalls.first.arguments['data'], TestData.emptyBinary);
    });
  });

  // ---------------------------------------------------------------------------
  // Outgoing Calls: getPlatformVersion
  // ---------------------------------------------------------------------------

  group('getPlatformVersion()', () {
    test('should invoke native getPlatformVersion', () async {
      nativeResponse = 'iOS 17.0';
      final version = await platform.getPlatformVersion();

      expect(nativeCalls.length, 1);
      expect(nativeCalls.first.method, 'getPlatformVersion');
      expect(version, 'iOS 17.0');
    });

    test('should return null when native returns null', () async {
      nativeResponse = null;
      final version = await platform.getPlatformVersion();

      expect(version, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Incoming Callbacks: onConnected
  // ---------------------------------------------------------------------------

  group('onConnected callback', () {
    test('should emit on onConnectedStream', () async {
      bool connected = false;
      platform.onConnectedStream.listen((_) => connected = true);

      await simulateNativeCallback('onConnected');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(connected, true);
    });

    test('should support multiple listeners', () async {
      int listenerCount = 0;
      platform.onConnectedStream.listen((_) => listenerCount++);
      platform.onConnectedStream.listen((_) => listenerCount++);

      await simulateNativeCallback('onConnected');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(listenerCount, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Incoming Callbacks: onMessage
  // ---------------------------------------------------------------------------

  group('onMessage callback', () {
    test('should emit text message on onMessageStream', () async {
      String? received;
      platform.onMessageStream.listen((msg) => received = msg);

      await simulateNativeCallback('onMessage', TestData.simpleMessage);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, TestData.simpleMessage);
    });

    test('should emit messages in order', () async {
      final messages = <String>[];
      platform.onMessageStream.listen(messages.add);

      await simulateNativeCallback('onMessage', 'first');
      await simulateNativeCallback('onMessage', 'second');
      await simulateNativeCallback('onMessage', 'third');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(messages, ['first', 'second', 'third']);
    });

    test('should handle special characters in message', () async {
      String? received;
      platform.onMessageStream.listen((msg) => received = msg);

      await simulateNativeCallback(
        'onMessage',
        TestData.specialCharactersMessage,
      );
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, TestData.specialCharactersMessage);
    });
  });

  // ---------------------------------------------------------------------------
  // Incoming Callbacks: onBinaryMessage
  // ---------------------------------------------------------------------------

  group('onBinaryMessage callback', () {
    test('should emit binary data on onBinaryMessageStream', () async {
      Uint8List? received;
      platform.onBinaryMessageStream.listen((data) => received = data);

      await simulateNativeCallback('onBinaryMessage', TestData.simpleBinary);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, TestData.simpleBinary);
    });
  });

  // ---------------------------------------------------------------------------
  // Incoming Callbacks: onError
  // ---------------------------------------------------------------------------

  group('onError callback', () {
    test('should emit SocketXError on onErrorStream', () async {
      SocketXError? received;
      platform.onErrorStream.listen((error) => received = error);

      await simulateNativeCallback('onError', TestData.networkErrorMap);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received, isNotNull);
      expect(received!.type, SocketXErrorType.network);
      expect(received!.reason, 'Connection refused');
    });

    test('should parse all error types correctly', () async {
      for (final errorMap in TestData.allErrorMaps) {
        SocketXError? received;
        platform.onErrorStream.listen((error) => received = error);

        await simulateNativeCallback('onError', errorMap);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(received, isNotNull,
            reason: 'Error not received for map: $errorMap');
        expect(received!.type.name, errorMap['type'],
            reason: 'Type mismatch for map: $errorMap');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Unknown Method Calls
  // ---------------------------------------------------------------------------

  group('Unknown native callbacks', () {
    test('should handle unknown method call without crashing', () async {
      // This should not throw — it just logs via debugPrint
      await expectLater(
        simulateNativeCallback('unknownMethod', 'some data'),
        completes,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Stream Behavior
  // ---------------------------------------------------------------------------

  group('Stream behavior', () {
    test('all streams are broadcast streams', () {
      // Broadcast streams can have multiple listeners
      // This would throw if they weren't broadcast streams
      platform.onConnectedStream.listen((_) {});
      platform.onConnectedStream.listen((_) {});

      platform.onMessageStream.listen((_) {});
      platform.onMessageStream.listen((_) {});

      platform.onBinaryMessageStream.listen((_) {});
      platform.onBinaryMessageStream.listen((_) {});

      platform.onErrorStream.listen((_) {});
      platform.onErrorStream.listen((_) {});
    });
  });
}
