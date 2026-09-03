import 'package:cloud_firestore/cloud_firestore.dart';

class Consultation {
  final String? id;
  final String idPsychologist;
  final String idPatient;
  final String? psychologistName;
  final String? psychologistSpecialty;
  final String? psychologistModality;
  final String? psychologistAvailability;
  final String? patientName;
  final int date; // millisecondsSinceEpoch
  final String hour; // e.g., "14:30"
  final String modality; // IN_PERSON, CALL, MESSAGE
  final String status; // SCHEDULED, CANCELED, RESCHEDULED
  final int createdAt;
  final int updatedAt;

  Consultation({
    this.id,
    required this.idPsychologist,
    required this.idPatient,
    this.psychologistName,
    this.psychologistSpecialty,
    this.psychologistModality,
    this.psychologistAvailability,
    this.patientName,
    required this.date,
    required this.hour,
    required this.modality,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'idPsychologist': idPsychologist,
      'idPatient': idPatient,
      if (psychologistName != null) 'psychologistName': psychologistName,
      if (psychologistSpecialty != null) 'psychologistSpecialty': psychologistSpecialty,
      if (psychologistModality != null) 'psychologistModality': psychologistModality,
      if (psychologistAvailability != null) 'psychologistAvailability': psychologistAvailability,
      if (patientName != null) 'patientName': patientName,
      'date': date,
      'hour': hour,
      'modality': modality,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Consultation.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    return Consultation(
      id: docId,
      idPsychologist: data['idPsychologist'] ?? '',
      idPatient: data['idPatient'] ?? '',
      psychologistName: data['psychologistName']?.toString(),
      psychologistSpecialty: data['psychologistSpecialty']?.toString(),
      psychologistModality: data['psychologistModality']?.toString(),
      psychologistAvailability: data['psychologistAvailability']?.toString(),
      patientName: data['patientName']?.toString(),
      date: _toEpochMillis(data['date']),
      hour: data['hour']?.toString() ?? '',
      modality: data['modality']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      createdAt: _toEpochMillis(data['createdAt']),
      updatedAt: _toEpochMillis(data['updatedAt']),
    );
  }

  static int _toEpochMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
