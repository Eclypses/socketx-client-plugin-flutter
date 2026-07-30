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

import Flutter
import UIKit
import SocketXClient

public class SocketXClientPlugin: NSObject, FlutterPlugin {
    
    // MARK: - Class Variables
    private var methodChannel: FlutterMethodChannel?
    private static let channelName = "socketx_client"
    private var socketXClient: SocketXClient?
    private var urlSession: URLSession?
    
    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SocketXClientPlugin()
        let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        instance.methodChannel = methodChannel
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }
    
    // MARK: - Method Call Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "connect":
            handleConnect(call: call, result: result)
            
        case "disconnect":
            handleDisconnect(result: result)
            
        case "sendText":
            handleSendText(call: call, result: result)
            
        case "sendBinary":
            handleSendBinary(call: call, result: result)

        case "enableFileLogging":
            handleEnableFileLogging(call: call, result: result)

        case "readLogFile":
            handleReadLogFile(result: result)

        case "clearLogFile":
            SocketXClient.clearLogFile()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Diagnostics

    private func handleEnableFileLogging(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "'enabled' is required",
                               details: nil))
            return
        }
        SocketXClient.enableFileLogging(enabled)
        result(nil)
    }

    private func handleReadLogFile(result: @escaping FlutterResult) {
        do {
            result(try SocketXClient.readLogFile())
        } catch {
            result(FlutterError(code: "READ_LOG_ERROR",
                               message: error.localizedDescription,
                               details: nil))
        }
    }
    
    // MARK: - Connection Methods
    
    private func handleConnect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "URL is required",
                               details: nil))
            return
        }
        
        // Disconnect existing connection if any
        socketXClient?.disconnect()
        
        // Create URL session configuration
        let configuration = URLSessionConfiguration.default
        if let headers = args["headers"] as? [String: String] {
            configuration.httpAdditionalHeaders = headers
        }
        
        // Create URL session and WebSocket task
        urlSession = URLSession(configuration: configuration)
        guard let task = urlSession?.webSocketTask(with: url) else {
            result(FlutterError(code: "CONNECTION_ERROR",
                               message: "Failed to create WebSocket task",
                               details: nil))
            return
        }
        
        do {
            // Initialize SocketXClient with the WebSocket task
            socketXClient = try SocketXClient(task: task)
            setupCallbacks()
            socketXClient?.connect()
            result(nil)
        } catch {
            sendError(type: "internal", reason: error.localizedDescription)
            result(FlutterError(code: "INITIALIZATION_ERROR",
                               message: error.localizedDescription,
                               details: nil))
        }
    }
    
    private func handleDisconnect(result: @escaping FlutterResult) {
        socketXClient?.disconnect()
        socketXClient = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        result(nil)
    }
    
    // MARK: - Send Methods
    
    private func handleSendText(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let text = args["text"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Text is required",
                               details: nil))
            return
        }
        
        guard let client = socketXClient else {
            result(FlutterError(code: "NOT_CONNECTED",
                               message: "WebSocket is not connected",
                               details: nil))
            return
        }
        
        client.send(text: text)
        result(nil)
    }
    
    private func handleSendBinary(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let data = args["data"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Binary data is required",
                               details: nil))
            return
        }
        
        guard let client = socketXClient else {
            result(FlutterError(code: "NOT_CONNECTED",
                               message: "WebSocket is not connected",
                               details: nil))
            return
        }
        
        client.send(binary: data.data)
        result(nil)
    }
    
    // MARK: - Callback Setup
    
    private func setupCallbacks() {
        socketXClient?.onConnected = { [weak self] in
            self?.invokeMethod("onConnected", arguments: nil)
        }
        
        socketXClient?.onMessageReceived = { [weak self] text in
            self?.invokeMethod("onMessage", arguments: text)
        }
        
        socketXClient?.onBinaryReceived = { [weak self] data in
            self?.invokeMethod("onBinaryMessage", arguments: FlutterStandardTypedData(bytes: data))
        }
        
        socketXClient?.onError = { [weak self] error in
            self?.handleSocketXError(error)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleSocketXError(_ error: SocketXError) {
        let errorType: String
        let reason: String
        
        switch error {
        case .networkError(let r):
            errorType = "network"
            reason = r
        case .transportError(let r):
            errorType = "transport"
            reason = r
        case .codecError(let r):
            errorType = "codec"
            reason = r
        case .handshakeError(let r):
            errorType = "handshake"
            reason = r
        case .proxyError(let r):
            errorType = "proxy"
            reason = r
        case .internalError(let r):
            errorType = "internal"
            reason = r
        case .unknown(let r):
            errorType = "unknown"
            reason = r
        }
        
        sendError(type: errorType, reason: reason)
    }
    
    private func sendError(type: String, reason: String) {
        let errorMap: [String: Any] = [
            "type": type,
            "reason": reason
        ]
        invokeMethod("onError", arguments: errorMap)
    }
    
    // MARK: - Helper Methods
    
    private func invokeMethod(_ method: String, arguments: Any?) {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel?.invokeMethod(method, arguments: arguments)
        }
    }
}
