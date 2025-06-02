import '../../domain/entities/trend.dart';
import '../../domain/repositories/trend_repository.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TrendRepositoryImpl implements TrendRepository {
  @override
  Future<List<Trend>> fetchTrends() async {
    final response = await http.get(Uri.parse('https://flutterlabo.tech/api/test/trend'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Trend(
        title: e['title'] as String,
        postCount: e['postCount'] as int,
      )).toList();
    } else {
      throw Exception('Failed to load trends');
    }
  }
}