/// Represents an active training period for a client.  A period has a start
/// date (the first lesson day) and an automatically calculated end date based
/// on the client's weekly schedule and purchased package size.
class Period {
  final int? id;
  final int? clientId;
  final String startDate; // ISO8601 string
  final String endDate; // ISO8601 string
  final String?
  postponedEndDate; // Ötelenmiş bitiş tarihi (iptal edilen dersler nedeniyle)
  final double? paymentAmount; // Ödeme tutarı
  final bool isPaid; // Ödeme yapıldı mı

  Period({
    this.id,
    this.clientId,
    required this.startDate,
    required this.endDate,
    this.postponedEndDate,
    this.paymentAmount,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'startDate': startDate,
      'endDate': endDate,
      'postponedEndDate': postponedEndDate,
      'paymentAmount': paymentAmount,
      'isPaid': isPaid ? 1 : 0,
    };
  }

  factory Period.fromMap(Map<String, dynamic> map) {
    return Period(
      id: map['id'] as int?,
      clientId: map['clientId'] as int?,
      startDate: map['startDate'] as String,
      endDate: map['endDate'] as String,
      postponedEndDate: map['postponedEndDate'] as String?,
      paymentAmount: map['paymentAmount'] as double?,
      isPaid: (map['isPaid'] as int? ?? 0) == 1,
    );
  }

  Period copyWith({
    int? id,
    int? clientId,
    String? startDate,
    String? endDate,
    String? postponedEndDate,
    double? paymentAmount,
    bool? isPaid,
  }) {
    return Period(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      postponedEndDate: postponedEndDate ?? this.postponedEndDate,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
