import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/budget/domain/entities/budget_category.dart';
import 'package:the25thrpg/features/budget/domain/entities/budget_transaction.dart';
import 'package:the25thrpg/features/budget/presentation/widgets/statement_review_sheet.dart';

BudgetCategory _cat(String id, String name) => BudgetCategory(
  id: id,
  userId: 'u',
  name: name,
  iconKey: 'other',
  colorIndex: 0,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  testWidgets('changing the category offers a rule, confirm saves the row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final reviewed = <(String, String, String?)>[];
    final rules = <(String, String)>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatementReviewSheet(
            transactions: [
              BudgetTransaction(
                id: 't1',
                userId: 'u',
                categoryId: 'eink',
                amountCents: 292,
                spentAt: DateTime(2026, 9, 26),
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
                needsReview: true,
                bankKey: 'k',
                bankDescription: 'Lidl sagt Danke',
              ),
            ],
            categories: [_cat('coffee', 'Coffee'), _cat('eink', 'Einkaufen')],
            onReview: ({required id, required categoryId, note}) async {
              reviewed.add((id, categoryId, note));
              return null;
            },
            onAddRule: ({required keyword, required categoryId}) async {
              rules.add((keyword, categoryId));
              return null;
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('Always categorize'), findsNothing);

    await tester.tap(find.text('Coffee'));
    await tester.pump();
    await tester.tap(find.text('Always categorize Lidl sagt Danke as Coffee'));
    await tester.pump();
    expect(rules, [('Lidl sagt Danke', 'coffee')]);
    expect(find.text('Rule saved: Lidl sagt Danke → Coffee'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'snacks');
    await tester.tap(find.byTooltip('Confirm'));
    await tester.pump();
    expect(reviewed, [('t1', 'coffee', 'snacks')]);
  });
}
