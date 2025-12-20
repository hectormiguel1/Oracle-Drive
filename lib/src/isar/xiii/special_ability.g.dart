// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'special_ability.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetSpecialAbilityCollection on Isar {
  IsarCollection<int, SpecialAbility> get specialAbilitys => this.collection();
}

final SpecialAbilitySchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'SpecialAbility',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'record', type: IsarType.string),
      IsarPropertySchema(name: 'ability', type: IsarType.string),
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
  converter: IsarObjectConverter<int, SpecialAbility>(
    serialize: serializeSpecialAbility,
    deserialize: deserializeSpecialAbility,
    deserializeProperty: deserializeSpecialAbilityProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeSpecialAbility(IsarWriter writer, SpecialAbility object) {
  IsarCore.writeString(writer, 1, object.record);
  IsarCore.writeString(writer, 2, object.ability);
  return object.id;
}

@isarProtected
SpecialAbility deserializeSpecialAbility(IsarReader reader) {
  final String _record;
  _record = IsarCore.readString(reader, 1) ?? '';
  final String _ability;
  _ability = IsarCore.readString(reader, 2) ?? '';
  final object = SpecialAbility(record: _record, ability: _ability);
  return object;
}

@isarProtected
dynamic deserializeSpecialAbilityProp(IsarReader reader, int property) {
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

sealed class _SpecialAbilityUpdate {
  bool call({required int id, String? record, String? ability});
}

class _SpecialAbilityUpdateImpl implements _SpecialAbilityUpdate {
  const _SpecialAbilityUpdateImpl(this.collection);

  final IsarCollection<int, SpecialAbility> collection;

  @override
  bool call({
    required int id,
    Object? record = ignore,
    Object? ability = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (record != ignore) 1: record as String?,
            if (ability != ignore) 2: ability as String?,
          },
        ) >
        0;
  }
}

sealed class _SpecialAbilityUpdateAll {
  int call({required List<int> id, String? record, String? ability});
}

class _SpecialAbilityUpdateAllImpl implements _SpecialAbilityUpdateAll {
  const _SpecialAbilityUpdateAllImpl(this.collection);

  final IsarCollection<int, SpecialAbility> collection;

  @override
  int call({
    required List<int> id,
    Object? record = ignore,
    Object? ability = ignore,
  }) {
    return collection.updateProperties(id, {
      if (record != ignore) 1: record as String?,
      if (ability != ignore) 2: ability as String?,
    });
  }
}

extension SpecialAbilityUpdate on IsarCollection<int, SpecialAbility> {
  _SpecialAbilityUpdate get update => _SpecialAbilityUpdateImpl(this);

  _SpecialAbilityUpdateAll get updateAll => _SpecialAbilityUpdateAllImpl(this);
}

sealed class _SpecialAbilityQueryUpdate {
  int call({String? record, String? ability});
}

class _SpecialAbilityQueryUpdateImpl implements _SpecialAbilityQueryUpdate {
  const _SpecialAbilityQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<SpecialAbility> query;
  final int? limit;

  @override
  int call({Object? record = ignore, Object? ability = ignore}) {
    return query.updateProperties(limit: limit, {
      if (record != ignore) 1: record as String?,
      if (ability != ignore) 2: ability as String?,
    });
  }
}

extension SpecialAbilityQueryUpdate on IsarQuery<SpecialAbility> {
  _SpecialAbilityQueryUpdate get updateFirst =>
      _SpecialAbilityQueryUpdateImpl(this, limit: 1);

  _SpecialAbilityQueryUpdate get updateAll =>
      _SpecialAbilityQueryUpdateImpl(this);
}

class _SpecialAbilityQueryBuilderUpdateImpl
    implements _SpecialAbilityQueryUpdate {
  const _SpecialAbilityQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<SpecialAbility, SpecialAbility, QOperations> query;
  final int? limit;

  @override
  int call({Object? record = ignore, Object? ability = ignore}) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (record != ignore) 1: record as String?,
        if (ability != ignore) 2: ability as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension SpecialAbilityQueryBuilderUpdate
    on QueryBuilder<SpecialAbility, SpecialAbility, QOperations> {
  _SpecialAbilityQueryUpdate get updateFirst =>
      _SpecialAbilityQueryBuilderUpdateImpl(this, limit: 1);

  _SpecialAbilityQueryUpdate get updateAll =>
      _SpecialAbilityQueryBuilderUpdateImpl(this);
}

extension SpecialAbilityQueryFilter
    on QueryBuilder<SpecialAbility, SpecialAbility, QFilterCondition> {
  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  recordEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  recordLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  recordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  recordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  abilityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterFilterCondition> idBetween(
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

extension SpecialAbilityQueryObject
    on QueryBuilder<SpecialAbility, SpecialAbility, QFilterCondition> {}

extension SpecialAbilityQuerySortBy
    on QueryBuilder<SpecialAbility, SpecialAbility, QSortBy> {
  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> sortByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> sortByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> sortByAbility({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> sortByAbilityDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension SpecialAbilityQuerySortThenBy
    on QueryBuilder<SpecialAbility, SpecialAbility, QSortThenBy> {
  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> thenByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> thenByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> thenByAbility({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> thenByAbilityDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension SpecialAbilityQueryWhereDistinct
    on QueryBuilder<SpecialAbility, SpecialAbility, QDistinct> {
  QueryBuilder<SpecialAbility, SpecialAbility, QAfterDistinct>
  distinctByRecord({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpecialAbility, SpecialAbility, QAfterDistinct>
  distinctByAbility({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }
}

extension SpecialAbilityQueryProperty1
    on QueryBuilder<SpecialAbility, SpecialAbility, QProperty> {
  QueryBuilder<SpecialAbility, String, QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<SpecialAbility, String, QAfterProperty> abilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<SpecialAbility, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension SpecialAbilityQueryProperty2<R>
    on QueryBuilder<SpecialAbility, R, QAfterProperty> {
  QueryBuilder<SpecialAbility, (R, String), QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<SpecialAbility, (R, String), QAfterProperty> abilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<SpecialAbility, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension SpecialAbilityQueryProperty3<R1, R2>
    on QueryBuilder<SpecialAbility, (R1, R2), QAfterProperty> {
  QueryBuilder<SpecialAbility, (R1, R2, String), QOperations> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<SpecialAbility, (R1, R2, String), QOperations>
  abilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<SpecialAbility, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}
