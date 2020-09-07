package io.abner.flutter_js

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.os.Looper
import android.os.Handler
import fi.iki.elonen.NanoHTTPD
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

data class MethodChannelResult(val success: Boolean, val data: Any? = null)

/** FlutterJsPlugin */
class FlutterJsPlugin : FlutterPlugin, MethodCallHandler {
    private var applicationContext: android.content.Context? = null
    private var methodChannel: MethodChannel? = null
    val flutterJsServer = FlutterJsServer()
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
    }

    private fun onAttachedToEngine(applicationContext: android.content.Context, messenger: BinaryMessenger) {
        this.applicationContext = applicationContext
        methodChannel = MethodChannel(messenger, "io.abner.flutter_js")
        methodChannel!!.setMethodCallHandler(this)
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {


        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val instance = FlutterJsPlugin()
            instance.onAttachedToEngine(registrar.context(), registrar.messenger())
        }

        var jsEngineMap = mutableMapOf<Int, JSEngine>()
    }

//    suspend fun invokeMethod(jsEngine: JSEngine, method: String, arguments: Any, callback: (result: MethodChannelResult) -> Unit): MethodChannelResult {
//        println(">>> send n2f : cmd - $method")
//        methodChannel?.invokeMethod(method, arguments, object : MethodChannel.Result{
//            override fun notImplemented() {
//                Log.d("NormalMethodHandler", "notImplemented")
//                callback.invoke(MethodChannelResult(false, "notImplemented"))
//            }
//
//            override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
//                Log.d("NormalMethodHandler", "error $errorMessage $ errorDetails")
//                callback.invoke(MethodChannelResult(false, "error $errorMessage $ errorDetails"))
//            }
//
//            override fun success(result: Any?) {
//                Log.d("NormalMethodHandler", "success")
//                callback.invoke(MethodChannelResult(true, result))
//            }
//        })
//    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "initEngine") {
            Log.d("FlutterJS", call.arguments.toString())
            val engineId = call.arguments as Int
            jsEngineMap[engineId] = JSEngine(applicationContext!!)
            flutterJsServer.start()
            Log.i("FLUTTERJS", "SERVER IS ALIVE: ${flutterJsServer.isAlive}")
            Log.i("FLUTTERJS", "PORT of Running JsBridge Service: ${flutterJsServer.listeningPort}")
            result.success(mapOf(
                    "engineId" to engineId,
                    "httpPort" to flutterJsServer.listeningPort
            ))
        } else if (call.method == "evaluate") {
            Thread {
                //runBlocking {
                try {
                    //Log.d("FlutterJs", call.arguments.toString())
                    val jsCommand: String = call.argument<String>("command")!!
                    val engineId: Int = call.argument<Int>("engineId")!!
                    val resultJS = jsEngineMap[engineId]!!.eval(jsCommand)
                    Handler(Looper.getMainLooper()).post {
                        result.success(resultJS.toString())
                        // Call the desired channel message here.
                    }
                } catch (e: Exception) {
                    Handler(Looper.getMainLooper()).post {
                        result.error("FlutterJSException", e.message, null)
                    }
                }

                //}
            }.start();
        } else if (call.method == "registerChannel") {
            val engineId: Int = call.argument<Int>("engineId")!!
            val channelName: String = call.argument<String>("channelName")!!
            if (jsEngineMap.containsKey(engineId)) {
                val jsEngine = jsEngineMap[engineId]!!
                Log.i("FlutterJS", " --- registering channel: $channelName")
                jsEngine.registerChannel(channelName) { message ->
//              var invokeResult: String? = null
//              var result: Any?
//              runBlocking {
//                  result = methodChannel?.invokeAsync(
//                          "sendMessage",
//                          listOf(
//                                  engineId,
//                                  channelName,
//                                  message)
//                  )
//              }
//              Log.i("JS-ChannelCall", result!!::class.java.simpleName.toString())
//              invokeResult ?: "No result yet"
                    Handler(Looper.getMainLooper()).post {
                        methodChannel!!.invokeMethod("sendMessage",
                                listOf(engineId, channelName, message)
                        )
                    }
                    "OK"
                }
            }
        } else if (call.method == "close") {
            if (call.hasArgument("engineId")) {
                val engineId: Int = call.argument<Int>("engineId")!!
                if (jsEngineMap.containsKey(engineId)) {
                    val jsEngine = jsEngineMap[engineId]!!
                    jsEngine.release()
                    jsEngineMap.remove(engineId)
                }
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        jsEngineMap.forEach { engine -> engine.value.release() }
    }
}

suspend fun MethodChannel.invokeAsync(method: String, arguments: Any?): Any? =
        withContext(Dispatchers.Main) {
            suspendCoroutine<Any?> { continuation ->
                invokeMethod(method, arguments, object : MethodChannel.Result {

                    override fun notImplemented() {
                        continuation.resumeWithException(NotImplementedError("$method , $arguments"))
                    }

                    override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
                        continuation.resumeWithException(Exception("$errorCode , $errorMessage , $errorDetails"))
                    }

                    override fun success(result: Any?) {
                        continuation.resume(result)
                    }
                })
            }

        }

class FlutterJsServer() : NanoHTTPD(0) {

    override fun serve(session: IHTTPSession): Response {
        try {
            val bodyMap = mutableMapOf<String, String>()
            session.parseBody(bodyMap)
            val engineId = (session.parms["id"] ?: "0").toIntOrNull() ?: 0
            val code = bodyMap["postData"]
            val evalResult = FlutterJsPlugin.jsEngineMap[engineId]!!.eval(code!!)
            return newFixedLengthResponse(Response.Status.OK, MIME_PLAINTEXT, evalResult.toString())
        } catch (e: Exception) {
            return newFixedLengthResponse(Response.Status.BAD_REQUEST, MIME_PLAINTEXT, "ERROR: ${e.message}")
        }
    }

}