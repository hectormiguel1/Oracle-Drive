// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetMissionCollection on Isar {
  IsarCollection<int, Mission> get missions => this.collection();
}

final MissionSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Mission',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'record', type: IsarType.string),
      IsarPropertySchema(name: 'missionTitleStringId', type: IsarType.string),
      IsarPropertySchema(
        name: 'missionExplanationStringId',
        type: IsarType.string,
      ),
      IsarPropertySchema(name: 'missionTargetStringId', type: IsarType.string),
      IsarPropertySchema(name: 'missionPosStringId', type: IsarType.string),
      IsarPropertySchema(name: 'missionMarkPosStringId', type: IsarType.string),
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
  converter: IsarObjectConverter<int, Mission>(
    serialize: serializeMission,
    deserialize: deserializeMission,
    deserializeProperty: deserializeMissionProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeMission(IsarWriter writer, Mission object) {
  IsarCore.writeString(writer, 1, object.record);
  IsarCore.writeString(writer, 2, object.missionTitleStringId);
  IsarCore.writeString(writer, 3, object.missionExplanationStringId);
  IsarCore.writeString(writer, 4, object.missionTargetStringId);
  IsarCore.writeString(writer, 5, object.missionPosStringId);
  IsarCore.writeString(writer, 6, object.missionMarkPosStringId);
  return object.id;
}

@isarProtected
Mission deserializeMission(IsarReader reader) {
  final String _record;
  _record = IsarCore.readString(reader, 1) ?? '';
  final String _missionTitleStringId;
  _missionTitleStringId = IsarCore.readString(reader, 2) ?? '';
  final String _missionExplanationStringId;
  _missionExplanationStringId = IsarCore.readString(reader, 3) ?? '';
  final String _missionTargetStringId;
  _missionTargetStringId = IsarCore.readString(reader, 4) ?? '';
  final String _missionPosStringId;
  _missionPosStringId = IsarCore.readString(reader, 5) ?? '';
  final String _missionMarkPosStringId;
  _missionMarkPosStringId = IsarCore.readString(reader, 6) ?? '';
  final object = Mission(
    record: _record,
    missionTitleStringId: _missionTitleStringId,
    missionExplanationStringId: _missionExplanationStringId,
    missionTargetStringId: _missionTargetStringId,
    missionPosStringId: _missionPosStringId,
    missionMarkPosStringId: _missionMarkPosStringId,
  );
  return object;
}

@isarProtected
dynamic deserializeMissionProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      return IsarCore.readString(reader, 4) ?? '';
    case 5:
      return IsarCore.readString(reader, 5) ?? '';
    case 6:
      return IsarCore.readString(reader, 6) ?? '';
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _MissionUpdate {
  bool call({
    required int id,
    String? record,
    String? missionTitleStringId,
    String? missionExplanationStringId,
    String? missionTargetStringId,
    String? missionPosStringId,
    String? missionMarkPosStringId,
  });
}

class _MissionUpdateImpl implements _MissionUpdate {
  const _MissionUpdateImpl(this.collection);

  final IsarCollection<int, Mission> collection;

  @override
  bool call({
    required int id,
    Object? record = ignore,
    Object? missionTitleStringId = ignore,
    Object? missionExplanationStringId = ignore,
    Object? missionTargetStringId = ignore,
    Object? missionPosStringId = ignore,
    Object? missionMarkPosStringId = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (record != ignore) 1: record as String?,
            if (missionTitleStringId != ignore)
              2: missionTitleStringId as String?,
            if (missionExplanationStringId != ignore)
              3: missionExplanationStringId as String?,
            if (missionTargetStringId != ignore)
              4: missionTargetStringId as String?,
            if (missionPosStringId != ignore) 5: missionPosStringId as String?,
            if (missionMarkPosStringId != ignore)
              6: missionMarkPosStringId as String?,
          },
        ) >
        0;
  }
}

sealed class _MissionUpdateAll {
  int call({
    required List<int> id,
    String? record,
    String? missionTitleStringId,
    String? missionExplanationStringId,
    String? missionTargetStringId,
    String? missionPosStringId,
    String? missionMarkPosStringId,
  });
}

class _MissionUpdateAllImpl implements _MissionUpdateAll {
  const _MissionUpdateAllImpl(this.collection);

  final IsarCollection<int, Mission> collection;

  @override
  int call({
    required List<int> id,
    Object? record = ignore,
    Object? missionTitleStringId = ignore,
    Object? missionExplanationStringId = ignore,
    Object? missionTargetStringId = ignore,
    Object? missionPosStringId = ignore,
    Object? missionMarkPosStringId = ignore,
  }) {
    return collection.updateProperties(id, {
      if (record != ignore) 1: record as String?,
      if (missionTitleStringId != ignore) 2: missionTitleStringId as String?,
      if (missionExplanationStringId != ignore)
        3: missionExplanationStringId as String?,
      if (missionTargetStringId != ignore) 4: missionTargetStringId as String?,
      if (missionPosStringId != ignore) 5: missionPosStringId as String?,
      if (missionMarkPosStringId != ignore)
        6: missionMarkPosStringId as String?,
    });
  }
}

extension MissionUpdate on IsarCollection<int, Mission> {
  _MissionUpdate get update => _MissionUpdateImpl(this);

  _MissionUpdateAll get updateAll => _MissionUpdateAllImpl(this);
}

sealed class _MissionQueryUpdate {
  int call({
    String? record,
    String? missionTitleStringId,
    String? missionExplanationStringId,
    String? missionTargetStringId,
    String? missionPosStringId,
    String? missionMarkPosStringId,
  });
}

class _MissionQueryUpdateImpl implements _MissionQueryUpdate {
  const _MissionQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Mission> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? missionTitleStringId = ignore,
    Object? missionExplanationStringId = ignore,
    Object? missionTargetStringId = ignore,
    Object? missionPosStringId = ignore,
    Object? missionMarkPosStringId = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (record != ignore) 1: record as String?,
      if (missionTitleStringId != ignore) 2: missionTitleStringId as String?,
      if (missionExplanationStringId != ignore)
        3: missionExplanationStringId as String?,
      if (missionTargetStringId != ignore) 4: missionTargetStringId as String?,
      if (missionPosStringId != ignore) 5: missionPosStringId as String?,
      if (missionMarkPosStringId != ignore)
        6: missionMarkPosStringId as String?,
    });
  }
}

extension MissionQueryUpdate on IsarQuery<Mission> {
  _MissionQueryUpdate get updateFirst =>
      _MissionQueryUpdateImpl(this, limit: 1);

  _MissionQueryUpdate get updateAll => _MissionQueryUpdateImpl(this);
}

class _MissionQueryBuilderUpdateImpl implements _MissionQueryUpdate {
  const _MissionQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Mission, Mission, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? record = ignore,
    Object? missionTitleStringId = ignore,
    Object? missionExplanationStringId = ignore,
    Object? missionTargetStringId = ignore,
    Object? missionPosStringId = ignore,
    Object? missionMarkPosStringId = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (record != ignore) 1: record as String?,
        if (missionTitleStringId != ignore) 2: missionTitleStringId as String?,
        if (missionExplanationStringId != ignore)
          3: missionExplanationStringId as String?,
        if (missionTargetStringId != ignore)
          4: missionTargetStringId as String?,
        if (missionPosStringId != ignore) 5: missionPosStringId as String?,
        if (missionMarkPosStringId != ignore)
          6: missionMarkPosStringId as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension MissionQueryBuilderUpdate
    on QueryBuilder<Mission, Mission, QOperations> {
  _MissionQueryUpdate get updateFirst =>
      _MissionQueryBuilderUpdateImpl(this, limit: 1);

  _MissionQueryUpdate get updateAll => _MissionQueryBuilderUpdateImpl(this);
}

extension MissionQueryFilter
    on QueryBuilder<Mission, Mission, QFilterCondition> {
  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordGreaterThan(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordLessThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordBetween(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordStartsWith(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordEndsWith(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordContains(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordMatches(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> recordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdGreaterThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdLessThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdBetween(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTitleStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdGreaterThan(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdLessThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdBetween(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdStartsWith(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdEndsWith(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdContains(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdMatches(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionExplanationStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdGreaterThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdLessThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdBetween(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionTargetStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdGreaterThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdBetween(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionPosStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdGreaterThan(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdGreaterThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdLessThanOrEqualTo(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdBetween(
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition>
  missionMarkPosStringIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Mission, Mission, QAfterFilterCondition> idBetween(
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

extension MissionQueryObject
    on QueryBuilder<Mission, Mission, QFilterCondition> {}

extension MissionQuerySortBy on QueryBuilder<Mission, Mission, QSortBy> {
  QueryBuilder<Mission, Mission, QAfterSortBy> sortByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByMissionTitleStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByMissionTitleStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy>
  sortByMissionExplanationStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy>
  sortByMissionExplanationStringIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByMissionTargetStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByMissionTargetStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByMissionPosStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByMissionPosStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByMissionMarkPosStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy>
  sortByMissionMarkPosStringIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension MissionQuerySortThenBy
    on QueryBuilder<Mission, Mission, QSortThenBy> {
  QueryBuilder<Mission, Mission, QAfterSortBy> thenByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByRecordDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByMissionTitleStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByMissionTitleStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy>
  thenByMissionExplanationStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy>
  thenByMissionExplanationStringIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByMissionTargetStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByMissionTargetStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByMissionPosStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByMissionPosStringIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByMissionMarkPosStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy>
  thenByMissionMarkPosStringIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Mission, Mission, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension MissionQueryWhereDistinct
    on QueryBuilder<Mission, Mission, QDistinct> {
  QueryBuilder<Mission, Mission, QAfterDistinct> distinctByRecord({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterDistinct>
  distinctByMissionTitleStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterDistinct>
  distinctByMissionExplanationStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterDistinct>
  distinctByMissionTargetStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterDistinct> distinctByMissionPosStringId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mission, Mission, QAfterDistinct>
  distinctByMissionMarkPosStringId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6, caseSensitive: caseSensitive);
    });
  }
}

extension MissionQueryProperty1 on QueryBuilder<Mission, Mission, QProperty> {
  QueryBuilder<Mission, String, QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Mission, String, QAfterProperty> missionTitleStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Mission, String, QAfterProperty>
  missionExplanationStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Mission, String, QAfterProperty>
  missionTargetStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Mission, String, QAfterProperty> missionPosStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Mission, String, QAfterProperty>
  missionMarkPosStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Mission, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension MissionQueryProperty2<R> on QueryBuilder<Mission, R, QAfterProperty> {
  QueryBuilder<Mission, (R, String), QAfterProperty> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Mission, (R, String), QAfterProperty>
  missionTitleStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Mission, (R, String), QAfterProperty>
  missionExplanationStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Mission, (R, String), QAfterProperty>
  missionTargetStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Mission, (R, String), QAfterProperty>
  missionPosStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Mission, (R, String), QAfterProperty>
  missionMarkPosStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Mission, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension MissionQueryProperty3<R1, R2>
    on QueryBuilder<Mission, (R1, R2), QAfterProperty> {
  QueryBuilder<Mission, (R1, R2, String), QOperations> recordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Mission, (R1, R2, String), QOperations>
  missionTitleStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Mission, (R1, R2, String), QOperations>
  missionExplanationStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Mission, (R1, R2, String), QOperations>
  missionTargetStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Mission, (R1, R2, String), QOperations>
  missionPosStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Mission, (R1, R2, String), QOperations>
  missionMarkPosStringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Mission, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}
