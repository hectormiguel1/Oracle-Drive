// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetStringsCollection on Isar {
  IsarCollection<int, Strings> get strings => this.collection();
}

final StringsSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Strings',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'strResourceId', type: IsarType.string),
      IsarPropertySchema(name: 'value', type: IsarType.string),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'strResourceId',
        properties: ["strResourceId"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, Strings>(
    serialize: serializeStrings,
    deserialize: deserializeStrings,
    deserializeProperty: deserializeStringsProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeStrings(IsarWriter writer, Strings object) {
  IsarCore.writeString(writer, 1, object.strResourceId);
  IsarCore.writeString(writer, 2, object.value);
  return object.id;
}

@isarProtected
Strings deserializeStrings(IsarReader reader) {
  final String _strResourceId;
  _strResourceId = IsarCore.readString(reader, 1) ?? '';
  final String _value;
  _value = IsarCore.readString(reader, 2) ?? '';
  final object = Strings(strResourceId: _strResourceId, value: _value);
  return object;
}

@isarProtected
dynamic deserializeStringsProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _StringsUpdate {
  bool call({required int id, String? strResourceId, String? value});
}

class _StringsUpdateImpl implements _StringsUpdate {
  const _StringsUpdateImpl(this.collection);

  final IsarCollection<int, Strings> collection;

  @override
  bool call({
    required int id,
    Object? strResourceId = ignore,
    Object? value = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (strResourceId != ignore) 1: strResourceId as String?,
            if (value != ignore) 2: value as String?,
          },
        ) >
        0;
  }
}

sealed class _StringsUpdateAll {
  int call({required List<int> id, String? strResourceId, String? value});
}

class _StringsUpdateAllImpl implements _StringsUpdateAll {
  const _StringsUpdateAllImpl(this.collection);

  final IsarCollection<int, Strings> collection;

  @override
  int call({
    required List<int> id,
    Object? strResourceId = ignore,
    Object? value = ignore,
  }) {
    return collection.updateProperties(id, {
      if (strResourceId != ignore) 1: strResourceId as String?,
      if (value != ignore) 2: value as String?,
    });
  }
}

extension StringsUpdate on IsarCollection<int, Strings> {
  _StringsUpdate get update => _StringsUpdateImpl(this);

  _StringsUpdateAll get updateAll => _StringsUpdateAllImpl(this);
}

sealed class _StringsQueryUpdate {
  int call({String? strResourceId, String? value});
}

class _StringsQueryUpdateImpl implements _StringsQueryUpdate {
  const _StringsQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Strings> query;
  final int? limit;

  @override
  int call({Object? strResourceId = ignore, Object? value = ignore}) {
    return query.updateProperties(limit: limit, {
      if (strResourceId != ignore) 1: strResourceId as String?,
      if (value != ignore) 2: value as String?,
    });
  }
}

extension StringsQueryUpdate on IsarQuery<Strings> {
  _StringsQueryUpdate get updateFirst =>
      _StringsQueryUpdateImpl(this, limit: 1);

  _StringsQueryUpdate get updateAll => _StringsQueryUpdateImpl(this);
}

class _StringsQueryBuilderUpdateImpl implements _StringsQueryUpdate {
  const _StringsQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Strings, Strings, QOperations> query;
  final int? limit;

  @override
  int call({Object? strResourceId = ignore, Object? value = ignore}) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (strResourceId != ignore) 1: strResourceId as String?,
        if (value != ignore) 2: value as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension StringsQueryBuilderUpdate
    on QueryBuilder<Strings, Strings, QOperations> {
  _StringsQueryUpdate get updateFirst =>
      _StringsQueryBuilderUpdateImpl(this, limit: 1);

  _StringsQueryUpdate get updateAll => _StringsQueryBuilderUpdateImpl(this);
}

extension StringsQueryFilter
    on QueryBuilder<Strings, Strings, QFilterCondition> {
  QueryBuilder<Strings, Strings, QAfterFilterCondition> strResourceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition>
  strResourceIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition>
  strResourceIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> strResourceIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition>
  strResourceIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> strResourceIdBetween(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> strResourceIdStartsWith(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> strResourceIdEndsWith(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> strResourceIdContains(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> strResourceIdMatches(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> strResourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition>
  strResourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition>
  valueGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueBetween(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueEndsWith(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueContains(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueMatches(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> idBetween(
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

extension StringsQueryObject
    on QueryBuilder<Strings, Strings, QFilterCondition> {}

extension StringsQuerySortBy on QueryBuilder<Strings, Strings, QSortBy> {
  QueryBuilder<Strings, Strings, QAfterSortBy> sortByStrResourceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> sortByStrResourceIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> sortByValue({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> sortByValueDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension StringsQuerySortThenBy
    on QueryBuilder<Strings, Strings, QSortThenBy> {
  QueryBuilder<Strings, Strings, QAfterSortBy> thenByStrResourceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> thenByStrResourceIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> thenByValue({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> thenByValueDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension StringsQueryWhereDistinct
    on QueryBuilder<Strings, Strings, QDistinct> {
  QueryBuilder<Strings, Strings, QAfterDistinct> distinctByStrResourceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterDistinct> distinctByValue({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }
}

extension StringsQueryProperty1 on QueryBuilder<Strings, Strings, QProperty> {
  QueryBuilder<Strings, String, QAfterProperty> strResourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Strings, String, QAfterProperty> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Strings, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension StringsQueryProperty2<R> on QueryBuilder<Strings, R, QAfterProperty> {
  QueryBuilder<Strings, (R, String), QAfterProperty> strResourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Strings, (R, String), QAfterProperty> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Strings, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension StringsQueryProperty3<R1, R2>
    on QueryBuilder<Strings, (R1, R2), QAfterProperty> {
  QueryBuilder<Strings, (R1, R2, String), QOperations> strResourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Strings, (R1, R2, String), QOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Strings, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetItemCollection on Isar {
  IsarCollection<int, Item> get items => this.collection();
}

final ItemSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Item',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'record', type: IsarType.string),
      IsarPropertySchema(name: 'itemNameStringId', type: IsarType.string),
      IsarPropertySchema(name: 'helpStringId', type: IsarType.string),
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
  converter: IsarObjectConverter<int, Item>(
    serialize: serializeItem,
    deserialize: deserializeItem,
    deserializeProperty: deserializeItemProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeItem(IsarWriter writer, Item object) {
  IsarCore.writeString(writer, 1, object.record);
  IsarCore.writeString(writer, 2, object.itemNameStringId);
  IsarCore.writeString(writer, 3, object.helpStringId);
  return object.id;
}

@isarProtected
Item deserializeItem(IsarReader reader) {
  final String _record;
  _record = IsarCore.readString(reader, 1) ?? '';
  final String _itemNameStringId;
  _itemNameStringId = IsarCore.readString(reader, 2) ?? '';
  final String _helpStringId;
  _helpStringId = IsarCore.readString(reader, 3) ?? '';
  final object = Item(
    record: _record,
    itemNameStringId: _itemNameStringId,
    helpStringId: _helpStringId,
  );
  return object;
}

@isarProtected
dynamic deserializeItemProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _ItemUpdate {
  bool call({
    required int id,
    String? record,
    String? itemNameStringId,
    String? helpStringId,
  });
}

class _ItemUpdateImpl implements _ItemUpdate {
  const _ItemUpdateImpl(this.collection);

  final IsarCollection<int, Item> collection;

  @override
  bool call({
    required int id,
    Object? record = ignore,
    Object? itemNameStringId = ignore,
    Object? helpStringId = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (record != ignore) 1: record as String?,
            if (itemNameStringId != ignore) 2: itemNameStringId as String?,
            if (helpStringId != ignore) 3: helpStringId as String?,
          },
        ) >
        0;
  }
}

sealed class _ItemUpdateAll {
  int call({
    required List<int> id,
    String? record,
    String? itemNameStringId,
    String? helpStringId,
  });
}

class _ItemUpdateAllImpl implements _ItemUpdateAll {
  const _ItemUpdateAllImpl(this.collection);

  final IsarCollection<int, Item> collection;

  @override
  int call({
    required List<int> id,
    Object? record = ignore,
    Object? itemNameStringId = ignore,
    Object? helpStringId = ignore,
  }) {
    return collection.updateProperties(id, {
      if (record != ignore) 1: record as String?,
      if (itemNameStringId != ignore) 2: itemNameStringId as String?,
      if (helpStringId != ignore) 3: helpStringId as String?,
    });
  }
}

extension ItemUpdate on IsarCollection<int, Item> {
  _ItemUpdate get update => _ItemUpdateImpl(this);

  _ItemUpdateAll get updateAll => _ItemUpdateAllImpl(this);
}

sealed class _ItemQueryUpdate {
  int call({String? record, String? itemNameStringId, String? helpStringId});
}

class _ItemQueryUpdateImpl implements _ItemQueryUpdate {
  const _ItemQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Item> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? itemNameStringId = ignore,
    Object? helpStringId = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (record != ignore) 1: record as String?,
      if (itemNameStringId != ignore) 2: itemNameStringId as String?,
      if (helpStringId != ignore) 3: helpStringId as String?,
    });
  }
}

extension ItemQueryUpdate on IsarQuery<Item> {
  _ItemQueryUpdate get updateFirst => _ItemQueryUpdateImpl(this, limit: 1);

  _ItemQueryUpdate get updateAll => _ItemQueryUpdateImpl(this);
}

class _ItemQueryBuilderUpdateImpl implements _ItemQueryUpdate {
  const _ItemQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Item, Item, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? itemNameStringId = ignore,
    Object? helpStringId = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (record != ignore) 1: record as String?,
        if (itemNameStringId != ignore) 2: itemNameStringId as String?,
        if (helpStringId != ignore) 3: helpStringId as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension ItemQueryBuilderUpdate on QueryBuilder<Item, Item, QOperations> {
  _ItemQueryUpdate get updateFirst =>
      _ItemQueryBuilderUpdateImpl(this, limit: 1);

  _ItemQueryUpdate get updateAll => _ItemQueryBuilderUpdateImpl(this);
}

extension ItemQueryFilter on QueryBuilder<Item, Item, QFilterCondition> {
  QueryBuilder<Item, Item, QAfterFilterCondition> recordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> recordGreaterThan(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> recordGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> recordLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> recordLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> recordBetween(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> recordStartsWith(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> recordEndsWith(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> recordContains(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> recordMatches(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> recordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> recordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition>
  itemNameStringIdGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  itemNameStringIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdBetween(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdEndsWith(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdContains(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdMatches(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> itemNameStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition>
  helpStringIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdBetween(
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

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> helpStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idBetween(
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

extension ItemQueryObject on QueryBuilder<Item, Item, QFilterCondition> {}

extension ItemQuerySortBy on QueryBuilder<Item, Item, QSortBy> {
  QueryBuilder<Item, Item, QAfterSortBy> sortByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByItemNameStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByItemNameStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByHelpStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByHelpStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension ItemQuerySortThenBy on QueryBuilder<Item, Item, QSortThenBy> {
  QueryBuilder<Item, Item, QAfterSortBy> thenByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByItemNameStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByItemNameStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByHelpStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByHelpStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension ItemQueryWhereDistinct on QueryBuilder<Item, Item, QDistinct> {
  QueryBuilder<Item, Item, QAfterDistinct> distinctByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByItemNameStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByHelpStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }
}

extension ItemQueryProperty1 on QueryBuilder<Item, Item, QProperty> {
  QueryBuilder<Item, String, QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Item, String, QAfterProperty> itemNameStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Item, String, QAfterProperty> helpStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Item, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension ItemQueryProperty2<R> on QueryBuilder<Item, R, QAfterProperty> {
  QueryBuilder<Item, (R, String), QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Item, (R, String), QAfterProperty> itemNameStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Item, (R, String), QAfterProperty> helpStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Item, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension ItemQueryProperty3<R1, R2>
    on QueryBuilder<Item, (R1, R2), QAfterProperty> {
  QueryBuilder<Item, (R1, R2, String), QOperations> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Item, (R1, R2, String), QOperations> itemNameStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Item, (R1, R2, String), QOperations> helpStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Item, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetBattleAbilityCollection on Isar {
  IsarCollection<int, BattleAbility> get battleAbilitys => this.collection();
}

final BattleAbilitySchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'BattleAbility',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'record', type: IsarType.string),
      IsarPropertySchema(name: 'stringResId', type: IsarType.string),
      IsarPropertySchema(name: 'infoStResId', type: IsarType.string),
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
  converter: IsarObjectConverter<int, BattleAbility>(
    serialize: serializeBattleAbility,
    deserialize: deserializeBattleAbility,
    deserializeProperty: deserializeBattleAbilityProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeBattleAbility(IsarWriter writer, BattleAbility object) {
  IsarCore.writeString(writer, 1, object.record);
  IsarCore.writeString(writer, 2, object.stringResId);
  IsarCore.writeString(writer, 3, object.infoStResId);
  return object.id;
}

@isarProtected
BattleAbility deserializeBattleAbility(IsarReader reader) {
  final String _record;
  _record = IsarCore.readString(reader, 1) ?? '';
  final String _stringResId;
  _stringResId = IsarCore.readString(reader, 2) ?? '';
  final String _infoStResId;
  _infoStResId = IsarCore.readString(reader, 3) ?? '';
  final object = BattleAbility(
    record: _record,
    stringResId: _stringResId,
    infoStResId: _infoStResId,
  );
  return object;
}

@isarProtected
dynamic deserializeBattleAbilityProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _BattleAbilityUpdate {
  bool call({
    required int id,
    String? record,
    String? stringResId,
    String? infoStResId,
  });
}

class _BattleAbilityUpdateImpl implements _BattleAbilityUpdate {
  const _BattleAbilityUpdateImpl(this.collection);

  final IsarCollection<int, BattleAbility> collection;

  @override
  bool call({
    required int id,
    Object? record = ignore,
    Object? stringResId = ignore,
    Object? infoStResId = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (record != ignore) 1: record as String?,
            if (stringResId != ignore) 2: stringResId as String?,
            if (infoStResId != ignore) 3: infoStResId as String?,
          },
        ) >
        0;
  }
}

sealed class _BattleAbilityUpdateAll {
  int call({
    required List<int> id,
    String? record,
    String? stringResId,
    String? infoStResId,
  });
}

class _BattleAbilityUpdateAllImpl implements _BattleAbilityUpdateAll {
  const _BattleAbilityUpdateAllImpl(this.collection);

  final IsarCollection<int, BattleAbility> collection;

  @override
  int call({
    required List<int> id,
    Object? record = ignore,
    Object? stringResId = ignore,
    Object? infoStResId = ignore,
  }) {
    return collection.updateProperties(id, {
      if (record != ignore) 1: record as String?,
      if (stringResId != ignore) 2: stringResId as String?,
      if (infoStResId != ignore) 3: infoStResId as String?,
    });
  }
}

extension BattleAbilityUpdate on IsarCollection<int, BattleAbility> {
  _BattleAbilityUpdate get update => _BattleAbilityUpdateImpl(this);

  _BattleAbilityUpdateAll get updateAll => _BattleAbilityUpdateAllImpl(this);
}

sealed class _BattleAbilityQueryUpdate {
  int call({String? record, String? stringResId, String? infoStResId});
}

class _BattleAbilityQueryUpdateImpl implements _BattleAbilityQueryUpdate {
  const _BattleAbilityQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<BattleAbility> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? stringResId = ignore,
    Object? infoStResId = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (record != ignore) 1: record as String?,
      if (stringResId != ignore) 2: stringResId as String?,
      if (infoStResId != ignore) 3: infoStResId as String?,
    });
  }
}

extension BattleAbilityQueryUpdate on IsarQuery<BattleAbility> {
  _BattleAbilityQueryUpdate get updateFirst =>
      _BattleAbilityQueryUpdateImpl(this, limit: 1);

  _BattleAbilityQueryUpdate get updateAll =>
      _BattleAbilityQueryUpdateImpl(this);
}

class _BattleAbilityQueryBuilderUpdateImpl
    implements _BattleAbilityQueryUpdate {
  const _BattleAbilityQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<BattleAbility, BattleAbility, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? stringResId = ignore,
    Object? infoStResId = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (record != ignore) 1: record as String?,
        if (stringResId != ignore) 2: stringResId as String?,
        if (infoStResId != ignore) 3: infoStResId as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension BattleAbilityQueryBuilderUpdate
    on QueryBuilder<BattleAbility, BattleAbility, QOperations> {
  _BattleAbilityQueryUpdate get updateFirst =>
      _BattleAbilityQueryBuilderUpdateImpl(this, limit: 1);

  _BattleAbilityQueryUpdate get updateAll =>
      _BattleAbilityQueryBuilderUpdateImpl(this);
}

extension BattleAbilityQueryFilter
    on QueryBuilder<BattleAbility, BattleAbility, QFilterCondition> {
  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  recordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  stringResIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  infoStResIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterFilterCondition> idBetween(
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

extension BattleAbilityQueryObject
    on QueryBuilder<BattleAbility, BattleAbility, QFilterCondition> {}

extension BattleAbilityQuerySortBy
    on QueryBuilder<BattleAbility, BattleAbility, QSortBy> {
  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> sortByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> sortByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> sortByStringResId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy>
  sortByStringResIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> sortByInfoStResId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy>
  sortByInfoStResIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension BattleAbilityQuerySortThenBy
    on QueryBuilder<BattleAbility, BattleAbility, QSortThenBy> {
  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> thenByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> thenByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> thenByStringResId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy>
  thenByStringResIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> thenByInfoStResId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy>
  thenByInfoStResIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension BattleAbilityQueryWhereDistinct
    on QueryBuilder<BattleAbility, BattleAbility, QDistinct> {
  QueryBuilder<BattleAbility, BattleAbility, QAfterDistinct> distinctByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterDistinct>
  distinctByStringResId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAbility, BattleAbility, QAfterDistinct>
  distinctByInfoStResId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }
}

extension BattleAbilityQueryProperty1
    on QueryBuilder<BattleAbility, BattleAbility, QProperty> {
  QueryBuilder<BattleAbility, String, QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<BattleAbility, String, QAfterProperty> stringResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<BattleAbility, String, QAfterProperty> infoStResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<BattleAbility, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension BattleAbilityQueryProperty2<R>
    on QueryBuilder<BattleAbility, R, QAfterProperty> {
  QueryBuilder<BattleAbility, (R, String), QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<BattleAbility, (R, String), QAfterProperty>
  stringResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<BattleAbility, (R, String), QAfterProperty>
  infoStResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<BattleAbility, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension BattleAbilityQueryProperty3<R1, R2>
    on QueryBuilder<BattleAbility, (R1, R2), QAfterProperty> {
  QueryBuilder<BattleAbility, (R1, R2, String), QOperations> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<BattleAbility, (R1, R2, String), QOperations>
  stringResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<BattleAbility, (R1, R2, String), QOperations>
  infoStResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<BattleAbility, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetBattleAutoAbilityCollection on Isar {
  IsarCollection<int, BattleAutoAbility> get battleAutoAbilitys =>
      this.collection();
}

final BattleAutoAbilitySchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'BattleAutoAbility',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'record', type: IsarType.string),
      IsarPropertySchema(name: 'stringResId', type: IsarType.string),
      IsarPropertySchema(name: 'infoStResId', type: IsarType.string),
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
  converter: IsarObjectConverter<int, BattleAutoAbility>(
    serialize: serializeBattleAutoAbility,
    deserialize: deserializeBattleAutoAbility,
    deserializeProperty: deserializeBattleAutoAbilityProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeBattleAutoAbility(IsarWriter writer, BattleAutoAbility object) {
  IsarCore.writeString(writer, 1, object.record);
  IsarCore.writeString(writer, 2, object.stringResId);
  IsarCore.writeString(writer, 3, object.infoStResId);
  return object.id;
}

@isarProtected
BattleAutoAbility deserializeBattleAutoAbility(IsarReader reader) {
  final String _record;
  _record = IsarCore.readString(reader, 1) ?? '';
  final String _stringResId;
  _stringResId = IsarCore.readString(reader, 2) ?? '';
  final String _infoStResId;
  _infoStResId = IsarCore.readString(reader, 3) ?? '';
  final object = BattleAutoAbility(
    record: _record,
    stringResId: _stringResId,
    infoStResId: _infoStResId,
  );
  return object;
}

@isarProtected
dynamic deserializeBattleAutoAbilityProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _BattleAutoAbilityUpdate {
  bool call({
    required int id,
    String? record,
    String? stringResId,
    String? infoStResId,
  });
}

class _BattleAutoAbilityUpdateImpl implements _BattleAutoAbilityUpdate {
  const _BattleAutoAbilityUpdateImpl(this.collection);

  final IsarCollection<int, BattleAutoAbility> collection;

  @override
  bool call({
    required int id,
    Object? record = ignore,
    Object? stringResId = ignore,
    Object? infoStResId = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (record != ignore) 1: record as String?,
            if (stringResId != ignore) 2: stringResId as String?,
            if (infoStResId != ignore) 3: infoStResId as String?,
          },
        ) >
        0;
  }
}

sealed class _BattleAutoAbilityUpdateAll {
  int call({
    required List<int> id,
    String? record,
    String? stringResId,
    String? infoStResId,
  });
}

class _BattleAutoAbilityUpdateAllImpl implements _BattleAutoAbilityUpdateAll {
  const _BattleAutoAbilityUpdateAllImpl(this.collection);

  final IsarCollection<int, BattleAutoAbility> collection;

  @override
  int call({
    required List<int> id,
    Object? record = ignore,
    Object? stringResId = ignore,
    Object? infoStResId = ignore,
  }) {
    return collection.updateProperties(id, {
      if (record != ignore) 1: record as String?,
      if (stringResId != ignore) 2: stringResId as String?,
      if (infoStResId != ignore) 3: infoStResId as String?,
    });
  }
}

extension BattleAutoAbilityUpdate on IsarCollection<int, BattleAutoAbility> {
  _BattleAutoAbilityUpdate get update => _BattleAutoAbilityUpdateImpl(this);

  _BattleAutoAbilityUpdateAll get updateAll =>
      _BattleAutoAbilityUpdateAllImpl(this);
}

sealed class _BattleAutoAbilityQueryUpdate {
  int call({String? record, String? stringResId, String? infoStResId});
}

class _BattleAutoAbilityQueryUpdateImpl
    implements _BattleAutoAbilityQueryUpdate {
  const _BattleAutoAbilityQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<BattleAutoAbility> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? stringResId = ignore,
    Object? infoStResId = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (record != ignore) 1: record as String?,
      if (stringResId != ignore) 2: stringResId as String?,
      if (infoStResId != ignore) 3: infoStResId as String?,
    });
  }
}

extension BattleAutoAbilityQueryUpdate on IsarQuery<BattleAutoAbility> {
  _BattleAutoAbilityQueryUpdate get updateFirst =>
      _BattleAutoAbilityQueryUpdateImpl(this, limit: 1);

  _BattleAutoAbilityQueryUpdate get updateAll =>
      _BattleAutoAbilityQueryUpdateImpl(this);
}

class _BattleAutoAbilityQueryBuilderUpdateImpl
    implements _BattleAutoAbilityQueryUpdate {
  const _BattleAutoAbilityQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<BattleAutoAbility, BattleAutoAbility, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? stringResId = ignore,
    Object? infoStResId = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (record != ignore) 1: record as String?,
        if (stringResId != ignore) 2: stringResId as String?,
        if (infoStResId != ignore) 3: infoStResId as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension BattleAutoAbilityQueryBuilderUpdate
    on QueryBuilder<BattleAutoAbility, BattleAutoAbility, QOperations> {
  _BattleAutoAbilityQueryUpdate get updateFirst =>
      _BattleAutoAbilityQueryBuilderUpdateImpl(this, limit: 1);

  _BattleAutoAbilityQueryUpdate get updateAll =>
      _BattleAutoAbilityQueryBuilderUpdateImpl(this);
}

extension BattleAutoAbilityQueryFilter
    on QueryBuilder<BattleAutoAbility, BattleAutoAbility, QFilterCondition> {
  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  recordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  stringResIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  infoStResIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterFilterCondition>
  idBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }
}

extension BattleAutoAbilityQueryObject
    on QueryBuilder<BattleAutoAbility, BattleAutoAbility, QFilterCondition> {}

extension BattleAutoAbilityQuerySortBy
    on QueryBuilder<BattleAutoAbility, BattleAutoAbility, QSortBy> {
  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  sortByRecord({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  sortByRecordDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  sortByStringResId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  sortByStringResIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  sortByInfoStResId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  sortByInfoStResIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension BattleAutoAbilityQuerySortThenBy
    on QueryBuilder<BattleAutoAbility, BattleAutoAbility, QSortThenBy> {
  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  thenByRecord({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  thenByRecordDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  thenByStringResId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  thenByStringResIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  thenByInfoStResId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  thenByInfoStResIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension BattleAutoAbilityQueryWhereDistinct
    on QueryBuilder<BattleAutoAbility, BattleAutoAbility, QDistinct> {
  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterDistinct>
  distinctByRecord({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterDistinct>
  distinctByStringResId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BattleAutoAbility, BattleAutoAbility, QAfterDistinct>
  distinctByInfoStResId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }
}

extension BattleAutoAbilityQueryProperty1
    on QueryBuilder<BattleAutoAbility, BattleAutoAbility, QProperty> {
  QueryBuilder<BattleAutoAbility, String, QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<BattleAutoAbility, String, QAfterProperty>
  stringResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<BattleAutoAbility, String, QAfterProperty>
  infoStResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<BattleAutoAbility, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension BattleAutoAbilityQueryProperty2<R>
    on QueryBuilder<BattleAutoAbility, R, QAfterProperty> {
  QueryBuilder<BattleAutoAbility, (R, String), QAfterProperty>
  recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<BattleAutoAbility, (R, String), QAfterProperty>
  stringResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<BattleAutoAbility, (R, String), QAfterProperty>
  infoStResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<BattleAutoAbility, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension BattleAutoAbilityQueryProperty3<R1, R2>
    on QueryBuilder<BattleAutoAbility, (R1, R2), QAfterProperty> {
  QueryBuilder<BattleAutoAbility, (R1, R2, String), QOperations>
  recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<BattleAutoAbility, (R1, R2, String), QOperations>
  stringResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<BattleAutoAbility, (R1, R2, String), QOperations>
  infoStResIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<BattleAutoAbility, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}
