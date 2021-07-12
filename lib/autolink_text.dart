library autolink_text;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class _AutolinkTextComponent {
  final String text;
  final bool isLink;

  _AutolinkTextComponent({required this.text, required this.isLink});
}

class AutolinkText extends StatefulWidget {
  static const Color defaultLinkColor = Color(0xff0085FF);
  final String text;
  final TextStyle style;
  final Color linkColor;
  final Function(String url) handleTapOnUrl;
  final bool enableShowMore;
  final int showMoreLineLimit;
  final String showMoreText;
  final String showLessText;

  const AutolinkText(
    this.text, {
    Key? key,
    required this.handleTapOnUrl,
    this.style = const TextStyle(),
    this.linkColor = defaultLinkColor,
    this.enableShowMore = false,
    this.showMoreLineLimit = 3,
    this.showMoreText = "show more...",
    this.showLessText = "show less",
  }) : super(key: key);

  @override
  _AutolinkTextState createState() => _AutolinkTextState();
}

class _AutolinkTextState extends State<AutolinkText> {
  static const MAX_LINES = 99999;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final matches = _getRegExpMatches();
    final textComponents = _getTextComponents(matches);
    final tailText = _getTailText(matches);
    final style = this.widget.style;
    final linkStyle = _getLinkStyle(style);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          maxLines: widget.enableShowMore
              ? _isExpanded
                  ? MAX_LINES
                  : widget.showMoreLineLimit
              : MAX_LINES,
          text: TextSpan(
            style: style,
            children: [
              ...textComponents
                  .map(
                    (e) => TextSpan(
                        text: e.text,
                        style: e.isLink ? linkStyle : style,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _openLink(e.text);
                          }),
                  )
                  .toList(),
              TextSpan(
                text: tailText,
                style: style,
              )
            ],
          ),
        ),
        if (widget.enableShowMore)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: Text(
                _isExpanded ? widget.showLessText : widget.showMoreText,
                style: style.copyWith(color: Colors.black.withAlpha((0.38 * 255).round())),
              ),
            ),
          ),
      ],
    );
  }

  List<RegExpMatch> _getRegExpMatches() {
    RegExp exp = new RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');

    List<RegExpMatch> matches = exp.allMatches(widget.text).toList();
    matches.removeWhere((match) {
      final textComponent = (widget.text.substring(match.start, match.end));
      final cleanComponent = textComponent.replaceAll(".", "");
      final isNumeric = _isTextNumeric(cleanComponent);

      var endsWithDomain = textComponent.split(".").last == textComponent.split(".").last.toLowerCase();
      if (textComponent.split(".").last.length <= 1) {
        endsWithDomain = false;
      }

      return isNumeric || !endsWithDomain;
    });
    return matches;
  }

  bool _isTextNumeric(String text) {
    return RegExp(r'^\d+$').hasMatch(text);
  }

  List<_AutolinkTextComponent> _getTextComponents(List<RegExpMatch> matches) {
    List<_AutolinkTextComponent> textComponents = [];
    var offset = 0;
    matches.forEach((match) {
      final textComponent = (widget.text.substring(offset, match.start));
      final linkComponent = (widget.text.substring(match.start, match.end));
      offset = match.end;
      textComponents.add(_AutolinkTextComponent(text: textComponent, isLink: false));
      textComponents.add(_AutolinkTextComponent(text: linkComponent, isLink: true));
    });
    return textComponents;
  }

  String _getTailText(List<RegExpMatch> matches) {
    return (widget.text.substring(matches.length == 0 ? 0 : matches.last.end, widget.text.length));
  }

  TextStyle _getLinkStyle(TextStyle style) {
    return style.copyWith(
      color: Colors.transparent,
      decoration: TextDecoration.underline,
      decorationColor: AutolinkText.defaultLinkColor,
      shadows: [Shadow(offset: Offset(0, -2), color: AutolinkText.defaultLinkColor)],
    );
  }

  _openLink(String url) {
    widget.handleTapOnUrl(url);
  }
}
