import 'package:flutter/material.dart';
import '../domain/board_theme.dart';
import '../domain/frame_skin.dart';

const _previewFrameThickness = 32.0;
const _previewCornerSize = 42.0;

class CosmeticsBoardPreview extends StatelessWidget {
  final BoardTheme theme;
  final FrameSkin frame;
  final bool showFrame;

  const CosmeticsBoardPreview({
    super.key,
    required this.theme,
    required this.frame,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(theme.backgroundPath, fit: BoxFit.cover),
          ),
          if (showFrame) _buildFrame(),
          Padding(
            padding: const EdgeInsets.all(_previewFrameThickness),
            child: _dummyGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFrame() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildSides(),
        _buildCorners(),
        _buildOrnaments(),
      ],
    );
  }

  Widget _buildSides() {
    return Stack(
      children: [
        Positioned(top: 0, left: _previewFrameThickness, right: _previewFrameThickness, child: Image.asset(frame.edges.top, height: _previewFrameThickness, fit: BoxFit.fill)),
        Positioned(bottom: 0, left: _previewFrameThickness, right: _previewFrameThickness, child: Image.asset(frame.edges.bottom, height: _previewFrameThickness, fit: BoxFit.fill)),
        Positioned(left: 0, top: _previewFrameThickness, bottom: _previewFrameThickness, child: Image.asset(frame.edges.left, width: _previewFrameThickness, fit: BoxFit.fill)),
        Positioned(right: 0, top: _previewFrameThickness, bottom: _previewFrameThickness, child: Image.asset(frame.edges.right, width: _previewFrameThickness, fit: BoxFit.fill)),
      ],
    );
  }

  Widget _buildCorners() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(top: 0, left: 0, child: Image.asset(frame.corners.tl, width: _previewCornerSize, height: _previewCornerSize)),
        Positioned(top: 0, right: 0, child: Image.asset(frame.corners.tr, width: _previewCornerSize, height: _previewCornerSize)),
        Positioned(bottom: 0, left: 0, child: Image.asset(frame.corners.bl, width: _previewCornerSize, height: _previewCornerSize)),
        Positioned(bottom: 0, right: 0, child: Image.asset(frame.corners.br, width: _previewCornerSize, height: _previewCornerSize)),
      ],
    );
  }

  Widget _buildOrnaments() {
    return Stack(
      children: [
        Positioned(top: 0, left: 0, right: 0, child: Center(child: Image.asset(frame.decorations.topCenter, width: _previewFrameThickness, height: _previewFrameThickness))),
        Positioned(bottom: 0, left: 0, right: 0, child: Center(child: Image.asset(frame.decorations.bottomCenter, width: _previewFrameThickness, height: _previewFrameThickness))),
        Positioned(left: 0, top: 0, bottom: 0, child: Center(child: Image.asset(frame.decorations.leftCenter, width: _previewFrameThickness, height: _previewFrameThickness))),
        Positioned(right: 0, top: 0, bottom: 0, child: Center(child: Image.asset(frame.decorations.rightCenter, width: _previewFrameThickness, height: _previewFrameThickness))),
      ],
    );
  }

  Widget _dummyGrid() {
    return Column(
      children: List.generate(9, (r) {
        return Expanded(
          child: Row(
            children: List.generate(9, (c) {
              final isBold = r % 3 == 0 || c % 3 == 0;
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isBold ? 0.15 : 0.06),
                      width: isBold ? 1.5 : 0.5,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
