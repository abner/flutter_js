package io.abner.flutter_js

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** FlutterJsPlugin */
public class FlutterJsPlugin: FlutterPlugin, MethodCallHandler {
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "io.abner.flutter_js")
    channel.setMethodCallHandler(FlutterJsPlugin());
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
      val channel = MethodChannel(registrar.messenger(), "flutter_js")
      channel.setMethodCallHandler(FlutterJsPlugin())
    }

    private var jsEngineMap = mutableMapOf<Int, JSEngine>()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "initEngine") {
      Log.d("FlutterJS", call.arguments.toString())
      val engineId = call.arguments as Int
      jsEngineMap[engineId] = JSEngine()
      result.success(engineId)
    } else if (call.method == "evaluate") {
      try {
        Log.d("FlutterJs", call.arguments.toString())
        val jsCommand: String = call.argument<String>("command")!!
        val engineId: Int = call.argument<Int>("engineId")!!
        val resultJS = jsEngineMap[engineId]!!.eval(jsCommand)
        result.success(resultJS)
      } catch (e: Exception) {
        result.error("FlutterJSException", e.message, null)
      }
    } else if (call.method == "close") {
      if (call.hasArgument("engineId")) {
        val engineId: Int = call.argument<Int>("engineId")!!
        if (jsEngineMap.containsKey(engineId)) {
          val jsEngine = jsEngineMap[engineId]!!
          jsEngine.close()
          jsEngineMap.remove(engineId)
        }
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    // close all quickjs contexts
    jsEngineMap.forEach { engine -> engine.value.close() }
    // close the quickjs runtime and the quickjs instance itself
    JSEngine.closeEngine()
  }
}
