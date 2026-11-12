String _str(Object? v) => v?.toString().trim() ?? '';

/// `{value, label}` pair from the options endpoint.
class OptionItem {
  const OptionItem(this.value, this.label);

  final String value;
  final String label;

  factory OptionItem.fromJson(Map<String, dynamic> json) =>
      OptionItem(_str(json['value']), _str(json['label']));
}

/// `GET consultations/options/` (API ref K1).
class ConsultationOptions {
  const ConsultationOptions({
    required this.serviceTypes,
    required this.consultationTypes,
    required this.timeSlots,
  });

  final List<OptionItem> serviceTypes;
  final List<OptionItem> consultationTypes;
  final List<OptionItem> timeSlots;

  /// Used when the options call fails (same values the API returns today).
  static const fallback = ConsultationOptions(
    serviceTypes: [
      OptionItem('legal', 'Legal Consultation'),
      OptionItem('taxation', 'CA & CS Consultation'),
      OptionItem('property_advice', 'Property Advisory'),
      OptionItem('loan_assistance', 'Loan Assistance'),
      OptionItem('other', 'Other Services'),
    ],
    consultationTypes: [
      OptionItem('new_property', 'New Property'),
      OptionItem('old_property', 'Old Property'),
      OptionItem('other', 'Other'),
    ],
    timeSlots: [
      OptionItem('10-12', '10 AM - 12 PM'),
      OptionItem('12-2', '12 PM - 2 PM'),
      OptionItem('2-4', '2 PM - 4 PM'),
      OptionItem('4-6', '4 PM - 6 PM'),
    ],
  );

  factory ConsultationOptions.fromJson(Map<String, dynamic> json) {
    List<OptionItem> list(String key) => [
      for (final item in json[key] as List? ?? const [])
        if (item is Map) OptionItem.fromJson(Map<String, dynamic>.from(item)),
    ];
    final options = ConsultationOptions(
      serviceTypes: list('service_types'),
      consultationTypes: list('consultation_types'),
      timeSlots: list('time_slots'),
    );
    return options.serviceTypes.isEmpty ? fallback : options;
  }
}

/// One booked consultation (K3/K4).
class Consultation {
  const Consultation({
    required this.id,
    required this.service,
    required this.type,
    required this.timeSlot,
    required this.status,
    required this.statusLabel,
    this.bookingId = '',
    this.notes = '',
    this.createdAt,
  });

  final int id;
  final String bookingId;
  final String service;
  final String type;
  final String timeSlot;

  /// pending / confirmed / completed / cancelled / rescheduled
  final String status;
  final String statusLabel;
  final String notes;
  final DateTime? createdAt;

  bool get canCancel => status == 'pending' || status == 'confirmed';

  factory Consultation.fromJson(Map<String, dynamic> json) {
    String pick(String display, String raw) =>
        _str(json[display]).isNotEmpty ? _str(json[display]) : _str(json[raw]);
    return Consultation(
      id: int.tryParse(_str(json['id'])) ?? 0,
      bookingId: _str(json['booking_id']),
      service: pick('service_type_display', 'service_type'),
      type: pick('consultation_type_display', 'consultation_type'),
      timeSlot: pick('time_slot_display', 'time_slot'),
      status: _str(json['status']),
      statusLabel: pick('status_display', 'status'),
      notes: _str(json['additional_notes']),
      createdAt: DateTime.tryParse(_str(json['created_at'])),
    );
  }
}
