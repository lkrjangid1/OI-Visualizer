import 'package:json_annotation/json_annotation.dart';

part 'builder_data.g.dart';

@JsonSerializable()
class PayoffAt {
  final double? payoff;
  final double? at;

  const PayoffAt({
    this.payoff,
    this.at,
  });

  factory PayoffAt.fromJson(Map<String, dynamic> json) => _$PayoffAtFromJson(json);
  Map<String, dynamic> toJson() => _$PayoffAtToJson(this);
}

@JsonSerializable()
class ProjectedFuturesPrice {
  final String? expiry;
  final double? price;

  const ProjectedFuturesPrice({
    this.expiry,
    this.price,
  });

  factory ProjectedFuturesPrice.fromJson(Map<String, dynamic> json) => _$ProjectedFuturesPriceFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectedFuturesPriceToJson(this);
}

@JsonSerializable()
class BuilderData {
  final List<PayoffAt>? payoffsAtTarget;
  final List<PayoffAt>? payoffsAtExpiry;
  final double? xMin;
  final double? xMax;
  final List<ProjectedFuturesPrice>? projectedFuturesPrices;
  final double? underlyingPrice;
  final double? targetUnderlyingPrice;
  final double? payoffAtTarget;
  final double? payoffAtExpiry;

  const BuilderData({
    this.payoffsAtTarget,
    this.payoffsAtExpiry,
    this.xMin,
    this.xMax,
    this.projectedFuturesPrices,
    this.underlyingPrice,
    this.targetUnderlyingPrice,
    this.payoffAtTarget,
    this.payoffAtExpiry,
  });

  factory BuilderData.fromJson(Map<String, dynamic> json) => _$BuilderDataFromJson(json);
  Map<String, dynamic> toJson() => _$BuilderDataToJson(this);
}