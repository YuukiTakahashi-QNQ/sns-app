// lib/features/tweet/data/datasources/tweet_remote_data_source.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/tweet_model.dart';

abstract class TweetRemoteDataSource {
  Future<List<TweetModel>> fetchTweets();
  Future<TweetModel> createTweet(String content, int userId);
}

class TweetRemoteDataSourceImpl implements TweetRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'https://flutterlabo.tech/api/test';

  TweetRemoteDataSourceImpl({http.Client? client})
    : client = client ?? http.Client();

  @override
  Future<List<TweetModel>> fetchTweets() async {
    final response = await client.get(Uri.parse('$baseUrl/tweet'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => TweetModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load tweets');
    }
  }

  @override
  Future<TweetModel> createTweet(String content, int userId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/tweet'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'content': content, 'user_id': userId}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return TweetModel.fromJson(data);
    } else {
      throw Exception('Failed to create tweet');
    }
  }
}
