import 'dart:io';

import 'package:flutter_js/javascript_runtime.dart';
import 'package:flutter_js/javascriptcore/jscore_runtime.dart';
import 'package:flutter_js/quickjs/quickjs_runtime.dart';

import './extensions/fetch.dart';
import './extensions/handle_promises.dart';

export './javascript_runtime.dart';

export './quickjs/quickjs_runtime.dart';

export './extensions/handle_promises.dart';

JavascriptRuntime getJavascriptRuntime(
    {bool forceJavascriptCoreOnAndroid = false, bool xhr = true}) {
  JavascriptRuntime runtime;
  if ((Platform.isAndroid || Platform.isWindows) && !forceJavascriptCoreOnAndroid) {
    runtime = QuickJsRuntime('fileQuickjs.js');
  } else {
    runtime = JavascriptCoreRuntime();
  }
  setFetchDebug(true);
  if (xhr) runtime.enableFetch();
  runtime.enableHandlePromises();
  return runtime;
}
