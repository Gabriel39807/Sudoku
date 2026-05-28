class ShopCosmetic {
  final String id;
  final String name;
  final int gemCost;
  final String rarity;
  final String type; // 'background' | 'frame' | 'avatar'

  const ShopCosmetic({
    required this.id,
    required this.name,
    required this.gemCost,
    this.rarity = 'common',
    required this.type,
  });
}

class ShopConsumable {
  final String id;
  final String name;
  final String description;
  final int tokenCost;
  final int quantity; // how many units you get

  const ShopConsumable({
    required this.id,
    required this.name,
    required this.description,
    required this.tokenCost,
    required this.quantity,
  });
}

class ShopAvatar {
  final String id;
  final String name;
  final int gemCost;
  final String rarity;

  const ShopAvatar({
    required this.id,
    required this.name,
    required this.gemCost,
    this.rarity = 'common',
  });
}

class ShopCatalog {
  static const List<ShopCosmetic> premiumBackgrounds = [
    ShopCosmetic(id: 'premium_void', name: 'Void', gemCost: 650, rarity: 'epic', type: 'background'),
    ShopCosmetic(id: 'premium_neon', name: 'Neon', gemCost: 1100, rarity: 'legendary', type: 'background'),
  ];

  static const List<ShopCosmetic> premiumFrames = [
    ShopCosmetic(id: 'premium_royal', name: 'Royal', gemCost: 500, rarity: 'rare', type: 'frame'),
    ShopCosmetic(id: 'premium_void_frame', name: 'Void Frame', gemCost: 750, rarity: 'epic', type: 'frame'),
  ];

  static const List<ShopAvatar> premiumAvatars = [
    // ── COMMON ──
    ShopAvatar(id: 'geo_circle', name: 'Círculo', gemCost: 100, rarity: 'common'),
    ShopAvatar(id: 'geo_square', name: 'Cuadrado', gemCost: 100, rarity: 'common'),
    ShopAvatar(id: 'geo_triangle', name: 'Triángulo', gemCost: 120, rarity: 'common'),
    ShopAvatar(id: 'geo_hex', name: 'Hexágono', gemCost: 130, rarity: 'common'),
    ShopAvatar(id: 'geo_diamond', name: 'Diamante', gemCost: 150, rarity: 'common'),
    // ── RARE ──
    ShopAvatar(id: 'element_fire', name: 'Llama', gemCost: 250, rarity: 'rare'),
    ShopAvatar(id: 'element_frost', name: 'Escarcha', gemCost: 250, rarity: 'rare'),
    ShopAvatar(id: 'element_neon', name: 'Neón', gemCost: 300, rarity: 'rare'),
    ShopAvatar(id: 'element_rune', name: 'Runa', gemCost: 350, rarity: 'rare'),
    ShopAvatar(id: 'element_crystal', name: 'Cristal', gemCost: 400, rarity: 'rare'),
    // ── EPIC ──
    ShopAvatar(id: 'theme_cyber', name: 'Cyber', gemCost: 600, rarity: 'epic'),
    ShopAvatar(id: 'theme_cosmic', name: 'Cósmico', gemCost: 700, rarity: 'epic'),
    ShopAvatar(id: 'theme_glitch', name: 'Glitch', gemCost: 800, rarity: 'epic'),
    ShopAvatar(id: 'theme_crown', name: 'Corona', gemCost: 900, rarity: 'epic'),
    // ── LEGENDARY ──
    ShopAvatar(id: 'legend_dragon', name: 'Dragón', gemCost: 1200, rarity: 'legendary'),
    ShopAvatar(id: 'legend_phoenix', name: 'Fénix', gemCost: 1400, rarity: 'legendary'),
    ShopAvatar(id: 'legend_eclipse', name: 'Eclipse', gemCost: 1600, rarity: 'legendary'),
    ShopAvatar(id: 'legend_void', name: 'Vacío', gemCost: 1800, rarity: 'legendary'),
    // ── MYTHIC ──
    ShopAvatar(id: 'mythic_aether', name: 'Aether', gemCost: 2500, rarity: 'mythic'),
    ShopAvatar(id: 'mythic_eternity', name: 'Eternidad', gemCost: 3000, rarity: 'mythic'),
  ];

  static const List<ShopAvatar> premiumAvatarFrames = [
    // ── COMMON ──
    ShopAvatar(id: 'frame_metallic', name: 'Metálico', gemCost: 450, rarity: 'common'),
    ShopAvatar(id: 'frame_minimal', name: 'Minimal', gemCost: 500, rarity: 'common'),
    // ── RARE ──
    ShopAvatar(id: 'frame_energy', name: 'Energía', gemCost: 700, rarity: 'rare'),
    ShopAvatar(id: 'frame_crystal', name: 'Cristal', gemCost: 900, rarity: 'rare'),
    // ── EPIC ──
    ShopAvatar(id: 'frame_neon', name: 'Neón', gemCost: 1200, rarity: 'epic'),
    ShopAvatar(id: 'frame_cosmic', name: 'Anillo Cósmico', gemCost: 1600, rarity: 'epic'),
    // ── LEGENDARY ──
    ShopAvatar(id: 'frame_dragon', name: 'Aura de Dragón', gemCost: 2000, rarity: 'legendary'),
    ShopAvatar(id: 'frame_phoenix', name: 'Llama de Fénix', gemCost: 2200, rarity: 'legendary'),
    // ── MYTHIC ──
    ShopAvatar(id: 'frame_void', name: 'Orbital del Vacío', gemCost: 3000, rarity: 'mythic'),
    ShopAvatar(id: 'frame_aether', name: 'Halo Etéreo', gemCost: 3500, rarity: 'mythic'),
  ];

  static const List<ShopConsumable> consumables = [
    ShopConsumable(id: 'hint_1', name: 'Pista', description: '1 pista instantánea', tokenCost: 5, quantity: 1),
    ShopConsumable(id: 'hint_5', name: 'Pack x5 Pistas', description: '5 pistas con descuento', tokenCost: 20, quantity: 5),
    ShopConsumable(id: 'adv_note_1', name: 'Nota Avanzada', description: '1 activación de notas avanzadas', tokenCost: 2, quantity: 1),
    ShopConsumable(id: 'adv_note_10', name: 'Pack x10 Notas', description: '10 activaciones con descuento', tokenCost: 15, quantity: 10),
  ];
}
