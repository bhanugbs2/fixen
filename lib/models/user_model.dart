class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobileNumber;
  final String address;
  final String profileImage;
  final String role; // 'user', 'worker', 'admin'
  
  // Worker-specific fields
  final String? governmentId;
  final String? verificationStatus; // 'pending', 'approved', 'rejected', 'suspended'
  final int? experience;
  final List<String>? languages;
  final String? workingHours;
  final double? rating;
  final int? reviewCount;
  final bool? isOnline;
  final double? commissionDue;
  final bool? isBlocked;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.profileImage,
    required this.role,
    this.governmentId,
    this.verificationStatus,
    this.experience,
    this.languages,
    this.workingHours,
    this.rating,
    this.reviewCount,
    this.isOnline,
    this.commissionDue,
    this.isBlocked,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      address: json['address'] ?? '',
      profileImage: json['profileImage'] ?? '',
      role: json['role'] ?? 'user',
      governmentId: json['governmentId'],
      verificationStatus: json['verificationStatus'],
      experience: json['experience'] is int ? json['experience'] : int.tryParse(json['experience']?.toString() ?? ''),
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      workingHours: json['workingHours'],
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : double.tryParse(json['rating']?.toString() ?? ''),
      reviewCount: json['reviewCount'] is int ? json['reviewCount'] : int.tryParse(json['reviewCount']?.toString() ?? ''),
      isOnline: json['isOnline'] is bool ? json['isOnline'] : json['isOnline'] == 'true',
      commissionDue: json['commissionDue'] is num ? (json['commissionDue'] as num).toDouble() : double.tryParse(json['commissionDue']?.toString() ?? ''),
      isBlocked: json['isBlocked'] is bool ? json['isBlocked'] : json['isBlocked'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'address': address,
      'profileImage': profileImage,
      'role': role,
      'governmentId': governmentId,
      'verificationStatus': verificationStatus,
      'experience': experience,
      'languages': languages,
      'workingHours': workingHours,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOnline': isOnline,
      'commissionDue': commissionDue,
      'isBlocked': isBlocked,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? mobileNumber,
    String? address,
    String? profileImage,
    String? role,
    String? governmentId,
    String? verificationStatus,
    int? experience,
    List<String>? languages,
    String? workingHours,
    double? rating,
    int? reviewCount,
    bool? isOnline,
    double? commissionDue,
    bool? isBlocked,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      governmentId: governmentId ?? this.governmentId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      experience: experience ?? this.experience,
      languages: languages ?? this.languages,
      workingHours: workingHours ?? this.workingHours,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOnline: isOnline ?? this.isOnline,
      commissionDue: commissionDue ?? this.commissionDue,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
