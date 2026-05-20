// Future economy models.
// No UI, no shop, no monetization — just data models for future use.

// TODO FUTURE SHOP: coins, gems, purchases, inventory
class CoinBalance {
  final int coins;
  const CoinBalance({this.coins = 0});
}

// TODO FUTURE SHOP: premium currency
class GemBalance {
  final int gems;
  const GemBalance({this.gems = 0});
}

// TODO FUTURE SHOP: cosmetic skins
class Skin {
  final String id;
  final String name;
  final bool owned;
  final bool equipped;
  const Skin({required this.id, required this.name, this.owned = false, this.equipped = false});
}

// TODO FUTURE SHOP: UI themes
class ThemeData {
  final String id;
  final String name;
  final bool owned;
  final bool equipped;
  const ThemeData({required this.id, required this.name, this.owned = false, this.equipped = false});
}

// TODO FUTURE SHOP: full player inventory
class PlayerInventory {
  final int coins;
  final int gems;
  final List<Skin> skins;
  final List<ThemeData> themes;
  const PlayerInventory({
    this.coins = 0,
    this.gems = 0,
    this.skins = const [],
    this.themes = const [],
  });
}
