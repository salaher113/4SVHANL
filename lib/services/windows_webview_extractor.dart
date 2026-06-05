import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';

class WindowsWebviewExtractor {
  static Future<String?> extractM3u8(String url) async {
    if (!Platform.isWindows) return null;
    
    final controller = WebviewController();
    final completer = Completer<String?>();
    
    try {
      await controller.initialize();
      // Try to suppress popups
      await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Listen for messages from injected JS
      final subscription = controller.webMessage.listen((message) {
        if (!completer.isCompleted && message != null) {
          final msgStr = message.toString();
          if (msgStr.contains('.m3u8')) {
            completer.complete(msgStr);
          }
        }
      });

      // We will inject a script to intercept network requests.
      // webview_windows might not have addScriptToExecuteOnDocumentCreated 
      // but we can try to inject it periodically or use the built in.
      // Wait, there is a way to intercept XMLHttpRequest and fetch
      final script = '''
        (function() {
          if (window.__intercepted) return;
          window.__intercepted = true;
          
          const origFetch = window.fetch;
          window.fetch = async function() {
            const url = arguments[0];
            if (typeof url === 'string' && url.indexOf('.m3u8') !== -1) {
              window.chrome.webview.postMessage(url);
            }
            return origFetch.apply(this, arguments);
          };

          const origOpen = XMLHttpRequest.prototype.open;
          XMLHttpRequest.prototype.open = function() {
            const url = arguments[1];
            if (typeof url === 'string' && url.indexOf('.m3u8') !== -1) {
              window.chrome.webview.postMessage(url);
            }
            return origOpen.apply(this, arguments);
          };
        })();
      ''';

      // Load the URL
      await controller.loadUrl(url);

      // We need to continuously inject the script because we might miss the window load
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (completer.isCompleted) {
          timer.cancel();
          return;
        }
        try {
          controller.executeScript(script);
        } catch (_) {}
      });

      // Also timeout after 25 seconds
      Timer(const Duration(seconds: 25), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      final result = await completer.future;
      subscription.cancel();
      controller.dispose();
      return result;
      
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
      return null;
    }
  }
}
