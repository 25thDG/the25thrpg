import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/core/error/app_exception.dart';
import 'package:the25thrpg/features/budget/application/use_cases/import_statement_use_case.dart';
import 'package:the25thrpg/features/budget/data/datasources/statement_pdf_datasource.dart';

import 'helpers/fake_budget_repository.dart';
import 'helpers/statement_text.dart';

final _noBytes = Uint8List(0);

final _september = statementText(
  opening: '50,00 €',
  incoming: '144,99 €',
  outgoing: '48,42 €',
  closing: '146,57 €',
  rows: [
    statementRow(
      '01 Sept.',
      'Kartentransaktion',
      ['Lidl sagt Danke'],
      '1,93 €',
      '48,07 €',
    ),
    statementRow(
      '01 Sept.',
      'Kartentransaktion',
      ['Lidl sagt Danke'],
      '1,50 €',
      '46,57 €',
    ),
    statementRow(
      '02 Sept.',
      'Kartentransaktion',
      ['Jack Jones-Vero Moda'],
      '44,99 €',
      '1,58 €',
    ),
    statementRow(
      '03 Sept.',
      'Kartentransaktion',
      ['Jack Jones-Vero Moda'],
      '44,99 €',
      '46,57 €',
    ),
    statementRow(
      '04 Sept.',
      'Überweisung',
      ['Incoming transfer from N/A $kHolder', '(DE76100110012224428539)'],
      '100,00 €',
      '146,57 €',
    ),
  ],
);

void main() {
  late FakeBudgetRepository repo;

  setUp(() {
    repo = FakeBudgetRepository();
  });

  group('idempotent import', () {
    test(
      'importing the same statement twice adds nothing the second time',
      () async {
        final useCase = ImportStatementUseCase(repo, TextPdf(_september));

        final first = await useCase.execute(_noBytes);
        expect(first.parsed, 5);
        expect(first.added, 4);
        expect(first.topUps, 1);
        expect(repo.live, hasLength(4));

        final second = await useCase.execute(_noBytes);
        expect(second.added, 0);
        expect(second.duplicates, 4);
        expect(repo.live, hasLength(4));
      },
    );

    test('top ups are never stored; refunds are stored as refunds', () async {
      await ImportStatementUseCase(repo, TextPdf(_september)).execute(_noBytes);

      expect(
        repo.live.where((t) => t.bankDescription!.contains('transfer')),
        isEmpty,
      );
      final refund = repo.live.singleWhere((t) => t.isRefund);
      expect(refund.amountCents, 4499);
      expect(refund.signedAmountCents, -4499);
    });

    test('a deleted import is not brought back by importing again', () async {
      final useCase = ImportStatementUseCase(repo, TextPdf(_september));
      await useCase.execute(_noBytes);
      await repo.deleteTransaction(repo.live.first.id);

      final again = await useCase.execute(_noBytes);
      expect(again.added, 0);
      expect(repo.live, hasLength(3));
    });

    test('a statement that does not add up imports nothing', () async {
      final broken = _september.replaceFirst('144,99 €', '145,00 €');
      await expectLater(
        ImportStatementUseCase(repo, TextPdf(broken)).execute(_noBytes),
        throwsA(isA<ValidationException>()),
      );
      expect(repo.transactions, isEmpty);
    });
  });

  group('fixture', () {
    final file = File('test/fixtures/tr_statement_2026_09.pdf');

    test(
      'importing the September PDF twice leaves the count unchanged',
      () async {
        final useCase = ImportStatementUseCase(
          repo,
          const StatementPdfDatasource(),
        );
        final bytes = file.readAsBytesSync();

        final first = await useCase.execute(bytes);
        expect(first.parsed, 102);
        expect(first.topUps, 7);
        expect(first.added, 95);
        final count = repo.live.length;

        final second = await useCase.execute(bytes);
        expect(second.added, 0);
        expect(repo.live.length, count);
      },
      skip: file.existsSync() ? false : 'fixture PDF not present (gitignored)',
    );
  });
}
