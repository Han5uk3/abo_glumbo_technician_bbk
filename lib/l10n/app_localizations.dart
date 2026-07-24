import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'Admin View Only'**
  String get viewOnly;

  /// No description provided for @noTechnicianAssigned.
  ///
  /// In en, this message translates to:
  /// **'No Technician Assigned'**
  String get noTechnicianAssigned;

  /// No description provided for @calculatingDistance.
  ///
  /// In en, this message translates to:
  /// **'Calculating distance...'**
  String get calculatingDistance;

  /// No description provided for @awaitingCustomerAction.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Customer Action'**
  String get awaitingCustomerAction;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(Object distance);

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Abo Glumbo'**
  String get appName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Full Name'**
  String get enterYourFullName;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Your Full Name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @onlineStatusOn.
  ///
  /// In en, this message translates to:
  /// **'You are now Online'**
  String get onlineStatusOn;

  /// No description provided for @fullNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Full Name is required'**
  String get fullNameIsRequired;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Email'**
  String get enterYourEmail;

  /// No description provided for @onlineStatusOff.
  ///
  /// In en, this message translates to:
  /// **'You are now Offline'**
  String get onlineStatusOff;

  /// No description provided for @errorUpdatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating status'**
  String get errorUpdatingStatus;

  /// No description provided for @appLoginCaption.
  ///
  /// In en, this message translates to:
  /// **'Your go-to app for finding qualified professionals.'**
  String get appLoginCaption;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @byContinuingYouAgreeToOur.
  ///
  /// In en, this message translates to:
  /// **'By Continuing you agree to our'**
  String get byContinuingYouAgreeToOur;

  /// No description provided for @termsOfUseAndPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **' Terms of use & privacy policy'**
  String get termsOfUseAndPrivacyPolicy;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @banners.
  ///
  /// In en, this message translates to:
  /// **'Banners'**
  String get banners;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @technicians.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get technicians;

  /// No description provided for @payouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get payouts;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqs;

  /// No description provided for @totalPayoutAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Payout Amount'**
  String get totalPayoutAmount;

  /// No description provided for @reviewPayoutDetails.
  ///
  /// In en, this message translates to:
  /// **'Review Payout Details'**
  String get reviewPayoutDetails;

  /// No description provided for @manageOrders.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get manageOrders;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refreshStatus;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @areYouSureYouWantToRejectThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get areYouSureYouWantToRejectThisOrder;

  /// No description provided for @loadingAgents.
  ///
  /// In en, this message translates to:
  /// **'Loading Technicians...'**
  String get loadingAgents;

  /// No description provided for @bonusCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Earned Bonus will be included in your wallet for Payout.'**
  String get bonusCardDesc;

  /// No description provided for @noReview.
  ///
  /// In en, this message translates to:
  /// **'No Review'**
  String get noReview;

  /// No description provided for @areYouSureYouWantToAcceptThisNewTime.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this new time?'**
  String get areYouSureYouWantToAcceptThisNewTime;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @availableToWork.
  ///
  /// In en, this message translates to:
  /// **'Available To Work'**
  String get availableToWork;

  /// No description provided for @notAvailableToWork.
  ///
  /// In en, this message translates to:
  /// **'Not Available To Work'**
  String get notAvailableToWork;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @availableLocations.
  ///
  /// In en, this message translates to:
  /// **'Available Locations'**
  String get availableLocations;

  /// No description provided for @workHoursPricing.
  ///
  /// In en, this message translates to:
  /// **'Work Hours Pricing'**
  String get workHoursPricing;

  /// No description provided for @workStartTime.
  ///
  /// In en, this message translates to:
  /// **'Work Start Time'**
  String get workStartTime;

  /// No description provided for @workEndTime.
  ///
  /// In en, this message translates to:
  /// **'Work End Time'**
  String get workEndTime;

  /// No description provided for @onWorkPrice.
  ///
  /// In en, this message translates to:
  /// **'On-Work Price'**
  String get onWorkPrice;

  /// No description provided for @offWorkPrice.
  ///
  /// In en, this message translates to:
  /// **'Off-Work Price'**
  String get offWorkPrice;

  /// No description provided for @generalPrice.
  ///
  /// In en, this message translates to:
  /// **'General Price (Fallback)'**
  String get generalPrice;

  /// No description provided for @chooseLocations.
  ///
  /// In en, this message translates to:
  /// **'Choose Locations'**
  String get chooseLocations;

  /// No description provided for @pleaseEnterAnOnWorkPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter an on-work price'**
  String get pleaseEnterAnOnWorkPrice;

  /// No description provided for @pleaseEnterOffWorkPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter off-work price'**
  String get pleaseEnterOffWorkPrice;

  /// No description provided for @pleaseEnterAGeneralPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a general price'**
  String get pleaseEnterAGeneralPrice;

  /// No description provided for @grantAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant Admin Access'**
  String get grantAdminAccess;

  /// No description provided for @adminAccessManagement.
  ///
  /// In en, this message translates to:
  /// **'Admin Access Management'**
  String get adminAccessManagement;

  /// No description provided for @searchByBookingId.
  ///
  /// In en, this message translates to:
  /// **'Search by Booking ID'**
  String get searchByBookingId;

  /// No description provided for @rejectingOrder.
  ///
  /// In en, this message translates to:
  /// **'Rejecting Order'**
  String get rejectingOrder;

  /// No description provided for @failedToRejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to Reject Order'**
  String get failedToRejectOrder;

  /// No description provided for @assigningBookingTo.
  ///
  /// In en, this message translates to:
  /// **'Assigning Booking to'**
  String get assigningBookingTo;

  /// No description provided for @failedToAssignBookingTo.
  ///
  /// In en, this message translates to:
  /// **'Failed to Assign booking to'**
  String get failedToAssignBookingTo;

  /// No description provided for @completeOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete Order'**
  String get completeOrder;

  /// No description provided for @areYouSureYouWantToCompleteThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to complete this order?'**
  String get areYouSureYouWantToCompleteThisOrder;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @completingOrder.
  ///
  /// In en, this message translates to:
  /// **'Completing Order'**
  String get completingOrder;

  /// No description provided for @failedToCompleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete order'**
  String get failedToCompleteOrder;

  /// No description provided for @yourAccountHasBeenDeactivatedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deactivated by admin'**
  String get yourAccountHasBeenDeactivatedByAdmin;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign To'**
  String get assignTo;

  /// No description provided for @agent.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get agent;

  /// No description provided for @assignToUser.
  ///
  /// In en, this message translates to:
  /// **'Assign to user'**
  String get assignToUser;

  /// No description provided for @noAgentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Technician Available'**
  String get noAgentsAvailable;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled For'**
  String get scheduledFor;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @highlightedServices.
  ///
  /// In en, this message translates to:
  /// **'Highlighted Services'**
  String get highlightedServices;

  /// No description provided for @manageBanners.
  ///
  /// In en, this message translates to:
  /// **'Manage Banners'**
  String get manageBanners;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @bannerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Banner Deleted'**
  String get bannerDeleted;

  /// No description provided for @failedToDeleteBanner.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete Banner'**
  String get failedToDeleteBanner;

  /// No description provided for @failedToSaveBanner.
  ///
  /// In en, this message translates to:
  /// **'Failed to save Banner'**
  String get failedToSaveBanner;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @showInPrimaryBanner.
  ///
  /// In en, this message translates to:
  /// **'Show In Primary Banner'**
  String get showInPrimaryBanner;

  /// No description provided for @ifDisabledItWillShowInSecondaryBanner.
  ///
  /// In en, this message translates to:
  /// **'If disabled, it will show in secondary banner'**
  String get ifDisabledItWillShowInSecondaryBanner;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImage;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @failedToSaveHighlightedService.
  ///
  /// In en, this message translates to:
  /// **'Failed to save Highlighted service'**
  String get failedToSaveHighlightedService;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @noServicesSelected.
  ///
  /// In en, this message translates to:
  /// **'No services selected'**
  String get noServicesSelected;

  /// No description provided for @failedToSaveService.
  ///
  /// In en, this message translates to:
  /// **'Failed to save service'**
  String get failedToSaveService;

  /// No description provided for @failedToCreateService.
  ///
  /// In en, this message translates to:
  /// **'Failed to create service'**
  String get failedToCreateService;

  /// No description provided for @failedToUpdateService.
  ///
  /// In en, this message translates to:
  /// **'Failed to update service'**
  String get failedToUpdateService;

  /// No description provided for @pleaseVerifyYourIqama.
  ///
  /// In en, this message translates to:
  /// **'Please verify your iqama by checking the confirmation box'**
  String get pleaseVerifyYourIqama;

  /// No description provided for @uploadYourIqama.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Iqama'**
  String get uploadYourIqama;

  /// No description provided for @locationPermissionsAreDenied.
  ///
  /// In en, this message translates to:
  /// **'Location Permissions Are Denied'**
  String get locationPermissionsAreDenied;

  /// No description provided for @locationPermissionsArePermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location Permissions Are Permanently Denied'**
  String get locationPermissionsArePermanentlyDenied;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionPermanentlyDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied. Please enable them in app settings to receive job offers.'**
  String get locationPermissionPermanentlyDeniedMessage;

  /// No description provided for @pleaseEnableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services to continue using the app as a technician.'**
  String get pleaseEnableLocationServices;

  /// No description provided for @fetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching...'**
  String get fetching;

  /// No description provided for @currentGeopoint.
  ///
  /// In en, this message translates to:
  /// **'Current Geopoint'**
  String get currentGeopoint;

  /// No description provided for @latitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Lat'**
  String get latitudeLabel;

  /// No description provided for @longitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Lon'**
  String get longitudeLabel;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved'**
  String get locationSaved;

  /// No description provided for @errorDetectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error Detecting Location'**
  String get errorDetectingLocation;

  /// No description provided for @errorGettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Error Getting Address'**
  String get errorGettingAddress;

  /// No description provided for @pleaseSelectYourIdDocument.
  ///
  /// In en, this message translates to:
  /// **'Please Select Your ID Document'**
  String get pleaseSelectYourIdDocument;

  /// No description provided for @pleaseSelectAtLeastOneJobRole.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one job role'**
  String get pleaseSelectAtLeastOneJobRole;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @timedOut.
  ///
  /// In en, this message translates to:
  /// **'Timed Out'**
  String get timedOut;

  /// No description provided for @technicianNotFound.
  ///
  /// In en, this message translates to:
  /// **'Technician Not Found'**
  String get technicianNotFound;

  /// No description provided for @otpAutoVerified.
  ///
  /// In en, this message translates to:
  /// **'OTP Auto Verified'**
  String get otpAutoVerified;

  /// No description provided for @somethingWentWrongTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong, Try Again'**
  String get somethingWentWrongTryAgain;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP Sent'**
  String get otpSent;

  /// No description provided for @otpHasbeensentto.
  ///
  /// In en, this message translates to:
  /// **'OTP has been sent to'**
  String get otpHasbeensentto;

  /// No description provided for @anErrorOccurredPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'An Error Occurred, Please Try Again Later'**
  String get anErrorOccurredPleaseTryAgainLater;

  /// No description provided for @pleaseEnterAValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please Enter A Valid Phone Number'**
  String get pleaseEnterAValidPhoneNumber;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalidOtp;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @enterTheOtpSentToTheNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter The OTP Sent To The Number '**
  String get enterTheOtpSentToTheNumber;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @failedToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failedToLoadCategories;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myBooking.
  ///
  /// In en, this message translates to:
  /// **'My Booking'**
  String get myBooking;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @searchHere.
  ///
  /// In en, this message translates to:
  /// **'Search here'**
  String get searchHere;

  /// No description provided for @availableServices.
  ///
  /// In en, this message translates to:
  /// **'Available Services'**
  String get availableServices;

  /// No description provided for @failedToLoadLocations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load locations'**
  String get failedToLoadLocations;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @profileManagement.
  ///
  /// In en, this message translates to:
  /// **'Profile Management'**
  String get profileManagement;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name Is Required'**
  String get nameIsRequired;

  /// No description provided for @enterAValidName.
  ///
  /// In en, this message translates to:
  /// **'Enter A Valid Name'**
  String get enterAValidName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email Is Required'**
  String get emailIsRequired;

  /// No description provided for @enterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter A Valid Email'**
  String get enterAValidEmail;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @locationIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Is Required'**
  String get locationIsRequired;

  /// No description provided for @buildingNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Building Number Is Required'**
  String get buildingNumberIsRequired;

  /// No description provided for @streetName.
  ///
  /// In en, this message translates to:
  /// **'Street Name'**
  String get streetName;

  /// No description provided for @streetNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Street Name is Required'**
  String get streetNameIsRequired;

  /// No description provided for @cityName.
  ///
  /// In en, this message translates to:
  /// **'City Name'**
  String get cityName;

  /// No description provided for @cityNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'City Name Is Required'**
  String get cityNameIsRequired;

  /// No description provided for @postcode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postcode;

  /// No description provided for @postcodeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Postcode Is Required'**
  String get postcodeIsRequired;

  /// No description provided for @extensionNumber.
  ///
  /// In en, this message translates to:
  /// **'Extension Number'**
  String get extensionNumber;

  /// No description provided for @extensionNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Extension Number Is Required'**
  String get extensionNumberIsRequired;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account Created Successfully'**
  String get accountCreatedSuccessfully;

  /// No description provided for @failedToCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to create account'**
  String get failedToCreateAccount;

  /// No description provided for @pleaseFillTheInputBelowHereToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please fill the input below here to continue'**
  String get pleaseFillTheInputBelowHereToContinue;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @failedToLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content'**
  String get failedToLoadContent;

  /// No description provided for @noAddress.
  ///
  /// In en, this message translates to:
  /// **'No Address'**
  String get noAddress;

  /// No description provided for @searchForAService.
  ///
  /// In en, this message translates to:
  /// **'Search for a service'**
  String get searchForAService;

  /// No description provided for @jobCategories.
  ///
  /// In en, this message translates to:
  /// **'Job Categories'**
  String get jobCategories;

  /// No description provided for @failedToLoadDataPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data. Please try again later.'**
  String get failedToLoadDataPleaseTryAgainLater;

  /// No description provided for @noBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get noBookings;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found.'**
  String get noBookingsFound;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get searchServices;

  /// No description provided for @noServicesInYourWishlist.
  ///
  /// In en, this message translates to:
  /// **'No services in your wishlist'**
  String get noServicesInYourWishlist;

  /// No description provided for @failedToSaveBooking.
  ///
  /// In en, this message translates to:
  /// **'Failed to Save booking'**
  String get failedToSaveBooking;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afterNoon.
  ///
  /// In en, this message translates to:
  /// **'After Noon'**
  String get afterNoon;

  /// No description provided for @confirmRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm Request'**
  String get confirmRequest;

  /// No description provided for @bonusAmount.
  ///
  /// In en, this message translates to:
  /// **'Bonus Amount'**
  String get bonusAmount;

  /// No description provided for @requestBonusPayout.
  ///
  /// In en, this message translates to:
  /// **'Request Bonus Payout'**
  String get requestBonusPayout;

  /// No description provided for @noBonusAvailableToClaim.
  ///
  /// In en, this message translates to:
  /// **'No bonus available to claim'**
  String get noBonusAvailableToClaim;

  /// No description provided for @monthlyBonusEarned.
  ///
  /// In en, this message translates to:
  /// **'Monthly Bonus Earned'**
  String get monthlyBonusEarned;

  /// No description provided for @areYouSureYouWantToRequestAPayoutForYourMonthlyBonus.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to request a payout for your monthly bonus?'**
  String get areYouSureYouWantToRequestAPayoutForYourMonthlyBonus;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @serviceBookedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service Booked Successfully'**
  String get serviceBookedSuccessfully;

  /// No description provided for @checkForBookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Check your booking status in \'My Bookings\' section'**
  String get checkForBookingStatus;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @completeYourBooking.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Booking'**
  String get completeYourBooking;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @availableTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Available Time Slot'**
  String get availableTimeSlot;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Add Notes'**
  String get addNotes;

  /// No description provided for @cashInHand.
  ///
  /// In en, this message translates to:
  /// **'Cash payment'**
  String get cashInHand;

  /// No description provided for @netBankingUpiCard.
  ///
  /// In en, this message translates to:
  /// **'Net banking / UPI /Card'**
  String get netBankingUpiCard;

  /// No description provided for @pleaseSelectADate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get pleaseSelectADate;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reviewSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Review Submitted Successfully.'**
  String get reviewSubmittedSuccessfully;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get anErrorOccurred;

  /// No description provided for @submitAReview.
  ///
  /// In en, this message translates to:
  /// **'Submit A Rating'**
  String get submitAReview;

  /// No description provided for @overallRating.
  ///
  /// In en, this message translates to:
  /// **'Overall Rating'**
  String get overallRating;

  /// No description provided for @writeYourReviewHere.
  ///
  /// In en, this message translates to:
  /// **'Write your review here'**
  String get writeYourReviewHere;

  /// No description provided for @pleaseWriteAReview.
  ///
  /// In en, this message translates to:
  /// **'Please write a review'**
  String get pleaseWriteAReview;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking Canceled'**
  String get bookingCancelled;

  /// No description provided for @failedToCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel booking'**
  String get failedToCancelBooking;

  /// No description provided for @areYouSureToWantCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to want cancel booking?'**
  String get areYouSureToWantCancelBooking;

  /// No description provided for @youWillBeRefundedTheFullAmount.
  ///
  /// In en, this message translates to:
  /// **'You will be refunded the full amount'**
  String get youWillBeRefundedTheFullAmount;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @failedToLoadServices.
  ///
  /// In en, this message translates to:
  /// **'Failed to load services'**
  String get failedToLoadServices;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write A Review'**
  String get writeAReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Rating Submitted'**
  String get reviewSubmitted;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceled;

  /// No description provided for @requestService.
  ///
  /// In en, this message translates to:
  /// **'Request Service'**
  String get requestService;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get sar;

  /// No description provided for @serviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Service Description'**
  String get serviceDescription;

  /// No description provided for @serviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Service Info'**
  String get serviceInfo;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @customerInfo.
  ///
  /// In en, this message translates to:
  /// **'Customer Info'**
  String get customerInfo;

  /// No description provided for @bookingInfo.
  ///
  /// In en, this message translates to:
  /// **'Booking Info'**
  String get bookingInfo;

  /// No description provided for @agentInfo.
  ///
  /// In en, this message translates to:
  /// **'Technician Info'**
  String get agentInfo;

  /// No description provided for @reviewInfo.
  ///
  /// In en, this message translates to:
  /// **'Rating & Review Info'**
  String get reviewInfo;

  /// No description provided for @issueImage.
  ///
  /// In en, this message translates to:
  /// **'Issue Image'**
  String get issueImage;

  /// No description provided for @issueVideo.
  ///
  /// In en, this message translates to:
  /// **'Issue Video'**
  String get issueVideo;

  /// No description provided for @tapToZoom.
  ///
  /// In en, this message translates to:
  /// **'Tap to zoom'**
  String get tapToZoom;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @buildingNumber.
  ///
  /// In en, this message translates to:
  /// **'Building Number'**
  String get buildingNumber;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @postCode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postCode;

  /// No description provided for @bookedFor.
  ///
  /// In en, this message translates to:
  /// **'Booked For'**
  String get bookedFor;

  /// No description provided for @paymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get paymentMode;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @bookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Booking Status'**
  String get bookingStatus;

  /// No description provided for @bookingNote.
  ///
  /// In en, this message translates to:
  /// **'Problem Description'**
  String get bookingNote;

  /// No description provided for @bookedAt.
  ///
  /// In en, this message translates to:
  /// **'Booked At'**
  String get bookedAt;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Rating On'**
  String get reviewedAt;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @manageServices.
  ///
  /// In en, this message translates to:
  /// **'Manage Services'**
  String get manageServices;

  /// No description provided for @manageHighlightedServices.
  ///
  /// In en, this message translates to:
  /// **'Manage Highlighted Services'**
  String get manageHighlightedServices;

  /// No description provided for @manageAgents.
  ///
  /// In en, this message translates to:
  /// **'Manage Technicians'**
  String get manageAgents;

  /// No description provided for @pleaseEnterYourEmailToResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Please Enter your Email to Reset Password'**
  String get pleaseEnterYourEmailToResetPassword;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password Reset email sent. Please check your Email'**
  String get passwordResetEmailSent;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Your Email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Your Password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @areYouSureYouWantToApproveAgent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve'**
  String get areYouSureYouWantToApproveAgent;

  /// No description provided for @areYouSureYouWantToDisapproveAgent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disapprove'**
  String get areYouSureYouWantToDisapproveAgent;

  /// No description provided for @yesText.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesText;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleArabic.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get titleArabic;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameArabic.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get nameArabic;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionArabic.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic)'**
  String get descriptionArabic;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please Enter A Valid Email Address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @emailNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email Not Registered'**
  String get emailNotRegistered;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid Email Format'**
  String get invalidEmailFormat;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get tooManyRequests;

  /// No description provided for @netError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get netError;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'User account disabled'**
  String get userDisabled;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting account...'**
  String get deletingAccount;

  /// No description provided for @requiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'This operation requires recent authentication. Please log out and log back in.'**
  String get requiresRecentLogin;

  /// No description provided for @resetPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Reset Password Error'**
  String get resetPasswordError;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Password'**
  String get incorrectPassword;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account Disabled'**
  String get accountDisabled;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid Credentials'**
  String get invalidCredentials;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login Error'**
  String get loginError;

  /// No description provided for @passwordMustBeAtleast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password Must Be At Least 6 Characters Long'**
  String get passwordMustBeAtleast6Characters;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get rejected;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get accepted;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get cancelled;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @bookedOn.
  ///
  /// In en, this message translates to:
  /// **'Booked On'**
  String get bookedOn;

  /// No description provided for @agentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Technicians Available'**
  String get agentsAvailable;

  /// No description provided for @acceptedAt.
  ///
  /// In en, this message translates to:
  /// **'Confirmed At'**
  String get acceptedAt;

  /// No description provided for @rejectedAt.
  ///
  /// In en, this message translates to:
  /// **'Rejected At'**
  String get rejectedAt;

  /// No description provided for @completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed At'**
  String get completedAt;

  /// No description provided for @expiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired On'**
  String get expiredOn;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @applePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @cashOnHands.
  ///
  /// In en, this message translates to:
  /// **'Outside App'**
  String get cashOnHands;

  /// No description provided for @ext.
  ///
  /// In en, this message translates to:
  /// **'Ext'**
  String get ext;

  /// No description provided for @serviceAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service Added Successfully'**
  String get serviceAddedSuccessfully;

  /// No description provided for @serviceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service Updated Successfully'**
  String get serviceUpdatedSuccessfully;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// No description provided for @pleaseEnterAName.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Name'**
  String get pleaseEnterAName;

  /// No description provided for @pleaseEnterNameInArabic.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Arabic Name'**
  String get pleaseEnterNameInArabic;

  /// No description provided for @textMustBeInArabic.
  ///
  /// In en, this message translates to:
  /// **'Text Must Be In Arabic'**
  String get textMustBeInArabic;

  /// No description provided for @pleaseEnterADescription.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Description'**
  String get pleaseEnterADescription;

  /// No description provided for @pleaseEnterDescriptionInArabic.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Description In Arabic'**
  String get pleaseEnterDescriptionInArabic;

  /// No description provided for @descriptionMustBeInArabic.
  ///
  /// In en, this message translates to:
  /// **'Description Must Be In Arabic'**
  String get descriptionMustBeInArabic;

  /// No description provided for @pleaseEnterAPrice.
  ///
  /// In en, this message translates to:
  /// **'Please Enter A Price'**
  String get pleaseEnterAPrice;

  /// No description provided for @pleaseSelectACategory.
  ///
  /// In en, this message translates to:
  /// **'Please Select Category'**
  String get pleaseSelectACategory;

  /// No description provided for @discountPercentage.
  ///
  /// In en, this message translates to:
  /// **'Discount Percentage (%)'**
  String get discountPercentage;

  /// No description provided for @pleaseEnterADiscountPercentage.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Discount Percentage'**
  String get pleaseEnterADiscountPercentage;

  /// No description provided for @highlightedServiceAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Highlighted Service Added Successfully'**
  String get highlightedServiceAddedSuccessfully;

  /// No description provided for @highlightedServiceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Highlighted Service Updated Successfully'**
  String get highlightedServiceUpdatedSuccessfully;

  /// No description provided for @selectServices.
  ///
  /// In en, this message translates to:
  /// **'Select Services'**
  String get selectServices;

  /// No description provided for @addHighlightedService.
  ///
  /// In en, this message translates to:
  /// **'Add Highlighted Service'**
  String get addHighlightedService;

  /// No description provided for @editHighlightedService.
  ///
  /// In en, this message translates to:
  /// **'Edit Highlighted Service'**
  String get editHighlightedService;

  /// No description provided for @pleaseEnterATitle.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Title'**
  String get pleaseEnterATitle;

  /// No description provided for @pleaseEnterTheTitleInArabic.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Arabic Title'**
  String get pleaseEnterTheTitleInArabic;

  /// No description provided for @addBanner.
  ///
  /// In en, this message translates to:
  /// **'Add Banner'**
  String get addBanner;

  /// No description provided for @editBanner.
  ///
  /// In en, this message translates to:
  /// **'Edit Banner'**
  String get editBanner;

  /// No description provided for @labelIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Label Is Required'**
  String get labelIsRequired;

  /// No description provided for @urlIsRequired.
  ///
  /// In en, this message translates to:
  /// **'URL Is Required'**
  String get urlIsRequired;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @bannerAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Banner Added Successfully'**
  String get bannerAddedSuccessfully;

  /// No description provided for @bannerUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Banner Updated Successfully'**
  String get bannerUpdatedSuccessfully;

  /// No description provided for @doYouWantToUploadThisImage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to upload this image?'**
  String get doYouWantToUploadThisImage;

  /// No description provided for @pleaseSelectAnImage.
  ///
  /// In en, this message translates to:
  /// **'Please Select An Image'**
  String get pleaseSelectAnImage;

  /// No description provided for @hasBeenApprovedAsAnAgent.
  ///
  /// In en, this message translates to:
  /// **'has been approved as an Technician'**
  String get hasBeenApprovedAsAnAgent;

  /// No description provided for @hasBeenDisapprovedAsAnAgent.
  ///
  /// In en, this message translates to:
  /// **'has been disapproved as an Technician'**
  String get hasBeenDisapprovedAsAnAgent;

  /// No description provided for @jobRoles.
  ///
  /// In en, this message translates to:
  /// **'Job Roles'**
  String get jobRoles;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @jobRolesAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Job Roles Are Required'**
  String get jobRolesAreRequired;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please Confirm Your Password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords Do Not Match'**
  String get passwordsDoNotMatch;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @selectJobRoles.
  ///
  /// In en, this message translates to:
  /// **'Select Job Roles'**
  String get selectJobRoles;

  /// No description provided for @failedToDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to detect location'**
  String get failedToDetectLocation;

  /// No description provided for @failedToGetAddress.
  ///
  /// In en, this message translates to:
  /// **'Failed to get address'**
  String get failedToGetAddress;

  /// No description provided for @addCustomJobRoles.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Job Roles'**
  String get addCustomJobRoles;

  /// No description provided for @enterAdditionalJobRoles.
  ///
  /// In en, this message translates to:
  /// **'Enter Additional Job Roles'**
  String get enterAdditionalJobRoles;

  /// No description provided for @detectCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Detect Current Location'**
  String get detectCurrentLocation;

  /// No description provided for @failedToGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get failedToGetLocation;

  /// No description provided for @cannotCompleteTasksScheduledForTheFuture.
  ///
  /// In en, this message translates to:
  /// **'Cannot complete tasks scheduled for the future'**
  String get cannotCompleteTasksScheduledForTheFuture;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @failedToLoadUserData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user data'**
  String get failedToLoadUserData;

  /// No description provided for @areYouSureYouWantToDeleteYourAccountThisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone'**
  String get areYouSureYouWantToDeleteYourAccountThisActionCannotBeUndone;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @bookingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingAccepted;

  /// No description provided for @bookingAssignedToYou.
  ///
  /// In en, this message translates to:
  /// **'You have been assigned to a booking.'**
  String get bookingAssignedToYou;

  /// No description provided for @yourBookingRequestHasBeenAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your booking request has been confirmed! Our team will contact you shortly.'**
  String get yourBookingRequestHasBeenAccepted;

  /// No description provided for @bookingRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking Rejected'**
  String get bookingRejected;

  /// No description provided for @yourBookingRequestHasBeenRejected.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your booking request has been rejected. Please try again or contact support.'**
  String get yourBookingRequestHasBeenRejected;

  /// No description provided for @sendingNotification.
  ///
  /// In en, this message translates to:
  /// **'Sending notification to customer'**
  String get sendingNotification;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent to customer'**
  String get notificationSent;

  /// No description provided for @bookingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Booking Completed'**
  String get bookingCompleted;

  /// No description provided for @yourBookingHasBeenCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your booking has been completed!'**
  String get yourBookingHasBeenCompleted;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pleaseWaitAccountVerification.
  ///
  /// In en, this message translates to:
  /// **'Your account is being verified by the admin, check back later'**
  String get pleaseWaitAccountVerification;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @deleteRegistrationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your registration?'**
  String get deleteRegistrationConfirmation;

  /// No description provided for @phoneNumberAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Phone number already exists'**
  String get phoneNumberAlreadyExists;

  /// No description provided for @keepImage.
  ///
  /// In en, this message translates to:
  /// **'Keep Image'**
  String get keepImage;

  /// No description provided for @keepImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Do you want to keep the selected image without cropping?'**
  String get keepImageDescription;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @pleaseSelectAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one service'**
  String get pleaseSelectAtLeastOneService;

  /// No description provided for @deleteBannerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this banner?'**
  String get deleteBannerConfirmation;

  /// No description provided for @selectLocations.
  ///
  /// In en, this message translates to:
  /// **'Select Locations'**
  String get selectLocations;

  /// No description provided for @tapToSelectLocations.
  ///
  /// In en, this message translates to:
  /// **'Tap to select locations'**
  String get tapToSelectLocations;

  /// No description provided for @locationsSelected.
  ///
  /// In en, this message translates to:
  /// **'Locations Selected'**
  String get locationsSelected;

  /// No description provided for @locationSelected.
  ///
  /// In en, this message translates to:
  /// **'Location Selected'**
  String get locationSelected;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocation;

  /// No description provided for @noLocationsFound.
  ///
  /// In en, this message translates to:
  /// **'No locations found'**
  String get noLocationsFound;

  /// No description provided for @accountVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Your account is currently under Review by our admin team.'**
  String get accountVerificationPending;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @enterAValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please Enter a valid phone number'**
  String get enterAValidPhoneNumber;

  /// No description provided for @manageTips.
  ///
  /// In en, this message translates to:
  /// **'Manage Tips'**
  String get manageTips;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @counterPropose.
  ///
  /// In en, this message translates to:
  /// **'Counter Propose'**
  String get counterPropose;

  /// No description provided for @proposeNewTime.
  ///
  /// In en, this message translates to:
  /// **'Suggest New Time'**
  String get proposeNewTime;

  /// No description provided for @counterOfferPending.
  ///
  /// In en, this message translates to:
  /// **'Counter Offer Pending'**
  String get counterOfferPending;

  /// No description provided for @customerProposedNewTime.
  ///
  /// In en, this message translates to:
  /// **'Customer proposed a new time'**
  String get customerProposedNewTime;

  /// No description provided for @acceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept Offer'**
  String get acceptOffer;

  /// No description provided for @rejectOffer.
  ///
  /// In en, this message translates to:
  /// **'Reject Offer'**
  String get rejectOffer;

  /// No description provided for @newProposedTime.
  ///
  /// In en, this message translates to:
  /// **'New Proposed Time'**
  String get newProposedTime;

  /// No description provided for @waitingForCustomer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for customer response'**
  String get waitingForCustomer;

  /// No description provided for @proposedTime.
  ///
  /// In en, this message translates to:
  /// **'Proposed Time'**
  String get proposedTime;

  /// No description provided for @counterOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Counter offer sent successfully'**
  String get counterOfferSent;

  /// No description provided for @counterOfferResponse.
  ///
  /// In en, this message translates to:
  /// **'Response sent successfully'**
  String get counterOfferResponse;

  /// No description provided for @counterProposalStarted.
  ///
  /// In en, this message translates to:
  /// **'Counter proposal started'**
  String get counterProposalStarted;

  /// No description provided for @counterProposalAccepted.
  ///
  /// In en, this message translates to:
  /// **'Counter proposal confirmed'**
  String get counterProposalAccepted;

  /// No description provided for @proposalRejected.
  ///
  /// In en, this message translates to:
  /// **'Proposal Rejected'**
  String get proposalRejected;

  /// No description provided for @proposalAccepted.
  ///
  /// In en, this message translates to:
  /// **'Proposal Confirmed'**
  String get proposalAccepted;

  /// No description provided for @customerRejectedProposal.
  ///
  /// In en, this message translates to:
  /// **'Customer rejected your proposal.'**
  String get customerRejectedProposal;

  /// No description provided for @youRejectedProposal.
  ///
  /// In en, this message translates to:
  /// **'You rejected customer\'s proposal.'**
  String get youRejectedProposal;

  /// No description provided for @appointmentRescheduledTo.
  ///
  /// In en, this message translates to:
  /// **'Appointment rescheduled to'**
  String get appointmentRescheduledTo;

  /// No description provided for @rescheduleBookingTimeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this new appointment time? The booking schedule will be updated immediately.'**
  String get rescheduleBookingTimeConfirmation;

  /// No description provided for @startWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get startWork;

  /// No description provided for @pleaseEnterSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Please enter sort order'**
  String get pleaseEnterSortOrder;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @categoryAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category added successfully'**
  String get categoryAddedSuccessfully;

  /// No description provided for @categoryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully'**
  String get categoryUpdatedSuccessfully;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number is invalid'**
  String get phoneNumberInvalid;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @pleaseSelectALocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location'**
  String get pleaseSelectALocation;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just Now'**
  String get justNow;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists'**
  String get emailAlreadyExists;

  /// No description provided for @tippingCleared.
  ///
  /// In en, this message translates to:
  /// **'Tipping cleared'**
  String get tippingCleared;

  /// No description provided for @failedToClearTipping.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear tipping'**
  String get failedToClearTipping;

  /// No description provided for @manageTipping.
  ///
  /// In en, this message translates to:
  /// **'Manage Tipping'**
  String get manageTipping;

  /// No description provided for @noTipsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tips available'**
  String get noTipsAvailable;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @tipInfo.
  ///
  /// In en, this message translates to:
  /// **'Tip info'**
  String get tipInfo;

  /// No description provided for @totalTips.
  ///
  /// In en, this message translates to:
  /// **'Total tips'**
  String get totalTips;

  /// No description provided for @lastTipAmount.
  ///
  /// In en, this message translates to:
  /// **'Last tip Amount'**
  String get lastTipAmount;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @agentId.
  ///
  /// In en, this message translates to:
  /// **'Technician ID'**
  String get agentId;

  /// No description provided for @sendAndClearWallet.
  ///
  /// In en, this message translates to:
  /// **'Send & Clear Wallet'**
  String get sendAndClearWallet;

  /// No description provided for @clearWallet.
  ///
  /// In en, this message translates to:
  /// **'Clear Wallet'**
  String get clearWallet;

  /// No description provided for @clearWalletWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The Technician will receive the total amount in their wallet, and it will be reset to zero.'**
  String get clearWalletWarning;

  /// No description provided for @areYouSureYouWantToSend.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to send'**
  String get areYouSureYouWantToSend;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @andClearTheirWallet.
  ///
  /// In en, this message translates to:
  /// **'and clear their wallet'**
  String get andClearTheirWallet;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied forever'**
  String get locationPermissionDeniedForever;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @pleaseUploadAnImage.
  ///
  /// In en, this message translates to:
  /// **'Please upload an image'**
  String get pleaseUploadAnImage;

  /// No description provided for @searchBookings.
  ///
  /// In en, this message translates to:
  /// **'Search Bookings'**
  String get searchBookings;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @warrantyRejectedTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Warranty Rejected Technicians'**
  String get warrantyRejectedTechnicians;

  /// No description provided for @loadingBanners.
  ///
  /// In en, this message translates to:
  /// **'Loading Banners'**
  String get loadingBanners;

  /// No description provided for @cancelledDate.
  ///
  /// In en, this message translates to:
  /// **'Cancelled Date'**
  String get cancelledDate;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPending;

  /// No description provided for @loadingHighlightedServices.
  ///
  /// In en, this message translates to:
  /// **'Loading Highlighted Services'**
  String get loadingHighlightedServices;

  /// No description provided for @loadingServices.
  ///
  /// In en, this message translates to:
  /// **'Loading Services'**
  String get loadingServices;

  /// No description provided for @completionDetails.
  ///
  /// In en, this message translates to:
  /// **'Completed Details'**
  String get completionDetails;

  /// No description provided for @loadingFaqs.
  ///
  /// In en, this message translates to:
  /// **'Loading FAQs'**
  String get loadingFaqs;

  /// No description provided for @loadingTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Loading Technicians'**
  String get loadingTechnicians;

  /// No description provided for @bookingWasCancelledByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Booking was cancelled by customer'**
  String get bookingWasCancelledByCustomer;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Delete error'**
  String get deleteError;

  /// No description provided for @deleteService.
  ///
  /// In en, this message translates to:
  /// **'Delete Service'**
  String get deleteService;

  /// No description provided for @serviceCompletedDescription.
  ///
  /// In en, this message translates to:
  /// **'Service has been completed successfully. A 1-week warranty will be applied.'**
  String get serviceCompletedDescription;

  /// No description provided for @paymentThroughApp.
  ///
  /// In en, this message translates to:
  /// **'Inside App'**
  String get paymentThroughApp;

  /// No description provided for @paymentOutsideApp.
  ///
  /// In en, this message translates to:
  /// **'Outside App'**
  String get paymentOutsideApp;

  /// No description provided for @paymentThroughAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Customer will pay through the app.'**
  String get paymentThroughAppDesc;

  /// No description provided for @paymentOutsideAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect payment outside of the app.'**
  String get paymentOutsideAppDesc;

  /// No description provided for @deleteServiceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this service?'**
  String get deleteServiceConfirmation;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// No description provided for @categoryNameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Category name already exists'**
  String get categoryNameAlreadyExists;

  /// No description provided for @deleteCategoryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get deleteCategoryConfirmation;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @completeWork.
  ///
  /// In en, this message translates to:
  /// **'Complete Work'**
  String get completeWork;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @inspectionOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Only inspection done, no service provided'**
  String get inspectionOnlyDescription;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @newtext.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newtext;

  /// No description provided for @waitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get waitingForPayment;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @inspectionOnly.
  ///
  /// In en, this message translates to:
  /// **'Inspection Only'**
  String get inspectionOnly;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @getHelpAnytime.
  ///
  /// In en, this message translates to:
  /// **'Get help anytime'**
  String get getHelpAnytime;

  /// No description provided for @tierSystem.
  ///
  /// In en, this message translates to:
  /// **'Tier System'**
  String get tierSystem;

  /// No description provided for @bronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get bronze;

  /// No description provided for @silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @platinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get platinum;

  /// No description provided for @nobonus.
  ///
  /// In en, this message translates to:
  /// **'No bonus'**
  String get nobonus;

  /// No description provided for @fivepercentBonus.
  ///
  /// In en, this message translates to:
  /// **'5% Bonus'**
  String get fivepercentBonus;

  /// No description provided for @tenpercentBonus.
  ///
  /// In en, this message translates to:
  /// **'10% Bonus'**
  String get tenpercentBonus;

  /// No description provided for @fifteenpercentBonus.
  ///
  /// In en, this message translates to:
  /// **'15% Bonus + Badge'**
  String get fifteenpercentBonus;

  /// No description provided for @greaterThan3dot5rating.
  ///
  /// In en, this message translates to:
  /// **'3.5+ rating'**
  String get greaterThan3dot5rating;

  /// No description provided for @greaterThan4dot0rating.
  ///
  /// In en, this message translates to:
  /// **'4.0+ rating'**
  String get greaterThan4dot0rating;

  /// No description provided for @greaterThan4dot5rating.
  ///
  /// In en, this message translates to:
  /// **'4.5+ rating'**
  String get greaterThan4dot5rating;

  /// No description provided for @greaterThan4dot8rating.
  ///
  /// In en, this message translates to:
  /// **'4.8+ rating'**
  String get greaterThan4dot8rating;

  /// No description provided for @searchByTechnicianName.
  ///
  /// In en, this message translates to:
  /// **'Search by technician name'**
  String get searchByTechnicianName;

  /// No description provided for @bookingWasRejectedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Booking was rejected by admin'**
  String get bookingWasRejectedByAdmin;

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @twentyPlusJobs.
  ///
  /// In en, this message translates to:
  /// **'20+ Jobs'**
  String get twentyPlusJobs;

  /// No description provided for @thirtyPlusJobs.
  ///
  /// In en, this message translates to:
  /// **'30+ Jobs'**
  String get thirtyPlusJobs;

  /// No description provided for @fortyPlusJobs.
  ///
  /// In en, this message translates to:
  /// **'40+ Jobs'**
  String get fortyPlusJobs;

  /// No description provided for @sixtyPlusJobs.
  ///
  /// In en, this message translates to:
  /// **'60+ Jobs'**
  String get sixtyPlusJobs;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitAppTitle;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the app?'**
  String get exitAppMessage;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @nextTierProgress.
  ///
  /// In en, this message translates to:
  /// **'Next tier progress'**
  String get nextTierProgress;

  /// No description provided for @greaterThan20jobsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'â‰¥ 20 jobs/month'**
  String get greaterThan20jobsPerMonth;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @greaterThan40jobsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'â‰¥ 40 jobs/month'**
  String get greaterThan40jobsPerMonth;

  /// No description provided for @greaterThan60jobsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'â‰¥ 60 jobs/month'**
  String get greaterThan60jobsPerMonth;

  /// No description provided for @progressResetsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Progress resets monthly, Maintain high ratings and complete more jobs to unlock better rewards.'**
  String get progressResetsMonthly;

  /// No description provided for @progressResetsMonthlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Progresses rests monthly. Maintain high ratings and complete more jobs to unlock better rewards'**
  String get progressResetsMonthlyDesc;

  /// No description provided for @zeroPercentBonus.
  ///
  /// In en, this message translates to:
  /// **'0% Bonus'**
  String get zeroPercentBonus;

  /// No description provided for @fivepercentBonusOnly.
  ///
  /// In en, this message translates to:
  /// **'5% Bonus'**
  String get fivepercentBonusOnly;

  /// No description provided for @tenpercentBonusOnly.
  ///
  /// In en, this message translates to:
  /// **'10% Bonus'**
  String get tenpercentBonusOnly;

  /// No description provided for @fifteenpercentBonusOnly.
  ///
  /// In en, this message translates to:
  /// **'15% Bonus'**
  String get fifteenpercentBonusOnly;

  /// No description provided for @viewYourRewards.
  ///
  /// In en, this message translates to:
  /// **'View your rewards'**
  String get viewYourRewards;

  /// No description provided for @noSupportAvailable.
  ///
  /// In en, this message translates to:
  /// **'No support available'**
  String get noSupportAvailable;

  /// No description provided for @contactSupportOptions.
  ///
  /// In en, this message translates to:
  /// **'Contact support options'**
  String get contactSupportOptions;

  /// No description provided for @contactByEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact by email'**
  String get contactByEmail;

  /// No description provided for @contactByPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact by phone'**
  String get contactByPhone;

  /// No description provided for @contactByWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Contact by WhatsApp'**
  String get contactByWhatsApp;

  /// No description provided for @serviceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Service Completed'**
  String get serviceCompleted;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @serviceItems.
  ///
  /// In en, this message translates to:
  /// **'Service Items'**
  String get serviceItems;

  /// No description provided for @enterServiceCost.
  ///
  /// In en, this message translates to:
  /// **'Enter service cost'**
  String get enterServiceCost;

  /// No description provided for @serviceCostMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Service cost must be greater than 0'**
  String get serviceCostMustBeGreaterThanZero;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @pleaseEnterServiceCost.
  ///
  /// In en, this message translates to:
  /// **'Please enter service cost'**
  String get pleaseEnterServiceCost;

  /// No description provided for @tapToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload image'**
  String get tapToUploadImage;

  /// No description provided for @serviceCost.
  ///
  /// In en, this message translates to:
  /// **'Service Cost'**
  String get serviceCost;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @pleaseAddAtleastOneServiceItem.
  ///
  /// In en, this message translates to:
  /// **'Please add atleast one service item'**
  String get pleaseAddAtleastOneServiceItem;

  /// No description provided for @pleaseFillAllServiceItemFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all service item fields'**
  String get pleaseFillAllServiceItemFields;

  /// No description provided for @workingDays.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get workingDays;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @locationServiceRequired.
  ///
  /// In en, this message translates to:
  /// **'Location service is required'**
  String get locationServiceRequired;

  /// No description provided for @pleaseEnableLocationService.
  ///
  /// In en, this message translates to:
  /// **'Please enable location service'**
  String get pleaseEnableLocationService;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @bioMetricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric'**
  String get bioMetricAuthentication;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start Tracking'**
  String get startTracking;

  /// No description provided for @stopTracking.
  ///
  /// In en, this message translates to:
  /// **'Stop Tracking'**
  String get stopTracking;

  /// No description provided for @arrivedAtLocation.
  ///
  /// In en, this message translates to:
  /// **'Arrived at location'**
  String get arrivedAtLocation;

  /// No description provided for @youHaveActiveBooking.
  ///
  /// In en, this message translates to:
  /// **'You have an active booking'**
  String get youHaveActiveBooking;

  /// No description provided for @areYouSureYouWantToStartTracking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to start tracking for this booking? This will enable location monitoring.'**
  String get areYouSureYouWantToStartTracking;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @areYouSureYouWantToStopTracking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop tracking for this booking? Location monitoring will be disabled.'**
  String get areYouSureYouWantToStopTracking;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @activeBooking.
  ///
  /// In en, this message translates to:
  /// **'Active Booking'**
  String get activeBooking;

  /// No description provided for @failedToStartTracking.
  ///
  /// In en, this message translates to:
  /// **'Failed to start tracking'**
  String get failedToStartTracking;

  /// No description provided for @trackingStarted.
  ///
  /// In en, this message translates to:
  /// **'Tracking started'**
  String get trackingStarted;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @trackingNote.
  ///
  /// In en, this message translates to:
  /// **'Note: If youâ€™re starting the work, please click the â€œStart Trackingâ€ button. In case the button gets cut off or changes, make sure to click â€œStart Trackingâ€ again.'**
  String get trackingNote;

  /// No description provided for @filterByLocation.
  ///
  /// In en, this message translates to:
  /// **'Filter by Location'**
  String get filterByLocation;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All Locations'**
  String get allLocations;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @agents.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get agents;

  /// No description provided for @inSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'In Selected Location'**
  String get inSelectedLocation;

  /// No description provided for @totalAgents.
  ///
  /// In en, this message translates to:
  /// **'Total Technicians'**
  String get totalAgents;

  /// No description provided for @filteredBy.
  ///
  /// In en, this message translates to:
  /// **'Filtered by'**
  String get filteredBy;

  /// No description provided for @notificationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Notification Language'**
  String get notificationLanguage;

  /// No description provided for @areYouSureYouWantToCancelThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get areYouSureYouWantToCancelThisBooking;

  /// No description provided for @bookingTimeline.
  ///
  /// In en, this message translates to:
  /// **'Booking Timeline'**
  String get bookingTimeline;

  /// No description provided for @trackingStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Tracking started at'**
  String get trackingStartedAt;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @enableBiometricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Authentication'**
  String get enableBiometricAuthentication;

  /// No description provided for @notificationLanguageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Notification language updated'**
  String get notificationLanguageUpdated;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @issueMedia.
  ///
  /// In en, this message translates to:
  /// **'Issue Media'**
  String get issueMedia;

  /// No description provided for @loadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading Video'**
  String get loadingVideo;

  /// No description provided for @categoryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Category already exists'**
  String get categoryAlreadyExists;

  /// No description provided for @noLocationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No locations available'**
  String get noLocationsAvailable;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @enterPasswordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter Password to Confirm'**
  String get enterPasswordToConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone'**
  String get deleteAccountWarning;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @walletClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Wallet balances successfully cleared'**
  String get walletClearedSuccessfully;

  /// No description provided for @biometricNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Biometric not supported'**
  String get biometricNotSupported;

  /// No description provided for @pleaseAuthenticateToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to continue'**
  String get pleaseAuthenticateToContinue;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric not available'**
  String get biometricNotAvailable;

  /// No description provided for @biometricTemporarilyLocked.
  ///
  /// In en, this message translates to:
  /// **'Biometric temporarily locked'**
  String get biometricTemporarilyLocked;

  /// No description provided for @unexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred'**
  String get unexpectedErrorOccurred;

  /// No description provided for @ago.
  ///
  /// In en, this message translates to:
  /// **'Ago'**
  String get ago;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @languageCode.
  ///
  /// In en, this message translates to:
  /// **'Language Code'**
  String get languageCode;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @adminStatus.
  ///
  /// In en, this message translates to:
  /// **'Admin Status'**
  String get adminStatus;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @systemInformation.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get systemInformation;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @assignedRoles.
  ///
  /// In en, this message translates to:
  /// **'Assigned Roles'**
  String get assignedRoles;

  /// No description provided for @noAgentsFound.
  ///
  /// In en, this message translates to:
  /// **'No Technician found'**
  String get noAgentsFound;

  /// No description provided for @agentApproved.
  ///
  /// In en, this message translates to:
  /// **'Technician Approved'**
  String get agentApproved;

  /// No description provided for @agentDisapproved.
  ///
  /// In en, this message translates to:
  /// **'Technician Disapproved'**
  String get agentDisapproved;

  /// No description provided for @deleteBanner.
  ///
  /// In en, this message translates to:
  /// **'Delete Banner'**
  String get deleteBanner;

  /// No description provided for @invalidImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid Image URL'**
  String get invalidImageUrl;

  /// No description provided for @imageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Image load error'**
  String get imageLoadError;

  /// No description provided for @imageCropError.
  ///
  /// In en, this message translates to:
  /// **'Image crop error'**
  String get imageCropError;

  /// No description provided for @errorAddingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error adding category'**
  String get errorAddingCategory;

  /// No description provided for @errorUpdatingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error updating category'**
  String get errorUpdatingCategory;

  /// No description provided for @customerSubmittedBookingRequest.
  ///
  /// In en, this message translates to:
  /// **'Customer submitted booking request'**
  String get customerSubmittedBookingRequest;

  /// No description provided for @serviceProviderConfirmedAppointment.
  ///
  /// In en, this message translates to:
  /// **'Technician confirmed appointment'**
  String get serviceProviderConfirmedAppointment;

  /// No description provided for @serviceTrackingInitiated.
  ///
  /// In en, this message translates to:
  /// **'Service tracking initiated'**
  String get serviceTrackingInitiated;

  /// No description provided for @serviceHasBeenSuccessfullyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Service has been successfully completed'**
  String get serviceHasBeenSuccessfullyCompleted;

  /// No description provided for @bookingWasRejectedByServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Booking was rejected by Technician'**
  String get bookingWasRejectedByServiceProvider;

  /// No description provided for @bookingWasCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking was cancelled'**
  String get bookingWasCancelled;

  /// No description provided for @serviceInProgress.
  ///
  /// In en, this message translates to:
  /// **'Service in progress'**
  String get serviceInProgress;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @serviceIsCurrentlyBeingPerformed.
  ///
  /// In en, this message translates to:
  /// **'Service is currently being performed'**
  String get serviceIsCurrentlyBeingPerformed;

  /// No description provided for @waitingForServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Technician'**
  String get waitingForServiceProvider;

  /// No description provided for @waitingForTechnicianToStartService.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Technician to start service'**
  String get waitingForTechnicianToStartService;

  /// No description provided for @waitingForAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for acceptance'**
  String get waitingForAcceptance;

  /// No description provided for @waitingForServiceProviderResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Technician response'**
  String get waitingForServiceProviderResponse;

  /// No description provided for @waitingForAdmin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Admin'**
  String get waitingForAdmin;

  /// No description provided for @waitingForAdminToReassign.
  ///
  /// In en, this message translates to:
  /// **'Waiting for admin to reassign technician'**
  String get waitingForAdminToReassign;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order Rejected Successfully'**
  String get orderRejected;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration Success'**
  String get registrationSuccess;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed'**
  String get registrationFailed;

  /// No description provided for @confirmReject.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get confirmReject;

  /// No description provided for @updatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated On'**
  String get updatedOn;

  /// No description provided for @approvedOn.
  ///
  /// In en, this message translates to:
  /// **'Confirmed On'**
  String get approvedOn;

  /// No description provided for @confirmRejectMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get confirmRejectMessage;

  /// No description provided for @bookingCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled Successfully'**
  String get bookingCancelledSuccessfully;

  /// No description provided for @workMarkedAsComplete.
  ///
  /// In en, this message translates to:
  /// **'Work Marked As Complete'**
  String get workMarkedAsComplete;

  /// No description provided for @areYouSureYouWantToStartTrackingThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to start tracking this booking?'**
  String get areYouSureYouWantToStartTrackingThisBooking;

  /// No description provided for @areYouSureYouWantToPauseTrackingThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to pause tracking this booking?'**
  String get areYouSureYouWantToPauseTrackingThisBooking;

  /// No description provided for @areYouSureYouWantToStopTrackingThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop tracking this booking?'**
  String get areYouSureYouWantToStopTrackingThisBooking;

  /// No description provided for @pauseTracking.
  ///
  /// In en, this message translates to:
  /// **'Pause Tracking'**
  String get pauseTracking;

  /// No description provided for @resumeTracking.
  ///
  /// In en, this message translates to:
  /// **'Resume Tracking'**
  String get resumeTracking;

  /// No description provided for @trackingPausedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tracking paused successfully'**
  String get trackingPausedSuccessfully;

  /// No description provided for @areYouSureYouWantToCompleteThisWork.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to complete this work?'**
  String get areYouSureYouWantToCompleteThisWork;

  /// No description provided for @useBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get useBiometric;

  /// No description provided for @imageIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Image is required'**
  String get imageIsRequired;

  /// No description provided for @bookingCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booking completed successfully'**
  String get bookingCompletedSuccessfully;

  /// No description provided for @startedWorkingOnBookingSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Started working on booking successfully'**
  String get startedWorkingOnBookingSuccessfully;

  /// No description provided for @stopTrackingBookingSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking booking successfully'**
  String get stopTrackingBookingSuccessfully;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'Inside App'**
  String get cards;

  /// No description provided for @insideApp.
  ///
  /// In en, this message translates to:
  /// **'Inside App'**
  String get insideApp;

  /// No description provided for @outsideApp.
  ///
  /// In en, this message translates to:
  /// **'Outside-App'**
  String get outsideApp;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @failedToSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification to customer'**
  String get failedToSendNotification;

  /// No description provided for @locationPermissionErrorIOS.
  ///
  /// In en, this message translates to:
  /// **'Location permission error on iOS. Please go to Settings > Privacy & Security > Location Services > Abo Glumbo Technician and select \'Always\' to enable background tracking.'**
  String get locationPermissionErrorIOS;

  /// No description provided for @youHaveAnActiveBookingAlready.
  ///
  /// In en, this message translates to:
  /// **'You have an active booking already.'**
  String get youHaveAnActiveBookingAlready;

  /// No description provided for @locationServicesDisabledPleaseEnable.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled. Please enable location services.'**
  String get locationServicesDisabledPleaseEnable;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Location Settings'**
  String get openLocationSettings;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get notificationTitle;

  /// No description provided for @enterYourNotificationMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Enter your notification message here'**
  String get enterYourNotificationMessageHere;

  /// No description provided for @aboGlumboTechnician.
  ///
  /// In en, this message translates to:
  /// **'Abo Glumbo Technician'**
  String get aboGlumboTechnician;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @assigningTechnician.
  ///
  /// In en, this message translates to:
  /// **'Pending Acceptance'**
  String get assigningTechnician;

  /// No description provided for @selectProvince.
  ///
  /// In en, this message translates to:
  /// **'Select Province'**
  String get selectProvince;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @rejectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Rejection History'**
  String get rejectionHistory;

  /// No description provided for @selectNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Select Neighborhood'**
  String get selectNeighborhood;

  /// No description provided for @recipients.
  ///
  /// In en, this message translates to:
  /// **'Recipients'**
  String get recipients;

  /// No description provided for @techniciansRejectedThisClaim.
  ///
  /// In en, this message translates to:
  /// **'Technicians rejected this claim'**
  String get techniciansRejectedThisClaim;

  /// No description provided for @technicianRejectedThisClaim.
  ///
  /// In en, this message translates to:
  /// **'Technician rejected this claim'**
  String get technicianRejectedThisClaim;

  /// No description provided for @warrantyClaims.
  ///
  /// In en, this message translates to:
  /// **'Warranty Claims'**
  String get warrantyClaims;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @tapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToView;

  /// No description provided for @rejections.
  ///
  /// In en, this message translates to:
  /// **'Rejections'**
  String get rejections;

  /// No description provided for @exceedsMaxSize.
  ///
  /// In en, this message translates to:
  /// **'Exceeds max size'**
  String get exceedsMaxSize;

  /// No description provided for @sendNotifications.
  ///
  /// In en, this message translates to:
  /// **'Send Notifications'**
  String get sendNotifications;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotification;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file'**
  String get couldNotOpenFile;

  /// No description provided for @noTechniciansFound.
  ///
  /// In en, this message translates to:
  /// **'No technicians found'**
  String get noTechniciansFound;

  /// No description provided for @noTechniciansAvailable.
  ///
  /// In en, this message translates to:
  /// **'No technicians available'**
  String get noTechniciansAvailable;

  /// No description provided for @manageNotificationAlerts.
  ///
  /// In en, this message translates to:
  /// **'Manage Notification Alerts'**
  String get manageNotificationAlerts;

  /// No description provided for @previewLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preview Language'**
  String get previewLanguage;

  /// No description provided for @sendNotificationsToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Send Notifications to Customer'**
  String get sendNotificationsToCustomer;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @composeMessage.
  ///
  /// In en, this message translates to:
  /// **'Compose Message'**
  String get composeMessage;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @iqama.
  ///
  /// In en, this message translates to:
  /// **'Iqama'**
  String get iqama;

  /// No description provided for @certificationsrelevantExperienceDocuments.
  ///
  /// In en, this message translates to:
  /// **'Certifications/Relevant Experience Documents'**
  String get certificationsrelevantExperienceDocuments;

  /// No description provided for @filesSelected.
  ///
  /// In en, this message translates to:
  /// **'Files selected'**
  String get filesSelected;

  /// No description provided for @certificationsrelevantExperienceDocumentsOptional.
  ///
  /// In en, this message translates to:
  /// **'Certifications/relevant experience documents (optional)'**
  String get certificationsrelevantExperienceDocumentsOptional;

  /// No description provided for @invoiceType.
  ///
  /// In en, this message translates to:
  /// **'Invoice Type'**
  String get invoiceType;

  /// No description provided for @fullService.
  ///
  /// In en, this message translates to:
  /// **'Full Service'**
  String get fullService;

  /// No description provided for @inspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get inspection;

  /// No description provided for @inspectionFee.
  ///
  /// In en, this message translates to:
  /// **'Inspection Fee'**
  String get inspectionFee;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @typeMessageToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Type a message to customer...'**
  String get typeMessageToCustomer;

  /// No description provided for @startConversationWithCustomer.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with your customer'**
  String get startConversationWithCustomer;

  /// No description provided for @chatWithCustomer.
  ///
  /// In en, this message translates to:
  /// **'Chat with Customer'**
  String get chatWithCustomer;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChat;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get amountPaid;

  /// No description provided for @continueChat.
  ///
  /// In en, this message translates to:
  /// **'Continue Chat'**
  String get continueChat;

  /// No description provided for @failedToStartChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to start chat'**
  String get failedToStartChat;

  /// No description provided for @creatingChatRoom.
  ///
  /// In en, this message translates to:
  /// **'Creating chat room'**
  String get creatingChatRoom;

  /// No description provided for @loadingChat.
  ///
  /// In en, this message translates to:
  /// **'Loading chat'**
  String get loadingChat;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @errorLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages'**
  String get errorLoadingMessages;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @backgroundLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Background location tracking requires Always Allow permission. Please enable this in your device settings.'**
  String get backgroundLocationPermissionRequired;

  /// No description provided for @locationPermissionDeniedPleaseGrant.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please grant location permission to continue.'**
  String get locationPermissionDeniedPleaseGrant;

  /// No description provided for @areYouSureYouWantToCompleteThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to complete this booking?'**
  String get areYouSureYouWantToCompleteThisBooking;

  /// No description provided for @locationPermissionPermanentlyDeniedPleaseEnable.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Please enable location access in Settings.'**
  String get locationPermissionPermanentlyDeniedPleaseEnable;

  /// No description provided for @locationServicesDisabledCannotRestoreTracking.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled, cannot restore tracking'**
  String get locationServicesDisabledCannotRestoreTracking;

  /// No description provided for @locationPermissionDeniedCannotRestoreTracking.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied, cannot restore tracking'**
  String get locationPermissionDeniedCannotRestoreTracking;

  /// No description provided for @iosLocationPermissionErrorDuringRestore.
  ///
  /// In en, this message translates to:
  /// **'iOS location permission error during restore - may need \"Always\" permission'**
  String get iosLocationPermissionErrorDuringRestore;

  /// No description provided for @locationTrackingRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location tracking restored successfully'**
  String get locationTrackingRestoredSuccessfully;

  /// No description provided for @iosLocationPermissionIssueDuringRestore.
  ///
  /// In en, this message translates to:
  /// **'iOS location permission issue during restore'**
  String get iosLocationPermissionIssueDuringRestore;

  /// No description provided for @iosOnlyWhenInUsePermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'iOS: Only \'When In Use\' permission granted. Background tracking will be limited.'**
  String get iosOnlyWhenInUsePermissionGranted;

  /// No description provided for @iosAlwaysPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'iOS: \'Always\' permission granted. Full background tracking available.'**
  String get iosAlwaysPermissionGranted;

  /// No description provided for @iosErrorRequestingAlwaysPermission.
  ///
  /// In en, this message translates to:
  /// **'iOS: Error requesting always permission'**
  String get iosErrorRequestingAlwaysPermission;

  /// No description provided for @iosContinuingWithWhenInUsePermissionOnly.
  ///
  /// In en, this message translates to:
  /// **'iOS: Continuing with \'When In Use\' permission only.'**
  String get iosContinuingWithWhenInUsePermissionOnly;

  /// No description provided for @batteryOptimizationEnabledMayAffectTracking.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is enabled, may affect background location'**
  String get batteryOptimizationEnabledMayAffectTracking;

  /// No description provided for @trackingYourLocationForServiceDelivery.
  ///
  /// In en, this message translates to:
  /// **'Tracking your location for service delivery'**
  String get trackingYourLocationForServiceDelivery;

  /// No description provided for @aboGlumboLocationTracking.
  ///
  /// In en, this message translates to:
  /// **'Abo Glumbo - Location Tracking'**
  String get aboGlumboLocationTracking;

  /// No description provided for @backgroundLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Background location updated'**
  String get backgroundLocationUpdated;

  /// No description provided for @errorUpdatingBackgroundLocation.
  ///
  /// In en, this message translates to:
  /// **'Error updating background location'**
  String get errorUpdatingBackgroundLocation;

  /// No description provided for @backgroundFetchTriggered.
  ///
  /// In en, this message translates to:
  /// **'Background fetch triggered'**
  String get backgroundFetchTriggered;

  /// No description provided for @backgroundFetchTimeout.
  ///
  /// In en, this message translates to:
  /// **'Background fetch timeout'**
  String get backgroundFetchTimeout;

  /// No description provided for @locationStreamErrorDuringRestore.
  ///
  /// In en, this message translates to:
  /// **'Location stream error during restore'**
  String get locationStreamErrorDuringRestore;

  /// No description provided for @errorRestoringLocationTracking.
  ///
  /// In en, this message translates to:
  /// **'Error restoring location tracking'**
  String get errorRestoringLocationTracking;

  /// No description provided for @backgroundFetchConfiguredAndStarted.
  ///
  /// In en, this message translates to:
  /// **'Background fetch configured and started'**
  String get backgroundFetchConfiguredAndStarted;

  /// No description provided for @errorConfiguringBackgroundFetch.
  ///
  /// In en, this message translates to:
  /// **'Error configuring background fetch'**
  String get errorConfiguringBackgroundFetch;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated'**
  String get locationUpdated;

  /// No description provided for @errorUpdatingLocationToFirestore.
  ///
  /// In en, this message translates to:
  /// **'Error updating location to Firestore'**
  String get errorUpdatingLocationToFirestore;

  /// No description provided for @errorStoppingBackgroundFetch.
  ///
  /// In en, this message translates to:
  /// **'Error stopping background fetch'**
  String get errorStoppingBackgroundFetch;

  /// No description provided for @errorUpdatingBookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating booking status'**
  String get errorUpdatingBookingStatus;

  /// No description provided for @locationTrackingStopped.
  ///
  /// In en, this message translates to:
  /// **'Location tracking stopped'**
  String get locationTrackingStopped;

  /// No description provided for @deleteItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteItemConfirmation;

  /// No description provided for @agentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Technician Unavailable'**
  String get agentUnavailable;

  /// No description provided for @timeConflictDetected.
  ///
  /// In en, this message translates to:
  /// **'Time Conflict Detected'**
  String get timeConflictDetected;

  /// No description provided for @cannotAssignWorkTo.
  ///
  /// In en, this message translates to:
  /// **'Cannot assign work to'**
  String get cannotAssignWorkTo;

  /// No description provided for @alreadyAssignedAtExactSameTime.
  ///
  /// In en, this message translates to:
  /// **'Already assigned at exact same time'**
  String get alreadyAssignedAtExactSameTime;

  /// No description provided for @currentBookingTime.
  ///
  /// In en, this message translates to:
  /// **'Current Booking Time'**
  String get currentBookingTime;

  /// No description provided for @technicianCannotBeAssignedMultipleTimes.
  ///
  /// In en, this message translates to:
  /// **'A Technician cannot be assigned to multiple bookings at the exact same time. Please select a different time slot or choose another Technician.'**
  String get technicianCannotBeAssignedMultipleTimes;

  /// No description provided for @unknownTechnician.
  ///
  /// In en, this message translates to:
  /// **'Unknown Technician'**
  String get unknownTechnician;

  /// No description provided for @tryadifferentsearchterm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryadifferentsearchterm;

  /// No description provided for @warrantyRepairRequested.
  ///
  /// In en, this message translates to:
  /// **'Warranty Repair Requested'**
  String get warrantyRepairRequested;

  /// No description provided for @acceptWarrantyRepair.
  ///
  /// In en, this message translates to:
  /// **'Accept Warranty Repair'**
  String get acceptWarrantyRepair;

  /// No description provided for @customerRequestedRepairUnderWarranty.
  ///
  /// In en, this message translates to:
  /// **'Customer requested repair under warranty'**
  String get customerRequestedRepairUnderWarranty;

  /// No description provided for @warrantyRepairAccepted.
  ///
  /// In en, this message translates to:
  /// **'Warranty Repair Confirmed'**
  String get warrantyRepairAccepted;

  /// No description provided for @technicianAcceptedTheRequest.
  ///
  /// In en, this message translates to:
  /// **'Technician confirmed the request'**
  String get technicianAcceptedTheRequest;

  /// No description provided for @warrantyRepairCompleted.
  ///
  /// In en, this message translates to:
  /// **'Warranty Repair Completed'**
  String get warrantyRepairCompleted;

  /// No description provided for @originalServiceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Original Service Completed'**
  String get originalServiceCompleted;

  /// No description provided for @warrantyRejectedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Warranty Rejected by Admin'**
  String get warrantyRejectedByAdmin;

  /// No description provided for @warrantyRejectedByTechnician.
  ///
  /// In en, this message translates to:
  /// **'Warranty Rejected by Technician'**
  String get warrantyRejectedByTechnician;

  /// No description provided for @reasonforrejection.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get reasonforrejection;

  /// No description provided for @warrantyRequestWasRejectedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Warranty request was rejected by admin'**
  String get warrantyRequestWasRejectedByAdmin;

  /// No description provided for @warrantyRequestWasRejectedByTechnician.
  ///
  /// In en, this message translates to:
  /// **'Warranty request was rejected by technician'**
  String get warrantyRequestWasRejectedByTechnician;

  /// No description provided for @technicianCompletedTheRequest.
  ///
  /// In en, this message translates to:
  /// **'Technician completed the request'**
  String get technicianCompletedTheRequest;

  /// No description provided for @warrantyExpired.
  ///
  /// In en, this message translates to:
  /// **'Warranty Expired'**
  String get warrantyExpired;

  /// No description provided for @warrantyPeriodHasExpired.
  ///
  /// In en, this message translates to:
  /// **'Warranty period has expired'**
  String get warrantyPeriodHasExpired;

  /// No description provided for @trackingStoppedAt.
  ///
  /// In en, this message translates to:
  /// **'Tracking Stopped'**
  String get trackingStoppedAt;

  /// No description provided for @serviceTrackingStopped.
  ///
  /// In en, this message translates to:
  /// **'Service tracking has been stopped'**
  String get serviceTrackingStopped;

  /// No description provided for @youCancelledThisRequest.
  ///
  /// In en, this message translates to:
  /// **'You cancelled this request'**
  String get youCancelledThisRequest;

  /// No description provided for @youDeclinedThisWarrantyRequest.
  ///
  /// In en, this message translates to:
  /// **'You declined this warranty request'**
  String get youDeclinedThisWarrantyRequest;

  /// No description provided for @noresultsfound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noresultsfound;

  /// No description provided for @technicianCancelled.
  ///
  /// In en, this message translates to:
  /// **'Technician Cancelled'**
  String get technicianCancelled;

  /// No description provided for @cancelledByTechnician.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by Technician'**
  String get cancelledByTechnician;

  /// No description provided for @technicianPreviouslyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Technician Previously Cancelled'**
  String get technicianPreviouslyCancelled;

  /// No description provided for @agentCancelledAtTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Technician cancelled at this time before'**
  String get agentCancelledAtTimeSlot;

  /// No description provided for @previouslyCancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Previously cancelled at'**
  String get previouslyCancelledAt;

  /// No description provided for @chooseDifferentAgent.
  ///
  /// In en, this message translates to:
  /// **'Choose Different Technician'**
  String get chooseDifferentAgent;

  /// No description provided for @assignAnyway.
  ///
  /// In en, this message translates to:
  /// **'Assign Anyway'**
  String get assignAnyway;

  /// No description provided for @cancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled at'**
  String get cancelledAt;

  /// No description provided for @technicianCancelledAtTime.
  ///
  /// In en, this message translates to:
  /// **'This Technician previously cancelled a booking at this exact time slot. Consider assigning to a different Technician for better reliability.'**
  String get technicianCancelledAtTime;

  /// No description provided for @errorCheckingBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Error checking battery optimization'**
  String get errorCheckingBatteryOptimization;

  /// No description provided for @technicianRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician Restricted'**
  String get technicianRestrictedTitle;

  /// No description provided for @cannotAssignCancelledTechnician.
  ///
  /// In en, this message translates to:
  /// **'Cannot assign cancelled Technician'**
  String get cannotAssignCancelledTechnician;

  /// No description provided for @lastCancellationOn.
  ///
  /// In en, this message translates to:
  /// **'Last cancellation on'**
  String get lastCancellationOn;

  /// No description provided for @technicianCancelledRestrictionMessage.
  ///
  /// In en, this message translates to:
  /// **'This Technician has previously cancelled a booking and is now restricted from new assignments. Please choose a different Technician.'**
  String get technicianCancelledRestrictionMessage;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @suspendAccount.
  ///
  /// In en, this message translates to:
  /// **'Suspend Account'**
  String get suspendAccount;

  /// No description provided for @unblockAccount.
  ///
  /// In en, this message translates to:
  /// **'Unblock Account'**
  String get unblockAccount;

  /// No description provided for @areYouSureYouWantToSuspendThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to suspend this account?'**
  String get areYouSureYouWantToSuspendThisAccount;

  /// No description provided for @areYouSureYouWantToUnblockThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock this account?'**
  String get areYouSureYouWantToUnblockThisAccount;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspended;

  /// No description provided for @accountUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Account Unblocked'**
  String get accountUnblocked;

  /// No description provided for @completedOrders.
  ///
  /// In en, this message translates to:
  /// **'Completed Orders'**
  String get completedOrders;

  /// No description provided for @profession.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get profession;

  /// No description provided for @idAndDocuments.
  ///
  /// In en, this message translates to:
  /// **'ID and Documents'**
  String get idAndDocuments;

  /// No description provided for @bonusTier.
  ///
  /// In en, this message translates to:
  /// **'Bonus Tier'**
  String get bonusTier;

  /// No description provided for @systemInfo.
  ///
  /// In en, this message translates to:
  /// **'System Info'**
  String get systemInfo;

  /// No description provided for @earningsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Earnings Breakdown'**
  String get earningsBreakdown;

  /// No description provided for @bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get bonuses;

  /// No description provided for @noDocumentsUploaded.
  ///
  /// In en, this message translates to:
  /// **'No Documents Uploaded'**
  String get noDocumentsUploaded;

  /// No description provided for @cancelledThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancelled This Booking'**
  String get cancelledThisBooking;

  /// No description provided for @alreadyBookedAt.
  ///
  /// In en, this message translates to:
  /// **'Already booked at'**
  String get alreadyBookedAt;

  /// No description provided for @bookingAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Booking assigned to'**
  String get bookingAssignedTo;

  /// No description provided for @bookingAssignmentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Booking assignment successful'**
  String get bookingAssignmentSuccessful;

  /// No description provided for @anotherAssignmentInProgress.
  ///
  /// In en, this message translates to:
  /// **'Another assignment is in progress. Please wait...'**
  String get anotherAssignmentInProgress;

  /// No description provided for @assignmentInProgress.
  ///
  /// In en, this message translates to:
  /// **'Assignment in progress. Please wait...'**
  String get assignmentInProgress;

  /// No description provided for @checkingAvailabilityAndAssigning.
  ///
  /// In en, this message translates to:
  /// **'Checking availability and assigning...'**
  String get checkingAvailabilityAndAssigning;

  /// No description provided for @thisBookingAlreadyAssignedToAnotherAgent.
  ///
  /// In en, this message translates to:
  /// **'This booking has already been assigned to another Technician.'**
  String get thisBookingAlreadyAssignedToAnotherAgent;

  /// No description provided for @failedToAssignAgent.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign Technician. Please try again.'**
  String get failedToAssignAgent;

  /// No description provided for @thisAgentCancelledSameBookingBefore.
  ///
  /// In en, this message translates to:
  /// **'This Technician cancelled this same booking before'**
  String get thisAgentCancelledSameBookingBefore;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @showAllAgents.
  ///
  /// In en, this message translates to:
  /// **'Show All Technicians'**
  String get showAllAgents;

  /// No description provided for @availableInSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'available in selected location'**
  String get availableInSelectedLocation;

  /// No description provided for @cancelledThisBookingOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled this booking on'**
  String get cancelledThisBookingOn;

  /// No description provided for @previouslyCancelledAgent.
  ///
  /// In en, this message translates to:
  /// **'Previously Cancelled Technician'**
  String get previouslyCancelledAgent;

  /// No description provided for @agentPreviouslyCancelledWarning.
  ///
  /// In en, this message translates to:
  /// **'This Technician previously cancelled this same booking request. You can still assign them, but consider choosing a more reliable Technician.'**
  String get agentPreviouslyCancelledWarning;

  /// No description provided for @busyAt.
  ///
  /// In en, this message translates to:
  /// **'Busy at'**
  String get busyAt;

  /// No description provided for @managefaq.
  ///
  /// In en, this message translates to:
  /// **'Manage FAQ'**
  String get managefaq;

  /// No description provided for @technicianArrived.
  ///
  /// In en, this message translates to:
  /// **'Technician Arrived'**
  String get technicianArrived;

  /// No description provided for @paymentRequested.
  ///
  /// In en, this message translates to:
  /// **'Payment Requested'**
  String get paymentRequested;

  /// No description provided for @reassignedAt.
  ///
  /// In en, this message translates to:
  /// **'Reassigned At'**
  String get reassignedAt;

  /// No description provided for @newTechnicianAssigned.
  ///
  /// In en, this message translates to:
  /// **'New Technician Assigned'**
  String get newTechnicianAssigned;

  /// No description provided for @technicianStartedTracking.
  ///
  /// In en, this message translates to:
  /// **'Technician is on the way'**
  String get technicianStartedTracking;

  /// No description provided for @technicianArrivedAtLocation.
  ///
  /// In en, this message translates to:
  /// **'Technician arrived at location'**
  String get technicianArrivedAtLocation;

  /// No description provided for @inspectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Inspection Completed'**
  String get inspectionCompleted;

  /// No description provided for @fullServiceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Full Service Completed'**
  String get fullServiceCompleted;

  /// No description provided for @cancelledByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by Admin'**
  String get cancelledByAdmin;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment Completed'**
  String get paymentCompleted;

  /// No description provided for @paymentSuccessfullyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment has been successfully completed'**
  String get paymentSuccessfullyCompleted;

  /// No description provided for @bookingCancelledByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Booking was cancelled by admin'**
  String get bookingCancelledByAdmin;

  /// No description provided for @addFaq.
  ///
  /// In en, this message translates to:
  /// **'Add FAQ'**
  String get addFaq;

  /// No description provided for @noFaqEntriesFound.
  ///
  /// In en, this message translates to:
  /// **'No FAQ entries found'**
  String get noFaqEntriesFound;

  /// No description provided for @manageFaqs.
  ///
  /// In en, this message translates to:
  /// **'Manage FAQs'**
  String get manageFaqs;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @questionIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Question is required'**
  String get questionIsRequired;

  /// No description provided for @answerIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Answer is required'**
  String get answerIsRequired;

  /// No description provided for @faqAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'FAQ added successfully'**
  String get faqAddedSuccessfully;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @addFaqEntry.
  ///
  /// In en, this message translates to:
  /// **'Add FAQ Entry'**
  String get addFaqEntry;

  /// No description provided for @questionMustBeInArabic.
  ///
  /// In en, this message translates to:
  /// **'Question must be in Arabic'**
  String get questionMustBeInArabic;

  /// No description provided for @answerMustBeInArabic.
  ///
  /// In en, this message translates to:
  /// **'Answer must be in Arabic'**
  String get answerMustBeInArabic;

  /// No description provided for @faqEntryDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'FAQ entry deleted successfully'**
  String get faqEntryDeletedSuccessfully;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @entryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Entry exists in the entered position'**
  String get entryAlreadyExists;

  /// No description provided for @manageCustomers.
  ///
  /// In en, this message translates to:
  /// **'Manage Customers'**
  String get manageCustomers;

  /// No description provided for @areYouSureYouWantToUnBlockThisCustomer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to un-block this customer?'**
  String get areYouSureYouWantToUnBlockThisCustomer;

  /// No description provided for @areYouSureYouWantToBlockThisCustomer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this customer?'**
  String get areYouSureYouWantToBlockThisCustomer;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @customerUnblockedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer unblocked successfully'**
  String get customerUnblockedSuccessfully;

  /// No description provided for @customerBlockedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer blocked successfully'**
  String get customerBlockedSuccessfully;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @blockCustomer.
  ///
  /// In en, this message translates to:
  /// **'Block Customer'**
  String get blockCustomer;

  /// No description provided for @unBlockCustomer.
  ///
  /// In en, this message translates to:
  /// **'Un-block Customer'**
  String get unBlockCustomer;

  /// No description provided for @checkingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Checking Technician availability...'**
  String get checkingAvailability;

  /// No description provided for @positionText.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get positionText;

  /// No description provided for @faqUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'FAQ updated successfully'**
  String get faqUpdatedSuccessfully;

  /// No description provided for @deleteFaqEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete FAQ Entry'**
  String get deleteFaqEntry;

  /// No description provided for @manageTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Manage Technicians'**
  String get manageTechnicians;

  /// No description provided for @manageCustomerSupport.
  ///
  /// In en, this message translates to:
  /// **'Manage Customer Support'**
  String get manageCustomerSupport;

  /// No description provided for @customerSupport.
  ///
  /// In en, this message translates to:
  /// **'Customer Support'**
  String get customerSupport;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @addNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Add New Email'**
  String get addNewEmail;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @areYouSureYouWantToDeleteThisFaqEntry.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this FAQ entry?'**
  String get areYouSureYouWantToDeleteThisFaqEntry;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get thisActionCannotBeUndone;

  /// No description provided for @supportContactDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Support contact deleted successfully'**
  String get supportContactDeletedSuccessfully;

  /// No description provided for @supportContactUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Support contact updated successfully'**
  String get supportContactUpdatedSuccessfully;

  /// No description provided for @supportContactAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Support contact added successfully'**
  String get supportContactAddedSuccessfully;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get deleteConfirmation;

  /// No description provided for @areYouSureYouWantToDeleteThisSupportContact.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this support contact?'**
  String get areYouSureYouWantToDeleteThisSupportContact;

  /// No description provided for @supportContact.
  ///
  /// In en, this message translates to:
  /// **'Support Contact'**
  String get supportContact;

  /// No description provided for @phoneIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneIsRequired;

  /// No description provided for @whatsappNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number is required'**
  String get whatsappNumberIsRequired;

  /// No description provided for @editEmail.
  ///
  /// In en, this message translates to:
  /// **'Edit Email'**
  String get editEmail;

  /// No description provided for @addNewWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Add New WhatsApp'**
  String get addNewWhatsapp;

  /// No description provided for @addNewPhone.
  ///
  /// In en, this message translates to:
  /// **'Add New Phone'**
  String get addNewPhone;

  /// No description provided for @editWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Edit WhatsApp'**
  String get editWhatsapp;

  /// No description provided for @editPhone.
  ///
  /// In en, this message translates to:
  /// **'Edit Phone'**
  String get editPhone;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @setAsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set as Primary'**
  String get setAsPrimary;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @disapproveAgent.
  ///
  /// In en, this message translates to:
  /// **'Disapprove Technician'**
  String get disapproveAgent;

  /// No description provided for @approveAgent.
  ///
  /// In en, this message translates to:
  /// **'Approve Technician'**
  String get approveAgent;

  /// No description provided for @areYouSureYouWantToDisapproveThisAgent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disapprove this Technician?'**
  String get areYouSureYouWantToDisapproveThisAgent;

  /// No description provided for @areYouSureYouWantToApproveThisAgent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this Technician?'**
  String get areYouSureYouWantToApproveThisAgent;

  /// No description provided for @tryAdjustingYourSearchCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get tryAdjustingYourSearchCriteria;

  /// No description provided for @noTechniciansMatchYourFilters.
  ///
  /// In en, this message translates to:
  /// **'No Technicians match your search'**
  String get noTechniciansMatchYourFilters;

  /// No description provided for @unblockCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unblock Customer'**
  String get unblockCustomer;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @typeProvinceNameToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type province name to search...'**
  String get typeProvinceNameToSearch;

  /// No description provided for @typeCityNameToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type city name to search...'**
  String get typeCityNameToSearch;

  /// No description provided for @typeNeighborhoodNameToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type neighborhood name to search...'**
  String get typeNeighborhoodNameToSearch;

  /// No description provided for @areYouSureYouWantToUnblockThisCustomer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock this customer?'**
  String get areYouSureYouWantToUnblockThisCustomer;

  /// No description provided for @noCustomersMatchYourSearch.
  ///
  /// In en, this message translates to:
  /// **'No customers match your search'**
  String get noCustomersMatchYourSearch;

  /// No description provided for @searchbyBookingIdnameTechnician.
  ///
  /// In en, this message translates to:
  /// **'Search by Booking ID, Name, Technician'**
  String get searchbyBookingIdnameTechnician;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @cancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled On'**
  String get cancelledOn;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @whatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get whatsappNumber;

  /// No description provided for @whatsappCondition.
  ///
  /// In en, this message translates to:
  /// **'Please ensure the phone number you enter includes the country code at the beginning with a plus sign. This format is required for WhatsApp to recognize the number correctly.'**
  String get whatsappCondition;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @contactNotFound.
  ///
  /// In en, this message translates to:
  /// **'Contact not found'**
  String get contactNotFound;

  /// No description provided for @keepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep Booking'**
  String get keepBooking;

  /// No description provided for @orderCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully'**
  String get orderCancelledSuccessfully;

  /// No description provided for @failedToCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel order'**
  String get failedToCancelOrder;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @cancelledBy.
  ///
  /// In en, this message translates to:
  /// **'Cancelled By'**
  String get cancelledBy;

  /// No description provided for @pleaseEnterInspectionFeeAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter inspection fee amount'**
  String get pleaseEnterInspectionFeeAmount;

  /// No description provided for @rejectBooking.
  ///
  /// In en, this message translates to:
  /// **'Reject Booking'**
  String get rejectBooking;

  /// No description provided for @pleaseuploadpaymentproof.
  ///
  /// In en, this message translates to:
  /// **'Please upload payment proof'**
  String get pleaseuploadpaymentproof;

  /// No description provided for @iban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload proof image/file'**
  String get tapToUpload;

  /// No description provided for @selectSource.
  ///
  /// In en, this message translates to:
  /// **'Select Source'**
  String get selectSource;

  /// No description provided for @areYouSureYouWantToRejectThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this booking?'**
  String get areYouSureYouWantToRejectThisBooking;

  /// No description provided for @acceptBooking.
  ///
  /// In en, this message translates to:
  /// **'Accept Booking'**
  String get acceptBooking;

  /// No description provided for @requestPayout.
  ///
  /// In en, this message translates to:
  /// **'Request Payout'**
  String get requestPayout;

  /// No description provided for @lastTip.
  ///
  /// In en, this message translates to:
  /// **'Last Tip'**
  String get lastTip;

  /// No description provided for @paymentBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Payment Breakdown'**
  String get paymentBreakdown;

  /// No description provided for @cashPayments.
  ///
  /// In en, this message translates to:
  /// **'Cash Payments'**
  String get cashPayments;

  /// No description provided for @cardPayments.
  ///
  /// In en, this message translates to:
  /// **'Card Payments'**
  String get cardPayments;

  /// No description provided for @asOf.
  ///
  /// In en, this message translates to:
  /// **'As of'**
  String get asOf;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @pleaseEnterAValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterAValidAmount;

  /// No description provided for @amountExceedsAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds available balance'**
  String get amountExceedsAvailableBalance;

  /// No description provided for @cashPaymentsAreAlreadyWithYou.
  ///
  /// In en, this message translates to:
  /// **'Cash payments are already with you'**
  String get cashPaymentsAreAlreadyWithYou;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @availableForPayout.
  ///
  /// In en, this message translates to:
  /// **'Available for Payout'**
  String get availableForPayout;

  /// No description provided for @theAdminWillProcessYourRequestWithin2to3days.
  ///
  /// In en, this message translates to:
  /// **'The admin will process your request within 2 - 3 business days.'**
  String get theAdminWillProcessYourRequestWithin2to3days;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @areYouSureYouWantToAcceptThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this booking?'**
  String get areYouSureYouWantToAcceptThisBooking;

  /// No description provided for @cancelledByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by Customer'**
  String get cancelledByCustomer;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get confirmCancellation;

  /// No description provided for @adminCancelWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking? The customer will be notified. Cancelling this booking will not refund the customer automatically. Please ensure to process any necessary refunds manually.'**
  String get adminCancelWarning;

  /// No description provided for @atleastOneContactIsrequired.
  ///
  /// In en, this message translates to:
  /// **'At least one contact is required'**
  String get atleastOneContactIsrequired;

  /// No description provided for @cannotRemovePrimaryStatusFromTheOnlyContact.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove primary status from the only contact'**
  String get cannotRemovePrimaryStatusFromTheOnlyContact;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @payoutAccounts.
  ///
  /// In en, this message translates to:
  /// **'Payout Accounts'**
  String get payoutAccounts;

  /// No description provided for @noPayoutAccountsAdded.
  ///
  /// In en, this message translates to:
  /// **'No payout accounts added'**
  String get noPayoutAccountsAdded;

  /// No description provided for @imageIsTooLargePleaseSelectAnImageSmallerThan5MB.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Please select an image smaller than 5 MB'**
  String get imageIsTooLargePleaseSelectAnImageSmallerThan5MB;

  /// No description provided for @managePayouts.
  ///
  /// In en, this message translates to:
  /// **'Manage Payouts'**
  String get managePayouts;

  /// No description provided for @requestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested on'**
  String get requestedOn;

  /// No description provided for @selectedFileCouldNotBeFound.
  ///
  /// In en, this message translates to:
  /// **'Selected file could not be found. Please try again.'**
  String get selectedFileCouldNotBeFound;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// No description provided for @errorCroppingImage.
  ///
  /// In en, this message translates to:
  /// **'Error cropping image'**
  String get errorCroppingImage;

  /// No description provided for @technicianInformation.
  ///
  /// In en, this message translates to:
  /// **'Technician Information'**
  String get technicianInformation;

  /// No description provided for @noPayoutRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No payout requests yet'**
  String get noPayoutRequestsYet;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @payoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Payout History'**
  String get payoutHistory;

  /// No description provided for @searchByTechnicianNameOrAmount.
  ///
  /// In en, this message translates to:
  /// **'Search by technician name or amount...'**
  String get searchByTechnicianNameOrAmount;

  /// No description provided for @tipDetails.
  ///
  /// In en, this message translates to:
  /// **'Tip Details'**
  String get tipDetails;

  /// No description provided for @tipsSummary.
  ///
  /// In en, this message translates to:
  /// **'Tips Summary'**
  String get tipsSummary;

  /// No description provided for @noPayoutHistoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No payout history available'**
  String get noPayoutHistoryAvailable;

  /// No description provided for @smsRetrievalTimedOut.
  ///
  /// In en, this message translates to:
  /// **'SMS retrieval timed out. Please check if you received the code or try again.'**
  String get smsRetrievalTimedOut;

  /// No description provided for @payoutRequirement.
  ///
  /// In en, this message translates to:
  /// **'To request a tip payout, you\'ll need at least 10 SAR available for payout.'**
  String get payoutRequirement;

  /// No description provided for @notEnoughBalanceforRequestingTipPayout.
  ///
  /// In en, this message translates to:
  /// **'Not enough balance to request a tip payout'**
  String get notEnoughBalanceforRequestingTipPayout;

  /// No description provided for @cashTips.
  ///
  /// In en, this message translates to:
  /// **'Outside App Tips'**
  String get cashTips;

  /// No description provided for @cardTips.
  ///
  /// In en, this message translates to:
  /// **'Inside App Tips'**
  String get cardTips;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @inHand.
  ///
  /// In en, this message translates to:
  /// **'In Hand'**
  String get inHand;

  /// No description provided for @errorLoadingReviews.
  ///
  /// In en, this message translates to:
  /// **'Error loading reviews'**
  String get errorLoadingReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @reviewsWillAppearHereAfterCustomersRateYourService.
  ///
  /// In en, this message translates to:
  /// **'Reviews will appear here after customers rate your service'**
  String get reviewsWillAppearHereAfterCustomersRateYourService;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @failedToLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get failedToLoadVideo;

  /// No description provided for @payoutAmount.
  ///
  /// In en, this message translates to:
  /// **'Payout Amount'**
  String get payoutAmount;

  /// No description provided for @bankAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Details'**
  String get bankAccountDetails;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @rejectPayout.
  ///
  /// In en, this message translates to:
  /// **'Reject Payout'**
  String get rejectPayout;

  /// No description provided for @payoutApproved.
  ///
  /// In en, this message translates to:
  /// **'Payout Approved'**
  String get payoutApproved;

  /// No description provided for @approvePayout.
  ///
  /// In en, this message translates to:
  /// **'Approve Payout'**
  String get approvePayout;

  /// No description provided for @fileRequired.
  ///
  /// In en, this message translates to:
  /// **'File is required'**
  String get fileRequired;

  /// No description provided for @transactionNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Transaction number is required'**
  String get transactionNumberRequired;

  /// No description provided for @viewAndManageEarnings.
  ///
  /// In en, this message translates to:
  /// **'View and manage earnings'**
  String get viewAndManageEarnings;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats:'**
  String get supportedFormats;

  /// No description provided for @lifetimeTips.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Tips'**
  String get lifetimeTips;

  /// No description provided for @pleaseProvideTransactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Please provide transaction details to approve this payout request.'**
  String get pleaseProvideTransactionDetails;

  /// No description provided for @pdfImageOrDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF, Image, or Document'**
  String get pdfImageOrDocument;

  /// No description provided for @tapToSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select file'**
  String get tapToSelectFile;

  /// No description provided for @lifetimeEarnings.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Earnings'**
  String get lifetimeEarnings;

  /// No description provided for @uploadProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Proof'**
  String get uploadProof;

  /// No description provided for @notenoughtipstorequestpayoutminSAR10.
  ///
  /// In en, this message translates to:
  /// **'Not enough tips to request payout (min SAR 10)'**
  String get notenoughtipstorequestpayoutminSAR10;

  /// No description provided for @requestTipPayout.
  ///
  /// In en, this message translates to:
  /// **'Request Tip Payout'**
  String get requestTipPayout;

  /// No description provided for @errorRequestingPayout.
  ///
  /// In en, this message translates to:
  /// **'Error requesting payout'**
  String get errorRequestingPayout;

  /// No description provided for @payoutRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payout request submitted successfully'**
  String get payoutRequestSubmittedSuccessfully;

  /// No description provided for @areYouSureYouWantToRequestAPayoutForTheAccumulatedTips.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to request a payout for the accumulated tips?'**
  String get areYouSureYouWantToRequestAPayoutForTheAccumulatedTips;

  /// No description provided for @transactionNumber.
  ///
  /// In en, this message translates to:
  /// **'Transaction Number'**
  String get transactionNumber;

  /// No description provided for @tipspayoutisdoneseparately.
  ///
  /// In en, this message translates to:
  /// **'Tips payout is done separately'**
  String get tipspayoutisdoneseparately;

  /// No description provided for @pleaseProvideARejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a rejection reason'**
  String get pleaseProvideARejectionReason;

  /// No description provided for @enterTransactionNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Transaction Number'**
  String get enterTransactionNumber;

  /// No description provided for @youHaveNoPayoutAccountsgotoprofilesectionandaddanaccount.
  ///
  /// In en, this message translates to:
  /// **'You have no payout accounts. Go to profile section and add an account.'**
  String get youHaveNoPayoutAccountsgotoprofilesectionandaddanaccount;

  /// No description provided for @payoutRejectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payout rejected successfully'**
  String get payoutRejectedSuccessfully;

  /// No description provided for @payoutRejected.
  ///
  /// In en, this message translates to:
  /// **'Payout Rejected'**
  String get payoutRejected;

  /// No description provided for @rejectConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this payout request?'**
  String get rejectConfirmation;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @enterTheReason.
  ///
  /// In en, this message translates to:
  /// **'Enter the reason for rejecting this payout request'**
  String get enterTheReason;

  /// No description provided for @payoutRequests.
  ///
  /// In en, this message translates to:
  /// **'Payout Requests'**
  String get payoutRequests;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @noPayoutRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No payout requests found'**
  String get noPayoutRequestsFound;

  /// No description provided for @payoutRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payout request cancelled'**
  String get payoutRequestCancelled;

  /// No description provided for @areYouSureYouWantToCancelThisPayoutRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this payout request?'**
  String get areYouSureYouWantToCancelThisPayoutRequest;

  /// No description provided for @addAnAccountToReceivePayments.
  ///
  /// In en, this message translates to:
  /// **'Add an account to receive payments'**
  String get addAnAccountToReceivePayments;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @ifscCode.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get ifscCode;

  /// No description provided for @addFirstAccount.
  ///
  /// In en, this message translates to:
  /// **'Add your first account'**
  String get addFirstAccount;

  /// No description provided for @enterAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Account Details'**
  String get enterAccountDetails;

  /// No description provided for @manageBankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage Bank Accounts'**
  String get manageBankAccounts;

  /// No description provided for @addAndManageYourPayoutAccounts.
  ///
  /// In en, this message translates to:
  /// **'Add and manage your payout accounts'**
  String get addAndManageYourPayoutAccounts;

  /// No description provided for @updateAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Update Account Details'**
  String get updateAccountDetails;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @primaryAccountUpdated.
  ///
  /// In en, this message translates to:
  /// **'Primary account updated'**
  String get primaryAccountUpdated;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account?'**
  String get deleteAccountConfirmation;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @pleaseEnterAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter account number'**
  String get pleaseEnterAccountNumber;

  /// No description provided for @accountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderName;

  /// No description provided for @nameMustBeAtLeast3Chars.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get nameMustBeAtLeast3Chars;

  /// No description provided for @pleaseEnterAccountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Please enter account holder name'**
  String get pleaseEnterAccountHolderName;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @updateAccount.
  ///
  /// In en, this message translates to:
  /// **'Update Account'**
  String get updateAccount;

  /// No description provided for @setPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set Primary'**
  String get setPrimary;

  /// No description provided for @accountAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account added successfully'**
  String get accountAddedSuccessfully;

  /// No description provided for @accountUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account updated successfully'**
  String get accountUpdatedSuccessfully;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @enterAccountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Enter Account Holder Name'**
  String get enterAccountHolderName;

  /// No description provided for @enterifscCode.
  ///
  /// In en, this message translates to:
  /// **'Enter IBAN'**
  String get enterifscCode;

  /// No description provided for @enterBankName.
  ///
  /// In en, this message translates to:
  /// **'Enter Bank Name'**
  String get enterBankName;

  /// No description provided for @enterAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Account Number'**
  String get enterAccountNumber;

  /// No description provided for @setAsPrimaryAccount.
  ///
  /// In en, this message translates to:
  /// **'Set as Primary Account'**
  String get setAsPrimaryAccount;

  /// No description provided for @pleaseEnterBankName.
  ///
  /// In en, this message translates to:
  /// **'Please enter bank name'**
  String get pleaseEnterBankName;

  /// No description provided for @pleaseEnterIfscCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter IBAN'**
  String get pleaseEnterIfscCode;

  /// No description provided for @copyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get copyId;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loadingCustomers.
  ///
  /// In en, this message translates to:
  /// **'Loading customers'**
  String get loadingCustomers;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @allReviews.
  ///
  /// In en, this message translates to:
  /// **'All Reviews'**
  String get allReviews;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @ratingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Rating Distribution'**
  String get ratingDistribution;

  /// No description provided for @payoutRequestSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payout request successful'**
  String get payoutRequestSuccessful;

  /// No description provided for @rejectedBy.
  ///
  /// In en, this message translates to:
  /// **'Rejected by'**
  String get rejectedBy;

  /// No description provided for @rejectedOn.
  ///
  /// In en, this message translates to:
  /// **'Rejected on'**
  String get rejectedOn;

  /// No description provided for @acceptedOn.
  ///
  /// In en, this message translates to:
  /// **'Confirmed on'**
  String get acceptedOn;

  /// No description provided for @acceptedBy.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by'**
  String get acceptedBy;

  /// No description provided for @completedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed on'**
  String get completedOn;

  /// No description provided for @completedBy.
  ///
  /// In en, this message translates to:
  /// **'Completed by'**
  String get completedBy;

  /// No description provided for @confirmDetails.
  ///
  /// In en, this message translates to:
  /// **'Confirm Details'**
  String get confirmDetails;

  /// No description provided for @loadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loadingCategories;

  /// No description provided for @pleaseUploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Please upload files'**
  String get pleaseUploadFiles;

  /// No description provided for @confirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Completion'**
  String get confirmCompletion;

  /// No description provided for @uploadFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof of Completion / Supporting Documents'**
  String get uploadFilesTitle;

  /// No description provided for @uploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo or bill showing completed work or purchased items'**
  String get uploadHint;

  /// No description provided for @pleaseUploadFilesMessage.
  ///
  /// In en, this message translates to:
  /// **'Please upload atleast one proof of completion / supporting document'**
  String get pleaseUploadFilesMessage;

  /// No description provided for @confirmCompletionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm completion of this booking?'**
  String get confirmCompletionMessage;

  /// No description provided for @cannotCancel.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel this booking while tracking is active. Please stop tracking first, then you can cancel the booking.'**
  String get cannotCancel;

  /// No description provided for @cannotCompleteBookingWhileTracking.
  ///
  /// In en, this message translates to:
  /// **'Cannot complete this work while tracking is active. Please stop tracking first, then you can complete the work.'**
  String get cannotCompleteBookingWhileTracking;

  /// No description provided for @editSelection.
  ///
  /// In en, this message translates to:
  /// **'Edit Selection'**
  String get editSelection;

  /// No description provided for @noRecipientsSelected.
  ///
  /// In en, this message translates to:
  /// **'No recipients selected'**
  String get noRecipientsSelected;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @tapToUploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload files'**
  String get tapToUploadFiles;

  /// No description provided for @addRecipients.
  ///
  /// In en, this message translates to:
  /// **'Add Recipients'**
  String get addRecipients;

  /// No description provided for @serviceItemsCalculationNote.
  ///
  /// In en, this message translates to:
  /// **'The total cost will be calculated automatically as (Quantity Ã— Price) for each item and added to the inspection fee.'**
  String get serviceItemsCalculationNote;

  /// No description provided for @addMoreFiles.
  ///
  /// In en, this message translates to:
  /// **'Add more files'**
  String get addMoreFiles;

  /// No description provided for @allowedFileTypes.
  ///
  /// In en, this message translates to:
  /// **'Allowed file types: jpg, jpeg, png, pdf, doc,'**
  String get allowedFileTypes;

  /// No description provided for @uploadFileOrImage.
  ///
  /// In en, this message translates to:
  /// **'Upload File or Image'**
  String get uploadFileOrImage;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'PENDING REVIEW'**
  String get pendingReview;

  /// No description provided for @uploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload Files'**
  String get uploadFiles;

  /// No description provided for @filesAttached.
  ///
  /// In en, this message translates to:
  /// **'Files attached'**
  String get filesAttached;

  /// No description provided for @costBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Cost Breakdown'**
  String get costBreakdown;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @removeItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this item?'**
  String get removeItemConfirmation;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @noBannersAAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No banners added yet'**
  String get noBannersAAddedYet;

  /// No description provided for @availableRoles.
  ///
  /// In en, this message translates to:
  /// **'Available Roles'**
  String get availableRoles;

  /// No description provided for @fifteenpercentBonusOnEarningsandASpecialBadge.
  ///
  /// In en, this message translates to:
  /// **'15% Bonus on Earnings + Special Badge'**
  String get fifteenpercentBonusOnEarningsandASpecialBadge;

  /// No description provided for @tenpercentBonusOnEarnings.
  ///
  /// In en, this message translates to:
  /// **'10% Bonus on Earnings'**
  String get tenpercentBonusOnEarnings;

  /// No description provided for @fivepercentBonusOnEarnings.
  ///
  /// In en, this message translates to:
  /// **'5% Bonus on Earnings'**
  String get fivepercentBonusOnEarnings;

  /// No description provided for @invalidAccountNumberLength.
  ///
  /// In en, this message translates to:
  /// **'Invalid account number length'**
  String get invalidAccountNumberLength;

  /// Done button with selected count
  ///
  /// In en, this message translates to:
  /// **'Done ({count} selected)'**
  String doneSelectedCount(int count);

  /// Message showing number of technicians selected with plural forms
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No technicians selected} =1{1 technician selected} other{{count} technicians selected}}'**
  String technicianSelected(int count);

  /// Message indicating payout request is successful
  ///
  /// In en, this message translates to:
  /// **'\'Payout request for SAR \${amount} submitted\','**
  String payoutRequestSuccessfulMessage(String amount);

  /// Message indicating cash payments are with the user
  ///
  /// In en, this message translates to:
  /// **'Cash payments (SAR \${amount}) are already with you'**
  String cashPaymentsMessage(String amount);

  /// Error message when trying to delete the last contact of a specific type
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the last {contactType} contact. At least one contact is required.'**
  String cannotDeleteLastContact(String contactType);

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInfo;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location Error'**
  String get locationError;

  /// No description provided for @locationServicesIos.
  ///
  /// In en, this message translates to:
  /// **'This is an iOS location permission error. Please check your location settings.'**
  String get locationServicesIos;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services in your device settings.'**
  String get locationServices;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Please grant location permission in Settings and select \"Allow all the time\" for background tracking.'**
  String get locationPermission;

  /// No description provided for @batteryOptimizationWarning.
  ///
  /// In en, this message translates to:
  /// **'For reliable background location tracking, please disable battery optimization for this app. This ensures location updates continue even when the app is in the background.'**
  String get batteryOptimizationWarning;

  /// No description provided for @bookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking history'**
  String get bookingHistory;

  /// No description provided for @pleaseSelectAtLeastOneRecipient.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one recipient'**
  String get pleaseSelectAtLeastOneRecipient;

  /// No description provided for @fillInAtLeastEnglishOrArabicMessageContent.
  ///
  /// In en, this message translates to:
  /// **'Please fill in at least English or Arabic message content'**
  String get fillInAtLeastEnglishOrArabicMessageContent;

  /// No description provided for @searchByNameEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or phone...'**
  String get searchByNameEmailOrPhone;

  /// No description provided for @noFcmTokenAvailable.
  ///
  /// In en, this message translates to:
  /// **'No FCM token available'**
  String get noFcmTokenAvailable;

  /// No description provided for @selectRecipients.
  ///
  /// In en, this message translates to:
  /// **'Select Recipients'**
  String get selectRecipients;

  /// No description provided for @removeAll.
  ///
  /// In en, this message translates to:
  /// **'Remove All'**
  String get removeAll;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Uploaded documents'**
  String get documents;

  /// No description provided for @allData.
  ///
  /// In en, this message translates to:
  /// **'All associated data'**
  String get allData;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication disabled'**
  String get biometricDisabled;

  /// No description provided for @disableBiometricWarning.
  ///
  /// In en, this message translates to:
  /// **'Disabling biometric authentication will prevent you from logging in using fingerprint.'**
  String get disableBiometricWarning;

  /// No description provided for @youWillNeedPhoneOtp.
  ///
  /// In en, this message translates to:
  /// **'You will need to use your phone number and OTP to login.'**
  String get youWillNeedPhoneOtp;

  /// No description provided for @whatWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'What will be deleted:'**
  String get whatWillBeDeleted;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @disableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Disable Biometric?'**
  String get disableBiometric;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @pleaseSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Please select city'**
  String get pleaseSelectCity;

  /// No description provided for @pleaseSelectGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Please select governorate'**
  String get pleaseSelectGovernorate;

  /// No description provided for @governorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get governorate;

  /// No description provided for @neighborhood.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get neighborhood;

  /// No description provided for @pleaseSelectNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Please select neighborhood'**
  String get pleaseSelectNeighborhood;

  /// No description provided for @pleaseSelectProvince.
  ///
  /// In en, this message translates to:
  /// **'Please select province'**
  String get pleaseSelectProvince;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'OTP expired'**
  String get otpExpired;

  /// No description provided for @invalidOTP.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalidOTP;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @otpSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otpSentSuccessfully;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// No description provided for @registerAsTechinicianInfo.
  ///
  /// In en, this message translates to:
  /// **'Register your phone number to create a technician account'**
  String get registerAsTechinicianInfo;

  /// No description provided for @phoneAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Phone already registered'**
  String get phoneAlreadyRegistered;

  /// No description provided for @invalidOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP code'**
  String get invalidOtpCode;

  /// No description provided for @quotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'Quota exceeded'**
  String get quotaExceeded;

  /// No description provided for @internalError.
  ///
  /// In en, this message translates to:
  /// **'Internal error'**
  String get internalError;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @loginWithBiometric.
  ///
  /// In en, this message translates to:
  /// **'Login with biometric'**
  String get loginWithBiometric;

  /// No description provided for @migratingData.
  ///
  /// In en, this message translates to:
  /// **'Migrating data'**
  String get migratingData;

  /// No description provided for @weAreMigratingYourData.
  ///
  /// In en, this message translates to:
  /// **'We are migrating your data'**
  String get weAreMigratingYourData;

  /// No description provided for @pleaseDontCloseTheApp.
  ///
  /// In en, this message translates to:
  /// **'Please don\'t close the app'**
  String get pleaseDontCloseTheApp;

  /// No description provided for @transferringData.
  ///
  /// In en, this message translates to:
  /// **'Transferring data'**
  String get transferringData;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @sendingOTP.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP'**
  String get sendingOTP;

  /// No description provided for @cancelRegistration.
  ///
  /// In en, this message translates to:
  /// **'Cancel Registration'**
  String get cancelRegistration;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @didNotReceiveOTP.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive OTP?'**
  String get didNotReceiveOTP;

  /// No description provided for @cancelRegistrationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel registration?'**
  String get cancelRegistrationConfirmation;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registrationSuccessful;

  /// No description provided for @otpMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'OTP must be 6 digits'**
  String get otpMustBe6Digits;

  /// No description provided for @pleaseEnterOTP.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP'**
  String get pleaseEnterOTP;

  /// No description provided for @resendOTP.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOTP;

  /// No description provided for @enterReasonForCancel.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for cancellation'**
  String get enterReasonForCancel;

  /// No description provided for @enterReasonForReject.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for rejection'**
  String get enterReasonForReject;

  /// No description provided for @noWarrantyRequests.
  ///
  /// In en, this message translates to:
  /// **'No warranty requests'**
  String get noWarrantyRequests;

  /// No description provided for @completeWarrantyRepair.
  ///
  /// In en, this message translates to:
  /// **'Complete Warranty Repair'**
  String get completeWarrantyRepair;

  /// No description provided for @areYouSureYouWantToCompleteThisWarrantyRepairThisIsAFreeService.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to complete this warranty repair? This is a free service.'**
  String get areYouSureYouWantToCompleteThisWarrantyRepairThisIsAFreeService;

  /// No description provided for @areYouSureYouWantToStopTrackingThisWarrantyRepair.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop tracking this warranty repair?'**
  String get areYouSureYouWantToStopTrackingThisWarrantyRepair;

  /// No description provided for @areYouSureYouWantToStartTrackingThisWarrantyRepair.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to start tracking this warranty repair?'**
  String get areYouSureYouWantToStartTrackingThisWarrantyRepair;

  /// No description provided for @anotherBookingIsAlreadyBeingTracked.
  ///
  /// In en, this message translates to:
  /// **'Another booking is already being tracked. Please complete or stop the current tracking before starting a new one.'**
  String get anotherBookingIsAlreadyBeingTracked;

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'requested'**
  String get requested;

  /// No description provided for @areYouSureYouWantToCancelThisWarrantyRepairThisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this warranty repair? This action cannot be undone.'**
  String
  get areYouSureYouWantToCancelThisWarrantyRepairThisActionCannotBeUndone;

  /// No description provided for @reasonMustBeAtLeast10Characters.
  ///
  /// In en, this message translates to:
  /// **'Reason must be at least 10 characters'**
  String get reasonMustBeAtLeast10Characters;

  /// No description provided for @cancelWarrantyRepair.
  ///
  /// In en, this message translates to:
  /// **'Cancel Warranty Repair'**
  String get cancelWarrantyRepair;

  /// No description provided for @areYouSureYouWantToDeleteThisFile.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file?'**
  String get areYouSureYouWantToDeleteThisFile;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @rejectWarrantyClaimMessage.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejecting this warranty claim'**
  String get rejectWarrantyClaimMessage;

  /// No description provided for @invalidPhoneNumberLength.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number length'**
  String get invalidPhoneNumberLength;

  /// No description provided for @phoneNumberMustIncludeCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Phone number must include country code'**
  String get phoneNumberMustIncludeCountryCode;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max 10MB)'**
  String get fileTooLarge;

  /// No description provided for @warrantyClaimRejected.
  ///
  /// In en, this message translates to:
  /// **'Warranty claim rejected'**
  String get warrantyClaimRejected;

  /// No description provided for @rejectWarrantyClaim.
  ///
  /// In en, this message translates to:
  /// **'Reject Warranty Claim'**
  String get rejectWarrantyClaim;

  /// No description provided for @workCompleted.
  ///
  /// In en, this message translates to:
  /// **'Work Completed'**
  String get workCompleted;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @technician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technician;

  /// No description provided for @noBankAccountDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No bank account details available'**
  String get noBankAccountDetailsAvailable;

  /// No description provided for @acceptWarrantyClaim.
  ///
  /// In en, this message translates to:
  /// **'Accept Warranty Claim'**
  String get acceptWarrantyClaim;

  /// No description provided for @areYouSureYouWantToRejectThisWarrantyClaim.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this warranty claim?'**
  String get areYouSureYouWantToRejectThisWarrantyClaim;

  /// No description provided for @acceptWarrantyClaimMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to accept this warranty claim?'**
  String get acceptWarrantyClaimMessage;

  /// No description provided for @completeWorkMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this warranty work as completed?'**
  String get completeWorkMessage;

  /// No description provided for @startWorkMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you ready to start working on this warranty claim?'**
  String get startWorkMessage;

  /// No description provided for @stopTrackingMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to stop tracking for this warranty work?'**
  String get stopTrackingMessage;

  /// No description provided for @warrantyClaimCancelled.
  ///
  /// In en, this message translates to:
  /// **'Warranty claim cancelled'**
  String get warrantyClaimCancelled;

  /// No description provided for @cancelWarrantyClaim.
  ///
  /// In en, this message translates to:
  /// **'Cancel Warranty Claim'**
  String get cancelWarrantyClaim;

  /// No description provided for @cancelWork.
  ///
  /// In en, this message translates to:
  /// **'Cancel Work'**
  String get cancelWork;

  /// No description provided for @cancelWarrantyClaimMessage.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for cancelling this warranty work'**
  String get cancelWarrantyClaimMessage;

  /// No description provided for @cropDocument.
  ///
  /// In en, this message translates to:
  /// **'Crop Document'**
  String get cropDocument;

  /// No description provided for @tapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get tapToRetry;

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistration;

  /// No description provided for @chooseFromList.
  ///
  /// In en, this message translates to:
  /// **'Choose from list'**
  String get chooseFromList;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name too short'**
  String get nameTooShort;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @uploadCertifications.
  ///
  /// In en, this message translates to:
  /// **'Upload Certifications'**
  String get uploadCertifications;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @idDocumentUploaded.
  ///
  /// In en, this message translates to:
  /// **'ID document uploaded'**
  String get idDocumentUploaded;

  /// No description provided for @uploadIdDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload ID document'**
  String get uploadIdDocument;

  /// No description provided for @idDocument.
  ///
  /// In en, this message translates to:
  /// **'ID Document'**
  String get idDocument;

  /// No description provided for @pleaseUploadIdDocument.
  ///
  /// In en, this message translates to:
  /// **'Please upload ID document'**
  String get pleaseUploadIdDocument;

  /// No description provided for @pleaseSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select location'**
  String get pleaseSelectLocation;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating Your Account'**
  String get creatingAccount;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @noJobCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No job categories available'**
  String get noJobCategoriesAvailable;

  /// No description provided for @availabilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Availability Status'**
  String get availabilityStatus;

  /// No description provided for @youAreNowOnline.
  ///
  /// In en, this message translates to:
  /// **'You are now online'**
  String get youAreNowOnline;

  /// No description provided for @leaveOffForInspectionOnly.
  ///
  /// In en, this message translates to:
  /// **' (Leave OFF for inspection only, or turn ON for repair details)'**
  String get leaveOffForInspectionOnly;

  /// No description provided for @youAreNowOffline.
  ///
  /// In en, this message translates to:
  /// **'You are now offline'**
  String get youAreNowOffline;

  /// No description provided for @youAreCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You are currently unavailable for requests'**
  String get youAreCurrentlyUnavailable;

  /// No description provided for @youAreAvailableForRequests.
  ///
  /// In en, this message translates to:
  /// **'You are available for requests'**
  String get youAreAvailableForRequests;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @enableFullServiceAndRepair.
  ///
  /// In en, this message translates to:
  /// **'Enable Full Service & Repair'**
  String get enableFullServiceAndRepair;

  /// No description provided for @phoneNumberAlreadyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone number already updated'**
  String get phoneNumberAlreadyUpdated;

  /// No description provided for @phoneNumberFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number must start with 05'**
  String get phoneNumberFormatHint;

  /// No description provided for @manageTransactions.
  ///
  /// In en, this message translates to:
  /// **'Manage Transactions'**
  String get manageTransactions;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get tooManyAttempts;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @pleaseSelectAllLocationFields.
  ///
  /// In en, this message translates to:
  /// **'Please select all location fields'**
  String get pleaseSelectAllLocationFields;

  /// No description provided for @bookingName.
  ///
  /// In en, this message translates to:
  /// **'Booking Name'**
  String get bookingName;

  /// No description provided for @technicianName.
  ///
  /// In en, this message translates to:
  /// **'Technician Name'**
  String get technicianName;

  /// No description provided for @changeIdDocument.
  ///
  /// In en, this message translates to:
  /// **'Change ID Document'**
  String get changeIdDocument;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not Assigned'**
  String get notAssigned;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @removeFile.
  ///
  /// In en, this message translates to:
  /// **'Remove File'**
  String get removeFile;

  /// No description provided for @removeFileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this file?'**
  String get removeFileConfirmation;

  /// No description provided for @errorSendingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error sending notifications'**
  String get errorSendingNotifications;

  /// No description provided for @fillInBothEnglishAndArabicMessageContent.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both English and Arabic message content'**
  String get fillInBothEnglishAndArabicMessageContent;

  /// No description provided for @notificationSenttoTechnicians.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {Notification sent to 1 technician.} other {Notification sent to {count} technicians.}}'**
  String notificationSenttoTechnicians(int count);

  /// No description provided for @notificationSenttoCustomers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {Notification sent to 1 customer.} other {Notification sent to {count} customers.}}'**
  String notificationSenttoCustomers(int count);

  /// No description provided for @locationTracking.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get locationTracking;

  /// No description provided for @trackingInactive.
  ///
  /// In en, this message translates to:
  /// **'Tracking Inactive'**
  String get trackingInactive;

  /// No description provided for @trackingActive.
  ///
  /// In en, this message translates to:
  /// **'Tracking Active'**
  String get trackingActive;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @locationTrackingStartedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location tracking started successfully'**
  String get locationTrackingStartedSuccessfully;

  /// No description provided for @locationTrackingHelpText.
  ///
  /// In en, this message translates to:
  /// **'Location tracking helps customers track your progress. Make sure to keep location services enabled.'**
  String get locationTrackingHelpText;

  /// No description provided for @batteryOptimizationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is enabled. This may affect background location tracking.'**
  String get batteryOptimizationEnabled;

  /// No description provided for @agentAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Technician assigned successfully'**
  String get agentAssignedSuccessfully;

  /// No description provided for @orderRejectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order rejected successfully'**
  String get orderRejectedSuccessfully;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @couldNotLaunchPhone.
  ///
  /// In en, this message translates to:
  /// **'Could not launch phone app'**
  String get couldNotLaunchPhone;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} minute ago} other {{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} day ago} other {{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} hour ago} other {{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @paymentCompletedAt.
  ///
  /// In en, this message translates to:
  /// **'Payment Completed At'**
  String get paymentCompletedAt;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @amountToBePaid.
  ///
  /// In en, this message translates to:
  /// **'Amount to be paid'**
  String get amountToBePaid;

  /// No description provided for @cannotRequestPayoutPendingRequest.
  ///
  /// In en, this message translates to:
  /// **'You already have a payout request in progress. Please wait until it is approved or rejected'**
  String get cannotRequestPayoutPendingRequest;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInformation;

  /// No description provided for @serviceInformation.
  ///
  /// In en, this message translates to:
  /// **'Service Information'**
  String get serviceInformation;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @introduction.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get introduction;

  /// No description provided for @policy1title.
  ///
  /// In en, this message translates to:
  /// **'Data We Collect'**
  String get policy1title;

  /// No description provided for @policy2title.
  ///
  /// In en, this message translates to:
  /// **'How We Use It'**
  String get policy2title;

  /// No description provided for @policy3title.
  ///
  /// In en, this message translates to:
  /// **'Data Sharing'**
  String get policy3title;

  /// No description provided for @terms1title.
  ///
  /// In en, this message translates to:
  /// **'Licenses and Qualifications'**
  String get terms1title;

  /// No description provided for @terms2title.
  ///
  /// In en, this message translates to:
  /// **'Service Quality and Responsibility'**
  String get terms2title;

  /// No description provided for @terms3title.
  ///
  /// In en, this message translates to:
  /// **'Fair Pricing'**
  String get terms3title;

  /// No description provided for @terms4title.
  ///
  /// In en, this message translates to:
  /// **'Platform Commission'**
  String get terms4title;

  /// No description provided for @terms5title.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get terms5title;

  /// No description provided for @terms6title.
  ///
  /// In en, this message translates to:
  /// **'Legal Liability Limits'**
  String get terms6title;

  /// No description provided for @searchByCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Search by customer name'**
  String get searchByCustomerName;

  /// No description provided for @phoneNumberUpdateInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number starting with \'05\' for updating phone number'**
  String get phoneNumberUpdateInfo;

  /// No description provided for @termsIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Your use of the Application constitutes full and unconditional acceptance of these terms. The Application acts solely as an electronic intermediary platform connecting you with service providers (Technicians).'**
  String get termsIntroduction;

  /// No description provided for @terms1.
  ///
  /// In en, this message translates to:
  /// **'You guarantee that you possess all necessary professional licenses and qualifications to provide the services advertised.'**
  String get terms1;

  /// No description provided for @terms2.
  ///
  /// In en, this message translates to:
  /// **'You are solely responsible for the quality of the service provided, the tools used, and ensuring the safety of the premises during and after the work.'**
  String get terms2;

  /// No description provided for @terms3.
  ///
  /// In en, this message translates to:
  /// **'You are committed to providing fair, reasonable, and upfront pricing to the User after inspection.'**
  String get terms3;

  /// No description provided for @terms4.
  ///
  /// In en, this message translates to:
  /// **'You are committed to paying the pre-agreed commission to the Application, which will be deducted from the value of the completed service.'**
  String get terms4;

  /// No description provided for @warrantyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Warranty Policy'**
  String get warrantyPolicy;

  /// No description provided for @terms6.
  ///
  /// In en, this message translates to:
  /// **'The Application is not responsible for any material damages or injuries resulting from your performance of the service.'**
  String get terms6;

  /// No description provided for @terms5.
  ///
  /// In en, this message translates to:
  /// **'You are obligated to provide a warranty on the work performed in accordance with the \"Warranty Policy,\" and you bear the cost of repairs falling within the warranty period.'**
  String get terms5;

  /// No description provided for @policy1.
  ///
  /// In en, this message translates to:
  /// **'Professional license information, qualifications and experience, personal/professional photos, bank account details for payment reception, and rating history.'**
  String get policy1;

  /// No description provided for @policy2.
  ///
  /// In en, this message translates to:
  /// **'Used to verify your identity and qualifications, process your payments, and display your professional profile to Users (ratings and experience).'**
  String get policy2;

  /// No description provided for @policy3.
  ///
  /// In en, this message translates to:
  /// **'Your name, professional photo, and ratings are shared with Users. Your bank account information is NOT shared.'**
  String get policy3;

  /// No description provided for @waitingForAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Waiting for admin action'**
  String get waitingForAdminAction;

  /// No description provided for @whatsCovered.
  ///
  /// In en, this message translates to:
  /// **'What\'s Covered'**
  String get whatsCovered;

  /// No description provided for @issueone.
  ///
  /// In en, this message translates to:
  /// **'Faulty installation or poor workmanship'**
  String get issueone;

  /// No description provided for @issuetwo.
  ///
  /// In en, this message translates to:
  /// **'Substandard performance by technician'**
  String get issuetwo;

  /// No description provided for @issuethree.
  ///
  /// In en, this message translates to:
  /// **'Same original fault that was repaired'**
  String get issuethree;

  /// No description provided for @issuefour.
  ///
  /// In en, this message translates to:
  /// **'Valid for one time, within 7 days from completion date'**
  String get issuefour;

  /// No description provided for @whatsNotCovered.
  ///
  /// In en, this message translates to:
  /// **'What\'s Not Covered'**
  String get whatsNotCovered;

  /// No description provided for @notissueone.
  ///
  /// In en, this message translates to:
  /// **'Defective spare parts or materials'**
  String get notissueone;

  /// No description provided for @notissuetwo.
  ///
  /// In en, this message translates to:
  /// **'Misuse or tampering after service'**
  String get notissuetwo;

  /// No description provided for @notissuethree.
  ///
  /// In en, this message translates to:
  /// **'Third-party interventions'**
  String get notissuethree;

  /// No description provided for @notissuefour.
  ///
  /// In en, this message translates to:
  /// **'Power surges, water leaks, natural disasters'**
  String get notissuefour;

  /// No description provided for @notissuefive.
  ///
  /// In en, this message translates to:
  /// **'Normal wear and tear'**
  String get notissuefive;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @walletSynced.
  ///
  /// In en, this message translates to:
  /// **'Wallet synced successfully'**
  String get walletSynced;

  /// No description provided for @payoutRequested.
  ///
  /// In en, this message translates to:
  /// **'Payout requested successfully'**
  String get payoutRequested;

  /// No description provided for @balanceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Balance Breakdown'**
  String get balanceBreakdown;

  /// No description provided for @selectAmounts.
  ///
  /// In en, this message translates to:
  /// **'Select Amounts'**
  String get selectAmounts;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @payoutPending.
  ///
  /// In en, this message translates to:
  /// **'Payout Pending'**
  String get payoutPending;

  /// No description provided for @requestedAmount.
  ///
  /// In en, this message translates to:
  /// **'Requested Amount'**
  String get requestedAmount;

  /// No description provided for @payoutNote.
  ///
  /// In en, this message translates to:
  /// **'Note: This request will be sent to admin for approval. The full available balance will be requested.'**
  String get payoutNote;

  /// No description provided for @noPayoutRequests.
  ///
  /// In en, this message translates to:
  /// **'No payout requests yet'**
  String get noPayoutRequests;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @useMax.
  ///
  /// In en, this message translates to:
  /// **'Use Max'**
  String get useMax;

  /// No description provided for @searchByWorkerName.
  ///
  /// In en, this message translates to:
  /// **'Search by worker name'**
  String get searchByWorkerName;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @payoutDetails.
  ///
  /// In en, this message translates to:
  /// **'Payout Details'**
  String get payoutDetails;

  /// No description provided for @workerName.
  ///
  /// In en, this message translates to:
  /// **'Worker Name'**
  String get workerName;

  /// No description provided for @payoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Payout Account'**
  String get payoutAccount;

  /// No description provided for @requestDate.
  ///
  /// In en, this message translates to:
  /// **'Request Date'**
  String get requestDate;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @enterTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Enter Transaction ID'**
  String get enterTransactionId;

  /// No description provided for @uploadPaymentProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Proof'**
  String get uploadPaymentProof;

  /// No description provided for @paymentProof.
  ///
  /// In en, this message translates to:
  /// **'Payment Proof'**
  String get paymentProof;

  /// No description provided for @proofUploaded.
  ///
  /// In en, this message translates to:
  /// **'Proof uploaded successfully'**
  String get proofUploaded;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason'**
  String get enterReason;

  /// No description provided for @cancelPayoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this payout request?'**
  String get cancelPayoutConfirmation;

  /// No description provided for @payoutCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payout request cancelled successfully'**
  String get payoutCancelled;

  /// No description provided for @confirmPayoutRequest.
  ///
  /// In en, this message translates to:
  /// **'You are requesting a payout for your total available balance'**
  String get confirmPayoutRequest;

  /// No description provided for @bonusIncludedInWallet.
  ///
  /// In en, this message translates to:
  /// **'Bonus is included in your unified wallet. Request payout from Earnings page.'**
  String get bonusIncludedInWallet;

  /// No description provided for @claimText.
  ///
  /// In en, this message translates to:
  /// **'To claim warranty, submit a request through the app within 7 days from service completion. The warranty can be claimed only once.'**
  String get claimText;

  /// No description provided for @syncWallet.
  ///
  /// In en, this message translates to:
  /// **'Sync Wallet'**
  String get syncWallet;

  /// No description provided for @alreadyInHand.
  ///
  /// In en, this message translates to:
  /// **'already in hand'**
  String get alreadyInHand;

  /// No description provided for @minimumPayoutAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum payout amount is 10 SAR'**
  String get minimumPayoutAmount;

  /// No description provided for @enableAvailability.
  ///
  /// In en, this message translates to:
  /// **'Enable Availability'**
  String get enableAvailability;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'We are happy to have you join the Abo Glumbo team.\n\nâ€¢ One-week warranty for every service\nâ€¢ Higher ratings increase future selection chances\nâ€¢ Special rewards for high-performing technicians'**
  String get welcomeDescription;

  /// No description provided for @welcomeToAboGlumboTechnician.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}'**
  String welcomeToAboGlumboTechnician(String name);

  /// No description provided for @onlyMainAdminCanManageAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Only the main admin can manage admin access'**
  String get onlyMainAdminCanManageAdminAccess;

  /// No description provided for @cannotModifyMainAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Cannot modify main admin account'**
  String get cannotModifyMainAdminAccount;

  /// No description provided for @adminAccessRevokedFor.
  ///
  /// In en, this message translates to:
  /// **'Admin access revoked for'**
  String get adminAccessRevokedFor;

  /// No description provided for @adminAccess.
  ///
  /// In en, this message translates to:
  /// **'Admin Access'**
  String get adminAccess;

  /// No description provided for @selectAdminAccessLevelFor.
  ///
  /// In en, this message translates to:
  /// **'Select admin access level for'**
  String get selectAdminAccessLevelFor;

  /// No description provided for @fullAdmin.
  ///
  /// In en, this message translates to:
  /// **'Full Admin'**
  String get fullAdmin;

  /// No description provided for @customerService.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get customerService;

  /// No description provided for @grantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant Access'**
  String get grantAccess;

  /// No description provided for @grantingAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Granting admin access'**
  String get grantingAdminAccess;

  /// No description provided for @adminAccessGrantedTo.
  ///
  /// In en, this message translates to:
  /// **'Admin access granted to'**
  String get adminAccessGrantedTo;

  /// No description provided for @revokeAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke Admin Access'**
  String get revokeAdminAccess;

  /// No description provided for @revokingAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoking admin access'**
  String get revokingAdminAccess;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @switchToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Switch to Admin'**
  String get switchToAdmin;

  /// No description provided for @manageAdmins.
  ///
  /// In en, this message translates to:
  /// **'Manage Admins'**
  String get manageAdmins;

  /// No description provided for @searchAdmins.
  ///
  /// In en, this message translates to:
  /// **'Search admins...'**
  String get searchAdmins;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @noAdminsFound.
  ///
  /// In en, this message translates to:
  /// **'No Admins Found'**
  String get noAdminsFound;

  /// No description provided for @loadingAdmins.
  ///
  /// In en, this message translates to:
  /// **'Loading Admins...'**
  String get loadingAdmins;

  /// No description provided for @noAdminsMatchYourFilters.
  ///
  /// In en, this message translates to:
  /// **'No Admins Match Your Filters'**
  String get noAdminsMatchYourFilters;

  /// No description provided for @grantedOn.
  ///
  /// In en, this message translates to:
  /// **'Granted On'**
  String get grantedOn;

  /// No description provided for @selectRecipientType.
  ///
  /// In en, this message translates to:
  /// **'Select Recipient Type'**
  String get selectRecipientType;

  /// No description provided for @recipientsSelected.
  ///
  /// In en, this message translates to:
  /// **'Recipients Selected'**
  String get recipientsSelected;

  /// No description provided for @areYouSureYouWantToRevokeAdminAccessFor.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to revoke admin access for'**
  String get areYouSureYouWantToRevokeAdminAccessFor;

  /// No description provided for @onlyTheMainAdminCanRevokeAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Only the main admin can revoke admin access'**
  String get onlyTheMainAdminCanRevokeAdminAccess;

  /// No description provided for @accessToAllAdminFeaturesExceptManagingOtherAdmins.
  ///
  /// In en, this message translates to:
  /// **'Access to all admin features except managing other admins'**
  String get accessToAllAdminFeaturesExceptManagingOtherAdmins;

  /// No description provided for @viewOnlyAccessToCustomersTechniciansAndSupport.
  ///
  /// In en, this message translates to:
  /// **'View only access to customers, technicians and support'**
  String get viewOnlyAccessToCustomersTechniciansAndSupport;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'Ready to work? Nearby jobs and better income await you.'**
  String get loginDescription;

  /// No description provided for @aboutUsTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUsTitle;

  /// No description provided for @aboutUsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your Journey to Professional Growth Starts Here'**
  String get aboutUsHeadline;

  /// No description provided for @aboutUsIntro.
  ///
  /// In en, this message translates to:
  /// **'Join our network of certified technicians and take your next step towards financial independence and professional excellence. We don\'t just offer you a job; we offer you a partner dedicated to ensuring your success.'**
  String get aboutUsIntro;

  /// No description provided for @aboutRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Rewards & Incentives'**
  String get aboutRewardsTitle;

  /// No description provided for @aboutIncentiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Incentive System'**
  String get aboutIncentiveTitle;

  /// No description provided for @aboutIncentiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Climb through our tiered system (Bronze, Silver, Gold, Platinum). The more jobs you complete and the higher your rating you maintain (4.8+ for Platinum), the higher the bonus percentage you earn (up to 15% bonus).'**
  String get aboutIncentiveDesc;

  /// No description provided for @aboutEarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transparent Monthly Earnings'**
  String get aboutEarningsTitle;

  /// No description provided for @aboutEarningsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your earned monthly income and easily request your payout using the \"Request Payout\" button.'**
  String get aboutEarningsDesc;

  /// No description provided for @aboutSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Efficiency & Support'**
  String get aboutSupportTitle;

  /// No description provided for @aboutFlexibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Flexibility'**
  String get aboutFlexibilityTitle;

  /// No description provided for @aboutFlexibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'You set your own working hours and the areas you cover. We work to provide you with service requests based on your preferences.'**
  String get aboutFlexibilityDesc;

  /// No description provided for @aboutNoHuntingTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero Customer Hunting'**
  String get aboutNoHuntingTitle;

  /// No description provided for @aboutNoHuntingDesc.
  ///
  /// In en, this message translates to:
  /// **'Say goodbye to chasing clients. We provide you with ready job requests from reliable customers, ensuring a continuous flow of work.'**
  String get aboutNoHuntingDesc;

  /// No description provided for @aboutTransparencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Transparency'**
  String get aboutTransparencyTitle;

  /// No description provided for @aboutTransparencyDesc.
  ///
  /// In en, this message translates to:
  /// **'All service details and pricing are documented in advance, ensuring clarity in all financial dealings between you and the customer.'**
  String get aboutTransparencyDesc;

  /// No description provided for @locationNumber.
  ///
  /// In en, this message translates to:
  /// **'Location {number}'**
  String locationNumber(int number);

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// No description provided for @mapPickerInstructions.
  ///
  /// In en, this message translates to:
  /// **'â€¢ Click \'Add Region\' to start drawing a new area\nâ€¢ Tap on the map to add boundary points (at least 4 points required)\nâ€¢ Click \'Complete Region\' when finished\nâ€¢ Enter location details and confirm\nâ€¢ Use the Edit icon to update details or the Red X to remove an area'**
  String get mapPickerInstructions;

  /// No description provided for @tapOnMapToDrawPolygonPoints.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to draw polygon points'**
  String get tapOnMapToDrawPolygonPoints;

  /// No description provided for @addRegion.
  ///
  /// In en, this message translates to:
  /// **'Add Region'**
  String get addRegion;

  /// No description provided for @regionMustHaveAtLeast4Points.
  ///
  /// In en, this message translates to:
  /// **'A region must have at least 4 points to be completed.'**
  String get regionMustHaveAtLeast4Points;

  /// No description provided for @completeRegionWithPts.
  ///
  /// In en, this message translates to:
  /// **'Complete Region ({count} pts)'**
  String completeRegionWithPts(int count);

  /// No description provided for @clearDrawing.
  ///
  /// In en, this message translates to:
  /// **'Clear Drawing'**
  String get clearDrawing;

  /// No description provided for @pleaseDrawPolygonFirst.
  ///
  /// In en, this message translates to:
  /// **'Please draw a polygon first'**
  String get pleaseDrawPolygonFirst;

  /// No description provided for @pleaseDrawPolygonAreaFirst.
  ///
  /// In en, this message translates to:
  /// **'Please draw a polygon area on the map first'**
  String get pleaseDrawPolygonAreaFirst;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @enterPriority.
  ///
  /// In en, this message translates to:
  /// **'Enter priority'**
  String get enterPriority;

  /// No description provided for @pleaseEnterPriority.
  ///
  /// In en, this message translates to:
  /// **'Please enter priority'**
  String get pleaseEnterPriority;

  /// No description provided for @pointsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 point} other{{count} points}}'**
  String pointsCount(int count);

  /// No description provided for @locationsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} location selected} other {{count} locations selected}}'**
  String locationsSelectedCount(int count);

  /// No description provided for @addCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Current Location'**
  String get addCurrentLocation;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// No description provided for @searchForAPlace.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get searchForAPlace;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @noLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'No Location Selected'**
  String get noLocationSelected;

  /// No description provided for @tapOnMapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap on map to select'**
  String get tapOnMapToSelect;

  /// No description provided for @confirmLocations.
  ///
  /// In en, this message translates to:
  /// **'Confirm Locations'**
  String get confirmLocations;

  /// No description provided for @radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radius;

  /// No description provided for @locationAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Location already added'**
  String get locationAlreadyAdded;

  /// No description provided for @locationAddedToList.
  ///
  /// In en, this message translates to:
  /// **'Location added to list'**
  String get locationAddedToList;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get locationNotFound;

  /// No description provided for @errorFindingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error finding location'**
  String get errorFindingLocation;

  /// No description provided for @editLocation.
  ///
  /// In en, this message translates to:
  /// **'Edit Location'**
  String get editLocation;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get addLocation;

  /// No description provided for @englishName.
  ///
  /// In en, this message translates to:
  /// **'English Name'**
  String get englishName;

  /// No description provided for @pleaseEnterEnglishName.
  ///
  /// In en, this message translates to:
  /// **'Please enter English name'**
  String get pleaseEnterEnglishName;

  /// No description provided for @arabicName.
  ///
  /// In en, this message translates to:
  /// **'Arabic Name'**
  String get arabicName;

  /// No description provided for @pleaseEnterArabicName.
  ///
  /// In en, this message translates to:
  /// **'Please enter Arabic name'**
  String get pleaseEnterArabicName;

  /// No description provided for @pleaseEnterArabicNameOnly.
  ///
  /// In en, this message translates to:
  /// **'Please enter Arabic name only'**
  String get pleaseEnterArabicNameOnly;

  /// No description provided for @radiusInMeters.
  ///
  /// In en, this message translates to:
  /// **'Radius in meters'**
  String get radiusInMeters;

  /// No description provided for @enterRadiusInMeters.
  ///
  /// In en, this message translates to:
  /// **'Enter radius in meters'**
  String get enterRadiusInMeters;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get meters;

  /// No description provided for @pleaseEnterRadius.
  ///
  /// In en, this message translates to:
  /// **'Please enter radius'**
  String get pleaseEnterRadius;

  /// No description provided for @addArea.
  ///
  /// In en, this message translates to:
  /// **'Add Area'**
  String get addArea;

  /// No description provided for @gettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Getting address...'**
  String get gettingAddress;

  /// No description provided for @serviceRadius.
  ///
  /// In en, this message translates to:
  /// **'Service Radius'**
  String get serviceRadius;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @tapOnMapOrSearchToAddLocations.
  ///
  /// In en, this message translates to:
  /// **'Tap on map or search to add locations'**
  String get tapOnMapOrSearchToAddLocations;

  /// No description provided for @selectedLocations.
  ///
  /// In en, this message translates to:
  /// **'Selected Locations'**
  String get selectedLocations;

  /// No description provided for @profileSentForVerification.
  ///
  /// In en, this message translates to:
  /// **'Your Profile has been sent for Verification!'**
  String get profileSentForVerification;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// No description provided for @waitingForTechnicianVerification.
  ///
  /// In en, this message translates to:
  /// **'Waiting for technician to verify payment'**
  String get waitingForTechnicianVerification;

  /// No description provided for @verifyPayment.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment'**
  String get verifyPayment;

  /// No description provided for @confirmPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment Receipt'**
  String get confirmPaymentReceipt;

  /// No description provided for @uploadTechnicianPaymentProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Technician Payment Proof'**
  String get uploadTechnicianPaymentProof;

  /// No description provided for @paymentVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment verified successfully'**
  String get paymentVerifiedSuccessfully;

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFiles;

  /// No description provided for @pleaseSelectAtLeastOneFile.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one file'**
  String get pleaseSelectAtLeastOneFile;

  /// No description provided for @errorUploading.
  ///
  /// In en, this message translates to:
  /// **'Error uploading'**
  String get errorUploading;

  /// No description provided for @warranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get warranty;

  /// No description provided for @warrantyAppliedOn.
  ///
  /// In en, this message translates to:
  /// **'Warranty applied on'**
  String get warrantyAppliedOn;

  /// No description provided for @bookingIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Booking ID Copied'**
  String get bookingIdCopied;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @submitCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Submit a New Offer'**
  String get submitCounterOffer;

  /// No description provided for @pleaseSelectALaterTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a time later than the current booking time'**
  String get pleaseSelectALaterTime;

  /// No description provided for @listeningForSms.
  ///
  /// In en, this message translates to:
  /// **'Listening for SMS...'**
  String get listeningForSms;

  /// No description provided for @earningsInfoOnly.
  ///
  /// In en, this message translates to:
  /// **'For informational purposes only'**
  String get earningsInfoOnly;

  /// No description provided for @throughApp.
  ///
  /// In en, this message translates to:
  /// **'Through App'**
  String get throughApp;

  /// No description provided for @rebookTechnician.
  ///
  /// In en, this message translates to:
  /// **'Rebooking'**
  String get rebookTechnician;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectService;

  /// No description provided for @rejectionProfessionalMessage.
  ///
  /// In en, this message translates to:
  /// **'If you are unavailable at the requested time, please propose an alternative date and time to the customer instead of canceling the appointment.'**
  String get rejectionProfessionalMessage;

  /// No description provided for @proposeAlternativeTime.
  ///
  /// In en, this message translates to:
  /// **'Propose New Time'**
  String get proposeAlternativeTime;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get appointmentDetails;

  /// No description provided for @residenceIDImage.
  ///
  /// In en, this message translates to:
  /// **'Residence ID Image'**
  String get residenceIDImage;

  /// No description provided for @sponsorWorkPermit.
  ///
  /// In en, this message translates to:
  /// **'Sponsor Work Permit'**
  String get sponsorWorkPermit;

  /// No description provided for @chamberOfCommerceApproval.
  ///
  /// In en, this message translates to:
  /// **'Chamber of Commerce Approval'**
  String get chamberOfCommerceApproval;

  /// No description provided for @certificatesOrTrainingCoursesOptional.
  ///
  /// In en, this message translates to:
  /// **'Certificates or Training Courses (Optional)'**
  String get certificatesOrTrainingCoursesOptional;

  /// No description provided for @uploadCertificates.
  ///
  /// In en, this message translates to:
  /// **'Upload Certificates'**
  String get uploadCertificates;

  /// No description provided for @refreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh Location'**
  String get refreshLocation;

  /// No description provided for @selectJobRolesDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the services you are qualified to provide.'**
  String get selectJobRolesDescription;

  /// No description provided for @updateDocuments.
  ///
  /// In en, this message translates to:
  /// **'Update Documents'**
  String get updateDocuments;

  /// No description provided for @pleaseSelectAtLeastOneDocumentToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Please remove and select new file for atleast one of the documents to re-upload'**
  String get pleaseSelectAtLeastOneDocumentToUpdate;

  /// No description provided for @reuploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Re-upload failed: {error}'**
  String reuploadFailed(String error);

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @accountBlocked.
  ///
  /// In en, this message translates to:
  /// **'Account Blocked'**
  String get accountBlocked;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been blocked by the admin. Please contact support for more information.'**
  String get accountBlockedMessage;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application Rejected'**
  String get applicationRejected;

  /// No description provided for @applicationRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your application has been rejected after review. You can see the reason below and update your documents to try again.'**
  String get applicationRejectedMessage;

  /// No description provided for @reasonForRejection.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection:'**
  String get reasonForRejection;

  /// No description provided for @noReasonProvided.
  ///
  /// In en, this message translates to:
  /// **'No reason provided'**
  String get noReasonProvided;

  /// No description provided for @failedResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP. Please try again.'**
  String get failedResendOtp;

  /// No description provided for @verificationIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Verification ID not found. Please try again.'**
  String get verificationIdNotFound;

  /// No description provided for @pleaseFetchLocation.
  ///
  /// In en, this message translates to:
  /// **'Please fetch your current location'**
  String get pleaseFetchLocation;

  /// No description provided for @pleaseSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one job role'**
  String get pleaseSelectRole;

  /// No description provided for @pleaseUploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please upload all mandatory documents'**
  String get pleaseUploadDocuments;

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke Access'**
  String get revokeAccess;

  /// No description provided for @coreAdminCannotRemove.
  ///
  /// In en, this message translates to:
  /// **'Core admin cannot be removed.'**
  String get coreAdminCannotRemove;

  /// No description provided for @onlyCoreAdminCanAdd.
  ///
  /// In en, this message translates to:
  /// **'Only the core admin can add new admins.'**
  String get onlyCoreAdminCanAdd;

  /// No description provided for @adminAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Admin added successfully to pending invites.'**
  String get adminAddedSuccessfully;

  /// No description provided for @failedUpdateTechStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update technician status'**
  String get failedUpdateTechStatus;

  /// No description provided for @offerAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted successfully'**
  String get offerAcceptedSuccessfully;

  /// No description provided for @failedToSendCounter.
  ///
  /// In en, this message translates to:
  /// **'Failed to send counter offer'**
  String get failedToSendCounter;

  /// No description provided for @couldNotLaunchEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not launch email client'**
  String get couldNotLaunchEmail;

  /// No description provided for @couldNotLaunchWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not launch WhatsApp'**
  String get couldNotLaunchWhatsapp;

  /// No description provided for @cancelLower.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLower;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'INVITED'**
  String get invited;

  /// No description provided for @accessLevelUpper.
  ///
  /// In en, this message translates to:
  /// **'ACCESS LEVEL'**
  String get accessLevelUpper;

  /// No description provided for @phoneUpper.
  ///
  /// In en, this message translates to:
  /// **'PHONE'**
  String get phoneUpper;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Booking Invoice'**
  String get invoiceTitle;

  /// No description provided for @invoiceWord.
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get invoiceWord;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Status: PAID'**
  String get statusPaid;

  /// No description provided for @billTo.
  ///
  /// In en, this message translates to:
  /// **'BILL TO:'**
  String get billTo;

  /// No description provided for @bookingDetailsInvoice.
  ///
  /// In en, this message translates to:
  /// **'BOOKING DETAILS:'**
  String get bookingDetailsInvoice;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal:'**
  String get subtotal;

  /// No description provided for @inspectionFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Inspection Fee:'**
  String get inspectionFeeLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get totalLabel;

  /// No description provided for @thankYouInvoice.
  ///
  /// In en, this message translates to:
  /// **'Thank you for choosing Abo Glumbo!'**
  String get thankYouInvoice;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #: {number}'**
  String invoiceNumber(String number);

  /// No description provided for @dateString.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateString(String date);

  /// No description provided for @serviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service: {name}'**
  String serviceLabel(String name);

  /// No description provided for @completedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed At: {date}'**
  String completedAtLabel(String date);

  /// No description provided for @paymentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode: {mode}'**
  String paymentModeLabel(String mode);

  /// No description provided for @transactionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID: {id}'**
  String transactionIdLabel(String id);

  /// No description provided for @warrantyLabel.
  ///
  /// In en, this message translates to:
  /// **'Warranty: {duration}'**
  String warrantyLabel(String duration);

  /// No description provided for @sarAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} SAR'**
  String sarAmount(String amount);

  /// No description provided for @onHour.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get onHour;

  /// No description provided for @offHour.
  ///
  /// In en, this message translates to:
  /// **'Outside Working Hours'**
  String get offHour;

  /// No description provided for @inAppEarnings.
  ///
  /// In en, this message translates to:
  /// **'In-App Earnings'**
  String get inAppEarnings;

  /// No description provided for @outsideAppEarnings.
  ///
  /// In en, this message translates to:
  /// **'Outside-App Earnings'**
  String get outsideAppEarnings;

  /// No description provided for @earningsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Earnings Period'**
  String get earningsPeriod;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @customDateRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range'**
  String get customDateRange;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @inApp.
  ///
  /// In en, this message translates to:
  /// **'In-App'**
  String get inApp;

  /// No description provided for @clearWalletBalances.
  ///
  /// In en, this message translates to:
  /// **'Clear Wallet Balances'**
  String get clearWalletBalances;

  /// No description provided for @clearWalletConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to completely clear and reset the wallet balances for {name}? This action is irreversible.'**
  String clearWalletConfirmation(String name);

  /// No description provided for @errorClearingWallet.
  ///
  /// In en, this message translates to:
  /// **'Error clearing wallet: {error}'**
  String errorClearingWallet(String error);

  /// No description provided for @bookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking Date'**
  String get bookingDate;

  /// No description provided for @yourAccountIsBeingVerified.
  ///
  /// In en, this message translates to:
  /// **'Your account is being verified by the admin. Please check back later.'**
  String get yourAccountIsBeingVerified;

  /// No description provided for @aboGlumboWorker.
  ///
  /// In en, this message translates to:
  /// **'Abo Glumbo Technician'**
  String get aboGlumboWorker;

  /// No description provided for @workerCannotBeAssignedMultipleTimes.
  ///
  /// In en, this message translates to:
  /// **'The same technician cannot be assigned to more than one booking at the same time. Please choose a different time or another technician.'**
  String get workerCannotBeAssignedMultipleTimes;

  /// No description provided for @unknownWorker.
  ///
  /// In en, this message translates to:
  /// **'Unknown Technician'**
  String get unknownWorker;

  /// No description provided for @workerCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking was cancelled by the technician'**
  String get workerCancelled;

  /// No description provided for @cancelledByWorker.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by Technician'**
  String get cancelledByWorker;

  /// No description provided for @workerPreviouslyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Technician previously cancelled'**
  String get workerPreviouslyCancelled;

  /// No description provided for @workerCancelledAtTime.
  ///
  /// In en, this message translates to:
  /// **'This technician previously cancelled a booking at the same time. It is recommended to assign another technician for better reliability.'**
  String get workerCancelledAtTime;

  /// No description provided for @workerRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician Restricted'**
  String get workerRestrictedTitle;

  /// No description provided for @cannotAssignCancelledWorker.
  ///
  /// In en, this message translates to:
  /// **'Cannot assign a technician who previously cancelled'**
  String get cannotAssignCancelledWorker;

  /// No description provided for @workerCancelledRestrictionMessage.
  ///
  /// In en, this message translates to:
  /// **'This technician previously cancelled a booking and is now restricted from new assignments. Please choose a different technician.'**
  String get workerCancelledRestrictionMessage;

  /// No description provided for @managefaqs.
  ///
  /// In en, this message translates to:
  /// **'Manage FAQs'**
  String get managefaqs;

  /// No description provided for @manageWorkers.
  ///
  /// In en, this message translates to:
  /// **'Manage Technicians'**
  String get manageWorkers;

  /// No description provided for @noWorkersMatchYourFilters.
  ///
  /// In en, this message translates to:
  /// **'No technicians match your search criteria'**
  String get noWorkersMatchYourFilters;

  /// No description provided for @workerInformation.
  ///
  /// In en, this message translates to:
  /// **'Technician Information'**
  String get workerInformation;

  /// No description provided for @loadingWorkers.
  ///
  /// In en, this message translates to:
  /// **'Loading Technicians...'**
  String get loadingWorkers;

  /// No description provided for @serviceDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service deleted successfully'**
  String get serviceDeletedSuccessfully;

  /// No description provided for @netTechnicianror.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading technicians'**
  String get netTechnicianror;

  /// No description provided for @urdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get urdu;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurred(String error);

  /// No description provided for @cannotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot open file: {path}'**
  String cannotOpenFile(String path);

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: {error}'**
  String failedToSendMessage(String error);

  /// No description provided for @failedToRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to retry message: {error}'**
  String failedToRetryMessage(String error);

  /// No description provided for @errorFetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error fetching location: {error}'**
  String errorFetchingLocation(String error);

  /// No description provided for @confirmRemoveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove admin access for {name}?'**
  String confirmRemoveAdmin(String name);

  /// No description provided for @adminAccessRevoked.
  ///
  /// In en, this message translates to:
  /// **'Admin access revoked for {name}'**
  String adminAccessRevoked(String name);

  /// No description provided for @inviteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Invite deleted for {name}'**
  String inviteDeleted(String name);

  /// No description provided for @biometricError.
  ///
  /// In en, this message translates to:
  /// **'âŒ Biometric error'**
  String get biometricError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @errorDuringLogin.
  ///
  /// In en, this message translates to:
  /// **'Error during login'**
  String get errorDuringLogin;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @coreAdmin.
  ///
  /// In en, this message translates to:
  /// **'Core Admin'**
  String get coreAdmin;

  /// No description provided for @addAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add Admin'**
  String get addAdmin;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @addNewAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add New Admin'**
  String get addNewAdmin;

  /// No description provided for @editAdmin.
  ///
  /// In en, this message translates to:
  /// **'Edit Admin'**
  String get editAdmin;

  /// No description provided for @enterAdminDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter admin details to invite them to the platform.'**
  String get enterAdminDetails;

  /// No description provided for @editAdminDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit admin details and access level.'**
  String get editAdminDetails;

  /// No description provided for @adminUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Admin updated successfully.'**
  String get adminUpdatedSuccessfully;

  /// No description provided for @adminPhoneExists.
  ///
  /// In en, this message translates to:
  /// **'Admin with this phone number already exists.'**
  String get adminPhoneExists;

  /// No description provided for @adminPhoneInvited.
  ///
  /// In en, this message translates to:
  /// **'Admin with this phone number is already invited.'**
  String get adminPhoneInvited;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get pleaseEnterName;

  /// No description provided for @enterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get enterEmailAddress;

  /// No description provided for @egPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'e.g. +9665XXXXXXXX'**
  String get egPhoneNumber;

  /// No description provided for @accessLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Level'**
  String get accessLevelTitle;

  /// No description provided for @customerServiceOnly.
  ///
  /// In en, this message translates to:
  /// **'Customer Service Only'**
  String get customerServiceOnly;

  /// No description provided for @customerServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'View only access to bookings and manage sections.'**
  String get customerServiceDesc;

  /// No description provided for @fullAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Full Admin Access'**
  String get fullAdminAccess;

  /// No description provided for @fullAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Full access except management of other admins.'**
  String get fullAdminDesc;

  /// No description provided for @phoneNoteWithCountryCode.
  ///
  /// In en, this message translates to:
  /// **'(enter phone number along with country code example : +966)'**
  String get phoneNoteWithCountryCode;

  /// No description provided for @selectNewDateAppointment.
  ///
  /// In en, this message translates to:
  /// **'Select a new date and time for the appointment'**
  String get selectNewDateAppointment;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @noAdditionalDescription.
  ///
  /// In en, this message translates to:
  /// **'No additional description'**
  String get noAdditionalDescription;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get discountAmount;

  /// No description provided for @discountAppliesToInspectionFeeOnly.
  ///
  /// In en, this message translates to:
  /// **'Discount applies to the inspection fee only.'**
  String get discountAppliesToInspectionFeeOnly;

  /// No description provided for @discountApplied.
  ///
  /// In en, this message translates to:
  /// **'{percentageamount}% discount'**
  String discountApplied(num percentageamount);

  /// No description provided for @escalated.
  ///
  /// In en, this message translates to:
  /// **'Pending Admin Review'**
  String get escalated;

  /// No description provided for @resolveIssue.
  ///
  /// In en, this message translates to:
  /// **'Resolve Issue'**
  String get resolveIssue;

  /// No description provided for @whatWasDoneToResolve.
  ///
  /// In en, this message translates to:
  /// **'What was done to resolve the issue?'**
  String get whatWasDoneToResolve;

  /// No description provided for @resolutionTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Resolution text is required'**
  String get resolutionTextRequired;

  /// No description provided for @urduName.
  ///
  /// In en, this message translates to:
  /// **'Urdu Name'**
  String get urduName;

  /// No description provided for @enterUrduName.
  ///
  /// In en, this message translates to:
  /// **'Enter Urdu name'**
  String get enterUrduName;

  /// No description provided for @pleaseEnterUrduName.
  ///
  /// In en, this message translates to:
  /// **'Please enter Urdu name'**
  String get pleaseEnterUrduName;

  /// No description provided for @pleaseEnterUrduNameOnly.
  ///
  /// In en, this message translates to:
  /// **'Please enter Urdu name only'**
  String get pleaseEnterUrduNameOnly;

  /// No description provided for @searchForZones.
  ///
  /// In en, this message translates to:
  /// **'Search for zones'**
  String get searchForZones;

  /// No description provided for @failedToSearchForZones.
  ///
  /// In en, this message translates to:
  /// **'Failed to search for zones. Please try again.'**
  String get failedToSearchForZones;

  /// No description provided for @zoneNameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Zone name already exists'**
  String get zoneNameAlreadyExists;

  /// No description provided for @zoneType.
  ///
  /// In en, this message translates to:
  /// **'Zone Type'**
  String get zoneType;

  /// No description provided for @waitingTechnicianToVerifyDocuments.
  ///
  /// In en, this message translates to:
  /// **'Waiting technician to verify documents'**
  String get waitingTechnicianToVerifyDocuments;

  /// No description provided for @workerCancelledThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Worker cancelled this booking'**
  String get workerCancelledThisBooking;

  /// No description provided for @workerCancelledNearby.
  ///
  /// In en, this message translates to:
  /// **'Worker cancelled nearby'**
  String get workerCancelledNearby;

  /// No description provided for @busyAtThisTime.
  ///
  /// In en, this message translates to:
  /// **'Busy at this time'**
  String get busyAtThisTime;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
