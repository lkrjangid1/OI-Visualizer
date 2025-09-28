import 'package:json_annotation/json_annotation.dart';

part 'option_leg.g.dart';

enum OptionAction {
  @JsonValue('B')
  buy,
  @JsonValue('S')
  sell
}

enum OptionType {
  @JsonValue('CE')
  call,
  @JsonValue('PE')
  put
}

@JsonSerializable()
class OptionLeg {
  final bool? active;
  final OptionAction? action;
  final String? expiry;
  final double? strike;
  final OptionType? type;
  final int? lots;
  final double? price;
  final double? iv;

  const OptionLeg({
    this.active,
    this.action,
    this.expiry,
    this.strike,
    this.type,
    this.lots,
    this.price,
    this.iv,
  });

  factory OptionLeg.fromJson(Map<String, dynamic> json) => _$OptionLegFromJson(json);
  Map<String, dynamic> toJson() => _$OptionLegToJson(this);
}

@JsonSerializable()
class ActiveOptionLeg {
  final OptionAction? action;
  final String? expiry;
  final double? strike;
  final OptionType? type;
  final int? lots;
  final double? price;
  final double? iv;

  const ActiveOptionLeg({
    this.action,
    this.expiry,
    this.strike,
    this.type,
    this.lots,
    this.price,
    this.iv,
  });

  factory ActiveOptionLeg.fromJson(Map<String, dynamic> json) => _$ActiveOptionLegFromJson(json);
  Map<String, dynamic> toJson() => _$ActiveOptionLegToJson(this);
}