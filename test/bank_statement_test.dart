import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/core/error/app_exception.dart';
import 'package:the25thrpg/features/budget/data/datasources/statement_pdf_datasource.dart';
import 'package:the25thrpg/features/budget/domain/entities/bank_statement.dart';

import 'helpers/statement_text.dart';

void main() {
  group('German amounts', () {
    test('parses cents, thousands separators and signs', () {
      expect(parseGermanAmount('0,64 €'), 64);
      expect(parseGermanAmount('1,93 €'), 193);
      expect(parseGermanAmount('1.234,56 €'), 123456);
      expect(parseGermanAmount('12.345.678,90 €'), 1234567890);
      expect(parseGermanAmount('-5,00 €'), -500);
    });

    test('rejects anything that is not a German euro amount', () {
      for (final bad in ['1,5 €', '1.93 €', '1,93', '1234,56 €', 'abc']) {
        expect(() => parseGermanAmount(bad), throwsA(isA<ValidationException>()),
            reason: bad);
      }
    });

    test('formats back to the statement notation', () {
      expect(formatGermanAmount(123456), '1.234,56 €');
      expect(formatGermanAmount(64), '0,64 €');
      expect(formatGermanAmount(-4499), '-44,99 €');
    });
  });

  group('dates', () {
    test('reads day and month from one line and the year from the next', () {
      final s = parseBankStatement(statementText(
        opening: '10,00 €',
        incoming: '0,00 €',
        outgoing: '1,93 €',
        closing: '8,07 €',
        rows: [
          statementRow('01 Sept.', 'Kartentransaktion', ['Lidl sagt Danke'], '1,93 €',
              '8,07 €'),
        ],
      ));
      expect(s.transactions.single.bookedOn, DateTime(2026, 9, 1));
    });

    test('knows every German month abbreviation', () {
      const months = [
        'Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', //
        'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.',
      ];
      final s = parseBankStatement(statementText(
        opening: '20,00 €',
        incoming: '0,00 €',
        outgoing: '12,00 €',
        closing: '8,00 €',
        rows: [
          for (var m = 0; m < 12; m++)
            statementRow('0${m % 9 + 1} ${months[m]}', 'Kartentransaktion', ['X'],
                '1,00 €', '${19 - m},00 €'),
        ],
      ));
      expect(s.transactions.map((t) => t.bookedOn.month),
          List.generate(12, (m) => m + 1));
    });

    test('throws a clear error on an unknown month', () {
      final text = statementText(
        opening: '10,00 €',
        incoming: '0,00 €',
        outgoing: '1,00 €',
        closing: '9,00 €',
        rows: [
          statementRow('01 Sep.', 'Kartentransaktion', ['X'], '1,00 €', '9,00 €'),
        ],
      );
      expect(
        () => parseBankStatement(text),
        throwsA(isA<ValidationException>().having(
            (e) => e.message, 'message', contains('Unknown month abbreviation "Sep."'))),
      );
    });
  });

  group('direction and type', () {
    final s = parseBankStatement(statementText(
      opening: '50,00 €',
      incoming: '164,99 €',
      outgoing: '46,92 €',
      closing: '168,07 €',
      rows: [
        statementRow('01 Sept.', 'Kartentransaktion', ['Lidl sagt Danke'], '1,93 €',
            '48,07 €'),
        statementRow('02 Sept.', 'Kartentransaktion', ['Jack Jones-Vero Moda'],
            '44,99 €', '3,08 €'),
        statementRow('03 Sept.', 'Kartentransaktion', ['Jack Jones-Vero Moda'],
            '44,99 €', '48,07 €'),
        statementRow(
            '04 Sept.',
            'Überweisung',
            ['Incoming transfer from N/A $kHolder', '(DE76100110012224428539)'],
            '100,00 €',
            '148,07 €'),
        statementRow('05 Sept.', 'Überweisung',
            ['Incoming transfer from Filip Nowak', '(DE11)'], '20,00 €', '168,07 €'),
      ],
    ));
    final t = s.transactions;

    test('card payment is negative', () {
      expect(t[0].amountCents, -193);
      expect(t[0].kind, BankTransactionType.cardPayment);
    });

    test('refund is a card transaction whose balance goes up', () {
      expect(t[2].amountCents, 4499);
      expect(t[2].kind, BankTransactionType.refund);
    });

    test('top up is an incoming transfer from the account holder', () {
      expect(t[3].amountCents, 10000);
      expect(t[3].kind, BankTransactionType.topUp);
      expect(t[3].description,
          'Incoming transfer from N/A $kHolder (DE76100110012224428539)');
    });

    test('incoming transfer from someone else is not a top up', () {
      expect(t[4].kind, BankTransactionType.other);
    });

    test('dedupe key is date, amount, description and balance', () {
      expect(t[0].dedupeKey, '2026-09-01|-193|Lidl sagt Danke|4807');
    });
  });

  group('page chrome and validation', () {
    test('ignores the letterhead and column header repeated on a new page', () {
      final s = parseBankStatement(statementText(
        opening: '10,00 €',
        incoming: '0,00 €',
        outgoing: '3,00 €',
        closing: '7,00 €',
        rows: [
          statementRow('01 Sept.', 'Kartentransaktion', ['A'], '1,00 €', '9,00 €'),
          statementPageBreak,
          statementRow('02 Sept.', 'Kartentransaktion', ['B'], '2,00 €', '7,00 €'),
        ],
      ));
      expect(s.transactions.map((t) => t.description), ['A', 'B']);
    });

    test('rejects a statement whose totals do not match the header', () {
      final text = statementText(
        opening: '10,00 €',
        incoming: '5,00 €',
        outgoing: '1,00 €',
        closing: '9,00 €',
        rows: [
          statementRow('01 Sept.', 'Kartentransaktion', ['A'], '1,00 €', '9,00 €'),
        ],
      );
      expect(
        () => parseBankStatement(text),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message',
            contains('incoming 0,00 €, statement says 5,00 €'))),
      );
    });

    test('rejects a row whose amount does not match the balance change', () {
      final text = statementText(
        opening: '10,00 €',
        incoming: '0,00 €',
        outgoing: '2,00 €',
        closing: '8,00 €',
        rows: [
          statementRow('01 Sept.', 'Kartentransaktion', ['A'], '1,00 €', '8,00 €'),
        ],
      );
      expect(() => parseBankStatement(text), throwsA(isA<ValidationException>()));
    });
  });

  group('fixture', () {
    final file = File('test/fixtures/tr_statement_2026_09.pdf');

    test('parses the September 2026 statement', () {
      final text =
          const StatementPdfDatasource().extractText(file.readAsBytesSync());
      final s = parseBankStatement(text);

      expect(s.transactions, hasLength(102));
      expect(s.openingBalanceCents, 24126);
      expect(s.incomingCents, 66999);
      expect(s.outgoingCents, 84938);
      expect(s.closingBalanceCents, 6187);
      expect(s.accountHolder, kHolder);

      int count(BankTransactionType k) =>
          s.transactions.where((t) => t.kind == k).length;
      expect(count(BankTransactionType.cardPayment), 94);
      expect(count(BankTransactionType.refund), 1);
      expect(count(BankTransactionType.topUp), 7);
      expect(count(BankTransactionType.other), 0);
    }, skip: file.existsSync() ? false : 'fixture PDF not present (gitignored)');
  });
}
