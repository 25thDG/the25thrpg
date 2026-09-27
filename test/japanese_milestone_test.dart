import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/japanese/application/use_cases/get_japanese_stats_use_case.dart';
import 'package:the25thrpg/features/japanese/domain/entities/japanese_milestone.dart';
import 'package:the25thrpg/features/japanese/domain/entities/japanese_session.dart';
import 'package:the25thrpg/features/japanese/domain/repositories/japanese_repository.dart';

const _japan = JapaneseMilestone(targetHours: 700, label: 'Japan');

MilestoneForecast _forecast(double lifetime, double perWeek) =>
    MilestoneForecast(
      milestone: _japan,
      lifetimeHours: lifetime,
      hoursPerWeek: perWeek,
    );

JapaneseSession _session(int minutes, DateTime at) => JapaneseSession(
      id: '$minutes-${at.millisecondsSinceEpoch}',
      userId: 'u',
      category: SessionCategory.vocab,
      minutes: minutes,
      sessionAt: at,
      createdAt: at,
      updatedAt: at,
    );

class _FakeRepo implements JapaneseRepository {
  final List<JapaneseSession> sessions;
  _FakeRepo(this.sessions);

  @override
  Future<List<JapaneseSession>> getAllActiveSessions() async => sessions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('milestone forecast', () {
    test('divides the remaining hours by the weekly pace', () {
      // 100 h left at 7 h/week = 1 h/day → 100 days.
      final f = _forecast(600, 7);
      expect(f.remainingHours, 100);
      expect(f.daysLeft, 100);
    });

    test('rounds a partial day up', () {
      // 10 h left at 3.5 h/week = 0.5 h/day → 20 days exactly; 10.1 h → 21.
      expect(_forecast(690, 3.5).daysLeft, 20);
      expect(_forecast(689.9, 3.5).daysLeft, 21);
    });

    test('has no forecast when nothing was logged this week', () {
      final f = _forecast(162, 0);
      expect(f.daysLeft, isNull);
      expect(f.etaFrom(DateTime(2026, 9, 28)), isNull);
    });

    test('is done once the target is passed', () {
      final f = _forecast(712, 0);
      expect(f.isReached, isTrue);
      expect(f.remainingHours, 0);
      expect(f.progress, 1.0);
      expect(f.daysLeft, 0);
    });

    test('ETA is a calendar date counted from today', () {
      // 7 h left at 7 h/week → 7 days, across a month boundary.
      final eta = _forecast(693, 7).etaFrom(DateTime(2026, 9, 28, 23, 30));
      expect(eta, DateTime(2026, 10, 5));
    });
  });

  group('weekly pace', () {
    test('last 7 days leave out backfill rows', () async {
      final now = DateTime.now();
      final stats = await GetJapaneseStatsUseCase(_FakeRepo([
        _session(60, now.subtract(const Duration(days: 1))),
        _session(90, now.subtract(const Duration(days: 3))),
        _session(4000, now.subtract(const Duration(days: 2))), // backfill
        _session(120, now.subtract(const Duration(days: 9))), // too old
      ])).execute();

      expect(stats.last7DaysMinutes, 150);
      // Backfill still counts toward the lifetime total.
      expect(stats.lifetimeMinutes, 4270);
    });
  });
}
