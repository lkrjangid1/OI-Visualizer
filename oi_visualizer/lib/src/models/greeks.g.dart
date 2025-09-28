// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'greeks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Greeks _$GreeksFromJson(Map<String, dynamic> json) => Greeks(
  delta: (json['delta'] as num?)?.toDouble(),
  gamma: (json['gamma'] as num?)?.toDouble(),
  theta: (json['theta'] as num?)?.toDouble(),
  vega: (json['vega'] as num?)?.toDouble(),
  rho: (json['rho'] as num?)?.toDouble(),
);

Map<String, dynamic> _$GreeksToJson(Greeks instance) => <String, dynamic>{
  'delta': instance.delta,
  'gamma': instance.gamma,
  'theta': instance.theta,
  'vega': instance.vega,
  'rho': instance.rho,
};
