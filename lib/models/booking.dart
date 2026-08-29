import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/warranty.dart';
import 'package:aboglumbo_bbk_panel/models/counter_offer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/customer.dart';
import '/models/service.dart';

class BookingModel {
  String id;
  String? newBookingId;
  late ServiceModel service;
  late Timestamp bookingDateTime;
  late String bookingStatusCode;
  /// Warranty complaint escalation. The customer raises a complaint against an
  /// unresolved warranty claim (`isEscalated: true` + [escalatedAt]); an admin
  /// closes it out with [resolutionText] + [resolvedAt], which clears the flag.
  bool? isEscalated;
  Timestamp? escalatedAt;

  /// What the admin wrote when resolving the customer's complaint.
  String? resolutionText;
  Timestamp? resolvedAt;
  late String notes;
  late String? issueImage;
  late String? issueVideo;
  late CustomerModel customer;
  CompletionDataModel?
  completionData; // This now contains List<String> imageUrls
  late String paymentModeCode;
  String? chatroomId = "";
  bool isRatingSheetShown = false;

  ReviewModel? review;
  UserModel? agent;
  bool? isStartTracking;
  List<CancelledWorkers> cancelledWorkers;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  Timestamp? acceptedAt;
  Timestamp? rejectedAt;
  Timestamp? completedAt;
  Timestamp? trackingStartedAt;
  Timestamp? trackingStoppedAt;
  Timestamp? cancelledAt;
  Timestamp? arrivedAt; // ✅ Added
  Timestamp? paymentRequestedAt; // ✅ Added
  Timestamp? assignedAt; // ✅ Added
  Timestamp? reassignedAt; // ✅ Added
  Timestamp? technicianSelectedAt; // ✅ Added
  String? cancelledBy; // ✅ Added (Customer, Technician, Admin)
  String? cancellationReason;
  String? rejectedBy;
  String? orderId;
  String? transactionId; // Added transactionId
  Timestamp? paymentCompletedAt;
  Timestamp? paymentVerifiedAt;
  Timestamp? counterProposalAcceptedAt;
  Timestamp? counterProposalStartedAt;

  bool paymentCompleted = false;
  List<String>? cancelledWorkerUids;
  List<String>? technicianPaymentProof;

  WarrantyModel? warranty;
  CounterOfferModel? activeCounterOffer;
  bool? isOnHour; // ✅ Added
  String? autoAssignmentStatus; // ✅ Added
  Timestamp? assignmentScheduledTime;
  String? rebookTechnicianId; // ✅ Added

  /// The polygon service zone matched when the customer validated their address.
  /// Written by the customer app; read here by the technician/admin app.
  BookingServiceLocation? serviceLocation;

  final String? invoiceId;
  final String? invoicePdfUrl; // Fallback for old bookings
  final String? invoicePdfUrlEn;
  final String? invoicePdfUrlAr;
  final String? invoicePdfUrlUr;

  /// Returns the correct inspection fee based on the on-hour/off-hour status
  /// The inspection fee for this booking's on-hour/off-hour band, and 0 when
  /// that band is not priced.
  ///
  /// `service.price` is deliberately not a fallback. It must stay in step with
  /// the customer app's `BookingModel.effectiveInspectionFee`, which is what
  /// the customer is actually shown and charged — if this one fell back to a
  /// price the customer app no longer uses, the technician would be credited
  /// an amount the customer was never billed.
  ///
  /// The service's general price is not lost by this: it is captured onto
  /// `completionData.generalServicePrice` at completion, where it is the basis
  /// for the monthly bonus. See `AppServices.completeBooking`.
  double get effectiveInspectionFee {
    if (isOnHour == true) {
      return service.onWorkHourPrice ?? 0.0;
    } else {
      return service.offWorkHourPrice ?? 0.0;
    }
  }

  /// Returns the formatted string for the customer's selected service address.
  /// Prioritizes the address with isSelected == true.
  String get customerSelectedAddressText {
    try {
      final selectedAddress = customer.addresses.firstWhere(
        (address) => address.isSelected == true,
      );
      final text =
          "${selectedAddress.buildingNumber.isNotEmpty ? '${selectedAddress.buildingNumber}, ' : ''}${selectedAddress.streetName ?? ''}"
              .trim();
      if (text.isNotEmpty && text != ',') {
        return text;
      }
    } catch (e) {
      // Ignored
    }

    try {
      if (customer.addresses.isNotEmpty) {
        final firstAddress = customer.addresses.first;
        final text =
            "${firstAddress.buildingNumber.isNotEmpty ? '${firstAddress.buildingNumber}, ' : ''}${firstAddress.streetName ?? ''}"
                .trim();
        if (text.isNotEmpty && text != ',') {
          return text;
        }
      }
    } catch (e) {
      // Ignored
    }

    if (customer.location?.fullAddress != null &&
        customer.location!.fullAddress!.isNotEmpty) {
      return customer.location!.fullAddress!;
    }

    return '';
  }

  /// Returns the correct invoice PDF URL based on the given locale.
  /// Falls back to the old `invoicePdfUrl` if the specific language one is missing.
  String? getInvoiceUrlForLocale(String localeName) {
    if (localeName == 'ar' && invoicePdfUrlAr != null && invoicePdfUrlAr!.isNotEmpty) {
      return invoicePdfUrlAr;
    } else if (localeName == 'ur' && invoicePdfUrlUr != null && invoicePdfUrlUr!.isNotEmpty) {
      return invoicePdfUrlUr;
    } else if (localeName == 'en' && invoicePdfUrlEn != null && invoicePdfUrlEn!.isNotEmpty) {
      return invoicePdfUrlEn;
    }
    return invoicePdfUrl;
  }

  BookingModel({
    required this.id,
    this.newBookingId,
    required this.paymentCompletedAt,
    this.paymentVerifiedAt,
    required this.service,
    required this.bookingDateTime,
    required this.bookingStatusCode,
    this.cancelledWorkers = const [],
    required this.notes,
    required this.issueImage,
    required this.issueVideo,
    required this.customer,
    required this.paymentModeCode,
    this.isStartTracking,
    this.review,
    this.chatroomId = '',
    this.agent,
    this.completionData, // Add this
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.completedAt,
    this.trackingStartedAt,
    this.trackingStoppedAt,
    this.cancelledAt,
    this.arrivedAt, // ✅ Added
    this.paymentRequestedAt, // ✅ Added
    this.assignedAt, // ✅ Added
    this.reassignedAt, // ✅ Added
    this.technicianSelectedAt, // ✅ Added
    this.cancelledBy, // ✅ Added
    this.cancellationReason,
    this.rejectedBy,
    this.orderId,
    this.transactionId, // Added transactionId
    this.cancelledWorkerUids,
    this.serviceLocation,
    this.paymentCompleted = false,
    this.technicianPaymentProof,
    this.warranty,
    this.activeCounterOffer,
    this.isOnHour, // ✅ Added
    this.autoAssignmentStatus, // ✅ Added
    this.assignmentScheduledTime,
    this.counterProposalAcceptedAt,
    this.counterProposalStartedAt,
    this.rebookTechnicianId, // ✅ Added
    this.isEscalated,
    this.escalatedAt,
    this.resolutionText,
    this.resolvedAt,
    this.invoiceId,
    this.invoicePdfUrl,
    this.invoicePdfUrlEn,
    this.invoicePdfUrlAr,
    this.invoicePdfUrlUr,
    this.isRatingSheetShown = false,
  });

  BookingModel.fromMap(Map<String, dynamic> data)
    : service = ServiceModel.fromJson(data['service']),
      bookingDateTime = data['bookingDateTime'],
      bookingStatusCode = data['bookingStatusCode'],
      cancelledWorkers = data['cancelledWorkers'] != null
          ? (data['cancelledWorkers'] as List)
                .map((e) => CancelledWorkers.fromMap(e))
                .toList()
          : [],
      paymentCompletedAt = data['paymentCompletedAt'] as Timestamp?,
      paymentVerifiedAt = data['paymentVerifiedAt'] as Timestamp?,
      isStartTracking = data['isStarted'] ?? false,
      notes = data['notes'],
      id = data['id'] ?? '',
      isEscalated = data['isEscalated'] ?? false,
      escalatedAt = data['escalatedAt'] as Timestamp?,
      resolutionText = data['resolutionText'] as String?,
      resolvedAt = data['resolvedAt'] as Timestamp?,
      newBookingId = data['newBookingId'],
      chatroomId = data['chatroomId'],
      issueImage = data['issueImage'],
      warranty = data['warranty'] != null
          ? WarrantyModel.fromJson(data['warranty'])
          : null,
      issueVideo = data['issueVideo'],
      customer = CustomerModel.fromJson(data['customer']),
      paymentModeCode = data['paymentModeCode'],
      review = data['review'] != null
          ? ReviewModel.fromMap(data['review'])
          : null,
      completionData = data['completionData'] != null
          ? CompletionDataModel.fromMap(data['completionData'])
          : null, // Parse completion data
      agent = data['agent'] != null ? UserModel.fromJson(data['agent']) : null,
      createdAt = data['createdAt'] as Timestamp?,
      updatedAt = data['updatedAt'] as Timestamp?,
      acceptedAt = data['acceptedAt'] as Timestamp?,
      rejectedAt = data['rejectedAt'] as Timestamp?,
      completedAt = data['completedAt'] as Timestamp?,
      cancellationReason = data['cancellationReason'],
      paymentCompleted = data['paymentCompleted'] ?? false,
      trackingStartedAt = data['trackingStartedAt'] as Timestamp?,
      trackingStoppedAt = data['trackingStoppedAt'] as Timestamp?,
      orderId = data['orderId'],
      activeCounterOffer = data['activeCounterOffer'] != null
          ? CounterOfferModel.fromMap(data['activeCounterOffer'])
          : null,
      transactionId = data['transactionId'], // Added transactionId
      cancelledWorkerUids = data['cancelledWorkerUids'] != null
          ? List<String>.from(data['cancelledWorkerUids'])
          : null,
      serviceLocation = data['serviceLocation'] != null
          ? BookingServiceLocation.fromJson(
              data['serviceLocation'] as Map<String, dynamic>,
            )
          : null,
      rejectedBy = data['rejectedBy'] as String?,
      isOnHour = data['isOnHour'], // ✅ Added
      autoAssignmentStatus = data['autoAssignmentStatus'], // ✅ Added
      assignmentScheduledTime = data['assignmentScheduledTime'],
      technicianPaymentProof = data['technicianPaymentProof'] != null
          ? List<String>.from(data['technicianPaymentProof'])
          : null,
      arrivedAt = data['arrivedAt'] as Timestamp?, // ✅ Added
      paymentRequestedAt = data['paymentRequestedAt'] as Timestamp?, // ✅ Added
      assignedAt = data['assignedAt'] as Timestamp?, // ✅ Added
      reassignedAt = data['reassignedAt'] as Timestamp?, // ✅ Added
      technicianSelectedAt =
          data['technicianSelectedAt'] as Timestamp?, // ✅ Added
      cancelledBy = data['cancelledBy'] as String?, // ✅ Added
      cancelledAt = data['cancelledAt'] as Timestamp?,
      counterProposalAcceptedAt =
          data['counterProposalAcceptedAt'] as Timestamp?,
      counterProposalStartedAt = data['counterProposalStartedAt'] as Timestamp?,
      rebookTechnicianId = data['rebookTechnicianId'] as String?,
      invoiceId = data['invoiceId'] as String?,
      invoicePdfUrl = data['invoicePdfUrl'] as String?,
      invoicePdfUrlEn = data['invoicePdfUrlEn'] as String?,
      invoicePdfUrlAr = data['invoicePdfUrlAr'] as String?,
      invoicePdfUrlUr = data['invoicePdfUrlUr'] as String?,
      isRatingSheetShown = data['isRatingSheetShown'] ?? false;

  factory BookingModel.fromQueryDocumentSnapshot(
    QueryDocumentSnapshot snapshot,
  ) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return BookingModel.fromMap(data);
  }

  factory BookingModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return BookingModel.fromMap(data);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'service': service.toJson(),
      'bookingDateTime': bookingDateTime,
      'bookingStatusCode': bookingStatusCode,
      'notes': notes,
      'paymentCompletedAt': paymentCompletedAt,
      'paymentVerifiedAt': paymentVerifiedAt,
      'issueImage': issueImage,
      'customer': customer.toJson(),
      'orderId': orderId,
      'transactionId': transactionId, // Added transactionId
      'chatroomId': chatroomId,
      'issueVideo': issueVideo,
      'cancelledWorkers': cancelledWorkers.map((e) => e.toJson()).toList(),
      'paymentModeCode': paymentModeCode,
      'isStarted': isStartTracking ?? false,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'acceptedAt': acceptedAt,
      'rejectedAt': rejectedAt,
      'completedAt': completedAt,
      'trackingStartedAt': trackingStartedAt,
      'trackingStoppedAt': trackingStoppedAt,
      'cancelledWorkerUids': cancelledWorkerUids,
      'cancelledAt': cancelledAt,
      'arrivedAt': arrivedAt, // ✅ Added
      'paymentRequestedAt': paymentRequestedAt, // ✅ Added
      'assignedAt': assignedAt, // ✅ Added
      'reassignedAt': reassignedAt, // ✅ Added
      'technicianSelectedAt': technicianSelectedAt, // ✅ Added
      'cancelledBy': cancelledBy, // ✅ Added
      'cancellationReason': cancellationReason,
      'rejectedBy': rejectedBy,
      'paymentCompleted': paymentCompleted,
      'technicianPaymentProof': technicianPaymentProof,
      'activeCounterOffer': activeCounterOffer?.toMap(),
      'isOnHour': isOnHour, // ✅ Added
      'autoAssignmentStatus': autoAssignmentStatus, // ✅ Added
      'assignmentScheduledTime': assignmentScheduledTime,
      'rebookTechnicianId': rebookTechnicianId, // ✅ Added
      'isEscalated': isEscalated ?? false,
      'escalatedAt': escalatedAt,
      'resolutionText': resolutionText,
      'resolvedAt': resolvedAt,
      'invoiceId': invoiceId,
      'invoicePdfUrl': invoicePdfUrl,
      if (invoicePdfUrlEn != null) 'invoicePdfUrlEn': invoicePdfUrlEn,
      if (invoicePdfUrlAr != null) 'invoicePdfUrlAr': invoicePdfUrlAr,
      if (invoicePdfUrlUr != null) 'invoicePdfUrlUr': invoicePdfUrlUr,
      'isRatingSheetShown': isRatingSheetShown,
    };

    map['id'] = id;
    if (newBookingId != null) {
      map['newBookingId'] = newBookingId;
    }
    if (serviceLocation != null) {
      map['serviceLocation'] = serviceLocation!.toJson();
    }
    if (warranty != null) {
      map['warranty'] = warranty!.toJson();
    }
    if (review != null) {
      map['review'] = review!.toJson();
    }
    if (agent != null) {
      map['agent'] = agent!.toJson();
    }
    if (completionData != null) {
      map['completionData'] = completionData!.toJson();
    }
    return map;
  }
}

/// The service zone that the customer's address matched during booking validation.
/// Stored on the booking document by the customer app; read by the technician/admin app.
class BookingServiceLocation {
  final String nameEn;
  final String nameAr;
  final String nameUr;
  final int priority;

  const BookingServiceLocation({
    required this.nameEn,
    required this.nameAr,
    required this.nameUr,
    required this.priority,
  });

  factory BookingServiceLocation.fromJson(Map<String, dynamic> json) {
    return BookingServiceLocation(
      nameEn: json['nameEn'] as String? ?? json['en_name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['ar_name'] as String? ?? '',
      nameUr:
          json['nameUr'] as String? ??
          json['ur_name'] as String? ??
          json['nameAr'] as String? ??
          json['nameEn'] as String? ??
          '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'nameEn': nameEn,
    'nameAr': nameAr,
    'nameUr': nameUr,
    'priority': priority,
  };

  String localizedName(String? locale) => locale == 'ar'
      ? nameAr
      : locale == 'ur'
      ? nameUr
      : nameEn;
}

class ReviewModel {
  int? rating;
  String review;
  double? tipAmount;
  String? paymentType;
  bool? isTipPaid;
  Timestamp? createdAt;
  String? workerId;
  ReviewModel({
    required this.rating,
    required this.review,
    this.createdAt,
    this.tipAmount,
    this.paymentType,
    this.isTipPaid,
    this.workerId,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data) {
    return ReviewModel(
      rating: data['rating'] != null
          ? (data['rating'] is int
                ? data['rating'] as int
                : (data['rating'] as num).toInt())
          : null,
      review: data['review']?.toString() ?? '', // ✅ Fixed: Safe conversion
      tipAmount:
          data['tipAmount'] !=
              null // ✅ Fixed: Check null first
          ? (data['tipAmount'] is double
                ? data['tipAmount'] as double
                : (data['tipAmount'] as num).toDouble())
          : null,
      paymentType: data['paymentType'] as String?, // ✅ Make nullable
      isTipPaid: data['isTipPaid'] as bool?, // ✅ Make nullable
      createdAt: data['createdAt'] as Timestamp?, // ✅ Make nullable
      workerId: data['workerId'] as String?, // ✅ Make nullable
    );
  }
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel.fromMap(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'review': review,
      'tipAmount': tipAmount,
      'paymentType': paymentType,
      'isTipPaid': isTipPaid,
      'createdAt': createdAt,
      'workerId': workerId,
    };
  }

  ReviewModel copyWith({
    int? rating,
    String? review,
    double? tipAmount,
    String? paymentType,
    bool? isTipPaid,
    Timestamp? createdAt,
    String? workerId,
  }) {
    return ReviewModel(
      rating: rating ?? this.rating,
      review: review ?? this.review,
      tipAmount: tipAmount ?? this.tipAmount,
      paymentType: paymentType ?? this.paymentType,
      isTipPaid: isTipPaid ?? this.isTipPaid,
      createdAt: createdAt ?? this.createdAt,
      workerId: workerId ?? this.workerId,
    );
  }
}

class CancelledWorkers {
  String uid;
  String agentName;
  Timestamp cancelledAt;

  CancelledWorkers({
    required this.uid,
    required this.agentName,
    required this.cancelledAt,
  });

  factory CancelledWorkers.fromMap(Map<String, dynamic> data) {
    return CancelledWorkers(
      uid: data['uid'],
      agentName: data['agentName'],
      cancelledAt: data['cancelledAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'agentName': agentName, 'cancelledAt': cancelledAt};
  }
}

class CompletionDataModel {
  final List<String> fileUrls; // Changed from imageUrls
  final int mode;
  final String paymentMethod;
  final double serviceCost;
  final double totalCost;
  final List<BookingServiceItem> serviceItems;
  final double inspectionFee;

  /// The service's general price, captured at completion purely as the basis
  /// for the technician's monthly bonus when [inspectionFee] is 0 (the
  /// booking's on-hour/off-hour band carries no price). Never shown to the
  /// customer - their app's CompletionDataModel does not even parse it.
  final double generalServicePrice;

  CompletionDataModel({
    required this.fileUrls, // Changed
    required this.mode,
    required this.paymentMethod,
    required this.serviceCost,
    required this.totalCost,
    required this.serviceItems,
    required this.inspectionFee,
    this.generalServicePrice = 0.0,
  });

  factory CompletionDataModel.fromMap(Map<String, dynamic> data) {
    return CompletionDataModel(
      fileUrls: data['fileUrls'] != null
          ? List<String>.from(data['fileUrls'])
          : (data['imageUrls'] != null
                ? List<String>.from(data['imageUrls']) // Support old field name
                : (data['imageUrl'] != null
                      ? [data['imageUrl']]
                      : [])), // Backward compatibility
      mode: data['mode'] ?? 0,
      paymentMethod: data['paymentMethod'] ?? '',
      serviceCost: data['serviceCost']?.toDouble() ?? 0.0,
      totalCost: data['totalCost']?.toDouble() ?? 0.0,
      inspectionFee: data['inspectionFee']?.toDouble() ?? 0.0,
      generalServicePrice:
          data['generalServicePrice']?.toDouble() ?? 0.0,
      serviceItems:
          (data['serviceItems'] as List<dynamic>?)
              ?.map(
                (item) => BookingServiceItem(
                  name: item['name'] ?? '',
                  quantity: item['quantity']?.toDouble() ?? 0.0,
                  price: item['price']?.toDouble() ?? 0.0,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileUrls': fileUrls, // Changed from imageUrls
      'mode': mode,
      'paymentMethod': paymentMethod,
      'serviceCost': serviceCost,
      'totalCost': totalCost,
      'inspectionFee': inspectionFee,
      // Preserved on round-trip so re-serialising a completed booking cannot
      // silently drop the monthly bonus basis.
      'generalServicePrice': generalServicePrice,
      'serviceItems': serviceItems.map((e) => e.toMap()).toList(),
    };
  }

  // Helper getter for backward compatibility
  String? get firstFileUrl => fileUrls.isNotEmpty ? fileUrls.first : null;

  // Get only image URLs from the file list
  List<String> get imageUrls {
    return fileUrls.where((url) {
      String lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.jpg') ||
          lowerUrl.endsWith('.jpeg') ||
          lowerUrl.endsWith('.png');
    }).toList();
  }

  // Get only document URLs from the file list
  List<String> get documentUrls {
    return fileUrls.where((url) {
      String lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.pdf') ||
          lowerUrl.endsWith('.doc') ||
          lowerUrl.endsWith('.docx');
    }).toList();
  }
}

class BookingServiceItem {
  final String name;
  final double quantity;
  final double price;

  const BookingServiceItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity, 'price': price};
  }
}
