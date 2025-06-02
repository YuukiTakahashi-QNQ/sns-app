import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_sns_app/features/tweet/domain/entities/trend.dart';
import 'package:train_sns_app/features/tweet/data/datasources/trend_repository_impl.dart';

final trendListProvider = FutureProvider<List<Trend>>((ref) async {
  final repo = TrendRepositoryImpl();
  return await repo.fetchTrends();
});