<center>
<img src="Eclypses.png" style="width:50%;" alt="Eclypses Logo"/>
</center>

<div align="center" style="font-size:40pt; font-weight:900; font-family:arial; margin-top:50px;" >
SocketX Client Flutter Plugin</div>
<br>

### This Flutter plugin provides secure WebSocket communication with automatic MTE encryption for iOS and Android applications. It enables real-time, bidirectional messaging between Flutter apps and SocketX servers with minimal code and maximum security.

---

## 📑 Table of Contents

- [Overview](#overview)
- [Before You Begin](#before-you-begin)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)
- [Contact Eclypses](#contact-eclypses) 
<br><br>

## Overview 

SocketX Client is a Flutter plugin that simplifies secure WebSocket communication with automatic Message Tailoring Engine (MTE) encryption. When integrated into your Flutter application:

- **Secure WebSocket Connections**: Establishes WSS connections with automatic MTE encryption/decryption
- **Simple Event-Driven API**: Listen for connection events, messages, and errors through reactive streams
- **Binary & Text Support**: Send and receive both text and binary messages seamlessly
- **Cross-Platform**: Works on both iOS and Android with native performance
- **Minimal Configuration**: Connect with just a URL - the plugin handles the complexity

This plugin requires a SocketX server instance that supports the MTE protocol for encoding/decoding messages.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

<br>

## Before You Begin

Ensure you have the following ready before integrating this plugin:

- [ ] **SocketX Server Access** - A running SocketX server instance with WebSocket endpoint URL
- [ ] **Flutter SDK** - Latest stable version installed (\`flutter --version\` to check)
- [ ] **Xcode** - Latest version for iOS development (macOS only)
- [ ] **Android Studio** - For Android development with SDK tools installed (Android SDK 26+ required)

> 💡 **Tip:** Run \`flutter doctor\` to verify your development environment is properly configured.

<br>

## Installation

### Step 1: Add the Plugin Dependency

Add the plugin to your \`pubspec.yaml\` file:

> ⚠️ **Important:** YAML indentation is critical! Use exactly 2 or 4 spaces (be consistent), never tabs.

```yaml
dependencies:
  flutter:
    sdk: flutter
  socketx_client:
    git:
      url: https://github.com/Eclypses/socketx-client-plugin-flutter.git
      ref: v2.0.0
```

> ⚠️ **Requirements:**
> - **iOS**: Requires iOS 16.0 or greater
> - **Android**: Requires minSdk 26 (Android 8.0) or greater

### Step 2: Install Dependencies

Run this command in your project root:

```bash
flutter pub get
```

This downloads the SocketX Client Plugin and its dependencies.

<br>

## Quick Start

### Step 1: Import the Plugin

```dart
import 'package:socketx_client/socketx_client.dart';
import 'dart:typed_data';  // For binary message handling
```

### Step 2: Create a SocketX Client Instance

```dart
final _socketXClient = SocketXClient();
```

### Step 3: Set Up Event Listeners

Subscribe to the event streams to handle WebSocket events:

```dart
@override
void initState() {
  super.initState();
  
  // Listen for connection established
  _socketXClient.onConnected.listen((_) {
    print('Connected to SocketX server!');
    setState(() => _isConnected = true);
  });
  
  // Listen for text messages
  _socketXClient.onMessage.listen((message) {
    print('Received text: $message');
  });
  
  // Listen for binary messages
  _socketXClient.onBinaryMessage.listen((data) {
    print('Received binary: ${data.length} bytes');
  });
  
  // Listen for errors
  _socketXClient.onError.listen((error) {
    print('Error: ${error.message} (${error.type})');
    setState(() => _isConnected = false);
  });
}
```

### Step 4: Connect to the Server

```dart
Future<void> connectToServer() async {
  try {
    await _socketXClient.connect(
      url: 'wss://your-socketx-server.com/room',
      headers: {
        'Authorization': 'Bearer your-token',  // Optional
      },
    );
  } catch (e) {
    print('Connection failed: $e');
  }
}
```

### Step 5: Send Messages

```dart
// Send text message
_socketXClient.send(text: 'Hello, server!');

// Send binary message
_socketXClient.send(binary: Uint8List.fromList([0x01, 0x02, 0x03]));
```

### Step 6: Disconnect When Done

```dart
@override
void dispose() {
  _socketXClient.disconnect();
  super.dispose();
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:socketx_client/socketx_client.dart';
import 'dart:typed_data';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _socketXClient = SocketXClient();
  final _messageController = TextEditingController();
  final List<String> _messages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _connect();
  }

  void _setupListeners() {
    _socketXClient.onConnected.listen((_) {
      setState(() => _isConnected = true);
    });

    _socketXClient.onMessage.listen((message) {
      setState(() => _messages.add('Received: $message'));
    });

    _socketXClient.onError.listen((error) {
      setState(() {
        _isConnected = false;
        _messages.add('Error: ${error.message}');
      });
    });
  }

  Future<void> _connect() async {
    await _socketXClient.connect(
      url: 'wss://dev-socketx-server.eclypses.com',
    );
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _socketXClient.send(text: _messageController.text);
      setState(() => _messages.add('Sent: ${_messageController.text}'));
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _socketXClient.disconnect();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SocketX Chat'),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_messages[index]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isConnected ? _sendMessage : null,
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## API Reference

### SocketXClient Class

The main class for WebSocket communication with MTE encryption.

#### Connection Methods

##### connect()
Establishes a WebSocket connection to the specified URL.

```dart
Future<void> connect({
  required String url,
  Map<String, String>? headers,
})
```

**Parameters:**
- \`url\` (required): WebSocket URL (e.g., 'wss://example.com/room')
- \`headers\` (optional): HTTP headers to include in the connection request

**Example:**
```dart
await _socketXClient.connect(
  url: 'wss://dev-socketx-server.eclypses.com/chat',
  headers: {'Authorization': 'Bearer token123'},
);
```

##### disconnect()
Closes the WebSocket connection.

```dart
void disconnect()
```

**Example:**
```dart
_socketXClient.disconnect();
```

#### Messaging Methods

##### send()
Sends a message through the WebSocket. Provide either \`text\` or \`binary\`, not both.

```dart
void send({String? text, Uint8List? binary})
```

**Parameters:**
- \`text\` (optional): Text message to send
- \`binary\` (optional): Binary data to send as Uint8List

**Examples:**
```dart
// Send text
_socketXClient.send(text: 'Hello, world!');

// Send binary
_socketXClient.send(binary: Uint8List.fromList([0xFF, 0xAA, 0x55]));
```

#### Event Streams

All events are exposed as broadcast streams for reactive programming.

##### onConnected
Emitted when the WebSocket connection is successfully established.

```dart
Stream<void> get onConnected
```

**Example:**
```dart
_socketXClient.onConnected.listen((_) {
  print('Connected to server');
});
```

##### onMessage
Emitted when a text message is received from the server.

```dart
Stream<String> get onMessage
```

**Example:**
```dart
_socketXClient.onMessage.listen((message) {
  print('Received: $message');
});
```

##### onBinaryMessage
Emitted when binary data is received from the server.

```dart
Stream<Uint8List> get onBinaryMessage
```

**Example:**
```dart
_socketXClient.onBinaryMessage.listen((data) {
  print('Received ${data.length} bytes');
});
```

##### onError
Emitted when an error occurs during connection or communication.

```dart
Stream<SocketXError> get onError
```

**Example:**
```dart
_socketXClient.onError.listen((error) {
  print('Error: ${error.message}');
  print('Type: ${error.type}');
});
```

### SocketXError Class

Represents an error that occurred during WebSocket operations.

**Properties:**
- \`message\` (String): Human-readable error description
- \`type\` (SocketXErrorType): Category of the error

**Error Types:**
- \`SocketXErrorType.connection\`: Connection-related errors
- \`SocketXErrorType.encoding\`: MTE encoding errors
- \`SocketXErrorType.decoding\`: MTE decoding errors
- \`SocketXErrorType.unknown\`: Other errors

---

## Advanced Usage

### Handling Multiple Rooms

Connect to different SocketX server rooms by changing the URL:

```dart
String selectedRoom = 'chat';
String baseUrl = 'wss://dev-socketx-server.eclypses.com';

Future<void> switchRoom(String room) async {
  // Disconnect from current room
  _socketXClient.disconnect();
  
  // Connect to new room
  String url = room.isEmpty ? baseUrl : '$baseUrl/$room';
  await _socketXClient.connect(url: url);
}
```

### Binary Protocol Communication

For applications that use binary protocols (e.g., Protocol Buffers, MessagePack):

```dart
import 'dart:convert';

// Send JSON as binary
void sendJsonAsBinary(Map<String, dynamic> data) {
  final jsonString = json.encode(data);
  final bytes = utf8.encode(jsonString);
  _socketXClient.send(binary: Uint8List.fromList(bytes));
}

// Receive and decode binary JSON
_socketXClient.onBinaryMessage.listen((data) {
  final jsonString = utf8.decode(data);
  final decoded = json.decode(jsonString);
  print('Received data: $decoded');
});
```

### Connection State Management

Track connection state for UI updates:

```dart
enum ConnectionState { disconnected, connecting, connected }

class SocketManager {
  final _socketXClient = SocketXClient();
  ConnectionState _state = ConnectionState.disconnected;
  
  ConnectionState get state => _state;
  
  Future<void> connect(String url) async {
    _state = ConnectionState.connecting;
    
    _socketXClient.onConnected.listen((_) {
      _state = ConnectionState.connected;
    });
    
    _socketXClient.onError.listen((error) {
      _state = ConnectionState.disconnected;
    });
    
    await _socketXClient.connect(url: url);
  }
}
```

### Auto-Reconnection

Implement automatic reconnection on connection loss:

```dart
class AutoReconnectSocket {
  final _socketXClient = SocketXClient();
  String? _lastUrl;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;
  
  Future<void> connect(String url) async {
    _lastUrl = url;
    await _socketXClient.connect(url: url);
    _reconnectAttempts = 0;
  }
  
  void _setupAutoReconnect() {
    _socketXClient.onError.listen((error) async {
      if (!_shouldReconnect || _lastUrl == null) return;
      
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
        
        print('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
        await Future.delayed(delay);
        
        try {
          await _socketXClient.connect(url: _lastUrl!);
          _reconnectAttempts = 0;
        } catch (e) {
          print('Reconnection failed: $e');
        }
      }
    });
  }
  
  void disconnect() {
    _shouldReconnect = false;
    _socketXClient.disconnect();
  }
}
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection fails immediately | Invalid WebSocket URL | Verify URL starts with \`wss://\` or \`ws://\` |
| \`onError\` fires with encoding error | MTE initialization failed | Check SocketX server is running and accessible |
| Messages not received | Not subscribed to streams | Ensure you've set up \`.listen()\` on event streams before connecting |
| App crashes on Android | minSdk too low | Set \`minSdk = 26\` in \`android/app/build.gradle.kts\` |
| Build fails on iOS | Deployment target too low | Set iOS deployment target to 16.0+ in Xcode |
| Connection drops randomly | Network instability | Implement auto-reconnection (see Advanced Usage) |

### Debugging Tips

1. **Enable verbose logging**: Check your SocketX server logs to see connection attempts and errors
2. **Test with demo server**: Use \`wss://dev-socketx-server.eclypses.com\` to verify your code works
3. **Check network permissions**: Ensure your app has internet permission:
   - Android: Check \`AndroidManifest.xml\` has \`<uses-permission android:name="android.permission.INTERNET" />\`
   - iOS: Check \`Info.plist\` allows arbitrary loads for development servers
4. **Monitor event streams**: Add listeners to all streams during development to see what's happening

### Example: Debug Logging

```dart
void setupDebugLogging() {
  _socketXClient.onConnected.listen((_) {
    print('[SocketX] ✅ Connected');
  });
  
  _socketXClient.onMessage.listen((msg) {
    print('[SocketX] 📩 Message: $msg');
  });
  
  _socketXClient.onBinaryMessage.listen((data) {
    print('[SocketX] 📦 Binary: ${data.length} bytes');
  });
  
  _socketXClient.onError.listen((error) {
    print('[SocketX] ❌ Error (${error.type}): ${error.message}');
  });
}
```

### Need More Help?

- **Example Project**: Check the \`example/\` folder in this repository for a complete working implementation
- **Issues**: Report bugs on [GitHub Issues](https://github.com/Eclypses/socketx-client-plugin-flutter/issues)
- **Contact**: Reach out to Eclypses support (see contact section below)

---

<div style="page-break-after: always; break-after: page;"></div>

# Contact Eclypses

<p align="center" style="font-weight: bold; font-size: 20pt;">Email: <a href="mailto:info@eclypses.com">info@eclypses.com</a></p>
<p align="center" style="font-weight: bold; font-size: 20pt;">Web: <a href="https://www.eclypses.com">www.eclypses.com</a></p>
<p style="font-size: 8pt; margin-bottom: 0; margin: 100px 24px 30px 24px; " >
<b>All trademarks of Eclypses Inc.</b> may not be used without Eclypses Inc.'s prior written consent. No license for any use thereof has been granted without express written consent. Any unauthorized use thereof may violate copyright laws, trademark laws, privacy and publicity laws and communications regulations and statutes. The names, images and likeness of the Eclypses logo, along with all representations thereof, are valuable intellectual property assets of Eclypses, Inc. Accordingly, no party or parties, without the prior written consent of Eclypses, Inc., (which may be withheld in Eclypses' sole discretion), use or permit the use of any of the Eclypses trademarked names or logos of Eclypses, Inc. for any purpose other than as part of the address for the Premises, or use or permit the use of, for any purpose whatsoever, any image or rendering of, or any design based on, the exterior appearance or profile of the Eclypses trademarks and or logo(s).
</p>
