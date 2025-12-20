class ZtrEntry {
  final String id;
  String text;

  ZtrEntry(this.id, this.text);
}

class ZtrKeyMapping {
  final String key;
  final String value;

  ZtrKeyMapping(this.key, this.value);
}

class ZtrData {
  final List<ZtrEntry> entries;
  final List<ZtrKeyMapping> mappings;

  ZtrData({required this.entries, this.mappings = const []});
}
