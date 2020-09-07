import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_js/javascript_runtime.dart';

import 'qjs_typedefs.dart';

final DynamicLibrary qjsDynamicLibrary = Platform.isAndroid
    ? DynamicLibrary.open("libfastdev_quickjs_runtime.so")
    : DynamicLibrary.process();

typedef FnBridgeCallback = Function(
    dynamic args); //String Function(String channel, String message);

final Map<String, FnBridgeCallback> mapJsBridge = {};

Pointer<JSValueConst> bridgeCallbackGlobalHandler(
  Pointer<JSContext> ctx,
  Pointer<Utf8> channelName,
  Pointer<Utf8> message,
) {
  String channelNameStr = Utf8.fromUtf8(channelName);
  String messageStr = Utf8.fromUtf8(message);

  if (mapJsBridge.containsKey(channelNameStr)) {
    String result = 'NO RESULT YET';
    try {
      result = mapJsBridge[channelNameStr].call(jsonDecode(messageStr));
    } on Error catch (e) {
      result = e.toString();
      print('ERROR ------ $e');
    } on Exception catch (e) {
      result = e.toString();
      print('EXCEPTION ------ $e');
    }
    if (result == null) {
      Pointer<JSValueConst> nullValue = allocate();
      QuickJsRuntime._jsGetNullValue(ctx, nullValue);
      return nullValue;
    } else {
      return QuickJsRuntime.jsEval(ctx, "'$result';").rawResult;
    }
  }

  return QuickJsRuntime.jsEval(
          ctx, "'No channel registered: ($channelNameStr) => $messageStr'")
      .rawResult;
}

Pointer<NativeFunction<ChannelCallback>> consoleLogBridgeFunction;
Pointer<NativeFunction<ChannelCallback>> setTimeoutBridgeFunction;
Pointer<NativeFunction<ChannelCallback>> sendNativeBridgeFunction;

class QuickJsRuntime extends JavascriptRuntime {
  Pointer<JSContext> _context;
  Pointer<JSRuntime> _runtime;

  final String fileName;

  QuickJsRuntime(this.fileName) {
    _runtime = _jsNewRuntimeDartBridge();
    consoleLogBridgeFunction = Pointer.fromFunction<
        Pointer<JSValueConst> Function(
            Pointer<JSContext> ctx,
            Pointer<Utf8> channel,
            Pointer<Utf8> msg)>(bridgeCallbackGlobalHandler);
    setTimeoutBridgeFunction = Pointer.fromFunction<
        Pointer<JSValueConst> Function(
            Pointer<JSContext> ctx,
            Pointer<Utf8> channel,
            Pointer<Utf8> msg)>(bridgeCallbackGlobalHandler);
    sendNativeBridgeFunction = Pointer.fromFunction<
        Pointer<JSValueConst> Function(
            Pointer<JSContext> ctx,
            Pointer<Utf8> channel,
            Pointer<Utf8> msg)>(bridgeCallbackGlobalHandler);
    _context = _jsNewContext(
      _runtime,
      consoleLogBridgeFunction,
      setTimeoutBridgeFunction,
      sendNativeBridgeFunction,
    );

    init();
  }

  // NATIVE BRIDGE DECLARATIONS
  static JSEvalWrapper _jsEvalWrapper = qjsDynamicLibrary
      .lookupFunction<JSEvalWrapperNative, JSEvalWrapper>('JSEvalWrapper');

  static JS_NewRuntimeDartBridge _jsNewRuntimeDartBridge = qjsDynamicLibrary
      .lookup<NativeFunction<JS_NewRuntimeDartBridge>>(
        'JS_NewRuntimeDartBridge',
      )
      .asFunction();
  static JS_NewContextFn _jsNewContext = qjsDynamicLibrary
      .lookup<NativeFunction<JS_NewContextFn>>('JS_NewContextDartBridge')
      .asFunction();

  static JS_GetNullValue _jsGetNullValue = qjsDynamicLibrary
      .lookup<NativeFunction<JS_GetNullValue>>('JS_GetNullValue')
      .asFunction();

  static JSExecutePendingJob _jsExecutePendingJob = qjsDynamicLibrary
      .lookupFunction<JSExecutePendingJobNative, JSExecutePendingJob>(
    'JS_ExecutePendingJob',
  );

  static JSCallFunction1Arg _callJsFunction1Arg = qjsDynamicLibrary
      .lookupFunction<JSCallFunction1ArgNative, JSCallFunction1Arg>(
          'callJsFunction1Arg');

  static JSGetTypeTag _jsGetTypeTag = qjsDynamicLibrary
      .lookupFunction<JSGetTypeTagNative, JSGetTypeTag>('getTypeTag');

  static JSIsArray _jsIsArray = qjsDynamicLibrary
      .lookupFunction<JSIsArrayNative, JSIsArray>('JS_IsArrayDartWrapper');

  static JSJSONStringify _jSJSONStringify =
      qjsDynamicLibrary.lookupFunction<JSJSONStringifyNative, JSJSONStringify>(
          'JS_JSONStringifyDartWrapper');
  // END NATIVE BRIDGE DECLARATIONS

  JsEvalResult callFunction(
    Pointer function,
    Pointer argument,
  ) {
    Pointer result = allocate<JSValueConst>();
    Pointer<Pointer<Utf8>> stringResult = allocate<Pointer<Utf8>>();
    int operationResult =
        _callJsFunction1Arg(_context, function, argument, result, stringResult);
    String resultStr = Utf8.fromUtf8(stringResult.value);
    return JsEvalResult(
      resultStr,
      result,
      isError: operationResult == 0,
      isPromise: resultStr == '[object Promise]',
    );
  }

  static Type getTypeForJsValue(Pointer<JSValueConst> jsValue) {
    int value = _jsGetTypeTag(jsValue);

    switch (value) {
      case JS_TAG_BOOL:
        return bool;
      case JS_TAG_NULL:
        return Null;
      case JS_TAG_INT:
        return int;
      case JS_TAG_STRING:
        return String;
      case JS_TAG_OBJECT:
        return Object;
      case JS_TAG_UNDEFINED:
        return Null;
      default:
        return Null;
    }
  }

  JsEvalResult evaluate(String js) {
    return jsEval(_context, js);
  }

  static JsEvalResult jsEval(
    Pointer<JSContext> ctx,
    String js, {
    String fileName = 'nofile.js',
  }) {
    Pointer<JSValueConst> result = allocate<JSValueConst>();
    Pointer<Pointer<Utf8>> stringResult = allocate<Pointer<Utf8>>();
    Pointer<Int32> errors = allocate<Int32>();
    _jsEvalWrapper(ctx, Utf8.toUtf8(js), js.length, Utf8.toUtf8(fileName), 0,
        errors, result, stringResult);

    final strResult = Utf8.fromUtf8(stringResult.value);
    return JsEvalResult(
      strResult,
      result,
      isError: errors.value == 1,
      isPromise: strResult == '[object Promise]',
    );
  }

  static T convertToValue<T>(
      Pointer<JSContext> context, JsEvalResult evalResult) {
    Type type = getTypeForJsValue(evalResult.rawResult);

    if (_jsIsArray(context, evalResult.rawResult) == 1) {
      Pointer<JSValueConst> stringifiedValue = allocate();
      Pointer<Pointer<Utf8>> stringResultPointer = allocate();
      int res = _jSJSONStringify(
        context,
        evalResult.rawResult,
        stringifiedValue,
        stringResultPointer,
      );
      final stringResult = Utf8.fromUtf8(stringResultPointer.value);
      return jsonDecode(stringResult);
    }
    switch (type) {
      case int:
        return int.parse(evalResult.stringResult) as T;
      case bool:
        return (evalResult.stringResult == "true") as T;
      case String:
        return (evalResult.stringResult) as T;
      case Null:
        return null;
      case Object:
        Pointer<JSValueConst> stringifiedValue = allocate<JSValueConst>();
        Pointer<Pointer<Utf8>> stringResultPointer = allocate();

        int res = _jSJSONStringify(
          context,
          evalResult.rawResult,
          stringifiedValue,
          stringResultPointer,
        );
        final stringResult = Utf8.fromUtf8(stringResultPointer.value);
        return jsonDecode(stringResult);
    }
    return null;
  }

  @override
  void dispose() {
    // Todo: free runtime and context
  }

  @override
  int executePendingJob() {
    Pointer<JSContext> newContext = allocate<JSContext>();
    return _jsExecutePendingJob(_runtime, newContext);
  }

  @override
  String getEngineInstanceId() => _context.address.toString();

  @override
  void initChannelFunctions() {
    final sendMessageCreateFnResult = evaluate("""
        function sendMessage(channelName, message) {
          return FLUTTER_JS_NATIVE_BRIDGE_sendMessage.apply(globalThis, [channelName, message]);
        }
        sendMessage
      """);
    print('RESULT creating sendMessage function: $sendMessageCreateFnResult');
  }

  @override
  String jsonStringify(JsEvalResult jsValue) {
    Pointer<JSValueConst> stringifiedValue = allocate();
    Pointer<Pointer<Utf8>> stringResultPointer = allocate();
    int res = _jSJSONStringify(
      _context,
      jsValue.rawResult,
      stringifiedValue,
      stringResultPointer,
    );
    final stringResult = Utf8.fromUtf8(stringResultPointer.value);
    return stringResult;
  }

  @override
  bool setupBridge(String channelName, void Function(dynamic args) fn) {
    mapJsBridge[channelName] = fn;
    return true;
  }

  @override
  T convertValue<T>(JsEvalResult evalResult) {
    return convertToValue<T>(_context, evalResult);
  }

  @override
  Future<JsEvalResult> evaluateAsync(String code) {
    return Future.value(evaluate(code));
  }
}
