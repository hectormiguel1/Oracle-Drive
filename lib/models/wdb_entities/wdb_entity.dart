enum LookupType { direct, item, ability }

abstract class WdbEntity {
  Map<String, dynamic> toMap();
  Map<LookupType, List<String>>? getLookupKeys();
}
