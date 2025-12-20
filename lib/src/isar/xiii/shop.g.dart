// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetShopTableCollection on Isar {
  IsarCollection<int, ShopTable> get shopTables => this.collection();
}

final ShopTableSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ShopTable',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'record', type: IsarType.string),
      IsarPropertySchema(name: 'flagItemId', type: IsarType.string),
      IsarPropertySchema(name: 'shopNameLabel', type: IsarType.string),
      IsarPropertySchema(name: 'itemLabels', type: IsarType.stringList),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'record',
        properties: ["record"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, ShopTable>(
    serialize: serializeShopTable,
    deserialize: deserializeShopTable,
    deserializeProperty: deserializeShopTableProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeShopTable(IsarWriter writer, ShopTable object) {
  IsarCore.writeString(writer, 1, object.record);
  IsarCore.writeString(writer, 2, object.flagItemId);
  IsarCore.writeString(writer, 3, object.shopNameLabel);
  {
    final list = object.itemLabels;
    final listWriter = IsarCore.beginList(writer, 4, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  return object.id;
}

@isarProtected
ShopTable deserializeShopTable(IsarReader reader) {
  final String _record;
  _record = IsarCore.readString(reader, 1) ?? '';
  final String _flagItemId;
  _flagItemId = IsarCore.readString(reader, 2) ?? '';
  final String _shopNameLabel;
  _shopNameLabel = IsarCore.readString(reader, 3) ?? '';
  final List<String> _itemLabels;
  {
    final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _itemLabels = const <String>[];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        _itemLabels = list;
      }
    }
  }
  final object = ShopTable(
    record: _record,
    flagItemId: _flagItemId,
    shopNameLabel: _shopNameLabel,
    itemLabels: _itemLabels,
  );
  return object;
}

@isarProtected
dynamic deserializeShopTableProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      {
        final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const <String>[];
          } else {
            final list = List<String>.filled(length, '', growable: true);
            for (var i = 0; i < length; i++) {
              list[i] = IsarCore.readString(reader, i) ?? '';
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _ShopTableUpdate {
  bool call({
    required int id,
    String? record,
    String? flagItemId,
    String? shopNameLabel,
  });
}

class _ShopTableUpdateImpl implements _ShopTableUpdate {
  const _ShopTableUpdateImpl(this.collection);

  final IsarCollection<int, ShopTable> collection;

  @override
  bool call({
    required int id,
    Object? record = ignore,
    Object? flagItemId = ignore,
    Object? shopNameLabel = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (record != ignore) 1: record as String?,
            if (flagItemId != ignore) 2: flagItemId as String?,
            if (shopNameLabel != ignore) 3: shopNameLabel as String?,
          },
        ) >
        0;
  }
}

sealed class _ShopTableUpdateAll {
  int call({
    required List<int> id,
    String? record,
    String? flagItemId,
    String? shopNameLabel,
  });
}

class _ShopTableUpdateAllImpl implements _ShopTableUpdateAll {
  const _ShopTableUpdateAllImpl(this.collection);

  final IsarCollection<int, ShopTable> collection;

  @override
  int call({
    required List<int> id,
    Object? record = ignore,
    Object? flagItemId = ignore,
    Object? shopNameLabel = ignore,
  }) {
    return collection.updateProperties(id, {
      if (record != ignore) 1: record as String?,
      if (flagItemId != ignore) 2: flagItemId as String?,
      if (shopNameLabel != ignore) 3: shopNameLabel as String?,
    });
  }
}

extension ShopTableUpdate on IsarCollection<int, ShopTable> {
  _ShopTableUpdate get update => _ShopTableUpdateImpl(this);

  _ShopTableUpdateAll get updateAll => _ShopTableUpdateAllImpl(this);
}

sealed class _ShopTableQueryUpdate {
  int call({String? record, String? flagItemId, String? shopNameLabel});
}

class _ShopTableQueryUpdateImpl implements _ShopTableQueryUpdate {
  const _ShopTableQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<ShopTable> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? flagItemId = ignore,
    Object? shopNameLabel = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (record != ignore) 1: record as String?,
      if (flagItemId != ignore) 2: flagItemId as String?,
      if (shopNameLabel != ignore) 3: shopNameLabel as String?,
    });
  }
}

extension ShopTableQueryUpdate on IsarQuery<ShopTable> {
  _ShopTableQueryUpdate get updateFirst =>
      _ShopTableQueryUpdateImpl(this, limit: 1);

  _ShopTableQueryUpdate get updateAll => _ShopTableQueryUpdateImpl(this);
}

class _ShopTableQueryBuilderUpdateImpl implements _ShopTableQueryUpdate {
  const _ShopTableQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<ShopTable, ShopTable, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? flagItemId = ignore,
    Object? shopNameLabel = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (record != ignore) 1: record as String?,
        if (flagItemId != ignore) 2: flagItemId as String?,
        if (shopNameLabel != ignore) 3: shopNameLabel as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension ShopTableQueryBuilderUpdate
    on QueryBuilder<ShopTable, ShopTable, QOperations> {
  _ShopTableQueryUpdate get updateFirst =>
      _ShopTableQueryBuilderUpdateImpl(this, limit: 1);

  _ShopTableQueryUpdate get updateAll => _ShopTableQueryBuilderUpdateImpl(this);
}

extension ShopTableQueryFilter
    on QueryBuilder<ShopTable, ShopTable, QFilterCondition> {
  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  recordGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  recordLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> recordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> flagItemIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  flagItemIdGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  flagItemIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> flagItemIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  flagItemIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> flagItemIdBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  flagItemIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> flagItemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> flagItemIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> flagItemIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  flagItemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  flagItemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  shopNameLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsIsEmpty() {
    return not().itemLabelsIsNotEmpty();
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  itemLabelsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 4, value: null),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }
}

extension ShopTableQueryObject
    on QueryBuilder<ShopTable, ShopTable, QFilterCondition> {}

extension ShopTableQuerySortBy on QueryBuilder<ShopTable, ShopTable, QSortBy> {
  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> sortByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> sortByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> sortByFlagItemId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> sortByFlagItemIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> sortByShopNameLabel({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> sortByShopNameLabelDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension ShopTableQuerySortThenBy
    on QueryBuilder<ShopTable, ShopTable, QSortThenBy> {
  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> thenByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> thenByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> thenByFlagItemId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> thenByFlagItemIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> thenByShopNameLabel({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> thenByShopNameLabelDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension ShopTableQueryWhereDistinct
    on QueryBuilder<ShopTable, ShopTable, QDistinct> {
  QueryBuilder<ShopTable, ShopTable, QAfterDistinct> distinctByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterDistinct> distinctByFlagItemId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterDistinct> distinctByShopNameLabel({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopTable, ShopTable, QAfterDistinct> distinctByItemLabels() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }
}

extension ShopTableQueryProperty1
    on QueryBuilder<ShopTable, ShopTable, QProperty> {
  QueryBuilder<ShopTable, String, QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ShopTable, String, QAfterProperty> flagItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ShopTable, String, QAfterProperty> shopNameLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ShopTable, List<String>, QAfterProperty> itemLabelsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ShopTable, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension ShopTableQueryProperty2<R>
    on QueryBuilder<ShopTable, R, QAfterProperty> {
  QueryBuilder<ShopTable, (R, String), QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ShopTable, (R, String), QAfterProperty> flagItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ShopTable, (R, String), QAfterProperty> shopNameLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ShopTable, (R, List<String>), QAfterProperty>
  itemLabelsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ShopTable, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension ShopTableQueryProperty3<R1, R2>
    on QueryBuilder<ShopTable, (R1, R2), QAfterProperty> {
  QueryBuilder<ShopTable, (R1, R2, String), QOperations> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ShopTable, (R1, R2, String), QOperations> flagItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ShopTable, (R1, R2, String), QOperations>
  shopNameLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ShopTable, (R1, R2, List<String>), QOperations>
  itemLabelsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<ShopTable, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}
