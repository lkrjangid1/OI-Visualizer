// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transformed_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupedDataItem _$GroupedDataItemFromJson(Map<String, dynamic> json) =>
    GroupedDataItem(
      atmStrike: (json['atmStrike'] as num?)?.toDouble(),
      atmIV: (json['atmIV'] as num?)?.toDouble(),
      syntheticFuturesPrice:
          (json['syntheticFuturesPrice'] as num?)?.toDouble(),
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => DataItem.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$GroupedDataItemToJson(GroupedDataItem instance) =>
    <String, dynamic>{
      'atmStrike': instance.atmStrike,
      'atmIV': instance.atmIV,
      'syntheticFuturesPrice': instance.syntheticFuturesPrice,
      'data': instance.data,
    };

TransformedData _$TransformedDataFromJson(
  Map<String, dynamic> json,
) => TransformedData(
  underlying: json['underlying'] as String?,
  grouped: (json['grouped'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, GroupedDataItem.fromJson(e as Map<String, dynamic>)),
  ),
  filteredExpiries:
      (json['filteredExpiries'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  allExpiries:
      (json['allExpiries'] as List<dynamic>?)?.map((e) => e as String).toList(),
  strikePrices:
      (json['strikePrices'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
  underlyingValue: (json['underlyingValue'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TransformedDataToJson(TransformedData instance) =>
    <String, dynamic>{
      'underlying': instance.underlying,
      'grouped': instance.grouped,
      'filteredExpiries': instance.filteredExpiries,
      'allExpiries': instance.allExpiries,
      'strikePrices': instance.strikePrices,
      'underlyingValue': instance.underlyingValue,
    };
