import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final double amount;
  final String customerId;
  final String workerId;
  final String paymentStatus;
  final String paymentMethod;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String bookingId;
  final String orderId;
  final String? invoiceId;

  TransactionModel(
    this.updatedAt, {
    required this.amount,
    required this.customerId,
    required this.workerId,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.orderId,
    required this.bookingId,
    this.invoiceId,
  });

  // Add any necessary methods for your transaction model

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'customerId': customerId,
      'workerId': workerId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'bookingId': bookingId,
      'orderId': orderId,
      if (invoiceId != null) 'invoiceId': invoiceId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      map['updatedAt'],
      amount: map['amount'],
      bookingId: map['bookingId'],
      customerId: map['customerId'],
      workerId: map['workerId'],
      paymentStatus: map['paymentStatus'],
      paymentMethod: map['paymentMethod'],
      createdAt: map['createdAt'],
      orderId: map['orderId'],
      invoiceId: map['invoiceId'],
    );
  }
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Handle createdAt - can be Timestamp or String
    final createdAtValue = json['createdAt'];
    Timestamp createdAtTimestamp;
    if (createdAtValue is Timestamp) {
      createdAtTimestamp = createdAtValue;
    } else if (createdAtValue is String) {
      createdAtTimestamp = Timestamp.fromDate(DateTime.parse(createdAtValue));
    } else {
      createdAtTimestamp = Timestamp.now();
    }

    // Handle updatedAt - can be Timestamp or String
    final updatedAtValue = json['updatedAt'];
    Timestamp updatedAtTimestamp;
    if (updatedAtValue is Timestamp) {
      updatedAtTimestamp = updatedAtValue;
    } else if (updatedAtValue is String) {
      updatedAtTimestamp = Timestamp.fromDate(DateTime.parse(updatedAtValue));
    } else {
      updatedAtTimestamp = Timestamp.now();
    }

    return TransactionModel(
      updatedAtTimestamp,
      amount: json['amount'],
      bookingId: json['bookingId'],
      customerId: json['customerId'],
      workerId: json['workerId'],
      paymentStatus: json['paymentStatus'],
      paymentMethod: json['paymentMethod'],
      createdAt: createdAtTimestamp,
      orderId: json['orderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'customerId': customerId,
      'workerId': workerId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'bookingId': bookingId,
      'orderId': orderId,
    };
  }

  @override
  String toString() {
    return 'TransactionModel{amount: $amount, paymentStatus: $paymentStatus, paymentMethod: $paymentMethod, createdAt: $createdAt, updatedAt: $updatedAt, orderId: $orderId, customerId: $customerId, workerId: $workerId, bookingId: $bookingId}';
  }
}
