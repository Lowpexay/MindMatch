class Consultation {
  final String? id;
  final String idPsychologist;
  final String idPatient;
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
      date: data['date'] ?? 0,
      hour: data['hour'] ?? '',
      modality: data['modality'] ?? '',
      status: data['status'] ?? '',
      createdAt: data['createdAt'] ?? 0,
      updatedAt: data['updatedAt'] ?? 0,
    );
  }
}
