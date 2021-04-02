import 'dart:ffi';

import 'package:flutter_js_platform_interface/flutter_js_platform_interface.dart';
import 'package:flutter_js_platform_interface/js_eval_result.dart';
import 'package:flutter_qjs/flutter_qjs.dart';

class FlutterJsLinuxWin extends FlutterJsPlatform {
  late FlutterQjs runtime;

  // static FlutterJsLinuxWin instance = FlutterJsLinuxWin()..init();

  @override
  FlutterJsPlatform init() {
    runtime = FlutterQjs(stackSize: 1024 * 1024);
    return super.init();
  }

  @override
  JsEvalResult callFunction(Pointer<NativeType> fn, Pointer<NativeType> obj) {
    return JsEvalResult(
      "NotYetImplemented",
      "NotYetImplemented",
      isError: true,
    );
  }

  @override
  T convertValue<T>(JsEvalResult jsValue) {
    return jsValue.rawResult;
  }

  @override
  void dispose() {
    runtime.close();
  }

  @override
  JsEvalResult evaluate(String code) {
    try {
      final runtimeResult = runtime.evaluate(code);

      return JsEvalResult(
        runtimeResult.toString(),
        runtimeResult,
        isError: false,
        isPromise: runtimeResult is Future,
      );
    } on Error catch (e) {
      return JsEvalResult(e.toString(), e, isError: true, isPromise: false);
    }
  }

  @override
  Future<JsEvalResult> evaluateAsync(String code) {
    final result = evaluate(code);
    return Future.value(result);
  }

  @override
  int executePendingJob() {
    runtime.dispatch();
    return 0;
  }

  @override
  String getEngineInstanceId() {
    return runtime.hashCode.toString();
  }

  @override
  void initChannelFunctions() {
    // TODO: implement initChannelFunctions
  }

  @override
  String jsonStringify(JsEvalResult jsValue) {
    return jsValue.stringResult;
  }

  @override
  bool setupBridge(String channelName, Function(dynamic args) fn) {
    final channelFunctionCallbacks =
        FlutterJsPlatform.channelFunctionsRegistered[getEngineInstanceId()];

    if ((channelFunctionCallbacks ?? {}).keys.contains(channelName))
      return false;

    channelFunctionCallbacks?[channelName] = fn;

    return true;
  }
}
