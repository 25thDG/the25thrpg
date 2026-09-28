import 'bank_statement.dart';
import 'budget_transaction.dart';

/// A manual entry and a card payment are the same payment if the amounts
/// differ by at most this much…
const kMatchToleranceCents = 10;

/// …and the bank booked it between 1 day before and 3 days after the day
/// the entry was logged.
const kMatchDaysBefore = 1;
const kMatchDaysAfter = 3;

typedef PaymentMatch = ({BankTransaction bank, BudgetTransaction manual});

/// Pairs card payments with manual entries. Exact amounts are paired first,
/// then the closest amounts; on equal amounts the closer date wins. Each
/// payment and each entry is used at most once.
///
/// Entries left unpaired were paid in cash.
List<PaymentMatch> matchPayments(
  List<BudgetTransaction> manual,
  List<BankTransaction> payments,
) {
  final candidates = <(int bank, int manual, int centsOff, int daysOff)>[];
  for (var b = 0; b < payments.length; b++) {
    for (var m = 0; m < manual.length; m++) {
      final centsOff =
          (payments[b].amountCents.abs() - manual[m].amountCents).abs();
      if (centsOff > kMatchToleranceCents) continue;
      final days = _daysBetween(manual[m].spentAt, payments[b].bookedOn);
      if (days < -kMatchDaysBefore || days > kMatchDaysAfter) continue;
      candidates.add((b, m, centsOff, days.abs()));
    }
  }
  candidates.sort((x, y) {
    final byCents = x.$3.compareTo(y.$3);
    if (byCents != 0) return byCents;
    final byDays = x.$4.compareTo(y.$4);
    if (byDays != 0) return byDays;
    final byBank = x.$1.compareTo(y.$1);
    return byBank != 0 ? byBank : x.$2.compareTo(y.$2);
  });

  final usedBank = <int>{};
  final usedManual = <int>{};
  final matches = <PaymentMatch>[];
  for (final (b, m, _, _) in candidates) {
    if (usedBank.contains(b) || usedManual.contains(m)) continue;
    usedBank.add(b);
    usedManual.add(m);
    matches.add((bank: payments[b], manual: manual[m]));
  }
  return matches;
}

/// Calendar days from [from] to [to]; positive when [to] is later.
int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;
