#include <quickjs.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <android/log.h>


int QUICKJS_RUNTIME_DEBUG_ENABLED = 0;

extern "C" __attribute__((visibility("default"))) __attribute__((used))
JSRuntime *JS_NewRuntimeDartBridge(void) {
    JSRuntime *runtime = JS_NewRuntime();
    JS_SetGCThreshold(runtime, -1); // disable GC - to prevent GC disallocate variables
                                    // yet in use in the Dart side
    // JS_SetMemoryLimit(rt, 0x4000000); // 64 Mo
    // JS_SetMemoryLimit(runtime, -1); is the default
    return runtime;
}

#define QUICKJS_CHANNEL_CONSOLELOG 0;
#define QUICKJS_CHANNEL_SETTIMEOUT 1;
#define QUICKJS_CHANNEL_SENDNATIVE 2;

typedef JSValue *(*ChannelFunc)(const JSContext *ctx, const char *channel, const char *message);
struct channel { 
    char *name;
    JSContext *ctx;
    ChannelFunc func;
    int assigned;
}; 
    
struct channel channel_functions[10] = { /*{"cat", cat_func}, {"dog", dog_func}, {NULL, NULL}*/ 
    { NULL, NULL, 0 },
    { NULL, NULL, 0 },
    { NULL, NULL, 0 },
    { NULL, NULL, 0 },
    { NULL, NULL, 0 },
    { NULL, NULL, 0 },
    { NULL, NULL, 0 },
    { NULL, NULL, 0 },
    { NULL, NULL, 0 },
    { NULL, NULL, 0 }
};

// where cat_func is declared int cat_func(const char **args);.
// You can search the list with

int contextsLength =0;

static JSValue CChannelFunction(JSContext *ctx, JSValueConst  this_val,
                              int argc, JSValueConst *argv) {
    
    const char* channelName = JS_ToCString(ctx, argv[0]);
    const char* message = JS_ToCString(ctx, argv[1]);   

    struct channel *cur = channel_functions;

    JSValue jsResult = JS_NULL;
    // while(cur->ctx) {
    //     //if(!strcmp(cur->name, channelName)) {
    //     if (cur->ctx == ctx && cur->assigned == 1) {
    //         JS_Eval(ctx, "console.log('Aqui no CChannelFunction3');", 40,"arquivo.js",0);
    //         result = cur->func(channelName, message);
    //         JS_Eval(ctx, "console.log('Aqui no CChannelFunction4');", 40,"arquivo.js",0);
    //         jsResult = JS_NewString(ctx, result);
    //         JS_Eval(ctx, "console.log('Aqui no CChannelFunction5');", 40,"arquivo.js",0);
    //     }
    // }

    int idxChannel = 0;
    if (strcmp("SendNative",channelName) == 0) {
        idxChannel = QUICKJS_CHANNEL_SENDNATIVE;
    } else if (strcmp("ConsoleLog",channelName) == 0) {
        idxChannel = QUICKJS_CHANNEL_CONSOLELOG;
    } if (strcmp("SetTimeout",channelName) == 0) {
        idxChannel = QUICKJS_CHANNEL_SETTIMEOUT;
    }

    if (channel_functions[idxChannel].assigned == 1) {
       ChannelFunc funcCaller = channel_functions[idxChannel].func;

        if (funcCaller != nullptr) {
            jsResult = * funcCaller(ctx, channelName, message);
        } else {
            jsResult = JS_NewString(ctx, "No function found");
        }
    }
    
    return jsResult;
}

JSValue stringifyFn;

extern "C" __attribute__((visibility("default"))) __attribute__((used))
JSContext *JS_NewContextDartBridge(
    JSRuntime *rt,
    ChannelFunc consoleLogChannelFunction,
    ChannelFunc setTimeoutChannelFunction,
    ChannelFunc sendNativeChannelFunction
) {
    JSContext *ctx;
    ctx = JS_NewContext(rt);
    
     // create the QuickJS Function passing the CChannelFunction ;
    // register the function jsBridgeFunction into the global object
    JSValue globalObject = JS_GetGlobalObject(ctx);


    stringifyFn = JS_Eval(
        ctx,
        "function simpleStringify(obj) { return JSON.stringify(obj);}simpleStringify;", 
        strlen("function simpleStringify(obj) { return JSON.stringify(obj);}"),
        "f1.js",
        0
    );

    JS_SetPropertyStr(
        ctx,
        globalObject,
        "FLUTTER_JS_NATIVE_BRIDGE_sendMessage", 
        JS_NewCFunction(ctx, CChannelFunction, "FLUTTER_JS_NATIVE_BRIDGE_sendMessage", 2)
    );

    if (consoleLogChannelFunction) {
        channel_functions[0].func = consoleLogChannelFunction;
        channel_functions[0].ctx = ctx;
        channel_functions[0].name = (char*)"ConsoleLog";
        channel_functions[0].assigned = 1;

        channel_functions[1].func = setTimeoutChannelFunction;
        channel_functions[1].ctx = ctx;
        channel_functions[1].name = (char*)"SetTimeout";
        channel_functions[1].assigned = 1;
        
        // store in the function register the dartChannelFunction passed
        channel_functions[2].func = sendNativeChannelFunction;
        channel_functions[2].ctx = ctx;
        channel_functions[2].name = (char*)"SendNative";
        channel_functions[2].assigned = 1;

        contextsLength=3;
    }

    JS_FreeValue(ctx, globalObject);

    JS_FreeValue(ctx, stringifyFn);

    // returns the generated context
    return ctx;
}


extern "C" __attribute__((visibility("default"))) __attribute__((used))
JSValue *copyToHeap(JSValueConst value)
{
    auto *result = static_cast<JSValue *>(malloc(sizeof(JSValueConst)));
    if (result)
    {
        memcpy(result, &value, sizeof(JSValueConst));
    }
    return result;
}
extern "C" __attribute__((visibility("default"))) __attribute__((used))
const void *JSEvalWrapper(JSContext *ctx, const char *input, size_t input_len,
                  const char *filename, int eval_flags,
                  int *errors, JSValueConst *result, char **stringResult) {
    
    // __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "Before Eval: %p", result);
    result = copyToHeap(JS_Eval(ctx, input, input_len, filename, eval_flags));
    // __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "After Eval: %p", result);
    *errors = 0;
    
    if (JS_IsException(*result) == 1) {
        // __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "Inside is exception: %p", result);
        JS_FreeValue(ctx, *result);
        *errors = 1;
        * result = JS_GetException(ctx);
        * stringResult = (char*)JS_ToCString(ctx, *result);
        // __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "After get  exception: %p", result);
        return nullptr;       
    }
    // __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "Before string result: %p", stringResult);
    *stringResult = (char*)JS_ToCString(ctx, *result);
    // __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "After string result: %p", stringResult);
    return nullptr;
}


extern "C" __attribute__((visibility("default"))) __attribute__((used))
void *JS_GetNullValue(JSContext *ctx, JSValue *result) {
    result = copyToHeap(JS_Eval(
        ctx,
        "null", 
        4,
        "f1.js",
        0
    ));
    return nullptr;
}

// used in method callFunction in quickjs_method_bindings
extern "C" __attribute__((visibility("default"))) __attribute__((used))
int callJsFunction1Arg(JSContext *ctx, JSValueConst *function, JSValueConst *object, JSValueConst *result, char **stringResult) {
    JSValue globalObject = JS_GetGlobalObject(ctx);
    //JSValue function = JS_GetPropertyStr(ctx, globalObject, functionName);
    result = copyToHeap(JS_Call(ctx, *function, globalObject, 1, object));
    
    int successOperation = 1;

    if (JS_IsException(*result) == 1) {
        successOperation = 0;
        result = copyToHeap(JS_GetException(ctx));
    }
    *stringResult = (char*)JS_ToCString(ctx, *result);
    return successOperation;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int getTypeTag(JSValue *jsValue) {
    if (jsValue) {
        return JS_VALUE_GET_TAG(*jsValue);
    } else {
        return JS_TAG_NULL;
    }
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int JS_IsArrayDartWrapper(JSContext *ctx, JSValueConst *val) {
    return JS_IsArray(ctx, *val);
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int JS_JSONStringifyDartWrapper(
    JSContext *ctx,
    JSValue *obj, JSValueConst *result, char **stringResult) {
    if (QUICKJS_RUNTIME_DEBUG_ENABLED == 1) {
    __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "JS_JSONStringifyDartWrapper %p", result);
    }
    JSValue globalObject = JS_GetGlobalObject(ctx);
    if (QUICKJS_RUNTIME_DEBUG_ENABLED == 1) {
        __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "JS_JSONStringifyDartWrapper2 %p", result);
    }
    if (JS_IsUndefined(*obj)==1) {
        if (QUICKJS_RUNTIME_DEBUG_ENABLED == 1) {
            __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "JS_JSONStringifyDartWrapper3 %p", result);
        }
        * stringResult = (char*) "undefined";
        return 0;
    } else if ( JS_IsNull(*obj) == 1) {
        if (QUICKJS_RUNTIME_DEBUG_ENABLED == 1) {
            __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "JS_JSONStringifyDartWrapper4 %p", result);
        }
        * stringResult = (char*) "null";
        return 0;
    } else {
        if (QUICKJS_RUNTIME_DEBUG_ENABLED == 1) {
            __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "JS_JSONStringifyDartWrapper5 %p", result);
        }
        result = copyToHeap(JS_Call(ctx, stringifyFn, globalObject, 1, obj));
        * stringResult = (char*)JS_ToCString(ctx, *result);
        if (QUICKJS_RUNTIME_DEBUG_ENABLED == 1) {
            __android_log_print(ANDROID_LOG_DEBUG, "LOG_TAG", "JS_JSONStringifyDartWrapper6 %p", result);
        }
        return 1;
    }
}