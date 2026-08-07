import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_transaction.dart';
import '../../domain/repositories/budget_repository.dart';

class ExportBundle {
  final Uint8List bytes;
  final String suggestedFileName;
  final int transactionCount;
  final double totalEur;

  const ExportBundle({
    required this.bytes,
    required this.suggestedFileName,
    required this.transactionCount,
    required this.totalEur,
  });
}

class ExportTransactionsUseCase {
  final BudgetRepository _repository;

  const ExportTransactionsUseCase(this._repository);

  Future<ExportBundle> execute({
    required DateTime start,
    required DateTime end,
  }) async {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEndExclusive = DateTime(end.year, end.month, end.day).add(
      const Duration(days: 1),
    );

    final (categories, transactions) = await (
      _repository.getCategories(),
      _repository.getTransactionsInRange(
          start: rangeStart, end: rangeEndExclusive),
    ).wait;

    final categoryMap = {for (final c in categories) c.id: c};

    final bytes = _buildWorkbook(
      transactions: transactions,
      categoryMap: categoryMap,
      start: rangeStart,
      end: end,
    );

    final totalCents =
        transactions.fold<int>(0, (sum, t) => sum + t.amountCents);

    return ExportBundle(
      bytes: Uint8List.fromList(bytes),
      suggestedFileName: _fileName(rangeStart, end),
      transactionCount: transactions.length,
      totalEur: totalCents / 100.0,
    );
  }

  String _fileName(DateTime start, DateTime end) {
    String pad(int n) => n.toString().padLeft(2, '0');
    final s = '${start.year}${pad(start.month)}${pad(start.day)}';
    final e = '${end.year}${pad(end.month)}${pad(end.day)}';
    return 'expenses_${s}_to_$e.xlsx';
  }

  List<int> _buildWorkbook({
    required List<BudgetTransaction> transactions,
    required Map<String, BudgetCategory> categoryMap,
    required DateTime start,
    required DateTime end,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Expenses';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    final headerBg = ExcelColor.fromHexString('#0F1116');
    final accent = ExcelColor.fromHexString('#4FC3F7');
    final stripeBg = ExcelColor.fromHexString('#F5F7FA');
    final totalBg = ExcelColor.fromHexString('#FFF3E0');
    final borderColor = ExcelColor.fromHexString('#CFD8DC');

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: headerBg,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final subTitleStyle = CellStyle(
      italic: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#546E7A'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: accent,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
      rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
      topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
      bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
    );

    CellStyle dataStyle({required bool stripe, HorizontalAlign? align}) =>
        CellStyle(
          fontSize: 11,
          backgroundColorHex: stripe ? stripeBg : ExcelColor.white,
          horizontalAlign: align ?? HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
          leftBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          rightBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          topBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          bottomBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
        );

    CellStyle currencyStyle({required bool stripe}) => CellStyle(
          fontSize: 11,
          backgroundColorHex: stripe ? stripeBg : ExcelColor.white,
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
          numberFormat: const CustomNumericNumFormat(formatCode: '€#,##0.00'),
          leftBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          rightBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          topBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          bottomBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
        );

    CellStyle dateStyle({required bool stripe}) => CellStyle(
          fontSize: 11,
          backgroundColorHex: stripe ? stripeBg : ExcelColor.white,
          horizontalAlign: HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
          numberFormat: const CustomDateTimeNumFormat(formatCode: 'yyyy-mm-dd'),
          leftBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          rightBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          topBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
          bottomBorder:
              Border(borderStyle: BorderStyle.Thin, borderColorHex: borderColor),
        );

    final totalLabelStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: totalBg,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      topBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: headerBg),
      bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: headerBg),
    );

    final totalValueStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: totalBg,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat: const CustomNumericNumFormat(formatCode: '€#,##0.00'),
      topBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: headerBg),
      bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: headerBg),
    );

    String pad(int n) => n.toString().padLeft(2, '0');
    String fmtRange(DateTime d) =>
        '${d.year}-${pad(d.month)}-${pad(d.day)}';

    // ── Row 0: title ──────────────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );
    final titleCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue('EXPENSE REPORT');
    titleCell.cellStyle = titleStyle;
    sheet.setRowHeight(0, 28);

    // ── Row 1: range ──────────────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1),
    );
    final rangeCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    rangeCell.value =
        TextCellValue('${fmtRange(start)}  →  ${fmtRange(end)}');
    rangeCell.cellStyle = subTitleStyle;

    // ── Row 2: spacer ─────────────────────────────────────────────────────
    sheet.setRowHeight(2, 8);

    // ── Row 3: column headers ─────────────────────────────────────────────
    const headerRow = 3;
    const headers = ['Date', 'Category', 'Amount (EUR)', 'Note'];
    for (var i = 0; i < headers.length; i++) {
      final c = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = headerStyle;
    }
    sheet.setRowHeight(headerRow, 22);

    // ── Data rows ─────────────────────────────────────────────────────────
    final firstDataRow = headerRow + 1;
    final sorted = [...transactions]
      ..sort((a, b) => a.spentAt.compareTo(b.spentAt));

    for (var i = 0; i < sorted.length; i++) {
      final t = sorted[i];
      final cat = categoryMap[t.categoryId];
      final stripe = i.isOdd;
      final row = firstDataRow + i;

      final dateCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      dateCell.value = DateTimeCellValue(
        year: t.spentAt.year,
        month: t.spentAt.month,
        day: t.spentAt.day,
        hour: 0,
        minute: 0,
      );
      dateCell.cellStyle = dateStyle(stripe: stripe);

      final catCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      catCell.value = TextCellValue(cat?.name ?? '(deleted category)');
      catCell.cellStyle = dataStyle(stripe: stripe);

      final amtCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      amtCell.value = DoubleCellValue(t.amountCents / 100.0);
      amtCell.cellStyle = currencyStyle(stripe: stripe);

      final noteCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
      noteCell.value = TextCellValue(t.note ?? '');
      noteCell.cellStyle = dataStyle(stripe: stripe);
    }

    // ── Total row ─────────────────────────────────────────────────────────
    final totalRow = firstDataRow + sorted.length + 1;
    sheet.setRowHeight(totalRow - 1, 8);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRow),
    );
    final totalLabel = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow));
    totalLabel.value = TextCellValue('TOTAL');
    totalLabel.cellStyle = totalLabelStyle;

    final totalValue = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRow));
    if (sorted.isNotEmpty) {
      final firstRef = 'C${firstDataRow + 1}';
      final lastRef = 'C${firstDataRow + sorted.length}';
      totalValue.value = FormulaCellValue('SUM($firstRef:$lastRef)');
    } else {
      totalValue.value = DoubleCellValue(0);
    }
    totalValue.cellStyle = totalValueStyle;

    final totalFiller = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRow));
    totalFiller.value = TextCellValue('');
    totalFiller.cellStyle = totalLabelStyle;

    // ── Column widths ─────────────────────────────────────────────────────
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 44);

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Failed to encode Excel workbook.');
    }
    return bytes;
  }
}
