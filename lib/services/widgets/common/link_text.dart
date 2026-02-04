import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';

class LinkText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final bool showPreview;
  final int? maxLines;
  final TextOverflow overflow;
  final Color? previewBackgroundColor;
  final Color? previewTextColor;

  const LinkText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.showPreview = false,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.previewBackgroundColor,
    this.previewTextColor,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final matches = _linkRegex.allMatches(text).toList();
    final spans = <TextSpan>[];
    var lastIndex = 0;
    String? firstUrl;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(text: text.substring(lastIndex, match.start), style: style),
        );
      }

      final rawUrl = text.substring(match.start, match.end);
      final normalized = _normalizeUrl(rawUrl);
      firstUrl ??= normalized;
      spans.add(
        TextSpan(
          text: rawUrl,
          style: linkStyle ?? style?.copyWith(color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openUrl(normalized),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: style));
    }

    final richText = RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );

    if (!showPreview || firstUrl == null) {
      return richText;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        richText,
        const SizedBox(height: 8),
        _LinkPreviewCard(
          url: firstUrl,
          backgroundColor: previewBackgroundColor,
          textColor: previewTextColor,
        ),
      ],
    );
  }

  static final RegExp _linkRegex = RegExp(
    r'((https?:\/\/|www\.)[^\s]+|\b[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*)',
    caseSensitive: false,
  );

  static String _normalizeUrl(String url) {
    url = _trimTrailingPunctuation(url);
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }

  static String _trimTrailingPunctuation(String url) {
    return url.replaceAll(RegExp(r'[),.!?:;]+$'), '');
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LinkPreviewCard extends StatelessWidget {
  final String url;
  final Color? backgroundColor;
  final Color? textColor;

  const _LinkPreviewCard({
    required this.url,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? url;
    final display = uri?.path.isNotEmpty == true ? '$host${uri?.path}' : host;
    final bg = backgroundColor ?? Colors.white.withOpacity(0.2);
    final fg = textColor ?? Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.link, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  display,
                  style: TextStyle(color: fg, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.openAction,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
