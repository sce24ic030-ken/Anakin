class AnalysisResult {
  final String url;
  final String? title;
  final String? description;
  final String? content;
  final String? markdown;
  final String? html;
  final List<String>? links;
  final String? screenshotBase64;
  final String? favicon;
  final Map<String, dynamic>? rawJson;
  final String? error;
  
  final String? ogTitle;
  final String? ogDescription;
  final String? ogImage;
  final String? ogUrl;
  final String? ogType;
  final String? twitterCard;
  final String? twitterImage;
  
  final String? author;
  final String? publishedTime;
  final String? keywords;
  final String? language;
  final String? robots;
  final String? canonicalUrl;
  
  final List<Map<String, dynamic>>? images;
  final List<Map<String, dynamic>>? videos;
  final String? pageSize;
  final String? loadTime;

  AnalysisResult({
    required this.url,
    this.title,
    this.description,
    this.content,
    this.markdown,
    this.html,
    this.links,
    this.screenshotBase64,
    this.favicon,
    this.rawJson,
    this.error,
    this.ogTitle,
    this.ogDescription,
    this.ogImage,
    this.ogUrl,
    this.ogType,
    this.twitterCard,
    this.twitterImage,
    this.author,
    this.publishedTime,
    this.keywords,
    this.language,
    this.robots,
    this.canonicalUrl,
    this.images,
    this.videos,
    this.pageSize,
    this.loadTime,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final openGraph = metadata['openGraph'] as Map<String, dynamic>? ?? {};
    final twitter = metadata['twitter'] as Map<String, dynamic>? ?? {};
    final seo = metadata['seo'] as Map<String, dynamic>? ?? {};
    final images = metadata['images'] as List<dynamic>? ?? [];
    final videos = metadata['videos'] as List<dynamic>? ?? [];

    return AnalysisResult(
      url: json['url'] ?? '',
      title: json['title'] ?? metadata['title'] ?? json['metadata']?['title'],
      description: json['description'] ?? metadata['description'] ?? json['metadata']?['description'],
      content: json['content'] ?? json['markdown'] ?? json['html'],
      markdown: json['markdown'],
      html: json['html'],
      links: json['links'] != null ? List<String>.from(json['links']) : null,
      screenshotBase64: json['screenshot'] ?? json['metadata']?['screenshot'],
      favicon: json['favicon'] ?? metadata['favicon'] ?? json['metadata']?['favicon'],
      rawJson: json,
      ogTitle: openGraph['title'] ?? json['ogTitle'],
      ogDescription: openGraph['description'] ?? json['ogDescription'],
      ogImage: openGraph['image'] ?? json['ogImage'],
      ogUrl: openGraph['url'],
      ogType: openGraph['type'],
      twitterCard: twitter['card'] ?? json['twitterCard'],
      twitterImage: twitter['image'] ?? json['twitterImage'],
      author: seo['author'],
      publishedTime: seo['publishedTime'] ?? json['publishedTime'],
      keywords: seo['keywords'] ?? json['keywords'],
      language: seo['language'] ?? json['language'],
      robots: seo['robots'],
      canonicalUrl: seo['canonicalUrl'] ?? json['canonicalUrl'],
      images: images.isNotEmpty ? images.cast<Map<String, dynamic>>() : null,
      videos: videos.isNotEmpty ? videos.cast<Map<String, dynamic>>() : null,
      pageSize: json['pageSize'] ?? json['metadata']?['pageSize'],
      loadTime: json['loadTime'] ?? json['metadata']?['loadTime'],
    );
  }

  bool get hasError => error != null;
  bool get hasContent => content != null || title != null || markdown != null;
  
  String get displayTitle => title ?? ogTitle ?? url;
  String get displayDescription => description ?? ogDescription ?? '';
  
  bool get hasOgImage => ogImage != null && ogImage!.isNotEmpty;
  bool get hasScreenshot => screenshotBase64 != null && screenshotBase64!.isNotEmpty;
  
  int get contentLength => (content?.length ?? 0) + (markdown?.length ?? 0);
}

class LlmExplanation {
  final String summary;
  final List<String> keyPoints;
  final List<String> insights;
  final String category;
  final Map<String, double> sentiment;
  final String mode;

  LlmExplanation({
    required this.summary,
    required this.keyPoints,
    required this.insights,
    required this.category,
    required this.sentiment,
    required this.mode,
  });

  factory LlmExplanation.fromText(String text, String mode) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    String summary = '';
    List<String> keyPoints = [];
    List<String> insights = [];
    String category = 'General';
    Map<String, double> sentiment = {'positive': 0.5, 'neutral': 0.3, 'negative': 0.2};

    for (final line in lines) {
      if (line.toLowerCase().contains('summary') && line.contains(':')) {
        summary = line.split(':').skip(1).join(':').trim();
      } else if (line.startsWith('-') || line.startsWith('•')) {
        if (line.toLowerCase().contains('insight')) {
          insights.add(line.substring(1).trim());
        } else {
          keyPoints.add(line.replaceAll(RegExp(r'^[•\-]\s*'), '').trim());
        }
      }
      if (line.toLowerCase().contains('category:')) {
        category = line.split(':').skip(1).join(':').trim();
      }
    }

    if (summary.isEmpty && lines.isNotEmpty) {
      summary = lines.take(3).join(' ');
    }

    return LlmExplanation(
      summary: summary,
      keyPoints: keyPoints,
      insights: insights,
      category: category,
      sentiment: sentiment,
      mode: mode,
    );
  }
}

enum AnalysisMode { beginner, student, developer }

extension AnalysisModeExtension on AnalysisMode {
  String get displayName {
    switch (this) {
      case AnalysisMode.beginner:
        return 'Beginner';
      case AnalysisMode.student:
        return 'Student';
      case AnalysisMode.developer:
        return 'Developer';
    }
  }

  String get description {
    switch (this) {
      case AnalysisMode.beginner:
        return 'Simple explanations with everyday examples';
      case AnalysisMode.student:
        return 'Detailed explanations with technical terms';
      case AnalysisMode.developer:
        return 'Full technical details and code analysis';
    }
  }

  String get emoji {
    switch (this) {
      case AnalysisMode.beginner:
        return '🌱';
      case AnalysisMode.student:
        return '📚';
      case AnalysisMode.developer:
        return '💻';
    }
  }
}