import 'package:flutter/material.dart';
import 'package:ff13_mod_resource/models/app_game_code.dart';
import 'ztr/ztr_data.dart';
import 'ztr/ztr_parser.dart';

class ZtrTextRenderer {
  static Widget render(
    String text,
    AppGameCode game, {
    TextStyle? style,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
    String? variableReplacement,
    bool displayMultiple = false,
  }) {
    // Fast path: if no tags, just return simple text
    if (!text.contains('{')) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final ZtrGameConfig config = ZtrGameConfig.forGame(game);
    final List<InlineSpan> spans = [];

    // Check for plural pattern
    final Match? pluralMatch =
        (text.contains('{StraightLine}') && text.contains('{Article}'))
            ? ZtrParser.pluralExp.firstMatch(text)
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

      if (displayMultiple) {
        spans.add(
          TextSpan(
            text: 'SINGLE: ',
            style: (style ?? const TextStyle()).copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        ZtrParser.parseTextToSpans(
          singularFull,
          config,
          style,
          spans,
          variableReplacement,
        );

        spans.add(const TextSpan(text: '\n'));

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

        spans.add(
          TextSpan(
            text: 'MULTIPLE: ',
            style: (style ?? const TextStyle()).copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        ZtrParser.parseTextToSpans(
          pluralFull,
          config,
          style,
          spans,
          variableReplacement,
        );
      } else {
        ZtrParser.parseTextToSpans(
          singularFull,
          config,
          style,
          spans,
          variableReplacement,
        );
      }
    } else {
      ZtrParser.parseTextToSpans(
        text,
        config,
        style,
        spans,
        variableReplacement,
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: overflow,
    );
  }

  static String stripTags(String text) {
    return ZtrParser.stripTags(text);
  }
}