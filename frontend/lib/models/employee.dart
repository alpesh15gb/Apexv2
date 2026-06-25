class Employee {
  final String id;
  final String tenantId;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? departmentId;
  final String? designationId;
  final String? branchId;
  final String? shiftId;
  final DateTime joiningDate;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bloodGroup;
  final String status;
  final String? photoUrl;
  final String? deviceUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? departmentName;
  final String? designationName;
  final String? branchName;
  final String? shiftName;

  Employee({
    required this.id,
    required this.tenantId,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.departmentId,
    this.designationId,
    this.branchId,
    this.shiftId,
    required this.joiningDate,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bloodGroup,
    required this.status,
    this.photoUrl,
    this.deviceUserId,
    required this.createdAt,
    required this.updatedAt,
    this.departmentName,
    this.designationName,
    this.branchName,
    this.shiftName,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeCode: json['employee_code'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      departmentId: json['department_id'] as String?,
      designationId: json['designation_id'] as String?,
      branchId: json['branch_id'] as String?,
      shiftId: json['shift_id'] as String?,
      joiningDate: DateTime.parse(json['joining_date'] as String),
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      bloodGroup: json['blood_group'] as String?,
      status: json['status'] as String? ?? 'active',
      photoUrl: json['photo_url'] as String?,
      deviceUserId: json['device_user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      departmentName: json['department_name'] as String?,
      designationName: json['designation_name'] as String?,
      branchName: json['branch_name'] as String?,
      shiftName: json['shift_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'employee_code': employeeCode,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'department_id': departmentId,
      'designation_id': designationId,
      'branch_id': branchId,
      'shift_id': shiftId,
      'joining_date': joiningDate.toIso8601String().substring(0, 10),
      'date_of_birth': dateOfBirth?.toIso8601String().substring(0, 10),
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'blood_group': bloodGroup,
      'status': status,
      'photo_url': photoUrl,
      'device_user_id': deviceUserId,
    };
  }
}

class Department {
  final String id;
  final String tenantId;
  final String name;
  final String code;
  final bool isActive;
  final DateTime createdAt;

  Department({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.isActive,
    required this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'code': code,
      'is_active': isActive,
    };
  }
}

class Branch {
  final String id;
  final String tenantId;
  final String name;
  final String code;
  final String? address;
  final String? city;
  final bool isActive;
  final DateTime createdAt;

  Branch({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    this.address,
    this.city,
    required this.isActive,
    required this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'is_active': isActive,
    };
  }
}

class Designation {
  final String id;
  final String tenantId;
  final String name;
  final String code;
  final bool isActive;
  final DateTime createdAt;

  Designation({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.isActive,
    required this.createdAt,
  });

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'code': code,
      'is_active': isActive,
    };
  }
}
