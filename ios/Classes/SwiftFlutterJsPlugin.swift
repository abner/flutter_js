import Flutter
import UIKit
// import JSContextFoundation

public class SwiftFlutterJsPlugin: NSObject, FlutterPlugin {
  private jsEngineMap = [Int: JSContextFoundation] = [:]
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "io.abner.flutter_js", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterJsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initEngine":
            let engineId = call.arguments as! Int
            jsEngineMap[engineId] = JSContextFoundation()
            result(engineId)
            break;
        case "evaluate":
            let argsMap = call.arguments as! NSDictionary
            //let command:String? = argsMap.value(forKey: "command") as? String
            let command:String = argsMap.value(forKey: "command") as! String
            let engineId:Int = argsMap.value(forKey: "engineId") as! Int

            if let jsEngine = jsEngineMap[engineId] {
                jsEngine.exceptionHandler = { context, exception in
                     let exceptionDictionary = exception?.toDictionary()
                     print("[JSCotextFoundation][Exception] \(String(describing: exception)) at line \(String(describing: exceptionDictionary?["line"])):\(String(describing: exceptionDictionary?["column"]))")
                     result(FlutterError(code: "EvaluateError",
                                             message: String(describing: exception),
                                             details: nil))
                 }

                let resultJS:String = jsEngine.evaluateScript(command)
                result(resultJS)
            } else {
                result(FlutterError(code: "EvaluateError",
                         message: "jsEngine with id \(enginedId) was not found",
                         details: nil))
            }
            result(resultJS)
            break;
        case "close":
            break;
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
  }
}

