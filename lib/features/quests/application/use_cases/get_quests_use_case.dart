import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';

class GetQuestsUseCase {
  final QuestRepository _repository;
  const GetQuestsUseCase(this._repository);
  Future<List<Quest>> call() => _repository.getQuests();
}
