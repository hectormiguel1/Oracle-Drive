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
      IsarPropertySchema(name: 'sourceFile', type: IsarType.string),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'strResourceId',
        properties: ["strResourceId"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'sourceFile',
        properties: ["sourceFile"],
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
  {
    final value = object.sourceFile;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      IsarCore.writeString(writer, 3, value);
    }
  }
  return object.id;
}

@isarProtected
Strings deserializeStrings(IsarReader reader) {
  final String _strResourceId;
  _strResourceId = IsarCore.readString(reader, 1) ?? '';
  final String _value;
  _value = IsarCore.readString(reader, 2) ?? '';
  final String? _sourceFile;
  _sourceFile = IsarCore.readString(reader, 3);
  final object = Strings(
    strResourceId: _strResourceId,
    value: _value,
    sourceFile: _sourceFile,
  );
  return object;
}

@isarProtected
dynamic deserializeStringsProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3);
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _StringsUpdate {
  bool call({
    required int id,
    String? strResourceId,
    String? value,
    String? sourceFile,
  });
}

class _StringsUpdateImpl implements _StringsUpdate {
  const _StringsUpdateImpl(this.collection);

  final IsarCollection<int, Strings> collection;

  @override
  bool call({
    required int id,
    Object? strResourceId = ignore,
    Object? value = ignore,
    Object? sourceFile = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (strResourceId != ignore) 1: strResourceId as String?,
            if (value != ignore) 2: value as String?,
            if (sourceFile != ignore) 3: sourceFile as String?,
          },
        ) >
        0;
  }
}

sealed class _StringsUpdateAll {
  int call({
    required List<int> id,
    String? strResourceId,
    String? value,
    String? sourceFile,
  });
}

class _StringsUpdateAllImpl implements _StringsUpdateAll {
  const _StringsUpdateAllImpl(this.collection);

  final IsarCollection<int, Strings> collection;

  @override
  int call({
    required List<int> id,
    Object? strResourceId = ignore,
    Object? value = ignore,
    Object? sourceFile = ignore,
  }) {
    return collection.updateProperties(id, {
      if (strResourceId != ignore) 1: strResourceId as String?,
      if (value != ignore) 2: value as String?,
      if (sourceFile != ignore) 3: sourceFile as String?,
    });
  }
}

extension StringsUpdate on IsarCollection<int, Strings> {
  _StringsUpdate get update => _StringsUpdateImpl(this);

  _StringsUpdateAll get updateAll => _StringsUpdateAllImpl(this);
}

sealed class _StringsQueryUpdate {
  int call({String? strResourceId, String? value, String? sourceFile});
}

class _StringsQueryUpdateImpl implements _StringsQueryUpdate {
  const _StringsQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Strings> query;
  final int? limit;

  @override
  int call({
    Object? strResourceId = ignore,
    Object? value = ignore,
    Object? sourceFile = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (strResourceId != ignore) 1: strResourceId as String?,
      if (value != ignore) 2: value as String?,
      if (sourceFile != ignore) 3: sourceFile as String?,
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
  int call({
    Object? strResourceId = ignore,
    Object? value = ignore,
    Object? sourceFile = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (strResourceId != ignore) 1: strResourceId as String?,
        if (value != ignore) 2: value as String?,
        if (sourceFile != ignore) 3: sourceFile as String?,
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileGreaterThan(
    String? value, {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition>
  sourceFileGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition>
  sourceFileLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileStartsWith(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileEndsWith(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileContains(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileMatches(
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

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<Strings, Strings, QAfterFilterCondition> sourceFileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
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

  QueryBuilder<Strings, Strings, QAfterSortBy> sortBySourceFile({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> sortBySourceFileDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
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

  QueryBuilder<Strings, Strings, QAfterSortBy> thenBySourceFile({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Strings, Strings, QAfterSortBy> thenBySourceFileDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
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

  QueryBuilder<Strings, Strings, QAfterDistinct> distinctBySourceFile({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
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

  QueryBuilder<Strings, String?, QAfterProperty> sourceFileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
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

  QueryBuilder<Strings, (R, String?), QAfterProperty> sourceFileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
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

  QueryBuilder<Strings, (R1, R2, String?), QOperations> sourceFileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
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

extension GetEntityLookupCollection on Isar {
  IsarCollection<int, EntityLookup> get entityLookups => this.collection();
}

final EntityLookupSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'EntityLookup',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'category', type: IsarType.string),
      IsarPropertySchema(name: 'record', type: IsarType.string),
      IsarPropertySchema(name: 'nameStringId', type: IsarType.string),
      IsarPropertySchema(name: 'descriptionStringId', type: IsarType.string),
      IsarPropertySchema(name: 'extraKeys', type: IsarType.stringList),
      IsarPropertySchema(name: 'extraValues', type: IsarType.stringList),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'category',
        properties: ["category"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'record',
        properties: ["record"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, EntityLookup>(
    serialize: serializeEntityLookup,
    deserialize: deserializeEntityLookup,
    deserializeProperty: deserializeEntityLookupProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeEntityLookup(IsarWriter writer, EntityLookup object) {
  IsarCore.writeString(writer, 1, object.category);
  IsarCore.writeString(writer, 2, object.record);
  {
    final value = object.nameStringId;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      IsarCore.writeString(writer, 3, value);
    }
  }
  {
    final value = object.descriptionStringId;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      IsarCore.writeString(writer, 4, value);
    }
  }
  {
    final list = object.extraKeys;
    if (list == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      final listWriter = IsarCore.beginList(writer, 5, list.length);
      for (var i = 0; i < list.length; i++) {
        IsarCore.writeString(listWriter, i, list[i]);
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  {
    final list = object.extraValues;
    if (list == null) {
      IsarCore.writeNull(writer, 6);
    } else {
      final listWriter = IsarCore.beginList(writer, 6, list.length);
      for (var i = 0; i < list.length; i++) {
        IsarCore.writeString(listWriter, i, list[i]);
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  return object.id;
}

@isarProtected
EntityLookup deserializeEntityLookup(IsarReader reader) {
  final String _category;
  _category = IsarCore.readString(reader, 1) ?? '';
  final String _record;
  _record = IsarCore.readString(reader, 2) ?? '';
  final String? _nameStringId;
  _nameStringId = IsarCore.readString(reader, 3);
  final String? _descriptionStringId;
  _descriptionStringId = IsarCore.readString(reader, 4);
  final List<String>? _extraKeys;
  {
    final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _extraKeys = null;
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        _extraKeys = list;
      }
    }
  }
  final List<String>? _extraValues;
  {
    final length = IsarCore.readList(reader, 6, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _extraValues = null;
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        _extraValues = list;
      }
    }
  }
  final object = EntityLookup(
    category: _category,
    record: _record,
    nameStringId: _nameStringId,
    descriptionStringId: _descriptionStringId,
    extraKeys: _extraKeys,
    extraValues: _extraValues,
  );
  return object;
}

@isarProtected
dynamic deserializeEntityLookupProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3);
    case 4:
      return IsarCore.readString(reader, 4);
    case 5:
      {
        final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return null;
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
    case 6:
      {
        final length = IsarCore.readList(reader, 6, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return null;
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

sealed class _EntityLookupUpdate {
  bool call({
    required int id,
    String? category,
    String? record,
    String? nameStringId,
    String? descriptionStringId,
  });
}

class _EntityLookupUpdateImpl implements _EntityLookupUpdate {
  const _EntityLookupUpdateImpl(this.collection);

  final IsarCollection<int, EntityLookup> collection;

  @override
  bool call({
    required int id,
    Object? category = ignore,
    Object? record = ignore,
    Object? nameStringId = ignore,
    Object? descriptionStringId = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (category != ignore) 1: category as String?,
            if (record != ignore) 2: record as String?,
            if (nameStringId != ignore) 3: nameStringId as String?,
            if (descriptionStringId != ignore)
              4: descriptionStringId as String?,
          },
        ) >
        0;
  }
}

sealed class _EntityLookupUpdateAll {
  int call({
    required List<int> id,
    String? category,
    String? record,
    String? nameStringId,
    String? descriptionStringId,
  });
}

class _EntityLookupUpdateAllImpl implements _EntityLookupUpdateAll {
  const _EntityLookupUpdateAllImpl(this.collection);

  final IsarCollection<int, EntityLookup> collection;

  @override
  int call({
    required List<int> id,
    Object? category = ignore,
    Object? record = ignore,
    Object? nameStringId = ignore,
    Object? descriptionStringId = ignore,
  }) {
    return collection.updateProperties(id, {
      if (category != ignore) 1: category as String?,
      if (record != ignore) 2: record as String?,
      if (nameStringId != ignore) 3: nameStringId as String?,
      if (descriptionStringId != ignore) 4: descriptionStringId as String?,
    });
  }
}

extension EntityLookupUpdate on IsarCollection<int, EntityLookup> {
  _EntityLookupUpdate get update => _EntityLookupUpdateImpl(this);

  _EntityLookupUpdateAll get updateAll => _EntityLookupUpdateAllImpl(this);
}

sealed class _EntityLookupQueryUpdate {
  int call({
    String? category,
    String? record,
    String? nameStringId,
    String? descriptionStringId,
  });
}

class _EntityLookupQueryUpdateImpl implements _EntityLookupQueryUpdate {
  const _EntityLookupQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<EntityLookup> query;
  final int? limit;

  @override
  int call({
    Object? category = ignore,
    Object? record = ignore,
    Object? nameStringId = ignore,
    Object? descriptionStringId = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (category != ignore) 1: category as String?,
      if (record != ignore) 2: record as String?,
      if (nameStringId != ignore) 3: nameStringId as String?,
      if (descriptionStringId != ignore) 4: descriptionStringId as String?,
    });
  }
}

extension EntityLookupQueryUpdate on IsarQuery<EntityLookup> {
  _EntityLookupQueryUpdate get updateFirst =>
      _EntityLookupQueryUpdateImpl(this, limit: 1);

  _EntityLookupQueryUpdate get updateAll => _EntityLookupQueryUpdateImpl(this);
}

class _EntityLookupQueryBuilderUpdateImpl implements _EntityLookupQueryUpdate {
  const _EntityLookupQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<EntityLookup, EntityLookup, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? category = ignore,
    Object? record = ignore,
    Object? nameStringId = ignore,
    Object? descriptionStringId = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (category != ignore) 1: category as String?,
        if (record != ignore) 2: record as String?,
        if (nameStringId != ignore) 3: nameStringId as String?,
        if (descriptionStringId != ignore) 4: descriptionStringId as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension EntityLookupQueryBuilderUpdate
    on QueryBuilder<EntityLookup, EntityLookup, QOperations> {
  _EntityLookupQueryUpdate get updateFirst =>
      _EntityLookupQueryBuilderUpdateImpl(this, limit: 1);

  _EntityLookupQueryUpdate get updateAll =>
      _EntityLookupQueryBuilderUpdateImpl(this);
}

extension EntityLookupQueryFilter
    on QueryBuilder<EntityLookup, EntityLookup, QFilterCondition> {
  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition> recordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition> recordBetween(
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition> recordMatches(
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  recordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdGreaterThan(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  nameStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdGreaterThan(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdGreaterThanOrEqualTo(
    String? value, {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdLessThanOrEqualTo(
    String? value, {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  descriptionStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysIsEmpty() {
    return not().group((q) => q.extraKeysIsNull().or().extraKeysIsNotEmpty());
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 5, value: null),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 6,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 6,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesIsEmpty() {
    return not().group(
      (q) => q.extraValuesIsNull().or().extraValuesIsNotEmpty(),
    );
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  extraValuesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 6, value: null),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterFilterCondition> idBetween(
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

extension EntityLookupQueryObject
    on QueryBuilder<EntityLookup, EntityLookup, QFilterCondition> {}

extension EntityLookupQuerySortBy
    on QueryBuilder<EntityLookup, EntityLookup, QSortBy> {
  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> sortByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> sortByCategoryDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> sortByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> sortByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> sortByNameStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy>
  sortByNameStringIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy>
  sortByDescriptionStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy>
  sortByDescriptionStringIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension EntityLookupQuerySortThenBy
    on QueryBuilder<EntityLookup, EntityLookup, QSortThenBy> {
  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> thenByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> thenByCategoryDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> thenByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> thenByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> thenByNameStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy>
  thenByNameStringIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy>
  thenByDescriptionStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy>
  thenByDescriptionStringIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension EntityLookupQueryWhereDistinct
    on QueryBuilder<EntityLookup, EntityLookup, QDistinct> {
  QueryBuilder<EntityLookup, EntityLookup, QAfterDistinct> distinctByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterDistinct> distinctByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterDistinct>
  distinctByNameStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterDistinct>
  distinctByDescriptionStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterDistinct>
  distinctByExtraKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<EntityLookup, EntityLookup, QAfterDistinct>
  distinctByExtraValues() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }
}

extension EntityLookupQueryProperty1
    on QueryBuilder<EntityLookup, EntityLookup, QProperty> {
  QueryBuilder<EntityLookup, String, QAfterProperty> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<EntityLookup, String, QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<EntityLookup, String?, QAfterProperty> nameStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<EntityLookup, String?, QAfterProperty>
  descriptionStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<EntityLookup, List<String>?, QAfterProperty>
  extraKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<EntityLookup, List<String>?, QAfterProperty>
  extraValuesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<EntityLookup, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension EntityLookupQueryProperty2<R>
    on QueryBuilder<EntityLookup, R, QAfterProperty> {
  QueryBuilder<EntityLookup, (R, String), QAfterProperty> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<EntityLookup, (R, String), QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<EntityLookup, (R, String?), QAfterProperty>
  nameStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<EntityLookup, (R, String?), QAfterProperty>
  descriptionStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<EntityLookup, (R, List<String>?), QAfterProperty>
  extraKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<EntityLookup, (R, List<String>?), QAfterProperty>
  extraValuesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<EntityLookup, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension EntityLookupQueryProperty3<R1, R2>
    on QueryBuilder<EntityLookup, (R1, R2), QAfterProperty> {
  QueryBuilder<EntityLookup, (R1, R2, String), QOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<EntityLookup, (R1, R2, String), QOperations> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<EntityLookup, (R1, R2, String?), QOperations>
  nameStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<EntityLookup, (R1, R2, String?), QOperations>
  descriptionStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<EntityLookup, (R1, R2, List<String>?), QOperations>
  extraKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<EntityLookup, (R1, R2, List<String>?), QOperations>
  extraValuesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<EntityLookup, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}
