import 'dart:convert';
import 'package:http/http.dart' as http;
import 'article.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class NewsApiService {
  final String baseUrl = dotenv.env['API_URL']!;

  Future<List<Article>> fetchTopHeadlines({int page = 1}) async {
    final String url = '${baseUrl}news?page=$page'; 
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((jsonItem) => Article.fromJson(jsonItem)).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }
}
