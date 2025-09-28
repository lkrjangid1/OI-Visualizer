// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contract _$ContractFromJson(Map<String, dynamic> json) => Contract(
  totalOI: (json['totalOI'] as num?)?.toInt(),
  totalVol: (json['totalVol'] as num?)?.toInt(),
);

Map<String, dynamic> _$ContractToJson(Contract instance) => <String, dynamic>{
  'totalOI': instance.totalOI,
  'totalVol': instance.totalVol,
};
