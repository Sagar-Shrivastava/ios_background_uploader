import Flutter
import UIKit

public class IosBackgroundUploaderPlugin: NSObject, FlutterPlugin, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    private var backgroundSession: URLSession!
    private static var eventSink: FlutterEventSink?
    private var responseDataMap = [Int: Data]() // Store data per task

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ios_background_uploader", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "ios_background_uploader/events", binaryMessenger: registrar.messenger())

        let instance = IosBackgroundUploaderPlugin()
        eventChannel.setStreamHandler(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.desireweb.iosuploader.customUploader")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "uploadFiles":
            if let args = call.arguments as? [String: Any] {
                startUpload(args: args)
                result("upload_started") // Immediate ack
            } else {
                result("invalid_arguments")
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startUpload(args: [String: Any]) {
        guard let urlString = args["url"] as? String,
              let url = URL(string: urlString),
              let files = args["files"] as? [String] else {
            print("Invalid arguments for upload")
            return
        }

        let method = args["method"] as? String ?? "POST"
        let headers = args["headers"] as? [String: String] ?? [:]
        let fields = args["fields"] as? [String: String] ?? [:]
        let tag = args["tag"] as? String ?? UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = createMultipartBody(files: files, fields: fields, boundary: boundary)

        let tempDir = FileManager.default.temporaryDirectory
        let bodyFileURL = tempDir.appendingPathComponent("upload-\(tag).tmp")
        do {
            try body.write(to: bodyFileURL)
        } catch {
            print("Error writing body: \(error)")
            return
        }

        let uploadTask = backgroundSession.uploadTask(with: request, fromFile: bodyFileURL)
        uploadTask.taskDescription = tag
        uploadTask.resume()
    }

    private func createMultipartBody(files: [String], fields: [String: String], boundary: String) -> Data {
        var body = Data()

        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        for filePath in files {
            let url = URL(fileURLWithPath: filePath)
            let filename = url.lastPathComponent
            let mimetype = "image/jpeg" // TODO: Detect mime if needed

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            if let fileData = try? Data(contentsOf: url) {
                body.append(fileData)
            }
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    // MARK: - URLSession Delegates

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let taskId = dataTask.taskIdentifier
        if responseDataMap[taskId] == nil {
            responseDataMap[taskId] = Data()
        }
        responseDataMap[taskId]?.append(data)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend) * 100.0
        DispatchQueue.main.async {
            IosBackgroundUploaderPlugin.eventSink?([
                "status": "progress",
                "progress": progress,
                "tag": task.taskDescription ?? ""
            ])
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskId = task.taskIdentifier
        let responseBody = responseDataMap[taskId].flatMap { String(data: $0, encoding: .utf8) } ?? ""
        responseDataMap.removeValue(forKey: taskId)

        if let error = error {
            DispatchQueue.main.async {
                IosBackgroundUploaderPlugin.eventSink?([
                    "status": "failed",
                    "error": error.localizedDescription,
                    "tag": task.taskDescription ?? ""
                ])
            }
        } else {
            if let httpResponse = task.response as? HTTPURLResponse {
                DispatchQueue.main.async {
                    IosBackgroundUploaderPlugin.eventSink?([
                        "status": "completed",
                        "code": httpResponse.statusCode,
                        "response": responseBody,
                        "tag": task.taskDescription ?? ""
                    ])
                }
            } else {
                DispatchQueue.main.async {
                    IosBackgroundUploaderPlugin.eventSink?([
                        "status": "completed",
                        "response": responseBody,
                        "tag": task.taskDescription ?? ""
                    ])
                }
            }
        }
    }
}

extension IosBackgroundUploaderPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        IosBackgroundUploaderPlugin.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        IosBackgroundUploaderPlugin.eventSink = nil
        return nil
    }
}
