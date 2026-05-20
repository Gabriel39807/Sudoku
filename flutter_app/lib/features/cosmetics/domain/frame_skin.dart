import 'package:flutter/material.dart';

class FrameCorners {
  final String tl;
  final String tr;
  final String bl;
  final String br;

  const FrameCorners({
    required this.tl,
    required this.tr,
    required this.bl,
    required this.br,
  });

  ImageProvider image(String corner) {
    return AssetImage(_pathFor(corner));
  }

  String _pathFor(String corner) {
    switch (corner) {
      case 'tl': return tl;
      case 'tr': return tr;
      case 'bl': return bl;
      case 'br': return br;
      default: return tl;
    }
  }

  List<String> get all => [tl, tr, bl, br];
}

class FrameEdges {
  final String top;
  final String bottom;
  final String left;
  final String right;

  const FrameEdges({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  ImageProvider image(String edge) {
    return AssetImage(_pathFor(edge));
  }

  String _pathFor(String edge) {
    switch (edge) {
      case 'top': return top;
      case 'bottom': return bottom;
      case 'left': return left;
      case 'right': return right;
      default: return top;
    }
  }

  List<String> get all => [top, bottom, left, right];
}

class FrameDecorations {
  final String topCenter;
  final String bottomCenter;
  final String leftCenter;
  final String rightCenter;

  const FrameDecorations({
    required this.topCenter,
    required this.bottomCenter,
    required this.leftCenter,
    required this.rightCenter,
  });

  ImageProvider image(String decor) {
    return AssetImage(_pathFor(decor));
  }

  String _pathFor(String decor) {
    switch (decor) {
      case 'top_center': return topCenter;
      case 'bottom_center': return bottomCenter;
      case 'left_center': return leftCenter;
      case 'right_center': return rightCenter;
      default: return topCenter;
    }
  }

  List<String> get all => [topCenter, bottomCenter, leftCenter, rightCenter];
}

class FrameSkin {
  final String id;
  final String name;
  final FrameCorners corners;
  final FrameEdges edges;
  final FrameDecorations decorations;
  final bool locked;
  final String rarity;

  // FUTURE: coins, gems, unlockCost, shopCategory

  const FrameSkin({
    required this.id,
    required this.name,
    required this.corners,
    required this.edges,
    required this.decorations,
    this.locked = false,
    this.rarity = 'common',
  });

  static String _base(String id) => 'assets/cosmetics/frames/$id';

  static final List<FrameSkin> defaults = [
    FrameSkin(
      id: 'default',
      name: 'Default',
      rarity: 'common',
      corners: FrameCorners(
        tl: '${_base("default")}/tl.webp',
        tr: '${_base("default")}/tr.webp',
        bl: '${_base("default")}/bl.webp',
        br: '${_base("default")}/br.webp',
      ),
      edges: FrameEdges(
        top: '${_base("default")}/top.webp',
        bottom: '${_base("default")}/bottom.webp',
        left: '${_base("default")}/left.webp',
        right: '${_base("default")}/right.webp',
      ),
      decorations: FrameDecorations(
        topCenter: '${_base("default")}/top_center.webp',
        bottomCenter: '${_base("default")}/bottom_center.webp',
        leftCenter: '${_base("default")}/left_center.webp',
        rightCenter: '${_base("default")}/right_center.webp',
      ),
    ),
    FrameSkin(
      id: 'gold',
      name: 'Gold',
      rarity: 'rare',
      corners: FrameCorners(
        tl: '${_base("gold")}/tl.webp',
        tr: '${_base("gold")}/tr.webp',
        bl: '${_base("gold")}/bl.webp',
        br: '${_base("gold")}/br.webp',
      ),
      edges: FrameEdges(
        top: '${_base("gold")}/top.webp',
        bottom: '${_base("gold")}/bottom.webp',
        left: '${_base("gold")}/left.webp',
        right: '${_base("gold")}/right.webp',
      ),
      decorations: FrameDecorations(
        topCenter: '${_base("gold")}/top_center.webp',
        bottomCenter: '${_base("gold")}/bottom_center.webp',
        leftCenter: '${_base("gold")}/left_center.webp',
        rightCenter: '${_base("gold")}/right_center.webp',
      ),
    ),
    FrameSkin(
      id: 'crystal',
      name: 'Crystal',
      rarity: 'rare',
      corners: FrameCorners(
        tl: '${_base("crystal")}/tl.webp',
        tr: '${_base("crystal")}/tr.webp',
        bl: '${_base("crystal")}/bl.webp',
        br: '${_base("crystal")}/br.webp',
      ),
      edges: FrameEdges(
        top: '${_base("crystal")}/top.webp',
        bottom: '${_base("crystal")}/bottom.webp',
        left: '${_base("crystal")}/left.webp',
        right: '${_base("crystal")}/right.webp',
      ),
      decorations: FrameDecorations(
        topCenter: '${_base("crystal")}/top_center.webp',
        bottomCenter: '${_base("crystal")}/bottom_center.webp',
        leftCenter: '${_base("crystal")}/left_center.webp',
        rightCenter: '${_base("crystal")}/right_center.webp',
      ),
    ),
    FrameSkin(
      id: 'shadow',
      name: 'Shadow',
      rarity: 'uncommon',
      corners: FrameCorners(
        tl: '${_base("shadow")}/tl.webp',
        tr: '${_base("shadow")}/tr.webp',
        bl: '${_base("shadow")}/bl.webp',
        br: '${_base("shadow")}/br.webp',
      ),
      edges: FrameEdges(
        top: '${_base("shadow")}/top.webp',
        bottom: '${_base("shadow")}/bottom.webp',
        left: '${_base("shadow")}/left.webp',
        right: '${_base("shadow")}/right.webp',
      ),
      decorations: FrameDecorations(
        topCenter: '${_base("shadow")}/top_center.webp',
        bottomCenter: '${_base("shadow")}/bottom_center.webp',
        leftCenter: '${_base("shadow")}/left_center.webp',
        rightCenter: '${_base("shadow")}/right_center.webp',
      ),
    ),
  ];
}
