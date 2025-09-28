import 'package:json_annotation/json_annotation.dart';

part 'greeks.g.dart';

@JsonSerializable()
class Greeks {
  final double? delta;
  final double? gamma;
  final double? theta;
  final double? vega;
  final double? rho;

  const Greeks({
    this.delta,
    this.gamma,
    this.theta,
    this.vega,
    this.rho,
  });

  factory Greeks.fromJson(Map<String, dynamic> json) => _$GreeksFromJson(json);
  Map<String, dynamic> toJson() => _$GreeksToJson(this);
}