// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lookup_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LookupConfig _$LookupConfigFromJson(Map<String, dynamic> json) => LookupConfig(
  category: json['category'] as String,
  nameField: json['nameField'] as String,
  descriptionField: json['descriptionField'] as String?,
  extraFields: (json['extraFields'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$LookupConfigToJson(LookupConfig instance) =>
    <String, dynamic>{
      'category': instance.category,
      'nameField': instance.nameField,
      'descriptionField': instance.descriptionField,
      'extraFields': instance.extraFields,
    };

LookupConfigRoot _$LookupConfigRootFromJson(Map<String, dynamic> json) =>
    LookupConfigRoot(
      common: (json['common'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, LookupConfig.fromJson(e as Map<String, dynamic>)),
      ),
      overrides: (json['overrides'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          (e as Map<String, dynamic>).map(
            (k, e) =>
                MapEntry(k, LookupConfig.fromJson(e as Map<String, dynamic>)),
          ),
        ),
      ),
    );

Map<String, dynamic> _$LookupConfigRootToJson(LookupConfigRoot instance) =>
    <String, dynamic>{
      'common': instance.common,
      'overrides': instance.overrides,
    };
