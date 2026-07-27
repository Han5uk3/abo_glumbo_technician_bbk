// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get assign => 'Assign';

  @override
  String get later => 'Later';

  @override
  String get change => 'Change';

  @override
  String get viewOnly => 'Admin View Only';

  @override
  String get noTechnicianAssigned => 'No Technician Assigned';

  @override
  String get calculatingDistance => 'Calculating distance...';

  @override
  String get awaitingCustomerAction => 'Awaiting Customer Action';

  @override
  String kmAway(Object distance) {
    return '$distance km away';
  }

  @override
  String get appName => 'Abo Glumbo';

  @override
  String get enterYourFullName => 'Enter Your Full Name';

  @override
  String get pleaseEnterYourFullName => 'Please Enter Your Full Name';

  @override
  String get onlineStatusOn => 'You are now Online';

  @override
  String get fullNameIsRequired => 'Full Name is required';

  @override
  String get enterYourEmail => 'Enter Your Email';

  @override
  String get onlineStatusOff => 'You are now Offline';

  @override
  String get errorUpdatingStatus => 'Error updating status';

  @override
  String get appLoginCaption =>
      'Your go-to app for finding qualified professionals.';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get continueText => 'Continue';

  @override
  String get byContinuingYouAgreeToOur => 'By Continuing you agree to our';

  @override
  String get termsOfUseAndPrivacyPolicy => ' Terms of use & privacy policy';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get login => 'Login';

  @override
  String get monthlyRevenue => 'Monthly Revenue';

  @override
  String get admins => 'Admins';

  @override
  String get banners => 'Banners';

  @override
  String get customers => 'Customers';

  @override
  String get technicians => 'Technicians';

  @override
  String get payouts => 'Payouts';

  @override
  String get faqs => 'FAQs';

  @override
  String get totalPayoutAmount => 'Total Payout Amount';

  @override
  String get reviewPayoutDetails => 'Review Payout Details';

  @override
  String get manageOrders => 'Manage Orders';

  @override
  String get refreshStatus => 'Refresh Status';

  @override
  String get signOut => 'Sign Out';

  @override
  String get rejectOrder => 'Reject Order';

  @override
  String get areYouSureYouWantToRejectThisOrder =>
      'Are you sure you want to reject this order?';

  @override
  String get loadingAgents => 'Loading Technicians...';

  @override
  String get bonusCardDesc =>
      'Earned Bonus will be included in your wallet for Payout.';

  @override
  String get noReview => 'No Review';

  @override
  String get areYouSureYouWantToAcceptThisNewTime =>
      'Are you sure you want to accept this new time?';

  @override
  String get reject => 'Reject';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String get tip => 'Tip';

  @override
  String get availableToWork => 'Available To Work';

  @override
  String get notAvailableToWork => 'Not Available To Work';

  @override
  String get choose => 'Choose';

  @override
  String get availableLocations => 'Available Locations';

  @override
  String get workHoursPricing => 'Work Hours Pricing';

  @override
  String get workStartTime => 'Work Start Time';

  @override
  String get workEndTime => 'Work End Time';

  @override
  String get onWorkPrice => 'On-Work Price';

  @override
  String get offWorkPrice => 'Off-Work Price';

  @override
  String get generalPrice => 'General Price (Fallback)';

  @override
  String get chooseLocations => 'Choose Locations';

  @override
  String get pleaseEnterAnOnWorkPrice => 'Please enter an on-work price';

  @override
  String get pleaseEnterOffWorkPrice => 'Please enter off-work price';

  @override
  String get pleaseEnterAGeneralPrice => 'Please enter a general price';

  @override
  String get grantAdminAccess => 'Grant Admin Access';

  @override
  String get adminAccessManagement => 'Admin Access Management';

  @override
  String get searchByBookingId => 'Search by Booking ID';

  @override
  String get rejectingOrder => 'Rejecting Order';

  @override
  String get failedToRejectOrder => 'Failed to Reject Order';

  @override
  String get assigningBookingTo => 'Assigning Booking to';

  @override
  String get failedToAssignBookingTo => 'Failed to Assign booking to';

  @override
  String get completeOrder => 'Complete Order';

  @override
  String get areYouSureYouWantToCompleteThisOrder =>
      'Are you sure you want to complete this order?';

  @override
  String get complete => 'Complete';

  @override
  String get completingOrder => 'Completing Order';

  @override
  String get failedToCompleteOrder => 'Failed to complete order';

  @override
  String get yourAccountHasBeenDeactivatedByAdmin =>
      'Your account has been deactivated by admin';

  @override
  String get assignTo => 'Assign To';

  @override
  String get agent => 'Technician';

  @override
  String get assignToUser => 'Assign to user';

  @override
  String get noAgentsAvailable => 'No Technician Available';

  @override
  String get scheduledFor => 'Scheduled For';

  @override
  String get services => 'Services';

  @override
  String get highlightedServices => 'Highlighted Services';

  @override
  String get manageBanners => 'Manage Banners';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get delete => 'Delete';

  @override
  String get bannerDeleted => 'Banner Deleted';

  @override
  String get failedToDeleteBanner => 'Failed to delete Banner';

  @override
  String get failedToSaveBanner => 'Failed to save Banner';

  @override
  String get active => 'Active';

  @override
  String get showInPrimaryBanner => 'Show In Primary Banner';

  @override
  String get ifDisabledItWillShowInSecondaryBanner =>
      'If disabled, it will show in secondary banner';

  @override
  String get pickImage => 'Pick Image';

  @override
  String get upload => 'Upload';

  @override
  String get failedToSaveHighlightedService =>
      'Failed to save Highlighted service';

  @override
  String get done => 'Done';

  @override
  String get addService => 'Add Service';

  @override
  String get noServicesSelected => 'No services selected';

  @override
  String get failedToSaveService => 'Failed to save service';

  @override
  String get failedToCreateService => 'Failed to create service';

  @override
  String get failedToUpdateService => 'Failed to update service';

  @override
  String get pleaseVerifyYourIqama =>
      'Please verify your iqama by checking the confirmation box';

  @override
  String get uploadYourIqama => 'Upload Your Iqama';

  @override
  String get locationPermissionsAreDenied => 'Location Permissions Are Denied';

  @override
  String get locationPermissionsArePermanentlyDenied =>
      'Location Permissions Are Permanently Denied';

  @override
  String get locationPermissionRequired => 'Location Permission Required';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'Location permissions are permanently denied. Please enable them in app settings to receive job offers.';

  @override
  String get pleaseEnableLocationServices =>
      'Please enable location services to continue using the app as a technician.';

  @override
  String get fetching => 'Fetching...';

  @override
  String get currentGeopoint => 'Current Geopoint';

  @override
  String get latitudeLabel => 'Lat';

  @override
  String get longitudeLabel => 'Lon';

  @override
  String get locationSaved => 'Location saved';

  @override
  String get errorDetectingLocation => 'Error Detecting Location';

  @override
  String get errorGettingAddress => 'Error Getting Address';

  @override
  String get pleaseSelectYourIdDocument => 'Please Select Your ID Document';

  @override
  String get pleaseSelectAtLeastOneJobRole =>
      'Please select at least one job role';

  @override
  String get unknown => 'Unknown';

  @override
  String get timedOut => 'Timed Out';

  @override
  String get technicianNotFound => 'Technician Not Found';

  @override
  String get otpAutoVerified => 'OTP Auto Verified';

  @override
  String get somethingWentWrongTryAgain => 'Something Went Wrong, Try Again';

  @override
  String get otpSent => 'OTP Sent';

  @override
  String get otpHasbeensentto => 'OTP has been sent to';

  @override
  String get anErrorOccurredPleaseTryAgainLater =>
      'An Error Occurred, Please Try Again Later';

  @override
  String get pleaseEnterAValidPhoneNumber =>
      'Please Enter A Valid Phone Number';

  @override
  String get invalidOtp => 'Invalid OTP';

  @override
  String get otpVerification => 'OTP Verification';

  @override
  String get enterTheOtpSentToTheNumber => 'Enter The OTP Sent To The Number ';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get areYouSureYouWantToLogout => 'Are you sure you want to logout?';

  @override
  String get account => 'Account';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get failedToLoadCategories => 'Failed to load categories';

  @override
  String get home => 'Home';

  @override
  String get myBooking => 'My Booking';

  @override
  String get categories => 'Categories';

  @override
  String get error => 'Error';

  @override
  String get searchHere => 'Search here';

  @override
  String get availableServices => 'Available Services';

  @override
  String get failedToLoadLocations => 'Failed to load locations';

  @override
  String get retry => 'Retry';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get profileManagement => 'Profile Management';

  @override
  String get yourName => 'Your Name';

  @override
  String get nameIsRequired => 'Name Is Required';

  @override
  String get enterAValidName => 'Enter A Valid Name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailIsRequired => 'Email Is Required';

  @override
  String get enterAValidEmail => 'Enter A Valid Email';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get locationIsRequired => 'Location Is Required';

  @override
  String get buildingNumberIsRequired => 'Building Number Is Required';

  @override
  String get streetName => 'Street Name';

  @override
  String get streetNameIsRequired => 'Street Name is Required';

  @override
  String get cityName => 'City Name';

  @override
  String get cityNameIsRequired => 'City Name Is Required';

  @override
  String get postcode => 'Postcode';

  @override
  String get postcodeIsRequired => 'Postcode Is Required';

  @override
  String get extensionNumber => 'Extension Number';

  @override
  String get extensionNumberIsRequired => 'Extension Number Is Required';

  @override
  String get update => 'Update';

  @override
  String get accountCreatedSuccessfully => 'Account Created Successfully';

  @override
  String get failedToCreateAccount => 'Failed to create account';

  @override
  String get pleaseFillTheInputBelowHereToContinue =>
      'Please fill the input below here to continue';

  @override
  String get createAccount => 'Create Account';

  @override
  String get failedToLoadContent => 'Failed to load content';

  @override
  String get noAddress => 'No Address';

  @override
  String get searchForAService => 'Search for a service';

  @override
  String get jobCategories => 'Job Categories';

  @override
  String get failedToLoadDataPleaseTryAgainLater =>
      'Failed to load data. Please try again later.';

  @override
  String get noBookings => 'No bookings';

  @override
  String get noBookingsFound => 'No bookings found.';

  @override
  String get searchServices => 'Search services';

  @override
  String get noServicesInYourWishlist => 'No services in your wishlist';

  @override
  String get failedToSaveBooking => 'Failed to Save booking';

  @override
  String get morning => 'Morning';

  @override
  String get afterNoon => 'After Noon';

  @override
  String get confirmRequest => 'Confirm Request';

  @override
  String get bonusAmount => 'Bonus Amount';

  @override
  String get requestBonusPayout => 'Request Bonus Payout';

  @override
  String get noBonusAvailableToClaim => 'No bonus available to claim';

  @override
  String get monthlyBonusEarned => 'Monthly Bonus Earned';

  @override
  String get areYouSureYouWantToRequestAPayoutForYourMonthlyBonus =>
      'Are you sure you want to request a payout for your monthly bonus?';

  @override
  String get evening => 'Evening';

  @override
  String get serviceBookedSuccessfully => 'Service Booked Successfully';

  @override
  String get checkForBookingStatus =>
      'Check your booking status in \'My Bookings\' section';

  @override
  String get selectDateTime => 'Select Date & Time';

  @override
  String get completeYourBooking => 'Complete Your Booking';

  @override
  String get selectDate => 'Select Date';

  @override
  String get availableTimeSlot => 'Available Time Slot';

  @override
  String get addNotes => 'Add Notes';

  @override
  String get cashInHand => 'Cash payment';

  @override
  String get netBankingUpiCard => 'Net banking / UPI /Card';

  @override
  String get pleaseSelectADate => 'Please select a date';

  @override
  String get back => 'Back';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get filter => 'Filter';

  @override
  String get price => 'Price';

  @override
  String get clear => 'Clear';

  @override
  String get reviewSubmittedSuccessfully => 'Review Submitted Successfully.';

  @override
  String get anErrorOccurred => 'An error occurred.';

  @override
  String get submitAReview => 'Submit A Rating';

  @override
  String get overallRating => 'Overall Rating';

  @override
  String get writeYourReviewHere => 'Write your review here';

  @override
  String get pleaseWriteAReview => 'Please write a review';

  @override
  String get cancel => 'Cancel';

  @override
  String get bookingCancelled => 'Booking Canceled';

  @override
  String get failedToCancelBooking => 'Failed to cancel booking';

  @override
  String get areYouSureToWantCancelBooking =>
      'Are you sure to want cancel booking?';

  @override
  String get youWillBeRefundedTheFullAmount =>
      'You will be refunded the full amount';

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get failedToLoadServices => 'Failed to load services';

  @override
  String get writeAReview => 'Write A Review';

  @override
  String get reviewSubmitted => 'Rating Submitted';

  @override
  String get canceled => 'Canceled';

  @override
  String get requestService => 'Request Service';

  @override
  String get submit => 'Submit';

  @override
  String get sar => 'SAR';

  @override
  String get serviceDescription => 'Service Description';

  @override
  String get serviceInfo => 'Service Info';

  @override
  String get serviceName => 'Service Name';

  @override
  String get customerInfo => 'Customer Info';

  @override
  String get bookingInfo => 'Booking Info';

  @override
  String get agentInfo => 'Technician Info';

  @override
  String get reviewInfo => 'Rating & Review Info';

  @override
  String get issueImage => 'Issue Image';

  @override
  String get issueVideo => 'Issue Video';

  @override
  String get tapToZoom => 'Tap to zoom';

  @override
  String get email => 'Email';

  @override
  String get location => 'Location';

  @override
  String get address => 'Address';

  @override
  String get buildingNumber => 'Building Number';

  @override
  String get street => 'Street';

  @override
  String get city => 'City';

  @override
  String get postCode => 'Postcode';

  @override
  String get bookedFor => 'Booked For';

  @override
  String get paymentMode => 'Payment Mode';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get bookingStatus => 'Booking Status';

  @override
  String get bookingNote => 'Problem Description';

  @override
  String get bookedAt => 'Booked At';

  @override
  String get rating => 'Rating';

  @override
  String get review => 'Review';

  @override
  String get reviewedAt => 'Rating On';

  @override
  String get manage => 'Manage';

  @override
  String get manageServices => 'Manage Services';

  @override
  String get manageHighlightedServices => 'Manage Highlighted Services';

  @override
  String get manageAgents => 'Manage Technicians';

  @override
  String get pleaseEnterYourEmailToResetPassword =>
      'Please Enter your Email to Reset Password';

  @override
  String get passwordResetEmailSent =>
      'Password Reset email sent. Please check your Email';

  @override
  String get pleaseEnterYourEmail => 'Please Enter Your Email';

  @override
  String get pleaseEnterYourPassword => 'Please Enter Your Password';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get register => 'Register';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get areYouSureYouWantToApproveAgent =>
      'Are you sure you want to approve';

  @override
  String get areYouSureYouWantToDisapproveAgent =>
      'Are you sure you want to disapprove';

  @override
  String get yesText => 'Yes';

  @override
  String get cropImage => 'Crop Image';

  @override
  String get label => 'Label';

  @override
  String get url => 'URL';

  @override
  String get title => 'Title';

  @override
  String get titleArabic => 'Title (Arabic)';

  @override
  String get name => 'Name';

  @override
  String get nameArabic => 'Name (Arabic)';

  @override
  String get description => 'Description';

  @override
  String get descriptionArabic => 'Description (Arabic)';

  @override
  String get category => 'Category';

  @override
  String get sortOrder => 'Sort Order';

  @override
  String get pleaseEnterValidEmail => 'Please Enter A Valid Email Address';

  @override
  String get emailNotRegistered => 'Email Not Registered';

  @override
  String get invalidEmailFormat => 'Invalid Email Format';

  @override
  String get tooManyRequests => 'Too many requests';

  @override
  String get netError => 'Network Error';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get userNotFound => 'User not found';

  @override
  String get userDisabled => 'User account disabled';

  @override
  String get deletingAccount => 'Deleting account...';

  @override
  String get requiresRecentLogin =>
      'This operation requires recent authentication. Please log out and log back in.';

  @override
  String get resetPasswordError => 'Reset Password Error';

  @override
  String get incorrectPassword => 'Incorrect Password';

  @override
  String get accountDisabled => 'Account Disabled';

  @override
  String get invalidCredentials => 'Invalid Credentials';

  @override
  String get loginError => 'Login Error';

  @override
  String get passwordMustBeAtleast6Characters =>
      'Password Must Be At Least 6 Characters Long';

  @override
  String get pending => 'Pending';

  @override
  String get accepted => 'Confirmed';

  @override
  String get cancelled => 'Canceled';

  @override
  String get bookings => 'Bookings';

  @override
  String get bookedOn => 'Booked On';

  @override
  String get agentsAvailable => 'Technicians Available';

  @override
  String get acceptedAt => 'Confirmed At';

  @override
  String get rejectedAt => 'Rejected At';

  @override
  String get completedAt => 'Completed At';

  @override
  String get expiredOn => 'Expired On';

  @override
  String get phone => 'Phone';

  @override
  String get card => 'Card';

  @override
  String get applePay => 'Apple Pay';

  @override
  String get cashOnHands => 'Outside App';

  @override
  String get ext => 'Ext';

  @override
  String get serviceAddedSuccessfully => 'Service Added Successfully';

  @override
  String get serviceUpdatedSuccessfully => 'Service Updated Successfully';

  @override
  String get editService => 'Edit Service';

  @override
  String get pleaseEnterAName => 'Please Enter Name';

  @override
  String get pleaseEnterNameInArabic => 'Please Enter Arabic Name';

  @override
  String get textMustBeInArabic => 'Text Must Be In Arabic';

  @override
  String get pleaseEnterADescription => 'Please Enter Description';

  @override
  String get pleaseEnterDescriptionInArabic =>
      'Please Enter Description In Arabic';

  @override
  String get descriptionMustBeInArabic => 'Description Must Be In Arabic';

  @override
  String get pleaseEnterAPrice => 'Please Enter A Price';

  @override
  String get pleaseSelectACategory => 'Please Select Category';

  @override
  String get discountPercentage => 'Discount Percentage (%)';

  @override
  String get pleaseEnterADiscountPercentage =>
      'Please Enter Discount Percentage';

  @override
  String get highlightedServiceAddedSuccessfully =>
      'Highlighted Service Added Successfully';

  @override
  String get highlightedServiceUpdatedSuccessfully =>
      'Highlighted Service Updated Successfully';

  @override
  String get selectServices => 'Select Services';

  @override
  String get addHighlightedService => 'Add Highlighted Service';

  @override
  String get editHighlightedService => 'Edit Highlighted Service';

  @override
  String get pleaseEnterATitle => 'Please Enter Title';

  @override
  String get pleaseEnterTheTitleInArabic => 'Please Enter Arabic Title';

  @override
  String get addBanner => 'Add Banner';

  @override
  String get editBanner => 'Edit Banner';

  @override
  String get labelIsRequired => 'Label Is Required';

  @override
  String get urlIsRequired => 'URL Is Required';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get bannerAddedSuccessfully => 'Banner Added Successfully';

  @override
  String get bannerUpdatedSuccessfully => 'Banner Updated Successfully';

  @override
  String get doYouWantToUploadThisImage => 'Do you want to upload this image?';

  @override
  String get pleaseSelectAnImage => 'Please Select An Image';

  @override
  String get hasBeenApprovedAsAnAgent => 'has been approved as an Technician';

  @override
  String get hasBeenDisapprovedAsAnAgent =>
      'has been disapproved as an Technician';

  @override
  String get jobRoles => 'Job Roles';

  @override
  String get document => 'Document';

  @override
  String get jobRolesAreRequired => 'Job Roles Are Required';

  @override
  String get failedToDeleteAccount => 'Failed to delete account';

  @override
  String get pleaseConfirmYourPassword => 'Please Confirm Your Password';

  @override
  String get passwordsDoNotMatch => 'Passwords Do Not Match';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get selectJobRoles => 'Select Job Roles';

  @override
  String get failedToDetectLocation => 'Failed to detect location';

  @override
  String get failedToGetAddress => 'Failed to get address';

  @override
  String get addCustomJobRoles => 'Add Custom Job Roles';

  @override
  String get enterAdditionalJobRoles => 'Enter Additional Job Roles';

  @override
  String get detectCurrentLocation => 'Detect Current Location';

  @override
  String get failedToGetLocation => 'Failed to get location';

  @override
  String get cannotCompleteTasksScheduledForTheFuture =>
      'Cannot complete tasks scheduled for the future';

  @override
  String get orders => 'Orders';

  @override
  String get offers => 'Offers';

  @override
  String get failedToLoadUserData => 'Failed to load user data';

  @override
  String get areYouSureYouWantToDeleteYourAccountThisActionCannotBeUndone =>
      'Are you sure you want to delete your account? This action cannot be undone';

  @override
  String get completed => 'Completed';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get bookingAccepted => 'Booking Confirmed';

  @override
  String get bookingAssignedToYou => 'You have been assigned to a booking.';

  @override
  String get yourBookingRequestHasBeenAccepted =>
      'Your booking request has been confirmed! Our team will contact you shortly.';

  @override
  String get bookingRejected => 'Booking Rejected';

  @override
  String get yourBookingRequestHasBeenRejected =>
      'Unfortunately, your booking request has been rejected. Please try again or contact support.';

  @override
  String get sendingNotification => 'Sending notification to customer';

  @override
  String get notificationSent => 'Notification sent to customer';

  @override
  String get bookingCompleted => 'Booking Completed';

  @override
  String get yourBookingHasBeenCompleted => 'Your booking has been completed!';

  @override
  String get notifications => 'Notifications';

  @override
  String get pleaseWaitAccountVerification =>
      'Your account is being verified by the admin, check back later';

  @override
  String get goBack => 'Go Back';

  @override
  String get deleteRegistrationConfirmation =>
      'Are you sure you want to delete your registration?';

  @override
  String get phoneNumberAlreadyExists => 'Phone number already exists';

  @override
  String get keepImage => 'Keep Image';

  @override
  String get keepImageDescription =>
      'Do you want to keep the selected image without cropping?';

  @override
  String get keep => 'Keep';

  @override
  String get pleaseSelectAtLeastOneService =>
      'Please select at least one service';

  @override
  String get deleteBannerConfirmation =>
      'Are you sure you want to delete this banner?';

  @override
  String get selectLocations => 'Select Locations';

  @override
  String get tapToSelectLocations => 'Tap to select locations';

  @override
  String get locationsSelected => 'Locations Selected';

  @override
  String get locationSelected => 'Location Selected';

  @override
  String get searchLocation => 'Search Location';

  @override
  String get noLocationsFound => 'No locations found';

  @override
  String get accountVerificationPending =>
      'Your account is currently under Review by our admin team.';

  @override
  String get saving => 'Saving...';

  @override
  String get uploading => 'Uploading...';

  @override
  String get enterAValidPhoneNumber => 'Please Enter a valid phone number';

  @override
  String get manageTips => 'Manage Tips';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get counterPropose => 'Counter Propose';

  @override
  String get proposeNewTime => 'Suggest New Time';

  @override
  String get counterOfferPending => 'Counter Offer Pending';

  @override
  String get customerProposedNewTime => 'Customer proposed a new time';

  @override
  String get acceptOffer => 'Accept Offer';

  @override
  String get rejectOffer => 'Reject Offer';

  @override
  String get newProposedTime => 'New Proposed Time';

  @override
  String get waitingForCustomer => 'Waiting for customer response';

  @override
  String get proposedTime => 'Proposed Time';

  @override
  String get counterOfferSent => 'Counter offer sent successfully';

  @override
  String get counterOfferResponse => 'Response sent successfully';

  @override
  String get counterProposalStarted => 'Counter proposal started';

  @override
  String get counterProposalAccepted => 'Counter proposal confirmed';

  @override
  String get proposalRejected => 'Proposal Rejected';

  @override
  String get proposalAccepted => 'Proposal Confirmed';

  @override
  String get customerRejectedProposal => 'Customer rejected your proposal.';

  @override
  String get youRejectedProposal => 'You rejected customer\'s proposal.';

  @override
  String get appointmentRescheduledTo => 'Appointment rescheduled to';

  @override
  String get rescheduleBookingTimeConfirmation =>
      'Are you sure you want to accept this new appointment time? The booking schedule will be updated immediately.';

  @override
  String get startWork => 'Start Work';

  @override
  String get pleaseEnterSortOrder => 'Please enter sort order';

  @override
  String get yes => 'Yes';

  @override
  String get categoryAddedSuccessfully => 'Category added successfully';

  @override
  String get categoryUpdatedSuccessfully => 'Category updated successfully';

  @override
  String get phoneNumberRequired => 'Phone number is required';

  @override
  String get phoneNumberInvalid => 'Phone number is invalid';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get pleaseSelectALocation => 'Please select a location';

  @override
  String get day => 'Day';

  @override
  String get hour => 'Hour';

  @override
  String get minute => 'Minute';

  @override
  String get justNow => 'Just Now';

  @override
  String get emailAlreadyExists => 'Email already exists';

  @override
  String get tippingCleared => 'Tipping cleared';

  @override
  String get failedToClearTipping => 'Failed to clear tipping';

  @override
  String get manageTipping => 'Manage Tipping';

  @override
  String get noTipsAvailable => 'No tips available';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get tipInfo => 'Tip info';

  @override
  String get totalTips => 'Total tips';

  @override
  String get lastTipAmount => 'Last tip Amount';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get agentId => 'Technician ID';

  @override
  String get sendAndClearWallet => 'Send & Clear Wallet';

  @override
  String get clearWallet => 'Clear Wallet';

  @override
  String get clearWalletWarning =>
      'This action cannot be undone. The Technician will receive the total amount in their wallet, and it will be reset to zero.';

  @override
  String get areYouSureYouWantToSend => 'Are you sure you want to send';

  @override
  String get to => 'to';

  @override
  String get confirm => 'Confirm';

  @override
  String get andClearTheirWallet => 'and clear their wallet';

  @override
  String get invalid => 'Invalid';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission denied forever';

  @override
  String get tracking => 'Tracking';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get pleaseUploadAnImage => 'Please upload an image';

  @override
  String get searchBookings => 'Search Bookings';

  @override
  String get item => 'Item';

  @override
  String get quantity => 'Quantity';

  @override
  String get warrantyRejectedTechnicians => 'Warranty Rejected Technicians';

  @override
  String get loadingBanners => 'Loading Banners';

  @override
  String get cancelledDate => 'Cancelled Date';

  @override
  String get paymentPending => 'Payment Pending';

  @override
  String get loadingHighlightedServices => 'Loading Highlighted Services';

  @override
  String get loadingServices => 'Loading Services';

  @override
  String get completionDetails => 'Completed Details';

  @override
  String get loadingFaqs => 'Loading FAQs';

  @override
  String get loadingTechnicians => 'Loading Technicians';

  @override
  String get bookingWasCancelledByCustomer =>
      'Booking was cancelled by customer';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get deletedSuccessfully => 'Deleted successfully';

  @override
  String get deleteError => 'Delete error';

  @override
  String get deleteService => 'Delete Service';

  @override
  String get serviceCompletedDescription =>
      'Service has been completed successfully. A 1-week warranty will be applied.';

  @override
  String get paymentThroughApp => 'Inside App';

  @override
  String get paymentOutsideApp => 'Outside App';

  @override
  String get paymentThroughAppDesc => 'Customer will pay through the app.';

  @override
  String get paymentOutsideAppDesc => 'Collect payment outside of the app.';

  @override
  String get deleteServiceConfirmation =>
      'Are you sure you want to delete this service?';

  @override
  String get failedToLoadData => 'Failed to load data';

  @override
  String get categoryNameAlreadyExists => 'Category name already exists';

  @override
  String get deleteCategoryConfirmation =>
      'Are you sure you want to delete this category?';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get completeWork => 'Complete Work';

  @override
  String get gallery => 'Gallery';

  @override
  String get qty => 'Qty';

  @override
  String get inspectionOnlyDescription =>
      'Only inspection done, no service provided';

  @override
  String get required => 'Required';

  @override
  String get requests => 'Requests';

  @override
  String get newtext => 'New';

  @override
  String get waitingForPayment => 'Waiting for payment';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get inspectionOnly => 'Inspection Only';

  @override
  String get support => 'Support';

  @override
  String get getHelpAnytime => 'Get help anytime';

  @override
  String get tierSystem => 'Tier System';

  @override
  String get bronze => 'Bronze';

  @override
  String get silver => 'Silver';

  @override
  String get gold => 'Gold';

  @override
  String get platinum => 'Platinum';

  @override
  String get nobonus => 'No bonus';

  @override
  String get fivepercentBonus => '5% Bonus';

  @override
  String get tenpercentBonus => '10% Bonus';

  @override
  String get fifteenpercentBonus => '15% Bonus + Badge';

  @override
  String get greaterThan3dot5rating => '3.5+ rating';

  @override
  String get greaterThan4dot0rating => '4.0+ rating';

  @override
  String get greaterThan4dot5rating => '4.5+ rating';

  @override
  String get greaterThan4dot8rating => '4.8+ rating';

  @override
  String get searchByTechnicianName => 'Search by technician name';

  @override
  String get bookingWasRejectedByAdmin => 'Booking was rejected by admin';

  @override
  String get bonus => 'Bonus';

  @override
  String get jobs => 'Jobs';

  @override
  String get twentyPlusJobs => '20+ Jobs';

  @override
  String get thirtyPlusJobs => '30+ Jobs';

  @override
  String get fortyPlusJobs => '40+ Jobs';

  @override
  String get sixtyPlusJobs => '60+ Jobs';

  @override
  String get earnings => 'Earnings';

  @override
  String get exitAppTitle => 'Exit App';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get id => 'ID';

  @override
  String get exitAppMessage => 'Are you sure you want to exit the app?';

  @override
  String get exit => 'Exit';

  @override
  String get nextTierProgress => 'Next tier progress';

  @override
  String get greaterThan20jobsPerMonth => 'â‰¥ 20 jobs/month';

  @override
  String get orderId => 'Order ID';

  @override
  String get greaterThan40jobsPerMonth => 'â‰¥ 40 jobs/month';

  @override
  String get greaterThan60jobsPerMonth => 'â‰¥ 60 jobs/month';

  @override
  String get progressResetsMonthly =>
      'Progress resets monthly, Maintain high ratings and complete more jobs to unlock better rewards.';

  @override
  String get progressResetsMonthlyDesc =>
      'Progresses rests monthly. Maintain high ratings and complete more jobs to unlock better rewards';

  @override
  String get zeroPercentBonus => '0% Bonus';

  @override
  String get fivepercentBonusOnly => '5% Bonus';

  @override
  String get tenpercentBonusOnly => '10% Bonus';

  @override
  String get fifteenpercentBonusOnly => '15% Bonus';

  @override
  String get viewYourRewards => 'View your rewards';

  @override
  String get noSupportAvailable => 'No support available';

  @override
  String get contactSupportOptions => 'Contact support options';

  @override
  String get contactByEmail => 'Contact by email';

  @override
  String get contactByPhone => 'Contact by phone';

  @override
  String get contactByWhatsApp => 'Contact by WhatsApp';

  @override
  String get serviceCompleted => 'Service Completed';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get serviceItems => 'Service Items';

  @override
  String get enterServiceCost => 'Enter service cost';

  @override
  String get serviceCostMustBeGreaterThanZero =>
      'Service cost must be greater than 0';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get pleaseEnterServiceCost => 'Please enter service cost';

  @override
  String get tapToUploadImage => 'Tap to upload image';

  @override
  String get serviceCost => 'Service Cost';

  @override
  String get addItem => 'Add Item';

  @override
  String get camera => 'Camera';

  @override
  String get pleaseAddAtleastOneServiceItem =>
      'Please add atleast one service item';

  @override
  String get pleaseFillAllServiceItemFields =>
      'Please fill all service item fields';

  @override
  String get workingDays => 'Working Days';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get locationServiceRequired => 'Location service is required';

  @override
  String get pleaseEnableLocationService => 'Please enable location service';

  @override
  String get ok => 'OK';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get bioMetricAuthentication => 'Enable Biometric';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get startTracking => 'Start Tracking';

  @override
  String get stopTracking => 'Stop Tracking';

  @override
  String get arrivedAtLocation => 'Arrived at location';

  @override
  String get youHaveActiveBooking => 'You have an active booking';

  @override
  String get areYouSureYouWantToStartTracking =>
      'Are you sure you want to start tracking for this booking? This will enable location monitoring.';

  @override
  String get start => 'Start';

  @override
  String get areYouSureYouWantToStopTracking =>
      'Are you sure you want to stop tracking for this booking? Location monitoring will be disabled.';

  @override
  String get stop => 'Stop';

  @override
  String get activeBooking => 'Active Booking';

  @override
  String get failedToStartTracking => 'Failed to start tracking';

  @override
  String get trackingStarted => 'Tracking started';

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get settings => 'Settings';

  @override
  String get trackingNote =>
      'Note: If youâ€™re starting the work, please click the â€œStart Trackingâ€ button. In case the button gets cut off or changes, make sure to click â€œStart Trackingâ€ again.';

  @override
  String get filterByLocation => 'Filter by Location';

  @override
  String get allLocations => 'All Locations';

  @override
  String get clearFilter => 'Clear Filter';

  @override
  String get agents => 'Technicians';

  @override
  String get inSelectedLocation => 'In Selected Location';

  @override
  String get totalAgents => 'Total Technicians';

  @override
  String get filteredBy => 'Filtered by';

  @override
  String get notificationLanguage => 'Notification Language';

  @override
  String get areYouSureYouWantToCancelThisBooking =>
      'Are you sure you want to cancel this booking?';

  @override
  String get bookingTimeline => 'Booking Timeline';

  @override
  String get trackingStartedAt => 'Tracking started at';

  @override
  String get createdAt => 'Created At';

  @override
  String get enableBiometricAuthentication => 'Enable Biometric Authentication';

  @override
  String get notificationLanguageUpdated => 'Notification language updated';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get issueMedia => 'Issue Media';

  @override
  String get loadingVideo => 'Loading Video';

  @override
  String get categoryAlreadyExists => 'Category already exists';

  @override
  String get noLocationsAvailable => 'No locations available';

  @override
  String get close => 'Close';

  @override
  String get enterPasswordToConfirm => 'Enter Password to Confirm';

  @override
  String get deleteAccountWarning =>
      'Are you sure you want to delete your account? This action cannot be undone';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get customerName => 'Customer Name';

  @override
  String get call => 'Call';

  @override
  String get directions => 'Directions';

  @override
  String get images => 'Images';

  @override
  String get video => 'Video';

  @override
  String get walletClearedSuccessfully =>
      'Wallet balances successfully cleared';

  @override
  String get biometricNotSupported => 'Biometric not supported';

  @override
  String get pleaseAuthenticateToContinue => 'Please authenticate to continue';

  @override
  String get authenticationFailed => 'Authentication failed';

  @override
  String get biometricNotAvailable => 'Biometric not available';

  @override
  String get biometricTemporarilyLocked => 'Biometric temporarily locked';

  @override
  String get unexpectedErrorOccurred => 'Unexpected error occurred';

  @override
  String get ago => 'Ago';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get country => 'Country';

  @override
  String get languageCode => 'Language Code';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get adminStatus => 'Admin Status';

  @override
  String get verified => 'Verified';

  @override
  String get systemInformation => 'System Information';

  @override
  String get userId => 'User ID';

  @override
  String get updatedAt => 'Updated At';

  @override
  String get admin => 'Admin';

  @override
  String get assignedRoles => 'Assigned Roles';

  @override
  String get noAgentsFound => 'No Technician found';

  @override
  String get agentApproved => 'Technician Approved';

  @override
  String get agentDisapproved => 'Technician Disapproved';

  @override
  String get deleteBanner => 'Delete Banner';

  @override
  String get invalidImageUrl => 'Invalid Image URL';

  @override
  String get imageLoadError => 'Image load error';

  @override
  String get imageCropError => 'Image crop error';

  @override
  String get errorAddingCategory => 'Error adding category';

  @override
  String get errorUpdatingCategory => 'Error updating category';

  @override
  String get customerSubmittedBookingRequest =>
      'Customer submitted booking request';

  @override
  String get serviceProviderConfirmedAppointment =>
      'Technician confirmed appointment';

  @override
  String get serviceTrackingInitiated => 'Service tracking initiated';

  @override
  String get serviceHasBeenSuccessfullyCompleted =>
      'Service has been successfully completed';

  @override
  String get bookingWasRejectedByServiceProvider =>
      'Booking was rejected by Technician';

  @override
  String get bookingWasCancelled => 'Booking was cancelled';

  @override
  String get serviceInProgress => 'Service in progress';

  @override
  String get current => 'Current';

  @override
  String get serviceIsCurrentlyBeingPerformed =>
      'Service is currently being performed';

  @override
  String get waitingForServiceProvider => 'Waiting for Technician';

  @override
  String get waitingForTechnicianToStartService =>
      'Waiting for Technician to start service';

  @override
  String get waitingForAcceptance => 'Waiting for acceptance';

  @override
  String get waitingForServiceProviderResponse =>
      'Waiting for Technician response';

  @override
  String get waitingForAdmin => 'Waiting for Admin';

  @override
  String get waitingForAdminToReassign =>
      'Waiting for admin to reassign technician';

  @override
  String get orderRejected => 'Order Rejected Successfully';

  @override
  String get registrationSuccess => 'Registration Success';

  @override
  String get registrationFailed => 'Registration Failed';

  @override
  String get confirmReject => 'Confirm Reject';

  @override
  String get updatedOn => 'Updated On';

  @override
  String get approvedOn => 'Confirmed On';

  @override
  String get confirmRejectMessage =>
      'Are you sure you want to reject this order?';

  @override
  String get bookingCancelledSuccessfully => 'Booking Cancelled Successfully';

  @override
  String get workMarkedAsComplete => 'Work Marked As Complete';

  @override
  String get areYouSureYouWantToStartTrackingThisBooking =>
      'Are you sure you want to start tracking this booking?';

  @override
  String get areYouSureYouWantToPauseTrackingThisBooking =>
      'Are you sure you want to pause tracking this booking?';

  @override
  String get areYouSureYouWantToStopTrackingThisBooking =>
      'Are you sure you want to stop tracking this booking?';

  @override
  String get pauseTracking => 'Pause Tracking';

  @override
  String get resumeTracking => 'Resume Tracking';

  @override
  String get trackingPausedSuccessfully => 'Tracking paused successfully';

  @override
  String get areYouSureYouWantToCompleteThisWork =>
      'Are you sure you want to complete this work?';

  @override
  String get useBiometric => 'Use Biometric';

  @override
  String get imageIsRequired => 'Image is required';

  @override
  String get bookingCompletedSuccessfully => 'Booking completed successfully';

  @override
  String get startedWorkingOnBookingSuccessfully =>
      'Started working on booking successfully';

  @override
  String get stopTrackingBookingSuccessfully =>
      'Stop tracking booking successfully';

  @override
  String get cards => 'Inside App';

  @override
  String get insideApp => 'Inside App';

  @override
  String get outsideApp => 'Outside-App';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get failedToSendNotification =>
      'Failed to send notification to customer';

  @override
  String get locationPermissionErrorIOS =>
      'Location permission error on iOS. Please go to Settings > Privacy & Security > Location Services > Abo Glumbo Technician and select \'Always\' to enable background tracking.';

  @override
  String get youHaveAnActiveBookingAlready =>
      'You have an active booking already.';

  @override
  String get locationServicesDisabledPleaseEnable =>
      'Location services disabled. Please enable location services.';

  @override
  String get openLocationSettings => 'Open Location Settings';

  @override
  String get image => 'Image';

  @override
  String get notificationTitle => 'Notification Title';

  @override
  String get enterYourNotificationMessageHere =>
      'Enter your notification message here';

  @override
  String get aboGlumboTechnician => 'Abo Glumbo Technician';

  @override
  String get now => 'Now';

  @override
  String get assigningTechnician => 'Pending Acceptance';

  @override
  String get selectProvince => 'Select Province';

  @override
  String get selectCity => 'Select City';

  @override
  String get rejectionHistory => 'Rejection History';

  @override
  String get selectNeighborhood => 'Select Neighborhood';

  @override
  String get recipients => 'Recipients';

  @override
  String get techniciansRejectedThisClaim => 'Technicians rejected this claim';

  @override
  String get technicianRejectedThisClaim => 'Technician rejected this claim';

  @override
  String get warrantyClaims => 'Warranty Claims';

  @override
  String get expired => 'Expired';

  @override
  String get tapToView => 'Tap to view';

  @override
  String get rejections => 'Rejections';

  @override
  String get exceedsMaxSize => 'Exceeds max size';

  @override
  String get sendNotifications => 'Send Notifications';

  @override
  String get sendNotification => 'Send Notification';

  @override
  String get couldNotOpenFile => 'Could not open file';

  @override
  String get noTechniciansFound => 'No technicians found';

  @override
  String get noTechniciansAvailable => 'No technicians available';

  @override
  String get manageNotificationAlerts => 'Manage Notification Alerts';

  @override
  String get previewLanguage => 'Preview Language';

  @override
  String get sendNotificationsToCustomer => 'Send Notifications to Customer';

  @override
  String get preview => 'Preview';

  @override
  String get message => 'Message';

  @override
  String get composeMessage => 'Compose Message';

  @override
  String get clearAll => 'Clear All';

  @override
  String get iqama => 'Iqama';

  @override
  String get certificationsrelevantExperienceDocuments =>
      'Certifications/Relevant Experience Documents';

  @override
  String get filesSelected => 'Files selected';

  @override
  String get certificationsrelevantExperienceDocumentsOptional =>
      'Certifications/relevant experience documents (optional)';

  @override
  String get invoiceType => 'Invoice Type';

  @override
  String get fullService => 'Full Service';

  @override
  String get inspection => 'Inspection';

  @override
  String get inspectionFee => 'Inspection Fee';

  @override
  String get bookingId => 'Booking ID';

  @override
  String get typeMessageToCustomer => 'Type a message to customer...';

  @override
  String get startConversationWithCustomer =>
      'Start a conversation with your customer';

  @override
  String get chatWithCustomer => 'Chat with Customer';

  @override
  String get startChat => 'Start Chat';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get amountPaid => 'Amount Paid';

  @override
  String get continueChat => 'Continue Chat';

  @override
  String get failedToStartChat => 'Failed to start chat';

  @override
  String get creatingChatRoom => 'Creating chat room';

  @override
  String get loadingChat => 'Loading chat';

  @override
  String get noMessages => 'No messages';

  @override
  String get errorLoadingMessages => 'Error loading messages';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get backgroundLocationPermissionRequired =>
      'Background location tracking requires Always Allow permission. Please enable this in your device settings.';

  @override
  String get locationPermissionDeniedPleaseGrant =>
      'Location permission denied. Please grant location permission to continue.';

  @override
  String get areYouSureYouWantToCompleteThisBooking =>
      'Are you sure you want to complete this booking?';

  @override
  String get locationPermissionPermanentlyDeniedPleaseEnable =>
      'Location permission permanently denied. Please enable location access in Settings.';

  @override
  String get locationServicesDisabledCannotRestoreTracking =>
      'Location services disabled, cannot restore tracking';

  @override
  String get locationPermissionDeniedCannotRestoreTracking =>
      'Location permission denied, cannot restore tracking';

  @override
  String get iosLocationPermissionErrorDuringRestore =>
      'iOS location permission error during restore - may need \"Always\" permission';

  @override
  String get locationTrackingRestoredSuccessfully =>
      'Location tracking restored successfully';

  @override
  String get iosLocationPermissionIssueDuringRestore =>
      'iOS location permission issue during restore';

  @override
  String get iosOnlyWhenInUsePermissionGranted =>
      'iOS: Only \'When In Use\' permission granted. Background tracking will be limited.';

  @override
  String get iosAlwaysPermissionGranted =>
      'iOS: \'Always\' permission granted. Full background tracking available.';

  @override
  String get iosErrorRequestingAlwaysPermission =>
      'iOS: Error requesting always permission';

  @override
  String get iosContinuingWithWhenInUsePermissionOnly =>
      'iOS: Continuing with \'When In Use\' permission only.';

  @override
  String get batteryOptimizationEnabledMayAffectTracking =>
      'Battery optimization is enabled, may affect background location';

  @override
  String get trackingYourLocationForServiceDelivery =>
      'Tracking your location for service delivery';

  @override
  String get aboGlumboLocationTracking => 'Abo Glumbo - Location Tracking';

  @override
  String get backgroundLocationUpdated => 'Background location updated';

  @override
  String get errorUpdatingBackgroundLocation =>
      'Error updating background location';

  @override
  String get backgroundFetchTriggered => 'Background fetch triggered';

  @override
  String get backgroundFetchTimeout => 'Background fetch timeout';

  @override
  String get locationStreamErrorDuringRestore =>
      'Location stream error during restore';

  @override
  String get errorRestoringLocationTracking =>
      'Error restoring location tracking';

  @override
  String get backgroundFetchConfiguredAndStarted =>
      'Background fetch configured and started';

  @override
  String get errorConfiguringBackgroundFetch =>
      'Error configuring background fetch';

  @override
  String get locationUpdated => 'Location updated';

  @override
  String get errorUpdatingLocationToFirestore =>
      'Error updating location to Firestore';

  @override
  String get errorStoppingBackgroundFetch => 'Error stopping background fetch';

  @override
  String get errorUpdatingBookingStatus => 'Error updating booking status';

  @override
  String get locationTrackingStopped => 'Location tracking stopped';

  @override
  String get deleteItemConfirmation =>
      'Are you sure you want to delete this item?';

  @override
  String get agentUnavailable => 'Technician Unavailable';

  @override
  String get timeConflictDetected => 'Time Conflict Detected';

  @override
  String get cannotAssignWorkTo => 'Cannot assign work to';

  @override
  String get alreadyAssignedAtExactSameTime =>
      'Already assigned at exact same time';

  @override
  String get currentBookingTime => 'Current Booking Time';

  @override
  String get technicianCannotBeAssignedMultipleTimes =>
      'A Technician cannot be assigned to multiple bookings at the exact same time. Please select a different time slot or choose another Technician.';

  @override
  String get unknownTechnician => 'Unknown Technician';

  @override
  String get tryadifferentsearchterm => 'Try a different search term';

  @override
  String get warrantyRepairRequested => 'Warranty Repair Requested';

  @override
  String get acceptWarrantyRepair => 'Accept Warranty Repair';

  @override
  String get customerRequestedRepairUnderWarranty =>
      'Customer requested repair under warranty';

  @override
  String get warrantyRepairAccepted => 'Warranty Repair Confirmed';

  @override
  String get technicianAcceptedTheRequest => 'Technician confirmed the request';

  @override
  String get warrantyRepairCompleted => 'Warranty Repair Completed';

  @override
  String get originalServiceCompleted => 'Original Service Completed';

  @override
  String get warrantyRejectedByAdmin => 'Warranty Rejected by Admin';

  @override
  String get warrantyRejectedByTechnician => 'Warranty Rejected by Technician';

  @override
  String get reasonforrejection => 'Reason for rejection';

  @override
  String get warrantyRequestWasRejectedByAdmin =>
      'Warranty request was rejected by admin';

  @override
  String get warrantyRequestWasRejectedByTechnician =>
      'Warranty request was rejected by technician';

  @override
  String get technicianCompletedTheRequest =>
      'Technician completed the request';

  @override
  String get warrantyExpired => 'Warranty Expired';

  @override
  String get warrantyPeriodHasExpired => 'Warranty period has expired';

  @override
  String get trackingStoppedAt => 'Tracking Stopped';

  @override
  String get serviceTrackingStopped => 'Service tracking has been stopped';

  @override
  String get youCancelledThisRequest => 'You cancelled this request';

  @override
  String get youDeclinedThisWarrantyRequest =>
      'You declined this warranty request';

  @override
  String get noresultsfound => 'No results found';

  @override
  String get technicianCancelled => 'Technician Cancelled';

  @override
  String get cancelledByTechnician => 'Cancelled by Technician';

  @override
  String get technicianPreviouslyCancelled => 'Technician Previously Cancelled';

  @override
  String get agentCancelledAtTimeSlot =>
      'Technician cancelled at this time before';

  @override
  String get previouslyCancelledAt => 'Previously cancelled at';

  @override
  String get chooseDifferentAgent => 'Choose Different Technician';

  @override
  String get assignAnyway => 'Assign Anyway';

  @override
  String get cancelledAt => 'Cancelled at';

  @override
  String get technicianCancelledAtTime =>
      'This Technician previously cancelled a booking at this exact time slot. Consider assigning to a different Technician for better reliability.';

  @override
  String get errorCheckingBatteryOptimization =>
      'Error checking battery optimization';

  @override
  String get technicianRestrictedTitle => 'Technician Restricted';

  @override
  String get cannotAssignCancelledTechnician =>
      'Cannot assign cancelled Technician';

  @override
  String get lastCancellationOn => 'Last cancellation on';

  @override
  String get technicianCancelledRestrictionMessage =>
      'This Technician has previously cancelled a booking and is now restricted from new assignments. Please choose a different Technician.';

  @override
  String get understood => 'Understood';

  @override
  String get suspendAccount => 'Suspend Account';

  @override
  String get unblockAccount => 'Unblock Account';

  @override
  String get areYouSureYouWantToSuspendThisAccount =>
      'Are you sure you want to suspend this account?';

  @override
  String get areYouSureYouWantToUnblockThisAccount =>
      'Are you sure you want to unblock this account?';

  @override
  String get accountSuspended => 'Account Suspended';

  @override
  String get accountUnblocked => 'Account Unblocked';

  @override
  String get completedOrders => 'Completed Orders';

  @override
  String get profession => 'Profession';

  @override
  String get idAndDocuments => 'ID and Documents';

  @override
  String get bonusTier => 'Bonus Tier';

  @override
  String get systemInfo => 'System Info';

  @override
  String get earningsBreakdown => 'Earnings Breakdown';

  @override
  String get bonuses => 'Bonuses';

  @override
  String get noDocumentsUploaded => 'No Documents Uploaded';

  @override
  String get cancelledThisBooking => 'Cancelled This Booking';

  @override
  String get alreadyBookedAt => 'Already booked at';

  @override
  String get bookingAssignedTo => 'Booking assigned to';

  @override
  String get bookingAssignmentSuccessful => 'Booking assignment successful';

  @override
  String get anotherAssignmentInProgress =>
      'Another assignment is in progress. Please wait...';

  @override
  String get assignmentInProgress => 'Assignment in progress. Please wait...';

  @override
  String get checkingAvailabilityAndAssigning =>
      'Checking availability and assigning...';

  @override
  String get thisBookingAlreadyAssignedToAnotherAgent =>
      'This booking has already been assigned to another Technician.';

  @override
  String get failedToAssignAgent =>
      'Failed to assign Technician. Please try again.';

  @override
  String get thisAgentCancelledSameBookingBefore =>
      'This Technician cancelled this same booking before';

  @override
  String get gotIt => 'Got it';

  @override
  String get showAllAgents => 'Show All Technicians';

  @override
  String get availableInSelectedLocation => 'available in selected location';

  @override
  String get cancelledThisBookingOn => 'Cancelled this booking on';

  @override
  String get previouslyCancelledAgent => 'Previously Cancelled Technician';

  @override
  String get agentPreviouslyCancelledWarning =>
      'This Technician previously cancelled this same booking request. You can still assign them, but consider choosing a more reliable Technician.';

  @override
  String get busyAt => 'Busy at';

  @override
  String get managefaq => 'Manage FAQ';

  @override
  String get technicianArrived => 'Technician Arrived';

  @override
  String get paymentRequested => 'Payment Requested';

  @override
  String get reassignedAt => 'Reassigned At';

  @override
  String get newTechnicianAssigned => 'New Technician Assigned';

  @override
  String get technicianStartedTracking => 'Technician is on the way';

  @override
  String get technicianArrivedAtLocation => 'Technician arrived at location';

  @override
  String get inspectionCompleted => 'Inspection Completed';

  @override
  String get fullServiceCompleted => 'Full Service Completed';

  @override
  String get cancelledByAdmin => 'Cancelled by Admin';

  @override
  String get paymentCompleted => 'Payment Completed';

  @override
  String get paymentSuccessfullyCompleted =>
      'Payment has been successfully completed';

  @override
  String get bookingCancelledByAdmin => 'Booking was cancelled by admin';

  @override
  String get addFaq => 'Add FAQ';

  @override
  String get noFaqEntriesFound => 'No FAQ entries found';

  @override
  String get manageFaqs => 'Manage FAQs';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get question => 'Question';

  @override
  String get answer => 'Answer';

  @override
  String get questionIsRequired => 'Question is required';

  @override
  String get answerIsRequired => 'Answer is required';

  @override
  String get faqAddedSuccessfully => 'FAQ added successfully';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get addFaqEntry => 'Add FAQ Entry';

  @override
  String get questionMustBeInArabic => 'Question must be in Arabic';

  @override
  String get answerMustBeInArabic => 'Answer must be in Arabic';

  @override
  String get faqEntryDeletedSuccessfully => 'FAQ entry deleted successfully';

  @override
  String get position => 'Position';

  @override
  String get entryAlreadyExists => 'Entry exists in the entered position';

  @override
  String get manageCustomers => 'Manage Customers';

  @override
  String get areYouSureYouWantToUnBlockThisCustomer =>
      'Are you sure you want to un-block this customer?';

  @override
  String get areYouSureYouWantToBlockThisCustomer =>
      'Are you sure you want to block this customer?';

  @override
  String get customer => 'Customer';

  @override
  String get blocked => 'Blocked';

  @override
  String get customerUnblockedSuccessfully => 'Customer unblocked successfully';

  @override
  String get customerBlockedSuccessfully => 'Customer blocked successfully';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get blockCustomer => 'Block Customer';

  @override
  String get unBlockCustomer => 'Un-block Customer';

  @override
  String get checkingAvailability => 'Checking Technician availability...';

  @override
  String get positionText => 'Position';

  @override
  String get faqUpdatedSuccessfully => 'FAQ updated successfully';

  @override
  String get deleteFaqEntry => 'Delete FAQ Entry';

  @override
  String get manageTechnicians => 'Manage Technicians';

  @override
  String get manageCustomerSupport => 'Manage Customer Support';

  @override
  String get customerSupport => 'Customer Support';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get addNewEmail => 'Add New Email';

  @override
  String get add => 'Add';

  @override
  String get areYouSureYouWantToDeleteThisFaqEntry =>
      'Are you sure you want to delete this FAQ entry?';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone';

  @override
  String get supportContactDeletedSuccessfully =>
      'Support contact deleted successfully';

  @override
  String get supportContactUpdatedSuccessfully =>
      'Support contact updated successfully';

  @override
  String get supportContactAddedSuccessfully =>
      'Support contact added successfully';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get deleteConfirmation => 'Delete Confirmation';

  @override
  String get areYouSureYouWantToDeleteThisSupportContact =>
      'Are you sure you want to delete this support contact?';

  @override
  String get supportContact => 'Support Contact';

  @override
  String get phoneIsRequired => 'Phone is required';

  @override
  String get whatsappNumberIsRequired => 'WhatsApp number is required';

  @override
  String get editEmail => 'Edit Email';

  @override
  String get addNewWhatsapp => 'Add New WhatsApp';

  @override
  String get addNewPhone => 'Add New Phone';

  @override
  String get editWhatsapp => 'Edit WhatsApp';

  @override
  String get editPhone => 'Edit Phone';

  @override
  String get edit => 'Edit';

  @override
  String get setAsPrimary => 'Set as Primary';

  @override
  String get primary => 'Primary';

  @override
  String get search => 'Search';

  @override
  String get all => 'All';

  @override
  String get disapproveAgent => 'Disapprove Technician';

  @override
  String get approveAgent => 'Approve Technician';

  @override
  String get areYouSureYouWantToDisapproveThisAgent =>
      'Are you sure you want to disapprove this Technician?';

  @override
  String get areYouSureYouWantToApproveThisAgent =>
      'Are you sure you want to approve this Technician?';

  @override
  String get tryAdjustingYourSearchCriteria =>
      'Try adjusting your search or filters.';

  @override
  String get noTechniciansMatchYourFilters =>
      'No Technicians match your search';

  @override
  String get unblockCustomer => 'Unblock Customer';

  @override
  String get filterByDate => 'Filter by Date';

  @override
  String get typeProvinceNameToSearch => 'Type province name to search...';

  @override
  String get typeCityNameToSearch => 'Type city name to search...';

  @override
  String get typeNeighborhoodNameToSearch =>
      'Type neighborhood name to search...';

  @override
  String get areYouSureYouWantToUnblockThisCustomer =>
      'Are you sure you want to unblock this customer?';

  @override
  String get noCustomersMatchYourSearch => 'No customers match your search';

  @override
  String get searchbyBookingIdnameTechnician =>
      'Search by Booking ID, Name, Technician';

  @override
  String get block => 'Block';

  @override
  String get days => 'Days';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get startDate => 'Start Date';

  @override
  String get cancelledOn => 'Cancelled On';

  @override
  String get endDate => 'End Date';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get unblock => 'Unblock';

  @override
  String get whatsappNumber => 'WhatsApp Number';

  @override
  String get whatsappCondition =>
      'Please ensure the phone number you enter includes the country code at the beginning with a plus sign. This format is required for WhatsApp to recognize the number correctly.';

  @override
  String get rewards => 'Rewards';

  @override
  String get contactNotFound => 'Contact not found';

  @override
  String get keepBooking => 'Keep Booking';

  @override
  String get orderCancelledSuccessfully => 'Order cancelled successfully';

  @override
  String get failedToCancelOrder => 'Failed to cancel order';

  @override
  String get accept => 'Accept';

  @override
  String get excellent => 'Excellent';

  @override
  String get good => 'Good';

  @override
  String get average => 'Average';

  @override
  String get poor => 'Poor';

  @override
  String get selected => 'Selected';

  @override
  String get selectAll => 'Select All';

  @override
  String get cancelledBy => 'Cancelled By';

  @override
  String get pleaseEnterInspectionFeeAmount =>
      'Please enter inspection fee amount';

  @override
  String get rejectBooking => 'Reject Booking';

  @override
  String get pleaseuploadpaymentproof => 'Please upload payment proof';

  @override
  String get iban => 'IBAN';

  @override
  String get tapToUpload => 'Tap to upload proof image/file';

  @override
  String get selectSource => 'Select Source';

  @override
  String get areYouSureYouWantToRejectThisBooking =>
      'Are you sure you want to reject this booking?';

  @override
  String get acceptBooking => 'Accept Booking';

  @override
  String get requestPayout => 'Request Payout';

  @override
  String get lastTip => 'Last Tip';

  @override
  String get paymentBreakdown => 'Payment Breakdown';

  @override
  String get cashPayments => 'Cash Payments';

  @override
  String get cardPayments => 'Card Payments';

  @override
  String get asOf => 'As of';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String get pleaseEnterAValidAmount => 'Please enter a valid amount';

  @override
  String get amountExceedsAvailableBalance =>
      'Amount exceeds available balance';

  @override
  String get cashPaymentsAreAlreadyWithYou =>
      'Cash payments are already with you';

  @override
  String get amount => 'Amount';

  @override
  String get availableForPayout => 'Available for Payout';

  @override
  String get theAdminWillProcessYourRequestWithin2to3days =>
      'The admin will process your request within 2 - 3 business days.';

  @override
  String get availableBalance => 'Available Balance';

  @override
  String get areYouSureYouWantToAcceptThisBooking =>
      'Are you sure you want to accept this booking?';

  @override
  String get cancelledByCustomer => 'Cancelled by Customer';

  @override
  String get bookingDetails => 'Booking Details';

  @override
  String get confirmCancellation => 'Confirm Cancellation';

  @override
  String get adminCancelWarning =>
      'Are you sure you want to cancel this booking? The customer will be notified. Cancelling this booking will not refund the customer automatically. Please ensure to process any necessary refunds manually.';

  @override
  String get atleastOneContactIsrequired => 'At least one contact is required';

  @override
  String get cannotRemovePrimaryStatusFromTheOnlyContact =>
      'Cannot remove primary status from the only contact';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get payoutAccounts => 'Payout Accounts';

  @override
  String get noPayoutAccountsAdded => 'No payout accounts added';

  @override
  String get imageIsTooLargePleaseSelectAnImageSmallerThan5MB =>
      'Image is too large. Please select an image smaller than 5 MB';

  @override
  String get managePayouts => 'Manage Payouts';

  @override
  String get requestedOn => 'Requested on';

  @override
  String get selectedFileCouldNotBeFound =>
      'Selected file could not be found. Please try again.';

  @override
  String get errorPickingImage => 'Error picking image';

  @override
  String get errorCroppingImage => 'Error cropping image';

  @override
  String get technicianInformation => 'Technician Information';

  @override
  String get noPayoutRequestsYet => 'No payout requests yet';

  @override
  String get reviews => 'Reviews';

  @override
  String get payoutHistory => 'Payout History';

  @override
  String get searchByTechnicianNameOrAmount =>
      'Search by technician name or amount...';

  @override
  String get tipDetails => 'Tip Details';

  @override
  String get tipsSummary => 'Tips Summary';

  @override
  String get noPayoutHistoryAvailable => 'No payout history available';

  @override
  String get smsRetrievalTimedOut =>
      'SMS retrieval timed out. Please check if you received the code or try again.';

  @override
  String get payoutRequirement =>
      'To request a tip payout, you\'ll need at least 10 SAR available for payout.';

  @override
  String get notEnoughBalanceforRequestingTipPayout =>
      'Not enough balance to request a tip payout';

  @override
  String get cashTips => 'Outside App Tips';

  @override
  String get cardTips => 'Inside App Tips';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get inHand => 'In Hand';

  @override
  String get errorLoadingReviews => 'Error loading reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get reviewsWillAppearHereAfterCustomersRateYourService =>
      'Reviews will appear here after customers rate your service';

  @override
  String get approved => 'Approved';

  @override
  String get total => 'Total';

  @override
  String get failedToLoadVideo => 'Failed to load video';

  @override
  String get payoutAmount => 'Payout Amount';

  @override
  String get bankAccountDetails => 'Bank Account Details';

  @override
  String get approve => 'Approve';

  @override
  String get rejectPayout => 'Reject Payout';

  @override
  String get payoutApproved => 'Payout Approved';

  @override
  String get approvePayout => 'Approve Payout';

  @override
  String get fileRequired => 'File is required';

  @override
  String get transactionNumberRequired => 'Transaction number is required';

  @override
  String get viewAndManageEarnings => 'View and manage earnings';

  @override
  String get supportedFormats => 'Supported formats:';

  @override
  String get lifetimeTips => 'Lifetime Tips';

  @override
  String get pleaseProvideTransactionDetails =>
      'Please provide transaction details to approve this payout request.';

  @override
  String get pdfImageOrDocument => 'PDF, Image, or Document';

  @override
  String get tapToSelectFile => 'Tap to select file';

  @override
  String get lifetimeEarnings => 'Lifetime Earnings';

  @override
  String get uploadProof => 'Upload Proof';

  @override
  String get notenoughtipstorequestpayoutminSAR10 =>
      'Not enough tips to request payout (min SAR 10)';

  @override
  String get requestTipPayout => 'Request Tip Payout';

  @override
  String get errorRequestingPayout => 'Error requesting payout';

  @override
  String get payoutRequestSubmittedSuccessfully =>
      'Payout request submitted successfully';

  @override
  String get areYouSureYouWantToRequestAPayoutForTheAccumulatedTips =>
      'Are you sure you want to request a payout for the accumulated tips?';

  @override
  String get transactionNumber => 'Transaction Number';

  @override
  String get tipspayoutisdoneseparately => 'Tips payout is done separately';

  @override
  String get pleaseProvideARejectionReason =>
      'Please provide a rejection reason';

  @override
  String get enterTransactionNumber => 'Enter Transaction Number';

  @override
  String get youHaveNoPayoutAccountsgotoprofilesectionandaddanaccount =>
      'You have no payout accounts. Go to profile section and add an account.';

  @override
  String get payoutRejectedSuccessfully => 'Payout rejected successfully';

  @override
  String get payoutRejected => 'Payout Rejected';

  @override
  String get rejectConfirmation =>
      'Are you sure you want to reject this payout request?';

  @override
  String get reason => 'Reason';

  @override
  String get enterTheReason =>
      'Enter the reason for rejecting this payout request';

  @override
  String get payoutRequests => 'Payout Requests';

  @override
  String get status => 'Status';

  @override
  String get noPayoutRequestsFound => 'No payout requests found';

  @override
  String get payoutRequestCancelled => 'Payout request cancelled';

  @override
  String get areYouSureYouWantToCancelThisPayoutRequest =>
      'Are you sure you want to cancel this payout request?';

  @override
  String get addAnAccountToReceivePayments =>
      'Add an account to receive payments';

  @override
  String get addAccount => 'Add Account';

  @override
  String get accountNumber => 'Account Number';

  @override
  String get ifscCode => 'IBAN';

  @override
  String get addFirstAccount => 'Add your first account';

  @override
  String get enterAccountDetails => 'Enter Account Details';

  @override
  String get manageBankAccounts => 'Manage Bank Accounts';

  @override
  String get addAndManageYourPayoutAccounts =>
      'Add and manage your payout accounts';

  @override
  String get updateAccountDetails => 'Update Account Details';

  @override
  String get accountType => 'Account Type';

  @override
  String get primaryAccountUpdated => 'Primary account updated';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete this account?';

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully';

  @override
  String get editAccount => 'Edit Account';

  @override
  String get pleaseEnterAccountNumber => 'Please enter account number';

  @override
  String get accountHolderName => 'Account Holder Name';

  @override
  String get nameMustBeAtLeast3Chars => 'Name must be at least 3 characters';

  @override
  String get pleaseEnterAccountHolderName => 'Please enter account holder name';

  @override
  String get bankName => 'Bank Name';

  @override
  String get updateAccount => 'Update Account';

  @override
  String get setPrimary => 'Set Primary';

  @override
  String get accountAddedSuccessfully => 'Account added successfully';

  @override
  String get accountUpdatedSuccessfully => 'Account updated successfully';

  @override
  String get savings => 'Savings';

  @override
  String get enterAccountHolderName => 'Enter Account Holder Name';

  @override
  String get enterifscCode => 'Enter IBAN';

  @override
  String get enterBankName => 'Enter Bank Name';

  @override
  String get enterAccountNumber => 'Enter Account Number';

  @override
  String get setAsPrimaryAccount => 'Set as Primary Account';

  @override
  String get pleaseEnterBankName => 'Please enter bank name';

  @override
  String get pleaseEnterIfscCode => 'Please enter IBAN';

  @override
  String get copyId => 'Copy ID';

  @override
  String get notSelected => 'Not selected';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get refresh => 'Refresh';

  @override
  String get loadingCustomers => 'Loading customers';

  @override
  String get processing => 'Processing';

  @override
  String get allReviews => 'All Reviews';

  @override
  String get service => 'Service';

  @override
  String get ratingDistribution => 'Rating Distribution';

  @override
  String get payoutRequestSuccessful => 'Payout request successful';

  @override
  String get rejectedBy => 'Rejected by';

  @override
  String get rejectedOn => 'Rejected on';

  @override
  String get acceptedOn => 'Confirmed on';

  @override
  String get acceptedBy => 'Confirmed by';

  @override
  String get completedOn => 'Completed on';

  @override
  String get completedBy => 'Completed by';

  @override
  String get confirmDetails => 'Confirm Details';

  @override
  String get loadingCategories => 'Loading categories...';

  @override
  String get pleaseUploadFiles => 'Please upload files';

  @override
  String get confirmCompletion => 'Confirm Completion';

  @override
  String get uploadFilesTitle => 'Proof of Completion / Supporting Documents';

  @override
  String get uploadHint =>
      'Upload a photo or bill showing completed work or purchased items';

  @override
  String get pleaseUploadFilesMessage =>
      'Please upload atleast one proof of completion / supporting document';

  @override
  String get confirmCompletionMessage =>
      'Are you sure you want to confirm completion of this booking?';

  @override
  String get cannotCancel =>
      'Cannot cancel this booking while tracking is active. Please stop tracking first, then you can cancel the booking.';

  @override
  String get cannotCompleteBookingWhileTracking =>
      'Cannot complete this work while tracking is active. Please stop tracking first, then you can complete the work.';

  @override
  String get editSelection => 'Edit Selection';

  @override
  String get noRecipientsSelected => 'No recipients selected';

  @override
  String get apply => 'Apply';

  @override
  String get tapToUploadFiles => 'Tap to upload files';

  @override
  String get addRecipients => 'Add Recipients';

  @override
  String get serviceItemsCalculationNote =>
      'The total cost will be calculated automatically as (Quantity Ã— Price) for each item and added to the inspection fee.';

  @override
  String get addMoreFiles => 'Add more files';

  @override
  String get allowedFileTypes =>
      'Allowed file types: jpg, jpeg, png, pdf, doc,';

  @override
  String get uploadFileOrImage => 'Upload File or Image';

  @override
  String get pendingReview => 'PENDING REVIEW';

  @override
  String get uploadFiles => 'Upload Files';

  @override
  String get filesAttached => 'Files attached';

  @override
  String get costBreakdown => 'Cost Breakdown';

  @override
  String get removeItem => 'Remove Item';

  @override
  String get removeItemConfirmation =>
      'Are you sure you want to remove this item?';

  @override
  String get remove => 'Remove';

  @override
  String get noBannersAAddedYet => 'No banners added yet';

  @override
  String get availableRoles => 'Available Roles';

  @override
  String get fifteenpercentBonusOnEarningsandASpecialBadge =>
      '15% Bonus on Earnings + Special Badge';

  @override
  String get tenpercentBonusOnEarnings => '10% Bonus on Earnings';

  @override
  String get fivepercentBonusOnEarnings => '5% Bonus on Earnings';

  @override
  String get invalidAccountNumberLength => 'Invalid account number length';

  @override
  String doneSelectedCount(int count) {
    return 'Done ($count selected)';
  }

  @override
  String technicianSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count technicians selected',
      one: '1 technician selected',
      zero: 'No technicians selected',
    );
    return '$_temp0';
  }

  @override
  String payoutRequestSuccessfulMessage(String amount) {
    return '\'Payout request for SAR \$$amount submitted\',';
  }

  @override
  String cashPaymentsMessage(String amount) {
    return 'Cash payments (SAR \$$amount) are already with you';
  }

  @override
  String cannotDeleteLastContact(String contactType) {
    return 'Cannot delete the last $contactType contact. At least one contact is required.';
  }

  @override
  String get personalInfo => 'Personal information';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get locationError => 'Location Error';

  @override
  String get locationServicesIos =>
      'This is an iOS location permission error. Please check your location settings.';

  @override
  String get locationServices =>
      'Please enable location services in your device settings.';

  @override
  String get locationPermission =>
      'Please grant location permission in Settings and select \"Allow all the time\" for background tracking.';

  @override
  String get batteryOptimizationWarning =>
      'For reliable background location tracking, please disable battery optimization for this app. This ensures location updates continue even when the app is in the background.';

  @override
  String get bookingHistory => 'Booking history';

  @override
  String get pleaseSelectAtLeastOneRecipient =>
      'Please select at least one recipient';

  @override
  String get fillInAtLeastEnglishOrArabicMessageContent =>
      'Please fill in at least English or Arabic message content';

  @override
  String get searchByNameEmailOrPhone => 'Search by name, email, or phone...';

  @override
  String get noFcmTokenAvailable => 'No FCM token available';

  @override
  String get selectRecipients => 'Select Recipients';

  @override
  String get removeAll => 'Remove All';

  @override
  String get documents => 'Uploaded documents';

  @override
  String get allData => 'All associated data';

  @override
  String get networkError => 'Network Error';

  @override
  String get biometricEnabled => 'Biometric authentication enabled';

  @override
  String get biometricDisabled => 'Biometric authentication disabled';

  @override
  String get disableBiometricWarning =>
      'Disabling biometric authentication will prevent you from logging in using fingerprint.';

  @override
  String get youWillNeedPhoneOtp =>
      'You will need to use your phone number and OTP to login.';

  @override
  String get whatWillBeDeleted => 'What will be deleted:';

  @override
  String get disable => 'Disable';

  @override
  String get disableBiometric => 'Disable Biometric?';

  @override
  String get optional => 'Optional';

  @override
  String get province => 'Province';

  @override
  String get pleaseSelectCity => 'Please select city';

  @override
  String get pleaseSelectGovernorate => 'Please select governorate';

  @override
  String get governorate => 'Governorate';

  @override
  String get neighborhood => 'Neighborhood';

  @override
  String get pleaseSelectNeighborhood => 'Please select neighborhood';

  @override
  String get pleaseSelectProvince => 'Please select province';

  @override
  String get otpExpired => 'OTP expired';

  @override
  String get invalidOTP => 'Invalid OTP';

  @override
  String get invalidPhoneNumber => 'Invalid phone number';

  @override
  String get otpSentSuccessfully => 'OTP sent successfully';

  @override
  String get otpCode => 'OTP Code';

  @override
  String get registerAsTechinicianInfo =>
      'Register your phone number to create a technician account';

  @override
  String get phoneAlreadyRegistered => 'Phone already registered';

  @override
  String get invalidOtpCode => 'Invalid OTP code';

  @override
  String get quotaExceeded => 'Quota exceeded';

  @override
  String get internalError => 'Internal error';

  @override
  String get resend => 'Resend';

  @override
  String get or => 'or';

  @override
  String get loginWithBiometric => 'Login with biometric';

  @override
  String get migratingData => 'Migrating data';

  @override
  String get weAreMigratingYourData => 'We are migrating your data';

  @override
  String get pleaseDontCloseTheApp => 'Please don\'t close the app';

  @override
  String get transferringData => 'Transferring data';

  @override
  String get fullName => 'Full Name';

  @override
  String get sendingOTP => 'Sending OTP';

  @override
  String get cancelRegistration => 'Cancel Registration';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get didNotReceiveOTP => 'Didn\'t receive OTP?';

  @override
  String get cancelRegistrationConfirmation =>
      'Are you sure you want to cancel registration?';

  @override
  String get registrationSuccessful => 'Registration successful';

  @override
  String get otpMustBe6Digits => 'OTP must be 6 digits';

  @override
  String get pleaseEnterOTP => 'Please enter OTP';

  @override
  String get resendOTP => 'Resend OTP';

  @override
  String get enterReasonForCancel => 'Enter reason for cancellation';

  @override
  String get enterReasonForReject => 'Enter reason for rejection';

  @override
  String get noWarrantyRequests => 'No warranty requests';

  @override
  String get completeWarrantyRepair => 'Complete Warranty Repair';

  @override
  String get areYouSureYouWantToCompleteThisWarrantyRepairThisIsAFreeService =>
      'Are you sure you want to complete this warranty repair? This is a free service.';

  @override
  String get areYouSureYouWantToStopTrackingThisWarrantyRepair =>
      'Are you sure you want to stop tracking this warranty repair?';

  @override
  String get areYouSureYouWantToStartTrackingThisWarrantyRepair =>
      'Are you sure you want to start tracking this warranty repair?';

  @override
  String get anotherBookingIsAlreadyBeingTracked =>
      'Another booking is already being tracked. Please complete or stop the current tracking before starting a new one.';

  @override
  String get requested => 'requested';

  @override
  String
  get areYouSureYouWantToCancelThisWarrantyRepairThisActionCannotBeUndone =>
      'Are you sure you want to cancel this warranty repair? This action cannot be undone.';

  @override
  String get reasonMustBeAtLeast10Characters =>
      'Reason must be at least 10 characters';

  @override
  String get cancelWarrantyRepair => 'Cancel Warranty Repair';

  @override
  String get areYouSureYouWantToDeleteThisFile =>
      'Are you sure you want to delete this file?';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get rejectWarrantyClaimMessage =>
      'Please provide a reason for rejecting this warranty claim';

  @override
  String get invalidPhoneNumberLength => 'Invalid phone number length';

  @override
  String get phoneNumberMustIncludeCountryCode =>
      'Phone number must include country code';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter phone number';

  @override
  String get fileTooLarge => 'File too large (max 10MB)';

  @override
  String get warrantyClaimRejected => 'Warranty claim rejected';

  @override
  String get rejectWarrantyClaim => 'Reject Warranty Claim';

  @override
  String get workCompleted => 'Work Completed';

  @override
  String get resetFilters => 'Reset Filters';

  @override
  String get technician => 'Technician';

  @override
  String get noBankAccountDetailsAvailable =>
      'No bank account details available';

  @override
  String get acceptWarrantyClaim => 'Accept Warranty Claim';

  @override
  String get areYouSureYouWantToRejectThisWarrantyClaim =>
      'Are you sure you want to reject this warranty claim?';

  @override
  String get acceptWarrantyClaimMessage =>
      'Do you want to accept this warranty claim?';

  @override
  String get completeWorkMessage =>
      'Are you sure you want to mark this warranty work as completed?';

  @override
  String get startWorkMessage =>
      'Are you ready to start working on this warranty claim?';

  @override
  String get stopTrackingMessage =>
      'Do you want to stop tracking for this warranty work?';

  @override
  String get warrantyClaimCancelled => 'Warranty claim cancelled';

  @override
  String get cancelWarrantyClaim => 'Cancel Warranty Claim';

  @override
  String get cancelWork => 'Cancel Work';

  @override
  String get cancelWarrantyClaimMessage =>
      'Please provide a reason for cancelling this warranty work';

  @override
  String get cropDocument => 'Crop Document';

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get completeRegistration => 'Complete Registration';

  @override
  String get chooseFromList => 'Choose from list';

  @override
  String get nameTooShort => 'Name too short';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get uploadCertifications => 'Upload Certifications';

  @override
  String get certifications => 'Certifications';

  @override
  String get certificate => 'Certificate';

  @override
  String get idDocumentUploaded => 'ID document uploaded';

  @override
  String get uploadIdDocument => 'Upload ID document';

  @override
  String get idDocument => 'ID Document';

  @override
  String get pleaseUploadIdDocument => 'Please upload ID document';

  @override
  String get pleaseSelectLocation => 'Please select location';

  @override
  String get creatingAccount => 'Creating Your Account';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get noJobCategoriesAvailable => 'No job categories available';

  @override
  String get availabilityStatus => 'Availability Status';

  @override
  String get youAreNowOnline => 'You are now online';

  @override
  String get leaveOffForInspectionOnly =>
      ' (Leave OFF for inspection only, or turn ON for repair details)';

  @override
  String get youAreNowOffline => 'You are now offline';

  @override
  String get youAreCurrentlyUnavailable =>
      'You are currently unavailable for requests';

  @override
  String get youAreAvailableForRequests => 'You are available for requests';

  @override
  String get files => 'Files';

  @override
  String get enableFullServiceAndRepair => 'Enable Full Service & Repair';

  @override
  String get phoneNumberAlreadyUpdated => 'Phone number already updated';

  @override
  String get phoneNumberFormatHint => 'Phone number must start with 05';

  @override
  String get manageTransactions => 'Manage Transactions';

  @override
  String get noTransactionsFound => 'No transactions found';

  @override
  String get tooManyAttempts => 'Too many attempts';

  @override
  String get cash => 'Cash';

  @override
  String get transactions => 'Transactions';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get pleaseSelectAllLocationFields =>
      'Please select all location fields';

  @override
  String get bookingName => 'Booking Name';

  @override
  String get technicianName => 'Technician Name';

  @override
  String get changeIdDocument => 'Change ID Document';

  @override
  String get notAssigned => 'Not Assigned';

  @override
  String get date => 'Date';

  @override
  String get removeFile => 'Remove File';

  @override
  String get removeFileConfirmation =>
      'Are you sure you want to remove this file?';

  @override
  String get errorSendingNotifications => 'Error sending notifications';

  @override
  String get fillInBothEnglishAndArabicMessageContent =>
      'Please fill in both English and Arabic message content';

  @override
  String notificationSenttoTechnicians(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notification sent to $count technicians.',
      one: 'Notification sent to 1 technician.',
    );
    return '$_temp0';
  }

  @override
  String notificationSenttoCustomers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notification sent to $count customers.',
      one: 'Notification sent to 1 customer.',
    );
    return '$_temp0';
  }

  @override
  String get locationTracking => 'Location Tracking';

  @override
  String get trackingInactive => 'Tracking Inactive';

  @override
  String get trackingActive => 'Tracking Active';

  @override
  String get fix => 'Fix';

  @override
  String get locationTrackingStartedSuccessfully =>
      'Location tracking started successfully';

  @override
  String get locationTrackingHelpText =>
      'Location tracking helps customers track your progress. Make sure to keep location services enabled.';

  @override
  String get batteryOptimizationEnabled =>
      'Battery optimization is enabled. This may affect background location tracking.';

  @override
  String get agentAssignedSuccessfully => 'Technician assigned successfully';

  @override
  String get orderRejectedSuccessfully => 'Order rejected successfully';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get couldNotLaunchPhone => 'Could not launch phone app';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '$count minute ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '$count hour ago',
    );
    return '$_temp0';
  }

  @override
  String get paymentCompletedAt => 'Payment Completed At';

  @override
  String get more => 'More';

  @override
  String get amountToBePaid => 'Amount to be paid';

  @override
  String get cannotRequestPayoutPendingRequest =>
      'You already have a payout request in progress. Please wait until it is approved or rejected';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get customerInformation => 'Customer Information';

  @override
  String get serviceInformation => 'Service Information';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get and => 'and';

  @override
  String get copy => 'Copy';

  @override
  String get introduction => 'Introduction';

  @override
  String get policy1title => 'Data We Collect';

  @override
  String get policy2title => 'How We Use It';

  @override
  String get policy3title => 'Data Sharing';

  @override
  String get terms1title => 'Licenses and Qualifications';

  @override
  String get terms2title => 'Service Quality and Responsibility';

  @override
  String get terms3title => 'Fair Pricing';

  @override
  String get terms4title => 'Platform Commission';

  @override
  String get terms5title => 'Warranty';

  @override
  String get terms6title => 'Legal Liability Limits';

  @override
  String get searchByCustomerName => 'Search by customer name';

  @override
  String get phoneNumberUpdateInfo =>
      'Enter phone number starting with \'05\' for updating phone number';

  @override
  String get termsIntroduction =>
      'Your use of the Application constitutes full and unconditional acceptance of these terms. The Application acts solely as an electronic intermediary platform connecting you with service providers (Technicians).';

  @override
  String get terms1 =>
      'You guarantee that you possess all necessary professional licenses and qualifications to provide the services advertised.';

  @override
  String get terms2 =>
      'You are solely responsible for the quality of the service provided, the tools used, and ensuring the safety of the premises during and after the work.';

  @override
  String get terms3 =>
      'You are committed to providing fair, reasonable, and upfront pricing to the User after inspection.';

  @override
  String get terms4 =>
      'You are committed to paying the pre-agreed commission to the Application, which will be deducted from the value of the completed service.';

  @override
  String get warrantyPolicy => 'Warranty Policy';

  @override
  String get terms6 =>
      'The Application is not responsible for any material damages or injuries resulting from your performance of the service.';

  @override
  String get terms5 =>
      'You are obligated to provide a warranty on the work performed in accordance with the \"Warranty Policy,\" and you bear the cost of repairs falling within the warranty period.';

  @override
  String get policy1 =>
      'Professional license information, qualifications and experience, personal/professional photos, bank account details for payment reception, and rating history.';

  @override
  String get policy2 =>
      'Used to verify your identity and qualifications, process your payments, and display your professional profile to Users (ratings and experience).';

  @override
  String get policy3 =>
      'Your name, professional photo, and ratings are shared with Users. Your bank account information is NOT shared.';

  @override
  String get waitingForAdminAction => 'Waiting for admin action';

  @override
  String get whatsCovered => 'What\'s Covered';

  @override
  String get issueone => 'Faulty installation or poor workmanship';

  @override
  String get issuetwo => 'Substandard performance by technician';

  @override
  String get issuethree => 'Same original fault that was repaired';

  @override
  String get issuefour =>
      'Valid for one time, within 7 days from completion date';

  @override
  String get whatsNotCovered => 'What\'s Not Covered';

  @override
  String get notissueone => 'Defective spare parts or materials';

  @override
  String get notissuetwo => 'Misuse or tampering after service';

  @override
  String get notissuethree => 'Third-party interventions';

  @override
  String get notissuefour => 'Power surges, water leaks, natural disasters';

  @override
  String get notissuefive => 'Normal wear and tear';

  @override
  String get showMore => 'Show More';

  @override
  String get loading => 'Loading...';

  @override
  String get wallet => 'Wallet';

  @override
  String get walletSynced => 'Wallet synced successfully';

  @override
  String get payoutRequested => 'Payout requested successfully';

  @override
  String get balanceBreakdown => 'Balance Breakdown';

  @override
  String get selectAmounts => 'Select Amounts';

  @override
  String get available => 'Available';

  @override
  String get paid => 'Paid';

  @override
  String get tips => 'Tips';

  @override
  String get payoutPending => 'Payout Pending';

  @override
  String get requestedAmount => 'Requested Amount';

  @override
  String get payoutNote =>
      'Note: This request will be sent to admin for approval. The full available balance will be requested.';

  @override
  String get noPayoutRequests => 'No payout requests yet';

  @override
  String get max => 'Max';

  @override
  String get min => 'Min';

  @override
  String get useMax => 'Use Max';

  @override
  String get searchByWorkerName => 'Search by worker name';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get payoutDetails => 'Payout Details';

  @override
  String get workerName => 'Worker Name';

  @override
  String get payoutAccount => 'Payout Account';

  @override
  String get requestDate => 'Request Date';

  @override
  String get rejectionReason => 'Rejection Reason';

  @override
  String get enterTransactionId => 'Enter Transaction ID';

  @override
  String get uploadPaymentProof => 'Upload Payment Proof';

  @override
  String get paymentProof => 'Payment Proof';

  @override
  String get proofUploaded => 'Proof uploaded successfully';

  @override
  String get enterReason => 'Enter reason';

  @override
  String get cancelPayoutConfirmation =>
      'Are you sure you want to cancel this payout request?';

  @override
  String get payoutCancelled => 'Payout request cancelled successfully';

  @override
  String get confirmPayoutRequest =>
      'You are requesting a payout for your total available balance';

  @override
  String get bonusIncludedInWallet =>
      'Bonus is included in your unified wallet. Request payout from Earnings page.';

  @override
  String get claimText =>
      'To claim warranty, submit a request through the app within 7 days from service completion. The warranty can be claimed only once.';

  @override
  String get syncWallet => 'Sync Wallet';

  @override
  String get alreadyInHand => 'already in hand';

  @override
  String get minimumPayoutAmount => 'Minimum payout amount is 10 SAR';

  @override
  String get enableAvailability => 'Enable Availability';

  @override
  String get welcomeDescription =>
      'We are happy to have you join the Abo Glumbo team.\n\nâ€¢ One-week warranty for every service\nâ€¢ Higher ratings increase future selection chances\nâ€¢ Special rewards for high-performing technicians';

  @override
  String welcomeToAboGlumboTechnician(String name) {
    return 'Welcome $name';
  }

  @override
  String get onlyMainAdminCanManageAdminAccess =>
      'Only the main admin can manage admin access';

  @override
  String get cannotModifyMainAdminAccount => 'Cannot modify main admin account';

  @override
  String get adminAccessRevokedFor => 'Admin access revoked for';

  @override
  String get adminAccess => 'Admin Access';

  @override
  String get selectAdminAccessLevelFor => 'Select admin access level for';

  @override
  String get fullAdmin => 'Full Admin';

  @override
  String get customerService => 'Customer Service';

  @override
  String get grantAccess => 'Grant Access';

  @override
  String get grantingAdminAccess => 'Granting admin access';

  @override
  String get adminAccessGrantedTo => 'Admin access granted to';

  @override
  String get revokeAdminAccess => 'Revoke Admin Access';

  @override
  String get revokingAdminAccess => 'Revoking admin access';

  @override
  String get switchToAdmin => 'Switch to Admin';

  @override
  String get manageAdmins => 'Manage Admins';

  @override
  String get searchAdmins => 'Search admins...';

  @override
  String get aboutUs => 'About Us';

  @override
  String get noAdminsFound => 'No Admins Found';

  @override
  String get loadingAdmins => 'Loading Admins...';

  @override
  String get noAdminsMatchYourFilters => 'No Admins Match Your Filters';

  @override
  String get grantedOn => 'Granted On';

  @override
  String get selectRecipientType => 'Select Recipient Type';

  @override
  String get recipientsSelected => 'Recipients Selected';

  @override
  String get areYouSureYouWantToRevokeAdminAccessFor =>
      'Are you sure you want to revoke admin access for';

  @override
  String get onlyTheMainAdminCanRevokeAdminAccess =>
      'Only the main admin can revoke admin access';

  @override
  String get accessToAllAdminFeaturesExceptManagingOtherAdmins =>
      'Access to all admin features except managing other admins';

  @override
  String get viewOnlyAccessToCustomersTechniciansAndSupport =>
      'View only access to customers, technicians and support';

  @override
  String get loginDescription =>
      'Ready to work? Nearby jobs and better income await you.';

  @override
  String get aboutUsTitle => 'About Us';

  @override
  String get aboutUsHeadline =>
      'Your Journey to Professional Growth Starts Here';

  @override
  String get aboutUsIntro =>
      'Join our network of certified technicians and take your next step towards financial independence and professional excellence. We don\'t just offer you a job; we offer you a partner dedicated to ensuring your success.';

  @override
  String get aboutRewardsTitle => 'Your Rewards & Incentives';

  @override
  String get aboutIncentiveTitle => 'Financial Incentive System';

  @override
  String get aboutIncentiveDesc =>
      'Climb through our tiered system (Bronze, Silver, Gold, Platinum). The more jobs you complete and the higher your rating you maintain (4.8+ for Platinum), the higher the bonus percentage you earn (up to 15% bonus).';

  @override
  String get aboutEarningsTitle => 'Transparent Monthly Earnings';

  @override
  String get aboutEarningsDesc =>
      'Track your earned monthly income and easily request your payout using the \"Request Payout\" button.';

  @override
  String get aboutSupportTitle => 'Efficiency & Support';

  @override
  String get aboutFlexibilityTitle => 'Complete Flexibility';

  @override
  String get aboutFlexibilityDesc =>
      'You set your own working hours and the areas you cover. We work to provide you with service requests based on your preferences.';

  @override
  String get aboutNoHuntingTitle => 'Zero Customer Hunting';

  @override
  String get aboutNoHuntingDesc =>
      'Say goodbye to chasing clients. We provide you with ready job requests from reliable customers, ensuring a continuous flow of work.';

  @override
  String get aboutTransparencyTitle => 'Guaranteed Transparency';

  @override
  String get aboutTransparencyDesc =>
      'All service details and pricing are documented in advance, ensuring clarity in all financial dealings between you and the customer.';

  @override
  String locationNumber(int number) {
    return 'Location $number';
  }

  @override
  String get selectedLocation => 'Selected Location';

  @override
  String get mapPickerInstructions =>
      'â€¢ Click \'Add Region\' to start drawing a new area\nâ€¢ Tap on the map to add boundary points (at least 4 points required)\nâ€¢ Click \'Complete Region\' when finished\nâ€¢ Enter location details and confirm\nâ€¢ Use the Edit icon to update details or the Red X to remove an area';

  @override
  String get tapOnMapToDrawPolygonPoints =>
      'Tap on the map to draw polygon points';

  @override
  String get addRegion => 'Add Region';

  @override
  String get regionMustHaveAtLeast4Points =>
      'A region must have at least 4 points to be completed.';

  @override
  String completeRegionWithPts(int count) {
    return 'Complete Region ($count pts)';
  }

  @override
  String get clearDrawing => 'Clear Drawing';

  @override
  String get pleaseDrawPolygonFirst => 'Please draw a polygon first';

  @override
  String get pleaseDrawPolygonAreaFirst =>
      'Please draw a polygon area on the map first';

  @override
  String get priority => 'Priority';

  @override
  String get enterPriority => 'Enter priority';

  @override
  String get pleaseEnterPriority => 'Please enter priority';

  @override
  String pointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String locationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count locations selected',
      one: '$count location selected',
    );
    return '$_temp0';
  }

  @override
  String get addCurrentLocation => 'Add Current Location';

  @override
  String get howToUse => 'How to use';

  @override
  String get searchForAPlace => 'Search for a place';

  @override
  String get myLocation => 'My Location';

  @override
  String get noLocationSelected => 'No Location Selected';

  @override
  String get tapOnMapToSelect => 'Tap on map to select';

  @override
  String get confirmLocations => 'Confirm Locations';

  @override
  String get radius => 'Radius';

  @override
  String get locationAlreadyAdded => 'Location already added';

  @override
  String get locationAddedToList => 'Location added to list';

  @override
  String get locationNotFound => 'Location not found';

  @override
  String get errorFindingLocation => 'Error finding location';

  @override
  String get editLocation => 'Edit Location';

  @override
  String get addLocation => 'Add Location';

  @override
  String get englishName => 'English Name';

  @override
  String get pleaseEnterEnglishName => 'Please enter English name';

  @override
  String get arabicName => 'Arabic Name';

  @override
  String get pleaseEnterArabicName => 'Please enter Arabic name';

  @override
  String get pleaseEnterArabicNameOnly => 'Please enter Arabic name only';

  @override
  String get radiusInMeters => 'Radius in meters';

  @override
  String get enterRadiusInMeters => 'Enter radius in meters';

  @override
  String get meters => 'meters';

  @override
  String get pleaseEnterRadius => 'Please enter radius';

  @override
  String get addArea => 'Add Area';

  @override
  String get gettingAddress => 'Getting address...';

  @override
  String get serviceRadius => 'Service Radius';

  @override
  String get km => 'km';

  @override
  String get tapOnMapOrSearchToAddLocations =>
      'Tap on map or search to add locations';

  @override
  String get selectedLocations => 'Selected Locations';

  @override
  String get profileSentForVerification =>
      'Your Profile has been sent for Verification!';

  @override
  String get verificationPending => 'Verification Pending';

  @override
  String get waitingForTechnicianVerification =>
      'Waiting for technician to verify payment';

  @override
  String get verifyPayment => 'Verify Payment';

  @override
  String get confirmPaymentReceipt => 'Confirm Payment Receipt';

  @override
  String get uploadTechnicianPaymentProof => 'Upload Technician Payment Proof';

  @override
  String get paymentVerifiedSuccessfully => 'Payment verified successfully';

  @override
  String get selectFiles => 'Select Files';

  @override
  String get pleaseSelectAtLeastOneFile => 'Please select at least one file';

  @override
  String get errorUploading => 'Error uploading';

  @override
  String get warranty => 'Warranty';

  @override
  String get warrantyAppliedOn => 'Warranty applied on';

  @override
  String get bookingIdCopied => 'Booking ID Copied';

  @override
  String get selectTime => 'Select Time';

  @override
  String get submitCounterOffer => 'Submit a New Offer';

  @override
  String get pleaseSelectALaterTime =>
      'Please select a time later than the current booking time';

  @override
  String get listeningForSms => 'Listening for SMS...';

  @override
  String get earningsInfoOnly => 'For informational purposes only';

  @override
  String get throughApp => 'Through App';

  @override
  String get rebookTechnician => 'Rebooking';

  @override
  String get selectService => 'Select Service';

  @override
  String get rejectionProfessionalMessage =>
      'If you are unavailable at the requested time, please propose an alternative date and time to the customer instead of canceling the appointment.';

  @override
  String get proposeAlternativeTime => 'Propose New Time';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get notes => 'Notes';

  @override
  String get time => 'Time';

  @override
  String get appointmentDetails => 'Appointment Details';

  @override
  String get residenceIDImage => 'Residence ID Image';

  @override
  String get sponsorWorkPermit => 'Sponsor Work Permit';

  @override
  String get chamberOfCommerceApproval => 'Chamber of Commerce Approval';

  @override
  String get certificatesOrTrainingCoursesOptional =>
      'Certificates or Training Courses (Optional)';

  @override
  String get uploadCertificates => 'Upload Certificates';

  @override
  String get refreshLocation => 'Refresh Location';

  @override
  String get selectJobRolesDescription =>
      'Choose the services you are qualified to provide.';

  @override
  String get updateDocuments => 'Update Documents';

  @override
  String get pleaseSelectAtLeastOneDocumentToUpdate =>
      'Please remove and select new file for atleast one of the documents to re-upload';

  @override
  String reuploadFailed(String error) {
    return 'Re-upload failed: $error';
  }

  @override
  String get selectFile => 'Select File';

  @override
  String get accountBlocked => 'Account Blocked';

  @override
  String get accountBlockedMessage =>
      'Your account has been blocked by the admin. Please contact support for more information.';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get applicationRejected => 'Application Rejected';

  @override
  String get applicationRejectedMessage =>
      'Unfortunately, your application has been rejected after review. You can see the reason below and update your documents to try again.';

  @override
  String get reasonForRejection => 'Reason for rejection:';

  @override
  String get noReasonProvided => 'No reason provided';

  @override
  String get failedResendOtp => 'Failed to resend OTP. Please try again.';

  @override
  String get verificationIdNotFound =>
      'Verification ID not found. Please try again.';

  @override
  String get pleaseFetchLocation => 'Please fetch your current location';

  @override
  String get pleaseSelectRole => 'Please select at least one job role';

  @override
  String get pleaseUploadDocuments => 'Please upload all mandatory documents';

  @override
  String get revokeAccess => 'Revoke Access';

  @override
  String get coreAdminCannotRemove => 'Core admin cannot be removed.';

  @override
  String get onlyCoreAdminCanAdd => 'Only the core admin can add new admins.';

  @override
  String get adminAddedSuccessfully =>
      'Admin added successfully to pending invites.';

  @override
  String get failedUpdateTechStatus => 'Failed to update technician status';

  @override
  String get offerAcceptedSuccessfully => 'Offer accepted successfully';

  @override
  String get failedToSendCounter => 'Failed to send counter offer';

  @override
  String get couldNotLaunchEmail => 'Could not launch email client';

  @override
  String get couldNotLaunchWhatsapp => 'Could not launch WhatsApp';

  @override
  String get cancelLower => 'Cancel';

  @override
  String get invited => 'INVITED';

  @override
  String get accessLevelUpper => 'ACCESS LEVEL';

  @override
  String get phoneUpper => 'PHONE';

  @override
  String get invoiceTitle => 'Service Booking Invoice';

  @override
  String get invoiceWord => 'INVOICE';

  @override
  String get statusPaid => 'Status: PAID';

  @override
  String get billTo => 'BILL TO:';

  @override
  String get bookingDetailsInvoice => 'BOOKING DETAILS:';

  @override
  String get subtotal => 'Subtotal:';

  @override
  String get inspectionFeeLabel => 'Inspection Fee:';

  @override
  String get totalLabel => 'Total:';

  @override
  String get thankYouInvoice => 'Thank you for choosing Abo Glumbo!';

  @override
  String invoiceNumber(String number) {
    return 'Invoice #: $number';
  }

  @override
  String dateString(String date) {
    return 'Date: $date';
  }

  @override
  String serviceLabel(String name) {
    return 'Service: $name';
  }

  @override
  String completedAtLabel(String date) {
    return 'Completed At: $date';
  }

  @override
  String paymentModeLabel(String mode) {
    return 'Payment Mode: $mode';
  }

  @override
  String transactionIdLabel(String id) {
    return 'Transaction ID: $id';
  }

  @override
  String warrantyLabel(String duration) {
    return 'Warranty: $duration';
  }

  @override
  String sarAmount(String amount) {
    return '$amount SAR';
  }

  @override
  String get onHour => 'Working Hours';

  @override
  String get offHour => 'Outside Working Hours';

  @override
  String get inAppEarnings => 'In-App Earnings';

  @override
  String get outsideAppEarnings => 'Outside-App Earnings';

  @override
  String get earningsPeriod => 'Earnings Period';

  @override
  String get selectPeriod => 'Select Period';

  @override
  String get selectMonth => 'Select Month';

  @override
  String get customDateRange => 'Custom Date Range';

  @override
  String get allTime => 'All Time';

  @override
  String get thisMonth => 'This Month';

  @override
  String get inApp => 'In-App';

  @override
  String get clearWalletBalances => 'Clear Wallet Balances';

  @override
  String clearWalletConfirmation(String name) {
    return 'Are you sure you want to completely clear and reset the wallet balances for $name? This action is irreversible.';
  }

  @override
  String errorClearingWallet(String error) {
    return 'Error clearing wallet: $error';
  }

  @override
  String get bookingDate => 'Booking Date';

  @override
  String get yourAccountIsBeingVerified =>
      'Your account is being verified by the admin. Please check back later.';

  @override
  String get aboGlumboWorker => 'Abo Glumbo Technician';

  @override
  String get workerCannotBeAssignedMultipleTimes =>
      'The same technician cannot be assigned to more than one booking at the same time. Please choose a different time or another technician.';

  @override
  String get unknownWorker => 'Unknown Technician';

  @override
  String get workerCancelled => 'Booking was cancelled by the technician';

  @override
  String get cancelledByWorker => 'Cancelled by Technician';

  @override
  String get workerPreviouslyCancelled => 'Technician previously cancelled';

  @override
  String get workerCancelledAtTime =>
      'This technician previously cancelled a booking at the same time. It is recommended to assign another technician for better reliability.';

  @override
  String get workerRestrictedTitle => 'Technician Restricted';

  @override
  String get cannotAssignCancelledWorker =>
      'Cannot assign a technician who previously cancelled';

  @override
  String get workerCancelledRestrictionMessage =>
      'This technician previously cancelled a booking and is now restricted from new assignments. Please choose a different technician.';

  @override
  String get managefaqs => 'Manage FAQs';

  @override
  String get manageWorkers => 'Manage Technicians';

  @override
  String get noWorkersMatchYourFilters =>
      'No technicians match your search criteria';

  @override
  String get workerInformation => 'Technician Information';

  @override
  String get loadingWorkers => 'Loading Technicians...';

  @override
  String get serviceDeletedSuccessfully => 'Service deleted successfully';

  @override
  String get netTechnicianror => 'An error occurred while loading technicians';

  @override
  String get urdu => 'Urdu';

  @override
  String errorOccurred(String error) {
    return 'Error: $error';
  }

  @override
  String cannotOpenFile(String path) {
    return 'Cannot open file: $path';
  }

  @override
  String failedToSendMessage(String error) {
    return 'Failed to send message: $error';
  }

  @override
  String failedToRetryMessage(String error) {
    return 'Failed to retry message: $error';
  }

  @override
  String errorFetchingLocation(String error) {
    return 'Error fetching location: $error';
  }

  @override
  String confirmRemoveAdmin(String name) {
    return 'Are you sure you want to remove admin access for $name?';
  }

  @override
  String adminAccessRevoked(String name) {
    return 'Admin access revoked for $name';
  }

  @override
  String inviteDeleted(String name) {
    return 'Invite deleted for $name';
  }

  @override
  String get biometricError => 'âŒ Biometric error';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get errorDuringLogin => 'Error during login';

  @override
  String get filterAll => 'All';

  @override
  String get coreAdmin => 'Core Admin';

  @override
  String get addAdmin => 'Add Admin';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get addNewAdmin => 'Add New Admin';

  @override
  String get editAdmin => 'Edit Admin';

  @override
  String get enterAdminDetails =>
      'Enter admin details to invite them to the platform.';

  @override
  String get editAdminDetails => 'Edit admin details and access level.';

  @override
  String get adminUpdatedSuccessfully => 'Admin updated successfully.';

  @override
  String get adminPhoneExists => 'Admin with this phone number already exists.';

  @override
  String get adminPhoneInvited =>
      'Admin with this phone number is already invited.';

  @override
  String get enterFullName => 'Enter full name';

  @override
  String get pleaseEnterName => 'Please enter name';

  @override
  String get enterEmailAddress => 'Enter email address';

  @override
  String get egPhoneNumber => 'e.g. +9665XXXXXXXX';

  @override
  String get accessLevelTitle => 'Access Level';

  @override
  String get customerServiceOnly => 'Customer Service Only';

  @override
  String get customerServiceDesc =>
      'View only access to bookings and manage sections.';

  @override
  String get fullAdminAccess => 'Full Admin Access';

  @override
  String get fullAdminDesc => 'Full access except management of other admins.';

  @override
  String get phoneNoteWithCountryCode =>
      '(enter phone number along with country code example : +966)';

  @override
  String get selectNewDateAppointment =>
      'Select a new date and time for the appointment';

  @override
  String get notAvailable => 'N/A';

  @override
  String get noAdditionalDescription => 'No additional description';

  @override
  String get distance => 'Distance';

  @override
  String get discountAmount => 'Discount Amount';

  @override
  String get discountAppliesToInspectionFeeOnly =>
      'Discount applies to the inspection fee only.';

  @override
  String discountApplied(num percentageamount) {
    final intl.NumberFormat percentageamountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentageamountString = percentageamountNumberFormat.format(
      percentageamount,
    );

    return '$percentageamountString% discount';
  }

  @override
  String get escalated => 'Pending Admin Review';

  @override
  String get resolveIssue => 'Resolve Issue';

  @override
  String get whatWasDoneToResolve => 'What was done to resolve the issue?';

  @override
  String get resolutionTextRequired => 'Resolution text is required';

  @override
  String get urduName => 'Urdu Name';

  @override
  String get enterUrduName => 'Enter Urdu name';

  @override
  String get pleaseEnterUrduName => 'Please enter Urdu name';

  @override
  String get pleaseEnterUrduNameOnly => 'Please enter Urdu name only';

  @override
  String get searchForZones => 'Search for zones';

  @override
  String get failedToSearchForZones =>
      'Failed to search for zones. Please try again.';

  @override
  String get zoneNameAlreadyExists => 'Zone name already exists';

  @override
  String get zoneType => 'Zone Type';

  @override
  String get rejected => 'REJECTED';

  @override
  String get waitingTechnicianToVerifyDocuments =>
      'Waiting technician to verify documents';

  @override
  String get workerCancelledThisBooking => 'Worker cancelled this booking';

  @override
  String get workerCancelledNearby => 'Worker cancelled nearby';

  @override
  String get busyAtThisTime => 'Busy at this time';

  @override
  String get revenueFilter7Days => '7 Days';

  @override
  String get revenueFilter30Days => '30 Days';

  @override
  String get revenueFilter6Months => '6 Months';

  @override
  String get revenueFilter12Months => '12 Months';

  @override
  String get revenueFilterCustomRange => 'Custom Range...';

  @override
  String get nearby20km => 'Nearby (20km)';
}
