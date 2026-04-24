import '../../../../core/error/app_exception.dart';
import '../../domain/entities/budget_transaction.dart';
import '../../domain/repositories/budget_repository.dart';

class AddTransactionUseCase {
  final BudgetRepository _repository;

  const AddTransactionUseCase(this._repository);

  Future<BudgetTransaction> execute({
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) async {
    if (amountCents <= 0) {
      throw const ValidationException('Amount must be greater than zero.');
    }
    if (categoryId.isEmpty) {
      throw const ValidationException('A category must be selected.');
    }
    return _repository.addTransaction(
      categoryId: categoryId,
      amountCents: amountCents,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      spentAt: spentAt,
    );
  }
}
