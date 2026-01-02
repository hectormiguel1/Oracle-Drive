import 'package:flutter/material.dart';
import 'ztr_data.dart';

class ZtrParser {
  static final RegExp pluralExp = RegExp(
    r'^(.*?)\{End\}\s*\{StraightLine\}(.*?)\{End\}\s*\{Article\}(.*?)(?:\{End\}\s*\{ArticleMany\}(.*))?$',
    dotAll: true,
  );
  static final RegExp tokenExp = RegExp(r'([+-]?\{[^}]+\})|([^{]+)');
  static final RegExp tagExp = RegExp(
    r'\{(Color|Icon|Btn|Text|Counter) ([^}]+)\}',
  );

  static String stripTags(String text) {
    final StringBuffer buffer = StringBuffer();

    final Match? pluralMatch =
        (text.contains('{StraightLine}') && text.contains('{Article}'))
            ? pluralExp.firstMatch(text)
            : null;

    if (pluralMatch != null) {
      final String singularBase = pluralMatch.group(1)!.trim();
      final String pluralBase = pluralMatch.group(2)!.trim();
      final String prefix = pluralMatch.group(3)!.trim();
      final String? prefixMany = pluralMatch.group(4)?.trim();

      String singularFull = singularBase;
      if (prefix.isNotEmpty) {
        singularFull = '$prefix $singularBase';
      }

      if (singularFull.isNotEmpty) {
        final firstChar = singularFull[0];
        if (firstChar.toUpperCase() != firstChar) {
          singularFull = firstChar.toUpperCase() + singularFull.substring(1);
        }
      }

      String pluralFull = pluralBase;
      if (prefixMany != null && prefixMany.isNotEmpty) {
        pluralFull = '$prefixMany $pluralBase';
      }

      if (pluralFull.isNotEmpty) {
        final firstChar = pluralFull[0];
        if (firstChar.toUpperCase() != firstChar) {
          pluralFull = firstChar.toUpperCase() + pluralFull.substring(1);
        }
      }

      buffer.write('SINGLE: ');
      buffer.write(parseTextToString(singularFull));
      buffer.write('\nMULTIPLE: ');
      buffer.write(parseTextToString(pluralFull));
    } else {
      buffer.write(parseTextToString(text));
    }

    return buffer.toString();
  }

  static String parseTextToString(String text) {
    final StringBuffer buffer = StringBuffer();
    tokenExp.allMatches(text).forEach((match) {
      final String? token = match.group(1);
      final String? plainText = match.group(2);

      if (plainText != null && plainText.isNotEmpty) {
        buffer.write(plainText);
      } else if (token != null && token.isNotEmpty) {
        final bool isCounter = token.startsWith('+') || token.startsWith('-');
        String cleanToken = token;
        if (isCounter) {
          cleanToken = token.substring(1);
        }

        final tagMatch = tagExp.firstMatch(cleanToken);

        if (tagMatch != null) {
          final String type = tagMatch.group(1)!;
          final String value = tagMatch.group(2)!;

          if (type == 'Btn') {
            String label = value;
            if (label.startsWith('Btn ')) label = label.substring(4);
            buffer.write(label);
          } else if (type == 'Text' && value == 'NewLine') {
            buffer.write('\n');
          } else if (type == 'Counter') {
            buffer.write('X');
          }
        }
      }
    });
    return buffer.toString();
  }

  static void parseTextToSpans(
    String text,
    ZtrGameConfig config,
    TextStyle? style,
    List<InlineSpan> spans,
    String? variableReplacement,
  ) {
    Color currentColor = style?.color ?? Colors.white;

    tokenExp.allMatches(text).forEach((match) {
      final String? token = match.group(1);
      final String? plainText = match.group(2);

      if (plainText != null && plainText.isNotEmpty) {
        spans.add(
          TextSpan(
            text: plainText,
            style:
                style?.copyWith(color: currentColor) ??
                TextStyle(color: currentColor),
          ),
        );
      } else if (token != null && token.isNotEmpty) {
        final bool isCounter = token.startsWith('+') || token.startsWith('-');
        String cleanToken = token;
        if (isCounter) {
          cleanToken = token.substring(1);
        }

        final tagMatch = tagExp.firstMatch(cleanToken);

        if (tagMatch != null) {
          final String type = tagMatch.group(1)!;
          final String value = tagMatch.group(2)!;

          if (type == 'Color') {
            if (config.colorMap.containsKey(value)) {
              currentColor = config.colorMap[value]!;
            } else if (value.startsWith('Ex')) {
              currentColor = Colors.white54;
            }
          } else if (type == 'Icon') {
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Tooltip(
                  message: value,
                  child: Icon(
                    config.iconMap[value] ?? Icons.help_outline,
                    color: currentColor,
                    size: (style?.fontSize ?? 14.0) * 1.2,
                  ),
                ),
              ),
            );
          } else if (type == 'Btn') {
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: buildButtonChip(value, (style?.fontSize ?? 14.0)),
              ),
            );
          } else if (type == 'Text' && value == 'NewLine') {
            spans.add(
              TextSpan(
                text: '\n',
                style: style?.copyWith(color: currentColor),
              ),
            );
          } else if (type == 'Counter') {
            spans.add(
              TextSpan(
                text: variableReplacement ?? 'X',
                style:
                    style?.copyWith(
                      color: currentColor,
                      fontWeight: FontWeight.w900,
                    ) ??
                    TextStyle(color: currentColor, fontWeight: FontWeight.bold),
              ),
            );
          }
        }
      }
    });
  }

  static Widget buildButtonChip(String btnName, double fontSize) {
    String label = btnName;
    if (label.startsWith('Btn ')) label = label.substring(4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize * 0.8,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
