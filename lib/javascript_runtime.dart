import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/foundation.dart';

class JsEvalResult {
  final String stringResult;
  final dynamic rawResult;
  final bool isPromise;
  final bool isError;

  JsEvalResult(this.stringResult, this.rawResult,
      {this.isError = false, this.isPromise = false});

  toString() => stringResult;
}

abstract class JavascriptRuntime {
  @protected
  JavascriptRuntime init() {
    initChannelFunctions();
    _setupConsoleLog();
    _setupSetTimeout();
    return this;
  }

  Map<String, Pointer> localContext = {};

  Map<String, dynamic> dartContext = {};

  void dispose();

  static Map<String, Map<String, Function(dynamic arg)>>
      _channelFunctionsRegistered = {};

  static Map<String, Map<String, Function(dynamic arg)>>
      get channelFunctionsRegistered => _channelFunctionsRegistered;

  JsEvalResult evaluate(String code);

  Future<JsEvalResult> evaluateAsync(String code);

  JsEvalResult callFunction(Pointer fn, Pointer obj);

  T convertValue<T>(JsEvalResult jsValue);

  String jsonStringify(JsEvalResult jsValue);

  @protected
  void initChannelFunctions();

  int executePendingJob();

  void _setupConsoleLog() {
    evaluate("""
    var console = {
      log: function() {
        sendMessage('ConsoleLog', JSON.stringify(['log', ...arguments]));
      },
      warn: function() {
        sendMessage('ConsoleLog', JSON.stringify(['info', ...arguments]));
      },
      error: function() {
        sendMessage('ConsoleLog', JSON.stringify(['error', ...arguments]));
      }
    }""");
    onMessage('ConsoleLog', (dynamic args) {
      print(args[1]);
    });
  }

  void _setupSetTimeout() {
    final setTImeoutResult = evaluate("""
      var __NATIVE_FLUTTER_JS__setTimeoutCount = -1;
      var __NATIVE_FLUTTER_JS__setTimeoutCallbacks = {};
      function setTimeout(fnTimeout, timeout) {
        // console.log('Set Timeout Called');
        try {
        __NATIVE_FLUTTER_JS__setTimeoutCount += 1;
          var timeoutIndex = '' + __NATIVE_FLUTTER_JS__setTimeoutCount;
          __NATIVE_FLUTTER_JS__setTimeoutCallbacks[timeoutIndex] =  fnTimeout;
          ;
          // console.log(typeof(sendMessage));
          // console.log('BLA');
          sendMessage('SetTimeout', JSON.stringify({ timeoutIndex, timeout}));
            
        } catch (e) {
          console.error('ERROR HERE',e.message);
        }
      };
      1
    """);
    print('SET TIMEOUT EVAL RESULT: $setTImeoutResult');
    onMessage('SetTimeout', (dynamic args) {
      try {
        int duration = args['timeout'];
        String idx = args['timeoutIndex'];

        Timer(Duration(milliseconds: duration), () {
          evaluate("""
            __NATIVE_FLUTTER_JS__setTimeoutCallbacks[$idx].call();
            delete __NATIVE_FLUTTER_JS__setTimeoutCallbacks[$idx];
          """);
        });
      } on Exception catch (e) {
        print('Exception no setTimeout: $e');
      } on Error catch (e) {
        print('Erro no setTimeout: $e');
      }
    });
  }

  sendMessage({
    @required String channelName,
    @required List<String> args,
    String uuid,
  }) {
    if (uuid != null) {
      evaluate(
          "DART_TO_QUICKJS_CHANNEL_sendMessage('$channelName', '${jsonEncode(args)}', '$uuid');");
    } else {
      evaluate(
          "DART_TO_QUICKJS_CHANNEL_sendMessage('$channelName', '${jsonEncode(args)}');");
    }
  }

  onMessage(String channelName, void Function(dynamic args) fn) {
    setupBridge(channelName, fn);
  }

  bool setupBridge(String channelName, void Function(dynamic args) fn);

  String getEngineInstanceId();
}
