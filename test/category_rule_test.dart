import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/budget/application/use_cases/add_category_rule_use_case.dart';
import 'package:the25thrpg/features/budget/application/use_cases/import_statement_use_case.dart';
import 'package:the25thrpg/features/budget/domain/entities/category_rule.dart';

import 'helpers/fake_budget_repository.dart';
import 'helpers/statement_text.dart';

CategoryRule _rule(String keyword, String categoryId, int priority) =>
    CategoryRule(
      id: keyword,
      keyword: keyword,
      categoryId: categoryId,
      priority: priority,
    );

void main() {
  group('categorize', () {
    final rules = [
      _rule('amazon', 'shopping', 310),
      _rule('lidl', 'supermarket', 10),
      _rule('amazon prim', 'subscriptions', 280),
      _rule('paypal *spaeter zahlen', 'pay later', 370),
    ];

    test('matches case-insensitive substrings of the merchant text', () {
      expect(categorize('Lidl sagt Danke', rules), 'supermarket');
      expect(categorize('PAYPAL *SPAETER ZAHLEN', rules), 'pay later');
    });

    test('first rule by priority wins, not list order', () {
      expect(categorize('AMAZON PRIM* NV0S703M4', rules), 'subscriptions');
      expect(categorize('WWW.AMAZON.* NF3ZP6OL4', rules), 'shopping');
    });

    test('no match is null', () {
      expect(categorize('difmark', rules), isNull);
      expect(categorize('PAYPAL *filip.no1055', rules), isNull);
    });
  });

  group('rules in the import', () {
    late FakeBudgetRepository repo;

    setUp(() async {
      repo = FakeBudgetRepository();
      await repo.addCategory(
        name: 'Einkaufen',
        iconKey: 'shopping',
        colorIndex: 8,
      );
      await repo.addCategory(name: 'Coffee', iconKey: 'coffee', colorIndex: 6);
      await repo.addCategory(
        name: kUncategorizedCategoryName,
        iconKey: 'other',
        colorIndex: 9,
      );
      await repo.addCategoryRule(
        keyword: 'lidl',
        categoryId: repo.category('Einkaufen').id,
        priority: 10,
      );
    });

    final text = statementText(
      opening: '10,00 €',
      incoming: '0,00 €',
      outgoing: '3,00 €',
      closing: '7,00 €',
      rows: [
        statementRow(
          '01 Sept.',
          'Kartentransaktion',
          ['Lidl sagt Danke'],
          '1,00 €',
          '9,00 €',
        ),
        statementRow(
          '02 Sept.',
          'Kartentransaktion',
          ['difmark'],
          '2,00 €',
          '7,00 €',
        ),
      ],
    );

    test(
      'matched rows get the rule category, the rest Uncategorized',
      () async {
        final result = await ImportStatementUseCase(
          repo,
          TextPdf(text),
        ).execute(Uint8List(0));

        expect(result.uncategorized, 1);
        String categoryOf(String merchant) => repo.live
            .singleWhere((t) => t.bankDescription == merchant)
            .categoryId;
        expect(categoryOf('Lidl sagt Danke'), repo.category('Einkaufen').id);
        expect(
          categoryOf('difmark'),
          repo.category(kUncategorizedCategoryName).id,
        );
        expect(repo.live.every((t) => t.needsReview), isTrue);
      },
    );

    test('"Always categorize" rule runs before every existing rule', () async {
      await AddCategoryRuleUseCase(repo).execute(
        keyword: 'Lidl sagt Danke',
        categoryId: repo.category('Coffee').id,
      );

      expect(
        categorize('Lidl sagt Danke', repo.rules),
        repo.category('Coffee').id,
      );
      expect(
        categorize('Lidl Express', repo.rules),
        repo.category('Einkaufen').id,
      );
    });
  });
}
