import '../../../../core/error/app_exception.dart';

/// What a statement row means for the budget.
enum BankTransactionType {
  /// Card transaction that took money out.
  cardPayment,

  /// Card transaction that put money back in.
  refund,

  /// Transfer from the account holder's own account. Not income, not
  /// spending — excluded from every stat.
  topUp,

  /// Anything else (transfers from other people, interest, trades…). Parsed
  /// so the balances can be checked, never imported.
  other,
}

class BankTransaction {
  final DateTime bookedOn;

  /// TYP column as printed, e.g. `Kartentransaktion`, `Überweisung`.
  final String type;
  final String description;

  /// Signed: negative is money out. Always derived from the SALDO change,
  /// never from which column the amount was printed in.
  final int amountCents;

  /// SALDO after this row.
  final int balanceCents;
  final BankTransactionType kind;

  const BankTransaction({
    required this.bookedOn,
    required this.type,
    required this.description,
    required this.amountCents,
    required this.balanceCents,
    required this.kind,
  });

  /// Identity of a statement row across imports: date + amount + description
  /// + balance. The balance keeps two identical same-day purchases apart.
  String get dedupeKey {
    String pad(int n) => n.toString().padLeft(2, '0');
    final d = '${bookedOn.year}-${pad(bookedOn.month)}-${pad(bookedOn.day)}';
    return '$d|$amountCents|$description|$balanceCents';
  }
}

class BankStatement {
  final String accountHolder;
  final int openingBalanceCents;
  final int incomingCents;
  final int outgoingCents;
  final int closingBalanceCents;
  final List<BankTransaction> transactions;

  const BankStatement({
    required this.accountHolder,
    required this.openingBalanceCents,
    required this.incomingCents,
    required this.outgoingCents,
    required this.closingBalanceCents,
    required this.transactions,
  });
}

const _months = {
  'Jan.': 1,
  'Feb.': 2,
  'März': 3,
  'Apr.': 4,
  'Mai': 5,
  'Juni': 6,
  'Juli': 7,
  'Aug.': 8,
  'Sept.': 9,
  'Okt.': 10,
  'Nov.': 11,
  'Dez.': 12,
};

final _amountLine = RegExp(r'^(-?)(\d{1,3}(?:\.\d{3})*),(\d{2})\s*€$');
final _dateLine = RegExp(r'^(\d{1,2})\s+(\S+)(?:\s+(\d{4}))?$');
final _yearLine = RegExp(r'^\d{4}$');

const _pageHeaderStart = 'TRADE REPUBLIC BANK GMBH';
const _columnHeader = [
  'DATUM',
  'TYP',
  'BESCHREIBUNG',
  'ZAHLUNGSEINGANG',
  'ZAHLUNGSAUSGANG',
  'SALDO',
];
const _incomingTransferPrefix = 'Incoming transfer from ';

bool isGermanAmount(String s) => _amountLine.hasMatch(s.trim());

/// `"1.234,56 €"` → `123456`.
int parseGermanAmount(String s) {
  final m = _amountLine.firstMatch(s.trim());
  if (m == null) {
    throw ValidationException('Not a euro amount: "$s"');
  }
  final cents =
      int.parse(m.group(2)!.replaceAll('.', '')) * 100 + int.parse(m.group(3)!);
  return m.group(1) == '-' ? -cents : cents;
}

/// `123456` → `"1.234,56 €"`.
String formatGermanAmount(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final euros = (abs ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+$)'),
        (_) => '.',
      );
  return '$sign$euros,${(abs % 100).toString().padLeft(2, '0')} €';
}

/// Parses the text of a Trade Republic Kontoauszug as extracted from the PDF
/// (one table cell per line) and checks it against the KONTOÜBERSICHT.
///
/// Throws [ValidationException] if the text can't be read or if the parsed
/// incoming total, outgoing total or final balance differ from the header.
BankStatement parseBankStatement(String text) {
  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final holder = _accountHolder(lines);
  final header = _overview(lines);
  final opening = header[0];

  final start = lines.indexOf('UMSATZÜBERSICHT');
  if (start == -1) {
    throw const ValidationException('UMSATZÜBERSICHT not found.');
  }
  var end = lines.indexOf('BARMITTELÜBERSICHT', start);
  if (end == -1) end = lines.length;
  final body = _withoutPageChrome(lines.sublist(start + 1, end));

  final transactions = <BankTransaction>[];
  var previousBalance = opening;
  var i = 0;
  while (i < body.length) {
    final dateMatch = _dateLine.firstMatch(body[i]);
    if (dateMatch == null) {
      throw ValidationException(
          'Expected a date in UMSATZÜBERSICHT, found "${body[i]}".');
    }
    final dateText = body[i];
    i++;

    final month = _months[dateMatch.group(2)!];
    if (month == null) {
      throw ValidationException(
          'Unknown month abbreviation "${dateMatch.group(2)}" in "$dateText".');
    }
    var year = dateMatch.group(3);
    if (year == null) {
      if (i >= body.length || !_yearLine.hasMatch(body[i])) {
        throw ValidationException('No year after "$dateText".');
      }
      year = body[i];
      i++;
    }
    final bookedOn =
        DateTime(int.parse(year), month, int.parse(dateMatch.group(1)!));

    if (i >= body.length) {
      throw ValidationException('Row "$dateText $year" is cut off.');
    }
    final type = body[i];
    i++;

    final descriptionLines = <String>[];
    while (i < body.length && !isGermanAmount(body[i])) {
      descriptionLines.add(body[i]);
      i++;
    }
    if (i + 1 >= body.length || !isGermanAmount(body[i + 1])) {
      throw ValidationException(
          'Row "$dateText $year $type" has no amount and balance.');
    }
    final printedAmount = parseGermanAmount(body[i]);
    final balance = parseGermanAmount(body[i + 1]);
    i += 2;

    final description = descriptionLines.join(' ');
    final amount = balance - previousBalance;
    if (amount.abs() != printedAmount) {
      throw ValidationException(
          'Row "$dateText $year $description": amount '
          '${formatGermanAmount(printedAmount)} does not match the balance '
          'change ${formatGermanAmount(amount)}.');
    }

    transactions.add(BankTransaction(
      bookedOn: bookedOn,
      type: type,
      description: description,
      amountCents: amount,
      balanceCents: balance,
      kind: _kindOf(type, amount, descriptionLines, holder),
    ));
    previousBalance = balance;
  }

  final statement = BankStatement(
    accountHolder: holder,
    openingBalanceCents: opening,
    incomingCents: header[1],
    outgoingCents: header[2],
    closingBalanceCents: header[3],
    transactions: transactions,
  );
  _validate(statement);
  return statement;
}

/// The holder's name is the line right after the BIC value in the address
/// block.
String _accountHolder(List<String> lines) {
  final bic = lines.indexOf('BIC');
  if (bic == -1 || bic + 2 >= lines.length) {
    throw const ValidationException('Account holder not found.');
  }
  return lines[bic + 2];
}

/// ANFANGSSALDO, ZAHLUNGSEINGANG, ZAHLUNGSAUSGANG, ENDSALDO in cents.
List<int> _overview(List<String> lines) {
  final start = lines.indexOf('KONTOÜBERSICHT');
  final labels = start == -1 ? -1 : lines.indexOf('ENDSALDO', start);
  if (labels == -1) {
    throw const ValidationException('KONTOÜBERSICHT not found.');
  }
  final amounts = <int>[];
  for (var i = labels + 1; i < lines.length && amounts.length < 4; i++) {
    if (lines[i] == 'UMSATZÜBERSICHT') break;
    if (isGermanAmount(lines[i])) amounts.add(parseGermanAmount(lines[i]));
  }
  if (amounts.length != 4) {
    throw const ValidationException(
        'KONTOÜBERSICHT does not have four amounts.');
  }
  return amounts;
}

/// Drops the column header under UMSATZÜBERSICHT and the letterhead, footer
/// and column header that repeat on every following page.
List<String> _withoutPageChrome(List<String> lines) {
  final out = <String>[];
  var i = 0;
  while (i < lines.length) {
    if (lines[i] == _pageHeaderStart) {
      while (i < lines.length && lines[i] != _columnHeader.last) {
        i++;
      }
      i++;
      continue;
    }
    if (_isColumnHeaderAt(lines, i)) {
      i += _columnHeader.length;
      continue;
    }
    out.add(lines[i]);
    i++;
  }
  return out;
}

bool _isColumnHeaderAt(List<String> lines, int i) {
  if (i + _columnHeader.length > lines.length) return false;
  for (var j = 0; j < _columnHeader.length; j++) {
    if (lines[i + j] != _columnHeader[j]) return false;
  }
  return true;
}

BankTransactionType _kindOf(
  String type,
  int amount,
  List<String> descriptionLines,
  String holder,
) {
  if (amount == 0) return BankTransactionType.other;
  if (type == 'Kartentransaktion') {
    return amount < 0
        ? BankTransactionType.cardPayment
        : BankTransactionType.refund;
  }
  if (amount > 0 &&
      descriptionLines.isNotEmpty &&
      _isFromHolder(descriptionLines.first, holder)) {
    return BankTransactionType.topUp;
  }
  return BankTransactionType.other;
}

/// `Incoming transfer from N/A DLDAR TAHER GULANI` → sender equals holder.
/// Trade Republic prints `N/A` in front of the sender's name; it is not part
/// of the name.
bool _isFromHolder(String line, String holder) {
  if (!line.startsWith(_incomingTransferPrefix)) return false;
  var sender = line
      .substring(_incomingTransferPrefix.length)
      .replaceAll(RegExp(r'\(.*\)'), '')
      .trim();
  if (sender.startsWith('N/A ')) sender = sender.substring(4);
  String norm(String s) => s.toLowerCase().split(RegExp(r'\s+')).join(' ');
  return norm(sender) == norm(holder);
}

void _validate(BankStatement s) {
  var incoming = 0;
  var outgoing = 0;
  for (final t in s.transactions) {
    if (t.amountCents > 0) {
      incoming += t.amountCents;
    } else {
      outgoing -= t.amountCents;
    }
  }
  final closing = s.transactions.isEmpty
      ? s.openingBalanceCents
      : s.transactions.last.balanceCents;

  final problems = [
    if (incoming != s.incomingCents)
      'incoming ${formatGermanAmount(incoming)}, statement says '
          '${formatGermanAmount(s.incomingCents)}',
    if (outgoing != s.outgoingCents)
      'outgoing ${formatGermanAmount(outgoing)}, statement says '
          '${formatGermanAmount(s.outgoingCents)}',
    if (closing != s.closingBalanceCents)
      'final balance ${formatGermanAmount(closing)}, statement says '
          '${formatGermanAmount(s.closingBalanceCents)}',
  ];
  if (problems.isNotEmpty) {
    throw ValidationException(
        'Statement does not add up, import rejected: ${problems.join('; ')}.');
  }
}
