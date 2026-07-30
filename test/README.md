# SocketX Client Flutter Plugin - Test Suite

## Quick Start

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/socketx_client_test.dart

# Run tests matching a pattern
flutter test --name "connect"
```

## Test Statistics

- **Total Tests**: 135 passing
- **Test Files**: 5
- **Coverage**: 100% (85/85 lines across all 3 library files)
- **Testing Approach**: Hand-written fakes (no mocking frameworks)

## Test Structure

```
test/
├── helpers/                                    # Test infrastructure
│   ├── fake_socketx_client_platform.dart       # Platform fake (40 tests)
│   └── fake_socketx_client_platform_test.dart  # Tests for the fake
│
├── fixtures/                                   # Test data
│   └── test_data.dart                          # URLs, messages, errors
│
├── socketx_error_test.dart                     # Error model (24 tests)
├── socketx_client_platform_interface_test.dart # Platform contract (8 tests)
├── socketx_client_method_channel_test.dart     # Native bridge (28 tests)
└── socketx_client_test.dart                    # Public API (35 tests)
```

## Test Infrastructure

### FakeSocketXClientPlatform (`test/helpers/fake_socketx_client_platform.dart`)

A controllable test double that simulates the native platform without requiring actual native code. This is the foundation of the test suite.

**Key Features**:
- **Failure flags**: Control when operations fail
- **Call tracking**: Verify what methods were called with what arguments
- **Stream simulation**: Manually trigger connection, message, and error events
- **Lifecycle management**: Reset state between tests, dispose streams

**Basic Usage**:

```dart
import 'package:socketx_client/socketx_client_platform_interface.dart';
import 'helpers/fake_socketx_client_platform.dart';

void main() {
  late FakeSocketXClientPlatform fake;
  
  setUp(() {
    fake = FakeSocketXClientPlatform();
    SocketXClientPlatform.instance = fake;
  });
  
  tearDown(() {
    fake.dispose();
  });
  
  test('example', () async {
    // Simulate successful connection
    await fake.connect(url: 'wss://example.com');
    fake.simulateConnected();
    
    // Simulate receiving a message
    fake.simulateMessage('Hello!');
    
    // Verify behavior
    expect(fake.connectCallCount, 1);
    expect(fake.lastConnectUrl, 'wss://example.com');
  });
}
```

**Simulating Events**:

```dart
// Connection events
fake.simulateConnected();
fake.simulateDisconnected();

// Message events (text)
fake.simulateMessage('Hello, World!');

// Message events (binary)
fake.simulateBinaryMessage(Uint8List.fromList([1, 2, 3]));

// Error events
fake.simulateError(TestData.networkError());
```

**Controlling Failures**:

```dart
// Make connect() throw
fake.shouldFailConnect = true;
fake.failureMessage = 'Connection refused';

// Make sendText() throw
fake.shouldFailSendText = true;

// Make sendBinary() throw  
fake.shouldFailSendBinary = true;

// Make disconnect() throw
fake.shouldFailDisconnect = true;
```

**Call Tracking**:

```dart
// Check what was called
expect(fake.connectCallCount, 2);
expect(fake.sendTextCallCount, 5);
expect(fake.disconnectCallCount, 1);

// Check arguments
expect(fake.lastConnectUrl, 'wss://example.com');
expect(fake.lastConnectHeaders, {'Auth': 'Bearer token'});
expect(fake.lastSentText, 'Hello');

// Check message history
expect(fake.sentTextMessages, ['msg1', 'msg2', 'msg3']);
expect(fake.sentBinaryMessages.length, 2);
```

**Lifecycle**:

```dart
// Reset between tests (clears counters, doesn't close streams)
fake.reset();

// Dispose streams when done
fake.dispose();
```

### TestData (`test/fixtures/test_data.dart`)

Centralized test data to keep tests clean and avoid hardcoded values.

**URLs**:
```dart
TestData.testUrl                 // 'wss://dev-socketx-server.eclypses.com'
TestData.testUrlWithRoom         // includes /dogs path
TestData.testUrlWithPort         // includes port :8080
```

**Headers**:
```dart
TestData.testHeaders             // Auth + custom header
TestData.emptyHeaders            // {}
TestData.singleHeader            // Just auth
```

**Text Messages**:
```dart
TestData.simpleMessage           // 'Hello, SocketX!'
TestData.emptyMessage            // ''
TestData.specialCharactersMessage // Unicode, emojis, symbols
TestData.longMessage             // 10,000 characters
TestData.jsonMessage             // Valid JSON string
TestData.multilineMessage        // Multi-line text
TestData.sampleMessages(100)     // Generate N messages
```

**Binary Data**:
```dart
TestData.simpleBinary            // Uint8List with simple bytes
TestData.emptyBinary             // Empty Uint8List
TestData.largeBinary             // 100KB of data
TestData.utf8Binary              // Text encoded as UTF-8 bytes
TestData.sampleBinaryMessages(50) // Generate N binary messages
```

**Error Maps**:
```dart
// All 7 error types
TestData.unknownError()
TestData.connectionFailedError()
TestData.invalidUrlError()
TestData.networkError()
TestData.authenticationError()
TestData.timeoutError()
TestData.sendFailedError()

// Edge cases
TestData.malformedErrorMap()     // Invalid structure
TestData.emptyErrorMap()         // {}
```

**SocketXError Factories**:
```dart
TestData.unknownSocketXError()
TestData.connectionFailedSocketXError()
TestData.networkSocketXError()
// etc...
```

## Writing Tests

### Testing the Public API (`socketx_client_test.dart`)

Tests that verify the `SocketXClient` correctly delegates to the platform interface.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:socketx_client/socketx_client.dart';
import 'package:socketx_client/socketx_client_platform_interface.dart';
import 'fixtures/test_data.dart';
import 'helpers/fake_socketx_client_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSocketXClientPlatform fake;
  late SocketXClient client;

  setUp(() {
    fake = FakeSocketXClientPlatform();
    SocketXClientPlatform.instance = fake;
    client = SocketXClient();
  });

  tearDown(() {
    fake.dispose();
  });

  test('should connect with url and headers', () async {
    await client.connect(
      url: TestData.testUrl,
      headers: TestData.testHeaders,
    );

    expect(fake.connectCallCount, 1);
    expect(fake.lastConnectUrl, TestData.testUrl);
    expect(fake.lastConnectHeaders, TestData.testHeaders);
  });
}
```

### Testing Method Channel (`socketx_client_method_channel_test.dart`)

Tests that verify the Dart-to-Native bridge using Flutter's `TestDefaultBinaryMessengerBinding`.

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socketx_client/socketx_client_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final channel = MethodChannelSocketXClient();
  final List<MethodCall> log = [];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel.methodChannel, (call) async {
      log.add(call);
      return null; // or return appropriate value
    });
  });

  test('should invoke connect method', () async {
    await channel.connect(url: 'wss://test.com', headers: {});

    expect(log.length, 1);
    expect(log[0].method, 'connect');
    expect(log[0].arguments['url'], 'wss://test.com');
  });
}
```

### Testing Error Models (`socketx_error_test.dart`)

Tests for the `SocketXError` class and `SocketXErrorType` enum.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:socketx_client/socketx_client.dart';
import 'fixtures/test_data.dart';

void main() {
  group('SocketXError.fromMap()', () {
    test('should parse network error', () {
      final error = SocketXError.fromMap(TestData.networkError());

      expect(error.type, SocketXErrorType.network);
      expect(error.message, 'Network error');
    });

    test('should handle unknown error type', () {
      final error = SocketXError.fromMap({'type': 'weird', 'message': 'oops'});

      expect(error.type, SocketXErrorType.unknown);
    });
  });
}
```

## Common Testing Patterns

### Testing Async Streams

Streams emit asynchronously. Always add a small delay after simulation before asserting.

```dart
test('should receive messages on stream', () async {
  final messages = <String>[];
  fake.onMessage.listen(messages.add);

  fake.simulateMessage('Hello');
  fake.simulateMessage('World');
  
  // Critical: Wait for async stream propagation
  await Future.delayed(Duration(milliseconds: 10));

  expect(messages, ['Hello', 'World']);
});
```

### Testing Error Handling

```dart
test('should throw when connection fails', () async {
  fake.shouldFailConnect = true;
  fake.failureMessage = 'Connection refused';

  expect(
    () => client.connect(url: TestData.testUrl),
    throwsA(isA<PlatformException>()),
  );
});
```

### Testing Stream Disposal

```dart
test('should close streams on dispose', () async {
  var streamClosed = false;
  fake.onConnected.listen((_) {}, onDone: () => streamClosed = true);

  fake.dispose();
  await Future.delayed(Duration(milliseconds: 10));

  expect(streamClosed, true);
});
```

### Testing Call Sequences

```dart
test('should track multiple operations', () async {
  await client.connect(url: TestData.testUrl);
  await client.sendText('msg1');
  await client.sendText('msg2');
  await client.disconnect();

  expect(fake.connectCallCount, 1);
  expect(fake.sendTextCallCount, 2);
  expect(fake.disconnectCallCount, 1);
  expect(fake.sentTextMessages, ['msg1', 'msg2']);
});
```

## Best Practices

✅ **DO**:
- Use `TestData` for all test data (don't hardcode values)
- Always call `fake.dispose()` in `tearDown()`
- Add `await Future.delayed()` after stream simulations
- Test behavior, not implementation details
- Use descriptive test names that explain the scenario
- Follow Arrange-Act-Assert pattern
- Test both success and failure paths
- Verify call counts and arguments with the fake

❌ **DON'T**:
- Test private methods or internal implementation
- Skip the delay after stream events (causes flaky tests)
- Rely on external servers or services
- Create test interdependencies (each test isolated)
- Hardcode test data (use fixtures)
- Forget to reset or dispose the fake
- Test the same thing multiple times at different layers

## Coverage

Generate and view coverage reports:

```bash
# Generate coverage data
flutter test --coverage

# View summary (requires lcov)
lcov --summary coverage/lcov.info

# Generate HTML report (requires genhtml)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Current Coverage**: 100% (85/85 lines)

## Testing Philosophy

### Hand-Written Fakes Over Mocking Frameworks

This test suite uses a hand-written `FakeSocketXClientPlatform` instead of a mocking framework (like Mockito). Why?

- **Better control** over async/stream behavior
- **Easier to debug** when tests fail
- **Self-documenting** through explicit methods
- **Validated** by 40 dedicated tests on the fake itself

### Layered Testing Approach

Tests are organized in layers, each independently verifiable:

1. **Error models** (`socketx_error_test.dart`) - Pure Dart, no platform
2. **Platform interface** (`socketx_client_platform_interface_test.dart`) - Contract
3. **Method channel** (`socketx_client_method_channel_test.dart`) - Dart ↔ Native bridge
4. **Public API** (`socketx_client_test.dart`) - What users actually call

### Test the Fake First

The fake itself has 40 tests proving it works correctly. Bugs in test infrastructure produce false positives across the entire suite, so the fake must be rock-solid.

## Troubleshooting

### Test Times Out

- Ensure `await` before all async operations
- Add `await Future.delayed()` after stream simulations
- Check for unclosed streams or futures that never complete

### Streams Not Emitting

- Add `await Future.delayed(Duration(milliseconds: 10))` after `simulate*()` calls
- Verify stream listener was set up before simulation
- Check that fake wasn't disposed before assertion

### Platform Not Found

- Ensure `TestWidgetsFlutterBinding.ensureInitialized()` called
- Verify fake was assigned to `SocketXClientPlatform.instance` in `setUp()`

### Flaky Tests

- Usually caused by missing `await Future.delayed()` after stream events
- Ensure proper test isolation with `setUp()`/`tearDown()`
- Don't share state between tests

## Additional Resources

- [Flutter Plugin Testing](https://docs.flutter.dev/testing/testing-plugins)
- [Method Channel Testing](https://docs.flutter.dev/development/platform-integration/platform-channels?tab=type-safe-kotlin-tab#testing)
- [TESTING_SUMMARY.md](../dev_docs/TESTING_SUMMARY.md) - Detailed test architecture and patterns
- [LIBRARY_CONTEXT.md](../dev_docs/LIBRARY_CONTEXT.md) - Complete plugin architecture

---

Run `flutter test` to verify all 135 tests pass! ✅
