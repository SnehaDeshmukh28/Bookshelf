import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/book.dart';
import '../models/highlight.dart';
import '../models/bookmark.dart';
import '../providers/library_provider.dart';
import '../services/insights_service.dart';
import '../theme/app_theme.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with TickerProviderStateMixin {
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfKey = GlobalKey();

  late Book _book;
  ReadingMode _readingMode = ReadingMode.dark;
  bool _toolbarVisible = true;
  bool _isLoaded = false;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isBookmarked = false;

  bool _showHighlights = false;
  bool _showBookmarks = false;
  bool _showInsights = false;

  List<Highlight> _highlights = [];
  List<Bookmark> _bookmarks = [];
  String _selectedText = '';

  late AnimationController _toolbarAnim;
  final TextEditingController _pageCtrl = TextEditingController();
  // Debounce DB writes so rapid page swipes don't stall the UI
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _currentPage = _book.currentPage.clamp(1, _book.totalPages.clamp(1, 999999));
    _toolbarAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _toolbarAnim.value = 1.0;
    _loadData();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _toolbarAnim.dispose();
    _pdfController.dispose();
    _pageCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadData() async {
    final p = context.read<LibraryProvider>();
    _highlights = await p.getHighlights(_book.id);
    _bookmarks = await p.getBookmarks(_book.id);
    if (mounted) setState(() {});
  }

  int _bookmarkCheckPage = -1;
  Future<void> _checkBookmark() async {
    final page = _currentPage;
    if (page == _bookmarkCheckPage) return;
    _bookmarkCheckPage = page;
    final v = await context
        .read<LibraryProvider>()
        .isPageBookmarked(_book.id, page);
    if (mounted && _currentPage == page) setState(() => _isBookmarked = v);
  }

  void _toggleToolbar() {
    if (_toolbarVisible) {
      _toolbarAnim.reverse();
      setState(() => _toolbarVisible = false);
    } else {
      _toolbarAnim.forward();
      setState(() {
        _toolbarVisible = true;
        _showHighlights = false;
        _showBookmarks = false;
      });
    }
  }

  void _toggleInsights() {
    HapticFeedback.selectionClick();
    setState(() {
      _showInsights = !_showInsights;
      if (_showInsights) {
        _showHighlights = false;
        _showBookmarks = false;
      }
    });
  }

  // ── Highlight ─────────────────────────────────────────────────────────────

  void _showColorPicker() {
    if (_selectedText.isNotEmpty) {
      // Text was selected via long-press — go straight to color picker
      _openColorPicker(_selectedText);
    } else {
      // No selection — show text input so user can type the quote manually
      _showManualHighlightDialog();
    }
  }

  void _showManualHighlightDialog() {
    HapticFeedback.mediumImpact();
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.border_color,
                    color: AppColors.violetLight, size: 18),
                const SizedBox(width: 8),
                const Text('Add Highlight — Page ',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Text('$_currentPage',
                    style: const TextStyle(
                        color: AppColors.violet,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              const Text(
                'Type or paste the text you want to save as a highlight',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 4,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'e.g. "The only way to do great work is to love what you do."',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.violet, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              // Color row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: Highlight.highlightColors.entries.map((e) {
                  return GestureDetector(
                    onTap: () async {
                      final text = ctrl.text.trim();
                      if (text.isEmpty) {
                        _showSnack('Please enter some text first',
                            AppColors.textMuted);
                        return;
                      }
                      Navigator.pop(context);
                      _selectedText = text;
                      await _saveHighlight(e.value);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(e.value),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(e.value).withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(e.key,
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openColorPicker(String text) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Highlight',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '"${text.length > 80 ? '${text.substring(0, 80)}…' : text}"',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: Highlight.highlightColors.entries.map((e) {
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _saveHighlight(e.value);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Color(e.value),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(e.value).withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(e.key,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHighlight(int colorValue) async {
    final p = context.read<LibraryProvider>();
    final h = await p.addHighlight(
      bookId: _book.id,
      pageNumber: _currentPage,
      text: _selectedText,
      colorValue: colorValue,
    );
    setState(() {
      _highlights.add(h);
      _selectedText = '';
    });
    HapticFeedback.lightImpact();
    _showSnack('Highlight saved', Color(colorValue));
  }

  // ── Bookmark ──────────────────────────────────────────────────────────────

  Future<void> _toggleBookmark() async {
    HapticFeedback.mediumImpact();
    final p = context.read<LibraryProvider>();
    if (_isBookmarked) {
      final bm = _bookmarks.firstWhere((b) => b.pageNumber == _currentPage,
          orElse: () => _bookmarks.first);
      await p.deleteBookmark(bm.id);
      setState(() {
        _bookmarks.removeWhere((b) => b.id == bm.id);
        _isBookmarked = false;
      });
      _showSnack('Bookmark removed', AppColors.textMuted);
    } else {
      final bm = await p.addBookmark(
        bookId: _book.id,
        pageNumber: _currentPage,
        label: 'Page $_currentPage',
      );
      setState(() {
        _bookmarks.add(bm);
        _isBookmarked = true;
      });
      _showSnack('Bookmarked page $_currentPage', AppColors.gold);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.card,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5), width: 1),
        ),
      ),
    );
  }

  void _goToPageDialog() {
    _pageCtrl.text = _currentPage.toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Go to Page',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: _pageCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: '1 – $_totalPages',
            labelStyle:
                const TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: AppColors.violet, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final p = int.tryParse(_pageCtrl.text);
              if (p != null && p >= 1 && p <= _totalPages) {
                _pdfController.jumpToPage(p);
              }
              Navigator.pop(context);
            },
            child: const Text('Go',
                style: TextStyle(color: AppColors.violet)),
          ),
        ],
      ),
    );
  }

  void _showReadingMode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reading Mode',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ReadingMode.values.map((mode) {
                final isSelected = mode == _readingMode;
                final label = mode.name[0].toUpperCase() +
                    mode.name.substring(1);
                final bg = AppTheme.readerBg(mode);
                final textColor = AppTheme.readerText(mode);
                return GestureDetector(
                  onTap: () {
                    setState(() => _readingMode = mode);
                    Navigator.pop(context);
                    HapticFeedback.selectionClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.violet
                            : Colors.grey.shade700,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.violet.withOpacity(0.4),
                                blurRadius: 16,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.circle,
                            size: 10,
                            color: isSelected
                                ? AppColors.violet
                                : Colors.transparent),
                        const SizedBox(height: 6),
                        Text(label,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toolbarColor = AppTheme.readerToolbar(_readingMode);
    final bgColor = AppTheme.readerBg(_readingMode);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── PDF Viewer (no GestureDetector wrapper — lets SF handle all gestures) ──
          Positioned.fill(
            child: RepaintBoundary(
              child: SfPdfViewer.file(
                File(_book.filePath),
                key: _pdfKey,
                controller: _pdfController,
                pageLayoutMode: PdfPageLayoutMode.single,
                scrollDirection: PdfScrollDirection.horizontal,
                enableTextSelection: true,
                enableDoubleTapZooming: false,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                canShowPaginationDialog: false,
                enableHyperlinkNavigation: false,
                pageSpacing: 0,
                initialPageNumber: _currentPage,
                onDocumentLoaded: (d) {
                  setState(() {
                    _isLoaded = true;
                    _totalPages = d.document.pages.count;
                    _currentPage = _book.currentPage.clamp(1, _totalPages);
                  });
                  _checkBookmark();
                  context.read<LibraryProvider>().updateReadingProgress(
                      _book.id, _currentPage, _totalPages);
                },
                onDocumentLoadFailed: (d) {
                  _showSnack('Could not open PDF: ${d.description}',
                      AppColors.coral);
                },
                onPageChanged: (d) {
                  setState(() {
                    _currentPage = d.newPageNumber;
                    _selectedText = '';
                  });
                  _checkBookmark();
                  final now = DateTime.now();
                  if (now.difference(_lastProgressSave).inMilliseconds > 500) {
                    _lastProgressSave = now;
                    context.read<LibraryProvider>().updateReadingProgress(
                        _book.id, d.newPageNumber, _totalPages);
                  }
                },
                onTextSelectionChanged: (d) {
                  if (d.selectedText != null && d.selectedText!.isNotEmpty) {
                    // Keep the selection and auto-show toolbar so Highlight button is visible
                    _selectedText = d.selectedText!;
                    if (!_toolbarVisible) _toggleToolbar();
                  }
                  // Do NOT clear _selectedText here — tapping the toolbar deselects the PDF
                  // but we need the text to still be available when Highlight is tapped.
                },
              ),
            ),
          ),

          // ── Toolbar toggle button (shown when toolbar is hidden) ──────────
          if (!_toolbarVisible)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 14,
              child: GestureDetector(
                onTap: _toggleToolbar,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_rounded,
                      color: Colors.white70, size: 20),
                ),
              ),
            ),

          // ── Top bar (glass) ───────────────────────────────────────────────
          AnimatedBuilder(
            animation: _toolbarAnim,
            builder: (_, __) {
              if (_toolbarAnim.value == 0) return const SizedBox.shrink();
              return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(0, -80 * (1 - _toolbarAnim.value)),
                child: Opacity(
                  opacity: _toolbarAnim.value,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        color: toolbarColor.withOpacity(0.88),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new,
                                      color: Colors.white, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: Text(
                                    _book.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.search,
                                      color: Colors.white, size: 20),
                                  onPressed: () => showSearch(
                                    context: context,
                                    delegate: _PdfSearch(_pdfController),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.toc,
                                      color: Colors.white, size: 20),
                                  onPressed: () =>
                                      _pdfKey.currentState?.openBookmarkView(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          ),

          // ── Bottom bar (glass) ────────────────────────────────────────────
          AnimatedBuilder(
            animation: _toolbarAnim,
            builder: (_, __) {
              if (_toolbarAnim.value == 0) return const SizedBox.shrink();
              return Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: Transform.translate(
                offset: Offset(0, 120 * (1 - _toolbarAnim.value)),
                child: Opacity(
                  opacity: _toolbarAnim.value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: toolbarColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SafeArea(
                          top: false,
                          bottom: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress slider
                              if (_isLoaded && _totalPages > 1)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 0),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _goToPageDialog,
                                        child: Text(
                                          '$_currentPage',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderThemeData(
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                    enabledThumbRadius: 7),
                                            trackHeight: 2,
                                            activeTrackColor: AppColors.violet,
                                            inactiveTrackColor:
                                                Colors.white12,
                                            thumbColor: AppColors.violetLight,
                                            overlayShape:
                                                SliderComponentShape
                                                    .noOverlay,
                                          ),
                                          child: Slider(
                                            value: _currentPage.toDouble(),
                                            min: 1,
                                            max: _totalPages.toDouble(),
                                            onChanged: (v) {
                                              setState(() =>
                                                  _currentPage = v.toInt());
                                            },
                                            onChangeEnd: (v) =>
                                                _pdfController
                                                    .jumpToPage(v.toInt()),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _goToPageDialog,
                                        child: Text(
                                          '$_totalPages',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Action buttons
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    4, 4, 4, 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _Btn(
                                      icon: _isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      label: 'Bookmark',
                                      color: _isBookmarked
                                          ? AppColors.gold
                                          : Colors.white,
                                      onTap: _toggleBookmark,
                                    ),
                                    _Btn(
                                      icon: Icons.border_color,
                                      label: 'Highlight',
                                      color: _selectedText.isNotEmpty
                                          ? AppColors.highlightYellow
                                          : Colors.white,
                                      onTap: _showColorPicker,
                                    ),
                                    _Btn(
                                      icon: Icons.format_list_bulleted,
                                      label: 'Highlights',
                                      color: _showHighlights
                                          ? AppColors.violet
                                          : Colors.white,
                                      onTap: () => setState(() {
                                        _showHighlights = !_showHighlights;
                                        _showBookmarks = false;
                                      }),
                                    ),
                                    _Btn(
                                      icon: Icons.bookmarks_outlined,
                                      label: 'Bookmarks',
                                      color: _showBookmarks
                                          ? AppColors.violet
                                          : Colors.white,
                                      onTap: () => setState(() {
                                        _showBookmarks = !_showBookmarks;
                                        _showHighlights = false;
                                      }),
                                    ),
                                    _Btn(
                                      icon: Icons.brightness_medium_outlined,
                                      label: 'Theme',
                                      color: Colors.white,
                                      onTap: _showReadingMode,
                                    ),
                                    _Btn(
                                      icon: Icons.last_page,
                                      label: 'Jump',
                                      color: Colors.white,
                                      onTap: _goToPageDialog,
                                    ),
                                    _Btn(
                                      icon: Icons.insights_outlined,
                                      label: 'Insights',
                                      color: _showInsights
                                          ? AppColors.gold
                                          : Colors.white,
                                      onTap: _toggleInsights,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            },
          ),

          // ── Panels ────────────────────────────────────────────────────────
          if (_showHighlights)
            _Panel(
              title: 'Highlights',
              count: _highlights.length,
              onClose: () => setState(() => _showHighlights = false),
              child: _highlights.isEmpty
                  ? _emptyPanel('No highlights yet', Icons.border_color)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _highlights.length,
                      itemBuilder: (_, i) {
                        final h = _highlights[i];
                        return Dismissible(
                          key: Key(h.id),
                          direction: DismissDirection.endToStart,
                          background: _dismissBg(),
                          onDismissed: (_) async {
                            await context
                                .read<LibraryProvider>()
                                .deleteHighlight(h.id);
                            setState(() => _highlights
                                .removeWhere((x) => x.id == h.id));
                          },
                          child: GestureDetector(
                            onTap: () {
                              _pdfController.jumpToPage(h.pageNumber);
                              setState(() => _showHighlights = false);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: h.color.withOpacity(0.12),
                                border: Border(
                                    left: BorderSide(
                                        color: h.color, width: 4)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(h.text,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          height: 1.5)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Icon(Icons.bookmark_border,
                                        size: 12,
                                        color: h.color),
                                    const SizedBox(width: 4),
                                    Text('Page ${h.pageNumber}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: h.color
                                                .withOpacity(0.8))),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

          if (_showBookmarks)
            _Panel(
              title: 'Bookmarks',
              count: _bookmarks.length,
              onClose: () => setState(() => _showBookmarks = false),
              child: _bookmarks.isEmpty
                  ? _emptyPanel('No bookmarks yet', Icons.bookmark_border)
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _bookmarks.length,
                      itemBuilder: (_, i) {
                        final b = _bookmarks[i];
                        return Dismissible(
                          key: Key(b.id),
                          direction: DismissDirection.endToStart,
                          background: _dismissBg(),
                          onDismissed: (_) async {
                            await context
                                .read<LibraryProvider>()
                                .deleteBookmark(b.id);
                            setState(() => _bookmarks
                                .removeWhere((x) => x.id == b.id));
                            if (_currentPage == b.pageNumber) {
                              setState(() => _isBookmarked = false);
                            }
                          },
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bookmark,
                                  color: AppColors.gold, size: 18),
                            ),
                            title: Text(b.label,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14)),
                            subtitle: Text('Page ${b.pageNumber}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                            onTap: () {
                              _pdfController.jumpToPage(b.pageNumber);
                              setState(() => _showBookmarks = false);
                            },
                          ),
                        );
                      },
                    ),
            ),
          if (_showInsights)
            _InsightsPanel(
              book: _book,
              currentPage: _currentPage,
              onClose: () => setState(() => _showInsights = false),
            ),
        ],
      ),
    );
  }

  Widget _emptyPanel(String msg, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      );

  Widget _dismissBg() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.coral.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.coral, size: 22),
      );
}

// ── Toolbar button ────────────────────────────────────────────────────────────

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Btn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.85), fontSize: 9.5)),
          ],
        ),
      ),
    );
  }
}

// ── Glass bottom sheet ────────────────────────────────────────────────────────

class _GlassSheet extends StatelessWidget {
  final Widget child;
  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            border: const Border(
                top: BorderSide(color: AppColors.cardBorder, width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: child,
        ),
      ),
    );
  }
}

// ── Sliding panel ─────────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onClose;
  final Widget child;

  const _Panel(
      {required this.title,
      required this.count,
      required this.onClose,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.95),
              border: const Border(
                  top:
                      BorderSide(color: AppColors.cardBorder, width: 1)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      Text(
                        '$title  ',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: const TextStyle(
                                color: AppColors.violetLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(
        begin: 1, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

// ── Page Insights Panel ───────────────────────────────────────────────────────

class _InsightsPanel extends StatefulWidget {
  final Book book;
  final int currentPage;
  final VoidCallback onClose;
  const _InsightsPanel(
      {required this.book, required this.currentPage, required this.onClose});
  @override
  State<_InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends State<_InsightsPanel>
    with SingleTickerProviderStateMixin {
  final _svc = InsightsService.instance;
  final _searchCtrl = TextEditingController();
  late TabController _tabs;

  PageInsights? _insights;
  List<String> _searchResults = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final text =
        await _svc.extractPageText(widget.book.filePath, widget.currentPage);
    final insights = _svc.analyze(text);
    if (mounted) setState(() { _insights = insights; _loading = false; });
  }

  void _search(String query) {
    if (_insights == null || query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() =>
        _searchResults = _svc.findRelevant(_insights!.text, query.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.97),
              border: const Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 28,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.gold, strokeWidth: 2),
                    ),
                  )
                else if (!_insights!.hasText)
                  Expanded(child: _noTextState())
                else ...[
                  if (_insights != null) _buildStatsRow(_insights!),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildTabBar(),
                  Expanded(child: _buildTabViews()),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          const Text('Page Insights',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('p. ${widget.currentPage}',
                style: const TextStyle(
                    color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(PageInsights ins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _StatChip(label: '${ins.wordCount} words', icon: Icons.text_fields_rounded),
          const SizedBox(width: 8),
          _StatChip(label: ins.readingTime, icon: Icons.schedule_rounded),
          const SizedBox(width: 8),
          _StatChip(
            label: ins.difficulty,
            icon: Icons.bar_chart_rounded,
            emoji: ins.difficultyEmoji,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabs,
      indicatorColor: AppColors.gold,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: AppColors.gold,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Summary'),
        Tab(text: 'Key Points'),
        Tab(text: 'Find'),
      ],
    );
  }

  Widget _buildTabViews() {
    final ins = _insights!;
    return TabBarView(
      controller: _tabs,
      children: [
        // ── Summary ──
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ins.summary.isEmpty
              ? _emptyTab('No summary available for this page.')
              : Text(ins.summary,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14, height: 1.7)),
        ),

        // ── Key Points ──
        ins.keyPoints.isEmpty
            ? _emptyTab('No key points found for this page.')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: ins.keyPoints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: AppColors.gold, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(ins.keyPoints[i],
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              height: 1.55)),
                    ),
                  ],
                ),
              ),

        // ── Find ──
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: false,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'What are you looking for?',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textMuted, size: 18),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.gold, width: 1.5),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: _search,
                      onSubmitted: _search,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchCtrl.text.isEmpty
                            ? 'Type above to find relevant\npassages on this page'
                            : 'No relevant content found\nfor "${_searchCtrl.text}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.2), width: 1),
                        ),
                        child: Text(_searchResults[i],
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                height: 1.6)),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _noTextState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined,
                  size: 48, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'No text found on this page',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'This page appears to be a scanned image.\nInsights work on PDFs with embedded text.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );

  Widget _emptyTab(String msg) => Center(
        child: Text(msg,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? emoji;
  const _StatChip({required this.label, required this.icon, this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
          ] else ...[
            Icon(icon, size: 12, color: AppColors.gold),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── PDF Search ────────────────────────────────────────────────────────────────

class _PdfSearch extends SearchDelegate<String> {
  final PdfViewerController ctrl;
  _PdfSearch(this.ctrl);

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.surface),
        inputDecorationTheme: const InputDecorationTheme(
            hintStyle: TextStyle(color: AppColors.textMuted)),
      );

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textSecondary),
            onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
      onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (query.isNotEmpty) ctrl.searchText(query);
    });
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Searching "$query"…',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.violetLight,
                      side: const BorderSide(color: AppColors.cardBorder)),
                  onPressed: () => ctrl.searchText(query),
                  icon: const Icon(Icons.navigate_before, size: 18),
                  label: const Text('Prev'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.violetLight,
                      side: const BorderSide(color: AppColors.cardBorder)),
                  onPressed: () => ctrl.searchText(query),
                  icon: const Icon(Icons.navigate_next, size: 18),
                  label: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => Container(
      color: AppColors.bg,
      child: const Center(
          child: Text('Type to search in this book',
              style: TextStyle(color: AppColors.textMuted))));
}
