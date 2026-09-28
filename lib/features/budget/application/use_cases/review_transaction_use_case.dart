import '../../../../core/error/app_exception.dart';
import '../../domain/repositories/budget_repository.dart';

class ReviewTransactionUseCase {
  final BudgetRepository _repository;

  const ReviewTransactionUseCase(this._repository);

  Future<void> execute({
    required String id,
    required String categoryId,
    String? note,
  }) async {
    if (categoryId.isEmpty) {
      throw const ValidationException('A category must be selected.');
    }
    return _repository.reviewTransaction(
      id: id,
      categoryId: categoryId,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
  }
}
