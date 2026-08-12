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
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mte_socketx/mte_socketx.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SocketXDemoApp());
}

class SocketXDemoApp extends StatelessWidget {
  const SocketXDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocketX Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SocketXDemoPage(),
    );
  }
}

class SocketXDemoPage extends StatefulWidget {
  const SocketXDemoPage({super.key});

  @override
  State<SocketXDemoPage> createState() => _SocketXDemoPageState();
}

class _SocketXDemoPageState extends State<SocketXDemoPage> {
  final _socketXClient = SocketXClient();
  final _messageController = TextEditingController(text: 'Hello, SocketX!');
  final _scrollController = ScrollController();

  // SocketX Server configuration
  static const String _baseUrl = 'wss://socketx-server.eclypses.com';
  
  // Available rooms on the SocketX server
  static const List<String> _rooms = [
    '',           // Root
    'dogs',
    'cats', 
    'fish',
    'bytes-1',    // Binary message room
    'bytes-2',    // Binary message room
    'error',      // Triggers error response
    'disconnect', // Server disconnects
  ];

  String _selectedRoom = '';
  final List<_LogEntry> _logs = [];
  bool _isConnected = false;
  bool _isConnecting = false;
  
  StreamSubscription<void>? _connectedSubscription;
  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<Uint8List>? _binarySubscription;
  StreamSubscription<SocketXError>? _errorSubscription;

  String get _currentUrl {
    if (_selectedRoom.isEmpty) {
      return _baseUrl;
    }
    return '$_baseUrl/$_selectedRoom';
  }

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _connectedSubscription?.cancel();
    _messageSubscription?.cancel();
    _binarySubscription?.cancel();
    _errorSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupListeners() {
    _connectedSubscription = _socketXClient.onConnected.listen((_) {
      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });
      _addLog('SocketX Securely Paired & Connected', LogType.success);
    });

    _messageSubscription = _socketXClient.onMessage.listen((message) {
      _addLog('Received (Decrypted): $message', LogType.received);
    });

    _binarySubscription = _socketXClient.onBinaryMessage.listen((data) {
      final str = utf8.decode(data, allowMalformed: true);
      _addLog('Received Binary (Decrypted): $str', LogType.received);
    });

    _errorSubscription = _socketXClient.onError.listen((error) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
      });
      _addLog('${error.type.name.toUpperCase()} Error: ${error.reason}', LogType.error);
    });
  }

  void _addLog(String message, LogType type) {
    setState(() {
      _logs.add(_LogEntry(
        message: message,
        type: type,
        timestamp: DateTime.now(),
      ));
    });
    
    // Scroll to bottom after adding log
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    _addLog('Connecting to $_currentUrl...', LogType.info);

    try {
      await _socketXClient.connect(url: _currentUrl);
    } catch (e) {
      setState(() => _isConnecting = false);
      _addLog('Connection failed: $e', LogType.error);
    }
  }

  Future<void> _disconnect() async {
    _addLog('Disconnecting...', LogType.info);
    try {
      await _socketXClient.disconnect();
      setState(() => _isConnected = false);
      _addLog('--- Disconnected ---', LogType.info);
    } catch (e) {
      _addLog('Disconnect failed: $e', LogType.error);
    }
  }

  Future<void> _reconnect() async {
    await _disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    await _connect();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _addLog('Please enter a message', LogType.error);
      return;
    }

    try {
      // Use binary for bytes rooms
      if (_selectedRoom == 'bytes-1' || _selectedRoom == 'bytes-2') {
        final bytes = Uint8List.fromList(utf8.encode(message));
        await _socketXClient.sendBinary(binary: bytes);
        _addLog('Sent binary: ${bytes.length} bytes', LogType.sent);
      } else {
        await _socketXClient.send(text: message);
        _addLog('Sent: $message', LogType.sent);
      }
      
      // Set a random message for next send
      _messageController.text = _randomMessages[Random().nextInt(_randomMessages.length)];
    } catch (e) {
      _addLog('Send failed: $e', LogType.error);
    }
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  void _onRoomChanged(String? room) {
    if (room == null) return;
    setState(() => _selectedRoom = room);
    if (_isConnected) {
      _reconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SocketX Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status indicator
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.lock : Icons.lock_open,
                          color: _isConnected ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected ? 'Securely Connected' : 'Disconnected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isConnected ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Server URL (read-only display)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentUrl,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Room selector
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRoom,
                      decoration: const InputDecoration(
                        labelText: 'Select Room',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                      items: _rooms.map((room) {
                        return DropdownMenuItem(
                          value: room,
                          child: Text(room.isEmpty ? 'Root (/)' : '/$room'),
                        );
                      }).toList(),
                      onChanged: _isConnecting ? null : _onRoomChanged,
                    ),
                    const SizedBox(height: 12),
                    
                    // Connect/Disconnect button
                    ElevatedButton.icon(
                      onPressed: _isConnecting
                          ? null
                          : (_isConnected ? _disconnect : _connect),
                      icon: _isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isConnected ? Icons.close : Icons.power),
                      label: Text(_isConnected ? 'Disconnect' : 'Connect'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Message Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: _selectedRoom.startsWith('bytes') 
                            ? 'Message (sent as binary)'
                            : 'Message',
                        hintText: 'Enter message to send',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          _selectedRoom.startsWith('bytes') 
                              ? Icons.memory 
                              : Icons.message,
                        ),
                      ),
                      enabled: _isConnected,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isConnected ? _sendMessage : null,
                      icon: const Icon(Icons.send),
                      label: Text(
                        _selectedRoom.startsWith('bytes') 
                            ? 'Send Binary' 
                            : 'Send Text',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Log Section
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Event Log',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.black87,
                        child: _logs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No events yet\nConnect to start',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8),
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  return _LogEntryWidget(entry: log);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Random messages to cycle through (matching Swift demo)
const _randomMessages = [
  "Have a great Eclypses Day!",
  "Four score and seven years ago ...",
  "Hello, World!",
  "WebSockets are cool.",
  "Let's do this!",
  "To infinity, and beyond!",
  "May the force be with you.",
  "I think, therefore I am.",
  "Houston, we have a problem.",
  "Eureka!",
];

enum LogType { info, success, error, sent, received }

class _LogEntry {
  final String message;
  final LogType type;
  final DateTime timestamp;

  _LogEntry({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

class _LogEntryWidget extends StatelessWidget {
  final _LogEntry entry;

  const _LogEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.type) {
      LogType.info => Colors.grey,
      LogType.success => Colors.green,
      LogType.error => Colors.red,
      LogType.sent => Colors.cyan,
      LogType.received => Colors.lightGreenAccent,
    };

    final icon = switch (entry.type) {
      LogType.info => Icons.info_outline,
      LogType.success => Icons.check_circle_outline,
      LogType.error => Icons.error_outline,
      LogType.sent => Icons.arrow_upward,
      LogType.received => Icons.arrow_downward,
    };

    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
