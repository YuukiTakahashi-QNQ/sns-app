import '../entities/trend.dart';

abstract class TrendRepository {
  Future<List<Trend>> fetchTrends();
}