// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataItem _$DataItemFromJson(Map<String, dynamic> json) => DataItem(
  strikePrice: (json['strikePrice'] as num?)?.toDouble(),
  expiryDate: json['expiryDate'] as String?,
  pe:
      json['PE'] == null
          ? null
          : ContractData.fromJson(json['PE'] as Map<String, dynamic>),
  ce:
      json['CE'] == null
          ? null
          : ContractData.fromJson(json['CE'] as Map<String, dynamic>),
  syntheticFuturesPrice: (json['syntheticFuturesPrice'] as num?)?.toDouble(),
  iv: (json['iv'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DataItemToJson(DataItem instance) => <String, dynamic>{
  'strikePrice': instance.strikePrice,
  'expiryDate': instance.expiryDate,
  'PE': instance.pe,
  'CE': instance.ce,
  'syntheticFuturesPrice': instance.syntheticFuturesPrice,
  'iv': instance.iv,
};
