class ShopCosmetic {
  final String id;
  final String name;
  final int soulCost;
  final String rarity;
  final String type; // 'background' | 'frame' | 'avatar'

  const ShopCosmetic({
    required this.id,
    required this.name,
    required this.soulCost,
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
  final int soulCost;
  final String rarity;
  final String assetPath;

  const ShopAvatar({
    required this.id,
    required this.name,
    required this.soulCost,
    this.rarity = 'common',
    this.assetPath = '',
  });
}

class ShopCatalog {
  static const List<ShopCosmetic> premiumBackgrounds = [
    ShopCosmetic(id: 'premium_void', name: 'Void', soulCost: 650, rarity: 'epic', type: 'background'),
    ShopCosmetic(id: 'premium_neon', name: 'Neon', soulCost: 1100, rarity: 'legendary', type: 'background'),
  ];

  static const List<ShopCosmetic> premiumFrames = [
    ShopCosmetic(id: 'premium_royal', name: 'Royal', soulCost: 500, rarity: 'rare', type: 'frame'),
    ShopCosmetic(id: 'premium_void_frame', name: 'Void Frame', soulCost: 750, rarity: 'epic', type: 'frame'),
  ];

  static const List<ShopAvatar> premiumAvatars = [
    // AVAILABLE SOON — assets pending
  ];

  static const List<ShopConsumable> consumables = [
    ShopConsumable(id: 'hint_1', name: 'Pista', description: '1 pista instantánea', tokenCost: 5, quantity: 1),
    ShopConsumable(id: 'hint_5', name: 'Pack x5 Pistas', description: '5 pistas con descuento', tokenCost: 20, quantity: 5),
    ShopConsumable(id: 'adv_note_1', name: 'Nota Avanzada', description: '1 activación de notas avanzadas', tokenCost: 2, quantity: 1),
    ShopConsumable(id: 'adv_note_10', name: 'Pack x10 Notas', description: '10 activaciones con descuento', tokenCost: 15, quantity: 10),
  ];
}
