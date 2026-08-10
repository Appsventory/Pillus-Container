import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

Future<bool> showFingerprintDialog(
  BuildContext context, {
  required String host,
  required String? keyType,
  required String? fingerprint,
  bool changed = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      title: Row(
        children: [
          Icon(
            changed ? Icons.warning_rounded : Icons.fingerprint_rounded,
            color: changed ? AppColors.danger : AppColors.accent,
          ),
          SizedBox(width: 10),
          Text(changed ? AppLocalizations.of(context).fingerprintChanged : AppLocalizations.of(context).verifyHost),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (changed)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                AppLocalizations.of(context).fingerprintChangedBody,
                style: TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                AppLocalizations.of(context).fingerprintNewBody,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          _row('Host', host),
          _row(AppLocalizations.of(context).keyType, keyType ?? '-'),
          SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              fingerprint ?? '-',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: changed ? AppColors.danger : AppColors.accent,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(changed ? AppLocalizations.of(context).continueAnyway : AppLocalizations.of(context).trustAndContinue),
        ),
      ],
    ),
  );
  return result ?? false;
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 12.5)),
        ),
      ],
    ),
  );
}
