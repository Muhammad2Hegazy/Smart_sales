import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// A widget that displays window control buttons (minimize, close)
/// on the top right corner of the screen.
/// 
/// This widget is designed to work with fullscreen desktop applications
/// and provides custom window controls since the native title bar is hidden.
class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowRestore() {
    // Restore to fullscreen when window is restored from minimized state
    windowManager.setFullScreen(true);
  }

  @override
  Widget build(BuildContext context) {
    // Only show on desktop platforms
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      right: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           _WindowButton(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            onPressed: () async {
              await windowManager.close();
            },
            hoverColor: const Color(0xFFE81123),
            iconColor: Colors.white.withValues(alpha: 0.9),
          ),
          // Minimize Button
          _WindowButton(
            icon: Icons.horizontal_rule_rounded,
            tooltip: 'Minimize',
            onPressed: () async {
              final isFullScreen = await windowManager.isFullScreen();
              if (isFullScreen) {
                await windowManager.setFullScreen(false);
              }
              await windowManager.minimize();
            },
            hoverColor: Colors.white.withValues(alpha: 0.1),
            iconColor: Colors.white.withValues(alpha: 0.9),
          ),
          // Close Button (on the right)
         
        ],
      ),
    );
  }
}

/// A single window control button with hover effects
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color iconColor;

  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.hoverColor,
    required this.iconColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46,
            height: 32,
            decoration: BoxDecoration(
              color: _isHovered ? widget.hoverColor : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapper widget that adds window controls overlay to any screen
/// Use this to wrap the root of your app to ensure controls appear everywhere
class WindowControlsOverlay extends StatelessWidget {
  final Widget child;

  const WindowControlsOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Only add overlay on desktop platforms
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return child;
    }

    return Stack(
      children: [
        child,
        const WindowControls(),
      ],
    );
  }
}
