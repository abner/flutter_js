// import 'dart:async';

// import 'package:flutter_js/flutter_js.dart';

// // example to show how to an api call can be made and used a Future in dart
// Future<dynamic> getUser() {
//   final completer = Completer();
//   const code = """
//     try {
//       const response = await fetch('https://reqres.in/api/users?page=2');
//       const body = await response.json();
//       if (response.status === 200) {
//         sendMessage('onRequestSuccess', JSON.stringify(body));
//       } else {
//         sendMessage('onRequestFailure', JSON.stringify(body));
//       }
//     } catch(e) {
//       console.log(e.message);
//       sendMessage('onError', e.message);
//     }
//   """;
//   final jsRuntime = getJavascriptRuntime();
//   jsRuntime.onMessage('onRequestSuccess', completer.complete);
//   jsRuntime.onMessage('onRequestFailure', (args) {
//     completer.completeError(args);
//   });
//   jsRuntime.onMessage('onError', (args) {
//     completer.completeError(args);
//   });
//   return completer.future;
// }
