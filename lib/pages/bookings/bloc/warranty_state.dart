part of 'warranty_bloc.dart';

abstract class WarrantyState extends Equatable {
  const WarrantyState();

  @override
  List<Object> get props => [];
}

class WarrantyInitial extends WarrantyState {}

// Accept Warranty States
class WarrantyAcceptLoading extends WarrantyState {}

class WarrantyAcceptSuccess extends WarrantyState {}

class WarrantyAcceptFailure extends WarrantyState {
  final String error;

  const WarrantyAcceptFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Reject Warranty States
class WarrantyRejectLoading extends WarrantyState {}

class WarrantyRejectSuccess extends WarrantyState {}

class WarrantyRejectFailure extends WarrantyState {
  final String error;

  const WarrantyRejectFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Cancel Warranty States
class WarrantyCancelLoading extends WarrantyState {}

class WarrantyCancelSuccess extends WarrantyState {}

class WarrantyCancelFailure extends WarrantyState {
  final String error;

  const WarrantyCancelFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// Complete Warranty States
class WarrantyCompleteLoading extends WarrantyState {}

class WarrantyCompleteSuccess extends WarrantyState {}

class WarrantyCompleteFailure extends WarrantyState {
  final String error;

  const WarrantyCompleteFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// Start Working on Warranty States
class WarrantyStartWorkingLoading extends WarrantyState {}

class WarrantyStartWorkingSuccess extends WarrantyState {}

class WarrantyStartWorkingFailure extends WarrantyState {
  final String error;

  const WarrantyStartWorkingFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// Stop Working on Warranty States
class WarrantyStopWorkingLoading extends WarrantyState {}

class WarrantyStopWorkingSuccess extends WarrantyState {}

class WarrantyStopWorkingFailure extends WarrantyState {
  final String error;

  const WarrantyStopWorkingFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// Pause Working on Warranty States
class WarrantyPauseWorkingLoading extends WarrantyState {}

class WarrantyPauseWorkingSuccess extends WarrantyState {}

class WarrantyPauseWorkingFailure extends WarrantyState {
  final String error;

  const WarrantyPauseWorkingFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// Assign Warranty Technician States
class WarrantyAssignLoading extends WarrantyState {}

class WarrantyAssignSuccess extends WarrantyState {
  final UserModel technician;

  const WarrantyAssignSuccess({required this.technician});

  @override
  List<Object> get props => [technician];
}

class WarrantyAssignFailure extends WarrantyState {
  final String error;

  const WarrantyAssignFailure({required this.error});

  @override
  List<Object> get props => [error];
}
