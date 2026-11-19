// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovementDto _$MovementDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MovementDto', json, ($checkedConvert) {
      final val = MovementDto(
        id: $checkedConvert('id', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        amount: $checkedConvert('amount', (v) => v as num),
        type: $checkedConvert('type', (v) => v as String),
        status: $checkedConvert('status', (v) => v as String),
        date: $checkedConvert('date', (v) => v as String?),
        currency: $checkedConvert('currency', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$MovementDtoToJson(MovementDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'amount': instance.amount,
      'type': instance.type,
      'status': instance.status,
      'date': instance.date,
      'currency': instance.currency,
    };
