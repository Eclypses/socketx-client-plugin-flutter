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

package com.eclypses.socketx_client

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.eclypses.socketx_client_android.SocketXClient
import com.eclypses.socketx_client_android.SocketXError
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString

/**
 * Flutter plugin for secure WebSocket communication using the SocketX protocol.
 */
class SocketXClientPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private var socketXClient: SocketXClient? = null
    private var webSocket: WebSocket? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // The SocketX library holds no Context of its own, so the plugin supplies a
    // directory for optional log-file capture.
    private var appContext: Context? = null

    companion object {
        private const val CHANNEL_NAME = "socketx_client"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
        appContext = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        disconnect()
        appContext = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "connect" -> handleConnect(call, result)
            "disconnect" -> handleDisconnect(result)
            "sendText" -> handleSendText(call, result)
            "sendBinary" -> handleSendBinary(call, result)
            "enableFileLogging" -> handleEnableFileLogging(call, result)
            "readLogFile" -> result.success(SocketXClient.readLogFile().ifEmpty { null })
            "clearLogFile" -> {
                SocketXClient.clearLogFile()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // MARK: - Diagnostics

    private fun handleEnableFileLogging(call: MethodCall, result: Result) {
        val enabled = call.argument<Boolean>("enabled")
        if (enabled == null) {
            result.error("INVALID_ARGUMENTS", "'enabled' is required", null)
            return
        }
        SocketXClient.enableFileLogging(enabled, appContext?.filesDir)
        result.success(null)
    }

    // MARK: - Connection Methods

    private fun handleConnect(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        if (url.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "URL is required", null)
            return
        }

        // Disconnect existing connection if any
        disconnect()

        try {
            // Build OkHttpClient
            val okHttpClient = OkHttpClient.Builder().build()

            // Build request with optional headers
            val requestBuilder = Request.Builder().url(url)
            call.argument<Map<String, String>>("headers")?.forEach { (key, value) ->
                requestBuilder.addHeader(key, value)
            }
            val request = requestBuilder.build()

            // Initialize SocketXClient
            socketXClient = SocketXClient(okHttpClient).apply {
                onGlobalError = { error ->
                    sendError(error)
                }
            }

            // Create WebSocket with listener
            webSocket = socketXClient?.newWebSocket(request, createWebSocketListener())

            result.success(null)
        } catch (e: Exception) {
            sendError("internal", e.message ?: "Unknown error during connection")
            result.error("CONNECTION_ERROR", e.message, null)
        }
    }

    private fun handleDisconnect(result: Result) {
        disconnect()
        result.success(null)
    }

    private fun disconnect() {
        webSocket?.close(1000, "Client disconnected")
        webSocket = null
        socketXClient = null
    }

    // MARK: - Send Methods

    private fun handleSendText(call: MethodCall, result: Result) {
        val text = call.argument<String>("text")
        if (text.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "Text is required", null)
            return
        }

        val ws = webSocket
        if (ws == null) {
            result.error("NOT_CONNECTED", "WebSocket is not connected", null)
            return
        }

        ws.send(text)
        result.success(null)
    }

    private fun handleSendBinary(call: MethodCall, result: Result) {
        val data = call.argument<ByteArray>("data")
        if (data == null) {
            result.error("INVALID_ARGUMENTS", "Binary data is required", null)
            return
        }

        val ws = webSocket
        if (ws == null) {
            result.error("NOT_CONNECTED", "WebSocket is not connected", null)
            return
        }

        ws.send(ByteString.of(*data))
        result.success(null)
    }

    // MARK: - WebSocket Listener

    private fun createWebSocketListener(): WebSocketListener {
        return object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                invokeMethod("onConnected", null)
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                invokeMethod("onMessage", text)
            }

            override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
                invokeMethod("onBinaryMessage", bytes.toByteArray())
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                sendError("network", t.message ?: "Connection failed")
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                webSocket.close(code, reason)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                // Connection closed normally
            }
        }
    }

    // MARK: - Error Handling

    private fun sendError(error: SocketXError) {
        val (type, reason) = when (error) {
            is SocketXError.NetworkError -> "network" to error.message
            is SocketXError.TransportError -> "transport" to error.message
            is SocketXError.CodecError -> "codec" to error.message
            is SocketXError.HandshakeError -> "handshake" to error.message
            is SocketXError.ProxyError -> "proxy" to error.message
            is SocketXError.InternalError -> "internal" to error.message
            else -> "unknown" to (error.message ?: "Unknown error")
        }
        sendError(type, reason ?: "Unknown error")
    }

    private fun sendError(type: String, reason: String) {
        val errorMap = mapOf(
            "type" to type,
            "reason" to reason
        )
        invokeMethod("onError", errorMap)
    }

    // MARK: - Helper Methods

    private fun invokeMethod(method: String, arguments: Any?) {
        mainHandler.post {
            methodChannel.invokeMethod(method, arguments)
        }
    }
}
