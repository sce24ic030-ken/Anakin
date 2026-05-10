import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_result.dart';
import '../services/anakin_wire_service.dart';
import 'results_screen.dart';

class MainScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final String language;
  final Function(String) onChangeLanguage;

  const MainScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.language,
    required this.onChangeLanguage,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final AnakinWireService _anakinWire = AnakinWireService();
  
  bool _isLoading = false;
  String? _errorMessage;
  AnalysisMode _selectedMode = AnalysisMode.beginner;
  final List<String> _urlHistory = [];
  
  bool _showScanner = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _batchController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _analyzeUrl({String? customUrl}) async {
    final url = customUrl ?? _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _anakinWire.scrapeUrl(url, withScreenshot: true);
      if (!result.hasError) {
        final explanation = await _anakinWire.generateExplanation(result, _selectedMode);
        if (mounted) {
          _urlHistory.add(url);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ResultsScreen(
                result: result,
                explanation: explanation,
                mode: _selectedMode,
                themeMode: widget.themeMode,
                onToggleTheme: widget.onToggleTheme,
                language: widget.language,
                onChangeLanguage: widget.onChangeLanguage,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: 400.ms,
            ),
          );
        }
      } else {
        setState(() => _errorMessage = result.error);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeBatch() async {
    final urls = _batchController.text
        .split('\n')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();

    if (urls.isEmpty) {
      setState(() => _errorMessage = 'Please enter at least one URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _anakinWire.scrapeBatch(urls);
      final explanation = await _anakinWire.generateExplanation(result, _selectedMode);
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ResultsScreen(
              result: result,
              explanation: explanation,
              mode: _selectedMode,
              isBatch: true,
              batchUrls: urls,
              themeMode: widget.themeMode,
              onToggleTheme: widget.onToggleTheme,
              language: widget.language,
              onChangeLanguage: widget.onChangeLanguage,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: 400.ms,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _crawlAndAnalyze() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please enter a URL to crawl');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final discoveredUrls = await _anakinWire.crawlUrl(url, limit: 5);
      if (discoveredUrls.isNotEmpty) {
        final result = await _anakinWire.scrapeBatch([url, ...discoveredUrls.take(4)]);
        final explanation = await _anakinWire.generateExplanation(result, _selectedMode);
        if (mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ResultsScreen(
                result: result,
                explanation: explanation,
                mode: _selectedMode,
                isCrawl: true,
                discoveredUrls: discoveredUrls,
                themeMode: widget.themeMode,
                onToggleTheme: widget.onToggleTheme,
                language: widget.language,
                onChangeLanguage: widget.onChangeLanguage,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: 400.ms,
            ),
          );
        }
      } else {
        setState(() => _errorMessage = 'No URLs discovered from this page');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      String value = barcode!.rawValue!;
      if (!value.startsWith('http')) {
        value = 'https://$value';
      }
      setState(() {
        _urlController.text = value;
        _showScanner = false;
      });
      _scannerController?.dispose();
      _scannerController = MobileScannerController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'ANAKIN',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: 300.ms,
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
              ),
            ),
            onPressed: widget.onToggleTheme,
          ).animate().scale(delay: 200.ms),
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
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              labelPadding: EdgeInsets.zero,
              tabs: const [
                Tab(child: Icon(Icons.link_rounded, size: 20)),
                Tab(child: Icon(Icons.qr_code_scanner_rounded, size: 20)),
                Tab(child: Icon(Icons.layers_rounded, size: 20)),
                Tab(child: Icon(Icons.explore_rounded, size: 20)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildModeSelector().animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                    ),
                  ],
                ),
              ).animate().shake(duration: 500.ms).fadeIn(),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUrlTab(),
                _buildScannerTab(),
                _buildBatchTab(),
                _buildCrawlTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: AnalysisMode.values.map((mode) {
          final isSelected = _selectedMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMode = mode),
              child: AnimatedContainer(
                duration: 300.ms,
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ] : null,
                ),
                child: Column(
                  children: [
                    Text(mode.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(
                      mode.displayName.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onPrimary 
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUrlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'INVESTIGATE\nTHE WEB',
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
          ).animate().fadeIn().slideX(begin: -0.1, duration: 600.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),
          Text(
            'Uncover deep insights from any URL using the Anakin Oracle protocol.',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 40),
          TextField(
            controller: _urlController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'https://example.com',
              prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _urlController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _analyzeUrl(),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('INITIATE ANALYSIS'),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
          if (_urlHistory.isNotEmpty) ...[
            const SizedBox(height: 48),
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 18),
                const SizedBox(width: 10),
                Text(
                  'RECENT ARCHIVES',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 16),
            ..._urlHistory.take(5).toList().reversed.map((url) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                title: Text(
                  url, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.north_east_rounded, size: 16),
                onTap: () {
                  _urlController.text = url;
                  setState(() {});
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                dense: true,
              ),
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.05)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    if (_showScanner) {
      return Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => setState(() => _showScanner = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, 
                  foregroundColor: Colors.black,
                  elevation: 10,
                ),
                child: const Text('ABORT SCAN'),
              ),
            ),
          ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutBack),
        ],
      ).animate().fadeIn();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white24).scale(duration: 800.ms, curve: Curves.elasticOut),
            const SizedBox(height: 40),
            Text(
              'OPTICAL CAPTURE',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            Text(
              'Align the oracle lens with a digital cipher (QR code) to begin instant synchronization.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showScanner = true),
                icon: const Icon(Icons.camera_rounded),
                label: const Text('ACTIVATE LENS'),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'BATCH\nPROCESSING',
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 12),
          Text(
            'Deploy multiple analysis drones simultaneously to aggregate data from several sources.',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 40),
          TextField(
            controller: _batchController,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'https://source-alpha.com\nhttps://source-beta.org\nhttps://source-gamma.net',
              alignLabelWithHint: true,
            ),
            maxLines: 8,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _analyzeBatch,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('DEPLOY DRONES'),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildCrawlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'EXPLORATION\nCRAWL',
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 12),
          Text(
            'Initiate a recursive discovery protocol to find and analyze interconnected nodes.',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 40),
          TextField(
            controller: _urlController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Starting Node URL',
              prefixIcon: Icon(Icons.explore_rounded, color: Theme.of(context).colorScheme.primary),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _crawlAndAnalyze,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('INITIATE CRAWL'),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'PROTOCOL SPECS', 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoStep('01', 'ESTABLISH STARTING POINT'),
                _buildInfoStep('02', 'DISCOVER RELATED SUB-NODES'),
                _buildInfoStep('03', 'AGGREGATE MULTI-SOURCE DATA'),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            num, 
            style: GoogleFonts.outfit(
              fontSize: 14, 
              fontWeight: FontWeight.w900, 
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text, 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

  }
}