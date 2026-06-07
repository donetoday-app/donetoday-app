import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/ui/widgets/unified_header.dart';
import 'package:done_today/ui/widgets/done_today_markdown.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// BOOK APPEARANCE THEMES
// ============================================================================

class BookTheme {
  final String id;
  final String name;
  final String description;
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color lineColor;
  final Color marginColor;
  final Color spineColor;
  final String fontFamily;
  final bool isDark;
  final double textureOpacity;

  const BookTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.lineColor,
    required this.marginColor,
    required this.spineColor,
    required this.fontFamily,
    required this.isDark,
    this.textureOpacity = 0.03,
  });
}

final bookThemes = {
  'warm': BookTheme(
    id: 'warm',
    name: 'Warm Ivory',
    description: 'Classic organic book feel',
    backgroundColor: const Color(0xFFFDFBF7),
    textColor: const Color(0xFF332B25),
    secondaryTextColor: const Color(0xFF7A6B61),
    lineColor: Colors.black.withOpacity(0.11),
    marginColor: const Color(0xFFE29A8A),
    spineColor: Colors.black.withOpacity(0.06),
    fontFamily: 'Merriweather',
    isDark: false,
  ),
  'white': BookTheme(
    id: 'white',
    name: 'Notebook White',
    description: 'Familiar clean paper style',
    backgroundColor: Colors.white,
    textColor: const Color(0xFF1A1A1A),
    secondaryTextColor: const Color(0xFF666666),
    lineColor: Colors.black.withOpacity(0.12),
    marginColor: const Color(0xFFE29A8A),
    spineColor: Colors.black.withOpacity(0.05),
    fontFamily: 'Outfit',
    isDark: false,
  ),
  'black': BookTheme(
    id: 'black',
    name: 'Obsidian Black',
    description: 'High contrast AMOLED reading',
    backgroundColor: const Color(0xFF000000),
    textColor: const Color(0xFFE2E2E2),
    secondaryTextColor: Colors.white.withOpacity(0.55),
    lineColor: Colors.white.withOpacity(0.16),
    marginColor: Colors.redAccent.withOpacity(0.25),
    spineColor: Colors.black.withOpacity(0.45),
    fontFamily: 'Outfit',
    isDark: true,
  ),
  'leather': BookTheme(
    id: 'leather',
    name: 'Leather Bound',
    description: 'Premium embossed leather aesthetic',
    backgroundColor: const Color(0xFF3E2C1F),
    textColor: const Color(0xFFF5E6D3),
    secondaryTextColor: const Color(0xFFD4C4B0),
    lineColor: const Color(0xFFC9B89C).withOpacity(0.25),
    marginColor: const Color(0xFFB8860B),
    spineColor: Colors.black.withOpacity(0.3),
    fontFamily: 'Merriweather',
    isDark: true,
    textureOpacity: 0.08,
  ),
  'vintage': BookTheme(
    id: 'vintage',
    name: 'Vintage Journal',
    description: 'Old book with aged paper aesthetic',
    backgroundColor: const Color(0xFFF4E8D8),
    textColor: const Color(0xFF4A3C2A),
    secondaryTextColor: const Color(0xFF8B7355),
    lineColor: const Color(0xFF9B8B7B).withOpacity(0.15),
    marginColor: const Color(0xFFC66432),
    spineColor: Colors.black.withOpacity(0.08),
    fontFamily: 'Merriweather',
    isDark: false,
  ),
  'navy': BookTheme(
    id: 'navy',
    name: 'Navy Professional',
    description: 'Professional corporate aesthetic',
    backgroundColor: const Color(0xFF1A2A3A),
    textColor: const Color(0xFFE8EEF5),
    secondaryTextColor: const Color(0xFFB0B8C8),
    lineColor: const Color(0xFF4A6A8A).withOpacity(0.3),
    marginColor: const Color(0xFF24A0ED),
    spineColor: Colors.black.withOpacity(0.25),
    fontFamily: 'Outfit',
    isDark: true,
  ),
  'sepia': BookTheme(
    id: 'sepia',
    name: 'Sepia Tone',
    description: 'Timeless sepia journal pages',
    backgroundColor: const Color(0xFFE8D7C3),
    textColor: const Color(0xFF5C4B3A),
    secondaryTextColor: const Color(0xFF8B7355),
    lineColor: const Color(0xFF9B8B7B).withOpacity(0.12),
    marginColor: const Color(0xFFA0826D),
    spineColor: Colors.black.withOpacity(0.06),
    fontFamily: 'Merriweather',
    isDark: false,
  ),
};

// ============================================================================
// BOOK LAYOUT SETTINGS (Adjustable)
// ============================================================================

class BookLayoutSettings {
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final double horizontalPadding;
  final double verticalPadding;
  final int transitionDurationMs;

  const BookLayoutSettings({
    this.fontSize = 15.0,
    this.lineHeight = 2.0,
    this.letterSpacing = 0.0,
    this.horizontalPadding = 56.0,
    this.verticalPadding = 24.0,
    this.transitionDurationMs = 400,
  });

  BookLayoutSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    double? horizontalPadding,
    double? verticalPadding,
    int? transitionDurationMs,
  }) {
    return BookLayoutSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      transitionDurationMs: transitionDurationMs ?? this.transitionDurationMs,
    );
  }

  static BookLayoutSettings loadFromStorage() {
    final fontSize =
        HiveService.get<double>('settings', 'book_fontSize') ?? 15.0;
    final lineHeight =
        HiveService.get<double>('settings', 'book_lineHeight') ?? 2.0;
    final letterSpacing =
        HiveService.get<double>('settings', 'book_letterSpacing') ?? 0.0;
    final horizontalPadding =
        HiveService.get<double>('settings', 'book_horizontalPadding') ?? 56.0;
    final verticalPadding =
        HiveService.get<double>('settings', 'book_verticalPadding') ?? 24.0;
    final transitionDurationMs =
        HiveService.get<int>('settings', 'book_transitionDurationMs') ?? 400;

    return BookLayoutSettings(
      fontSize: fontSize,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      transitionDurationMs: transitionDurationMs,
    );
  }

  Future<void> saveToStorage() async {
    await HiveService.put<double>('settings', 'book_fontSize', fontSize);
    await HiveService.put<double>('settings', 'book_lineHeight', lineHeight);
    await HiveService.put<double>(
      'settings',
      'book_letterSpacing',
      letterSpacing,
    );
    await HiveService.put<double>(
      'settings',
      'book_horizontalPadding',
      horizontalPadding,
    );
    await HiveService.put<double>(
      'settings',
      'book_verticalPadding',
      verticalPadding,
    );
    await HiveService.put<int>(
      'settings',
      'book_transitionDurationMs',
      transitionDurationMs,
    );
  }
}

// ============================================================================
// ENHANCED RULED BOOK PAINTER
// ============================================================================

class EnhancedRuledBookSpreadPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final bool isTwoPage;
  final Color backgroundColor;
  final double textureOpacity;

  EnhancedRuledBookSpreadPainter({
    required this.lineColor,
    required this.marginColor,
    required this.isTwoPage,
    required this.backgroundColor,
    this.textureOpacity = 0.03,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle texture overlay
    _drawTextureOverlay(canvas, size);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    const double lineSpacing = 30.0;

    if (isTwoPage) {
      final double midX = size.width / 2;
      double currentY = 160.0;

      // Draw horizontal lines across both pages
      while (currentY < size.height - 60) {
        // Left page lines
        canvas.drawLine(
          Offset(54, currentY),
          Offset(midX - 32, currentY),
          linePaint,
        );
        // Right page lines
        canvas.drawLine(
          Offset(midX + 54, currentY),
          Offset(size.width - 32, currentY),
          linePaint,
        );
        currentY += lineSpacing;
      }

      final marginPaint = Paint()
        ..color = marginColor
        ..strokeWidth = 1.2;

      // Draw margins for left page
      canvas.drawLine(
        const Offset(46, 0),
        Offset(46, size.height),
        marginPaint,
      );

      // Draw margins for right page
      canvas.drawLine(
        Offset(midX + 46, 0),
        Offset(midX + 46, size.height),
        marginPaint,
      );
    } else {
      // Single page standard painting
      double currentY = 160.0;
      while (currentY < size.height - 60) {
        canvas.drawLine(
          Offset(46, currentY),
          Offset(size.width - 24, currentY),
          linePaint,
        );
        currentY += lineSpacing;
      }

      final marginPaint = Paint()
        ..color = marginColor
        ..strokeWidth = 1.2;
      canvas.drawLine(
        const Offset(40, 0),
        Offset(40, size.height),
        marginPaint,
      );
    }
  }

  void _drawTextureOverlay(Canvas canvas, Size size) {
    if (textureOpacity <= 0) return;
    final texturePaint = Paint()
      ..color = Colors.black.withOpacity(textureOpacity);

    // Create subtle noise texture
    for (int i = 0; i < 50; i++) {
      final random = (i * 73) % 100 / 100;
      canvas.drawCircle(
        Offset(size.width * random, size.height * (i / 50)),
        0.5,
        texturePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// BOOK READER SCREEN
// ============================================================================

class BookReaderScreen extends ConsumerStatefulWidget {
  const BookReaderScreen({super.key});

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  late final PageController _pageController;
  int _currentPageIndex = 0;
  String? _selectedTheme;
  late BookLayoutSettings _layoutSettings;

  String get _currentTheme {
    if (_selectedTheme == 'app_theme' || _selectedTheme == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? 'black' : 'white';
    }
    return _selectedTheme!;
  }

  BookTheme get _currentThemeData =>
      bookThemes[_currentTheme] ?? bookThemes['warm']!;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Load setting with fallback from older settings
    final savedTheme = HiveService.get<String>('settings', 'book_reader_theme');
    if (savedTheme != null) {
      _selectedTheme = savedTheme;
    } else {
      final savedAppearance = HiveService.get<String>(
        'settings',
        'book_reader_appearance',
      );
      _selectedTheme = savedAppearance ?? 'app_theme';
    }

    _layoutSettings = BookLayoutSettings.loadFromStorage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleMouseScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final logsState = ref.read(logsNotifierProvider);
      if (logsState is! LogsLoaded) return;
      final logsCount = logsState.logs.length;
      final isDesktop = ResponsiveHelper.isDesktop(context);
      final totalPagesCount = isDesktop ? (logsCount / 2).ceil() : logsCount;

      // Scroll down = next page
      if (event.scrollDelta.dy > 0) {
        if (_currentPageIndex < totalPagesCount - 1) {
          _pageController.nextPage(
            duration: Duration(
              milliseconds: _layoutSettings.transitionDurationMs,
            ),
            curve: Curves.easeInOutCubic,
          );
        }
      }
      // Scroll up = previous page
      else if (event.scrollDelta.dy < 0) {
        if (_currentPageIndex > 0) {
          _pageController.previousPage(
            duration: Duration(
              milliseconds: _layoutSettings.transitionDurationMs,
            ),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bookTheme = _currentThemeData;

    final scaffoldBgColor = isDark
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFF1EFE9);

    final logsState = ref.watch(logsNotifierProvider);

    if (logsState is! LogsLoaded) {
      return Scaffold(
        backgroundColor: bookTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final logs = List<Log>.from(logsState.logs)
      ..sort((a, b) => b.date.compareTo(a.date)); // Recent first

    if (logs.isEmpty) {
      return _buildEmptyBookScreen(theme, bookTheme);
    }

    // 2. Responsive Calculations for Desktop 2-Page Spread
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final totalPagesCount = isDesktop ? (logs.length / 2).ceil() : logs.length;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: ResponsiveConstraints(
          maxWidth: isDesktop
              ? ResponsiveHelper.maxFullWidth
              : ResponsiveHelper.maxContentWidth,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              // Standardized UnifiedHeader with themes, typography setting & bottom border
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: bookTheme.marginColor.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                ),
                child: UnifiedHeader(
                  title: "LOG BOOK",
                  onBack: () => Navigator.of(context).pop(),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      onPressed: () => _showSettingsSheet(context),
                      tooltip: "Appearance & Layout",
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.palette_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      onPressed: () => _showThemeMenu(context),
                      tooltip: "Change ThemePreset",
                    ),
                  ],
                ),
              ),

              // Page View container with Mouse Scroll Support
              Expanded(
                child: Center(
                  child: Listener(
                    onPointerSignal: _handleMouseScroll,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop
                            ? ResponsiveHelper.maxFullWidth - 80
                            : double.infinity,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 40 : 0,
                        vertical: isDesktop ? 24 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: bookTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(isDesktop ? 24 : 0),
                        boxShadow: isDesktop
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.4 : 0.12,
                                  ),
                                  blurRadius: 32,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                        border: isDesktop
                            ? Border.all(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.08,
                                ),
                                width: 1,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isDesktop ? 24 : 0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double midX = constraints.maxWidth / 2;

                            return Stack(
                              children: [
                                // Binder Crease/Fold Overlays
                                if (isDesktop) ...[
                                  // Middle Spine Shadow representing real bound spine fold
                                  Positioned(
                                    left: midX - 28,
                                    top: 0,
                                    bottom: 0,
                                    width: 56,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            bookTheme.spineColor.withOpacity(
                                              0.0,
                                            ),
                                            bookTheme.spineColor,
                                            bookTheme.spineColor.withOpacity(
                                              0.0,
                                            ),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Left Edge Crease for single-page bound simulation
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            bookTheme.spineColor,
                                            bookTheme.spineColor.withOpacity(
                                              0.0,
                                            ),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // Book Pages Content Builder
                                PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPageIndex = index;
                                    });
                                  },
                                  itemCount: totalPagesCount,
                                  itemBuilder: (context, spreadIndex) {
                                    final Widget spreadWidget;
                                    if (isDesktop) {
                                      // Render Left Page & Right Page side-by-side
                                      final leftLogIndex = spreadIndex * 2;
                                      final rightLogIndex =
                                          spreadIndex * 2 + 1;

                                      final leftLog = logs[leftLogIndex];
                                      final rightLog =
                                          rightLogIndex < logs.length
                                          ? logs[rightLogIndex]
                                          : null;

                                      spreadWidget = Row(
                                        children: [
                                          // Left Page Sheet
                                          Expanded(
                                            child: _buildSinglePageContent(
                                              context,
                                              theme,
                                              bookTheme,
                                              leftLog,
                                              isLeft: true,
                                            ),
                                          ),
                                          // Spacing for physical center spine creasing fold
                                          const SizedBox(width: 56),
                                          // Right Page Sheet
                                          Expanded(
                                            child: rightLog != null
                                                ? _buildSinglePageContent(
                                                    context,
                                                    theme,
                                                    bookTheme,
                                                    rightLog,
                                                    isLeft: false,
                                                  )
                                                : _buildEmptyRightPageContent(
                                                    theme,
                                                    bookTheme,
                                                  ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      // Render Single Page layout
                                      final log = logs[spreadIndex];
                                      spreadWidget =
                                          _buildSinglePageContent(
                                            context,
                                            theme,
                                            bookTheme,
                                            log,
                                            isLeft: true,
                                          );
                                    }

                                    // Wrap the page spread content with the slideable Lined Paper Background Painter
                                    final Widget sheetWithLines = Stack(
                                      children: [
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter:
                                                EnhancedRuledBookSpreadPainter(
                                                  lineColor:
                                                      bookTheme.lineColor,
                                                  marginColor:
                                                      bookTheme.marginColor,
                                                  isTwoPage: isDesktop,
                                                  backgroundColor: bookTheme
                                                      .backgroundColor,
                                                  textureOpacity: bookTheme
                                                      .textureOpacity,
                                                ),
                                          ),
                                        ),
                                        spreadWidget,
                                      ],
                                    );

                                    return AnimatedBuilder(
                                      animation: _pageController,
                                      child: sheetWithLines,
                                      builder: (context, child) {
                                        double pageValue = 0.0;
                                        if (_pageController.hasClients &&
                                            _pageController
                                                .position
                                                .haveDimensions) {
                                          pageValue =
                                              _pageController.page ?? 0.0;
                                        } else {
                                          pageValue = _currentPageIndex
                                              .toDouble();
                                        }

                                        final double delta =
                                            spreadIndex - pageValue;

                                        // Premium slide-and-reveal page-turn transition (Kindle/Apple Books style)
                                        double scale = 1.0;
                                        double translation = 0.0;
                                        double opacity = 1.0;

                                        if (isDesktop) {
                                          if (delta < 0) {
                                            // Outgoing page spread slides left slower (parallax) by offsetting PageView motion
                                            translation =
                                                -delta *
                                                constraints.maxWidth *
                                                0.7;
                                            opacity = (1.0 + delta).clamp(
                                              0.0,
                                              1.0,
                                            );
                                          } else if (delta > 0) {
                                            // Incoming page spread slides in normally from the right (let PageView handle translation)
                                            translation = 0.0;
                                            opacity = 1.0;
                                          }
                                        } else {
                                          if (delta < 0) {
                                            // Outgoing page slides left slower (parallax) by offsetting PageView motion
                                            translation =
                                                -delta *
                                                constraints.maxWidth *
                                                0.7;
                                            opacity = (1.0 + delta).clamp(
                                              0.0,
                                              1.0,
                                            );
                                            scale = 1.0 + (delta * 0.04);
                                          } else if (delta > 0) {
                                            // Incoming page slides in normally from the right (let PageView handle translation)
                                            translation = 0.0;
                                            opacity = 1.0;
                                          }
                                        }

                                        // Premium Page Turn Shadow and Lighting Overlay
                                        Widget pageWithShadow = child!;

                                        if (delta != 0) {
                                          final double shadowOpacity = delta < 0
                                              ? (-delta).clamp(
                                                  0.0,
                                                  0.35,
                                                ) // Outgoing page gets shadow cast by the turning page
                                              : (1.0 - delta).clamp(
                                                  0.0,
                                                  0.15,
                                                ); // Incoming page's edge shadow

                                          pageWithShadow = Stack(
                                            children: [
                                              child,

                                              // Soft ambient shadow gradient simulating physical page curve casting light blocking
                                              if (shadowOpacity > 0)
                                                Positioned.fill(
                                                  child: IgnorePointer(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.black
                                                                .withOpacity(
                                                                  delta < 0
                                                                      ? shadowOpacity
                                                                      : 0.0,
                                                                ),
                                                            Colors.black.withOpacity(
                                                              delta < 0
                                                                  ? shadowOpacity *
                                                                        0.4
                                                                  : shadowOpacity *
                                                                        0.15,
                                                            ),
                                                            Colors.transparent,
                                                          ],
                                                          begin: Alignment
                                                              .centerRight,
                                                          end: Alignment
                                                              .centerLeft,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              // Sharp edge shadow cast by the sliding sheet of the incoming page
                                              if (delta > 0 &&
                                                  shadowOpacity > 0)
                                                Positioned(
                                                  left: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  width: 32,
                                                  child: IgnorePointer(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.black
                                                                .withOpacity(
                                                                  shadowOpacity *
                                                                      1.6,
                                                                ),
                                                            Colors.black
                                                                .withOpacity(
                                                                  shadowOpacity *
                                                                      0.5,
                                                                ),
                                                            Colors.transparent,
                                                          ],
                                                          begin: Alignment
                                                              .centerLeft,
                                                          end: Alignment
                                                              .centerRight,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                        }

                                        final Matrix4 transform =
                                            Matrix4.identity()
                                              ..translate(translation, 0.0, 0.0)
                                              ..scale(scale, scale, 1.0);

                                        return Transform(
                                          transform: transform,
                                          child: Opacity(
                                            opacity: opacity.clamp(0.0, 1.0),
                                            child: pageWithShadow,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Pagination Controls at the bottom
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: scaffoldBgColor,
                  border: Border(
                    top: BorderSide(
                      color: bookTheme.marginColor.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back arrow
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_left_rounded,
                        color: _currentPageIndex > 0
                            ? theme.colorScheme.primary
                            : bookTheme.secondaryTextColor.withOpacity(0.2),
                        size: 28,
                      ),
                      onPressed: _currentPageIndex > 0
                          ? () {
                              _pageController.previousPage(
                                duration: Duration(
                                  milliseconds:
                                      _layoutSettings.transitionDurationMs,
                                ),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          : null,
                    ),

                    // Spread Page Progress
                    Text(
                      "PAGE ${_currentPageIndex + 1} OF $totalPagesCount",
                      style: TextStyle(
                        fontFamily: bookTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: bookTheme.secondaryTextColor.withOpacity(0.5),
                        letterSpacing: 1.5,
                      ),
                    ),

                    // Forward arrow
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_right_rounded,
                        color: _currentPageIndex < totalPagesCount - 1
                            ? theme.colorScheme.primary
                            : bookTheme.secondaryTextColor.withOpacity(0.2),
                        size: 28,
                      ),
                      onPressed: _currentPageIndex < totalPagesCount - 1
                          ? () {
                              _pageController.nextPage(
                                duration: Duration(
                                  milliseconds:
                                      _layoutSettings.transitionDurationMs,
                                ),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePageContent(
    BuildContext context,
    ThemeData theme,
    BookTheme bookTheme,
    Log log, {
    required bool isLeft,
  }) {
    final date = TimeUtil.parseIsoDate(log.date);
    final formattedDate = TimeUtil.formatFullDate(date);
    final formattedTime = TimeUtil.formatTimeString(log.time, use24Hour: false);
    final dateDisplay = formattedTime.isNotEmpty
        ? '$formattedDate • $formattedTime'
        : formattedDate;

    return Scrollbar(
      thumbVisibility: true,
      thickness: 4.0,
      radius: const Radius.circular(8.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          _layoutSettings
              .horizontalPadding, // Padding left to clear margin line
          _layoutSettings.verticalPadding, // Top padding adjusted
          isLeft ? 32 : 32, // Padding right
          _layoutSettings.verticalPadding, // Bottom padding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Organic Book Metadata Row
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  dateDisplay.toUpperCase(),
                  style: TextStyle(
                    fontFamily: bookTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: bookTheme.secondaryTextColor,
                    letterSpacing: 1.5,
                  ),
                ),
                if (log.mood != null && log.mood!.isNotEmpty) ...[
                  Text(
                    "•",
                    style: TextStyle(
                      color: bookTheme.secondaryTextColor.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        log.mood!.toUpperCase(),
                        style: TextStyle(
                          fontFamily: bookTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: bookTheme.secondaryTextColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
                Text(
                  "•",
                  style: TextStyle(
                    color: bookTheme.secondaryTextColor.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${log.wordCount} WORDS",
                  style: TextStyle(
                    fontFamily: bookTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: bookTheme.secondaryTextColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Beautiful large Title below metadata
            Text(
              log.title.isNotEmpty ? log.title : "Untitled Entry",
              style: TextStyle(
                fontFamily: bookTheme.fontFamily,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: bookTheme.textColor.withOpacity(0.95),
                height: 1.3,
              ),
            ),

            // Short elegant divider line before description body
            const SizedBox(height: 16),
            Container(
              height: 4,
              width: 64, // Elegant short divider
              decoration: BoxDecoration(
                color: bookTheme.marginColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Lined Serif Body content (Premium Done Today Markdown Renderer)
            DoneTodayMarkdown(
              data: log.description,
              textColor: bookTheme.textColor,
              fontSize: _layoutSettings.fontSize,
              height: _layoutSettings.lineHeight,
              onDataChanged: (updatedData) {
                ref.read(logsNotifierProvider.notifier).editLog(log.id, {
                  ...log.toJson(),
                  'description': updatedData,
                }, silent: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRightPageContent(ThemeData theme, BookTheme bookTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all_rounded,
              color: bookTheme.marginColor.withOpacity(0.35),
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              "END OF VOLUME",
              style: TextStyle(
                fontFamily: bookTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: bookTheme.secondaryTextColor,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Write another log to begin the next page.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: bookTheme.fontFamily,
                color: bookTheme.secondaryTextColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeMenu(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _currentThemeData.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Book Theme preset",
            style: TextStyle(
              fontFamily: _currentThemeData.fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: _currentThemeData.textColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Default Theme Option
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTheme = 'app_theme';
                      });
                      HiveService.put<String>(
                        'settings',
                        'book_reader_theme',
                        'app_theme',
                      );
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _selectedTheme == 'app_theme' ||
                                  _selectedTheme == null
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width:
                              _selectedTheme == 'app_theme' ||
                                  _selectedTheme == null
                              ? 2
                              : 1,
                        ),
                        color: _currentThemeData.secondaryTextColor.withOpacity(
                          0.04,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Aa",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "App Default (Auto)",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _currentThemeData.textColor,
                                  ),
                                ),
                                Text(
                                  "Matches your system/app theme",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _currentThemeData.secondaryTextColor
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedTheme == 'app_theme' ||
                              _selectedTheme == null)
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                ...bookThemes.entries.map((entry) {
                  final preset = entry.value;
                  final isSelected = _selectedTheme == preset.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {     
                          setState(() {
                            _selectedTheme = preset.id;
                          });
                          HiveService.put<String>(
                            'settings',
                            'book_reader_theme',
                            preset.id,
                          );
                          Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? preset.marginColor
                                : Colors.transparent,
                            width: isSelected ? 2 : 1,
                          ),
                          color: _currentThemeData.secondaryTextColor
                              .withOpacity(0.04),
                        ),
                        child: Row(
                          children: [
                            // Preview Circle
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: preset.backgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Aa",
                                  style: TextStyle(
                                    fontFamily: preset.fontFamily,
                                    color: preset.textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.name,
                                    style: TextStyle(
                                      fontFamily: preset.fontFamily,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: _currentThemeData.textColor,
                                    ),
                                  ),
                                  Text(
                                    preset.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _currentThemeData
                                          .secondaryTextColor
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                              Icon(
                                Icons.check_circle_rounded,
                                color: preset.marginColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _currentThemeData.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "READING SETTINGS",
                  style: TextStyle(
                    fontFamily: _currentThemeData.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: _currentThemeData.textColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 24),

                // Font Size
                _buildSettingSlider(
                  'Text Size',
                  _layoutSettings.fontSize,
                  12.0,
                  24.0,
                  (newValue) {
                    setSheetState(() {
                      _layoutSettings = _layoutSettings.copyWith(
                        fontSize: newValue,
                      );
                    });
                    setState(() {}); // Update the screen too
                    _layoutSettings.saveToStorage();
                  },
                ),
                const SizedBox(height: 16),

                // Line Height
                _buildSettingSlider(
                  'Line Height',
                  _layoutSettings.lineHeight,
                  1.4,
                  3.0,
                  (newValue) {
                    setSheetState(() {
                      _layoutSettings = _layoutSettings.copyWith(
                        lineHeight: newValue,
                      );
                    });
                    setState(() {});
                    _layoutSettings.saveToStorage();
                  },
                ),
                const SizedBox(height: 16),

                // Letter Spacing
                _buildSettingSlider(
                  'Letter Spacing',
                  _layoutSettings.letterSpacing,
                  0.0,
                  2.0,
                  (newValue) {
                    setSheetState(() {
                      _layoutSettings = _layoutSettings.copyWith(
                        letterSpacing: newValue,
                      );
                    });
                    setState(() {});
                    _layoutSettings.saveToStorage();
                  },
                ),
                const SizedBox(height: 16),

                // Page Transition Speed
                _buildSettingSlider(
                  'Page Transition Speed',
                  _layoutSettings.transitionDurationMs.toDouble(),
                  200.0,
                  800.0,
                  (newValue) {
                    setSheetState(() {
                      _layoutSettings = _layoutSettings.copyWith(
                        transitionDurationMs: newValue.toInt(),
                      );
                    });
                    setState(() {});
                    _layoutSettings.saveToStorage();
                  },
                  format: (val) => '${val.toInt()}ms',
                ),
                const SizedBox(height: 24),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setSheetState(() {
                        _layoutSettings = const BookLayoutSettings();
                      });
                      setState(() {});
                      _layoutSettings.saveToStorage();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _currentThemeData.marginColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reset to Defaults',
                      style: TextStyle(
                        fontFamily: _currentThemeData.fontFamily,
                        color: _currentThemeData.marginColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    String Function(double)? format,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: _currentThemeData.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _currentThemeData.textColor,
              ),
            ),
            Text(
              format?.call(value) ?? value.toStringAsFixed(2),
              style: TextStyle(
                fontFamily: _currentThemeData.fontFamily,
                fontSize: 12,
                color: _currentThemeData.marginColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: _currentThemeData.marginColor,
          inactiveColor: _currentThemeData.lineColor,
          onChanged: onChanged,
        ),
      ],
    );
  }


  Widget _buildEmptyBookScreen(ThemeData theme, BookTheme bookTheme) {
    return Scaffold(
      backgroundColor: bookTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: bookTheme.textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: bookTheme.textColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              "BOOK MODE EMPTY",
              style: TextStyle(
                fontFamily: bookTheme.fontFamily,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: bookTheme.textColor.withOpacity(0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create daily logs to begin your personal volume.",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: bookTheme.fontFamily,
                color: bookTheme.textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
