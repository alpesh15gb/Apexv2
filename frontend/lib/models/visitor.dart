class Visitor {
  final String id;
  final String tenantId;
  final String name;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final String? idProofType;
  final String? idProofNumber;
  final String? company;
  final String? address;
  final DateTime createdAt;

  Visitor({
    required this.id,
    required this.tenantId,
    required this.name,
    this.phone,
    this.email,
    this.photoUrl,
    this.idProofType,
    this.idProofNumber,
    this.company,
    this.address,
    required this.createdAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      idProofType: json['id_proof_type'] as String?,
      idProofNumber: json['id_proof_number'] as String?,
      company: json['company'] as String?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'phone': phone,
      'email': email,
      'photo_url': photoUrl,
      'id_proof_type': idProofType,
      'id_proof_number': idProofNumber,
      'company': company,
      'address': address,
    };
  }
}

class VisitorPass {
  final String id;
  final String tenantId;
  final String visitorId;
  final String hostEmployeeId;
  final String purpose;
  final DateTime expectedDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String passNumber;
  final String status;
  final String? badgeNumber;
  final String? zoneAccess;
  final bool visitorDeskValidated;
  final DateTime createdAt;
  final String? visitorName;
  final String? hostName;

  VisitorPass({
    required this.id,
    required this.tenantId,
    required this.visitorId,
    required this.hostEmployeeId,
    required this.purpose,
    required this.expectedDate,
    this.checkInTime,
    this.checkOutTime,
    required this.passNumber,
    required this.status,
    this.badgeNumber,
    this.zoneAccess,
    required this.visitorDeskValidated,
    required this.createdAt,
    this.visitorName,
    this.hostName,
  });

  factory VisitorPass.fromJson(Map<String, dynamic> json) {
    return VisitorPass(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      visitorId: json['visitor_id'] as String,
      hostEmployeeId: json['host_employee_id'] as String,
      purpose: json['purpose'] as String,
      expectedDate: DateTime.parse(json['expected_date'] as String),
      checkInTime: json['check_in_time'] != null ? DateTime.parse(json['check_in_time'] as String) : null,
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time'] as String) : null,
      passNumber: json['pass_number'] as String,
      status: json['status'] as String? ?? 'scheduled',
      badgeNumber: json['badge_number'] as String?,
      zoneAccess: json['zone_access'] as String?,
      visitorDeskValidated: json['visitor_desk_validated'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      visitorName: json['visitor_name'] as String?,
      hostName: json['host_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'visitor_id': visitorId,
      'host_employee_id': hostEmployeeId,
      'purpose': purpose,
      'expected_date': expectedDate.toIso8601String().substring(0, 10),
      'badge_number': badgeNumber,
      'zone_access': zoneAccess,
    };
  }
}
