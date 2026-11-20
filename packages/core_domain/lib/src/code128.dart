// Code 128 Subset C encoder: digits in pairs (values 00 to 99). The 12-digit
// garment barcode has an even length, so it fits Subset C exactly.
//
// The pattern table is the public ISO/IEC 15417 table (bar/space widths in
// modules, 6 per symbol). It was extracted from the pub.dev package barcode
// 2.2.9 (Apache-2.0) and every symbol was checked: 103 distinct patterns, each
// summing to 11 modules; the encoder is also tested against that package.

const List<String> _patterns = [
  '212222',
  '222122',
  '222221',
  '121223',
  '121322',
  '131222',
  '122213',
  '122312',
  '132212',
  '221213',
  '221312',
  '231212',
  '112232',
  '122132',
  '122231',
  '113222',
  '123122',
  '123221',
  '223211',
  '221132',
  '221231',
  '213212',
  '223112',
  '312131',
  '311222',
  '321122',
  '321221',
  '312212',
  '322112',
  '322211',
  '212123',
  '212321',
  '232121',
  '111323',
  '131123',
  '131321',
  '112313',
  '132113',
  '132311',
  '211313',
  '231113',
  '231311',
  '112133',
  '112331',
  '132131',
  '113123',
  '113321',
  '133121',
  '313121',
  '211331',
  '231131',
  '213113',
  '213311',
  '213131',
  '311123',
  '311321',
  '331121',
  '312113',
  '312311',
  '332111',
  '314111',
  '221411',
  '431111',
  '111224',
  '111422',
  '121124',
  '121421',
  '141122',
  '141221',
  '112214',
  '112412',
  '122114',
  '122411',
  '142112',
  '142211',
  '241211',
  '221114',
  '413111',
  '241112',
  '134111',
  '111242',
  '121142',
  '121241',
  '114212',
  '124112',
  '124211',
  '411212',
  '421112',
  '421211',
  '212141',
  '214121',
  '412121',
  '111143',
  '111341',
  '131141',
  '114113',
  '114311',
  '411113',
  '411311',
  '113141',
  '114131',
  '311141',
  '411131',
];

const String _startC = '211232'; // value 105
const String _stop = '2331112'; // value 106, 7 runs, 13 modules

/// The bar and space widths, in modules, for [digits] (even length, digits
/// only), starting with a bar and alternating. Includes Start C, the checksum
/// symbol and the stop pattern. Quiet zones are the drawer's job.
List<int> code128CRuns(String digits) {
  if (digits.isEmpty ||
      digits.length.isOdd ||
      !RegExp(r'^[0-9]+$').hasMatch(digits)) {
    throw ArgumentError.value(
      digits,
      'digits',
      'must be an even number of digits',
    );
  }
  final buffer = StringBuffer(_startC);
  var checksum = 105;
  for (var i = 0; i < digits.length; i += 2) {
    final value = int.parse(digits.substring(i, i + 2));
    buffer.write(_patterns[value]);
    checksum += value * (i ~/ 2 + 1);
  }
  buffer.write(_patterns[checksum % 103]);
  buffer.write(_stop);
  return [for (final unit in buffer.toString().codeUnits) unit - 0x30];
}
