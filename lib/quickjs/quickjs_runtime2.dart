/* START PARTS IMPORT QJS ENGINE */
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter_js/flutter_js.dart';
import 'ffi.dart';
export 'ffi.dart' show JSEvalFlag, JSRef;

part './isolate.dart';
part './wrapper.dart';
part './object.dart';

/// Handler function to manage js module.
typedef _JsModuleHandler = String Function(String name);

/// Handler to manage unhandled promise rejection.
typedef _JsHostPromiseRejectionHandler = void Function(dynamic reason);

/// Quickjs engine for flutter.
class FlutterQjs extends FlutterJsPlatform {
  Pointer<JSRuntime>? _rt;
  Pointer<JSContext>? _ctx;

  /// Max stack size for quickjs.
  final int? stackSize;

  /// Message Port for event loop. Close it to stop dispatching event loop.
  ReceivePort port = ReceivePort();

  /// Handler function to manage js module.
  final _JsModuleHandler? moduleHandler;

  /// Handler function to manage js module.
  final _JsHostPromiseRejectionHandler? hostPromiseRejectionHandler;

  FlutterQjs({
    this.moduleHandler,
    this.stackSize,
    this.hostPromiseRejectionHandler,
  });

  _ensureEngine() {
    if (_rt != null) return;
    final rt = jsNewRuntime((ctx, type, ptr) {
      try {
        switch (type) {
          case JSChannelType.METHON:
            final pdata = ptr.cast<Pointer<JSValue>>();
            final argc = pdata.elementAt(1).value.cast<Int32>().value;
            final pargs = [];
            for (var i = 0; i < argc; ++i) {
              pargs.add(_jsToDart(
                ctx,
                Pointer.fromAddress(
                  pdata.elementAt(2).value.address + sizeOfJSValue * i,
                ),
              ));
            }
            final JSInvokable func = _jsToDart(
              ctx,
              pdata.elementAt(3).value,
            );
            return _dartToJs(
                ctx,
                func.invoke(
                  pargs,
                  _jsToDart(ctx, pdata.elementAt(0).value),
                ));
          case JSChannelType.MODULE:
            if (moduleHandler == null) throw JSError('No ModuleHandler');
            final ret = moduleHandler!(
              ptr.cast<Utf8>().toDartString(),
            ).toNativeUtf8();
            Future.microtask(() {
              malloc.free(ret);
            });
            return ret.cast();
          case JSChannelType.PROMISE_TRACK:
            final err = _parseJSException(ctx, ptr);
            if (hostPromiseRejectionHandler != null) {
              hostPromiseRejectionHandler!(err);
            } else {
              print('unhandled promise rejection: $err');
            }
            return nullptr;
          case JSChannelType.FREE_OBJECT:
            final rt = ctx.cast<JSRuntime>();
            _DartObject.fromAddress(rt, ptr.address)?.free();
            return nullptr;
        }
        throw JSError('call channel with wrong type');
      } catch (e) {
        if (type == JSChannelType.FREE_OBJECT) {
          print('DartObject release error: $e');
          return nullptr;
        }
        if (type == JSChannelType.MODULE) {
          print('host Promise Rejection Handler error: $e');
          return nullptr;
        }
        final throwObj = _dartToJs(ctx, e);
        final err = jsThrow(ctx, throwObj);
        jsFreeValue(ctx, throwObj);
        if (type == JSChannelType.MODULE) {
          jsFreeValue(ctx, err);
          return nullptr;
        }
        return err;
      }
    }, port);
    final stackSize = this.stackSize ?? 0;
    if (stackSize > 0) jsSetMaxStackSize(rt, stackSize);
    _rt = rt;
    _ctx = jsNewContext(rt);
  }

  /// Free Runtime and Context which can be recreate when evaluate again.
  close() {
    final rt = _rt;
    final ctx = _ctx;
    _rt = null;
    _ctx = null;
    if (ctx != null) jsFreeContext(ctx);
    if (rt == null) return;
    _executePendingJob();
    try {
      jsFreeRuntime(rt);
    } on String catch (e) {
      throw JSError(e);
    }
  }

  void _executePendingJob() {
    final rt = _rt;
    final ctx = _ctx;
    if (rt == null || ctx == null) return;
    while (true) {
      int err = jsExecutePendingJob(rt);
      if (err <= 0) {
        if (err < 0) print(_parseJSException(ctx));
        break;
      }
    }
  }

  /// Dispatch JavaScript Event loop.
  Future<void> dispatch() async {
    await for (final _ in port) {
      _executePendingJob();
    }
  }

  /// Evaluate js script.
  dynamic evaluate(
    String command, {
    String? name,
    int? evalFlags,
  }) {
    _ensureEngine();
    final ctx = _ctx!;
    final jsval = jsEval(
      ctx,
      command,
      name ?? '<eval>',
      evalFlags ?? JSEvalFlag.GLOBAL,
    );
    if (jsIsException(jsval) != 0) {
      jsFreeValue(ctx, jsval);
      throw _parseJSException(ctx);
    }
    final result = _jsToDart(ctx, jsval);
    jsFreeValue(ctx, jsval);
    return result;
  }

  @override
  JsEvalResult callFunction(Pointer<NativeType> fn, Pointer<NativeType> obj) {
    // TODO: implement callFunction
    throw UnimplementedError();
  }

  @override
  T convertValue<T>(JsEvalResult jsValue) {
    // TODO: implement convertValue
    throw UnimplementedError();
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  Future<JsEvalResult> evaluateAsync(String code) {
    // TODO: implement evaluateAsync
    throw UnimplementedError();
  }

  @override
  int executePendingJob() {
    // TODO: implement executePendingJob
    throw UnimplementedError();
  }

  @override
  String getEngineInstanceId() {
    // TODO: implement getEngineInstanceId
    throw UnimplementedError();
  }

  @override
  void initChannelFunctions() {
    // TODO: implement initChannelFunctions
  }

  @override
  String jsonStringify(JsEvalResult jsValue) {
    // TODO: implement jsonStringify
    throw UnimplementedError();
  }

  @override
  bool setupBridge(String channelName, void Function(dynamic args) fn) {
    mapJsBridge[channelName] = fn;
    return true;
  }
}
