// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'option_leg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OptionLeg _$OptionLegFromJson(Map<String, dynamic> json) => OptionLeg(
  active: json['active'] as bool?,
  action: $enumDecodeNullable(_$OptionActionEnumMap, json['action']),
  expiry: json['expiry'] as String?,
  strike: (json['strike'] as num?)?.toDouble(),
  type: $enumDecodeNullable(_$OptionTypeEnumMap, json['type']),
  lots: (json['lots'] as num?)?.toInt(),
  price: (json['price'] as num?)?.toDouble(),
  iv: (json['iv'] as num?)?.toDouble(),
);

Map<String, dynamic> _$OptionLegToJson(OptionLeg instance) => <String, dynamic>{
  'active': instance.active,
  'action': _$OptionActionEnumMap[instance.action],
  'expiry': instance.expiry,
  'strike': instance.strike,
  'type': _$OptionTypeEnumMap[instance.type],
  'lots': instance.lots,
  'price': instance.price,
  'iv': instance.iv,
};

const _$OptionActionEnumMap = {OptionAction.buy: 'B', OptionAction.sell: 'S'};

const _$OptionTypeEnumMap = {OptionType.call: 'CE', OptionType.put: 'PE'};

ActiveOptionLeg _$ActiveOptionLegFromJson(Map<String, dynamic> json) =>
    ActiveOptionLeg(
      action: $enumDecodeNullable(_$OptionActionEnumMap, json['action']),
      expiry: json['expiry'] as String?,
      strike: (json['strike'] as num?)?.toDouble(),
      type: $enumDecodeNullable(_$OptionTypeEnumMap, json['type']),
      lots: (json['lots'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble(),
      iv: (json['iv'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ActiveOptionLegToJson(ActiveOptionLeg instance) =>
    <String, dynamic>{
      'action': _$OptionActionEnumMap[instance.action],
      'expiry': instance.expiry,
      'strike': instance.strike,
      'type': _$OptionTypeEnumMap[instance.type],
      'lots': instance.lots,
      'price': instance.price,
      'iv': instance.iv,
    };
