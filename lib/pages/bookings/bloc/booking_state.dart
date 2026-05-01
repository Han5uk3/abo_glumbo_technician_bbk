part of 'booking_bloc.dart';

sealed class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object> get props => [];
}

final class BookingInitial extends BookingState {}

final class BookingCancelLoading extends BookingState {}

final class BookingCancelSuccess extends BookingState {}

final class BookingCancelFailure extends BookingState {
  final String error;

  const BookingCancelFailure({required this.error});

  @override
  List<Object> get props => [error];
}

final class BookingCompleteLoading extends BookingState {}

final class BookingCompleteSuccess extends BookingState {}

final class BookingCompleteFailure extends BookingState {
  final String error;
  const BookingCompleteFailure({required this.error});
  @override
  List<Object> get props => [error];
}

final class BookingStartWorkingLoading extends BookingState {}

final class BookingStartWorkingSuccess extends BookingState {}

final class BookingStartWorkingFailure extends BookingState {
  final String error;

  const BookingStartWorkingFailure({required this.error});

  @override
  List<Object> get props => [error];
}

final class BookingStopWorkingLoading extends BookingState {}

final class BookingStopWorkingSuccess extends BookingState {}

final class BookingStopWorkingFailure extends BookingState {
  final String error;

  const BookingStopWorkingFailure({required this.error});
  @override
  List<Object> get props => [error];
}

final class BookingPauseWorkingLoading extends BookingState {}

final class BookingPauseWorkingSuccess extends BookingState {}

final class BookingPauseWorkingFailure extends BookingState {
  final String error;

  const BookingPauseWorkingFailure({required this.error});
  @override
  List<Object> get props => [error];
}
