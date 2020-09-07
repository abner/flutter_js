package io.abner.flutter_js

import kotlinx.coroutines.Dispatchers
import android.util.Log
import de.prosiebensat1digital.oasisjsbridge.*

class JSEngine(context: android.content.Context) {

    private var runtime: JsBridge = JsBridge(JsBridgeConfig.standardConfig())
    private var messageChannelMap = mutableMapOf<String, (message: String) -> String>()

    fun getRuntime(): JsBridge {
        return runtime
    } 

    var runtimeInitialized = false
    init {
        val errorListener = object : JsBridge.ErrorListener(Dispatchers.Main) {
            override fun onError(error: JsBridgeError) {
                Log.e("MainActivity", error.errorString())
            }
        }
        runtime.registerErrorListener(errorListener)

        val sendMessage = JsValue.fromNativeFunction2(runtime) {
            channelName: String, message: String ->

            try {
                if (messageChannelMap.containsKey(channelName)) {
                    messageChannelMap.getValue(channelName).invoke(message);
                } else {
                    Log.i("SendMessage Channel", "Channel ${channelName} wasn't registered!")
                }

                return@fromNativeFunction2 "$channelName:$message"
            } catch (e: Exception) {
                return@fromNativeFunction2 e.message
            }
            
        }.assignToGlobal("sendMessage")
    }

    fun registerChannel(channelName: String, channelFn: (message: String) -> String ) {
        messageChannelMap[channelName] = channelFn
    }

    fun eval(script: String): JsonObjectWrapper {
        return runtime.evaluateBlocking(script, JsonObjectWrapper::class.java) as JsonObjectWrapper
    }

    fun release() {
        runtime.release()
    }

}