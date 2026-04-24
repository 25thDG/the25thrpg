import '../../domain/repositories/budget_repository.dart';

class DeleteCategoryUseCase {
  final BudgetRepository _repository;

  const DeleteCategoryUseCase(this._repository);

  Future<void> execute(String id) => _repository.deleteCategory(id);
}
