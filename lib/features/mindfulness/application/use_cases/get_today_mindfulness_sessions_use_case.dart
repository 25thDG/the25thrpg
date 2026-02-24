import '../../domain/entities/mindfulness_session.dart';
import '../../domain/repositories/mindfulness_repository.dart';

class GetTodayMindfulnessSessionsUseCase {
  final MindfulnessRepository _repository;

  const GetTodayMindfulnessSessionsUseCase(this._repository);

  Future<List<MindfulnessSession>> execute() => _repository.getTodaySessions();
}
