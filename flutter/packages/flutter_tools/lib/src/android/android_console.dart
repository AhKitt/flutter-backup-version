// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import '../base/context.dart';
import '../base/io.dart';
import '../convert.dart';

/// Default factory that creates a real Android console connection.
final AndroidConsoleSocketFactory _kAndroidConsoleSocketFactory = (String host, int port) => Socket.connect( host,  port);

/// Currently active implementation of the AndroidConsoleFactory.
///
/// The default implementation will create real connections to a device.
/// Override this in tests with an implementation that returns mock responses.
AndroidConsoleSocketFactory get androidConsoleSocketFactory => context.get<AndroidConsoleSocketFactory>() ?? _kAndroidConsoleSocketFactory;

typedef AndroidConsoleSocketFactory = Future<Socket> Function(String host, int port);

/// Creates a console connection to an Android emulator that can be used to run
/// commands such as "avd name" which are not available to ADB.
///
/// See documentation at
/// https://developer.android.com/studio/run/emulator-console
class AndroidConsole {
  AndroidConsole(this._socket);

  Socket _socket;
  StreamQueue<String> _queue;

  Future<void> connect() async {
    assert(_socket != null);
    assert(_queue == null);

    _queue = StreamQueue<String>(_socket.asyncMap(ascii.decode));

    // Discard any initial connection text.
    await _readResponse();
  }

  Future<String> getAvdName() async {
    _write('avd name\n');
    return _readResponse();
  }

  void destroy() {
    if (_socket != null) {
      _socket.destroy();
      _socket = null;
      _queue = null;
    }
  }

  Future<String> _readResponse() async {
    final StringBuffer output = StringBuffer();
    while (true) {
      final String text = await _queue.next;
      final String trimmedText = text.trim();
      if (trimmedText == 'OK')
        break;
      if (trimmedText.endsWith('\nOK')) {
        output.write(trimmedText.substring(0, trimmedText.length - 3));
        break;
      }
      output.write(text);
    }
    return output.toString().trim();
  }

  void _write(String text) {
    _socket.add(ascii.encode(text));
  }
}
