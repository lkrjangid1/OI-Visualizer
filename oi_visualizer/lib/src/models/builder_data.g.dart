// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builder_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PayoffAt _$PayoffAtFromJson(Map<String, dynamic> json) => PayoffAt(
  payoff: (json['payoff'] as num?)?.toDouble(),
  at: (json['at'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PayoffAtToJson(PayoffAt instance) => <String, dynamic>{
  'payoff': instance.payoff,
  'at': instance.at,
};

ProjectedFuturesPrice _$ProjectedFuturesPriceFromJson(
  Map<String, dynamic> json,
) => ProjectedFuturesPrice(
  expiry: json['expiry'] as String?,
  price: (json['price'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ProjectedFuturesPriceToJson(
  ProjectedFuturesPrice instance,
) => <String, dynamic>{'expiry': instance.expiry, 'price': instance.price};

BuilderData _$BuilderDataFromJson(Map<String, dynamic> json) => BuilderData(
  payoffsAtTarget:
      (json['payoffsAtTarget'] as List<dynamic>?)
          ?.map((e) => PayoffAt.fromJson(e as Map<String, dynamic>))
          .toList(),
  payoffsAtExpiry:
      (json['payoffsAtExpiry'] as List<dynamic>?)
          ?.map((e) => PayoffAt.fromJson(e as Map<String, dynamic>))
          .toList(),
  xMin: (json['xMin'] as num?)?.toDouble(),
  xMax: (json['xMax'] as num?)?.toDouble(),
  projectedFuturesPrices:
      (json['projectedFuturesPrices'] as List<dynamic>?)
          ?.map(
            (e) => ProjectedFuturesPrice.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  underlyingPrice: (json['underlyingPrice'] as num?)?.toDouble(),
  targetUnderlyingPrice: (json['targetUnderlyingPrice'] as num?)?.toDouble(),
  payoffAtTarget: (json['payoffAtTarget'] as num?)?.toDouble(),
  payoffAtExpiry: (json['payoffAtExpiry'] as num?)?.toDouble(),
);

Map<String, dynamic> _$BuilderDataToJson(BuilderData instance) =>
    <String, dynamic>{
      'payoffsAtTarget': instance.payoffsAtTarget,
      'payoffsAtExpiry': instance.payoffsAtExpiry,
      'xMin': instance.xMin,
      'xMax': instance.xMax,
      'projectedFuturesPrices': instance.projectedFuturesPrices,
      'underlyingPrice': instance.underlyingPrice,
      'targetUnderlyingPrice': instance.targetUnderlyingPrice,
      'payoffAtTarget': instance.payoffAtTarget,
      'payoffAtExpiry': instance.payoffAtExpiry,
    };
