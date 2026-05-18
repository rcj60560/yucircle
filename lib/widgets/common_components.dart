import 'package:flutter/material.dart';
import '../config/theme.dart';

/// ============ 常用组件库 - RYMONTADA 蓝色风格 ============

/// 蓝色主按钮
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.surface),
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// 文字按钮 (蓝色)
class TextPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final TextStyle? style;

  const TextPrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: style,
      ),
    );
  }
}

/// 蓝色卡片容器
class PrimaryCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double borderRadius;

  const PrimaryCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppTheme.radiusLarge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      shadowColor: AppTheme.cardShadow,
      elevation: onTap != null ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// 蓝色输入框
class PrimaryTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;

  const PrimaryTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.obscureText = false,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : null,
          validator: validator,
          onChanged: onChanged,
          textInputAction: textInputAction,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// 蓝色分割线
class PrimaryDivider extends StatelessWidget {
  final double height;
  final double thickness;

  const PrimaryDivider({
    Key? key,
    this.height = 1,
    this.thickness = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      color: AppTheme.border,
    );
  }
}

/// 蓝色标签/Tag
class PrimaryTag extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryTag({
    Key? key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? backgroundColor ?? AppTheme.primary
        : backgroundColor ?? AppTheme.background;
    final tColor = isSelected
        ? textColor ?? AppTheme.surface
        : textColor ?? AppTheme.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: !isSelected
              ? Border.all(color: AppTheme.border, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: tColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// 蓝色圆形按钮 (用于图标)
class PrimaryIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const PrimaryIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.primary,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.surface,
        ),
      ),
    );
  }
}

/// 蓝色进度指示器
class PrimaryProgressBar extends StatelessWidget {
  final double value; // 0 到 1
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;

  const PrimaryProgressBar({
    Key? key,
    required this.value,
    this.height = 4,
    this.backgroundColor,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: backgroundColor ?? AppTheme.border,
        valueColor: AlwaysStoppedAnimation<Color>(
          valueColor ?? AppTheme.primary,
        ),
      ),
    );
  }
}

/// 蓝色信息提示框
class PrimaryInfoBox extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const PrimaryInfoBox({
    Key? key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: backgroundColor ?? AppTheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? AppTheme.primary,
            ),
            SizedBox(width: AppTheme.spacing12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? AppTheme.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 蓝色加载对话框
class PrimaryLoadingDialog extends StatelessWidget {
  final String? message;

  const PrimaryLoadingDialog({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  strokeWidth: 3,
                ),
              ),
              if (message != null) ...[
                SizedBox(height: AppTheme.spacing16),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 蓝色空状态
class PrimaryEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onRetry;

  const PrimaryEmptyState({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: AppTheme.spacing16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: AppTheme.spacing8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: AppTheme.spacing20),
            PrimaryButton(
              label: '重试',
              onPressed: onRetry!,
            ),
          ],
        ],
      ),
    );
  }
}

/// 蓝色顶部消息条
class PrimarySnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppTheme.danger : AppTheme.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }
}
