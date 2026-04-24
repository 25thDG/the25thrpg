import '../../domain/repositories/budget_repository.dart';

class DeleteTransactionUseCase {
  final BudgetRepository _repository;

  const DeleteTransactionUseCase(this._repository);

  Future<void> execute(String id) => _repository.deleteTransaction(id);
}
