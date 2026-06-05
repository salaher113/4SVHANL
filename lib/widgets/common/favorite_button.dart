import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const FavoriteButton({super.key, required this.isFavorite, required this.onTap});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _focused ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _focused ? Colors.blueAccent : Colors.transparent, width: 2),
          ),
          child: Icon(
            widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: _focused ? Colors.black : (widget.isFavorite ? Colors.redAccent : Colors.white),
            size: 22,
          ),
        ),
      ),
    );
  }
}
