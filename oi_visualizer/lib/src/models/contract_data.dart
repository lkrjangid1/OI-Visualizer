import 'package:json_annotation/json_annotation.dart';
import 'greeks.dart';

part 'contract_data.g.dart';

@JsonSerializable()
class ContractData {
  final double? askPrice;
  final int? askQty;
  final double? bidprice;
  final int? bidQty;
  final double? change;
  final double? changeinOpenInterest;
  final String? expiryDate;
  final String? identifier;
  final double? impliedVolatility;
  final double? lastPrice;
  final int? openInterest;
  final double? pChange;
  final double? pchangeinOpenInterest;
  final double? strikePrice;
  final int? totalBuyQuantity;
  final int? totalSellQuantity;
  final int? totalTradedVolume;
  final String? underlying;
  final double? underlyingValue;
  final Greeks? greeks;

  const ContractData({
    this.askPrice,
    this.askQty,
    this.bidprice,
    this.bidQty,
    this.change,
    this.changeinOpenInterest,
    this.expiryDate,
    this.identifier,
    this.impliedVolatility,
    this.lastPrice,
    this.openInterest,
    this.pChange,
    this.pchangeinOpenInterest,
    this.strikePrice,
    this.totalBuyQuantity,
    this.totalSellQuantity,
    this.totalTradedVolume,
    this.underlying,
    this.underlyingValue,
    this.greeks,
  });

  factory ContractData.fromJson(Map<String, dynamic> json) => _$ContractDataFromJson(json);
  Map<String, dynamic> toJson() => _$ContractDataToJson(this);
}