import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_result.dart';
import '../services/anakin_wire_service.dart';

class ResultsScreen extends StatefulWidget {
  final AnalysisResult result;
  final LlmExplanation explanation;
  final AnalysisMode mode;
  final bool isBatch;
  final bool isCrawl;
  final List<String>? batchUrls;
  final List<String>? discoveredUrls;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final String language;
  final Function(String) onChangeLanguage;

  const ResultsScreen({
    super.key,
    required this.result,
    required this.explanation,
    required this.mode,
    this.isBatch = false,
    this.isCrawl = false,
    this.batchUrls,
    this.discoveredUrls,
    required this.themeMode,
    required this.onToggleTheme,
    required this.language,
    required this.onChangeLanguage,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnakinWireService _anakinWire = AnakinWireService();
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _chatHistory = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _agenticSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _chatHistory.add(ChatMessage(role: 'user', content: query));
    });

    try {
      final result = await _anakinWire.agenticSearch(
        query,
        contextUrl: widget.result.url,
      );
      setState(() {
        _chatHistory.add(ChatMessage(
          role: 'assistant',
          content: result,
          hasCitations: true,
        ));
      });
    } catch (e) {
      setState(() {
        _chatHistory.add(ChatMessage(
          role: 'assistant',
          content: 'Search error: $e',
        ));
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Anakin Oracle Protocol - Analysis Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Mode: ${widget.mode.displayName} | Category: ${widget.explanation.category}',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Summary')),
          pw.Text(widget.explanation.summary),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Key Points')),
          ...widget.explanation.keyPoints.map((p) => pw.Bullet(text: p)),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Insights')),
          ...widget.explanation.insights.map((i) => pw.Bullet(text: i)),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Sentiment Analysis')),
          pw.Text('Positive: ${(widget.explanation.sentiment['positive']! * 100).toStringAsFixed(1)}%'),
          pw.Text('Neutral: ${(widget.explanation.sentiment['neutral']! * 100).toStringAsFixed(1)}%'),
          pw.Text('Negative: ${(widget.explanation.sentiment['negative']! * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'anakin_report.pdf');
  }

  Future<void> _shareReport() async {
    final content = '''
📊 Anakin Oracle Analysis Report

🔗 URL: ${widget.result.url}
📱 Mode: ${widget.mode.displayName}
📁 Category: ${widget.explanation.category}

📝 Summary:
${widget.explanation.summary}

🔑 Key Points:
${widget.explanation.keyPoints.map((p) => '• $p').join('\n')}

💡 Insights:
${widget.explanation.insights.map((i) => '• $i').join('\n')}

😊 Sentiment: Positive ${(widget.explanation.sentiment['positive']! * 100).toStringAsFixed(0)}% | 
Neutral ${(widget.explanation.sentiment['neutral']! * 100).toStringAsFixed(0)}% | 
Negative ${(widget.explanation.sentiment['negative']! * 100).toStringAsFixed(0)}%
''';
    await Share.share(content, subject: 'Anakin Analysis Report');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final sentiment = widget.explanation.sentiment;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'ANALYSIS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 20),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_rounded), onPressed: _generatePdf),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: _shareReport),
          IconButton(
            icon: AnimatedSwitcher(
              duration: 300.ms,
              child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, key: ValueKey(isDark)),
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primary,
              ),
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              tabs: const [
                Tab(child: Icon(Icons.article_rounded, size: 20)),
                Tab(child: Icon(Icons.analytics_rounded, size: 20)),
                Tab(child: Icon(Icons.chat_bubble_rounded, size: 20)),
                Tab(child: Icon(Icons.info_rounded, size: 20)),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildChartsTab(sentiment),
          _buildChatTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final sentiment = widget.explanation.sentiment;
    final result = widget.result;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(result).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 24),
          _buildSectionHeader('EXECUTIVE SUMMARY', Icons.summarize_rounded).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            ),
            child: Text(
              widget.explanation.summary,
              style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w400),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
          const SizedBox(height: 32),
          _buildSectionHeader('KEY OBSERVATIONS', Icons.auto_awesome_mosaic_rounded).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 12),
          ...widget.explanation.keyPoints.asMap().entries.map((e) => _buildKeyPointItem(e.key + 1, e.value).animate().fadeIn(delay: (500 + e.key * 100).ms).slideX(begin: 0.05)).toList(),
          const SizedBox(height: 32),
          _buildSectionHeader('SENTIMENT PROTOCOL', Icons.radar_rounded).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 16),
          _buildSentimentRadial(sentiment).animate().fadeIn(delay: 900.ms).scale(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroCard(AnalysisResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              widget.explanation.category.toUpperCase(),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            result.title ?? 'No Title Detected',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            result.url,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        ),
      ],
    );
  }

  Widget _buildKeyPointItem(int index, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text('$index', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildSentimentRadial(Map<String, double> sentiment) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(value: sentiment['positive']! * 100, color: Colors.green, radius: 25, showTitle: false),
                  PieChartSectionData(value: sentiment['neutral']! * 100, color: Colors.grey, radius: 20, showTitle: false),
                  PieChartSectionData(value: sentiment['negative']! * 100, color: Colors.red, radius: 25, showTitle: false),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildSentimentRow('POSITIVE', sentiment['positive']!, Colors.green),
              const SizedBox(height: 12),
              _buildSentimentRow('NEUTRAL', sentiment['neutral']!, Colors.grey),
              const SizedBox(height: 12),
              _buildSentimentRow('NEGATIVE', sentiment['negative']!, Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
            Text('${(value * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(value: value, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
        ),
      ],
    );
  }

  Widget _buildChartsTab(Map<String, double> sentiment) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildChartContainer('DATA DISTRIBUTION', SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(value: sentiment['positive']! * 100, title: 'POS', color: Colors.green, radius: 30, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  PieChartSectionData(value: sentiment['neutral']! * 100, title: 'NEU', color: Colors.grey, radius: 30, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  PieChartSectionData(value: sentiment['negative']! * 100, title: 'NEG', color: Colors.red, radius: 30, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          )).animate().fadeIn().scale(),
          const SizedBox(height: 24),
          _buildChartContainer('EMOTIONAL TRAJECTORY', SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [const FlSpot(0, 1), const FlSpot(1, 3), const FlSpot(2, 2), const FlSpot(3, 5), const FlSpot(4, 4)],
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          )).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
          const SizedBox(height: 24),
          chart,
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _chatHistory.length,
            itemBuilder: (context, index) {
              final msg = _chatHistory[index];
              final isUser = msg.role == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                    border: isUser ? null : Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(color: isUser ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Query the Oracle...',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _isSearching ? null : () => _agenticSearch(_chatController.text),
                icon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    final result = widget.result;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoSection('METADATA ARCHIVE', [
            _buildDetailRow('TITLE', result.title ?? 'N/A'),
            _buildDetailRow('AUTHOR', result.author ?? 'N/A'),
            _buildDetailRow('LANG', result.language ?? 'N/A'),
            _buildDetailRow('LENGTH', '${result.contentLength} chars'),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('PROTOCOL SPECIFICS', [
            _buildDetailRow('URL', result.url),
            _buildDetailRow('LOAD TIME', result.loadTime ?? 'N/A'),
            _buildDetailRow('PAGE SIZE', result.pageSize ?? 'N/A'),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  final bool hasCitations;

  ChatMessage({required this.role, required this.content, this.hasCitations = false});
}