class HtmlUtils {
  /// Map of additional common entities that might be missed
  static const Map<String, String> _additionalEntities = {
    // Math symbols
    '&times;': '×',
    '&divide;': '÷',
    '&frac12;': '½',
    '&frac14;': '¼',
    '&frac34;': '¾',
    '&sup2;': '²',
    '&sup3;': '³',

    // Currency and financial
    '&cent;': '¢',
    '&curren;': '¤',

    // Additional Vietnamese-specific (rare but possible)
    '&ETH;': 'Ð',
    '&eth;': 'ð',
    '&THORN;': 'Þ',
    '&thorn;': 'þ',
    '&szlig;': 'ß',

    // Space variants
    '&ensp;': ' ',    // en space
    '&emsp;': ' ',    // em space
    '&thinsp;': ' ',  // thin space
    '&zwnj;': '',     // zero width non-joiner
    '&zwj;': '',      // zero width joiner
  };

  static String decodeHtmlEntities(String text) {
    if (text.isEmpty) return text;

    String result = text;

    // First handle named entities (most common in Vietnamese news)
    result = result
        // Basic HTML entities (most critical first)
        .replaceAll('&amp;', '&')     // Must be first to avoid double decoding
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')

        // Quote characters - CRITICAL for Vietnamese news titles
        .replaceAll('&lsquo;', "'")   // left single quotation mark
        .replaceAll('&rsquo;', "'")   // right single quotation mark
        .replaceAll('&ldquo;', '"')   // left double quotation mark
        .replaceAll('&rdquo;', '"')   // right double quotation mark
        .replaceAll('&sbquo;', '‚')   // single low-9 quotation mark
        .replaceAll('&bdquo;', '„')   // double low-9 quotation mark
        .replaceAll('&laquo;', '«')   // left-pointing double angle quotation mark
        .replaceAll('&raquo;', '»')   // right-pointing double angle quotation mark
        .replaceAll('&lsaquo;', '‹')  // left-pointing single angle quotation mark
        .replaceAll('&rsaquo;', '›')  // right-pointing single angle quotation mark

        // Dashes and special punctuation (very common in news)
        .replaceAll('&ndash;', '–')   // en dash
        .replaceAll('&mdash;', '—')   // em dash
        .replaceAll('&hellip;', '…')  // horizontal ellipsis
        .replaceAll('&bull;', '•')    // bullet
        .replaceAll('&middot;', '·')  // middle dot
        .replaceAll('&prime;', '′')   // prime
        .replaceAll('&Prime;', '″')   // double prime
        .replaceAll('&minus;', '−')   // minus sign

        // Common symbols
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™')
        .replaceAll('&euro;', '€')
        .replaceAll('&pound;', '£')
        .replaceAll('&yen;', '¥')
        .replaceAll('&sect;', '§')
        .replaceAll('&para;', '¶')
        .replaceAll('&dagger;', '†')
        .replaceAll('&Dagger;', '‡')
        .replaceAll('&permil;', '‰')
        .replaceAll('&deg;', '°')     // degree symbol
        .replaceAll('&plusmn;', '±')  // plus-minus

        // Vietnamese characters with accents - A characters (complete set)
        .replaceAll('&agrave;', 'à')  .replaceAll('&Agrave;', 'À')
        .replaceAll('&aacute;', 'á')  .replaceAll('&Aacute;', 'Á')
        .replaceAll('&acirc;', 'â')   .replaceAll('&Acirc;', 'Â')
        .replaceAll('&atilde;', 'ã')  .replaceAll('&Atilde;', 'Ã')
        .replaceAll('&auml;', 'ä')    .replaceAll('&Auml;', 'Ä')
        .replaceAll('&aring;', 'å')   .replaceAll('&Aring;', 'Å')

        // E characters (complete set)
        .replaceAll('&egrave;', 'è')  .replaceAll('&Egrave;', 'È')
        .replaceAll('&eacute;', 'é')  .replaceAll('&Eacute;', 'É')
        .replaceAll('&ecirc;', 'ê')   .replaceAll('&Ecirc;', 'Ê')
        .replaceAll('&euml;', 'ë')    .replaceAll('&Euml;', 'Ë')

        // I characters (complete set)
        .replaceAll('&igrave;', 'ì')  .replaceAll('&Igrave;', 'Ì')
        .replaceAll('&iacute;', 'í')  .replaceAll('&Iacute;', 'Í')
        .replaceAll('&icirc;', 'î')   .replaceAll('&Icirc;', 'Î')
        .replaceAll('&iuml;', 'ï')    .replaceAll('&Iuml;', 'Ï')

        // O characters (complete set)
        .replaceAll('&ograve;', 'ò')  .replaceAll('&Ograve;', 'Ò')
        .replaceAll('&oacute;', 'ó')  .replaceAll('&Oacute;', 'Ó')
        .replaceAll('&ocirc;', 'ô')   .replaceAll('&Ocirc;', 'Ô')
        .replaceAll('&otilde;', 'õ')  .replaceAll('&Otilde;', 'Õ')
        .replaceAll('&ouml;', 'ö')    .replaceAll('&Ouml;', 'Ö')
        .replaceAll('&oslash;', 'ø')  .replaceAll('&Oslash;', 'Ø')

        // U characters (complete set)
        .replaceAll('&ugrave;', 'ù')  .replaceAll('&Ugrave;', 'Ù')
        .replaceAll('&uacute;', 'ú')  .replaceAll('&Uacute;', 'Ú')
        .replaceAll('&ucirc;', 'û')   .replaceAll('&Ucirc;', 'Û')
        .replaceAll('&uuml;', 'ü')    .replaceAll('&Uuml;', 'Ü')

        // Y characters
        .replaceAll('&yacute;', 'ý')  .replaceAll('&Yacute;', 'Ý')
        .replaceAll('&yuml;', 'ÿ')

        // Vietnamese specific characters (most important)
        .replaceAll('&Dcroat;', 'Đ')  .replaceAll('&dcroat;', 'đ')  // Đ,đ
        .replaceAll('&Abreve;', 'Ă')  .replaceAll('&abreve;', 'ă')  // Ă,ă

        // Extended Vietnamese characters (comprehensive)
        .replaceAll('&Abreveacute;', 'Ắ')   .replaceAll('&abreveacute;', 'ắ')
        .replaceAll('&Abrevedot;', 'Ặ')     .replaceAll('&abrevedot;', 'ặ')
        .replaceAll('&Abrevegrave;', 'Ằ')   .replaceAll('&abrevegrave;', 'ằ')
        .replaceAll('&Abrevehook;', 'Ẳ')    .replaceAll('&abrevehook;', 'ẳ')
        .replaceAll('&Abrevetilde;', 'Ẵ')   .replaceAll('&abrevetilde;', 'ẵ')
        .replaceAll('&Acircumflexacute;', 'Ấ') .replaceAll('&acircumflexacute;', 'ấ')
        .replaceAll('&Acircumflexdot;', 'Ậ')   .replaceAll('&acircumflexdot;', 'ậ')
        .replaceAll('&Acircumflexgrave;', 'Ầ') .replaceAll('&acircumflexgrave;', 'ầ')
        .replaceAll('&Acircumflexhook;', 'Ẩ')  .replaceAll('&acircumflexhook;', 'ẩ')
        .replaceAll('&Acircumflextilde;', 'Ẫ') .replaceAll('&acircumflextilde;', 'ẫ')
        .replaceAll('&Adot;', 'Ạ')           .replaceAll('&adot;', 'ạ')
        .replaceAll('&Ahook;', 'Ả')          .replaceAll('&ahook;', 'ả')
        .replaceAll('&Ecircumflexacute;', 'Ế') .replaceAll('&ecircumflexacute;', 'ế')
        .replaceAll('&Ecircumflexdot;', 'Ệ')   .replaceAll('&ecircumflexdot;', 'ệ')
        .replaceAll('&Ecircumflexgrave;', 'Ề') .replaceAll('&ecircumflexgrave;', 'ề')
        .replaceAll('&Ecircumflexhook;', 'Ể')  .replaceAll('&ecircumflexhook;', 'ể')
        .replaceAll('&Ecircumflextilde;', 'Ễ') .replaceAll('&ecircumflextilde;', 'ễ')
        .replaceAll('&Edot;', 'Ẹ')           .replaceAll('&edot;', 'ẹ')
        .replaceAll('&Ehook;', 'Ẻ')          .replaceAll('&ehook;', 'ẻ')
        .replaceAll('&Etilde;', 'Ẽ')         .replaceAll('&etilde;', 'ẽ')
        .replaceAll('&Idot;', 'Ị')           .replaceAll('&idot;', 'ị')
        .replaceAll('&Ihook;', 'Ỉ')          .replaceAll('&ihook;', 'ỉ')
        .replaceAll('&Itilde;', 'Ĩ')         .replaceAll('&itilde;', 'ĩ')
        .replaceAll('&Ocircumflexacute;', 'Ố') .replaceAll('&ocircumflexacute;', 'ố')
        .replaceAll('&Ocircumflexdot;', 'Ộ')   .replaceAll('&ocircumflexdot;', 'ộ')
        .replaceAll('&Ocircumflexgrave;', 'Ồ') .replaceAll('&ocircumflexgrave;', 'ồ')
        .replaceAll('&Ocircumflexhook;', 'Ổ')  .replaceAll('&ocircumflexhook;', 'ổ')
        .replaceAll('&Ocircumflextilde;', 'Ỗ') .replaceAll('&ocircumflextilde;', 'ỗ')
        .replaceAll('&Odot;', 'Ọ')           .replaceAll('&odot;', 'ọ')
        .replaceAll('&Ohook;', 'Ỏ')          .replaceAll('&ohook;', 'ỏ')
        .replaceAll('&Ohorn;', 'Ơ')          .replaceAll('&ohorn;', 'ơ')
        .replaceAll('&Ohornacute;', 'Ớ')     .replaceAll('&ohornacute;', 'ớ')
        .replaceAll('&Ohorndot;', 'Ợ')       .replaceAll('&ohorndot;', 'ợ')
        .replaceAll('&Ohorngrave;', 'Ờ')     .replaceAll('&ohorngrave;', 'ờ')
        .replaceAll('&Ohornhook;', 'Ở')      .replaceAll('&ohornhook;', 'ở')
        .replaceAll('&Ohorntilde;', 'Ỡ')     .replaceAll('&ohorntilde;', 'ỡ')
        .replaceAll('&Udot;', 'Ụ')           .replaceAll('&udot;', 'ụ')
        .replaceAll('&Uhook;', 'Ủ')          .replaceAll('&uhook;', 'ủ')
        .replaceAll('&Uhorn;', 'Ư')          .replaceAll('&uhorn;', 'ư')
        .replaceAll('&Uhornacute;', 'Ứ')     .replaceAll('&uhornacute;', 'ứ')
        .replaceAll('&Uhorndot;', 'Ự')       .replaceAll('&uhorndot;', 'ự')
        .replaceAll('&Uhorngrave;', 'Ừ')     .replaceAll('&uhorngrave;', 'ừ')
        .replaceAll('&Uhornhook;', 'Ử')      .replaceAll('&uhornhook;', 'ử')
        .replaceAll('&Uhorntilde;', 'Ữ')     .replaceAll('&uhorntilde;', 'ữ')
        .replaceAll('&Utilde;', 'Ũ')         .replaceAll('&utilde;', 'ũ')
        .replaceAll('&Ydot;', 'Ỵ')           .replaceAll('&ydot;', 'ỵ')
        .replaceAll('&Yhook;', 'Ỷ')          .replaceAll('&yhook;', 'ỷ')
        .replaceAll('&Ytilde;', 'Ỹ')         .replaceAll('&ytilde;', 'ỹ');

    // Handle additional entities that might be missed
    _additionalEntities.forEach((entity, replacement) {
      result = result.replaceAll(entity, replacement);
    });

    // Handle numeric character references
    result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      try {
        final code = int.parse(match.group(1)!);
        if (code > 0 && code <= 1114111) { // Valid Unicode range
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      } catch (e) {
        return match.group(0)!;
      }
    });

    result = result.replaceAllMapped(RegExp(r'&#[xX]([0-9a-fA-F]+);'), (match) {
      try {
        final code = int.parse(match.group(1)!, radix: 16);
        if (code > 0 && code <= 1114111) { // Valid Unicode range
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      } catch (e) {
        return match.group(0)!;
      }
    });

    // Apply fallback method for any remaining problematic entities
    result = _handleRemainingEntities(result);

    return result;
  }

  /// Fallback method for stubborn entities
  static String _handleRemainingEntities(String text) {
    // Handle malformed entities that don't end with semicolon
    text = text.replaceAllMapped(RegExp(r'&([a-zA-Z]+)(?![a-zA-Z;])'), (match) {
      final entity = '&${match.group(1)!};';
      return _additionalEntities[entity] ?? match.group(0)!;
    });

    // Handle common typos in entities (missing semicolon)
    final commonTypos = {
      '&amp': '&',
      '&lt': '<',
      '&gt': '>',
      '&quot': '"',
      '&nbsp': ' ',
    };

    commonTypos.forEach((typo, replacement) {
      text = text.replaceAll(typo, replacement);
    });

    return text;
  }

  /// More aggressive cleaning for edge cases
  static String cleanText(String text) {
    if (text.isEmpty) return text;

    final cleaned = decodeHtmlEntities(text)
        // Remove any remaining malformed entities
        .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;?'), '')
        // Clean up multiple spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned;
  }
}

