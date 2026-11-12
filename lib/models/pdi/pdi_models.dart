num _num(Object? v) =>
    v is num ? v : num.tryParse(v?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ?? 0;
String _str(Object? v) {
  final s = v?.toString().trim() ?? '';
  return s == 'null' ? '' : s;
}

/// 18% GST on top of the plan price (V1 computes it on the client too).
const double pdiGstRate = 0.18;

/// An inspection plan — `pdi/plans/` (API ref P4).
class PdiPlan {
  const PdiPlan({
    required this.id,
    required this.name,
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.description,
    required this.features,
    required this.isPopular,
  });

  final int id;

  /// Sent as `plan_type` (lower-cased): "pro", "advanced".
  final String name;
  final String title;
  final int price;
  final int oldPrice;
  final String description;
  final List<String> features;
  final bool isPopular;

  int get gst => (price * pdiGstRate).round();
  int get total => price + gst;
  int get savings => oldPrice > price ? oldPrice - price : 0;

  factory PdiPlan.fromJson(Map<String, dynamic> json) => PdiPlan(
    id: _num(json['id']).toInt(),
    name: _str(json['name']),
    title: _str(json['display_name']).isNotEmpty ? _str(json['display_name']) : _str(json['name']),
    price: _num(json['price']).round(),
    oldPrice: _num(json['old_price']).round(),
    description: _str(json['description']),
    features: [for (final f in json['feature_points'] as List? ?? const []) _str(f)],
    isPopular: json['is_popular'] == true,
  );
}

/// A bookable time — `pdi/time-slots/?date=` (P6).
class PdiSlot {
  const PdiSlot({required this.id, required this.time, required this.available});

  final int id;

  /// "09:00:00"
  final String time;
  final int available;

  /// "9:00 AM"
  String get label => formatTime(time);

  factory PdiSlot.fromJson(Map<String, dynamic> json) => PdiSlot(
    id: _num(json['id']).toInt(),
    time: _str(json['time']),
    available: json['is_active'] == false ? 0 : _num(json['available']).toInt(),
  );
}

/// "15:30:00" → "3:30 PM"
String formatTime(String hhmmss) {
  final parts = hhmmss.split(':');
  if (parts.length < 2) return hhmmss;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts[1].padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m $period';
}

/// A booked inspection — `pdi/book/` response and `pdi/bookings/` (P8–P10).
class PdiBooking {
  const PdiBooking({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.plan,
    required this.city,
    required this.project,
    required this.builder,
    required this.unitNumber,
    required this.floorNumber,
    required this.time,
    required this.price,
    required this.finalPrice,
    this.date,
    this.createdAt,
    this.notes = '',
  });

  final String id;
  final String bookingId;
  final String status;
  final String plan;
  final String city;
  final String project;
  final String builder;
  final String unitNumber;
  final String floorNumber;
  final String time;
  final int price;
  final int finalPrice;
  final DateTime? date;
  final DateTime? createdAt;
  final String notes;

  String get statusLabel =>
      status.isEmpty ? 'Booked' : status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');

  factory PdiBooking.fromJson(Map<String, dynamic> json) {
    String nameOf(Object? v, String key) =>
        v is Map ? _str(v[key] ?? v['name']) : _str(v);
    final project = nameOf(json['project'], 'name');
    final builder = nameOf(json['builder'], 'builder_name');
    final price = _num(json['price']).round();
    final finalPrice = _num(json['final_price']).round();
    return PdiBooking(
      id: _str(json['id']),
      bookingId: _str(json['booking_id']).isNotEmpty ? _str(json['booking_id']) : _str(json['id']),
      status: _str(json['status']),
      plan: _str(json['plan_type'] ?? json['plan']),
      city: _str(json['city']),
      project: project.isNotEmpty ? project : _str(json['project_other']),
      builder: builder.isNotEmpty ? builder : _str(json['builder_other']),
      unitNumber: _str(json['unit_number']),
      floorNumber: _str(json['floor_number']),
      time: _str(json['appointment_time'] ?? json['time']),
      price: price,
      finalPrice: finalPrice > 0 ? finalPrice : (price * (1 + pdiGstRate)).round(),
      date: DateTime.tryParse(_str(json['appointment_date'] ?? json['date'])),
      createdAt: DateTime.tryParse(_str(json['created_at'])),
      notes: _str(json['notes']),
    );
  }
}
