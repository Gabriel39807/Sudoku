import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/currency/currency_assets.dart';
import '../../ui/currency/currency_type.dart';

class DifficultyUnlockDialog extends StatefulWidget {
  final String difficulty;
  final VoidCallback onPlay;
  final VoidCallback onBack;

  const DifficultyUnlockDialog({
    super.key,
    required this.difficulty,
    required this.onPlay,
    required this.onBack,
  });

  @override
  State<DifficultyUnlockDialog> createState() => _DifficultyUnlockDialogState();
}

class _DifficultyUnlockDialogState extends State<DifficultyUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const _accentColors = {
    'easy': Color(0xFF4CAF50),
    'intermediate': Color(0xFF2196F3),
    'hard': Color(0xFFFF9800),
    'expert': Color(0xFFF44336),
    'evil': Color(0xFF9C27B0),
    'mythic': Color(0xFFFFD700),
  };

  static const _subtitles = {
    'easy': 'Aprendiz',
    'intermediate': 'Intermedio',
    'hard': 'Avanzado',
    'expert': 'Experto',
    'evil': 'Caos',
    'mythic': 'Legendario',
  };

  static const _descriptions = {
    'easy': 'Perfecto para empezar. Resuelve tableros con celdas predefinidas, solo necesitas lógica básica.',
    'intermediate': 'Nuevas técnicas aparecen. Pares desnudos y ocultos te harán pensar antes de colocar.',
    'hard': 'Pares señaladores y reducción de caja-línea. El tablero exige más de tu concentración.',
    'expert': 'XWing y Swordfish. Patrones avanzados que pocos dominan. Bienvenido al siguiente nivel.',
    'evil': 'XYWing. Cada movimiento cuenta. Un error y el tablero se vuelve contra vos.',
    'mythic': 'Cadenas forzadas. Solo los mejores leyendarios superan este desafío.',
  };

  static const _soulRewards = {
    'easy': 2, 'intermediate': 3, 'hard': 5,
    'expert': 7, 'evil': 10, 'mythic': 15,
  };

  Color get _accent => _accentColors[widget.difficulty] ?? Colors.grey;
  String get _displayName => widget.difficulty.toUpperCase();
  String get _subtitle => _subtitles[widget.difficulty] ?? '';
  String get _description => _descriptions[widget.difficulty] ?? '';
  int get _souls => _soulRewards[widget.difficulty] ?? 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: FadeTransition(
            opacity: _animController,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _animController,
                curve: Curves.easeOutBack,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                      ],
                    ),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildBadge(),
                      const SizedBox(height: 20),
                      _buildTitle(),
                      const SizedBox(height: 8),
                      _buildSubtitle(),
                      const SizedBox(height: 16),
                      _buildDescription(),
                      const SizedBox(height: 20),
                      _buildRewards(),
                      const SizedBox(height: 24),
                      _buildButtons(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onBack,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        'DESBLOQUEADO',
        style: GoogleFonts.exo2(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
          color: _accent,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _displayName,
      style: GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 6,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      _subtitle,
      style: GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: _accent.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        _description,
        textAlign: TextAlign.center,
        style: GoogleFonts.rajdhani(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildRewards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _rewardChip('${CurrencyAssets.emojiFor(CurrencyType.souls)} $_souls', CurrencyAssets.colorFor(CurrencyType.souls)),
          const SizedBox(width: 12),
          _rewardChip('${CurrencyAssets.emojiFor(CurrencyType.tokens)} 1', CurrencyAssets.colorFor(CurrencyType.tokens)),
        ],
      ),
    );
  }

  Widget _rewardChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.exo2(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onPlay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 8,
                shadowColor: _accent.withValues(alpha: 0.5),
              ),
              child: Text(
                'JUGAR',
                style: GoogleFonts.exo2(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onBack();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'VOLVER',
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
