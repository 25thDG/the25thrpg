import '../../domain/entities/japanese_session.dart';
import '../../domain/repositories/japanese_repository.dart';

class GetTodayJapaneseSessionsUseCase {
  final JapaneseRepository _repository;

  const GetTodayJapaneseSessionsUseCase(this._repository);

  Future<List<JapaneseSession>> execute() => _repository.getTodaySessions();
}
