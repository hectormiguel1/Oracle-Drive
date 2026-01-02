class ZtrEntry {
  final String id;
  String text;
  final String? sourceFile;

  ZtrEntry(this.id, this.text, {this.sourceFile});
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
