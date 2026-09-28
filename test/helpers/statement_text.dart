/// Builds statement text in the layout the PDF extractor produces for a
/// Trade Republic Kontoauszug: one table cell per line.
library;

import 'dart:typed_data';

import 'package:the25thrpg/features/budget/data/datasources/statement_pdf_datasource.dart';

/// Hands the import use case prepared text instead of reading a PDF.
class TextPdf implements StatementPdfDatasource {
  final String text;
  const TextPdf(this.text);

  @override
  String extractText(Uint8List bytes) => text;
}

const kHolder = 'DLDAR TAHER GULANI';

/// One UMSATZÜBERSICHT row: date, year, type, description lines, amount,
/// balance — each on its own line.
List<String> statementRow(
  String date,
  String type,
  List<String> description,
  String amount,
  String balance, {
  String year = '2026',
}) => ['$date ', year, type, ...description, amount, balance];

const statementPageBreak = [
  '',
  'TRADE REPUBLIC BANK GMBH',
  ' ',
  'BRUNNENSTRASSE 19-21',
  '10119 BERLIN',
  'Erstellt am 2026-09-28 01:24:54 Europe/Berlin (UTC+02:00)',
  'Seite',
  '2',
  'von',
  '2',
  'DATUM',
  'TYP',
  'BESCHREIBUNG',
  'ZAHLUNGSEINGANG',
  'ZAHLUNGSAUSGANG',
  'SALDO',
];

String statementText({
  required String opening,
  required String incoming,
  required String outgoing,
  required String closing,
  required List<List<String>> rows,
}) => [
  'TRADE REPUBLIC BANK GMBH',
  'BRUNNENSTRASSE 19-21',
  '10119 BERLIN',
  'DATUM',
  '01 Sept. 2026 - 26 Sept. 2026',
  'IBAN',
  'DE00100123450000000000',
  'BIC',
  'TRBKDEBBXXX',
  kHolder,
  'Musterstrasse 1',
  'Seite',
  '1',
  'von',
  '2',
  'KONTOÜBERSICHT',
  'PRODUKT',
  'ANFANGSSALDO',
  'ZAHLUNGSEINGANG',
  'ZAHLUNGSAUSGANG',
  'ENDSALDO',
  'Cashkonto',
  opening,
  incoming,
  outgoing,
  closing,
  'UMSATZÜBERSICHT',
  'DATUM',
  'TYP',
  'BESCHREIBUNG',
  'ZAHLUNGSEINGANG',
  'ZAHLUNGSAUSGANG',
  'SALDO',
  for (final r in rows) ...r,
  'BARMITTELÜBERSICHT',
  'Zum 26 Sept. 2026',
].join('\n');
