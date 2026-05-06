part of 'booking_bloc.dart';

sealed class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object> get props => [];
}

class CancelBooking extends BookingEvent {
  final String bookingId;
  final String agentUid;
  final String agentName;

  const CancelBooking({
    required this.bookingId,
    required this.agentUid,
    required this.agentName,
  });

  @override
  List<Object> get props => [bookingId, agentUid, agentName];
}

class CompleteBooking extends BookingEvent {
  final int mode;
  final String bookingId;
  final List<File> selectedFiles;
  final double serviceCost;
  final List<BookingServiceItem> serviceItems; // Changed to BookingServiceItem
  final double totalCost;
  final String technicianId;
  final String customerId;
  final double inspectionFee;

  const CompleteBooking({
    required this.mode,
    required this.selectedFiles,
    required this.serviceCost,
    required this.serviceItems,
    required this.totalCost,
    required this.bookingId,
    required this.technicianId,
    required this.customerId,
    required this.inspectionFee,
  });

  @override
  List<Object> get props => [
    mode,
    bookingId,
    selectedFiles,
    serviceCost,
    serviceItems,
    totalCost,
    technicianId,
    inspectionFee,
    customerId,
  ];
}

class StartWorkingOnBooking extends BookingEvent {
  final String bookingId;
  final String uid;
  final BuildContext context;

  const StartWorkingOnBooking({
    required this.bookingId,
    required this.uid,
    required this.context,
  });

  @override
  List<Object> get props => [bookingId, uid, context];
}

class StopWorkingOnBooking extends BookingEvent {
  final String bookingId;

  const StopWorkingOnBooking({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class PauseWorkingOnBooking extends BookingEvent {
  final String bookingId;

  const PauseWorkingOnBooking({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
