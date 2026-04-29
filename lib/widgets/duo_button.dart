import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// Duolingo 风格按钮：绿色实心 + 底部阴影下沉效果
class DuoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;

  const DuoButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.color,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final btnColor = widget.color ?? AppTheme.primary;
    final shadowColor = widget.color != null
        ? widget.color!.withOpacity(0.6)
        : AppTheme.primaryShadow;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        height: 56,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.isLoading ? btnColor.withOpacity(0.7) : btnColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
