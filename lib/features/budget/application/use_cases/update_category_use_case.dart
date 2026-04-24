import '../../../../core/error/app_exception.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/budget_repository.dart';

class UpdateCategoryUseCase {
  final BudgetRepository _repository;

  const UpdateCategoryUseCase(this._repository);

  Future<BudgetCategory> execute({
    required String id,
    required String name,
    required String iconKey,
    required int colorIndex,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Category name cannot be empty.');
    }
    return _repository.updateCategory(
      id: id,
      name: name.trim(),
      iconKey: iconKey,
      colorIndex: colorIndex,
    );
  }
}
