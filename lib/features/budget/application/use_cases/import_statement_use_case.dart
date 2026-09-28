import 'dart:typed_data';

import '../../data/datasources/statement_pdf_datasource.dart';
import '../../domain/entities/bank_statement.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_transaction.dart';
import '../../domain/entities/category_rule.dart';
import '../../domain/entities/statement_matcher.dart';
import '../../domain/repositories/budget_repository.dart';

/// Where imported rows go when no rule matches.
const kUncategorizedCategoryName = 'Uncategorized';

class ImportResult {
  /// Rows read from the statement.
  final int parsed;

  /// Transfers from the account holder — never stored.
  final int topUps;

  /// Rows that are neither card transactions nor top ups — never stored.
  final int skipped;

  /// Rows already imported earlier.
  final int duplicates;

  /// Card payments linked to an entry you had logged by hand.
  final int matched;

  /// New rows added, all marked needs review.
  final int added;

  /// Of [added], how many no rule could categorize.
  final int uncategorized;

  const ImportResult({
    required this.parsed,
    required this.topUps,
    required this.skipped,
    required this.duplicates,
    required this.matched,
    required this.added,
    required this.uncategorized,
  });
}

class ImportStatementUseCase {
  final BudgetRepository _repository;
  final StatementPdfDatasource _pdf;

  const ImportStatementUseCase(this._repository, this._pdf);

  /// Throws `ValidationException` (and imports nothing) if the statement
  /// can't be read or doesn't add up.
  Future<ImportResult> execute(Uint8List pdfBytes) async {
    final statement = parseBankStatement(_pdf.extractText(pdfBytes));
    final rows = statement.transactions;

    int count(BankTransactionType k) => rows.where((t) => t.kind == k).length;
    final card = rows
        .where((t) =>
            t.kind == BankTransactionType.cardPayment ||
            t.kind == BankTransactionType.refund)
        .toList();

    var fresh = <BankTransaction>[];
    if (card.isNotEmpty) {
      final dates = card.map((t) => t.bookedOn).toList()..sort();
      final existing = await _repository.getBankKeys(
          from: dates.first, to: dates.last);
      fresh = card.where((t) => !existing.contains(t.dedupeKey)).toList();
    }

    final matches = await _linkManualEntries(fresh);
    final matchedKeys = {for (final m in matches) m.bank.dedupeKey};
    final added =
        fresh.where((t) => !matchedKeys.contains(t.dedupeKey)).toList();

    var uncategorized = 0;
    if (added.isNotEmpty) {
      final (categories, allRules) = await (
        _repository.getCategories(),
        _repository.getCategoryRules(),
      ).wait;
      // A rule pointing at a deleted category would file rows out of sight.
      final liveIds = {for (final c in categories) c.id};
      final rules = allRules.where((r) => liveIds.contains(r.categoryId)).toList();

      final ruleCategoryIds =
          added.map((t) => categorize(t.description, rules)).toList();
      uncategorized = ruleCategoryIds.where((id) => id == null).length;
      final fallbackId = uncategorized > 0
          ? await _uncategorizedCategoryId(categories)
          : null;

      await _repository.addImportedTransactions([
        for (var i = 0; i < added.length; i++)
          NewImportedTransaction(
            categoryId: ruleCategoryIds[i] ?? fallbackId!,
            amountCents: added[i].amountCents.abs(),
            kind: added[i].kind == BankTransactionType.refund
                ? BudgetTransactionKind.refund
                : BudgetTransactionKind.expense,
            spentAt: added[i].bookedOn,
            bankKey: added[i].dedupeKey,
            bankDescription: added[i].description,
          ),
      ]);
    }

    return ImportResult(
      parsed: rows.length,
      topUps: count(BankTransactionType.topUp),
      skipped: count(BankTransactionType.other),
      duplicates: card.length - fresh.length,
      matched: matches.length,
      added: added.length,
      uncategorized: uncategorized,
    );
  }

  /// Links card payments to the manual entries they match; see
  /// [matchPayments].
  Future<List<PaymentMatch>> _linkManualEntries(
      List<BankTransaction> fresh) async {
    final payments = fresh
        .where((t) => t.kind == BankTransactionType.cardPayment)
        .toList();
    if (payments.isEmpty) return const [];

    final dates = payments.map((t) => t.bookedOn).toList()..sort();
    final first = dates.first;
    final last = dates.last;
    final manual = await _repository.getUnlinkedManualTransactions(
      start: DateTime(first.year, first.month, first.day - kMatchDaysAfter),
      end: DateTime(last.year, last.month, last.day + kMatchDaysBefore + 1),
    );

    final matches = matchPayments(manual, payments);
    await Future.wait([
      for (final m in matches)
        _repository.linkTransaction(
          id: m.manual.id,
          amountCents: m.bank.amountCents.abs(),
          bankKey: m.bank.dedupeKey,
          bankDescription: m.bank.description,
        ),
    ]);
    return matches;
  }

  Future<String> _uncategorizedCategoryId(
      List<BudgetCategory> categories) async {
    for (final c in categories) {
      if (c.name == kUncategorizedCategoryName) return c.id;
    }
    final created = await _repository.addCategory(
        name: kUncategorizedCategoryName, iconKey: 'other', colorIndex: 9);
    return created.id;
  }
}
