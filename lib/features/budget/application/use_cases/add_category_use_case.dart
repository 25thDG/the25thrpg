import '../../../../core/error/app_exception.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/budget_repository.dart';

class AddCategoryUseCase {
  final BudgetRepository _repository;

  const AddCategoryUseCase(this._repository);

  Future<BudgetCategory> execute({
    required String name,
    required String iconKey,
    required int colorIndex,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Category name cannot be empty.');
    }
    return _repository.addCategory(
      name: name.trim(),
      iconKey: iconKey,
      colorIndex: colorIndex,
    );
  }
}
