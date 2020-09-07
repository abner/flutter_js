import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:sync_http/sync_http.dart';

ReceivePort _callDartReceivePort = new ReceivePort();

void _setupCallDartPorts() {
  IsolateNameServer.registerPortWithName(
      _callDartReceivePort.sendPort, 'QuickJsServiceCallDart');

  _callDartReceivePort.listen((portMessage) {
    final decodedMessage = (portMessage as String).split(':');
    int idEngine = int.parse(decodedMessage[0]);
    String channel = decodedMessage[1];
    String message = utf8.decode(base64.decode(decodedMessage[2]));
  });
}

class QuickJsService extends JavascriptRuntime {
  ReceivePort _receivePort = new ReceivePort();
  SendPort _callServerSendPort;

  bool _ready = false;
  String _address;

  final FlutterJs _flutterJs;

  QuickJsService(this._flutterJs) {
    _startServer();
    IsolateNameServer.registerPortWithName(
        _receivePort.sendPort, 'QuickJsService');
    // TODO: remove from here
    initChannelFunctions();
  }

  bool get isReady => _ready;
  _startServer() async {
    _receivePort.listen((message) async {
      if (_address == null) {
        _address = message;
        _ready = true;
        return;
      }
      if (_callServerSendPort == null) {
        _callServerSendPort = message;
      }
    });
    return await FlutterIsolate.spawn(startQuickJsServer, 'init');
  }

  void dispose() {
    this._callServerSendPort.send('STOP');
  }

  JsEvalResult evaluate(String code) {
    if (!isReady)
      return JsEvalResult("string", null, isError: true, isPromise: false);
    var request = SyncHttpClient.postUrl(new Uri.http(
      _address,
      "",
      {
        "id": _flutterJs.id.toString(),
      },
    ));
    request..write(code);
    var response = request.close();
    return JsEvalResult(response.body, null,
        isPromise: response.body == 'isPromise', isError: false);
  }

  @override
  JsEvalResult callFunction(dynamic fn, dynamic obj) {
    throw UnimplementedError(
        'Call function yet not implemented in FlutterJS through Platform Channel');
    // _flutterJs.callFunction(fn, obj);
  }

  @override
  T convertValue<T>(JsEvalResult jsValue) {
    if (T is int) {
      return int.parse(jsValue.stringResult) as T;
    } else if (T is Map || T is List) {
      return jsonDecode(jsValue.stringResult) as T;
    } else if (T is double) {
      return double.parse(jsValue.stringResult) as T;
    } else if (T is num) {
      return num.parse(jsValue.stringResult) as T;
    }
    return jsValue.stringResult as T;
  }

  @override
  int executePendingJob() {
    evaluate('(function(){})();');
    return 0;
  }

  @override
  String getEngineInstanceId() {
    return _flutterJs.id.toString();
  }

  @override
  void initChannelFunctions() {
    JavascriptRuntime.channelFunctionsRegistered[getEngineInstanceId()] = {};
  }

  @override
  String jsonStringify(JsEvalResult jsValue) {
    return jsValue.stringResult;
  }

  @override
  bool setupBridge(String channelName, void Function(dynamic args) fn) {
    // final channelFunctionCallbacks =
    //     JavascriptRuntime.channelFunctionsRegistered[getEngineInstanceId()];
    // if (channelFunctionCallbacks.keys.contains(channelName)) return false;

    // channelFunctionCallbacks[channelName] = fn;
    _flutterJs.addChannel(channelName, (arg) {
      return Future.value(fn(arg) as String);
    });

    return true;
  }
}

void startQuickJsServer(String arg) async {
  var server = new QuickJsSyncServer();

  server.serve().then((address) {
    IsolateNameServer.lookupPortByName('QuickJsService').send(address);
    IsolateNameServer.lookupPortByName('QuickJsService')
        .send(server.dispatchSendPort);
  });
}

class QuickJsSyncServer {
  /// Server address
  InternetAddress address;

  SendPort get dispatchSendPort => _dispatchPort.sendPort;
  ReceivePort _dispatchPort;

  ReceivePort _receiveCallDartResponsePort = ReceivePort();

  /// Optional server port (note: might be already taken)
  /// Defaults to 0 (binds server to a random free port)
  int port;
  HttpServer _server;
  SyncHttpClient client;

  QuickJsSyncServer() {
    address = InternetAddress.loopbackIPv4;
    port = 0;
    _dispatchPort = new ReceivePort();

    IsolateNameServer.registerPortWithName(
      _receiveCallDartResponsePort.sendPort,
      'ReceiveCallDartResponsePort',
    );

    _dispatchPort.listen((message) {
      if (message == 'STOP') {
        _server.close();
      }
    });
  }

  /// Actual port server is listening on
  get boundPort => _server.port;

  /// Starts server
  Future<String> serve() async {
    _server = await HttpServer.bind(this.address, this.port);
    _server.listen(_handleReq);
    return '${_server.address.address}:${_server.port}';
  }

  _handleReq(HttpRequest request) async {
    String path = request.requestedUri.path.replaceFirst('/', '');

    if (path == '') {
      path = 'eval';
    }

    if (path == 'eval') {
      try {
        String code = await utf8.decoder.bind(request).join();
        String idEngine = request.uri.queryParameters['id'];

        String result =
            json.decode(await FlutterJs.evaluate(code, int.parse(idEngine)));

        var response = request.response;
        response
          ..contentLength = result.length
          ..write(result)
          ..close();
      } catch (err) {
        request.response
          ..statusCode = 500
          ..write("ERROR")
          ..close();
      }
    } else {
      // if not is eval it should be call to Dart
      String message = await utf8.decoder.bind(request).join();
      String idEngine = request.uri.queryParameters['id'];
      String channel = request.uri.queryParameters['channel'];

      final callDartPort =
          IsolateNameServer.lookupPortByName('QuickJsServiceCallDart');

      callDartPort
          .send("$idEngine:$channel:${base64.encode(utf8.encode(message))}");

      try {
        final result = await _receiveCallDartResponsePort.take(1).first;

        var response = request.response;
        response
          ..contentLength = result.length
          ..write(result)
          ..close();
      } catch (err) {
        request.response
          ..statusCode = 500
          ..write("ERROR")
          ..close();
      }
    }
  }
}
