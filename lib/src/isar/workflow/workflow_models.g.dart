// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_models.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetStoredWorkflowCollection on Isar {
  IsarCollection<int, StoredWorkflow> get storedWorkflows => this.collection();
}

final StoredWorkflowSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'StoredWorkflow',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'workflowId', type: IsarType.string),
      IsarPropertySchema(name: 'name', type: IsarType.string),
      IsarPropertySchema(name: 'description', type: IsarType.string),
      IsarPropertySchema(name: 'createdAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'modifiedAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'jsonData', type: IsarType.string),
      IsarPropertySchema(name: 'workspacePath', type: IsarType.string),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'workflowId',
        properties: ["workflowId"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, StoredWorkflow>(
    serialize: serializeStoredWorkflow,
    deserialize: deserializeStoredWorkflow,
    deserializeProperty: deserializeStoredWorkflowProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeStoredWorkflow(IsarWriter writer, StoredWorkflow object) {
  IsarCore.writeString(writer, 1, object.workflowId);
  IsarCore.writeString(writer, 2, object.name);
  IsarCore.writeString(writer, 3, object.description);
  IsarCore.writeLong(
    writer,
    4,
    object.createdAt.toUtc().microsecondsSinceEpoch,
  );
  IsarCore.writeLong(
    writer,
    5,
    object.modifiedAt.toUtc().microsecondsSinceEpoch,
  );
  IsarCore.writeString(writer, 6, object.jsonData);
  {
    final value = object.workspacePath;
    if (value == null) {
      IsarCore.writeNull(writer, 7);
    } else {
      IsarCore.writeString(writer, 7, value);
    }
  }
  return object.id;
}

@isarProtected
StoredWorkflow deserializeStoredWorkflow(IsarReader reader) {
  final String _workflowId;
  _workflowId = IsarCore.readString(reader, 1) ?? '';
  final String _name;
  _name = IsarCore.readString(reader, 2) ?? '';
  final String _description;
  _description = IsarCore.readString(reader, 3) ?? '';
  final DateTime _createdAt;
  {
    final value = IsarCore.readLong(reader, 4);
    if (value == -9223372036854775808) {
      _createdAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      _createdAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final DateTime _modifiedAt;
  {
    final value = IsarCore.readLong(reader, 5);
    if (value == -9223372036854775808) {
      _modifiedAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      _modifiedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final String _jsonData;
  _jsonData = IsarCore.readString(reader, 6) ?? '';
  final String? _workspacePath;
  _workspacePath = IsarCore.readString(reader, 7);
  final object = StoredWorkflow(
    workflowId: _workflowId,
    name: _name,
    description: _description,
    createdAt: _createdAt,
    modifiedAt: _modifiedAt,
    jsonData: _jsonData,
    workspacePath: _workspacePath,
  );
  return object;
}

@isarProtected
dynamic deserializeStoredWorkflowProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      {
        final value = IsarCore.readLong(reader, 4);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 5:
      {
        final value = IsarCore.readLong(reader, 5);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 6:
      return IsarCore.readString(reader, 6) ?? '';
    case 7:
      return IsarCore.readString(reader, 7);
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _StoredWorkflowUpdate {
  bool call({
    required int id,
    String? workflowId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? jsonData,
    String? workspacePath,
  });
}

class _StoredWorkflowUpdateImpl implements _StoredWorkflowUpdate {
  const _StoredWorkflowUpdateImpl(this.collection);

  final IsarCollection<int, StoredWorkflow> collection;

  @override
  bool call({
    required int id,
    Object? workflowId = ignore,
    Object? name = ignore,
    Object? description = ignore,
    Object? createdAt = ignore,
    Object? modifiedAt = ignore,
    Object? jsonData = ignore,
    Object? workspacePath = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (workflowId != ignore) 1: workflowId as String?,
            if (name != ignore) 2: name as String?,
            if (description != ignore) 3: description as String?,
            if (createdAt != ignore) 4: createdAt as DateTime?,
            if (modifiedAt != ignore) 5: modifiedAt as DateTime?,
            if (jsonData != ignore) 6: jsonData as String?,
            if (workspacePath != ignore) 7: workspacePath as String?,
          },
        ) >
        0;
  }
}

sealed class _StoredWorkflowUpdateAll {
  int call({
    required List<int> id,
    String? workflowId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? jsonData,
    String? workspacePath,
  });
}

class _StoredWorkflowUpdateAllImpl implements _StoredWorkflowUpdateAll {
  const _StoredWorkflowUpdateAllImpl(this.collection);

  final IsarCollection<int, StoredWorkflow> collection;

  @override
  int call({
    required List<int> id,
    Object? workflowId = ignore,
    Object? name = ignore,
    Object? description = ignore,
    Object? createdAt = ignore,
    Object? modifiedAt = ignore,
    Object? jsonData = ignore,
    Object? workspacePath = ignore,
  }) {
    return collection.updateProperties(id, {
      if (workflowId != ignore) 1: workflowId as String?,
      if (name != ignore) 2: name as String?,
      if (description != ignore) 3: description as String?,
      if (createdAt != ignore) 4: createdAt as DateTime?,
      if (modifiedAt != ignore) 5: modifiedAt as DateTime?,
      if (jsonData != ignore) 6: jsonData as String?,
      if (workspacePath != ignore) 7: workspacePath as String?,
    });
  }
}

extension StoredWorkflowUpdate on IsarCollection<int, StoredWorkflow> {
  _StoredWorkflowUpdate get update => _StoredWorkflowUpdateImpl(this);

  _StoredWorkflowUpdateAll get updateAll => _StoredWorkflowUpdateAllImpl(this);
}

sealed class _StoredWorkflowQueryUpdate {
  int call({
    String? workflowId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? jsonData,
    String? workspacePath,
  });
}

class _StoredWorkflowQueryUpdateImpl implements _StoredWorkflowQueryUpdate {
  const _StoredWorkflowQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<StoredWorkflow> query;
  final int? limit;

  @override
  int call({
    Object? workflowId = ignore,
    Object? name = ignore,
    Object? description = ignore,
    Object? createdAt = ignore,
    Object? modifiedAt = ignore,
    Object? jsonData = ignore,
    Object? workspacePath = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (workflowId != ignore) 1: workflowId as String?,
      if (name != ignore) 2: name as String?,
      if (description != ignore) 3: description as String?,
      if (createdAt != ignore) 4: createdAt as DateTime?,
      if (modifiedAt != ignore) 5: modifiedAt as DateTime?,
      if (jsonData != ignore) 6: jsonData as String?,
      if (workspacePath != ignore) 7: workspacePath as String?,
    });
  }
}

extension StoredWorkflowQueryUpdate on IsarQuery<StoredWorkflow> {
  _StoredWorkflowQueryUpdate get updateFirst =>
      _StoredWorkflowQueryUpdateImpl(this, limit: 1);

  _StoredWorkflowQueryUpdate get updateAll =>
      _StoredWorkflowQueryUpdateImpl(this);
}

class _StoredWorkflowQueryBuilderUpdateImpl
    implements _StoredWorkflowQueryUpdate {
  const _StoredWorkflowQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<StoredWorkflow, StoredWorkflow, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? workflowId = ignore,
    Object? name = ignore,
    Object? description = ignore,
    Object? createdAt = ignore,
    Object? modifiedAt = ignore,
    Object? jsonData = ignore,
    Object? workspacePath = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (workflowId != ignore) 1: workflowId as String?,
        if (name != ignore) 2: name as String?,
        if (description != ignore) 3: description as String?,
        if (createdAt != ignore) 4: createdAt as DateTime?,
        if (modifiedAt != ignore) 5: modifiedAt as DateTime?,
        if (jsonData != ignore) 6: jsonData as String?,
        if (workspacePath != ignore) 7: workspacePath as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension StoredWorkflowQueryBuilderUpdate
    on QueryBuilder<StoredWorkflow, StoredWorkflow, QOperations> {
  _StoredWorkflowQueryUpdate get updateFirst =>
      _StoredWorkflowQueryBuilderUpdateImpl(this, limit: 1);

  _StoredWorkflowQueryUpdate get updateAll =>
      _StoredWorkflowQueryBuilderUpdateImpl(this);
}

extension StoredWorkflowQueryFilter
    on QueryBuilder<StoredWorkflow, StoredWorkflow, QFilterCondition> {
  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workflowIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  createdAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  createdAtLessThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 4, value: value));
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  createdAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  createdAtBetween(DateTime lower, DateTime upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  modifiedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  modifiedAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  modifiedAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  modifiedAtLessThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 5, value: value));
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  modifiedAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  modifiedAtBetween(DateTime lower, DateTime upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 5, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  jsonDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 7, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 7, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 7,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 7,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 7, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  workspacePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 7, value: ''),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterFilterCondition> idBetween(
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

extension StoredWorkflowQueryObject
    on QueryBuilder<StoredWorkflow, StoredWorkflow, QFilterCondition> {}

extension StoredWorkflowQuerySortBy
    on QueryBuilder<StoredWorkflow, StoredWorkflow, QSortBy> {
  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> sortByWorkflowId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  sortByWorkflowIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> sortByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> sortByNameDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> sortByDescription({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  sortByDescriptionDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  sortByModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  sortByModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> sortByJsonData({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  sortByJsonDataDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  sortByWorkspacePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  sortByWorkspacePathDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension StoredWorkflowQuerySortThenBy
    on QueryBuilder<StoredWorkflow, StoredWorkflow, QSortThenBy> {
  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> thenByWorkflowId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  thenByWorkflowIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> thenByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> thenByNameDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> thenByDescription({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  thenByDescriptionDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  thenByModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  thenByModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> thenByJsonData({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  thenByJsonDataDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  thenByWorkspacePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy>
  thenByWorkspacePathDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension StoredWorkflowQueryWhereDistinct
    on QueryBuilder<StoredWorkflow, StoredWorkflow, QDistinct> {
  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterDistinct>
  distinctByWorkflowId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterDistinct>
  distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterDistinct>
  distinctByModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterDistinct>
  distinctByJsonData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredWorkflow, StoredWorkflow, QAfterDistinct>
  distinctByWorkspacePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7, caseSensitive: caseSensitive);
    });
  }
}

extension StoredWorkflowQueryProperty1
    on QueryBuilder<StoredWorkflow, StoredWorkflow, QProperty> {
  QueryBuilder<StoredWorkflow, String, QAfterProperty> workflowIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StoredWorkflow, String, QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StoredWorkflow, String, QAfterProperty> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StoredWorkflow, DateTime, QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<StoredWorkflow, DateTime, QAfterProperty> modifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<StoredWorkflow, String, QAfterProperty> jsonDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<StoredWorkflow, String?, QAfterProperty>
  workspacePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<StoredWorkflow, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension StoredWorkflowQueryProperty2<R>
    on QueryBuilder<StoredWorkflow, R, QAfterProperty> {
  QueryBuilder<StoredWorkflow, (R, String), QAfterProperty>
  workflowIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StoredWorkflow, (R, String), QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StoredWorkflow, (R, String), QAfterProperty>
  descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StoredWorkflow, (R, DateTime), QAfterProperty>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<StoredWorkflow, (R, DateTime), QAfterProperty>
  modifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<StoredWorkflow, (R, String), QAfterProperty> jsonDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<StoredWorkflow, (R, String?), QAfterProperty>
  workspacePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<StoredWorkflow, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension StoredWorkflowQueryProperty3<R1, R2>
    on QueryBuilder<StoredWorkflow, (R1, R2), QAfterProperty> {
  QueryBuilder<StoredWorkflow, (R1, R2, String), QOperations>
  workflowIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StoredWorkflow, (R1, R2, String), QOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StoredWorkflow, (R1, R2, String), QOperations>
  descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StoredWorkflow, (R1, R2, DateTime), QOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<StoredWorkflow, (R1, R2, DateTime), QOperations>
  modifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<StoredWorkflow, (R1, R2, String), QOperations>
  jsonDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<StoredWorkflow, (R1, R2, String?), QOperations>
  workspacePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<StoredWorkflow, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetWorkflowExecutionLogCollection on Isar {
  IsarCollection<int, WorkflowExecutionLog> get workflowExecutionLogs =>
      this.collection();
}

final WorkflowExecutionLogSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'WorkflowExecutionLog',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'workflowId', type: IsarType.string),
      IsarPropertySchema(name: 'executedAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'durationMs', type: IsarType.long),
      IsarPropertySchema(name: 'status', type: IsarType.string),
      IsarPropertySchema(name: 'errorMessage', type: IsarType.string),
      IsarPropertySchema(name: 'nodesExecuted', type: IsarType.long),
      IsarPropertySchema(name: 'totalNodes', type: IsarType.long),
      IsarPropertySchema(name: 'detailsJson', type: IsarType.string),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'workflowId',
        properties: ["workflowId"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'executedAt',
        properties: ["executedAt"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, WorkflowExecutionLog>(
    serialize: serializeWorkflowExecutionLog,
    deserialize: deserializeWorkflowExecutionLog,
    deserializeProperty: deserializeWorkflowExecutionLogProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeWorkflowExecutionLog(
  IsarWriter writer,
  WorkflowExecutionLog object,
) {
  IsarCore.writeString(writer, 1, object.workflowId);
  IsarCore.writeLong(
    writer,
    2,
    object.executedAt.toUtc().microsecondsSinceEpoch,
  );
  IsarCore.writeLong(writer, 3, object.durationMs);
  IsarCore.writeString(writer, 4, object.status);
  {
    final value = object.errorMessage;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  IsarCore.writeLong(writer, 6, object.nodesExecuted);
  IsarCore.writeLong(writer, 7, object.totalNodes);
  {
    final value = object.detailsJson;
    if (value == null) {
      IsarCore.writeNull(writer, 8);
    } else {
      IsarCore.writeString(writer, 8, value);
    }
  }
  return object.id;
}

@isarProtected
WorkflowExecutionLog deserializeWorkflowExecutionLog(IsarReader reader) {
  final String _workflowId;
  _workflowId = IsarCore.readString(reader, 1) ?? '';
  final DateTime _executedAt;
  {
    final value = IsarCore.readLong(reader, 2);
    if (value == -9223372036854775808) {
      _executedAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      _executedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final int _durationMs;
  _durationMs = IsarCore.readLong(reader, 3);
  final String _status;
  _status = IsarCore.readString(reader, 4) ?? '';
  final String? _errorMessage;
  _errorMessage = IsarCore.readString(reader, 5);
  final int _nodesExecuted;
  _nodesExecuted = IsarCore.readLong(reader, 6);
  final int _totalNodes;
  _totalNodes = IsarCore.readLong(reader, 7);
  final String? _detailsJson;
  _detailsJson = IsarCore.readString(reader, 8);
  final object = WorkflowExecutionLog(
    workflowId: _workflowId,
    executedAt: _executedAt,
    durationMs: _durationMs,
    status: _status,
    errorMessage: _errorMessage,
    nodesExecuted: _nodesExecuted,
    totalNodes: _totalNodes,
    detailsJson: _detailsJson,
  );
  return object;
}

@isarProtected
dynamic deserializeWorkflowExecutionLogProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      {
        final value = IsarCore.readLong(reader, 2);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      return IsarCore.readString(reader, 4) ?? '';
    case 5:
      return IsarCore.readString(reader, 5);
    case 6:
      return IsarCore.readLong(reader, 6);
    case 7:
      return IsarCore.readLong(reader, 7);
    case 8:
      return IsarCore.readString(reader, 8);
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _WorkflowExecutionLogUpdate {
  bool call({
    required int id,
    String? workflowId,
    DateTime? executedAt,
    int? durationMs,
    String? status,
    String? errorMessage,
    int? nodesExecuted,
    int? totalNodes,
    String? detailsJson,
  });
}

class _WorkflowExecutionLogUpdateImpl implements _WorkflowExecutionLogUpdate {
  const _WorkflowExecutionLogUpdateImpl(this.collection);

  final IsarCollection<int, WorkflowExecutionLog> collection;

  @override
  bool call({
    required int id,
    Object? workflowId = ignore,
    Object? executedAt = ignore,
    Object? durationMs = ignore,
    Object? status = ignore,
    Object? errorMessage = ignore,
    Object? nodesExecuted = ignore,
    Object? totalNodes = ignore,
    Object? detailsJson = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (workflowId != ignore) 1: workflowId as String?,
            if (executedAt != ignore) 2: executedAt as DateTime?,
            if (durationMs != ignore) 3: durationMs as int?,
            if (status != ignore) 4: status as String?,
            if (errorMessage != ignore) 5: errorMessage as String?,
            if (nodesExecuted != ignore) 6: nodesExecuted as int?,
            if (totalNodes != ignore) 7: totalNodes as int?,
            if (detailsJson != ignore) 8: detailsJson as String?,
          },
        ) >
        0;
  }
}

sealed class _WorkflowExecutionLogUpdateAll {
  int call({
    required List<int> id,
    String? workflowId,
    DateTime? executedAt,
    int? durationMs,
    String? status,
    String? errorMessage,
    int? nodesExecuted,
    int? totalNodes,
    String? detailsJson,
  });
}

class _WorkflowExecutionLogUpdateAllImpl
    implements _WorkflowExecutionLogUpdateAll {
  const _WorkflowExecutionLogUpdateAllImpl(this.collection);

  final IsarCollection<int, WorkflowExecutionLog> collection;

  @override
  int call({
    required List<int> id,
    Object? workflowId = ignore,
    Object? executedAt = ignore,
    Object? durationMs = ignore,
    Object? status = ignore,
    Object? errorMessage = ignore,
    Object? nodesExecuted = ignore,
    Object? totalNodes = ignore,
    Object? detailsJson = ignore,
  }) {
    return collection.updateProperties(id, {
      if (workflowId != ignore) 1: workflowId as String?,
      if (executedAt != ignore) 2: executedAt as DateTime?,
      if (durationMs != ignore) 3: durationMs as int?,
      if (status != ignore) 4: status as String?,
      if (errorMessage != ignore) 5: errorMessage as String?,
      if (nodesExecuted != ignore) 6: nodesExecuted as int?,
      if (totalNodes != ignore) 7: totalNodes as int?,
      if (detailsJson != ignore) 8: detailsJson as String?,
    });
  }
}

extension WorkflowExecutionLogUpdate
    on IsarCollection<int, WorkflowExecutionLog> {
  _WorkflowExecutionLogUpdate get update =>
      _WorkflowExecutionLogUpdateImpl(this);

  _WorkflowExecutionLogUpdateAll get updateAll =>
      _WorkflowExecutionLogUpdateAllImpl(this);
}

sealed class _WorkflowExecutionLogQueryUpdate {
  int call({
    String? workflowId,
    DateTime? executedAt,
    int? durationMs,
    String? status,
    String? errorMessage,
    int? nodesExecuted,
    int? totalNodes,
    String? detailsJson,
  });
}

class _WorkflowExecutionLogQueryUpdateImpl
    implements _WorkflowExecutionLogQueryUpdate {
  const _WorkflowExecutionLogQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<WorkflowExecutionLog> query;
  final int? limit;

  @override
  int call({
    Object? workflowId = ignore,
    Object? executedAt = ignore,
    Object? durationMs = ignore,
    Object? status = ignore,
    Object? errorMessage = ignore,
    Object? nodesExecuted = ignore,
    Object? totalNodes = ignore,
    Object? detailsJson = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (workflowId != ignore) 1: workflowId as String?,
      if (executedAt != ignore) 2: executedAt as DateTime?,
      if (durationMs != ignore) 3: durationMs as int?,
      if (status != ignore) 4: status as String?,
      if (errorMessage != ignore) 5: errorMessage as String?,
      if (nodesExecuted != ignore) 6: nodesExecuted as int?,
      if (totalNodes != ignore) 7: totalNodes as int?,
      if (detailsJson != ignore) 8: detailsJson as String?,
    });
  }
}

extension WorkflowExecutionLogQueryUpdate on IsarQuery<WorkflowExecutionLog> {
  _WorkflowExecutionLogQueryUpdate get updateFirst =>
      _WorkflowExecutionLogQueryUpdateImpl(this, limit: 1);

  _WorkflowExecutionLogQueryUpdate get updateAll =>
      _WorkflowExecutionLogQueryUpdateImpl(this);
}

class _WorkflowExecutionLogQueryBuilderUpdateImpl
    implements _WorkflowExecutionLogQueryUpdate {
  const _WorkflowExecutionLogQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QOperations>
  query;
  final int? limit;

  @override
  int call({
    Object? workflowId = ignore,
    Object? executedAt = ignore,
    Object? durationMs = ignore,
    Object? status = ignore,
    Object? errorMessage = ignore,
    Object? nodesExecuted = ignore,
    Object? totalNodes = ignore,
    Object? detailsJson = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (workflowId != ignore) 1: workflowId as String?,
        if (executedAt != ignore) 2: executedAt as DateTime?,
        if (durationMs != ignore) 3: durationMs as int?,
        if (status != ignore) 4: status as String?,
        if (errorMessage != ignore) 5: errorMessage as String?,
        if (nodesExecuted != ignore) 6: nodesExecuted as int?,
        if (totalNodes != ignore) 7: totalNodes as int?,
        if (detailsJson != ignore) 8: detailsJson as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension WorkflowExecutionLogQueryBuilderUpdate
    on QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QOperations> {
  _WorkflowExecutionLogQueryUpdate get updateFirst =>
      _WorkflowExecutionLogQueryBuilderUpdateImpl(this, limit: 1);

  _WorkflowExecutionLogQueryUpdate get updateAll =>
      _WorkflowExecutionLogQueryBuilderUpdateImpl(this);
}

extension WorkflowExecutionLogQueryFilter
    on
        QueryBuilder<
          WorkflowExecutionLog,
          WorkflowExecutionLog,
          QFilterCondition
        > {
  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  workflowIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  executedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  executedAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  executedAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  executedAtLessThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 2, value: value));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  executedAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  executedAtBetween(DateTime lower, DateTime upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 2, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  durationMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  durationMsGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  durationMsGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  durationMsLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 3, value: value));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  durationMsLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  durationMsBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 3, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusBetween(String lower, String upper, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageGreaterThan(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  nodesExecutedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  nodesExecutedGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  nodesExecutedGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  nodesExecutedLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 6, value: value));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  nodesExecutedLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  nodesExecutedBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 6, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  totalNodesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  totalNodesGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  totalNodesGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  totalNodesLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 7, value: value));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  totalNodesLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  totalNodesBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 7, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 8, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 8, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 8,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 8, value: ''),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  detailsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 8, value: ''),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<
    WorkflowExecutionLog,
    WorkflowExecutionLog,
    QAfterFilterCondition
  >
  idBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }
}

extension WorkflowExecutionLogQueryObject
    on
        QueryBuilder<
          WorkflowExecutionLog,
          WorkflowExecutionLog,
          QFilterCondition
        > {}

extension WorkflowExecutionLogQuerySortBy
    on QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QSortBy> {
  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByWorkflowId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByWorkflowIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByExecutedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByStatusDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByErrorMessageDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByNodesExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByNodesExecutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByTotalNodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByTotalNodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByDetailsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByDetailsJsonDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension WorkflowExecutionLogQuerySortThenBy
    on QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QSortThenBy> {
  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByWorkflowId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByWorkflowIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByExecutedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByStatusDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByErrorMessageDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByNodesExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByNodesExecutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByTotalNodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByTotalNodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByDetailsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByDetailsJsonDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension WorkflowExecutionLogQueryWhereDistinct
    on QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QDistinct> {
  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterDistinct>
  distinctByWorkflowId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterDistinct>
  distinctByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterDistinct>
  distinctByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterDistinct>
  distinctByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterDistinct>
  distinctByNodesExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterDistinct>
  distinctByTotalNodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }

  QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QAfterDistinct>
  distinctByDetailsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8, caseSensitive: caseSensitive);
    });
  }
}

extension WorkflowExecutionLogQueryProperty1
    on QueryBuilder<WorkflowExecutionLog, WorkflowExecutionLog, QProperty> {
  QueryBuilder<WorkflowExecutionLog, String, QAfterProperty>
  workflowIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<WorkflowExecutionLog, DateTime, QAfterProperty>
  executedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<WorkflowExecutionLog, int, QAfterProperty> durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<WorkflowExecutionLog, String, QAfterProperty> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<WorkflowExecutionLog, String?, QAfterProperty>
  errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<WorkflowExecutionLog, int, QAfterProperty>
  nodesExecutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<WorkflowExecutionLog, int, QAfterProperty> totalNodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<WorkflowExecutionLog, String?, QAfterProperty>
  detailsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<WorkflowExecutionLog, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension WorkflowExecutionLogQueryProperty2<R>
    on QueryBuilder<WorkflowExecutionLog, R, QAfterProperty> {
  QueryBuilder<WorkflowExecutionLog, (R, String), QAfterProperty>
  workflowIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R, DateTime), QAfterProperty>
  executedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R, int), QAfterProperty>
  durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R, String), QAfterProperty>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R, String?), QAfterProperty>
  errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R, int), QAfterProperty>
  nodesExecutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R, int), QAfterProperty>
  totalNodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R, String?), QAfterProperty>
  detailsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension WorkflowExecutionLogQueryProperty3<R1, R2>
    on QueryBuilder<WorkflowExecutionLog, (R1, R2), QAfterProperty> {
  QueryBuilder<WorkflowExecutionLog, (R1, R2, String), QOperations>
  workflowIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R1, R2, DateTime), QOperations>
  executedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R1, R2, int), QOperations>
  durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R1, R2, String), QOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R1, R2, String?), QOperations>
  errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R1, R2, int), QOperations>
  nodesExecutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R1, R2, int), QOperations>
  totalNodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R1, R2, String?), QOperations>
  detailsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<WorkflowExecutionLog, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}
