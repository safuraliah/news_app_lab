import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'article.dart';
import 'news_api_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(NewsApp());
}

class NewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App Lab',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NewsHomePage(),
    );
  }
}

class NewsHomePage extends StatefulWidget {
  @override
  _NewsHomePageState createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  final NewsApiService newsApiService = NewsApiService();
  List<Article> articles = [];
  int currentPage = 1;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchArticles();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        fetchArticles();
      }
    });
  }

  void fetchArticles() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<Article> newArticles = await newsApiService.fetchTopHeadlines(page: currentPage);
      setState(() {
        articles.addAll(newArticles);
        currentPage++;
      });
    } catch (e) {
      print('Error fetching articles: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Headlines'),
      ),
      body: articles.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: articles.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < articles.length) {
                  return NewsArticleTile(article: articles[index]);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}

class NewsArticleTile extends StatelessWidget {
  final Article article;

  const NewsArticleTile({Key? key, required this.article}) : super(key: key);

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        leading: CachedNetworkImage(
          imageUrl: article.urlToImage,
          width: 100,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Container(width: 100, child: Center(child: CircularProgressIndicator())),
          errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.red),
        ),
        title: Text(article.title),
        subtitle: Text(
          article.description.length > 200
              ? '${article.description.substring(0, 200)}...'
              : article.description,
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(article.title),
              content: Text(
                article.description.length > 200
                    ? '${article.description.substring(0, 200)}...'
                    : article.description,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Close"),
                ),
                TextButton(
                  onPressed: () {
                    _launchURL(article.url);
                  },
                  child: Text("Read More"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
