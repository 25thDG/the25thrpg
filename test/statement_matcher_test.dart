import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/budget/application/use_cases/import_statement_use_case.dart';
import 'package:the25thrpg/features/budget/domain/entities/bank_statement.dart';
import 'package:the25thrpg/features/budget/domain/entities/budget_transaction.dart';
import 'package:the25thrpg/features/budget/domain/entities/statement_matcher.dart';

import 'helpers/fake_budget_repository.dart';
import 'helpers/statement_text.dart';

BudgetTransaction _manual(String id, int cents, DateTime day) =>
    BudgetTransaction(
      id: id,
      userId: 'u',
      categoryId: 'c',
      amountCents: cents,
      spentAt: day,
      createdAt: day,
      updatedAt: day,
    );

BankTransaction _payment(int cents, DateTime day, {String merchant = 'M'}) =>
    BankTransaction(
      bookedOn: day,
      type: 'Kartentransaktion',
      description: merchant,
      amountCents: -cents,
      balanceCents: 0,
      kind: BankTransactionType.cardPayment,
    );

final _day = DateTime(2026, 9, 10);
DateTime _plus(int days) => DateTime(_day.year, _day.month, _day.day + days);

void main() {
  group('date window', () {
    bool matches(int bankDaysAfterManual) => matchPayments(
      [_manual('m', 500, _day)],
      [_payment(500, _plus(bankDaysAfterManual))],
    ).isNotEmpty;

    test('bank booked 1 day before the manual date matches', () {
      expect(matches(-1), isTrue);
    });

    test('bank booked 2 days before does not match', () {
      expect(matches(-2), isFalse);
    });

    test('bank booked 3 days after matches', () {
      expect(matches(3), isTrue);
    });

    test('bank booked 4 days after does not match', () {
      expect(matches(4), isFalse);
    });

    test('a manual entry logged late in the evening still uses its date', () {
      final lateEvening = DateTime(2026, 9, 10, 23, 30);
      expect(
        matchPayments(
          [_manual('m', 500, lateEvening)],
          [_payment(500, _plus(3))],
        ),
        hasLength(1),
      );
    });
  });

  group('amount tolerance', () {
    bool matches(int manualCents, int bankCents) => matchPayments(
      [_manual('m', manualCents, _day)],
      [_payment(bankCents, _day)],
    ).isNotEmpty;

    test('€0.10 apart matches, either way', () {
      expect(matches(500, 510), isTrue);
      expect(matches(510, 500), isTrue);
    });

    test('€0.11 apart does not match', () {
      expect(matches(500, 511), isFalse);
      expect(matches(511, 500), isFalse);
    });
  });

  group('pairing', () {
    test('an exact amount wins over a close one', () {
      final exact = _manual('exact', 500, _day);
      final close = _manual('close', 505, _day);
      final result = matchPayments([close, exact], [_payment(500, _day)]);
      expect(result.single.manual, exact);
    });

    test('otherwise the closest amount wins', () {
      final far = _manual('far', 500, _day);
      final near = _manual('near', 508, _day);
      final result = matchPayments([far, near], [_payment(506, _day)]);
      expect(result.single.manual, near);
    });

    test('an exact match elsewhere is not stolen by a closer date', () {
      final a = _manual('a', 500, _day);
      final result = matchPayments(
        [a],
        [_payment(505, _day), _payment(500, _plus(2))],
      );
      expect(result.single.bank.amountCents, -500);
    });

    test('each bank payment matches at most one manual entry', () {
      final result = matchPayments(
        [_manual('a', 500, _day), _manual('b', 500, _day)],
        [_payment(500, _day)],
      );
      expect(result, hasLength(1));
    });

    test('two equal payments pair with two equal entries', () {
      final result = matchPayments(
        [_manual('a', 500, _day), _manual('b', 500, _day)],
        [_payment(500, _day), _payment(500, _plus(1))],
      );
      expect(result.map((m) => m.manual.id).toSet(), {'a', 'b'});
    });
  });

  group('matching in the import', () {
    late FakeBudgetRepository repo;

    setUp(() async {
      repo = FakeBudgetRepository();
      await repo.addCategory(name: 'Coffee', iconKey: 'coffee', colorIndex: 6);
      await repo.addCategory(
        name: kUncategorizedCategoryName,
        iconKey: 'other',
        colorIndex: 9,
      );
    });

    final text = statementText(
      opening: '10,00 €',
      incoming: '0,00 €',
      outgoing: '5,85 €',
      closing: '4,15 €',
      rows: [
        statementRow(
          '06 Sept.',
          'Kartentransaktion',
          ['Konditorei Junge GmbH 304'],
          '2,35 €',
          '7,65 €',
        ),
        statementRow(
          '07 Sept.',
          'Kartentransaktion',
          ['LE CROBAG SHOP'],
          '3,50 €',
          '4,15 €',
        ),
      ],
    );

    test(
      'links the payment, bank amount wins, note and category stay',
      () async {
        final logged = repo.addManual(
          categoryName: 'Coffee',
          amountCents: 240,
          spentAt: DateTime(2026, 9, 5, 9, 15),
          note: 'croissant',
        );
        final cash = repo.addManual(
          categoryName: 'Coffee',
          amountCents: 120,
          spentAt: DateTime(2026, 9, 6),
        );

        final useCase = ImportStatementUseCase(repo, TextPdf(text));
        final result = await useCase.execute(Uint8List(0));

        expect(result.matched, 1);
        expect(result.added, 1);

        final linked = repo.live.singleWhere((t) => t.id == logged.id);
        expect(linked.amountCents, 235);
        expect(linked.note, 'croissant');
        expect(linked.categoryId, repo.category('Coffee').id);
        expect(linked.spentAt, logged.spentAt);
        expect(linked.bankDescription, 'Konditorei Junge GmbH 304');
        expect(linked.needsReview, isFalse);

        final unmatchedCash = repo.live.singleWhere((t) => t.id == cash.id);
        expect(unmatchedCash.bankKey, isNull);

        final added = repo.live.singleWhere(
          (t) => t.bankDescription == 'LE CROBAG SHOP',
        );
        expect(added.needsReview, isTrue);

        final again = await useCase.execute(Uint8List(0));
        expect(again.matched, 0);
        expect(again.added, 0);
        expect(repo.live, hasLength(3));
      },
    );
  });
}
