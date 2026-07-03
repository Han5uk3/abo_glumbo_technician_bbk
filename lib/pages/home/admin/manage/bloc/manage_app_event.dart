part of 'manage_app_bloc.dart';

sealed class ManageAppEvent extends Equatable {
  const ManageAppEvent();

  @override
  List<Object> get props => [];
}

class ClearTipWalletEvent extends ManageAppEvent {
  final String agentId;
  final String transactionId;
  final XFile? image;
  final TippingModel? tippingModel;
  const ClearTipWalletEvent(
    this.agentId,
    this.transactionId,
    this.image,
    this.tippingModel,
  );

  @override
  List<Object> get props => [agentId];
}

class ApproveRejectAgentEvent extends ManageAppEvent {
  final String agentId;
  final bool isApproved;
  const ApproveRejectAgentEvent(this.agentId, this.isApproved);

  @override
  List<Object> get props => [agentId, isApproved];
}

// Banners
class AddBannerEvent extends ManageAppEvent {
  final BannerModel banner;
  final XFile? imageFile;
  const AddBannerEvent(this.banner, {this.imageFile});

  @override
  List<Object> get props => [banner, imageFile ?? ''];
}

class UpdateBannerEvent extends ManageAppEvent {
  final BannerModel banner;
  final XFile? imageFile;
  const UpdateBannerEvent(this.banner, {this.imageFile});

  @override
  List<Object> get props => [banner, imageFile ?? ''];
}

class DeleteBannerEvent extends ManageAppEvent {
  final String bannerId;
  const DeleteBannerEvent(this.bannerId);

  @override
  List<Object> get props => [bannerId];
}

// Categories
class AddCategoryEvent extends ManageAppEvent {
  final CategoryModel category;
  final XFile? imageFile;
  const AddCategoryEvent(this.category, {this.imageFile});

  @override
  List<Object> get props => [category, imageFile ?? ''];
}

class UpdateCategoryEvent extends ManageAppEvent {
  final CategoryModel category;
  final XFile? imageFile;
  const UpdateCategoryEvent(this.category, {this.imageFile});

  @override
  List<Object> get props => [category, imageFile ?? ''];
}

class AddFaqEvent extends ManageAppEvent {
  final FaqModel faqEntry;
  const AddFaqEvent(this.faqEntry);

  @override
  List<Object> get props => [faqEntry];
}

class DeleteFaqEvent extends ManageAppEvent {
  final String faqId;
  const DeleteFaqEvent(this.faqId);

  @override
  List<Object> get props => [faqId];
}

class UpdateFaqEvent extends ManageAppEvent {
  final FaqModel faqEntry;
  const UpdateFaqEvent(this.faqEntry);

  @override
  List<Object> get props => [faqEntry];
}

class CustomerBlockUnblockEvent extends ManageAppEvent {
  final String customerId;
  final bool isBlocked;
  const CustomerBlockUnblockEvent(this.customerId, this.isBlocked);

  @override
  List<Object> get props => [customerId, isBlocked];
}

class AddCustomerServiceContactEvent extends ManageAppEvent {
  final CustomerSupportModel contact;
  const AddCustomerServiceContactEvent(this.contact);

  @override
  List<Object> get props => [contact];
}

class UpdateCustomerServiceContactEvent extends ManageAppEvent {
  final CustomerSupportModel contact;
  const UpdateCustomerServiceContactEvent(this.contact);

  @override
  List<Object> get props => [contact];
}

class DeleteCustomerServiceContactEvent extends ManageAppEvent {
  final BuildContext context;
  final String contactId;
  final String type;

  const DeleteCustomerServiceContactEvent(
    this.contactId,
    this.type,
    this.context,
  );

  @override
  List<Object> get props => [contactId, type, context];
}

class SetPrimaryCustomerServiceContactEvent extends ManageAppEvent {
  final CustomerSupportModel selectedContact;
  final List<CustomerSupportModel> allContactsOfType;

  const SetPrimaryCustomerServiceContactEvent(
    this.selectedContact,
    this.allContactsOfType,
  );

  @override
  List<Object> get props => [selectedContact, allContactsOfType];
}

class ApprovePayoutEvent extends ManageAppEvent {
  final String payoutRequestId;
  final String transactionNumber;
  final PlatformFile proofFile;

  const ApprovePayoutEvent({
    required this.payoutRequestId,
    required this.transactionNumber,
    required this.proofFile,
  });

  @override
  List<Object> get props => [payoutRequestId, transactionNumber, proofFile];
}

class RejectPayoutEvent extends ManageAppEvent {
  final String payoutRequestId;
  final String reason;

  const RejectPayoutEvent({
    required this.payoutRequestId,
    required this.reason,
  });

  @override
  List<Object> get props => [payoutRequestId, reason];
}

class DeleteCategoryEvent extends ManageAppEvent {
  final String categoryId;
  const DeleteCategoryEvent(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}

class DeleteServiceEvent extends ManageAppEvent {
  final String serviceId;
  const DeleteServiceEvent(this.serviceId);

  @override
  List<Object> get props => [serviceId];
}

class ToggleServiceStatusEvent extends ManageAppEvent {
  final ServiceModel service;
  final bool isActive;
  const ToggleServiceStatusEvent(this.service, this.isActive);

  @override
  List<Object> get props => [service, isActive];
}
