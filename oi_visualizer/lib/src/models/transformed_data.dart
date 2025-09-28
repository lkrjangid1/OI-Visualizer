import 'package:json_annotation/json_annotation.dart';
import 'data_item.dart';

part 'transformed_data.g.dart';

@JsonSerializable()
class GroupedDataItem {
  final double? atmStrike;
  final double? atmIV;
  final double? syntheticFuturesPrice;
  final List<DataItem>? data;

  const GroupedDataItem({
    this.atmStrike,
    this.atmIV,
    this.syntheticFuturesPrice,
    this.data,
  });

  factory GroupedDataItem.fromJson(Map<String, dynamic> json) => _$GroupedDataItemFromJson(json);
  Map<String, dynamic> toJson() => _$GroupedDataItemToJson(this);
}

@JsonSerializable()
class TransformedData {
  final String? underlying;
  final Map<String, GroupedDataItem>? grouped;
  final List<String>? filteredExpiries;
  final List<String>? allExpiries;
  final List<double>? strikePrices;
  final double? underlyingValue;

  const TransformedData({
    this.underlying,
    this.grouped,
    this.filteredExpiries,
    this.allExpiries,
    this.strikePrices,
    this.underlyingValue,
  });

  factory TransformedData.fromJson(Map<String, dynamic> json) => _$TransformedDataFromJson(json);
  Map<String, dynamic> toJson() => _$TransformedDataToJson(this);
}