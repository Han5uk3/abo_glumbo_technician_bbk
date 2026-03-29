part of 'manage_app_bloc.dart';

sealed class ManageAppState extends Equatable {
  const ManageAppState();

  @override
  List<Object> get props => [];
}

final class ManageAppInitial extends ManageAppState {}

final class ClearingWallet extends ManageAppState {}

final class WalletCleared extends ManageAppState {}

final class WalletClearError extends ManageAppState {
  final String error;
  const WalletClearError(this.error);
  @override
  List<Object> get props => [error];
}

final class ApprovingAgent extends ManageAppState {}

final class AgentApproved extends ManageAppState {
  final bool isApproved;
  const AgentApproved(this.isApproved);
  @override
  List<Object> get props => [isApproved];
}

final class AgentApprovalError extends ManageAppState {
  final String error;
  const AgentApprovalError(this.error);

  @override
  List<Object> get props => [error];
}

final class AddingBanner extends ManageAppState {}

final class BannerAdded extends ManageAppState {
  final bool isAdded;
  const BannerAdded(this.isAdded);

  @override
  List<Object> get props => [isAdded];
}

final class BannerAddError extends ManageAppState {
  final String error;
  const BannerAddError(this.error);

  @override
  List<Object> get props => [error];
}

final class UpdatingBanner extends ManageAppState {}

final class BannerUpdated extends ManageAppState {
  final bool isUpdated;
  const BannerUpdated(this.isUpdated);
  @override
  List<Object> get props => [isUpdated];
}

final class BannerUpdateError extends ManageAppState {
  final String error;
  const BannerUpdateError(this.error);

  @override
  List<Object> get props => [error];
}

final class DeletingBanner extends ManageAppState {}

final class BannerDeleted extends ManageAppState {
  final bool isDeleted;
  const BannerDeleted(this.isDeleted);

  @override
  List<Object> get props => [isDeleted];
}

final class BannerDeleteError extends ManageAppState {
  final String error;
  const BannerDeleteError(this.error);

  @override
  List<Object> get props => [error];
}

final class AddingCategory extends ManageAppState {}

final class CategoryAdded extends ManageAppState {
  final bool isAdded;
  const CategoryAdded(this.isAdded);

  @override
  List<Object> get props => [isAdded];
}

final class CategoryAddError extends ManageAppState {
  final String error;
  const CategoryAddError(this.error);

  @override
  List<Object> get props => [error];
}

final class UpdatingCategory extends ManageAppState {}

final class CategoryUpdated extends ManageAppState {
  final bool isUpdated;
  const CategoryUpdated(this.isUpdated);
  @override
  List<Object> get props => [isUpdated];
}

final class CategoryUpdateError extends ManageAppState {
  final String error;
  const CategoryUpdateError(this.error);

  @override
  List<Object> get props => [error];
}

final class AddFaq extends ManageAppState {}

final class AddingFaq extends ManageAppState {}

final class FaqAdded extends ManageAppState {}

final class FaqAddError extends ManageAppState {
  final String error;
  const FaqAddError(this.error);

  @override
  List<Object> get props => [error];
}

final class UpdateFaq extends ManageAppState {}

final class UpdatingFaq extends ManageAppState {}

final class FaqUpdated extends ManageAppState {
  final bool isUpdated;
  const FaqUpdated(this.isUpdated);

  @override
  List<Object> get props => [isUpdated];
}

final class FaqUpdateError extends ManageAppState {
  final String error;
  const FaqUpdateError(this.error);

  @override
  List<Object> get props => [error];
}

final class DeleteFaq extends ManageAppState {}

final class DeletingFaq extends ManageAppState {}

final class FaqDeleted extends ManageAppState {
  final bool isDeleted;
  const FaqDeleted(this.isDeleted);

  @override
  List<Object> get props => [isDeleted];
}

final class FaqDeleteError extends ManageAppState {
  final String error;
  const FaqDeleteError(this.error);

  @override
  List<Object> get props => [error];
}

final class CustomerBlockUnblocking extends ManageAppState {}

final class BlockUnblockCustomer extends ManageAppState {
  final bool isBlocked;
  const BlockUnblockCustomer(this.isBlocked);

  @override
  List<Object> get props => [isBlocked];
}

final class BlockUnblockCustomerError extends ManageAppState {
  final String error;
  const BlockUnblockCustomerError(this.error);

  @override
  List<Object> get props => [error];
}

final class AddCustomerSupport extends ManageAppState {}

final class AddingCustomerSupport extends ManageAppState {}

final class CustomerSupportAdded extends ManageAppState {
  final bool isAdded;
  const CustomerSupportAdded(this.isAdded);

  @override
  List<Object> get props => [isAdded];
}

final class UpdateCustomerSupport extends ManageAppState {}

final class UpdatingCustomerSupport extends ManageAppState {}

final class CustomerSupportUpdated extends ManageAppState {
  final bool isUpdated;
  const CustomerSupportUpdated(this.isUpdated);

  @override
  List<Object> get props => [isUpdated];
}

final class CustomerSupportUpdateError extends ManageAppState {
  final String error;
  const CustomerSupportUpdateError(this.error);

  @override
  List<Object> get props => [error];
}

final class DeleteCustomerSupport extends ManageAppState {}

final class DeletingCustomerSupport extends ManageAppState {}

final class CustomerSupportDeleted extends ManageAppState {
  final bool isDeleted;
  const CustomerSupportDeleted(this.isDeleted);

  @override
  List<Object> get props => [isDeleted];
}

final class CustomerSupportDeleteError extends ManageAppState {
  final String error;
  const CustomerSupportDeleteError(this.error);

  @override
  List<Object> get props => [error];
}

final class CustomerSupportAddError extends ManageAppState {
  final String error;
  const CustomerSupportAddError(this.error);

  @override
  List<Object> get props => [error];
}
final class SettingPrimaryCustomerSupport extends ManageAppState {
  @override
  List<Object> get props => []; // Changed from List<Object?>
}

// Payout Approval States
final class ApprovingPayout extends ManageAppState {}

final class PayoutApprovalSuccess extends ManageAppState {
  final String message;
  const PayoutApprovalSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class PayoutApprovalError extends ManageAppState {
  final String error;
  const PayoutApprovalError(this.error);

  @override
  List<Object> get props => [error];
}

// Payout Rejection States
final class RejectingPayout extends ManageAppState {}

final class PayoutRejectionSuccess extends ManageAppState {
  final String message;
  const PayoutRejectionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class PayoutRejectionError extends ManageAppState {
  final String error;
  const PayoutRejectionError(this.error);

  @override
  List<Object> get props => [error];
}



final class DeletingCategory extends ManageAppState {}

final class CategoryDeleted extends ManageAppState {
  final bool isDeleted;
  const CategoryDeleted(this.isDeleted);

  @override
  List<Object> get props => [isDeleted];
}

final class CategoryDeleteError extends ManageAppState {
  final String error;
  const CategoryDeleteError(this.error);

  @override
  List<Object> get props => [error];
}
final class DeletingService extends ManageAppState {}

final class ServiceDeleted extends ManageAppState {
  final bool isDeleted;
  const ServiceDeleted(this.isDeleted);

  @override
  List<Object> get props => [isDeleted];
}

final class ServiceDeleteError extends ManageAppState {
  final String error;
  const ServiceDeleteError(this.error);

  @override
  List<Object> get props => [error];
}

final class UpdatingServiceStatus extends ManageAppState {}
final class ServiceStatusUpdated extends ManageAppState {}
final class ServiceStatusUpdateError extends ManageAppState {
  final String error;
  const ServiceStatusUpdateError(this.error);
  @override
  List<Object> get props => [error];
}

