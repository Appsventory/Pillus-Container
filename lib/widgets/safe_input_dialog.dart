import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dialog input yang aman: [TextEditingController] dimiliki State dialog,
/// di-dispose setelah route benar-benar unmount — mencegah assertion
/// `_dependents.isEmpty` saat user menekan Cancel.
Future<String?> showSafeInputDialog({
  required BuildContext context,
  required String title,
  required String actionLabel,
  required String cancelLabel,
  String? hint,
  String? initialValue,
  IconData icon = Icons.edit_outlined,
  Color? iconColor,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _SafeInputDialog(
      title: title,
      actionLabel: actionLabel,
      cancelLabel: cancelLabel,
      hint: hint,
      initialValue: initialValue,
      icon: icon,
      iconColor: iconColor ?? AppColors.accent,
    ),
  );
}

class _SafeInputDialog extends StatefulWidget {
  final String title;
  final String actionLabel;
  final String cancelLabel;
  final String? hint;
  final String? initialValue;
  final IconData icon;
  final Color iconColor;

  const _SafeInputDialog({
    required this.title,
    required this.actionLabel,
    required this.cancelLabel,
    this.hint,
    this.initialValue,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<_SafeInputDialog> createState() => _SafeInputDialogState();
}

class _SafeInputDialogState extends State<_SafeInputDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(widget.icon, color: widget.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceDarkAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

/// Dispose controller setelah frame berikutnya — fallback bila dialog
/// custom masih memakai controller eksternal.
void disposeControllerLater(TextEditingController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
}
