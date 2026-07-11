// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get assign => 'تفویض کریں';

  @override
  String get later => 'بعد میں';

  @override
  String get change => 'تبدیل کریں';

  @override
  String get viewOnly => 'صرف ایڈمن کے دیکھنے کے لیے';

  @override
  String get noTechnicianAssigned => 'کوئی ٹیکنیشن تفویض نہیں کیا گیا';

  @override
  String get calculatingDistance => 'فاصلہ کا حساب لگایا جا رہا ہے...';

  @override
  String get awaitingCustomerAction => 'گاہک کے اگلے اقدامات کا انتظار ہے';

  @override
  String kmAway(Object distance) {
    return '$distance کلومیٹر دور';
  }

  @override
  String get appName => 'ابو جلمبو';

  @override
  String get enterYourFullName => 'اپنا پورا نام درج کریں';

  @override
  String get pleaseEnterYourFullName => 'براہ کرم اپنا پورا نام درج کریں';

  @override
  String get onlineStatusOn => 'اب آپ آن لائن ہیں';

  @override
  String get fullNameIsRequired => 'پورا نام ضروری ہے';

  @override
  String get enterYourEmail => 'اپنا ای میل درج کریں';

  @override
  String get onlineStatusOff => 'اب آپ آف لائن ہیں';

  @override
  String get errorUpdatingStatus => 'اسٹیٹس اپ ڈیٹ کرنے میں خرابی';

  @override
  String get appLoginCaption =>
      'کوالٹی پروفیشنلز تلاش کرنے کے لیے آپ کی پسندیدہ ایپ۔';

  @override
  String get mobileNumber => 'موبائل نمبر';

  @override
  String get continueText => 'جاری رکھیں';

  @override
  String get byContinuingYouAgreeToOur => 'جاری رکھ کر آپ ہمارے اس سے متفق ہیں';

  @override
  String get termsOfUseAndPrivacyPolicy =>
      ' استعمال کی شرائط اور رازداری کی پالیسی';

  @override
  String get rememberMe => 'مجھے یاد رکھیں';

  @override
  String get login => 'لاگ ان کریں';

  @override
  String get monthlyRevenue => 'ماہانہ آمدنی';

  @override
  String get admins => 'ایڈمنز';

  @override
  String get banners => 'بینرز';

  @override
  String get customers => 'صارفین';

  @override
  String get technicians => 'ٹیکنیشنز';

  @override
  String get payouts => 'ادائیگیاں';

  @override
  String get faqs => 'سوالات';

  @override
  String get totalPayoutAmount => 'کل ادائیگی کی رقم';

  @override
  String get reviewPayoutDetails => 'ادائیگی کی تفصیلات کا جائزہ لیں';

  @override
  String get manageOrders => 'آرڈرز کا انتظام کریں';

  @override
  String get refreshStatus => 'اسٹیٹس ریفریش کریں';

  @override
  String get signOut => 'سائن آؤٹ';

  @override
  String get rejectOrder => 'آرڈر مسترد کریں';

  @override
  String get areYouSureYouWantToRejectThisOrder =>
      'کیا آپ واقعی اس آرڈر کو مسترد کرنا چاہتے ہیں؟';

  @override
  String get loadingAgents => 'ٹیکنیشنز لوڈ ہو رہے ہیں...';

  @override
  String get bonusCardDesc =>
      'حاصل کردہ بونس ادائیگی کے لیے آپ کے بٹوے میں شامل کیا جائے گا۔';

  @override
  String get noReview => 'کوئی تبصرہ نہیں';

  @override
  String get areYouSureYouWantToAcceptThisNewTime =>
      'کیا آپ واقعی اس نئے وقت کو قبول کرنا چاہتے ہیں؟';

  @override
  String get reject => 'مسترد کریں';

  @override
  String get walletBalance => 'بٹوے کا بیلنس';

  @override
  String get tip => 'ٹپ';

  @override
  String get availableToWork => 'کام کے لیے دستیاب';

  @override
  String get notAvailableToWork => 'کام کے لیے دستیاب نہیں';

  @override
  String get choose => 'منتخب کریں';

  @override
  String get availableLocations => 'دستیاب مقامات';

  @override
  String get workHoursPricing => 'کام کے اوقات کی قیمتیں';

  @override
  String get workStartTime => 'کام شروع ہونے کا وقت';

  @override
  String get workEndTime => 'کام ختم ہونے کا وقت';

  @override
  String get onWorkPrice => 'کام کے دوران کی قیمت';

  @override
  String get offWorkPrice => 'کام کے بعد کی قیمت';

  @override
  String get generalPrice => 'عام قیمت';

  @override
  String get chooseLocations => 'مقامات منتخب کریں';

  @override
  String get pleaseEnterAnOnWorkPrice =>
      'براہ کرم کام کے دوران کی قیمت درج کریں';

  @override
  String get pleaseEnterOffWorkPrice => 'براہ کرم کام کے بعد کی قیمت درج کریں';

  @override
  String get pleaseEnterAGeneralPrice => 'براہ کرم عام قیمت درج کریں';

  @override
  String get grantAdminAccess => 'ایڈمن رسائی دیں';

  @override
  String get adminAccessManagement => 'ایڈمن رسائی کا انتظام';

  @override
  String get searchByBookingId => 'بکنگ آئی ڈی سے تلاش کریں';

  @override
  String get rejectingOrder => 'آرڈر مسترد کیا جا رہا ہے';

  @override
  String get failedToRejectOrder => 'آرڈر مسترد کرنے میں ناکامی';

  @override
  String get assigningBookingTo => 'بکنگ تفویض کی جا رہی ہے';

  @override
  String get failedToAssignBookingTo => 'بکنگ تفویض کرنے میں ناکامی';

  @override
  String get completeOrder => 'آرڈر مکمل کریں';

  @override
  String get areYouSureYouWantToCompleteThisOrder =>
      'کیا آپ واقعی اس آرڈر کو مکمل کرنا چاہتے ہیں؟';

  @override
  String get complete => 'مکمل';

  @override
  String get completingOrder => 'آرڈر مکمل کیا جا رہا ہے';

  @override
  String get failedToCompleteOrder => 'آرڈر مکمل کرنے میں ناکامی';

  @override
  String get yourAccountHasBeenDeactivatedByAdmin =>
      'آپ کا اکاؤنٹ ایڈمن نے غیر فعال کر دیا ہے';

  @override
  String get assignTo => 'تفویض کریں';

  @override
  String get agent => 'ٹیکنیشن';

  @override
  String get assignToUser => 'صارف کو تفویض کریں';

  @override
  String get noAgentsAvailable => 'کوئی ٹیکنیشن دستیاب نہیں';

  @override
  String get scheduledFor => 'کے لیے شیڈول کیا گیا';

  @override
  String get services => 'خدمات';

  @override
  String get highlightedServices => 'نمایاں خدمات';

  @override
  String get manageBanners => 'بینرز کا انتظام کریں';

  @override
  String get confirmDelete => 'حذف کرنے کی تصدیق کریں';

  @override
  String get delete => 'حذف کریں';

  @override
  String get bannerDeleted => 'بینر حذف کر دیا گیا';

  @override
  String get failedToDeleteBanner => 'بینر حذف کرنے میں ناکامی';

  @override
  String get failedToSaveBanner => 'بینر محفوظ کرنے میں ناکامی';

  @override
  String get active => 'فعال';

  @override
  String get showInPrimaryBanner => 'پرائمری بینر میں دکھائیں';

  @override
  String get ifDisabledItWillShowInSecondaryBanner =>
      'اگر غیر فعال ہو تو یہ سیکنڈری بینر میں دکھائے گا';

  @override
  String get pickImage => 'تصویر منتخب کریں';

  @override
  String get upload => 'اپ لوڈ کریں';

  @override
  String get failedToSaveHighlightedService =>
      'نمایاں خدمت محفوظ کرنے میں ناکامی';

  @override
  String get done => 'ہو گیا';

  @override
  String get addService => 'خدمت شامل کریں';

  @override
  String get noServicesSelected => 'کوئی خدمت منتخب نہیں کی گئی';

  @override
  String get failedToSaveService => 'خدمت محفوظ کرنے میں ناکامی';

  @override
  String get failedToCreateService => 'خدمت بنانے میں ناکامی';

  @override
  String get failedToUpdateService => 'خدمت اپ ڈیٹ کرنے میں ناکامی';

  @override
  String get pleaseVerifyYourIqama =>
      'براہ کرم کنفرمیشن باکس چیک کر کے اپنے اقامہ کی تصدیق کریں';

  @override
  String get uploadYourIqama => 'اپنا اقامہ اپ لوڈ کریں';

  @override
  String get locationPermissionsAreDenied => 'مقام کی اجازت مسترد کر دی گئی ہے';

  @override
  String get locationPermissionsArePermanentlyDenied =>
      'مقام کی اجازت مستقل طور پر مسترد کر دی گئی ہے';

  @override
  String get locationPermissionRequired => 'مقام کی اجازت درکار ہے';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'مقام کی اجازت مستقل طور پر مسترد کر دی گئی ہے۔ نوکری کی پیشکشیں حاصل کرنے کے لیے براہ کرم انہیں ایپ کی ترتیبات میں فعال کریں۔';

  @override
  String get pleaseEnableLocationServices =>
      'ٹیکنیشن کے طور پر ایپ کا استعمال جاری رکھنے کے لیے براہ کرم لوکیشن سروسز کو فعال کریں۔';

  @override
  String get fetching => 'حاصل کیا جا رہا ہے...';

  @override
  String get currentGeopoint => 'موجودہ جیو پوائنٹ';

  @override
  String get latitudeLabel => 'عرض بلد';

  @override
  String get longitudeLabel => 'طول بلد';

  @override
  String get locationSaved => 'مقام محفوظ کر لیا گیا';

  @override
  String get errorDetectingLocation => 'مقام کا پتہ لگانے میں خرابی';

  @override
  String get errorGettingAddress => 'پتہ حاصل کرنے میں خرابی';

  @override
  String get pleaseSelectYourIdDocument =>
      'براہ کرم اپنی شناختی دستاویز منتخب کریں';

  @override
  String get pleaseSelectAtLeastOneJobRole =>
      'براہ کرم کم از کم ایک جاب رول منتخب کریں';

  @override
  String get unknown => 'نامعلوم';

  @override
  String get timedOut => 'وقت ختم ہو گیا';

  @override
  String get technicianNotFound => 'ٹیکنیشن نہیں ملا';

  @override
  String get otpAutoVerified => 'او ٹی پی خودکار طور پر تصدیق شدہ';

  @override
  String get somethingWentWrongTryAgain => 'کچھ غلط ہو گیا، دوبارہ کوشش کریں';

  @override
  String get otpSent => 'او ٹی پی بھیج دیا گیا';

  @override
  String get otpHasbeensentto => 'او ٹی پی بھیج دیا گیا ہے کو';

  @override
  String get anErrorOccurredPleaseTryAgainLater =>
      'ایک خرابی پیش آگئی، براہ کرم بعد میں دوبارہ کوشش کریں';

  @override
  String get pleaseEnterAValidPhoneNumber =>
      'براہ کرم ایک درست فون نمبر درج کریں';

  @override
  String get invalidOtp => 'غلط او ٹی پی';

  @override
  String get otpVerification => 'او ٹی پی کی تصدیق';

  @override
  String get enterTheOtpSentToTheNumber =>
      'نمبر پر بھیجا گیا او ٹی پی درج کریں ';

  @override
  String get enterOtp => 'او ٹی پی درج کریں';

  @override
  String get verifyOtp => 'او ٹی پی کی تصدیق کریں';

  @override
  String get language => 'زبان';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get areYouSureYouWantToLogout =>
      'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get account => 'اکاؤنٹ';

  @override
  String get wishlist => 'پسندیدہ فہرست';

  @override
  String get selectLanguage => 'زبان منتخب کریں';

  @override
  String get failedToLoadCategories => 'زمرے لوڈ کرنے میں ناکامی';

  @override
  String get home => 'ہوم';

  @override
  String get myBooking => 'میری بکنگ';

  @override
  String get categories => 'زمرے';

  @override
  String get error => 'خرابی';

  @override
  String get searchHere => 'یہاں تلاش کریں';

  @override
  String get availableServices => 'دستیاب خدمات';

  @override
  String get failedToLoadLocations => 'مقامات لوڈ کرنے میں ناکامی';

  @override
  String get retry => 'دوبارہ کوشش کریں';

  @override
  String get selectLocation => 'مقام منتخب کریں';

  @override
  String get profileUpdatedSuccessfully =>
      'پروفائل کامیابی کے ساتھ اپ ڈیٹ ہو گیا';

  @override
  String get failedToUpdateProfile => 'پروفائل اپ ڈیٹ کرنے میں ناکامی';

  @override
  String get profileManagement => 'پروفائل کا انتظام';

  @override
  String get yourName => 'آپ کا نام';

  @override
  String get nameIsRequired => 'نام ضروری ہے';

  @override
  String get enterAValidName => 'درست نام درج کریں';

  @override
  String get emailAddress => 'ای میل ایڈریس';

  @override
  String get emailIsRequired => 'ای میل ضروری ہے';

  @override
  String get enterAValidEmail => 'درست ای میل درج کریں';

  @override
  String get phoneNumber => 'فون نمبر';

  @override
  String get locationIsRequired => 'مقام ضروری ہے';

  @override
  String get buildingNumberIsRequired => 'بلڈنگ نمبر ضروری ہے';

  @override
  String get streetName => 'گلی کا نام';

  @override
  String get streetNameIsRequired => 'گلی کا نام ضروری ہے';

  @override
  String get cityName => 'شہر کا نام';

  @override
  String get cityNameIsRequired => 'شہر کا نام ضروری ہے';

  @override
  String get postcode => 'پوسٹ کوڈ';

  @override
  String get postcodeIsRequired => 'پوسٹ کوڈ ضروری ہے';

  @override
  String get extensionNumber => 'ایکسٹینشن نمبر';

  @override
  String get extensionNumberIsRequired => 'ایکسٹینشن نمبر ضروری ہے';

  @override
  String get update => 'اپ ڈیٹ کریں';

  @override
  String get accountCreatedSuccessfully => 'اکاؤنٹ کامیابی سے بن گیا';

  @override
  String get failedToCreateAccount => 'اکاؤنٹ بنانے میں ناکامی';

  @override
  String get pleaseFillTheInputBelowHereToContinue =>
      'جاری رکھنے کے لیے براہ کرم نیچے دی گئی معلومات پُر کریں';

  @override
  String get createAccount => 'اکاؤنٹ بنائیں';

  @override
  String get failedToLoadContent => 'مواد لوڈ کرنے میں ناکامی';

  @override
  String get noAddress => 'کوئی پتہ نہیں';

  @override
  String get searchForAService => 'خدمت تلاش کریں';

  @override
  String get jobCategories => 'جاب کیٹیگریز';

  @override
  String get failedToLoadDataPleaseTryAgainLater =>
      'ڈیٹا لوڈ کرنے میں ناکامی۔ براہ کرم بعد میں دوبارہ کوشش کریں۔';

  @override
  String get noBookings => 'کوئی بکنگ نہیں';

  @override
  String get noBookingsFound => 'کوئی بکنگ نہیں ملی۔';

  @override
  String get searchServices => 'سروسز تلاش کریں...';

  @override
  String get noServicesInYourWishlist =>
      'آپ کی پسندیدہ فہرست میں کوئی خدمات نہیں ہیں';

  @override
  String get failedToSaveBooking => 'بکنگ محفوظ کرنے میں ناکامی';

  @override
  String get morning => 'صبح';

  @override
  String get afterNoon => 'دوپہر';

  @override
  String get confirmRequest => 'درخواست کی تصدیق کریں';

  @override
  String get bonusAmount => 'بونس کی رقم';

  @override
  String get requestBonusPayout => 'بونس کی ادائیگی کی درخواست کریں';

  @override
  String get noBonusAvailableToClaim =>
      'کلیم کرنے کے لیے کوئی بونس دستیاب نہیں ہے';

  @override
  String get monthlyBonusEarned => 'ماہانہ بونس حاصل کیا گیا';

  @override
  String get areYouSureYouWantToRequestAPayoutForYourMonthlyBonus =>
      'کیا آپ واقعی اپنے ماہانہ بونس کی ادائیگی کی درخواست کرنا چاہتے ہیں؟';

  @override
  String get evening => 'شام';

  @override
  String get serviceBookedSuccessfully => 'خدمت کامیابی سے بک ہو گئی';

  @override
  String get checkForBookingStatus =>
      'اپنی بکنگ کا اسٹیٹس \'میری بکنگ\' سیکشن میں چیک کریں';

  @override
  String get selectDateTime => 'تاریخ اور وقت منتخب کریں';

  @override
  String get completeYourBooking => 'اپنی بکنگ مکمل کریں';

  @override
  String get selectDate => 'تاریخ منتخب کریں';

  @override
  String get availableTimeSlot => 'دستیاب ٹائم سلاٹ';

  @override
  String get addNotes => 'نوٹس شامل کریں';

  @override
  String get cashInHand => 'نقد ادائیگی';

  @override
  String get netBankingUpiCard => 'نیٹ بینکنگ / کارڈ';

  @override
  String get pleaseSelectADate => 'براہ کرم تاریخ منتخب کریں';

  @override
  String get back => 'پیچھے';

  @override
  String get bookAppointment => 'اپائنٹمنٹ بک کریں';

  @override
  String get filter => 'فلٹر';

  @override
  String get price => 'قیمت';

  @override
  String get clear => 'صاف کریں';

  @override
  String get reviewSubmittedSuccessfully => 'تبصرہ کامیابی سے جمع ہو گیا۔';

  @override
  String get anErrorOccurred => 'ایک خرابی پیش آگئی۔';

  @override
  String get submitAReview => 'درجہ بندی جمع کرائیں';

  @override
  String get overallRating => 'مجموعی درجہ بندی';

  @override
  String get writeYourReviewHere => 'اپنا تبصرہ یہاں لکھیں';

  @override
  String get pleaseWriteAReview => 'براہ کرم ایک تبصرہ لکھیں';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get bookingCancelled => 'بکنگ منسوخ ہو گئی';

  @override
  String get failedToCancelBooking => 'بکنگ منسوخ کرنے میں ناکامی';

  @override
  String get areYouSureToWantCancelBooking =>
      'کیا آپ واقعی بکنگ منسوخ کرنا چاہتے ہیں؟';

  @override
  String get youWillBeRefundedTheFullAmount =>
      'آپ کو پوری رقم واپس کر دی جائے گی';

  @override
  String get no => 'نہیں';

  @override
  String get yesCancel => 'جی ہاں، منسوخ کریں';

  @override
  String get failedToLoadServices => 'خدمات لوڈ کرنے میں ناکامی';

  @override
  String get writeAReview => 'تبصرہ لکھیں';

  @override
  String get reviewSubmitted => 'درجہ بندی جمع کرائی گئی';

  @override
  String get canceled => 'منسوخ کر دیا گیا';

  @override
  String get requestService => 'خدمت کی درخواست کریں';

  @override
  String get submit => 'جمع کرائیں';

  @override
  String get sar => 'سعودی ریال';

  @override
  String get serviceDescription => 'خدمت کی تفصیل';

  @override
  String get serviceInfo => 'خدمت کی معلومات';

  @override
  String get serviceName => 'خدمت کا نام';

  @override
  String get customerInfo => 'صارف کی معلومات';

  @override
  String get bookingInfo => 'بکنگ کی معلومات';

  @override
  String get agentInfo => 'ٹیکنیشن کی معلومات';

  @override
  String get reviewInfo => 'درجہ بندی اور تبصرے کی معلومات';

  @override
  String get issueImage => 'مسئلہ کی تصویر';

  @override
  String get issueVideo => 'مسئلہ کی ویڈیو';

  @override
  String get tapToZoom => 'زوم کرنے کے لیے تھپتھپائیں';

  @override
  String get email => 'ای میل';

  @override
  String get location => 'مقام';

  @override
  String get address => 'پتہ';

  @override
  String get buildingNumber => 'بلڈنگ نمبر';

  @override
  String get street => 'گلی';

  @override
  String get city => 'شہر';

  @override
  String get postCode => 'پوسٹ کوڈ';

  @override
  String get bookedFor => 'کے لیے بک کیا گیا';

  @override
  String get paymentMode => 'ادائیگی کا طریقہ';

  @override
  String get paymentStatus => 'ادائیگی کی صورتحال';

  @override
  String get bookingStatus => 'بکنگ کی صورتحال';

  @override
  String get bookingNote => 'مسئلے کی تفصیل';

  @override
  String get bookedAt => 'بک کیا گیا بروز';

  @override
  String get rating => 'درجہ بندی';

  @override
  String get review => 'تبصرہ';

  @override
  String get reviewedAt => 'درجہ بندی کی گئی بروز';

  @override
  String get manage => 'انتظام کریں';

  @override
  String get manageServices => 'خدمات کا انتظام کریں';

  @override
  String get manageHighlightedServices => 'نمایاں خدمات کا انتظام کریں';

  @override
  String get manageAgents => 'ٹیکنیشنز کا انتظام کریں';

  @override
  String get pleaseEnterYourEmailToResetPassword =>
      'پاس ورڈ ری سیٹ کرنے کے لیے براہ کرم اپنا ای میل درج کریں';

  @override
  String get passwordResetEmailSent =>
      'پاس ورڈ ری سیٹ ای میل بھیج دی گئی۔ براہ کرم اپنا ای میل چیک کریں';

  @override
  String get pleaseEnterYourEmail => 'براہ کرم اپنا ای میل درج کریں';

  @override
  String get pleaseEnterYourPassword => 'براہ کرم اپنا پاس ورڈ درج کریں';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get forgotPassword => 'پاس ورڈ بھول گئے';

  @override
  String get register => 'رجسٹر کریں';

  @override
  String get deleteAccount => 'اکاؤنٹ حذف کریں';

  @override
  String get areYouSureYouWantToApproveAgent =>
      'کیا آپ واقعی منظوری دینا چاہتے ہیں؟';

  @override
  String get areYouSureYouWantToDisapproveAgent =>
      'کیا آپ واقعی نامنظور کرنا چاہتے ہیں؟';

  @override
  String get yesText => 'جی ہاں';

  @override
  String get cropImage => 'تصویر کراپ کریں';

  @override
  String get label => 'لیبل';

  @override
  String get url => 'یو آر ایل';

  @override
  String get title => 'عنوان';

  @override
  String get titleArabic => 'عنوان (عربی)';

  @override
  String get name => 'نام';

  @override
  String get nameArabic => 'نام (عربی)';

  @override
  String get description => 'تفصیل';

  @override
  String get descriptionArabic => 'تفصیل (عربی)';

  @override
  String get category => 'زمرہ';

  @override
  String get sortOrder => 'ترتیب دیں';

  @override
  String get pleaseEnterValidEmail =>
      'براہ کرم ایک درست ای میل ایڈریس درج کریں';

  @override
  String get emailNotRegistered => 'ای میل رجسٹرڈ نہیں ہے';

  @override
  String get invalidEmailFormat => 'ای میل کی شکل غلط ہے';

  @override
  String get tooManyRequests => 'بہت زیادہ درخواستیں';

  @override
  String get netError => 'نیٹ ورک کی خرابی';

  @override
  String get wrongPassword => 'غلط پاس ورڈ';

  @override
  String get userNotFound => 'صارف نہیں ملا';

  @override
  String get userDisabled => 'صارف کا اکاؤنٹ معطل ہے';

  @override
  String get deletingAccount => 'اکاؤنٹ حذف کیا جا رہا ہے...';

  @override
  String get requiresRecentLogin =>
      'اس آپریشن کے لیے حالیہ تصدیق ضروری ہے۔ براہ کرم لاگ آؤٹ کریں اور دوبارہ لاگ ان کریں۔';

  @override
  String get resetPasswordError => 'پاس ورڈ ری سیٹ کرنے میں خرابی';

  @override
  String get incorrectPassword => 'غلط پاس ورڈ';

  @override
  String get accountDisabled => 'اکاؤنٹ معطل ہے';

  @override
  String get invalidCredentials => 'غلط اسناد';

  @override
  String get loginError => 'لاگ ان خرابی';

  @override
  String get passwordMustBeAtleast6Characters =>
      'پاس ورڈ کم از کم 6 حروف طویل ہونا چاہیے';

  @override
  String get pending => 'زیر التوا';

  @override
  String get rejected => 'مسترد شدہ';

  @override
  String get accepted => 'تصدیق شدہ';

  @override
  String get cancelled => 'منسوخ شدہ';

  @override
  String get bookings => 'بکنگز';

  @override
  String get bookedOn => 'بک کیا گیا بروز';

  @override
  String get agentsAvailable => 'ٹیکنیشنز دستیاب ہیں';

  @override
  String get acceptedAt => 'تصدیق کیا گیا بروز';

  @override
  String get rejectedAt => 'مسترد کیا گیا بروز';

  @override
  String get completedAt => 'مکمل کیا گیا بروز';

  @override
  String get expiredOn => 'ختم ہوا بروز';

  @override
  String get phone => 'فون';

  @override
  String get card => 'کارڈ';

  @override
  String get applePay => 'ایپل پے';

  @override
  String get cashOnHands => 'ایپ سے باہر';

  @override
  String get ext => 'ایکسٹینشن';

  @override
  String get serviceAddedSuccessfully => 'خدمت کامیابی سے شامل ہو گئی';

  @override
  String get serviceUpdatedSuccessfully => 'خدمت کامیابی سے اپ ڈیٹ ہو گئی';

  @override
  String get editService => 'خدمت میں ترمیم کریں';

  @override
  String get pleaseEnterAName => 'براہ کرم نام درج کریں';

  @override
  String get pleaseEnterNameInArabic => 'براہ کرم عربی میں نام درج کریں';

  @override
  String get textMustBeInArabic => 'متن عربی میں ہونا چاہیے';

  @override
  String get pleaseEnterADescription => 'براہ کرم تفصیل درج کریں';

  @override
  String get pleaseEnterDescriptionInArabic =>
      'براہ کرم عربی میں تفصیل درج کریں';

  @override
  String get descriptionMustBeInArabic => 'تفصیل عربی میں ہونی چاہیے';

  @override
  String get pleaseEnterAPrice => 'براہ کرم قیمت درج کریں';

  @override
  String get pleaseSelectACategory => 'براہ کرم زمرہ منتخب کریں';

  @override
  String get discountPercentage => 'رعایت کا فیصد (%)';

  @override
  String get pleaseEnterADiscountPercentage =>
      'براہ کرم رعایت کا فیصد درج کریں';

  @override
  String get highlightedServiceAddedSuccessfully =>
      'نمایاں خدمت کامیابی سے شامل ہو گئی';

  @override
  String get highlightedServiceUpdatedSuccessfully =>
      'نمایاں خدمت کامیابی سے اپ ڈیٹ ہو گئی';

  @override
  String get selectServices => 'خدمات منتخب کریں';

  @override
  String get addHighlightedService => 'نمایاں خدمت شامل کریں';

  @override
  String get editHighlightedService => 'نمایاں خدمت میں ترمیم کریں';

  @override
  String get pleaseEnterATitle => 'براہ کرم عنوان درج کریں';

  @override
  String get pleaseEnterTheTitleInArabic => 'براہ کرم عربی میں عنوان درج کریں';

  @override
  String get addBanner => 'بینر شامل کریں';

  @override
  String get editBanner => 'بینر میں ترمیم کریں';

  @override
  String get labelIsRequired => 'لیبل ضروری ہے';

  @override
  String get urlIsRequired => 'یو آر ایل ضروری ہے';

  @override
  String get invalidUrl => 'غلط یو آر ایل';

  @override
  String get bannerAddedSuccessfully => 'بینر کامیابی سے شامل ہو گیا';

  @override
  String get bannerUpdatedSuccessfully => 'بینر کامیابی سے اپ ڈیٹ ہو گیا';

  @override
  String get doYouWantToUploadThisImage =>
      'کیا آپ یہ تصویر اپ لوڈ کرنا چاہتے ہیں؟';

  @override
  String get pleaseSelectAnImage => 'براہ کرم ایک تصویر منتخب کریں';

  @override
  String get hasBeenApprovedAsAnAgent => 'بطور ٹیکنیشن منظوری مل گئی ہے';

  @override
  String get hasBeenDisapprovedAsAnAgent =>
      'بطور ٹیکنیشن نامنظور کر دیا گیا ہے';

  @override
  String get jobRoles => 'جاب رولز';

  @override
  String get document => 'دستاویز';

  @override
  String get jobRolesAreRequired => 'جاب رولز ضروری ہیں';

  @override
  String get failedToDeleteAccount => 'اکاؤنٹ حذف کرنے میں ناکامی';

  @override
  String get pleaseConfirmYourPassword => 'براہ کرم اپنے پاس ورڈ کی تصدیق کریں';

  @override
  String get passwordsDoNotMatch => 'پاس ورڈ مماثل نہیں ہیں';

  @override
  String get confirmPassword => 'پاس ورڈ کی تصدیق کریں';

  @override
  String get selectJobRoles => 'جاب رولز منتخب کریں';

  @override
  String get failedToDetectLocation => 'مقام کا پتہ لگانے میں ناکامی';

  @override
  String get failedToGetAddress => 'پتہ حاصل کرنے میں ناکامی';

  @override
  String get addCustomJobRoles => 'حسب ضرورت جاب رولز شامل کریں';

  @override
  String get enterAdditionalJobRoles => 'اضافی جاب رولز درج کریں';

  @override
  String get detectCurrentLocation => 'موجودہ مقام کا پتہ لگائیں';

  @override
  String get failedToGetLocation => 'مقام حاصل کرنے میں ناکامی';

  @override
  String get cannotCompleteTasksScheduledForTheFuture =>
      'مستقبل کے لیے شیڈول کیے گئے کام مکمل نہیں کیے جا سکتے';

  @override
  String get orders => 'آرڈرز';

  @override
  String get offers => 'پیشکشیں';

  @override
  String get failedToLoadUserData => 'صارف کا ڈیٹا لوڈ کرنے میں ناکامی';

  @override
  String get areYouSureYouWantToDeleteYourAccountThisActionCannotBeUndone =>
      'کیا آپ واقعی اپنا اکاؤنٹ حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں لیا جا سکتا';

  @override
  String get completed => 'مکمل ہو گیا';

  @override
  String get addCategory => 'زمرہ شامل کریں';

  @override
  String get editCategory => 'زمرہ میں ترمیم کریں';

  @override
  String get manageCategories => 'زمروں کا انتظام کریں';

  @override
  String get bookingAccepted => 'بکنگ کی تصدیق ہو گئی';

  @override
  String get bookingAssignedToYou => 'آپ کو ایک نئی بکنگ تفویض کر دی گئی ہے۔';

  @override
  String get yourBookingRequestHasBeenAccepted =>
      'آپ کی بکنگ کی درخواست کی تصدیق ہو گئی ہے! ہماری ٹیم جلد ہی آپ سے رابطہ کرے گی۔';

  @override
  String get bookingRejected => 'بکنگ مسترد کر دی گئی';

  @override
  String get yourBookingRequestHasBeenRejected =>
      'بدقسمتی سے، آپ کی بکنگ کی درخواست مسترد کر دی گئی ہے۔ براہ کرم دوبارہ کوشش کریں یا سپورٹ سے رابطہ کریں۔';

  @override
  String get sendingNotification => 'صارف کو اطلاع بھیجی جا رہی ہے';

  @override
  String get notificationSent => 'صارف کو اطلاع بھیج دی گئی';

  @override
  String get bookingCompleted => 'بکنگ مکمل ہو گئی';

  @override
  String get yourBookingHasBeenCompleted => 'آپ کی بکنگ مکمل ہو گئی ہے!';

  @override
  String get notifications => 'اطلاعات';

  @override
  String get pleaseWaitAccountVerification =>
      'آپ کے اکاؤنٹ کی ایڈمن کے ذریعے تصدیق کی جا رہی ہے، بعد میں دوبارہ چیک کریں';

  @override
  String get goBack => 'واپس جائیں';

  @override
  String get deleteRegistrationConfirmation =>
      'کیا آپ واقعی اپنی رجسٹریشن حذف کرنا چاہتے ہیں؟';

  @override
  String get phoneNumberAlreadyExists => 'فون نمبر پہلے سے موجود ہے';

  @override
  String get keepImage => 'تصویر رکھیں';

  @override
  String get keepImageDescription =>
      'کیا آپ منتخب تصویر کو کراپ کیے بغیر رکھنا چاہتے ہیں؟';

  @override
  String get keep => 'رکھیں';

  @override
  String get pleaseSelectAtLeastOneService =>
      'براہ کرم کم از کم ایک خدمت منتخب کریں';

  @override
  String get deleteBannerConfirmation =>
      'کیا آپ واقعی اس بینر کو حذف کرنا چاہتے ہیں؟';

  @override
  String get selectLocations => 'مقامات منتخب کریں';

  @override
  String get tapToSelectLocations => 'مقامات منتخب کرنے کے لیے تھپتھپائیں';

  @override
  String get locationsSelected => 'مقامات منتخب کیے گئے';

  @override
  String get locationSelected => 'مقام منتخب کیا گیا';

  @override
  String get searchLocation => 'مقام تلاش کریں';

  @override
  String get noLocationsFound => 'کوئی مقامات نہیں ملے';

  @override
  String get accountVerificationPending =>
      'آپ کا اکاؤنٹ فی الحال ہماری ایڈمن ٹیم کے زیر جائزہ ہے۔';

  @override
  String get saving => 'محفوظ کیا جا رہا ہے...';

  @override
  String get uploading => 'اپ لوڈ کیا جا رہا ہے...';

  @override
  String get enterAValidPhoneNumber => 'براہ کرم ایک درست فون نمبر درج کریں';

  @override
  String get manageTips => 'ٹپس کا انتظام کریں';

  @override
  String get cancelBooking => 'بکنگ منسوخ کریں';

  @override
  String get counterPropose => 'جوابی تجویز';

  @override
  String get proposeNewTime => 'نیا وقت تجویز کریں';

  @override
  String get counterOfferPending => 'جوابی پیشکش زیر التوا ہے';

  @override
  String get customerProposedNewTime => 'صارف نے نئے وقت کی تجویز دی ہے';

  @override
  String get acceptOffer => 'پیشکش قبول کریں';

  @override
  String get rejectOffer => 'پیشکش مسترد کریں';

  @override
  String get newProposedTime => 'نیا مجوزہ وقت';

  @override
  String get waitingForCustomer => 'صارف کے جواب کا انتظار ہے';

  @override
  String get proposedTime => 'مجوزہ وقت';

  @override
  String get counterOfferSent => 'جوابی پیشکش کامیابی سے بھیج دی گئی';

  @override
  String get counterOfferResponse => 'جواب کامیابی سے بھیج دیا گیا';

  @override
  String get counterProposalStarted => 'جوابی تجویز شروع ہو گئی';

  @override
  String get counterProposalAccepted => 'جوابی تجویز کی تصدیق ہو گئی';

  @override
  String get proposalRejected => 'تجویز مسترد کر دی گئی';

  @override
  String get proposalAccepted => 'تجویز کی تصدیق ہو گئی';

  @override
  String get customerRejectedProposal => 'صارف نے آپ کی تجویز مسترد کر دی۔';

  @override
  String get youRejectedProposal => 'آپ نے صارف کی تجویز مسترد کر دی۔';

  @override
  String get appointmentRescheduledTo => 'اپائنٹمنٹ دوبارہ شیڈول کی گئی بروز';

  @override
  String get rescheduleBookingTimeConfirmation =>
      'کیا آپ واقعی اس نئے اپائنٹمنٹ کے وقت کو قبول کرنا چاہتے ہیں؟ بکنگ کا شیڈول فوری طور پر اپ ڈیٹ کر دیا جائے گا۔';

  @override
  String get startWork => 'کام شروع کریں';

  @override
  String get pleaseEnterSortOrder => 'براہ کرم ترتیب دیں';

  @override
  String get yes => 'جی ہاں';

  @override
  String get categoryAddedSuccessfully => 'زمرہ کامیابی سے شامل ہو گیا';

  @override
  String get categoryUpdatedSuccessfully => 'زمرہ کامیابی سے اپ ڈیٹ ہو گیا';

  @override
  String get phoneNumberRequired => 'فون نمبر ضروری ہے';

  @override
  String get phoneNumberInvalid => 'فون نمبر غلط ہے';

  @override
  String get useCurrentLocation => 'موجودہ مقام استعمال کریں';

  @override
  String get noNotifications => 'کوئی اطلاع نہیں';

  @override
  String get pleaseSelectALocation => 'براہ کرم مقام منتخب کریں';

  @override
  String get day => 'دن';

  @override
  String get hour => 'گھنٹہ';

  @override
  String get minute => 'منٹ';

  @override
  String get justNow => 'ابھی ابھی';

  @override
  String get emailAlreadyExists => 'ای میل پہلے سے موجود ہے';

  @override
  String get tippingCleared => 'ٹپنگ صاف کر دی گئی';

  @override
  String get failedToClearTipping => 'ٹپنگ صاف کرنے میں ناکامی';

  @override
  String get manageTipping => 'ٹپنگ کا انتظام کریں';

  @override
  String get noTipsAvailable => 'کوئی ٹپس دستیاب نہیں ہیں';

  @override
  String get noRecentActivity => 'کوئی حالیہ سرگرمی نہیں';

  @override
  String get tipInfo => 'ٹپ کی معلومات';

  @override
  String get totalTips => 'کل ٹپس';

  @override
  String get lastTipAmount => 'آخری ٹپ کی رقم';

  @override
  String get lastUpdated => 'آخری بار اپ ڈیٹ کیا گیا';

  @override
  String get agentId => 'ٹیکنیشن آئی ڈی';

  @override
  String get sendAndClearWallet => 'بھیجیں اور والٹ صاف کریں';

  @override
  String get clearWallet => 'والٹ صاف کریں';

  @override
  String get clearWalletWarning =>
      'یہ عمل واپس نہیں لیا جا سکتا۔ ٹیکنیشن کو اپنے والٹ میں کل رقم مل جائے گی، اور اسے صفر پر ری سیٹ کر دیا جائے گا۔';

  @override
  String get areYouSureYouWantToSend => 'کیا آپ واقعی بھیجنا چاہتے ہیں';

  @override
  String get to => 'کو';

  @override
  String get confirm => 'تصدیق کریں';

  @override
  String get andClearTheirWallet => 'اور ان کا والٹ صاف کریں';

  @override
  String get invalid => 'غلط';

  @override
  String get locationPermissionDeniedForever =>
      'مقام کی اجازت ہمیشہ کے لیے مسترد کر دی گئی';

  @override
  String get tracking => 'ٹریکنگ';

  @override
  String get uploadImage => 'تصویر اپ لوڈ کریں';

  @override
  String get pleaseUploadAnImage => 'براہ کرم ایک تصویر اپ لوڈ کریں';

  @override
  String get searchBookings => 'بکنگز تلاش کریں';

  @override
  String get item => 'آئٹم';

  @override
  String get quantity => 'مقدار';

  @override
  String get warrantyRejectedTechnicians => 'وارنٹی مسترد کرنے والے ٹیکنیشنز';

  @override
  String get loadingBanners => 'بینرز لوڈ ہو رہے ہیں...';

  @override
  String get cancelledDate => 'منسوخی کی تاریخ';

  @override
  String get paymentPending => 'ادائیگی زیر التوا ہے';

  @override
  String get loadingHighlightedServices => 'نمایاں خدمات لوڈ ہو رہی ہیں...';

  @override
  String get loadingServices => 'خدمات لوڈ ہو رہی ہیں...';

  @override
  String get completionDetails => 'تکمیل کی تفصیلات';

  @override
  String get loadingFaqs => 'سوالات لوڈ ہو رہے ہیں...';

  @override
  String get loadingTechnicians => 'ٹیکنیشنز لوڈ ہو رہے ہیں...';

  @override
  String get bookingWasCancelledByCustomer =>
      'بکنگ صارف کی طرف سے منسوخ کر دی گئی تھی';

  @override
  String get deleteCategory => 'زمرہ حذف کریں';

  @override
  String get deletedSuccessfully => 'کامیابی سے حذف ہو گیا';

  @override
  String get deleteError => 'حذف کرنے میں خرابی';

  @override
  String get deleteService => 'خدمت حذف کریں';

  @override
  String get serviceCompletedDescription =>
      'سروس کامیابی کے ساتھ مکمل ہو گئی ہے۔ 1 ہفتے کی وارنٹی لاگو ہوگی۔';

  @override
  String get paymentThroughApp => 'ایپ کے اندر';

  @override
  String get paymentOutsideApp => 'ایپ سے باہر';

  @override
  String get paymentThroughAppDesc => 'صارف ایپ کے ذریعے ادائیگی کرے گا۔';

  @override
  String get paymentOutsideAppDesc => 'نقد یا بیرونی ادائیگی وصول کریں۔';

  @override
  String get deleteServiceConfirmation =>
      'کیا آپ واقعی اس خدمت کو حذف کرنا چاہتے ہیں؟';

  @override
  String get failedToLoadData => 'ڈیٹا لوڈ کرنے میں ناکامی';

  @override
  String get categoryNameAlreadyExists => 'زمرہ کا نام پہلے سے موجود ہے';

  @override
  String get deleteCategoryConfirmation =>
      'کیا آپ واقعی اس زمرے کو حذف کرنا چاہتے ہیں؟';

  @override
  String get openSettings => 'ترتیبات کھولیں';

  @override
  String get paymentMethod => 'ادائیگی کا طریقہ';

  @override
  String get completeWork => 'کام مکمل کریں';

  @override
  String get gallery => 'گیلری';

  @override
  String get qty => 'مقدار';

  @override
  String get inspectionOnlyDescription =>
      'صرف معائنہ کیا گیا، کوئی خدمت فراہم نہیں کی گئی';

  @override
  String get required => 'ضروری ہے';

  @override
  String get requests => 'درخواستیں';

  @override
  String get newtext => 'نیا';

  @override
  String get waitingForPayment => 'صارف کی ادائیگی کا انتظار ہے';

  @override
  String get totalCost => 'کل لاگت';

  @override
  String get inspectionOnly => 'صرف معائنہ';

  @override
  String get support => 'سپورٹ';

  @override
  String get getHelpAnytime => 'کسی بھی وقت مدد حاصل کریں';

  @override
  String get tierSystem => 'ٹائر سسٹم';

  @override
  String get bronze => 'کانسی';

  @override
  String get silver => 'چاندی';

  @override
  String get gold => 'سونا';

  @override
  String get platinum => 'پلاٹینم';

  @override
  String get nobonus => 'کوئی بونس نہیں';

  @override
  String get fivepercentBonus => '5% بونس';

  @override
  String get tenpercentBonus => '10% بونس';

  @override
  String get fifteenpercentBonus => '15% بونس + بیج';

  @override
  String get greaterThan3dot5rating => '3.5+ درجہ بندی';

  @override
  String get greaterThan4dot0rating => '4.0+ درجہ بندی';

  @override
  String get greaterThan4dot5rating => '4.5+ درجہ بندی';

  @override
  String get greaterThan4dot8rating => '4.8+ درجہ بندی';

  @override
  String get searchByTechnicianName => 'ٹیکنیشن کے نام سے تلاش کریں';

  @override
  String get bookingWasRejectedByAdmin => 'بکنگ ایڈمن نے مسترد کر دی تھی';

  @override
  String get bonus => 'بونس';

  @override
  String get jobs => 'جابز';

  @override
  String get twentyPlusJobs => '20+ جابز';

  @override
  String get thirtyPlusJobs => '30+ جابز';

  @override
  String get fortyPlusJobs => '40+ جابز';

  @override
  String get sixtyPlusJobs => '60+ جابز';

  @override
  String get earnings => 'آمدنی';

  @override
  String get exitAppTitle => 'ایپ سے باہر نکلیں';

  @override
  String get recentTransactions => 'حالیہ لین دین';

  @override
  String get noTransactionsYet => 'ابھی تک کوئی لین دین نہیں ہوا';

  @override
  String get id => 'آئی ڈی';

  @override
  String get exitAppMessage => 'کیا آپ واقعی ایپ سے باہر نکلنا چاہتے ہیں؟';

  @override
  String get exit => 'باہر نکلیں';

  @override
  String get nextTierProgress => 'اگلے ٹائر کی پیش رفت';

  @override
  String get greaterThan20jobsPerMonth => '20+ جابز فی مہینہ';

  @override
  String get orderId => 'آرڈر آئی ڈی';

  @override
  String get greaterThan40jobsPerMonth => '40+ جابز فی مہینہ';

  @override
  String get greaterThan60jobsPerMonth => '60+ جابز فی مہینہ';

  @override
  String get progressResetsMonthly =>
      'پیش رفت ماہانہ ری سیٹ ہوتی ہے، بہتر انعامات حاصل کرنے کے لیے اعلیٰ درجہ بندی برقرار رکھیں اور مزید کام مکمل کریں۔';

  @override
  String get progressResetsMonthlyDesc =>
      'پیش رفت ماہانہ ری سیٹ ہوتی ہے۔ بہتر انعامات حاصل کرنے کے لیے اعلیٰ درجہ بندی برقرار رکھیں اور مزید کام مکمل کریں';

  @override
  String get zeroPercentBonus => '0% بونس';

  @override
  String get fivepercentBonusOnly => '5% بونس';

  @override
  String get tenpercentBonusOnly => '10% بونس';

  @override
  String get fifteenpercentBonusOnly => '15% بونس';

  @override
  String get viewYourRewards => 'اپنے انعامات دیکھیں';

  @override
  String get noSupportAvailable => 'کوئی سپورٹ دستیاب نہیں ہے';

  @override
  String get contactSupportOptions => 'سپورٹ کے اختیارات سے رابطہ کریں';

  @override
  String get contactByEmail => 'ای میل کے ذریعے رابطہ کریں';

  @override
  String get contactByPhone => 'فون کے ذریعے رابطہ کریں';

  @override
  String get contactByWhatsApp => 'واٹس ایپ کے ذریعے رابطہ کریں';

  @override
  String get serviceCompleted => 'خدمت مکمل ہو گئی';

  @override
  String get dashboard => 'ڈیش بورڈ';

  @override
  String get serviceItems => 'خدمت کے آئٹمز';

  @override
  String get enterServiceCost => 'خدمت کی لاگت درج کریں';

  @override
  String get serviceCostMustBeGreaterThanZero =>
      'خدمت کی لاگت 0 سے زیادہ ہونی چاہیے';

  @override
  String get pleaseEnterValidNumber => 'براہ کرم ایک درست نمبر درج کریں';

  @override
  String get pleaseEnterServiceCost => 'براہ کرم خدمت کی لاگت درج کریں';

  @override
  String get tapToUploadImage => 'تصویر اپ لوڈ کرنے کے لیے تھپتھپائیں';

  @override
  String get serviceCost => 'خدمت کی لاگت';

  @override
  String get addItem => 'آئٹم شامل کریں';

  @override
  String get camera => 'کیمرہ';

  @override
  String get pleaseAddAtleastOneServiceItem =>
      'براہ کرم کم از کم ایک خدمت کا آئٹم شامل کریں';

  @override
  String get pleaseFillAllServiceItemFields =>
      'براہ کرم سروس آئٹم کے تمام فیلڈز پُر کریں';

  @override
  String get workingDays => 'کام کے دن';

  @override
  String get monday => 'پیر';

  @override
  String get tuesday => 'منگل';

  @override
  String get wednesday => 'بدھ';

  @override
  String get thursday => 'جمعرات';

  @override
  String get friday => 'جمعہ';

  @override
  String get saturday => 'ہفتہ';

  @override
  String get sunday => 'اتوار';

  @override
  String get locationServiceRequired => 'مقام کی خدمت ضروری ہے';

  @override
  String get pleaseEnableLocationService => 'براہ کرم مقام کی خدمت فعال کریں';

  @override
  String get ok => 'ٹھیک ہے';

  @override
  String get locationPermissionDenied => 'مقام کی اجازت مسترد کر دی گئی';

  @override
  String get bioMetricAuthentication => 'بائیومیٹرک فعال کریں';

  @override
  String get confirmDeletion => 'حذف کرنے کی تصدیق کریں';

  @override
  String get accountDeleted => 'اکاؤنٹ حذف کر دیا گیا';

  @override
  String get startTracking => 'ٹریکنگ شروع کریں';

  @override
  String get stopTracking => 'ٹریکنگ روکیں';

  @override
  String get arrivedAtLocation => 'مقام پر پہنچ گئے';

  @override
  String get youHaveActiveBooking => 'آپ کی ایک فعال بکنگ ہے';

  @override
  String get areYouSureYouWantToStartTracking =>
      'کیا آپ واقعی اس بکنگ کے لیے ٹریکنگ شروع کرنا چاہتے ہیں؟ اس سے مقام کی نگرانی فعال ہو جائے گی۔';

  @override
  String get start => 'شروع کریں';

  @override
  String get areYouSureYouWantToStopTracking =>
      'کیا آپ واقعی اس بکنگ کے لیے ٹریکنگ روکنا چاہتے ہیں؟ مقام کی نگرانی غیر فعال کر دی جائے گی۔';

  @override
  String get stop => 'روکیں';

  @override
  String get activeBooking => 'فعال بکنگ';

  @override
  String get failedToStartTracking => 'ٹریکنگ شروع کرنے میں ناکامی';

  @override
  String get trackingStarted => 'ٹریکنگ شروع ہو گئی';

  @override
  String get locationServicesDisabled => 'مقام کی خدمات غیر فعال ہیں';

  @override
  String get settings => 'ترتیبات';

  @override
  String get trackingNote =>
      'نوٹ: اگر آپ کام شروع کر رہے ہیں، تو براہ کرم \'ٹریکنگ شروع کریں\' بٹن پر کلک کریں۔ اگر بٹن غائب ہو جائے یا تبدیل ہو جائے تو دوبارہ \'ٹریکنگ شروع کریں\' پر کلک کرنا یقینی بنائیں۔';

  @override
  String get filterByLocation => 'مقام کے لحاظ سے فلٹر کریں';

  @override
  String get allLocations => 'تمام مقامات';

  @override
  String get clearFilter => 'فلٹر صاف کریں';

  @override
  String get agents => 'ٹیکنیشنز';

  @override
  String get inSelectedLocation => 'منتخب مقام میں';

  @override
  String get totalAgents => 'کل ٹیکنیشنز';

  @override
  String get filteredBy => 'فلٹر شدہ بذریعہ';

  @override
  String get notificationLanguage => 'اطلاع کی زبان';

  @override
  String get areYouSureYouWantToCancelThisBooking =>
      'کیا آپ واقعی اس بکنگ کو منسوخ کرنا چاہتے ہیں؟';

  @override
  String get bookingTimeline => 'بکنگ ٹائم لائن';

  @override
  String get trackingStartedAt => 'ٹریکنگ شروع ہوئی بروز';

  @override
  String get createdAt => 'تخلیق کیا گیا بروز';

  @override
  String get enableBiometricAuthentication => 'بائیومیٹرک تصدیق فعال کریں';

  @override
  String get notificationLanguageUpdated => 'اطلاع کی زبان اپ ڈیٹ ہو گئی';

  @override
  String get failedToLoadImage => 'تصویر لوڈ کرنے میں ناکامی';

  @override
  String get issueMedia => 'مسئلہ میڈیا';

  @override
  String get loadingVideo => 'ویڈیو لوڈ ہو رہی ہے';

  @override
  String get categoryAlreadyExists => 'زمرہ پہلے سے موجود ہے';

  @override
  String get noLocationsAvailable => 'کوئی مقامات دستیاب نہیں ہیں';

  @override
  String get close => 'بند کریں';

  @override
  String get enterPasswordToConfirm => 'تصدیق کے لیے پاس ورڈ درج کریں';

  @override
  String get deleteAccountWarning =>
      'کیا آپ واقعی اپنا اکاؤنٹ حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں لیا جا سکتا';

  @override
  String get logoutConfirmation => 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get customerName => 'صارف کا نام';

  @override
  String get call => 'کال کریں';

  @override
  String get directions => 'راستہ دیکھیں';

  @override
  String get images => 'تصاویر';

  @override
  String get video => 'ویڈیو';

  @override
  String get walletClearedSuccessfully =>
      'والٹ بیلنس کامیابی سے صاف کر دیا گیا';

  @override
  String get biometricNotSupported => 'بائیومیٹرک سپورٹ نہیں ہے';

  @override
  String get pleaseAuthenticateToContinue =>
      'جاری رکھنے کے لیے براہ کرم تصدیق کریں';

  @override
  String get authenticationFailed => 'تصدیق ناکام ہو گئی';

  @override
  String get biometricNotAvailable => 'بائیومیٹرک دستیاب نہیں ہے';

  @override
  String get biometricTemporarilyLocked => 'بائیومیٹرک عارضی طور پر مقفل ہے';

  @override
  String get unexpectedErrorOccurred => 'غیر متوقع خرابی پیش آگئی';

  @override
  String get ago => 'پہلے';

  @override
  String get personalInformation => 'ذاتی معلومات';

  @override
  String get country => 'ملک';

  @override
  String get languageCode => 'زبان کا کوڈ';

  @override
  String get accountStatus => 'اکاؤنٹ کی صورتحال';

  @override
  String get adminStatus => 'ایڈمن کی صورتحال';

  @override
  String get verified => 'تصدیق شدہ';

  @override
  String get systemInformation => 'سسٹم کی معلومات';

  @override
  String get userId => 'صارف آئی ڈی';

  @override
  String get updatedAt => 'اپ ڈیٹ کیا گیا بروز';

  @override
  String get admin => 'ایڈمن';

  @override
  String get assignedRoles => 'تفویض کردہ کردار';

  @override
  String get noAgentsFound => 'کوئی ٹیکنیشن نہیں ملا';

  @override
  String get agentApproved => 'ٹیکنیشن منظور شدہ';

  @override
  String get agentDisapproved => 'ٹیکنیشن نامنظور شدہ';

  @override
  String get deleteBanner => 'بینر حذف کریں';

  @override
  String get invalidImageUrl => 'غلط تصویر کا یو آر ایل';

  @override
  String get imageLoadError => 'تصویر لوڈ کرنے میں خرابی';

  @override
  String get imageCropError => 'تصویر کراپ کرنے میں خرابی';

  @override
  String get errorAddingCategory => 'زمرہ شامل کرنے میں خرابی';

  @override
  String get errorUpdatingCategory => 'زمرہ اپ ڈیٹ کرنے میں خرابی';

  @override
  String get customerSubmittedBookingRequest =>
      'صارف نے بکنگ کی درخواست جمع کرائی';

  @override
  String get serviceProviderConfirmedAppointment =>
      'ٹیکنیشن نے اپائنٹمنٹ کی تصدیق کر دی';

  @override
  String get serviceTrackingInitiated => 'سروس ٹریکنگ شروع ہو گئی';

  @override
  String get serviceHasBeenSuccessfullyCompleted =>
      'سروس کامیابی سے مکمل ہو گئی ہے';

  @override
  String get bookingWasRejectedByServiceProvider =>
      'بکنگ ٹیکنیشن نے مسترد کر دی تھی';

  @override
  String get bookingWasCancelled => 'بکنگ منسوخ ہو گئی تھی';

  @override
  String get serviceInProgress => 'سروس جاری ہے';

  @override
  String get current => 'موجودہ';

  @override
  String get serviceIsCurrentlyBeingPerformed =>
      'سروس فی الحال انجام دی جا رہی ہے';

  @override
  String get waitingForServiceProvider => 'ٹیکنیشن کا انتظار ہے';

  @override
  String get waitingForTechnicianToStartService =>
      'ٹیکنیشن کے سروس شروع کرنے کا انتظار ہے';

  @override
  String get waitingForAcceptance => 'قبولیت کا انتظار ہے';

  @override
  String get waitingForServiceProviderResponse =>
      'ٹیکنیشن کے جواب کا انتظار ہے';

  @override
  String get waitingForAdmin => 'ایڈمن کا انتظار ہے';

  @override
  String get waitingForAdminToReassign =>
      'ایڈمن کے ذریعے دوبارہ ٹیکنیشن تفویض کرنے کا انتظار ہے';

  @override
  String get orderRejected => 'آرڈر کامیابی سے مسترد کر دیا گیا';

  @override
  String get registrationSuccess => 'رجسٹریشن کامیاب';

  @override
  String get registrationFailed => 'رجسٹریشن ناکام';

  @override
  String get confirmReject => 'مسترد کرنے کی تصدیق کریں';

  @override
  String get updatedOn => 'اپ ڈیٹ کیا گیا بروز';

  @override
  String get approvedOn => 'منظور کیا گیا بروز';

  @override
  String get confirmRejectMessage =>
      'کیا آپ واقعی اس آرڈر کو مسترد کرنا چاہتے ہیں؟';

  @override
  String get bookingCancelledSuccessfully => 'بکنگ کامیابی سے منسوخ ہو گئی';

  @override
  String get workMarkedAsComplete => 'کام کو مکمل قرار دے دیا گیا';

  @override
  String get areYouSureYouWantToStartTrackingThisBooking =>
      'کیا آپ واقعی اس بکنگ کے لیے ٹریکنگ شروع کرنا چاہتے ہیں؟';

  @override
  String get areYouSureYouWantToPauseTrackingThisBooking =>
      'کیا آپ واقعی اس بکنگ کی ٹریکنگ معطل کرنا چاہتے ہیں؟';

  @override
  String get areYouSureYouWantToStopTrackingThisBooking =>
      'کیا آپ واقعی اس بکنگ کے لیے ٹریکنگ روکنا چاہتے ہیں؟';

  @override
  String get pauseTracking => 'ٹریکنگ روک دیں';

  @override
  String get resumeTracking => 'ٹریکنگ بحال کریں';

  @override
  String get trackingPausedSuccessfully => 'ٹریکنگ کامیابی سے معطل کر دی گئی';

  @override
  String get areYouSureYouWantToCompleteThisWork =>
      'کیا آپ واقعی یہ کام مکمل کرنا چاہتے ہیں؟';

  @override
  String get useBiometric => 'بائیومیٹرک استعمال کریں';

  @override
  String get imageIsRequired => 'تصویر ضروری ہے';

  @override
  String get bookingCompletedSuccessfully => 'بکنگ کامیابی سے مکمل ہو گئی';

  @override
  String get startedWorkingOnBookingSuccessfully =>
      'بکنگ پر کام کامیابی سے شروع ہو گیا';

  @override
  String get stopTrackingBookingSuccessfully =>
      'بکنگ کی ٹریکنگ کامیابی سے روک دی گئی';

  @override
  String get cards => 'ایپ کے اندر';

  @override
  String get insideApp => 'ایپ کے اندر';

  @override
  String get outsideApp => 'خارج ایپ';

  @override
  String get goToLogin => 'لاگ ان پر جائیں';

  @override
  String get failedToSendNotification => 'صارف کو اطلاع بھیجنے میں ناکامی';

  @override
  String get locationPermissionErrorIOS =>
      'آئی او ایس پر مقام کی اجازت کی خرابی۔ براہ کرم ترتیبات > رازداری اور سیکیورٹی > مقام کی خدمات > ابو جلمبو ٹیکنیشن پر جائیں اور بیک گراؤنڈ ٹریکنگ فعال کرنے کے لیے \'ہمیشہ\' منتخب کریں۔';

  @override
  String get youHaveAnActiveBookingAlready =>
      'آپ کی پہلے سے ہی ایک فعال بکنگ موجود ہے۔';

  @override
  String get locationServicesDisabledPleaseEnable =>
      'مقام کی خدمات غیر فعال ہیں۔ براہ کرم مقام کی خدمات فعال کریں۔';

  @override
  String get openLocationSettings => 'مقام کی ترتیبات کھولیں';

  @override
  String get image => 'تصویر';

  @override
  String get notificationTitle => 'اطلاع کا عنوان';

  @override
  String get enterYourNotificationMessageHere =>
      'اپنا اطلاعی پیغام یہاں درج کریں';

  @override
  String get aboGlumboTechnician => 'ابو جلمبو ٹیکنیشن';

  @override
  String get now => 'ابھی';

  @override
  String get assigningTechnician => 'قبولیت زیر التوا';

  @override
  String get selectProvince => 'صوبہ منتخب کریں';

  @override
  String get selectCity => 'شہر منتخب کریں';

  @override
  String get rejectionHistory => 'مسترد کرنے کی تاریخ';

  @override
  String get selectNeighborhood => 'علاقہ منتخب کریں';

  @override
  String get recipients => 'موصول کنندگان';

  @override
  String get techniciansRejectedThisClaim => 'ٹیکنیشنز نے یہ کلیم مسترد کر دیا';

  @override
  String get technicianRejectedThisClaim => 'ٹیکنیشن نے یہ کلیم مسترد کر دیا';

  @override
  String get warrantyClaims => 'وارنٹی کلیمز';

  @override
  String get expired => 'ختم شدہ';

  @override
  String get tapToView => 'دیکھنے کے لیے تھپتھپائیں';

  @override
  String get rejections => 'مسترد شدہ';

  @override
  String get exceedsMaxSize => 'زیادہ سے زیادہ سائز سے تجاوز کر گیا';

  @override
  String get sendNotifications => 'اطلاعات بھیجیں';

  @override
  String get sendNotification => 'اطلاع بھیجیں';

  @override
  String get couldNotOpenFile => 'فائل نہیں کھل سکی';

  @override
  String get noTechniciansFound => 'کوئی ٹیکنیشن نہیں ملا';

  @override
  String get noTechniciansAvailable => 'کوئی ٹیکنیشن دستیاب نہیں';

  @override
  String get manageNotificationAlerts => 'اطلاعی الرٹس کا انتظام کریں';

  @override
  String get previewLanguage => 'زبان کا پیش نظارہ';

  @override
  String get sendNotificationsToCustomer => 'صارف کو اطلاعات بھیجیں';

  @override
  String get preview => 'پیش نظارہ';

  @override
  String get message => 'پیغام';

  @override
  String get composeMessage => 'پیغام تحریر کریں';

  @override
  String get clearAll => 'سب صاف کریں';

  @override
  String get iqama => 'اقامہ';

  @override
  String get certificationsrelevantExperienceDocuments =>
      'سرٹیفکیٹ/متعلقہ تجربہ کی دستاویزات';

  @override
  String get filesSelected => 'فائلیں منتخب کی گئیں';

  @override
  String get certificationsrelevantExperienceDocumentsOptional =>
      'سرٹیفکیٹ/متعلقہ تجربہ کی دستاویزات (اختیاری)';

  @override
  String get invoiceType => 'انوائس کی قسم';

  @override
  String get fullService => 'مکمل سروس';

  @override
  String get inspection => 'معائنہ';

  @override
  String get inspectionFee => 'معائنہ فیس';

  @override
  String get bookingId => 'بکنگ آئی ڈی';

  @override
  String get typeMessageToCustomer => 'صارف کو پیغام لکھیں...';

  @override
  String get startConversationWithCustomer =>
      'اپنے صارف کے ساتھ گفتگو شروع کریں';

  @override
  String get chatWithCustomer => 'صارف کے ساتھ چیٹ کریں';

  @override
  String get startChat => 'چیٹ شروع کریں';

  @override
  String get today => 'آج';

  @override
  String get yesterday => 'کل';

  @override
  String get amountPaid => 'ادا کردہ رقم';

  @override
  String get continueChat => 'چیٹ جاری رکھیں';

  @override
  String get failedToStartChat => 'چیٹ شروع کرنے میں ناکامی';

  @override
  String get creatingChatRoom => 'چیٹ روم بنایا جا رہا ہے';

  @override
  String get loadingChat => 'چیٹ لوڈ ہو رہی ہے';

  @override
  String get noMessages => 'کوئی پیغام نہیں';

  @override
  String get errorLoadingMessages => 'پیغامات لوڈ کرنے میں خرابی';

  @override
  String get transactionId => 'ٹرانزیکشن آئی ڈی';

  @override
  String get backgroundLocationPermissionRequired =>
      'بیک گراؤنڈ لوکیشن ٹریکنگ کے لیے ہمیشہ اجازت ضروری ہے۔ براہ کرم اسے اپنے آلے کی ترتیبات میں فعال کریں۔';

  @override
  String get locationPermissionDeniedPleaseGrant =>
      'مقام کی اجازت مسترد کر دی گئی۔ جاری رکھنے کے لیے براہ کرم مقام کی اجازت دیں۔';

  @override
  String get areYouSureYouWantToCompleteThisBooking =>
      'کیا آپ واقعی یہ بکنگ مکمل کرنا چاہتے ہیں؟';

  @override
  String get locationPermissionPermanentlyDeniedPleaseEnable =>
      'مقام کی اجازت مستقل طور پر مسترد کر دی گئی۔ براہ کرم ترتیبات میں مقام کی رسائی فعال کریں۔';

  @override
  String get locationServicesDisabledCannotRestoreTracking =>
      'مقام کی خدمات غیر فعال ہیں، ٹریکنگ بحال نہیں ہو سکتی';

  @override
  String get locationPermissionDeniedCannotRestoreTracking =>
      'مقام کی اجازت مسترد کر دی گئی، ٹریکنگ بحال نہیں ہو سکتی';

  @override
  String get iosLocationPermissionErrorDuringRestore =>
      'آئی او ایس مقام کی اجازت کی خرابی - \'ہمیشہ\' اجازت کی ضرورت ہو سکتی ہے';

  @override
  String get locationTrackingRestoredSuccessfully =>
      'لوکیشن ٹریکنگ کامیابی سے بحال ہو گئی';

  @override
  String get iosLocationPermissionIssueDuringRestore =>
      'آئی او ایس مقام کی اجازت کا مسئلہ';

  @override
  String get iosOnlyWhenInUsePermissionGranted =>
      'آئی او ایس: صرف \'ایپ استعمال کرتے وقت\' کی اجازت دی گئی۔ بیک گراؤنڈ ٹریکنگ محدود ہوگی۔';

  @override
  String get iosAlwaysPermissionGranted =>
      'آئی او ایس: \'ہمیشہ\' کی اجازت دی گئی۔ مکمل بیک گراؤنڈ ٹریکنگ دستیاب ہے۔';

  @override
  String get iosErrorRequestingAlwaysPermission =>
      'آئی او ایس: ہمیشہ کی اجازت مانگنے میں خرابی';

  @override
  String get iosContinuingWithWhenInUsePermissionOnly =>
      'آئی او ایس: صرف \'ایپ استعمال کرتے وقت\' کی اجازت کے ساتھ جاری ہے۔';

  @override
  String get batteryOptimizationEnabledMayAffectTracking =>
      'بیٹری آپٹیمائزیشن فعال ہے، یہ بیک گراؤنڈ ٹریکنگ کو متاثر کر سکتی ہے';

  @override
  String get trackingYourLocationForServiceDelivery =>
      'سروس کی فراہمی کے لیے آپ کے مقام کو ٹریک کیا جا رہا ہے';

  @override
  String get aboGlumboLocationTracking => 'ابو جلمبو - لوکیشن ٹریکنگ';

  @override
  String get backgroundLocationUpdated => 'بیک گراؤنڈ مقام اپ ڈیٹ ہو گیا';

  @override
  String get errorUpdatingBackgroundLocation =>
      'بیک گراؤنڈ مقام اپ ڈیٹ کرنے میں خرابی';

  @override
  String get backgroundFetchTriggered => 'بیک گراؤنڈ فیچ متحرک ہو گیا';

  @override
  String get backgroundFetchTimeout => 'بیک گراؤنڈ فیچ کا وقت ختم ہو گیا';

  @override
  String get locationStreamErrorDuringRestore =>
      'بحالی کے دوران لوکیشن اسٹریم کی خرابی';

  @override
  String get errorRestoringLocationTracking =>
      'لوکیشن ٹریکنگ بحال کرنے میں خرابی';

  @override
  String get backgroundFetchConfiguredAndStarted =>
      'بیک گراؤنڈ فیچ کنفیگر اور شروع ہو گیا';

  @override
  String get errorConfiguringBackgroundFetch =>
      'بیک گراؤنڈ فیچ کنفیگر کرنے میں خرابی';

  @override
  String get locationUpdated => 'مقام اپ ڈیٹ ہو گیا';

  @override
  String get errorUpdatingLocationToFirestore =>
      'فائر اسٹور پر مقام اپ ڈیٹ کرنے میں خرابی';

  @override
  String get errorStoppingBackgroundFetch => 'بیک گراؤنڈ فیچ روکنے میں خرابی';

  @override
  String get errorUpdatingBookingStatus => 'بکنگ اسٹیٹس اپ ڈیٹ کرنے میں خرابی';

  @override
  String get locationTrackingStopped => 'لوکیشن ٹریکنگ روک دی گئی';

  @override
  String get deleteItemConfirmation =>
      'کیا آپ واقعی اس آئٹم کو حذف کرنا چاہتے ہیں؟';

  @override
  String get agentUnavailable => 'ٹیکنیشن دستیاب نہیں';

  @override
  String get timeConflictDetected => 'وقت کا تعارض پایا گیا';

  @override
  String get cannotAssignWorkTo => 'کام تفویض نہیں کیا جا سکتا کو';

  @override
  String get alreadyAssignedAtExactSameTime =>
      'پہلے ہی بالکل اسی وقت تفویض کیا جا چکا ہے';

  @override
  String get currentBookingTime => 'موجودہ بکنگ کا وقت';

  @override
  String get technicianCannotBeAssignedMultipleTimes =>
      'ایک ٹیکنیشن کو بالکل ایک ہی وقت میں متعدد بکنگز تفویض نہیں کی جا سکتیں۔ براہ کرم ایک مختلف ٹائم سلاٹ منتخب کریں یا کوئی دوسرا ٹیکنیشن منتخب کریں۔';

  @override
  String get unknownTechnician => 'نامعلوم ٹیکنیشن';

  @override
  String get tryadifferentsearchterm => 'مختلف تلاش کی اصطلاح آزمائیں';

  @override
  String get warrantyRepairRequested => 'وارنٹی مرمت کی درخواست کی گئی';

  @override
  String get acceptWarrantyRepair => 'وارنٹی مرمت قبول کریں';

  @override
  String get customerRequestedRepairUnderWarranty =>
      'صارف نے وارنٹی کے تحت مرمت کی درخواست کی';

  @override
  String get warrantyRepairAccepted => 'وارنٹی مرمت کی تصدیق ہو گئی';

  @override
  String get technicianAcceptedTheRequest =>
      'ٹیکنیشن نے درخواست کی تصدیق کر دی';

  @override
  String get warrantyRepairCompleted => 'وارنٹی مرمت مکمل ہو گئی';

  @override
  String get originalServiceCompleted => 'اصل خدمت مکمل ہو گئی';

  @override
  String get warrantyRejectedByAdmin => 'وارنٹی ایڈمن نے مسترد کر دی';

  @override
  String get warrantyRejectedByTechnician => 'وارنٹی ٹیکنیشن نے مسترد کر دی';

  @override
  String get reasonforrejection => 'مسترد کرنے کی وجہ';

  @override
  String get warrantyRequestWasRejectedByAdmin =>
      'وارنٹی کی درخواست ایڈمن نے مسترد کر دی تھی';

  @override
  String get warrantyRequestWasRejectedByTechnician =>
      'وارنٹی کی درخواست ٹیکنیشن نے مسترد کر دی تھی';

  @override
  String get technicianCompletedTheRequest => 'ٹیکنیشن نے درخواست مکمل کر لی';

  @override
  String get warrantyExpired => 'وارنٹی ختم ہو گئی';

  @override
  String get warrantyPeriodHasExpired => 'وارنٹی کی مدت ختم ہو چکی ہے';

  @override
  String get trackingStoppedAt => 'ٹریکنگ روک دی گئی';

  @override
  String get serviceTrackingStopped => 'سروس ٹریکنگ روک دی گئی ہے';

  @override
  String get youCancelledThisRequest => 'آپ نے یہ درخواست منسوخ کر دی';

  @override
  String get youDeclinedThisWarrantyRequest =>
      'آپ نے وارنٹی کی یہ درخواست مسترد کر دی';

  @override
  String get noresultsfound => 'کوئی نتائج نہیں ملے';

  @override
  String get technicianCancelled => 'ٹیکنیشن نے منسوخ کر دیا';

  @override
  String get cancelledByTechnician => 'ٹیکنیشن کی طرف سے منسوخ کر دیا گیا';

  @override
  String get technicianPreviouslyCancelled => 'ٹیکنیشن نے پہلے منسوخ کیا تھا';

  @override
  String get agentCancelledAtTimeSlot => 'ٹیکنیشن نے اس وقت پہلے منسوخ کیا تھا';

  @override
  String get previouslyCancelledAt => 'پہلے منسوخ کیا گیا بروز';

  @override
  String get chooseDifferentAgent => 'مختلف ٹیکنیشن منتخب کریں';

  @override
  String get assignAnyway => 'بہرحال تفویض کریں';

  @override
  String get cancelledAt => 'منسوخ کیا گیا بروز';

  @override
  String get technicianCancelledAtTime =>
      'اس ٹیکنیشن نے پہلے بالکل اسی ٹائم سلاٹ میں بکنگ منسوخ کی تھی۔ بہتر وشوسنییتا کے لیے کسی دوسرے ٹیکنیشن کو تفویض کرنے پر غور کریں۔';

  @override
  String get errorCheckingBatteryOptimization =>
      'بیٹری آپٹیمائزیشن چیک کرنے میں خرابی';

  @override
  String get technicianRestrictedTitle => 'ٹیکنیشن محدود ہے';

  @override
  String get cannotAssignCancelledTechnician =>
      'منسوخ شدہ ٹیکنیشن کو تفویض نہیں کیا جا سکتا';

  @override
  String get lastCancellationOn => 'آخری منسوخی بروز';

  @override
  String get technicianCancelledRestrictionMessage =>
      'اس ٹیکنیشن نے پہلے بکنگ منسوخ کی ہے اور اب اسے نئی اسائنمنٹس سے روک دیا گیا ہے۔ براہ کرم ایک مختلف ٹیکنیشن منتخب کریں۔';

  @override
  String get understood => 'سمجھ گیا';

  @override
  String get suspendAccount => 'اکاؤنٹ معطل کریں';

  @override
  String get unblockAccount => 'اکاؤنٹ بحال کریں';

  @override
  String get areYouSureYouWantToSuspendThisAccount =>
      'کیا آپ واقعی اس اکاؤنٹ کو معطل کرنا چاہتے ہیں؟';

  @override
  String get areYouSureYouWantToUnblockThisAccount =>
      'کیا آپ واقعی اس اکاؤنٹ کو بحال کرنا چاہتے ہیں؟';

  @override
  String get accountSuspended => 'اکاؤنٹ معطل کر دیا گیا';

  @override
  String get accountUnblocked => 'اکاؤنٹ بحال کر دیا گیا';

  @override
  String get completedOrders => 'مکمل شدہ آرڈرز';

  @override
  String get profession => 'پیشہ';

  @override
  String get idAndDocuments => 'شناختی دستاویزات';

  @override
  String get bonusTier => 'بونس درجہ';

  @override
  String get systemInfo => 'سسٹم کی معلومات';

  @override
  String get earningsBreakdown => 'آمدنی کی تفصیل';

  @override
  String get bonuses => 'بونس';

  @override
  String get noDocumentsUploaded => 'کوئی دستاویز اپ لوڈ نہیں کی گئی';

  @override
  String get cancelledThisBooking => 'یہ بکنگ منسوخ کر دی';

  @override
  String get alreadyBookedAt => 'پہلے ہی بک ہے بروز';

  @override
  String get bookingAssignedTo => 'بکنگ تفویض کر دی گئی کو';

  @override
  String get bookingAssignmentSuccessful => 'بکنگ کی تفویض کامیاب رہی';

  @override
  String get anotherAssignmentInProgress =>
      'ایک اور تفویض جاری ہے۔ براہ کرم انتظار کریں...';

  @override
  String get assignmentInProgress => 'تفویض جاری ہے۔ براہ کرم انتظار کریں...';

  @override
  String get checkingAvailabilityAndAssigning =>
      'دستیابی چیک کی جا رہی ہے اور تفویض کیا جا رہا ہے...';

  @override
  String get thisBookingAlreadyAssignedToAnotherAgent =>
      'یہ بکنگ پہلے ہی کسی دوسرے ٹیکنیشن کو تفویض کی جا چکی ہے۔';

  @override
  String get failedToAssignAgent =>
      'ٹیکنیشن تفویض کرنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get thisAgentCancelledSameBookingBefore =>
      'اس ٹیکنیشن نے پہلے یہی بکنگ منسوخ کی تھی';

  @override
  String get gotIt => 'سمجھ گیا';

  @override
  String get showAllAgents => 'تمام ٹیکنیشنز دکھائیں';

  @override
  String get availableInSelectedLocation => 'منتخب مقام میں دستیاب';

  @override
  String get cancelledThisBookingOn => 'یہ بکنگ منسوخ کی بروز';

  @override
  String get previouslyCancelledAgent => 'پہلے منسوخ شدہ ٹیکنیشن';

  @override
  String get agentPreviouslyCancelledWarning =>
      'اس ٹیکنیشن نے پہلے یہی بکنگ کی درخواست منسوخ کی تھی۔ آپ پھر بھی انہیں تفویض کر سکتے ہیں، لیکن زیادہ قابل اعتماد ٹیکنیشن منتخب کرنے پر غور کریں۔';

  @override
  String get busyAt => 'مصروف ہے بروز';

  @override
  String get managefaq => 'سوالات کا انتظام کریں';

  @override
  String get technicianArrived => 'ٹیکنیشن پہنچ گیا';

  @override
  String get paymentRequested => 'ادائیگی کی درخواست';

  @override
  String get reassignedAt => 'ری-اسائنڈ';

  @override
  String get newTechnicianAssigned => 'نئے ٹیکنیشن کی تعیناتی';

  @override
  String get technicianStartedTracking => 'ٹیکنیشن نے ٹریکنگ شروع کی';

  @override
  String get technicianArrivedAtLocation => 'ٹیکنیشن مقام پر پہنچ گیا';

  @override
  String get inspectionCompleted => 'معائنہ مکمل';

  @override
  String get fullServiceCompleted => 'مکمل سروس مکمل';

  @override
  String get cancelledByAdmin => 'ایڈمن کی طرف سے منسوخ شدہ';

  @override
  String get paymentCompleted => 'ادائیگی مکمل';

  @override
  String get paymentSuccessfullyCompleted => 'ادائیگی کامیابی سے مکمل';

  @override
  String get bookingCancelledByAdmin => 'ایڈمن کی جانب سے بکنگ منسوخ';

  @override
  String get addFaq => 'سوال شامل کریں';

  @override
  String get noFaqEntriesFound => 'کوئی سوال نہیں ملا';

  @override
  String get manageFaqs => 'سوالات کا انتظام کریں';

  @override
  String get english => 'انگریزی';

  @override
  String get arabic => 'عربی';

  @override
  String get question => 'سوال';

  @override
  String get answer => 'جواب';

  @override
  String get questionIsRequired => 'سوال ضروری ہے';

  @override
  String get answerIsRequired => 'جواب ضروری ہے';

  @override
  String get faqAddedSuccessfully => 'سوال کامیابی سے شامل ہو گیا';

  @override
  String get addEntry => 'اندراج شامل کریں';

  @override
  String get addFaqEntry => 'سوال شامل کریں';

  @override
  String get questionMustBeInArabic => 'سوال عربی میں ہونا چاہیے';

  @override
  String get answerMustBeInArabic => 'جواب عربی میں ہونا چاہیے';

  @override
  String get faqEntryDeletedSuccessfully => 'سوال کامیابی سے حذف ہو گیا';

  @override
  String get position => 'پوزیشن';

  @override
  String get entryAlreadyExists => 'اس پوزیشن پر اندراج پہلے سے موجود ہے';

  @override
  String get manageCustomers => 'صارفین کا انتظام کریں';

  @override
  String get areYouSureYouWantToUnBlockThisCustomer =>
      'کیا آپ واقعی اس صارف کو ان بلاک کرنا چاہتے ہیں؟';

  @override
  String get areYouSureYouWantToBlockThisCustomer =>
      'کیا آپ واقعی اس صارف کو بلاک کرنا چاہتے ہیں؟';

  @override
  String get customer => 'صارف';

  @override
  String get blocked => 'بلاک شدہ';

  @override
  String get customerUnblockedSuccessfully => 'صارف کامیابی سے ان بلاک ہو گیا';

  @override
  String get customerBlockedSuccessfully => 'صارف کامیابی سے بلاک ہو گیا';

  @override
  String get noCustomersFound => 'کوئی صارف نہیں ملا';

  @override
  String get blockCustomer => 'صارف کو بلاک کریں';

  @override
  String get unBlockCustomer => 'صارف کو ان بلاک کریں';

  @override
  String get checkingAvailability => 'دستیابی چیک کی جا رہی ہے...';

  @override
  String get positionText => 'پوزیشن';

  @override
  String get faqUpdatedSuccessfully => 'سوال کامیابی سے اپ ڈیٹ ہو گیا';

  @override
  String get deleteFaqEntry => 'سوال حذف کریں';

  @override
  String get manageTechnicians => 'ٹیکنیشنز کا انتظام کریں';

  @override
  String get manageCustomerSupport => 'کسٹمر سپورٹ کا انتظام کریں';

  @override
  String get customerSupport => 'کسٹمر سپورٹ';

  @override
  String get whatsapp => 'واٹس ایپ';

  @override
  String get addNewEmail => 'نیا ای میل شامل کریں';

  @override
  String get add => 'شامل کریں';

  @override
  String get areYouSureYouWantToDeleteThisFaqEntry =>
      'کیا آپ واقعی اس سوال کو حذف کرنا چاہتے ہیں؟';

  @override
  String get thisActionCannotBeUndone => 'یہ عمل واپس نہیں لیا جا سکتا';

  @override
  String get supportContactDeletedSuccessfully =>
      'سپورٹ رابطہ کامیابی سے حذف ہو گیا';

  @override
  String get supportContactUpdatedSuccessfully =>
      'سپورٹ رابطہ کامیابی سے اپ ڈیٹ ہو گیا';

  @override
  String get supportContactAddedSuccessfully =>
      'سپورٹ رابطہ کامیابی سے شامل ہو گیا';

  @override
  String get noDataAvailable => 'کوئی ڈیٹا دستیاب نہیں ہے';

  @override
  String get deleteConfirmation => 'حذف کرنے کی تصدیق';

  @override
  String get areYouSureYouWantToDeleteThisSupportContact =>
      'کیا آپ واقعی اس سپورٹ رابطے کو حذف کرنا چاہتے ہیں؟';

  @override
  String get supportContact => 'سپورٹ رابطہ';

  @override
  String get phoneIsRequired => 'فون نمبر ضروری ہے';

  @override
  String get whatsappNumberIsRequired => 'واٹس ایپ نمبر ضروری ہے';

  @override
  String get editEmail => 'ای میل میں ترمیم کریں';

  @override
  String get addNewWhatsapp => 'نیا واٹس ایپ شامل کریں';

  @override
  String get addNewPhone => 'نیا فون شامل کریں';

  @override
  String get editWhatsapp => 'واٹس ایپ میں ترمیم کریں';

  @override
  String get editPhone => 'فون میں ترمیم کریں';

  @override
  String get edit => 'ترمیم کریں';

  @override
  String get setAsPrimary => 'بنیادی کے طور پر سیٹ کریں';

  @override
  String get primary => 'بنیادی';

  @override
  String get search => 'تلاش کریں';

  @override
  String get all => 'تمام';

  @override
  String get disapproveAgent => 'ٹیکنیشن کو نامنظور کریں';

  @override
  String get approveAgent => 'ٹیکنیشن کو منظور کریں';

  @override
  String get areYouSureYouWantToDisapproveThisAgent =>
      'کیا آپ واقعی اس ٹیکنیشن کو نامنظور کرنا چاہتے ہیں؟';

  @override
  String get areYouSureYouWantToApproveThisAgent =>
      'کیا آپ واقعی اس ٹیکنیشن کو منظور کرنا چاہتے ہیں؟';

  @override
  String get tryAdjustingYourSearchCriteria =>
      'اپنی تلاش یا فلٹرز کو ایڈجسٹ کرنے کی کوشش کریں۔';

  @override
  String get noTechniciansMatchYourFilters =>
      'کوئی ٹیکنیشن آپ کی تلاش سے مطابقت نہیں رکھتا';

  @override
  String get unblockCustomer => 'صارف کو ان بلاک کریں';

  @override
  String get filterByDate => 'تاریخ کے لحاظ سے فلٹر کریں';

  @override
  String get typeProvinceNameToSearch =>
      'تلاش کرنے کے لیے صوبے کا نام لکھیں...';

  @override
  String get typeCityNameToSearch => 'تلاش کرنے کے لیے شہر کا نام لکھیں...';

  @override
  String get typeNeighborhoodNameToSearch =>
      'تلاش کرنے کے لیے علاقے کا نام لکھیں...';

  @override
  String get areYouSureYouWantToUnblockThisCustomer =>
      'کیا آپ واقعی اس صارف کو ان بلاک کرنا چاہتے ہیں؟';

  @override
  String get noCustomersMatchYourSearch =>
      'کوئی صارف آپ کی تلاش سے مطابقت نہیں رکھتا';

  @override
  String get searchbyBookingIdnameTechnician =>
      'بکنگ آئی ڈی، نام، یا ٹیکنیشن کے ذریعے تلاش کریں';

  @override
  String get block => 'بلاک کریں';

  @override
  String get days => 'دن';

  @override
  String get hours => 'گھنٹے';

  @override
  String get minutes => 'منٹ';

  @override
  String get startDate => 'شروع ہونے کی تاریخ';

  @override
  String get cancelledOn => 'منسوخ ہوا بروز';

  @override
  String get endDate => 'ختم ہونے کی تاریخ';

  @override
  String get selectDateRange => 'تاریخ کی حد منتخب کریں';

  @override
  String get unblock => 'ان بلاک کریں';

  @override
  String get whatsappNumber => 'واٹس ایپ نمبر';

  @override
  String get whatsappCondition =>
      'براہ کرم یقینی بنائیں کہ آپ جو فون نمبر درج کرتے ہیں اس کے شروع میں پلس سائن کے ساتھ ملک کا کوڈ شامل ہے۔ واٹس ایپ کے لیے نمبر کو صحیح طریقے سے پہچاننے کے لیے یہ فارمیٹ ضروری ہے۔';

  @override
  String get rewards => 'انعامات';

  @override
  String get contactNotFound => 'رابطہ نہیں ملا';

  @override
  String get keepBooking => 'بکنگ رکھیں';

  @override
  String get orderCancelledSuccessfully => 'آرڈر کامیابی سے منسوخ ہو گیا';

  @override
  String get failedToCancelOrder => 'آرڈر منسوخ کرنے میں ناکامی';

  @override
  String get accept => 'قبول کریں';

  @override
  String get excellent => 'بہترین';

  @override
  String get good => 'اچھا';

  @override
  String get average => 'اوسط';

  @override
  String get poor => 'ناقص';

  @override
  String get selected => 'منتخب شدہ';

  @override
  String get selectAll => 'سب منتخب کریں';

  @override
  String get cancelledBy => 'منسوخ شدہ بذریعہ';

  @override
  String get pleaseEnterInspectionFeeAmount =>
      'براہ کرم معائنہ فیس کی رقم درج کریں';

  @override
  String get rejectBooking => 'بکنگ مسترد کریں';

  @override
  String get pleaseuploadpaymentproof => 'براہ کرم ادائیگی کا ثبوت اپ لوڈ کریں';

  @override
  String get iban => 'آئی بی اے این (IBAN)';

  @override
  String get tapToUpload => 'ثبوت کی تصویر/فائل اپ لوڈ کرنے کے لیے تھپتھپائیں';

  @override
  String get selectSource => 'ذریعہ منتخب کریں';

  @override
  String get areYouSureYouWantToRejectThisBooking =>
      'کیا آپ واقعی اس بکنگ کو مسترد کرنا چاہتے ہیں؟';

  @override
  String get acceptBooking => 'بکنگ قبول کریں';

  @override
  String get requestPayout => 'ادائیگی کی درخواست کریں';

  @override
  String get lastTip => 'آخری ٹپ';

  @override
  String get paymentBreakdown => 'ادائیگی کی تفصیل';

  @override
  String get cashPayments => 'نقد ادائیگیاں';

  @override
  String get cardPayments => 'کارڈ ادائیگیاں';

  @override
  String get asOf => 'تک';

  @override
  String get totalEarnings => 'کل آمدنی';

  @override
  String get pleaseEnterAValidAmount => 'براہ کرم ایک درست رقم درج کریں';

  @override
  String get amountExceedsAvailableBalance => 'رقم دستیاب بیلنس سے زیادہ ہے';

  @override
  String get cashPaymentsAreAlreadyWithYou =>
      'نقد ادائیگیاں پہلے سے ہی آپ کے پاس ہیں';

  @override
  String get amount => 'رقم';

  @override
  String get availableForPayout => 'ادائیگی کے لیے دستیاب';

  @override
  String get theAdminWillProcessYourRequestWithin2to3days =>
      'ایڈمن آپ کی درخواست پر 2 سے 3 کاروباری دنوں میں کارروائی کرے گا۔';

  @override
  String get availableBalance => 'دستیاب بیلنس';

  @override
  String get areYouSureYouWantToAcceptThisBooking =>
      'کیا آپ واقعی اس بکنگ کو قبول کرنا چاہتے ہیں؟';

  @override
  String get cancelledByCustomer => 'صارف کی طرف سے منسوخ شدہ';

  @override
  String get bookingDetails => 'بکنگ کی تفصیلات';

  @override
  String get confirmCancellation => 'منسوخی کی تصدیق کریں';

  @override
  String get adminCancelWarning =>
      'کیا آپ واقعی اس بکنگ کو منسوخ کرنا چاہتے ہیں؟ صارف کو مطلع کر دیا جائے گا۔ اس بکنگ کو منسوخ کرنے سے صارف کو خودکار طور پر رقم واپس نہیں ملے گی۔ براہ کرم یقینی بنائیں کہ کوئی بھی ضروری رقم دستی طور پر واپس کی جائے۔';

  @override
  String get atleastOneContactIsrequired => 'کم از کم ایک رابطہ ضروری ہے';

  @override
  String get cannotRemovePrimaryStatusFromTheOnlyContact =>
      'واحد رابطہ سے بنیادی حیثیت ختم نہیں کی جا سکتی';

  @override
  String get submitRequest => 'درخواست جمع کرائیں';

  @override
  String get payoutAccounts => 'ادائیگی کے اکاؤنٹس';

  @override
  String get noPayoutAccountsAdded => 'کوئی ادائیگی اکاؤنٹ شامل نہیں کیا گیا';

  @override
  String get imageIsTooLargePleaseSelectAnImageSmallerThan5MB =>
      'تصویر بہت بڑی ہے۔ براہ کرم 5 ایم بی سے چھوٹی تصویر منتخب کریں';

  @override
  String get managePayouts => 'ادائیگیوں کا انتظام کریں';

  @override
  String get requestedOn => 'درخواست دی گئی بروز';

  @override
  String get selectedFileCouldNotBeFound =>
      'منتخب فائل نہیں مل سکی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get errorPickingImage => 'تصویر منتخب کرنے میں خرابی';

  @override
  String get errorCroppingImage => 'تصویر کراپ کرنے میں خرابی';

  @override
  String get technicianInformation => 'ٹیکنیشن کی معلومات';

  @override
  String get noPayoutRequestsYet => 'ابھی تک کوئی ادائیگی کی درخواست نہیں ہے';

  @override
  String get reviews => 'تبصرے';

  @override
  String get payoutHistory => 'ادائیگی کی تاریخ';

  @override
  String get searchByTechnicianNameOrAmount =>
      'ٹیکنیشن کے نام یا رقم سے تلاش کریں...';

  @override
  String get tipDetails => 'ٹپ کی تفصیلات';

  @override
  String get tipsSummary => 'ٹپس کا خلاصہ';

  @override
  String get noPayoutHistoryAvailable => 'کوئی ادائیگی کی تاریخ دستیاب نہیں ہے';

  @override
  String get smsRetrievalTimedOut =>
      'ایس ایم ایس کی وصولی کا وقت ختم ہو گیا۔ براہ کرم چیک کریں کہ آیا آپ کو کوڈ موصول ہوا ہے یا دوبارہ کوشش کریں۔';

  @override
  String get payoutRequirement =>
      'ٹپ کی ادائیگی کی درخواست کرنے کے لیے، آپ کو ادائیگی کے لیے کم از کم 10 سعودی ریال دستیاب ہونے چاہئیں۔';

  @override
  String get notEnoughBalanceforRequestingTipPayout =>
      'ٹپ کی ادائیگی کی درخواست کرنے کے لیے کافی بیلنس نہیں ہے';

  @override
  String get cashTips => 'ایپ کے باہر ٹپس';

  @override
  String get cardTips => 'ایپ کے اندر ٹپس';

  @override
  String get am => 'صبح';

  @override
  String get pm => 'شام';

  @override
  String get inHand => 'پاس موجود';

  @override
  String get errorLoadingReviews => 'تبصرے لوڈ کرنے میں خرابی';

  @override
  String get noReviewsYet => 'ابھی تک کوئی تبصرہ نہیں ہوا';

  @override
  String get reviewsWillAppearHereAfterCustomersRateYourService =>
      'صارف کی طرف سے آپ کی سروس کی درجہ بندی کرنے کے بعد تبصرے یہاں ظاہر ہوں گے';

  @override
  String get approved => 'منظور شدہ';

  @override
  String get total => 'کل';

  @override
  String get failedToLoadVideo => 'ویڈیو لوڈ کرنے میں ناکامی';

  @override
  String get payoutAmount => 'ادائیگی کی رقم';

  @override
  String get bankAccountDetails => 'بینک اکاؤنٹ کی تفصیلات';

  @override
  String get approve => 'منظور کریں';

  @override
  String get rejectPayout => 'ادائیگی مسترد کریں';

  @override
  String get payoutApproved => 'ادائیگی منظور ہو گئی';

  @override
  String get approvePayout => 'ادائیگی منظور کریں';

  @override
  String get fileRequired => 'فائل ضروری ہے';

  @override
  String get transactionNumberRequired => 'トランザクション番号が必要です';

  @override
  String get viewAndManageEarnings => 'آمدنی دیکھیں اور ان کا انتظام کریں';

  @override
  String get supportedFormats => 'معاون فارمیٹس:';

  @override
  String get lifetimeTips => 'تاحیات ٹپس';

  @override
  String get pleaseProvideTransactionDetails =>
      'اس ادائیگی کی درخواست کو منظور کرنے کے لیے براہ کرم ٹرانزیکشن کی تفصیلات فراہم کریں۔';

  @override
  String get pdfImageOrDocument => 'پی ڈی ایف، تصویر، یا دستاویز';

  @override
  String get tapToSelectFile => 'فائل منتخب کرنے کے لیے تھپتھپائیں';

  @override
  String get lifetimeEarnings => 'تاحیات آمدنی';

  @override
  String get uploadProof => 'ثبوت اپ لوڈ کریں';

  @override
  String get notenoughtipstorequestpayoutminSAR10 =>
      'ادائیگی کی درخواست کے لیے کافی ٹپس نہیں ہیں (کم از کم 10 ریال)';

  @override
  String get requestTipPayout => 'ٹپ کی ادائیگی کی درخواست کریں';

  @override
  String get errorRequestingPayout => 'ادائیگی کی درخواست کرنے میں خرابی';

  @override
  String get payoutRequestSubmittedSuccessfully =>
      'ادائیگی کی درخواست کامیابی سے جمع ہو گئی';

  @override
  String get areYouSureYouWantToRequestAPayoutForTheAccumulatedTips =>
      'کیا آپ واقعی جمع شدہ ٹپس کی ادائیگی کی درخواست کرنا چاہتے ہیں؟';

  @override
  String get transactionNumber => 'ٹرانزیکشن نمبر';

  @override
  String get tipspayoutisdoneseparately =>
      'ٹپس کی ادائیگی علیحدہ سے کی جاتی ہے';

  @override
  String get pleaseProvideARejectionReason =>
      'براہ کرم مسترد کرنے کی وجہ فراہم کریں';

  @override
  String get enterTransactionNumber => 'ٹرانزیکشن نمبر درج کریں';

  @override
  String get youHaveNoPayoutAccountsgotoprofilesectionandaddanaccount =>
      'آپ کا کوئی ادائیگی اکاؤنٹ نہیں ہے۔ پروفائل سیکشن میں جائیں اور ایک اکاؤنٹ شامل کریں۔';

  @override
  String get payoutRejectedSuccessfully => 'ادائیگی کامیابی سے مسترد کر دی گئی';

  @override
  String get payoutRejected => 'ادائیگی مسترد کر دی گئی';

  @override
  String get rejectConfirmation =>
      'کیا آپ واقعی اس ادائیگی کی درخواست کو مسترد کرنا چاہتے ہیں؟';

  @override
  String get reason => 'وجہ';

  @override
  String get enterTheReason =>
      'اس ادائیگی کی درخواست کو مسترد کرنے کی وجہ درج کریں';

  @override
  String get payoutRequests => 'ادائیگی کی درخواستیں';

  @override
  String get status => 'صورتحال';

  @override
  String get noPayoutRequestsFound => 'کوئی ادائیگی کی درخواست نہیں ملی';

  @override
  String get payoutRequestCancelled => 'ادائیگی کی درخواست منسوخ ہو گئی';

  @override
  String get areYouSureYouWantToCancelThisPayoutRequest =>
      'کیا آپ واقعی اس ادائیگی کی درخواست کو منسوخ کرنا چاہتے ہیں؟';

  @override
  String get addAnAccountToReceivePayments =>
      'ادائیگیاں وصول کرنے کے لیے ایک اکاؤنٹ شامل کریں';

  @override
  String get addAccount => 'اکاؤنٹ شامل کریں';

  @override
  String get accountNumber => 'اکاؤنٹ نمبر';

  @override
  String get ifscCode => 'آئی بی اے این (IBAN)';

  @override
  String get addFirstAccount => 'اپنا پہلا اکاؤنٹ شامل کریں';

  @override
  String get enterAccountDetails => 'اکاؤنٹ کی تفصیلات درج کریں';

  @override
  String get manageBankAccounts => 'بینک اکاؤنٹس کا انتظام کریں';

  @override
  String get addAndManageYourPayoutAccounts =>
      'اپنے ادائیگی کے اکاؤنٹس شامل کریں اور ان کا انتظام کریں';

  @override
  String get updateAccountDetails => 'اکاؤنٹ کی تفصیلات اپ ڈیٹ کریں';

  @override
  String get accountType => 'اکاؤنٹ کی قسم';

  @override
  String get primaryAccountUpdated => 'بنیادی اکاؤنٹ اپ ڈیٹ ہو گیا';

  @override
  String get deleteAccountConfirmation =>
      'کیا آپ واقعی اس اکاؤنٹ کو حذف کرنا چاہتے ہیں؟';

  @override
  String get accountDeletedSuccessfully => 'اکاؤنٹ کامیابی سے حذف ہو گیا';

  @override
  String get editAccount => 'اکاؤنٹ میں ترمیم کریں';

  @override
  String get pleaseEnterAccountNumber => 'براہ کرم اکاؤنٹ نمبر درج کریں';

  @override
  String get accountHolderName => 'اکاؤنٹ ہولڈر کا نام';

  @override
  String get nameMustBeAtLeast3Chars =>
      'نام کم از کم 3 حروف پر مشتمل ہونا چاہیے';

  @override
  String get pleaseEnterAccountHolderName =>
      'براہ کرم اکاؤنٹ ہولڈر کا نام درج کریں';

  @override
  String get bankName => 'بینک کا نام';

  @override
  String get updateAccount => 'اکاؤنٹ اپ ڈیٹ کریں';

  @override
  String get setPrimary => 'بنیادی سیٹ کریں';

  @override
  String get accountAddedSuccessfully => 'اکاؤنٹ کامیابی سے شامل ہو گیا';

  @override
  String get accountUpdatedSuccessfully => 'اکاؤنٹ کامیابی سے اپ ڈیٹ ہو گیا';

  @override
  String get savings => 'سیونگز (Savings)';

  @override
  String get enterAccountHolderName => 'اکاؤنٹ ہولڈر کا نام درج کریں';

  @override
  String get enterifscCode => 'آئی بی اے این (IBAN) درج کریں';

  @override
  String get enterBankName => 'بینک کا نام درج کریں';

  @override
  String get enterAccountNumber => 'اکاؤنٹ نمبر درج کریں';

  @override
  String get setAsPrimaryAccount => 'بنیادی اکاؤنٹ کے طور پر سیٹ کریں';

  @override
  String get pleaseEnterBankName => 'براہ کرم بینک کا نام درج کریں';

  @override
  String get pleaseEnterIfscCode => 'براہ کرم آئی بی اے این (IBAN) درج کریں';

  @override
  String get copyId => 'آئی ڈی کاپی کریں';

  @override
  String get notSelected => 'منتخب نہیں کیا گیا';

  @override
  String get quickActions => 'فوری اقدامات';

  @override
  String get refresh => 'ریفریش کریں';

  @override
  String get loadingCustomers => 'صارفین لوڈ ہو رہے ہیں...';

  @override
  String get processing => 'کارروائی جاری ہے...';

  @override
  String get allReviews => 'تمام تبصرے';

  @override
  String get service => 'سروس';

  @override
  String get ratingDistribution => 'درجہ بندی کی تقسیم';

  @override
  String get payoutRequestSuccessful => 'ادائیگی کی درخواست کامیاب';

  @override
  String get rejectedBy => 'مسترد شدہ بذریعہ';

  @override
  String get rejectedOn => 'مسترد ہوا بروز';

  @override
  String get acceptedOn => 'تصدیق شدہ بروز';

  @override
  String get acceptedBy => 'تصدیق شدہ بذریعہ';

  @override
  String get completedOn => 'مکمل ہوا بروز';

  @override
  String get completedBy => 'مکمل شدہ بذریعہ';

  @override
  String get confirmDetails => 'تفصیلات کی تصدیق کریں';

  @override
  String get loadingCategories => 'زمرے لوڈ ہو رہے ہیں...';

  @override
  String get pleaseUploadFiles => 'براہ کرم فائلیں اپ لوڈ کریں';

  @override
  String get confirmCompletion => 'تکمیل کی تصدیق کریں';

  @override
  String get uploadFilesTitle => 'تکمیل کا ثبوت / معاون دستاویزات';

  @override
  String get uploadHint =>
      'مکمل کام یا خریدی گئی اشیاء کو ظاہر کرنے والی تصویر یا بل اپ لوڈ کریں';

  @override
  String get pleaseUploadFilesMessage =>
      'براہ کرم تکمیل کا کم از کم ایک ثبوت / معاون دستاویز اپ لوڈ کریں';

  @override
  String get confirmCompletionMessage =>
      'کیا آپ واقعی اس بکنگ کی تکمیل کی تصدیق کرنا چاہتے ہیں؟';

  @override
  String get cannotCancel =>
      'ٹریکنگ فعال ہونے کے دوران یہ بکنگ منسوخ نہیں کی جا سکتی۔ براہ کرم پہلے ٹریکنگ روکیں، پھر آپ بکنگ منسوخ کر سکتے ہیں۔';

  @override
  String get cannotCompleteBookingWhileTracking =>
      'ٹریکنگ فعال ہونے کے دوران یہ کام مکمل نہیں کیا جا سکتا۔ براہ کرم پہلے ٹریکنگ روکیں، پھر آپ کام مکمل کر سکتے ہیں۔';

  @override
  String get editSelection => 'انتخاب میں ترمیم کریں';

  @override
  String get noRecipientsSelected => 'کوئی موصول کنندہ منتخب نہیں کیا گیا';

  @override
  String get apply => 'لاگو کریں';

  @override
  String get tapToUploadFiles => 'فائلیں اپ لوڈ کرنے کے لیے تھپتھپائیں';

  @override
  String get addRecipients => 'موصول کنندگان شامل کریں';

  @override
  String get serviceItemsCalculationNote =>
      'کل لاگت کا حساب خودکار طور پر ہر آئٹم کے لیے (مقدار × قیمت) کے طور پر کیا جائے گا اور اسے معائنہ فیس میں شامل کیا جائے گا۔';

  @override
  String get addMoreFiles => 'مزید فائلیں شامل کریں';

  @override
  String get allowedFileTypes =>
      'معاون فائل کی اقسام: jpg, jpeg, png, pdf, doc';

  @override
  String get uploadFileOrImage => 'Upload File or Image';

  @override
  String get pendingReview => 'PENDING REVIEW';

  @override
  String get uploadFiles => 'فائلیں اپ لوڈ کریں';

  @override
  String get filesAttached => 'فائلیں منسلک کر دی گئیں';

  @override
  String get costBreakdown => 'لاگت کی تفصیل';

  @override
  String get removeItem => 'آئٹم حذف کریں';

  @override
  String get removeItemConfirmation =>
      'کیا آپ واقعی اس آئٹم کو حذف کرنا چاہتے ہیں؟';

  @override
  String get remove => 'حذف کریں';

  @override
  String get noBannersAAddedYet => 'अभी تک کوئی بینر شامل نہیں کیا گیا';

  @override
  String get availableRoles => 'دستیاب کردار';

  @override
  String get fifteenpercentBonusOnEarningsandASpecialBadge =>
      'آمدنی پر 15% بونس + ایک خصوصی بیج';

  @override
  String get tenpercentBonusOnEarnings => 'آمدنی پر 10% بونس';

  @override
  String get fivepercentBonusOnEarnings => 'آمدنی پر 5% بونس';

  @override
  String get invalidAccountNumberLength => 'اکاؤنٹ نمبر کی لمبائی غلط ہے';

  @override
  String doneSelectedCount(int count) {
    return 'ہو گیا ($count منتخب)';
  }

  @override
  String technicianSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹیکنیشنز منتخب کیے گئے',
      one: '1 ٹیکنیشن منتخب کیا گیا',
      zero: 'کوئی ٹیکنیشن منتخب نہیں کیا گیا',
    );
    return '$_temp0';
  }

  @override
  String payoutRequestSuccessfulMessage(String amount) {
    return '\'$amount سعودی ریال کی ادائیگی کی درخواست جمع کر دی گئی\',';
  }

  @override
  String cashPaymentsMessage(String amount) {
    return 'نقد ادائیگیاں ($amount سعودی ریال) پہلے سے ہی آپ کے پاس ہیں';
  }

  @override
  String cannotDeleteLastContact(String contactType) {
    return 'آخری $contactType رابطہ حذف نہیں کیا جا سکتا۔ کم از کم ایک رابطہ ضروری ہے۔';
  }

  @override
  String get personalInfo => 'ذاتی معلومات';

  @override
  String get batteryOptimization => 'بیٹری آپٹیمائزیشن';

  @override
  String get locationError => 'مقام کی خرابی';

  @override
  String get locationServicesIos =>
      'یہ آئی او ایس (iOS) کے مقام کی اجازت کی خرابی ہے۔ براہ کرم اپنی مقام کی ترتیبات چیک کریں۔';

  @override
  String get locationServices =>
      'براہ کرم اپنے آلے کی ترتیبات میں مقام کی خدمات فعال کریں۔';

  @override
  String get locationPermission =>
      'براہ کرم ترتیبات میں مقام کی اجازت دیں اور بیک گراؤنڈ ٹریکنگ کے لیے \"ہمیشہ اجازت دیں\" کو منتخب کریں۔';

  @override
  String get batteryOptimizationWarning =>
      'قابل اعتماد بیک گراؤنڈ لوکیشن ٹریکنگ کے لیے، براہ کرم اس ایپ کے لیے بیٹری آپٹیمائزیشن کو غیر فعال کریں۔ یہ اس بات کو یقینی بناتا ہے کہ ایپ بیک گراؤنڈ میں ہونے پر بھی لوکیشن اپ ڈیٹس جاری رہیں۔';

  @override
  String get bookingHistory => 'بکنگ کی تاریخ';

  @override
  String get pleaseSelectAtLeastOneRecipient =>
      'براہ کرم کم از کم ایک موصول کنندہ منتخب کریں';

  @override
  String get fillInAtLeastEnglishOrArabicMessageContent =>
      'براہ کرم کم از کم انگریزی یا عربی پیغام کا مواد پُر کریں';

  @override
  String get searchByNameEmailOrPhone => 'نام، ای میل، یا فون سے تلاش کریں...';

  @override
  String get noFcmTokenAvailable => 'کوئی ایف سی ایم (FCM) ٹوکن دستیاب نہیں ہے';

  @override
  String get selectRecipients => 'موصول کنندگان منتخب کریں';

  @override
  String get removeAll => 'سب حذف کریں';

  @override
  String get documents => 'اپ لوڈ کردہ دستاویزات';

  @override
  String get allData => 'تمام متعلقہ ڈیٹا';

  @override
  String get networkError => 'نیٹ ورک کی خرابی';

  @override
  String get biometricEnabled => 'بائیومیٹرک تصدیق فعال ہے';

  @override
  String get biometricDisabled => 'بائیومیٹرک تصدیق غیر فعال ہے';

  @override
  String get disableBiometricWarning =>
      'بائیومیٹرک تصدیق کو غیر فعال کرنے سے آپ فنگر پرنٹ کا استعمال کرتے ہوئے لاگ ان نہیں کر سکیں گے۔';

  @override
  String get youWillNeedPhoneOtp =>
      'آپ کو لاگ ان کرنے کے لیے اپنے فون نمبر اور او ٹی پی (OTP) کو استعمال کرنے کی ضرورت ہوگی۔';

  @override
  String get whatWillBeDeleted => 'کیا حذف کر دیا جائے گا:';

  @override
  String get disable => 'غیر فعال کریں';

  @override
  String get disableBiometric => 'بائیومیٹرک غیر فعال کریں؟';

  @override
  String get optional => 'اختیاری';

  @override
  String get province => 'صوبہ';

  @override
  String get pleaseSelectCity => 'براہ کرم شہر منتخب کریں';

  @override
  String get pleaseSelectGovernorate => 'براہ کرم گورنریٹ منتخب کریں';

  @override
  String get governorate => 'گورنریٹ';

  @override
  String get neighborhood => 'علاقہ';

  @override
  String get pleaseSelectNeighborhood => 'براہ کرم علاقہ منتخب کریں';

  @override
  String get pleaseSelectProvince => 'براہ کرم صوبہ منتخب کریں';

  @override
  String get otpExpired => 'او ٹی پی (OTP) ختم ہو گیا';

  @override
  String get invalidOTP => 'غلط او ٹی پی (OTP)';

  @override
  String get invalidPhoneNumber => 'غلط فون نمبر';

  @override
  String get otpSentSuccessfully => 'او ٹی پی (OTP) کامیابی سے بھیج دیا گیا';

  @override
  String get otpCode => 'او ٹی پی (OTP) کوڈ';

  @override
  String get registerAsTechinicianInfo =>
      'ٹیکنیشن اکاؤنٹ بنانے کے لیے اپنا فون نمبر رجسٹر کریں';

  @override
  String get phoneAlreadyRegistered => 'فون نمبر پہلے سے رجسٹرڈ ہے';

  @override
  String get invalidOtpCode => 'غلط او ٹی پی (OTP) کوڈ';

  @override
  String get quotaExceeded => 'کوٹہ ختم ہو گیا';

  @override
  String get internalError => 'اندرونی خرابی';

  @override
  String get resend => 'دوبارہ بھیجیں';

  @override
  String get or => 'یا';

  @override
  String get loginWithBiometric => 'بائیومیٹرک کے ساتھ لاگ ان کریں';

  @override
  String get migratingData => 'ڈیٹا منتقل کیا جا رہا ہے';

  @override
  String get weAreMigratingYourData => 'ہم آپ کا ڈیٹا منتقل کر رہے ہیں';

  @override
  String get pleaseDontCloseTheApp => 'براہ کرم ایپ بند نہ کریں';

  @override
  String get transferringData => 'ڈیٹا کی منتقلی';

  @override
  String get fullName => 'مکمل نام';

  @override
  String get sendingOTP => 'او ٹی پی (OTP) بھیجا جا رہا ہے';

  @override
  String get cancelRegistration => 'رجسٹریشن منسوخ کریں';

  @override
  String get loggingIn => 'لاگ ان کیا جا رہا ہے...';

  @override
  String get didNotReceiveOTP => 'او ٹی پی (OTP) موصول نہیں ہوا؟';

  @override
  String get cancelRegistrationConfirmation =>
      'کیا آپ واقعی رجسٹریشن منسوخ کرنا چاہتے ہیں؟';

  @override
  String get registrationSuccessful => 'رجسٹریشن کامیاب';

  @override
  String get otpMustBe6Digits => 'او ٹی پی (OTP) 6 ہندسوں پر مشتمل ہونا چاہیے';

  @override
  String get pleaseEnterOTP => 'براہ کرم او ٹی پی (OTP) درج کریں';

  @override
  String get resendOTP => 'او ٹی پی (OTP) دوبارہ بھیجیں';

  @override
  String get enterReasonForCancel => 'منسوخی کی وجہ درج کریں';

  @override
  String get enterReasonForReject => 'مسترد کرنے کی وجہ درج کریں';

  @override
  String get noWarrantyRequests => 'کوئی وارنٹی درخواستیں نہیں ہیں';

  @override
  String get completeWarrantyRepair => 'وارنٹی مرمت مکمل کریں';

  @override
  String get areYouSureYouWantToCompleteThisWarrantyRepairThisIsAFreeService =>
      'کیا آپ واقعی یہ وارنٹی مرمت مکمل کرنا چاہتے ہیں؟ یہ ایک مفت خدمت ہے۔';

  @override
  String get areYouSureYouWantToStopTrackingThisWarrantyRepair =>
      'کیا آپ واقعی اس وارنٹی مرمت کے لیے ٹریکنگ روکنا چاہتے ہیں؟';

  @override
  String get areYouSureYouWantToStartTrackingThisWarrantyRepair =>
      'کیا آپ واقعی اس وارنٹی مرمت کے لیے ٹریکنگ شروع کرنا چاہتے ہیں؟';

  @override
  String get anotherBookingIsAlreadyBeingTracked =>
      'ایک اور بکنگ پہلے ہی ٹریک کی جا رہی ہے۔ براہ کرم نیا شروع کرنے سے پہلے موجودہ ٹریکنگ کو مکمل کریں یا روک دیں۔';

  @override
  String get requested => 'درخواست کی گئی';

  @override
  String
  get areYouSureYouWantToCancelThisWarrantyRepairThisActionCannotBeUndone =>
      'کیا آپ واقعی اس وارنٹی مرمت کو منسوخ کرنا چاہتے ہیں؟ یہ عمل واپس نہیں لیا جا سکتا۔';

  @override
  String get reasonMustBeAtLeast10Characters =>
      'وجہ کم از کم 10 حروف پر مشتمل ہونی چاہیے';

  @override
  String get cancelWarrantyRepair => 'وارنٹی مرمت منسوخ کریں';

  @override
  String get areYouSureYouWantToDeleteThisFile =>
      'کیا آپ واقعی اس فائل کو حذف کرنا چاہتے ہیں؟';

  @override
  String get sendOtp => 'او ٹی پی (OTP) بھیجیں';

  @override
  String get rejectWarrantyClaimMessage =>
      'براہ کرم اس وارنٹی کلیم کو مسترد کرنے کی وجہ فراہم کریں';

  @override
  String get invalidPhoneNumberLength => 'فون نمبر کی لمبائی غلط ہے';

  @override
  String get phoneNumberMustIncludeCountryCode =>
      'فون نمبر میں ملک کا کوڈ شامل ہونا چاہیے';

  @override
  String get pleaseEnterPhoneNumber => 'براہ کرم فون نمبر درج کریں';

  @override
  String get fileTooLarge => 'فائل بہت بڑی ہے (زیادہ سے زیادہ 10 ایم بی)';

  @override
  String get warrantyClaimRejected => 'وارنٹی کلیم مسترد کر دیا گیا';

  @override
  String get rejectWarrantyClaim => 'وارنٹی کلیم مسترد کریں';

  @override
  String get workCompleted => 'کام مکمل ہو گیا';

  @override
  String get resetFilters => 'فلٹرز ری سیٹ کریں';

  @override
  String get technician => 'ٹیکنیشن';

  @override
  String get noBankAccountDetailsAvailable =>
      'بینک اکاؤنٹ کی کوئی تفصیلات دستیاب نہیں ہیں';

  @override
  String get acceptWarrantyClaim => 'وارنٹی کلیم قبول کریں';

  @override
  String get areYouSureYouWantToRejectThisWarrantyClaim =>
      'کیا آپ واقعی اس وارنٹی کلیم کو مسترد کرنا چاہتے ہیں؟';

  @override
  String get acceptWarrantyClaimMessage =>
      'کیا آپ یہ وارنٹی کلیم قبول کرنا چاہتے ہیں؟';

  @override
  String get completeWorkMessage =>
      'کیا آپ واقعی اس وارنٹی کام کو مکمل شدہ قرار دینا چاہتے ہیں؟';

  @override
  String get startWorkMessage =>
      'کیا آپ اس وارنٹی کلیم پر کام شروع کرنے کے لیے تیار ہیں؟';

  @override
  String get stopTrackingMessage =>
      'کیا آپ اس وارنٹی کام کے لیے ٹریکنگ روکنا چاہتے ہیں؟';

  @override
  String get warrantyClaimCancelled => 'وارنٹی کلیم منسوخ ہو گیا';

  @override
  String get cancelWarrantyClaim => 'وارنٹی کلیم منسوخ کریں';

  @override
  String get cancelWork => 'کام منسوخ کریں';

  @override
  String get cancelWarrantyClaimMessage =>
      'براہ کرم اس وارنٹی کام کو منسوخ کرنے کی وجہ فراہم کریں';

  @override
  String get cropDocument => 'دستاویز کراپ کریں';

  @override
  String get tapToRetry => 'دوبارہ کوشش کرنے کے لیے تھپتھپائیں';

  @override
  String get completeRegistration => 'رجسٹریشن مکمل کریں';

  @override
  String get chooseFromList => 'فہرست میں سے منتخب کریں';

  @override
  String get nameTooShort => 'نام بہت چھوٹا ہے';

  @override
  String get pleaseEnterYourName => 'براہ کرم اپنا نام درج کریں';

  @override
  String get uploadCertifications => 'سرٹیفیکیشنز اپ لوڈ کریں';

  @override
  String get certifications => 'سرٹیفیکیشنز';

  @override
  String get certificate => 'سرٹیفکیٹ';

  @override
  String get idDocumentUploaded => 'شناختی دستاویز اپ لوڈ کر دی گئی';

  @override
  String get uploadIdDocument => 'شناختی دستاویز اپ لوڈ کریں';

  @override
  String get idDocument => 'شناختی دستاویز';

  @override
  String get pleaseUploadIdDocument => 'براہ کرم شناختی دستاویز اپ لوڈ کریں';

  @override
  String get pleaseSelectLocation => 'براہ کرم مقام منتخب کریں';

  @override
  String get creatingAccount => 'آپ کا اکاؤنٹ بنایا جا رہا ہے';

  @override
  String get pleaseWait => 'براہ کرم انتظار کریں...';

  @override
  String get noJobCategoriesAvailable => 'کوئی جاب کیٹیگریز دستیاب نہیں ہیں';

  @override
  String get availabilityStatus => 'دستیابی کی صورتحال';

  @override
  String get youAreNowOnline => 'اب آپ آن لائن ہیں';

  @override
  String get youAreNowOffline => 'اب آپ آف لائن ہیں';

  @override
  String get youAreCurrentlyUnavailable =>
      'آپ فی الحال درخواستوں کے لیے دستیاب نہیں ہیں';

  @override
  String get youAreAvailableForRequests => 'آپ درخواستوں کے لیے دستیاب ہیں';

  @override
  String get files => 'فائلیں';

  @override
  String get phoneNumberAlreadyUpdated => 'فون نمبر پہلے ہی اپ ڈیٹ ہو چکا ہے';

  @override
  String get phoneNumberFormatHint => 'فون نمبر 05 سے شروع ہونا چاہیے';

  @override
  String get manageTransactions => 'لین دین کا انتظام کریں';

  @override
  String get noTransactionsFound => 'کوئی لین دین نہیں ملا';

  @override
  String get tooManyAttempts => 'بہت زیادہ کوششیں';

  @override
  String get cash => 'نقد';

  @override
  String get transactions => 'لین دین';

  @override
  String get transactionDetails => 'لین دین کی تفصیلات';

  @override
  String get pleaseSelectAllLocationFields =>
      'براہ کرم مقام کے تمام فیلڈز منتخب کریں';

  @override
  String get bookingName => 'بکنگ کا نام';

  @override
  String get technicianName => 'ٹیکنیشن کا نام';

  @override
  String get changeIdDocument => 'شناختی دستاویز تبدیل کریں';

  @override
  String get notAssigned => 'تفویض نہیں کیا گیا';

  @override
  String get date => 'تاریخ';

  @override
  String get removeFile => 'فائل حذف کریں';

  @override
  String get removeFileConfirmation =>
      'کیا آپ واقعی اس فائل کو حذف کرنا چاہتے ہیں؟';

  @override
  String get errorSendingNotifications => 'اطلاعات بھیجنے میں خرابی';

  @override
  String get fillInBothEnglishAndArabicMessageContent =>
      'براہ کرم انگریزی اور عربی دونوں پیغام کا مواد پُر کریں';

  @override
  String notificationSenttoTechnicians(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ٹیکنیشنز کو اطلاع بھیج دی گئی۔',
      one: '1 ٹیکنیشن کو اطلاع بھیج دی گئی۔',
    );
    return '$_temp0';
  }

  @override
  String get locationTracking => 'لوکیشن ٹریکنگ';

  @override
  String get trackingInactive => 'ٹریکنگ غیر فعال';

  @override
  String get trackingActive => 'ٹریکنگ فعال';

  @override
  String get fix => 'ٹھیک کریں';

  @override
  String get locationTrackingStartedSuccessfully =>
      'لوکیشن ٹریکنگ کامیابی سے شروع ہو گئی';

  @override
  String get locationTrackingHelpText =>
      'لوکیشن ٹریکنگ صارفین کو آپ کی پیش رفت ٹریک کرنے میں مدد دیتی ہے۔ مقام کی خدمات کو فعال رکھنا یقینی بنائیں۔';

  @override
  String get batteryOptimizationEnabled =>
      'بیٹری آپٹیمائزیشن فعال ہے۔ یہ بیک گراؤنڈ لوکیشن ٹریکنگ کو متاثر کر سکتا ہے۔';

  @override
  String get agentAssignedSuccessfully => 'ٹیکنیشن کامیابی سے تفویض ہو گیا';

  @override
  String get orderRejectedSuccessfully => 'آرڈر کامیابی سے مسترد کر دیا گیا';

  @override
  String get copiedToClipboard => 'کلپ بورڈ پر کاپی ہو گیا';

  @override
  String get couldNotLaunchPhone => 'فون ایپ نہیں کھولی جا سکی';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منٹ پہلے',
      one: '$count منٹ پہلے',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دن پہلے',
      one: '$count دن پہلے',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گھنٹے پہلے',
      one: '$count گھنٹہ پہلے',
    );
    return '$_temp0';
  }

  @override
  String get paymentCompletedAt => 'ادائیگی مکمل ہوئی بروز';

  @override
  String get more => 'مزید';

  @override
  String get amountToBePaid => 'ادا کی جانے والی رقم';

  @override
  String get cannotRequestPayoutPendingRequest =>
      'آپ کی ایک ادائیگی کی درخواست پہلے ہی زیر التوا ہے۔ براہ کرم اس کے منظور یا مسترد ہونے تک انتظار کریں۔';

  @override
  String get paidAmount => 'ادا شدہ رقم';

  @override
  String get customerInformation => 'صارف کی معلومات';

  @override
  String get serviceInformation => 'سروس کی معلومات';

  @override
  String get termsAndConditions => 'شرائط و ضوابط';

  @override
  String get termsOfUse => 'استعمال کی شرائط';

  @override
  String get privacyPolicy => 'رازداری کی پالیسی';

  @override
  String get and => 'اور';

  @override
  String get copy => 'کاپی کریں';

  @override
  String get introduction => 'تعارف';

  @override
  String get policy1title => 'ڈیٹا جو ہم جمع کرتے ہیں';

  @override
  String get policy2title => 'ہم اسے کیسے استعمال کرتے ہیں';

  @override
  String get policy3title => 'ڈیٹا کا اشتراک';

  @override
  String get terms1title => 'درخواست کی ذمہ داری';

  @override
  String get terms2title => 'معائنہ فیس';

  @override
  String get terms3title => 'ادائیگی اور حتمی لاگت';

  @override
  String get terms4title => 'وارنٹی (گارنٹی)';

  @override
  String get terms5title => 'درجہ بندی';

  @override
  String get searchByCustomerName => 'صارف کے نام سے تلاش کریں';

  @override
  String get phoneNumberUpdateInfo =>
      'فون نمبر اپ ڈیٹ کرنے کے لیے \'05\' سے شروع ہونے والا فون نمبر درج کریں';

  @override
  String get termsIntroduction =>
      'آپ کا اس ایپلیکیشن کا استعمال ان شرائط کی مکمل اور غیر مشروط قبولیت ہے۔ ایپلیکیشن صرف ایک الیکٹرانک درمیانی پلیٹ فارم کے طور پر کام کرتی ہے جو آپ کو سروس فراہم کرنے والوں (ٹیکنیشنز) سے جوڑتی ہے۔';

  @override
  String get terms1 =>
      'درخواست کی ذمہ داری: آپ مسئلے کی درست اور کافی تفصیل (متن، تصویر، ویڈیو) اور سروس کے مقام فراہم کرنے کے پابند ہیں تاکہ ٹیکنیشن جواب دے سکے۔';

  @override
  String get terms2 =>
      'معائنہ فیس: آپ ٹیکنیشن کے درخواست قبول کرنے اور مقام پر جانے کے فوراً بعد طے شدہ معائنہ/کال آؤٹ فیس (اگر قابل اطلاق ہو) ادا کرنے کے ذمہ دار ہیں۔ یہ فیس عام طور پر ناقابل واپسی ہوتی ہے۔';

  @override
  String get terms3 =>
      'ادائیگی اور حتمی لاگت: سروس کی کل لاگت معائنے کے بعد براہ راست ٹیکنیشن کے ساتھ طے کی جاتی ہے، اور کام شروع ہونے سے پہلے ایپلیکیشن کے ذریعے منظور ہونی چاہیے۔ آپ طے شدہ رقم پوری ادا کرنے کے ذمہ دار ہیں۔';

  @override
  String get terms4p1 => 'وارنٹی (گارنٹی): مکمل شدہ کام پلیٹ فارم کی';

  @override
  String get warrantyPolicy => 'وارنٹی پالیسی';

  @override
  String get terms4p2 =>
      'کے تابع ہے، جس کی مکمل تفصیلات وقف شدہ لنک کے ذریعے دیکھی جا سکتی ہیں۔';

  @override
  String get terms5 =>
      'آپ کو سروس مکمل ہونے کے بعد ٹیکنیشن کی کارکردگی کی درجہ بندی کرنے کا حق ہے، اور آپ کو یقینی بنانا چاہیے کہ درجہ بندی دیانتدارانہ اور غیر جانبدارانہ ہو۔';

  @override
  String get policy1 =>
      'نام، فون نمبر، ای میل ایڈریس، درست سروس لوکیشن ایڈریس، آرڈر کی تاریخ، اور ٹیکنیشن کی درجہ بندی۔';

  @override
  String get policy2 =>
      'آپ کو ٹیکنیشنز کے ساتھ ملانے، بکنگ اور ادائیگی کے عمل کو آسان بنانے، اور آرڈر کی اطلاعات بھیجنے کے لیے استعمال کیا جاتا ہے۔';

  @override
  String get policy3 =>
      'آپ کا نام، فون نمبر، اور مقام کا پتہ صرف اس ٹیکنیشن کے ساتھ شیئر کیا جاتا ہے جس نے سروس کی فراہمی کے لیے آپ کی درخواست قبول کی ہو۔';

  @override
  String get waitingForAdminAction => 'ایڈمن کی کارروائی کا انتظار ہے';

  @override
  String get whatsCovered => 'کیا شامل ہے';

  @override
  String get issueone => 'غلط تنصیب یا ناقص کاریگری';

  @override
  String get issuetwo => 'ٹیکنیشن کی غیر معیاری کارکردگی';

  @override
  String get issuethree => 'وہی اصل خرابی جو ٹھیک کی گئی تھی';

  @override
  String get issuefour =>
      'ایک بار کے لیے موزوں، تکمیل کی تاریخ سے 7 دنوں کے اندر';

  @override
  String get whatsNotCovered => 'کیا شامل نہیں ہے';

  @override
  String get notissueone => 'ناقص اسپیئر پارٹس یا مواد';

  @override
  String get notissuetwo => 'سروس کے بعد غلط استعمال یا چھیڑ چھاڑ';

  @override
  String get notissuethree => 'فریق ثالث کی مداخلت';

  @override
  String get notissuefour => 'بجلی کا اتار چڑھاؤ، پانی کا رساؤ، قدرتی آفات';

  @override
  String get notissuefive => 'عام توڑ پھوڑ';

  @override
  String get showMore => 'مزید دکھائیں';

  @override
  String get loading => 'لوڈ ہو رہا ہے...';

  @override
  String get wallet => 'بٹوے';

  @override
  String get walletSynced => 'والٹ کامیابی سے ہم آہنگ (Sync) ہو گیا';

  @override
  String get payoutRequested => 'ادائیگی کی درخواست کامیابی سے جمع ہو گئی';

  @override
  String get balanceBreakdown => 'بیلنس کی تفصیل';

  @override
  String get selectAmounts => 'رقوم منتخب کریں';

  @override
  String get available => 'دستیاب';

  @override
  String get paid => 'ادا شدہ';

  @override
  String get tips => 'ٹپس';

  @override
  String get payoutPending => 'ادائیگی زیر التوا';

  @override
  String get requestedAmount => 'درخواست کردہ رقم';

  @override
  String get payoutNote =>
      'نوٹ: یہ درخواست منظوری کے لیے ایڈمن کو بھیجی جائے گی۔ کل دستیاب بیلنس کی درخواست کی جائے گی۔';

  @override
  String get noPayoutRequests => 'ابھی تک کوئی ادائیگی کی درخواست نہیں ہے';

  @override
  String get max => 'زیادہ سے زیادہ';

  @override
  String get min => 'کم از کم';

  @override
  String get useMax => 'زیادہ سے زیادہ استعمال کریں';

  @override
  String get searchByWorkerName => 'ورکر کے نام سے تلاش کریں';

  @override
  String get noResultsFound => 'کوئی نتائج نہیں ملے';

  @override
  String get totalAmount => 'کل رقم';

  @override
  String get payoutDetails => 'ادائیگی کی تفصیلات';

  @override
  String get workerName => 'ورکر کا نام';

  @override
  String get payoutAccount => 'ادائیگی کا اکاؤنٹ';

  @override
  String get requestDate => 'درخواست کی تاریخ';

  @override
  String get rejectionReason => 'مسترد کرنے کی وجہ';

  @override
  String get enterTransactionId => 'ٹرانزیکشن آئی ڈی درج کریں';

  @override
  String get uploadPaymentProof => 'ادائیگی کا ثبوت اپ لوڈ کریں';

  @override
  String get proofUploaded => 'ثبوت کامیابی سے اپ لوڈ ہو گیا';

  @override
  String get enterReason => 'وجہ درج کریں';

  @override
  String get cancelPayoutConfirmation =>
      'کیا آپ واقعی اس ادائیگی کی درخواست کو منسوخ کرنا چاہتے ہیں؟';

  @override
  String get payoutCancelled => 'ادائیگی کی درخواست کامیابی سے منسوخ ہو گئی';

  @override
  String get confirmPayoutRequest =>
      'آپ اپنے کل دستیاب بیلنس کی ادائیگی کی درخواست کر رہے ہیں';

  @override
  String get bonusIncludedInWallet =>
      'بونس آپ کے متحد بٹوے میں شامل ہے۔ آمدنی (Earnings) پیج سے ادائیگی کی درخواست کریں۔';

  @override
  String get claimText =>
      'وارنٹی کلیم کرنے کے لیے، سروس مکمل ہونے کے 7 دنوں کے اندر ایپ کے ذریعے درخواست جمع کرائیں۔ وارنٹی کلیم صرف ایک بار کیا جا سکتا ہے۔';

  @override
  String get syncWallet => 'والٹ ہم آہنگ کریں';

  @override
  String get alreadyInHand => 'پہلے سے پاس موجود ہے';

  @override
  String get minimumPayoutAmount => 'ادائیگی کی کم از کم رقم 10 سعودی ریال ہے';

  @override
  String get enableAvailability => 'دستیابی فعال کریں';

  @override
  String get welcomeDescription =>
      'ہمیں آپ کو ابو جلمبو ٹیم میں شامل کرنے پر خوشی ہے۔\n\n• ہر سروس کے لیے ایک ہفتے کی وارنٹی\n• اعلی درجہ بندی مستقبل میں انتخاب کے امکانات کو بڑھاتی ہے\n• اعلی کارکردگی دکھانے والے ٹیکنیشنز کے لیے خصوصی انعامات';

  @override
  String welcomeToAboGlumboTechnician(String name) {
    return 'خوش آمدید $name';
  }

  @override
  String get onlyMainAdminCanManageAdminAccess =>
      'صرف مین ایڈمن ہی ایڈمن رسائی کا انتظام کر سکتا ہے';

  @override
  String get cannotModifyMainAdminAccount =>
      'مین ایڈمن اکاؤنٹ میں ترمیم نہیں کی جا سکتی';

  @override
  String get adminAccessRevokedFor => 'ایڈمن رسائی منسوخ کر دی گئی برائے';

  @override
  String get adminAccess => 'ایڈمن رسائی';

  @override
  String get selectAdminAccessLevelFor => 'ایڈمن رسائی کی سطح منتخب کریں برائے';

  @override
  String get fullAdmin => 'مکمل ایڈمن';

  @override
  String get customerService => 'کسٹمر سروس';

  @override
  String get grantAccess => 'رسائی دیں';

  @override
  String get grantingAdminAccess => 'ایڈمن رسائی دی جا رہی ہے';

  @override
  String get adminAccessGrantedTo => 'ایڈمن رسائی دے دی گئی کو';

  @override
  String get revokeAdminAccess => 'ایڈمن رسائی منسوخ کریں';

  @override
  String get revokingAdminAccess => 'ایڈمن رسائی منسوخ کی جا رہی ہے';

  @override
  String get revoke => 'منسوخ کریں';

  @override
  String get switchToAdmin => 'ایڈمن پر سوئچ کریں';

  @override
  String get manageAdmins => 'ایڈمنز کا انتظام کریں';

  @override
  String get searchAdmins => 'ایڈمنز تلاش کریں...';

  @override
  String get aboutUs => 'ہمارے بارے میں';

  @override
  String get noAdminsFound => 'کوئی ایڈمن نہیں ملا';

  @override
  String get loadingAdmins => 'ایڈمنز لوڈ ہو رہے ہیں...';

  @override
  String get noAdminsMatchYourFilters =>
      'کوئی ایڈمن آپ کے فلٹرز سے مطابقت نہیں رکھتا';

  @override
  String get grantedOn => 'دیا گیا بروز';

  @override
  String get selectRecipientType => 'موصول کنندہ کی قسم منتخب کریں';

  @override
  String get recipientsSelected => 'موصول کنندگان منتخب کیے گئے';

  @override
  String get areYouSureYouWantToRevokeAdminAccessFor =>
      'کیا آپ واقعی ایڈمن رسائی منسوخ کرنا چاہتے ہیں برائے';

  @override
  String get onlyTheMainAdminCanRevokeAdminAccess =>
      'صرف مین ایڈمن ہی ایڈمن رسائی منسوخ کر سکتا ہے';

  @override
  String get accessToAllAdminFeaturesExceptManagingOtherAdmins =>
      'دوسرے ایڈمنز کے انتظام کے علاوہ تمام ایڈمن فیچرز تک رسائی';

  @override
  String get viewOnlyAccessToCustomersTechniciansAndSupport =>
      'صارفین، ٹیکنیشنز اور سپورٹ تک صرف دیکھنے کی رسائی';

  @override
  String get loginDescription =>
      'کام کے لیے تیار؟ قریبی جابز اور بہتر آمدنی آپ کا انتظار کر رہی ہے۔';

  @override
  String get aboutUsTitle => 'ہمارے بارے میں';

  @override
  String get aboutUsHeadline =>
      'پیشہ ورانہ ترقی کا آپ کا سفر یہاں سے شروع ہوتا ہے';

  @override
  String get aboutUsIntro =>
      'ہمارے تصدیق شدہ ٹیکنیشنز کے نیٹ ورک میں شامل ہوں اور مالی آزادی اور پیشہ ورانہ فضیلت کی طرف اپنا اگلا قدم اٹھائیں۔ ہم آپ کو صرف ایک جاب نہیں پیش کرتے؛ ہم آپ کو ایک ایسا پارٹنر پیش کرتے ہیں جو آپ کی کامیابی کو یقینی بنانے کے لیے وقف ہے۔';

  @override
  String get aboutRewardsTitle => 'آپ کے انعامات اور مراعات';

  @override
  String get aboutIncentiveTitle => 'مالی ترغیبی نظام';

  @override
  String get aboutIncentiveDesc =>
      'ہمارے ٹائرڈ سسٹم (کانسی، چاندی، سونا، پلاٹینم) کے ذریعے ترقی کریں۔ آپ جتنی زیادہ جابز مکمل کریں گے اور آپ کی درجہ بندی جتنی زیادہ ہوگی (پلاٹینم کے لیے 4.8+)، آپ اتنا ہی زیادہ بونس فیصد کمائیں گے (15% بونس تک)۔';

  @override
  String get aboutEarningsTitle => 'شفاف ماہانہ آمدنی';

  @override
  String get aboutEarningsDesc =>
      'اپنی ماہانہ آمدنی کو ٹریک کریں اور \"ادائیگی کی درخواست کریں\" بٹن کا استعمال کرتے ہوئے آسانی سے اپنی ادائیگی کی درخواست کریں۔';

  @override
  String get aboutSupportTitle => 'کارکردگی اور تعاون';

  @override
  String get aboutFlexibilityTitle => 'مکمل لچک';

  @override
  String get aboutFlexibilityDesc =>
      'آپ اپنے کام کے اوقات اور ان علاقوں کا تعین خود کرتے ہیں جن کا آپ احاطہ کرتے ہیں۔ ہم آپ کی ترجیحات کی بنیاد پر آپ کو سروس کی درخواستیں فراہم کرنے کے لیے کام کرتے ہیں۔';

  @override
  String get aboutNoHuntingTitle => 'زیرو کسٹمر ہنٹنگ';

  @override
  String get aboutNoHuntingDesc =>
      'کلائنٹس کے پیچھے بھاگنے کو الوداع کہیں۔ ہم آپ کو قابل اعتماد صارفین کی طرف سے تیار جاب کی درخواستیں فراہم کرتے ہیں، جو کام کے مسلسل بہاؤ کو یقینی بناتی ہیں۔';

  @override
  String get aboutTransparencyTitle => 'ضمانت شدہ شفافیت';

  @override
  String get aboutTransparencyDesc =>
      'تمام سروس کی تفصیلات اور قیمتیں پہلے سے دستاویزی ہوتی ہیں، جو آپ اور صارف کے درمیان تمام مالی معاملات میں وضاحت کو یقینی بناتی ہیں۔';

  @override
  String locationNumber(int number) {
    return 'مقام $number';
  }

  @override
  String get selectedLocation => 'منتخب مقام';

  @override
  String get mapPickerInstructions =>
      '• نیا علاقہ بنانے کے لیے \'علاقہ شامل کریں\' پر کلک کریں\n• باؤنڈری پوائنٹس شامل کرنے کے لیے نقشے پر تھپتھپائیں (کم از کم 4 پوائنٹس درکار ہیں)\n• مکمل ہونے پر \'علاقہ مکمل کریں\' پر کلک کریں\n• مقام کی تفصیلات درج کریں اور تصدیق کریں\n• تفصیلات کو اپ ڈیٹ کرنے کے لیے ترمیم آئیکن کا استعمال کریں یا علاقے کو ہٹانے کے لیے سرخ X کا استعمال کریں';

  @override
  String get tapOnMapToDrawPolygonPoints =>
      'پولی گون پوائنٹس کھینچنے کے لیے نقشے پر تھپتھپائیں';

  @override
  String get addRegion => 'علاقہ شامل کریں';

  @override
  String get regionMustHaveAtLeast4Points =>
      'ایک علاقے کو مکمل ہونے کے لیے کم از کم 4 پوائنٹس کا ہونا ضروری ہے۔';

  @override
  String completeRegionWithPts(int count) {
    return 'علاقہ مکمل کریں ($count پوائنٹس)';
  }

  @override
  String get clearDrawing => 'ڈرائنگ صاف کریں';

  @override
  String get pleaseDrawPolygonFirst => 'براہ کرم پہلے پولی گون کھینچیں';

  @override
  String get pleaseDrawPolygonAreaFirst =>
      'براہ کرم پہلے نقشے پر پولی گون کا علاقہ کھینچیں';

  @override
  String get priority => 'ترجیح';

  @override
  String get enterPriority => 'ترجیح درج کریں';

  @override
  String get pleaseEnterPriority => 'براہ کرم ترجیح درج کریں';

  @override
  String pointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پوائنٹس',
      one: '1 پوائنٹ',
    );
    return '$_temp0';
  }

  @override
  String locationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقامات منتخب کیے گئے',
      one: '$count مقام منتخب کیا گیا',
    );
    return '$_temp0';
  }

  @override
  String get addCurrentLocation => 'موجودہ مقام شامل کریں';

  @override
  String get howToUse => 'استعمال کا طریقہ';

  @override
  String get searchForAPlace => 'جگہ تلاش کریں';

  @override
  String get myLocation => 'میرا مقام';

  @override
  String get noLocationSelected => 'کوئی مقام منتخب نہیں کیا گیا';

  @override
  String get tapOnMapToSelect => 'منتخب کرنے کے لیے نقشے پر تھپتھپائیں';

  @override
  String get confirmLocations => 'مقامات کی تصدیق کریں';

  @override
  String get radius => 'ریڈیئس';

  @override
  String get locationAlreadyAdded => 'مقام پہلے ہی شامل ہو چکا ہے';

  @override
  String get locationAddedToList => 'مقام فہرست میں شامل کر دیا گیا';

  @override
  String get locationNotFound => 'مقام نہیں ملا';

  @override
  String get errorFindingLocation => 'مقام تلاش کرنے میں خرابی';

  @override
  String get editLocation => 'مقام میں ترمیم کریں';

  @override
  String get addLocation => 'مقام شامل کریں';

  @override
  String get englishName => 'انگریزی نام';

  @override
  String get pleaseEnterEnglishName => 'براہ کرم انگریزی نام درج کریں';

  @override
  String get arabicName => 'عربی نام';

  @override
  String get pleaseEnterArabicName => 'براہ کرم عربی نام درج کریں';

  @override
  String get pleaseEnterArabicNameOnly => 'براہ کرم صرف عربی نام درج کریں';

  @override
  String get radiusInMeters => 'میٹر میں ریڈیئس';

  @override
  String get enterRadiusInMeters => 'میٹر میں ریڈیئس درج کریں';

  @override
  String get meters => 'میٹر';

  @override
  String get pleaseEnterRadius => 'براہ کرم ریڈیئس درج کریں';

  @override
  String get addArea => 'علاقہ شامل کریں';

  @override
  String get gettingAddress => 'پتہ حاصل کیا جا رہا ہے...';

  @override
  String get serviceRadius => 'سروس ریڈیئس';

  @override
  String get km => 'کلومیٹر';

  @override
  String get tapOnMapOrSearchToAddLocations =>
      'مقامات شامل کرنے کے نقشے پر تھپتھپائیں یا تلاش کریں';

  @override
  String get selectedLocations => 'منتخب مقامات';

  @override
  String get profileSentForVerification =>
      'آپ کا پروفائل تصدیق کے لیے بھیج دیا گیا ہے!';

  @override
  String get verificationPending => 'تصدیق زیر التوا ہے';

  @override
  String get waitingForTechnicianVerification =>
      'ٹیکنیشن کے ذریعے ادائیگی کی تصدیق کا انتظار ہے';

  @override
  String get verifyPayment => 'ادائیگی کی تصدیق کریں';

  @override
  String get confirmPaymentReceipt => 'ادائیگی کی وصولی کی تصدیق کریں';

  @override
  String get uploadTechnicianPaymentProof =>
      'ٹیکنیشن کی ادائیگی کا ثبوت اپ لوڈ کریں';

  @override
  String get paymentVerifiedSuccessfully =>
      'ادائیگی کی کامیابی سے تصدیق ہو گئی';

  @override
  String get selectFiles => 'فائلیں منتخب کریں';

  @override
  String get pleaseSelectAtLeastOneFile =>
      'براہ کرم کم از کم ایک فائل منتخب کریں';

  @override
  String get errorUploading => 'اپ لوڈ کرنے میں خرابی';

  @override
  String get warranty => 'وارنٹی';

  @override
  String get warrantyAppliedOn => 'وارنٹی لاگو ہوئی بروز';

  @override
  String get bookingIdCopied => 'بکنگ آئی ڈی کاپی ہو گئی';

  @override
  String get selectTime => 'وقت منتخب کریں';

  @override
  String get submitCounterOffer => 'جوابی پیشکش جمع کرائیں';

  @override
  String get pleaseSelectALaterTime =>
      'براہ کرم موجودہ بکنگ کے وقت سے بعد کا وقت منتخب کریں';

  @override
  String get listeningForSms => 'ایس ایم ایس کا انتظار ہے...';

  @override
  String get earningsInfoOnly => 'صرف معلوماتی مقاصد کے لیے';

  @override
  String get throughApp => 'ایپ کے ذریعے';

  @override
  String get rebookTechnician => 'ٹیکنیشن کو دوبارہ بک کریں';

  @override
  String get selectService => 'سروس منتخب کریں';

  @override
  String get rejectionProfessionalMessage =>
      'کیا آپ اس اپوائنٹمنٹ کے لیے دستیاب نہیں ہیں؟ مسترد کرنے کے بجائے، آپ کسٹمر کے لیے زیادہ مناسب وقت تجویز کر سکتے ہیں۔';

  @override
  String get proposeAlternativeTime => 'متبادل وقت تجویز کریں';

  @override
  String get areYouSure => 'کیا آپ کو یقین ہے؟';

  @override
  String get notes => 'ملاحظات';

  @override
  String get time => 'وقت';

  @override
  String get appointmentDetails => 'تقرری کی تفصیلات';

  @override
  String get residenceIDImage => 'رہائشی شناختی کارڈ کی تصویر';

  @override
  String get sponsorWorkPermit => 'سپانسر ورک پرمٹ';

  @override
  String get chamberOfCommerceApproval => 'چیمبر آف کامرس کی منظوری';

  @override
  String get certificatesOrTrainingCoursesOptional =>
      'سرٹیفکیٹ یا تربیتی کورسز (اختیاری)';

  @override
  String get uploadCertificates => 'سرٹیفکیٹ اپ لوڈ کریں';

  @override
  String get refreshLocation => 'مقام کو ریفریش کریں';

  @override
  String get selectJobRolesDescription =>
      'وہ خدمات منتخب کریں جنہیں فراہم کرنے کے آپ اہل ہیں۔';

  @override
  String get updateDocuments => 'دستاویزات اپ ڈیٹ کریں';

  @override
  String get pleaseSelectAtLeastOneDocumentToUpdate =>
      'براہ کرم دوبارہ اپ لوڈ کرنے کے لیے کم از کم ایک دستاویز کو ہٹائیں اور نئی فائل منتخب کریں';

  @override
  String reuploadFailed(String error) {
    return 'دوبارہ اپ لوڈ کرنے میں ناکامی: $error';
  }

  @override
  String get selectFile => 'فائل منتخب کریں';

  @override
  String get accountBlocked => 'اکاؤنٹ بلاک کر دیا گیا ہے';

  @override
  String get accountBlockedMessage =>
      'آپ کے اکاؤنٹ کو ایڈمن نے بلاک کر دیا ہے۔ مزید معلومات کے لیے براہ کرم سپورٹ سے رابطہ کریں۔';

  @override
  String get contactSupport => 'سپورٹ سے رابطہ کریں';

  @override
  String get applicationRejected => 'درخواست مسترد کر دی گئی';

  @override
  String get applicationRejectedMessage =>
      'بدقسمتی سے، آپ کی درخواست جائزہ لینے کے بعد مسترد کر دی گئی ہے۔ آپ نیچے وجہ دیکھ سکتے ہیں اور دوبارہ کوشش کرنے کے لیے اپنی دستاویزات کو اپ ڈیٹ کر سکتے ہیں۔';

  @override
  String get reasonForRejection => 'مسترد کرنے کی وجہ:';

  @override
  String get noReasonProvided => 'کوئی وجہ فراہم نہیں کی گئی';

  @override
  String get failedResendOtp =>
      'OTP دوبارہ بھیجنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get verificationIdNotFound =>
      'تصدیقی شناختی کارڈ نہیں ملا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get pleaseFetchLocation => 'براہ کرم اپنا موجودہ مقام حاصل کریں';

  @override
  String get pleaseSelectRole => 'براہ کرم کم از کم ایک جاب رول منتخب کریں';

  @override
  String get pleaseUploadDocuments =>
      'براہ کرم تمام ضروری دستاویزات اپ لوڈ کریں';

  @override
  String get revokeAccess => 'رسائی منسوخ کریں';

  @override
  String get coreAdminCannotRemove => 'بنیادی ایڈمن کو ہٹایا نہیں جا سکتا۔';

  @override
  String get onlyCoreAdminCanAdd =>
      'صرف بنیادی ایڈمن ہی نئے ایڈمنز شامل کر سکتا ہے۔';

  @override
  String get adminAddedSuccessfully =>
      'ایڈمن کو زیر التواء دعوت ناموں میں کامیابی سے شامل کر دیا گیا۔';

  @override
  String get failedUpdateTechStatus =>
      'ٹیکنیشن کی حیثیت اپ ڈیٹ کرنے میں ناکامی';

  @override
  String get offerAcceptedSuccessfully => 'پیشکش کامیابی سے قبول کر لی گئی';

  @override
  String get failedToSendCounter => 'جوابی پیشکش بھیجنے میں ناکامی';

  @override
  String get couldNotLaunchEmail => 'ای میل کلائنٹ شروع نہیں کیا جا سکا';

  @override
  String get couldNotLaunchWhatsapp => 'واٹس ایپ شروع نہیں کیا جا سکا';

  @override
  String get cancelLower => 'منسوخ کریں';

  @override
  String get invited => 'مدعو';

  @override
  String get accessLevelUpper => 'رسائی کی سطح';

  @override
  String get phoneUpper => 'فون';

  @override
  String get invoiceTitle => 'سروس بکنگ انوائس';

  @override
  String get invoiceWord => 'انوائس';

  @override
  String get statusPaid => 'حیثیت: ادا شدہ';

  @override
  String get billTo => 'بل بھیجیں:';

  @override
  String get bookingDetailsInvoice => 'بکنگ کی تفصیلات:';

  @override
  String get subtotal => 'مجموعی ذیلی:';

  @override
  String get inspectionFeeLabel => 'معائنہ فیس:';

  @override
  String get totalLabel => 'کل:';

  @override
  String get thankYouInvoice => 'ابو جلمبو منتخب کرنے کے لیے آپ کا شکریہ!';

  @override
  String invoiceNumber(String number) {
    return 'انوائس نمبر: $number';
  }

  @override
  String dateString(String date) {
    return 'تاریخ: $date';
  }

  @override
  String serviceLabel(String name) {
    return 'سروس: $name';
  }

  @override
  String completedAtLabel(String date) {
    return 'مکمل ہونے کی تاریخ: $date';
  }

  @override
  String paymentModeLabel(String mode) {
    return 'ادائیگی کا طریقہ: $mode';
  }

  @override
  String transactionIdLabel(String id) {
    return 'ٹرانزیکشن آئی ڈی: $id';
  }

  @override
  String warrantyLabel(String duration) {
    return 'وارنٹی: $duration';
  }

  @override
  String sarAmount(String amount) {
    return '$amount SAR';
  }

  @override
  String get onHour => 'فی گھنٹہ بکنگ';

  @override
  String get offHour => 'آف آور بکنگ';

  @override
  String get inAppEarnings => 'ان ایپ آمدنی';

  @override
  String get outsideAppEarnings => 'خارج ایپ آمدنی';

  @override
  String get earningsPeriod => 'آمدنی کا دورانیہ';

  @override
  String get selectPeriod => 'دورانیہ منتخب کریں';

  @override
  String get selectMonth => 'مہینہ منتخب کریں';

  @override
  String get customDateRange => 'حسب ضرورت تاریخ کا انتخاب';

  @override
  String get allTime => 'ہر وقت';

  @override
  String get thisMonth => 'اس مہینے';

  @override
  String get inApp => 'ان ایپ';

  @override
  String get clearWalletBalances => 'والٹ کا بیلنس صاف کریں';

  @override
  String clearWalletConfirmation(String name) {
    return 'کیا آپ واقعی $name کے والٹ بیلنس کو مکمل طور پر صاف اور دوبارہ ترتیب دینا چاہتے ہیں؟ یہ عمل ناقابل واپسی ہے۔';
  }

  @override
  String errorClearingWallet(String error) {
    return 'والٹ صاف کرنے میں خرابی: $error';
  }

  @override
  String get bookingDate => 'بکنگ کی تاریخ';

  @override
  String get yourAccountIsBeingVerified =>
      'آپ کا اکاؤنٹ ایڈمن کے ذریعے تصدیق ہو رہا ہے۔ براہ کرم بعد میں دوبارہ چیک کریں۔';

  @override
  String get aboGlumboWorker => 'ابو گلمبو ٹیکنیشن';

  @override
  String get workerCannotBeAssignedMultipleTimes =>
      'ایک ہی ٹیکنیشن کو ایک ہی وقت میں ایک سے زیادہ بکنگ پر تفویض نہیں کیا جا سکتا۔ براہ کرم مختلف وقت یا دوسرا ٹیکنیشن منتخب کریں۔';

  @override
  String get unknownWorker => 'نامعلوم ٹیکنیشن';

  @override
  String get workerCancelled => 'بکنگ ٹیکنیشن کے ذریعے منسوخ کی گئی';

  @override
  String get cancelledByWorker => 'ٹیکنیشن کے ذریعے منسوخ';

  @override
  String get workerPreviouslyCancelled => 'ٹیکنیشن نے پہلے منسوخ کیا';

  @override
  String get workerCancelledAtTime =>
      'اس ٹیکنیشن نے ایک ہی وقت میں پہلے بکنگ منسوخ کی تھی۔ بہتر قابل اعتمادی کے لیے کسی اور ٹیکنیشن کو تفویض کرنے کی سفارش کی جاتی ہے۔';

  @override
  String get workerRestrictedTitle => 'ٹیکنیشن پابند';

  @override
  String get cannotAssignCancelledWorker =>
      'ایسے ٹیکنیشن کو تفویض نہیں کیا جا سکتا جس نے پہلے منسوخ کیا ہو';

  @override
  String get workerCancelledRestrictionMessage =>
      'اس ٹیکنیشن نے پہلے بکنگ منسوخ کی ہے اور اب نئی تفویض سے محدود ہے۔ براہ کرم کوئی اور ٹیکنیشن منتخب کریں۔';

  @override
  String get managefaqs => 'اکثر پوچھے گئے سوالات کا انتظام';

  @override
  String get manageWorkers => 'ٹیکنیشنز کا انتظام';

  @override
  String get noWorkersMatchYourFilters =>
      'آپ کی تلاش کے معیار سے کوئی ٹیکنیشن مطابقت نہیں رکھتا';

  @override
  String get workerInformation => 'ٹیکنیشن کی معلومات';

  @override
  String get loadingWorkers => 'ٹیکنیشنز لوڈ ہو رہے ہیں...';

  @override
  String get serviceDeletedSuccessfully => 'سروس کامیابی سے حذف ہو گئی';

  @override
  String get netTechnicianror => 'ٹیکنیشنز لوڈ کرتے وقت خرابی پیش آئی';

  @override
  String get urdu => 'اردو';

  @override
  String errorOccurred(String error) {
    return 'خرابی: $error';
  }

  @override
  String cannotOpenFile(String path) {
    return 'فائل نہیں کھولی جا سکی: $path';
  }

  @override
  String failedToSendMessage(String error) {
    return 'پیغام بھیجنے میں ناکام: $error';
  }

  @override
  String failedToRetryMessage(String error) {
    return 'پیغام دوبارہ بھیجنے میں ناکام: $error';
  }

  @override
  String errorFetchingLocation(String error) {
    return 'مقام لانے میں خرابی: $error';
  }

  @override
  String confirmRemoveAdmin(String name) {
    return 'کیا آپ واقعی $name کی ایڈمن رسائی ختم کرنا چاہتے ہیں؟';
  }

  @override
  String adminAccessRevoked(String name) {
    return '$name کی ایڈمن رسائی منسوخ کر دی گئی';
  }

  @override
  String inviteDeleted(String name) {
    return '$name کی دعوت حذف کر دی گئی';
  }

  @override
  String get biometricError => '❌ بایومیٹرک غلطی';

  @override
  String get unknownError => 'نامعلوم غلطی';

  @override
  String get errorDuringLogin => 'لاگ ان کے دوران غلطی';

  @override
  String get filterAll => 'تمام';

  @override
  String get coreAdmin => 'بنیادی ایڈمن';

  @override
  String get addAdmin => 'ایڈمن شامل کریں';

  @override
  String get saveChanges => 'تبدیلیاں محفوظ کریں';

  @override
  String get addNewAdmin => 'نیا ایڈمن شامل کریں';

  @override
  String get editAdmin => 'ایڈمن میں ترمیم کریں';

  @override
  String get enterAdminDetails =>
      'ایڈمن کو پلیٹ فارم پر مدعو کرنے کے لیے تفصیلات درج کریں۔';

  @override
  String get editAdminDetails =>
      'ایڈمن کی تفصیلات اور رسائی کی سطح میں ترمیم کریں۔';

  @override
  String get adminUpdatedSuccessfully =>
      'ایڈمن کو کامیابی کے ساتھ اپ ڈیٹ کر دیا گیا ہے۔';

  @override
  String get adminPhoneExists => 'اس فون نمبر کے ساتھ ایڈمن پہلے ہی موجود ہے۔';

  @override
  String get adminPhoneInvited =>
      'اس فون نمبر کے ساتھ ایڈمن کو پہلے ہی مدعو کیا گیا ہے۔';

  @override
  String get enterFullName => 'پورا نام درج کریں';

  @override
  String get pleaseEnterName => 'براہ کرم نام درج کریں';

  @override
  String get enterEmailAddress => 'ای میل ایڈریس درج کریں';

  @override
  String get egPhoneNumber => 'مثال +9665XXXXXXXX';

  @override
  String get accessLevelTitle => 'رسائی کی سطح';

  @override
  String get customerServiceOnly => 'صرف کسٹمر سروس';

  @override
  String get customerServiceDesc =>
      'بکنگ اور انتظام کے حصوں تک صرف دیکھنے کی رسائی۔';

  @override
  String get fullAdminAccess => 'مکمل ایڈمن کی رسائی';

  @override
  String get fullAdminDesc => 'دوسرے ایڈمنز کے انتظام کے علاوہ مکمل رسائی۔';

  @override
  String get phoneNoteWithCountryCode =>
      '(فون نمبر ملک کے کوڈ کے ساتھ درج کریں مثال : 966+)';

  @override
  String get selectNewDateAppointment =>
      'ملاقات کے لیے نئی تاریخ اور وقت منتخب کریں';

  @override
  String get notAvailable => 'دستیاب نہیں';

  @override
  String get noAdditionalDescription => 'کوئی اضافی تفصیل نہیں';

  @override
  String get distance => 'فاصلہ';

  @override
  String get discountAmount => 'رعایتی رقم';

  @override
  String get discountAppliesToInspectionFeeOnly =>
      'رعایت صرف معائنہ کی فیس پر لاگو ہوتی ہے۔';

  @override
  String get escalated => 'مسئلہ بڑھا دیا گیا';

  @override
  String get resolveIssue => 'مسئلہ حل کریں';

  @override
  String get whatWasDoneToResolve => 'مسئلے کو حل کرنے کے لیے کیا کیا گیا؟';

  @override
  String get resolutionTextRequired => 'حل کی تفصیل درکار ہے';

  @override
  String get urduName => 'اردو نام';

  @override
  String get enterUrduName => 'اردو نام درج کریں';

  @override
  String get pleaseEnterUrduName => 'براہ کرم اردو نام درج کریں';

  @override
  String get pleaseEnterUrduNameOnly => 'براہ کرم صرف اردو نام درج کریں';

  @override
  String get searchForZones => 'علاقوں کے لیے تلاش کریں';

  @override
  String get failedToSearchForZones =>
      'علاقوں کی تلاش میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get zoneNameAlreadyExists => 'زون کا نام پہلے سے موجود ہے';

  @override
  String get zoneType => 'زون کی قسم';
}
