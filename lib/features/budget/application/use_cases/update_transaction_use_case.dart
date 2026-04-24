import '../../../../core/error/app_exception.dart';
import '../../domain/entities/budget_transaction.dart';
import '../../domain/repositories/budget_repository.dart';

class UpdateTransactionUseCase {
  final BudgetRepository _repository;

  const UpdateTransactionUseCase(this._repository);

  Future<BudgetTransaction> execute({
    required String id,
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) async {
    if (amountCents <= 0) {
      throw const ValidationException('Amount must be greater than zero.');
    }
    return _repository.updateTransaction(
      id: id,
      categoryId: categoryId,
      amountCents: amountCents,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      spentAt: spentAt,
    );
  }
}
