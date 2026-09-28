import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../../core/error/app_exception.dart';

class StatementPdfDatasource {
  const StatementPdfDatasource();

  /// Text of the PDF with one table cell per line, the layout
  /// `parseBankStatement` reads.
  String extractText(Uint8List bytes) {
    final PdfDocument doc;
    try {
      doc = PdfDocument(inputBytes: bytes);
    } catch (e) {
      throw ValidationException('Could not open the PDF: $e');
    }
    try {
      return PdfTextExtractor(doc).extractText();
    } finally {
      doc.dispose();
    }
  }
}
