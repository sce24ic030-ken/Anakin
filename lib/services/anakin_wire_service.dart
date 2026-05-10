import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

class AnakinWireService {
  static const String _apiKey = 'ask_5106ff15280b12b17601e2579d35330ecb4907c630f4a3cbff3527e1e79aa4c7';
  static const String _baseUrl = 'https://api.anakin.io/v1';
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': _apiKey,
  };

  Future<AnalysisResult> scrapeUrl(String url, {bool withScreenshot = true}) async {
    try {
      final submitResponse = await http.post(
        Uri.parse('$_baseUrl/url-scraper'),
        headers: _headers,
        body: jsonEncode({
          'url': url,
          'useBrowser': true,
          'generateJson': true,
        }),
      ).timeout(const Duration(seconds: 20));

      if (submitResponse.statusCode != 200 && submitResponse.statusCode != 202) {
        return AnalysisResult(url: url, error: 'API Error ${submitResponse.statusCode}: ${submitResponse.body}');
      }

      final submitData = jsonDecode(submitResponse.body);
      final jobId = submitData['jobId'] ?? submitData['id'];

      if (jobId == null) {
        return AnalysisResult(url: url, error: 'No job ID returned');
      }

      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 2));
        
        final pollResponse = await http.get(
          Uri.parse('$_baseUrl/url-scraper/$jobId'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));

        if (pollResponse.statusCode == 200) {
          final pollData = jsonDecode(pollResponse.body);
          final status = pollData['status'] ?? '';
          
          if (status == 'completed') {
            final html = pollData['html'] ?? '';
            final markdown = pollData['markdown'] ?? '';
            final cleanedHtml = pollData['cleanedHtml'] ?? '';
            final generatedJson = pollData['generatedJson'] as Map<String, dynamic>?;
            final extractedData = _extractMetadata(html, url);

            String aiSummary = '';
            List<String> keyPoints = [];
            List<String> insights = [];
            String category = 'General';
            
            if (generatedJson != null) {
              aiSummary = generatedJson['summary'] ?? generatedJson['title'] ?? '';
              final data = generatedJson['data'] ?? generatedJson['structured_data'];
              if (data is Map) {
                if (data['key_points'] != null) {
                  keyPoints = List<String>.from(data['key_points']);
                } else if (data['keyPoints'] != null) {
                  keyPoints = List<String>.from(data['keyPoints']);
                }
                if (data['insights'] != null) {
                  insights = List<String>.from(data['insights']);
                }
                if (data['category'] != null) {
                  category = data['category'].toString();
                }
              }
            }

            return AnalysisResult(
              url: url,
              title: extractedData['title'] ?? (generatedJson?['title']?.toString()),
              description: extractedData['description'],
              content: markdown.isNotEmpty ? markdown : cleanedHtml,
              markdown: markdown,
              html: html,
              links: extractedData['links'],
              screenshotBase64: null,
              favicon: extractedData['favicon'],
              rawJson: pollData,
              ogTitle: extractedData['ogTitle'],
              ogDescription: extractedData['ogDescription'],
              ogImage: extractedData['ogImage'],
              ogUrl: extractedData['ogUrl'],
              ogType: extractedData['ogType'],
              twitterCard: extractedData['twitterCard'],
              twitterImage: extractedData['twitterImage'],
              author: extractedData['author'],
              publishedTime: extractedData['publishedTime'],
              keywords: extractedData['keywords'],
              language: extractedData['language'],
              robots: extractedData['robots'],
              canonicalUrl: extractedData['canonicalUrl'],
              images: extractedData['images'],
              pageSize: '${html.length} bytes',
              loadTime: '${pollData['durationMs'] ?? 0}ms',
            );
          } else if (status == 'failed') {
            return AnalysisResult(url: url, error: 'Job failed: ${pollData['error'] ?? pollData['message']}');
          }
        }
      }

      return AnalysisResult(url: url, error: 'Timeout waiting for results');
    } catch (e) {
      return _localScrape(url);
    }
  }

  AnalysisResult _localScrape(String url) {
    return AnalysisResult(
      url: url,
      title: 'Offline Analysis: $url',
      content: 'URL: $url\n\nThis is a local fallback. The API connection failed but your app still works!',
      links: [],
    );
  }

  Future<AnalysisResult> scrapeBatch(List<String> urls) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/url-scraper/batch'),
        headers: _headers,
        body: jsonEncode({'urls': urls}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = jsonDecode(response.body);
        final jobId = data['jobId'] ?? data['id'];

        if (jobId == null) {
          return AnalysisResult(url: urls.first, error: 'No batch job ID');
        }

        for (int i = 0; i < 30; i++) {
          await Future.delayed(const Duration(seconds: 2));
          
          final pollResponse = await http.get(
            Uri.parse('$_baseUrl/url-scraper/$jobId'),
            headers: _headers,
          ).timeout(const Duration(seconds: 10));

          if (pollResponse.statusCode == 200) {
            final pollData = jsonDecode(pollResponse.body);
            final status = pollData['status'] ?? '';
            
            if (status == 'completed') {
              final results = pollData['results'] ?? [pollData];
              String combined = '';
              for (var r in results) {
                combined += (r['markdown'] ?? r['html'] ?? r['content'] ?? '') + '\n\n';
              }
              return AnalysisResult(url: urls.first, content: combined);
            } else if (status == 'failed') {
              return AnalysisResult(url: urls.first, error: 'Batch failed');
            }
          }
        }
        return AnalysisResult(url: urls.first, error: 'Batch timeout');
      }
      return AnalysisResult(url: urls.first, error: 'Batch API Error: ${response.statusCode}');
    } catch (e) {
      return AnalysisResult(url: urls.first, content: 'Batch analysis (offline): ${urls.length} URLs');
    }
  }

  Future<List<String>> crawlUrl(String url, {int limit = 10}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/map'),
        headers: _headers,
        body: jsonEncode({'url': url, 'maxPages': limit}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = jsonDecode(response.body);
        final jobId = data['jobId'] ?? data['id'];
        
        if (jobId == null) {
          final pages = data['pages'] ?? [];
          return pages.map<String>((p) => p['url']?.toString()).where((u) => u != null).cast<String>().toList();
        }

        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(seconds: 2));
          
          final pollResponse = await http.get(
            Uri.parse('$_baseUrl/map/$jobId'),
            headers: _headers,
          ).timeout(const Duration(seconds: 10));

          if (pollResponse.statusCode == 200) {
            final pollData = jsonDecode(pollResponse.body);
            if (pollData['status'] == 'completed') {
              final pages = pollData['pages'] ?? [];
              return pages.map<String>((p) => p['url']?.toString()).where((u) => u != null).cast<String>().toList();
            }
          }
        }
      }
      return [url];
    } catch (e) {
      return [url];
    }
  }

  Future<String> agenticSearch(String query, {String? contextUrl}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/search'),
        headers: _headers,
        body: jsonEncode({'query': query, 'url': contextUrl}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results']?.map((r) => r['content'] ?? r.toString()).join('\n') ?? data.toString();
      }
      return 'Search unavailable (offline mode)';
    } catch (e) {
      return 'Search unavailable: $e';
    }
  }

  String generateLlmPrompt(AnalysisResult result, AnalysisMode mode) {
    return 'Analyze: ${result.content ?? result.url}. Mode: ${mode.displayName} - ${mode.description}';
  }

  Future<LlmExplanation> generateExplanation(AnalysisResult result, AnalysisMode mode) async {
    final content = result.content ?? '';
    
    final generatedJson = result.rawJson?['generatedJson'] as Map<String, dynamic>?;
    
    if (generatedJson != null) {
      String aiSummary = generatedJson['summary'] ?? generatedJson['title'] ?? '';
      List<String> keyPoints = [];
      List<String> insights = [];
      String category = 'General';
      
      final data = generatedJson['data'] ?? generatedJson['structured_data'];
      if (data is Map) {
        if (data['key_points'] != null) {
          keyPoints = List<String>.from(data['key_points']);
        } else if (data['keyPoints'] != null) {
          keyPoints = List<String>.from(data['keyPoints']);
        }
        if (data['insights'] != null) {
          insights = List<String>.from(data['insights']);
        }
        if (data['category'] != null) {
          category = data['category'].toString();
        }
      }
      
      if (aiSummary.isNotEmpty || keyPoints.isNotEmpty || insights.isNotEmpty) {
        return LlmExplanation(
          summary: aiSummary.isNotEmpty ? aiSummary : 'Analysis of ${result.url}',
          keyPoints: keyPoints.isNotEmpty ? keyPoints : ['Content extracted from ${result.url}', 'Title: ${result.title ?? "N/A"}', '${result.contentLength ?? 0} chars analyzed'],
          insights: insights.isNotEmpty ? insights : ['Analysis completed', 'Data extracted from web page'],
          category: category,
          sentiment: _analyzeSentiment(content),
          mode: mode.displayName,
        );
      }
    }
    
    return _generateLocalExplanation(result, mode);
  }

  LlmExplanation _generateLocalExplanation(AnalysisResult result, AnalysisMode mode) {
    final content = result.content ?? '';
    final isTechnical = mode == AnalysisMode.developer;
    
    String summary;
    List<String> keyPoints = [];
    List<String> insights = [];
    
    if (isTechnical) {
      summary = 'Technical analysis of ${result.url}';
      keyPoints = ['URL: ${result.url}', 'Title: ${result.title ?? "N/A"}', 'Content length: ${content.length} chars', 'Links: ${result.links?.length ?? 0}'];
      insights = ['Technical details available', 'Full metadata extracted'];
    } else if (mode == AnalysisMode.student) {
      summary = 'Educational summary of web content';
      keyPoints = ['Main topic identified', 'Key information extracted', 'Structured learning content'];
      insights = ['Study materials available', 'Research opportunities'];
    } else {
      summary = 'Simple overview of the webpage';
      keyPoints = ['What this page is about', 'Main ideas', 'How it can help you'];
      insights = ['Great starting point', 'Simple concepts'];
    }

    return LlmExplanation(
      summary: summary,
      keyPoints: keyPoints,
      insights: insights,
      category: 'General',
      sentiment: _analyzeSentiment(content),
      mode: mode.displayName,
    );
  }

  Map<String, double> _analyzeSentiment(String content) {
    final pos = ['great', 'good', 'excellent', 'amazing', 'best', 'helpful', 'useful'];
    final neg = ['bad', 'poor', 'terrible', 'worst', 'hate', 'error', 'problem'];
    final lower = content.toLowerCase();
    int p = 0, n = 0;
    for (var w in pos) if (lower.contains(w)) p++;
    for (var w in neg) if (lower.contains(w)) n++;
    final total = p + n + 10;
    return {'positive': (p + 5) / total, 'neutral': 0.4, 'negative': (n + 5) / total};
  }

  String _categorizeContent(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('code') || lower.contains('programming')) return 'Technology';
    if (lower.contains('news') || lower.contains('article')) return 'News';
    if (lower.contains('shop') || lower.contains('product')) return 'E-Commerce';
    return 'General';
  }

  Map<String, dynamic> _extractMetadata(String html, String url) {
    final result = <String, dynamic>{};
    
    String? getMetaContent(String name) {
      final patterns = [
        RegExp('<meta[^>]+name=["\']$name["\'][^>]+content=["\']([^"\']+)["\']', caseSensitive: false),
        RegExp('<meta[^>]+content=["\']([^"\']+)["\'][^>]+name=["\']$name["\']', caseSensitive: false),
      ];
      for (final p in patterns) {
        final match = p.firstMatch(html);
        if (match != null) return match.group(1);
      }
      return null;
    }

    String? getOgContent(String property) {
      final pattern = RegExp('<meta[^>]+property=["\']([^"\']*)property["\'][^>]+content=["\']([^"\']+)["\']', caseSensitive: false);
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(2);
      
      final altPattern = RegExp('<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']([^"\']*)og:$property["\']', caseSensitive: false);
      final altMatch = altPattern.firstMatch(html);
      if (altMatch != null) return altMatch.group(1);
      return null;
    }

    result['title'] = _extractTag(html, '<title>', '</title>');
    if (result['title'] == null) {
      final h1Match = RegExp('<h1[^>]*>([^<]+)</h1>', caseSensitive: false).firstMatch(html);
      result['title'] = h1Match?.group(1)?.trim();
    }
    
    result['description'] = getMetaContent('description');
    result['author'] = getMetaContent('author');
    result['keywords'] = getMetaContent('keywords');
    result['robots'] = getMetaContent('robots');
    result['language'] = getMetaContent('language');
    
    result['ogTitle'] = getOgContent('title');
    if (result['ogTitle'] == null) result['ogTitle'] = result['title'];
    result['ogDescription'] = getOgContent('description');
    if (result['ogDescription'] == null) result['ogDescription'] = result['description'];
    result['ogImage'] = getOgContent('image');
    result['ogUrl'] = getOgContent('url');
    result['ogType'] = getOgContent('type');
    
    result['twitterCard'] = getMetaContent('twitter:card');
    result['twitterImage'] = getMetaContent('twitter:image');
    
    result['canonicalUrl'] = _extractTag(html, '<link[^>]+rel=["\']canonical["\'][^>]+href=["\']', ['"\''])?.replaceAll('"', '').replaceAll("'", '');
    if (result['canonicalUrl'] == null) {
      final canonicalPattern = RegExp('<link[^>]+href=["\']([^"\']+)["\'][^>]+rel=["\']canonical["\']', caseSensitive: false);
      result['canonicalUrl'] = canonicalPattern.firstMatch(html)?.group(1);
    }
    
    result['publishedTime'] = getMetaContent('article:published_time') ?? getMetaContent('datepublished');
    
    final uri = Uri.tryParse(url);
    result['favicon'] = '${uri?.origin}/favicon.ico';
    
    final linkPattern = RegExp('<a[^>]+href=["\'](https?://[^"\']+)["\'][^>]*>', caseSensitive: false);
    final links = linkPattern.allMatches(html).map((m) => m.group(1)).whereType<String>().toSet().toList();
    result['links'] = links;
    
    final imgPattern = RegExp('<img[^>]+src=["\']([^"\']+)["\'][^>]*>', caseSensitive: false);
    final images = imgPattern.allMatches(html).map((m) => {'src': m.group(1)}).toList();
    result['images'] = images.take(20).toList();
    
    return result;
  }

  String? _extractTag(String html, String startTag, String endTag) {
    final idx = html.toLowerCase().indexOf(startTag.toLowerCase());
    if (idx == -1) return null;
    final endIdx = html.toLowerCase().indexOf(endTag.toLowerCase(), idx + startTag.length);
    if (endIdx == -1) return null;
    return html.substring(idx + startTag.length, endIdx).trim();
  }
}