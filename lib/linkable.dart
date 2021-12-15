import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkable/constants.dart';
import 'package:linkable/emailParser.dart';
import 'package:linkable/httpParser.dart';
import 'package:linkable/link.dart';
import 'package:linkable/parser.dart';
import 'package:linkable/telParser.dart';
import 'package:url_launcher/url_launcher.dart';

class Linkable extends StatelessWidget {
  final String text;

  final Color? textColor;

  final Color? linkColor;

  final TextStyle? style;

  final TextAlign? textAlign;

  final TextDirection? textDirection;

  final int? maxLines;

  final double? textScaleFactor;

  final StrutStyle? strutStyle;

  final TextWidthBasis? textWidthBasis;

  final TextHeightBehavior? textHeightBehavior;

  final void Function(String value)? onTelephoneTap;

  final void Function(String value)? onLinkTap;

  final void Function(String value)? onEmailTap;

  final TextSpan Function(String value, GestureRecognizer function)? mobileSpan;

  final String? mobileRegExp;

  List<Parser> _parsers = <Parser>[];
  List<Link> _links = <Link>[];

  Linkable({
    Key? key,
    required this.text,
    this.textColor = Colors.black,
    this.linkColor = Colors.blue,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.mobileRegExp,
    this.onTelephoneTap,
    this.onLinkTap,
    this.onEmailTap,
    this.mobileSpan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    init();
    return SelectableText.rich(
      TextSpan(
        text: '',
        style: style,
        children: _getTextSpans(),
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }

  List<TextSpan> _getTextSpans() {
    List<TextSpan> _textSpans = <TextSpan>[];
    int i = 0;
    int pos = 0;
    while (i < text.length) {
      _textSpans.add(_text(text.substring(
          i,
          pos < _links.length && i <= _links[pos].regExpMatch.start
              ? _links[pos].regExpMatch.start
              : text.length)));
      if (pos < _links.length && i <= _links[pos].regExpMatch.start) {
        _textSpans.add(_link(
            text.substring(
                _links[pos].regExpMatch.start, _links[pos].regExpMatch.end),
            _links[pos].type));
        i = _links[pos].regExpMatch.end;
        pos++;
      } else {
        i = text.length;
      }
    }
    return _textSpans;
  }

  TextSpan _text(String text) {
    return TextSpan(text: text, style: TextStyle(color: textColor));
  }

  TextSpan _link(String text, String type) {
    if (type == tel && mobileSpan != null) {
      return mobileSpan!(
        text,
        TapGestureRecognizer()..onTap = () => _onTap(text, type),
      );
    }
    return TextSpan(
      text: text,
      style: TextStyle(color: linkColor),
      recognizer: TapGestureRecognizer()..onTap = () => _onTap(text, type),
    );
  }

  void _onTap(String text, String type) {
    switch (type) {
      case http:
        return onLinkTap != null
            ? onLinkTap!(text)
            : _launch(_getUrl(text, type));
      case email:
        return onEmailTap != null
            ? onEmailTap!(text)
            : _launch(_getUrl(text, type));
      case tel:
        return onTelephoneTap != null
            ? onTelephoneTap!(text)
            : _launch(_getUrl(text, type));
      default:
        return _launch(_getUrl(text, type));
    }
  }

  void _launch(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _getUrl(String text, String type) {
    switch (type) {
      case http:
        return text.substring(0, 4) == 'http' ? text : 'http://$text';
      case email:
        return text.substring(0, 7) == 'mailto:' ? text : 'mailto:$text';
      case tel:
        return text.substring(0, 4) == 'tel:' ? text : 'tel:$text';
      default:
        return text;
    }
  }

  void init() {
    _addParsers();
    _parseLinks();
    _filterLinks();
  }

  void _addParsers() {
    _parsers.add(EmailParser(text));
    _parsers.add(HttpParser(text));
    _parsers.add(
      TelParser(
        text,
        regExpPattern: mobileRegExp,
      ),
    );
  }

  void _parseLinks() {
    for (Parser parser in _parsers) {
      _links.addAll(parser.parse().toList());
    }
  }

  void _filterLinks() {
    _links.sort(
        (Link a, Link b) => a.regExpMatch.start.compareTo(b.regExpMatch.start));

    List<Link> _filteredLinks = <Link>[];
    if (_links.length > 0) {
      _filteredLinks.add(_links[0]);
    }

    for (int i = 0; i < _links.length - 1; i++) {
      if (_links[i + 1].regExpMatch.start > _links[i].regExpMatch.end) {
        _filteredLinks.add(_links[i + 1]);
      }
    }
    _links = _filteredLinks;
  }
}
