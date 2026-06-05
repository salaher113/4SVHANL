import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';

class WindowsWebviewPlayer extends StatefulWidget {
  final String url;
  final VoidCallback onBack;

  const WindowsWebviewPlayer({
    Key? key,
    required this.url,
    required this.onBack,
  }) : super(key: key);

  @override
  State<WindowsWebviewPlayer> createState() => _WindowsWebviewPlayerState();
}

class _WindowsWebviewPlayerState extends State<WindowsWebviewPlayer> {
  final _controller = WebviewController();
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  Future<void> _initWebview() async {
    try {
      await _controller.initialize();
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl(widget.url);
      
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Webview initialization failed: ${e.message}';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    return Stack(
      children: [
        Webview(
          _controller,
          permissionRequested: (url, permissionKind, isUserInitiated) async {
            return WebviewPermissionDecision.allow;
          },
        ),
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: widget.onBack,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
