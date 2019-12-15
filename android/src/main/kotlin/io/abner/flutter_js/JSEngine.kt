package io.abner.flutter_js

import com.hippo.quickjs.android.JSContext
import com.hippo.quickjs.android.JSRuntime
import com.hippo.quickjs.android.QuickJS

class JSEngine() {

    private lateinit var runtime: JSRuntime
    private lateinit var context: JSContext
    var runtimeInitialized = false
    init {
        initEngine()
    }

    companion object {

        private var quickJS: QuickJS? = null
        @JvmStatic
        fun closeEngine() {
            if (quickJS != null) {
                quickJS!!.close()
                quickJS = null
            }
        }

        @JvmStatic
        fun initEngine() {
            if (quickJS == null) {
                quickJS = QuickJS.Builder().build()
            }
        }
    }

    fun initRuntime() {
        initEngine()
        if (!runtimeInitialized) {
            runtime = quickJS!!.createJSRuntime()
            context = runtime.createJSContext()
            runtimeInitialized = true
        }

    }

    fun eval(script: String): String {
        initRuntime()
        return context.evaluate(script, "JSEngine-${this.hashCode()}.js", String::class.java)
    }

    fun close() {
        runtime.close()

    }

}