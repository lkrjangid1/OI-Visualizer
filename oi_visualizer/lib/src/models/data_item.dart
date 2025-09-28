import 'package:json_annotation/json_annotation.dart';
import 'contract_data.dart';

part 'data_item.g.dart';

@JsonSerializable()
class DataItem {
  final double? strikePrice;
  final String? expiryDate;
  @JsonKey(name: 'PE')
  final ContractData? pe;
  @JsonKey(name: 'CE')
  final ContractData? ce;
  final double? syntheticFuturesPrice;
  final double? iv;

  const DataItem({
    this.strikePrice,
    this.expiryDate,
    this.pe,
    this.ce,
    this.syntheticFuturesPrice,
    this.iv,
  });

  factory DataItem.fromJson(Map<String, dynamic> json) => _$DataItemFromJson(json);
  Map<String, dynamic> toJson() => _$DataItemToJson(this);
}