part of 'warranty_bloc.dart';

abstract class WarrantyEvent extends Equatable {
  const WarrantyEvent();

  @override
  List<Object> get props => [];
}

class AcceptWarranty extends WarrantyEvent {
  final String bookingId;

  const AcceptWarranty({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class RejectWarranty extends WarrantyEvent {
  final String bookingId;

  const RejectWarranty({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class AdminRejectWarranty extends WarrantyEvent {
  final String bookingId;

  const AdminRejectWarranty({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class CancelWarranty extends WarrantyEvent {
  final String bookingId;
  final String technicianUid;
  final String technicianName;
  final String technicianPhone;
  final String rejectionReason;

  const CancelWarranty({
    required this.bookingId,
    required this.technicianUid,
    required this.technicianName,
    required this.technicianPhone,
    required this.rejectionReason,
  });

  @override
  List<Object> get props => [
    bookingId,
    technicianUid,
    technicianName,
    technicianPhone,
    rejectionReason,
  ];
}

class CompleteWarranty extends WarrantyEvent {
  final String bookingId;

  const CompleteWarranty({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class StartWorkingOnWarranty extends WarrantyEvent {
  final String bookingId;
  final String uid;
  final BuildContext context;

  const StartWorkingOnWarranty({
    required this.bookingId,
    required this.uid,
    required this.context,
  });

  @override
  List<Object> get props => [bookingId, uid];
}

class StopWorkingOnWarranty extends WarrantyEvent {
  final String bookingId;

  const StopWorkingOnWarranty({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class PauseWorkingOnWarranty extends WarrantyEvent {
  final String bookingId;

  const PauseWorkingOnWarranty({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class AssignWarrantyTechnician extends WarrantyEvent {
  final String bookingId;
  final UserModel technician;

  const AssignWarrantyTechnician({
    required this.bookingId,
    required this.technician,
  });

  @override
  List<Object> get props => [bookingId, technician];
}
