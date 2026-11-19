@TestOn('mac-os')
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_js/javascriptcore/jscore_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late JavascriptCoreRuntime runtime;
  late List<dynamic> received;
  late Future<dynamic> reply;

  setUp(() {
    runtime = JavascriptCoreRuntime();
    received = [];
    runtime.onMessage('report', (args) => received.add(args));
    runtime.onMessage('reply', (_) => reply);
  });

  tearDown(() => runtime.dispose());

  Future<dynamic> roundTrip(Future<dynamic> nextReply) async {
    reply = nextReply;
    runtime.evaluate('''
      sendMessage('reply', '{}').then(
        (v) => sendMessage('report', JSON.stringify({type: typeof v, value: v})),
        (e) => sendMessage('report', JSON.stringify({type: 'rejected', value: e})));
    ''');
    // SynchronousFuture.catchError never completes.
    if (reply is! SynchronousFuture) await reply.catchError((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(1));
    return received.single;
  }

  test('a String reply arrives as the same JS string', () async {
    const text = '{"a":1} "quoted"\nline \u{1F600} \u0000 end';
    expect(
        await roundTrip(Future.value(text)), {'type': 'string', 'value': text});
  });

  test('a JSON-encodable reply arrives as the decoded JS value', () async {
    expect(
        await roundTrip(Future.value({
          'a': [1, true, null]
        })),
        {
          'type': 'object',
          'value': {
            'a': [1, true, null]
          }
        });
    received.clear();
    expect(await roundTrip(Future.value([1, 2])), {
      'type': 'object',
      'value': [1, 2]
    });
    received.clear();
    expect(
        await roundTrip(Future.value(null)), {'type': 'object', 'value': null});
    received.clear();
    expect(
        await roundTrip(Future.value(1.5)), {'type': 'number', 'value': 1.5});
    received.clear();
    expect(await roundTrip(Future.value(false)),
        {'type': 'boolean', 'value': false});
  });

  test('a failed future rejects with the error text', () async {
    final error = 'bad "reply"\nnext line';
    expect(await roundTrip(Future.error(error)),
        {'type': 'rejected', 'value': error});
  });

  test('a SynchronousFuture reply resolves the promise', () async {
    expect(await roundTrip(SynchronousFuture('now')),
        {'type': 'string', 'value': 'now'});
  });
}
