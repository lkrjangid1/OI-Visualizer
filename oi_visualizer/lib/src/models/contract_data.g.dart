// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractData _$ContractDataFromJson(Map<String, dynamic> json) => ContractData(
  askPrice: (json['askPrice'] as num?)?.toDouble(),
  askQty: (json['askQty'] as num?)?.toInt(),
  bidprice: (json['bidprice'] as num?)?.toDouble(),
  bidQty: (json['bidQty'] as num?)?.toInt(),
  change: (json['change'] as num?)?.toDouble(),
  changeinOpenInterest: (json['changeinOpenInterest'] as num?)?.toDouble(),
  expiryDate: json['expiryDate'] as String?,
  identifier: json['identifier'] as String?,
  impliedVolatility: (json['impliedVolatility'] as num?)?.toDouble(),
  lastPrice: (json['lastPrice'] as num?)?.toDouble(),
  openInterest: (json['openInterest'] as num?)?.toInt(),
  pChange: (json['pChange'] as num?)?.toDouble(),
  pchangeinOpenInterest: (json['pchangeinOpenInterest'] as num?)?.toDouble(),
  strikePrice: (json['strikePrice'] as num?)?.toDouble(),
  totalBuyQuantity: (json['totalBuyQuantity'] as num?)?.toInt(),
  totalSellQuantity: (json['totalSellQuantity'] as num?)?.toInt(),
  totalTradedVolume: (json['totalTradedVolume'] as num?)?.toInt(),
  underlying: json['underlying'] as String?,
  underlyingValue: (json['underlyingValue'] as num?)?.toDouble(),
  greeks:
      json['greeks'] == null
          ? null
          : Greeks.fromJson(json['greeks'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ContractDataToJson(ContractData instance) =>
    <String, dynamic>{
      'askPrice': instance.askPrice,
      'askQty': instance.askQty,
      'bidprice': instance.bidprice,
      'bidQty': instance.bidQty,
      'change': instance.change,
      'changeinOpenInterest': instance.changeinOpenInterest,
      'expiryDate': instance.expiryDate,
      'identifier': instance.identifier,
      'impliedVolatility': instance.impliedVolatility,
      'lastPrice': instance.lastPrice,
      'openInterest': instance.openInterest,
      'pChange': instance.pChange,
      'pchangeinOpenInterest': instance.pchangeinOpenInterest,
      'strikePrice': instance.strikePrice,
      'totalBuyQuantity': instance.totalBuyQuantity,
      'totalSellQuantity': instance.totalSellQuantity,
      'totalTradedVolume': instance.totalTradedVolume,
      'underlying': instance.underlying,
      'underlyingValue': instance.underlyingValue,
      'greeks': instance.greeks,
    };
