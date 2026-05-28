import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/sudoku_variant.dart';

enum TutorialStep { rows, columns, blocks }

class TutorialScreen extends StatefulWidget {
  final int level;
  final SudokuVariant variant;
  final VoidCallback onComplete;

  const TutorialScreen({
    super.key,
    required this.level,
    required this.variant,
    required this.onComplete,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentPage = 0;
  late final PageController _pageCtrl;
  late final List<_TutorialPage> _pages;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    final size = widget.variant.boardSize;
    _pages = [
      _TutorialPage(
        title: 'FILAS',
        subtitle: 'Cada fila tiene los números del 1 al $size sin repetir',
        description: 'En Sudoku, cada FILA debe contener todos los números exactamente una vez.\n\n'
            'Si ves un número repetido en la misma fila, es un error.',
        highlight: _buildRowHighlight(size),
        icon: Icons.view_column_outlined,
        gradientColors: [const Color(0xFF6C63FF), const Color(0xFF3F3D9E)],
      ),
      _TutorialPage(
        title: 'COLUMNAS',
        subtitle: 'Cada columna también tiene los números del 1 al $size sin repetir',
        description: 'Lo mismo aplica para cada COLUMNA.\n\n'
            'No podés repetir el mismo número en una columna.',
        highlight: _buildColumnHighlight(size),
        icon: Icons.view_column_outlined,
        gradientColors: [const Color(0xFFFF6B6B), const Color(0xFFC0392B)],
      ),
      _TutorialPage(
        title: 'BLOQUES',
        subtitle: 'Los bloques de ${widget.variant.config.subgridWidth}x${widget.variant.config.subgridHeight} también',
        description: 'Cada BLOQUE (subgrid) debe tener los números del 1 al $size sin repetir.\n\n'
            'Es la regla más importante del Sudoku.',
        highlight: _buildBlockHighlight(size, widget.variant.config.subgridWidth, widget.variant.config.subgridHeight),
        icon: Icons.grid_view_outlined,
        gradientColors: [const Color(0xFF00B894), const Color(0xFF00695C)],
      ),
    ];
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(duration: 300.ms, curve: Curves.easeInOut);
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [page.gradientColors.first, page.gradientColors.last],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return AnimatedSwitcher(
                      duration: 400.ms,
                      transitionBuilder: (child, anim) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        );
                      },
                      child: _buildPage(p, key: ValueKey(i)),
                    );
                  },
                ),
              ),
              _buildBottomNav(isLast),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(_pages.length, (i) {
          final isActive = i <= _currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: 300.ms,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage(_TutorialPage page, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(page.icon, size: 48, color: Colors.white),
          ).animate().fade(duration: 400.ms).scale(begin: Offset(0.8, 0.8), curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(page.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.white))
              .animate().fade(delay: 200.ms).slideY(begin: 0.3),
          const SizedBox(height: 12),
          Text(page.subtitle, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.9), height: 1.4))
              .animate().fade(delay: 300.ms).slideY(begin: 0.3),
          const SizedBox(height: 32),
          _buildMiniBoard(page.highlight),
          const SizedBox(height: 32),
          Text(page.description, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), height: 1.6))
              .animate().fade(delay: 400.ms).slideY(begin: 0.3),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMiniBoard(Set<String> highlighted) {
    final size = widget.variant.boardSize;
    final cellSize = (MediaQuery.of(context).size.width - 100) / size;
    final sw = widget.variant.config.subgridWidth;
    final sh = widget.variant.config.subgridHeight;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(size, (r) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(size, (c) {
              final key = '$r,$c';
              final isHighlighted = highlighted.contains(key);
              return Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.amber.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.05),
                  border: _buildBorder(r, c, size, sw, sh),
                ),
                child: Center(
                  child: Text('${r * size + c + 1}',
                      style: TextStyle(fontSize: cellSize * 0.3,
                          color: isHighlighted ? Colors.white : Colors.white38)),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Border _buildBorder(int r, int c, int size, int sw, int sh) {
    final thick = 1.5;
    final thin = 0.5;
    return Border(
      top: BorderSide(color: Colors.white24, width: r % sh == 0 && r != 0 ? thick : thin),
      left: BorderSide(color: Colors.white24, width: c % sw == 0 && c != 0 ? thick : thin),
      bottom: BorderSide(color: Colors.white24, width: thin),
      right: BorderSide(color: Colors.white24, width: thin),
    );
  }

  Widget _buildBottomNav(bool isLast) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: _goNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            isLast ? 'A JUGAR!' : 'SIGUIENTE',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
          ),
        ),
      ),
    );
  }
}

class _TutorialPage {
  final String title;
  final String subtitle;
  final String description;
  final Set<String> highlight;
  final IconData icon;
  final List<Color> gradientColors;

  const _TutorialPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.highlight,
    required this.icon,
    required this.gradientColors,
  });
}

Set<String> _buildRowHighlight(int size) {
  final cells = <String>{};
  for (var c = 0; c < size; c++) { cells.add('0,$c'); }
  return cells;
}

Set<String> _buildColumnHighlight(int size) {
  final cells = <String>{};
  for (var r = 0; r < size; r++) { cells.add('$r,0'); }
  return cells;
}

Set<String> _buildBlockHighlight(int size, int sw, int sh) {
  final cells = <String>{};
  for (var r = 0; r < sh; r++) {
    for (var c = 0; c < sw; c++) {
      cells.add('$r,$c');
    }
  }
  return cells;
}
