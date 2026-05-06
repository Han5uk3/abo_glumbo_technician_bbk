// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get calculatingDistance => 'جاري حساب المسافة...';

  @override
  String kmAway(Object distance) {
    return 'على بعد $distance كم';
  }

  @override
  String get appName => 'أبو جلمبو';

  @override
  String get onlineStatusOn => 'أنت الآن متصل';

  @override
  String get onlineStatusOff => 'أنت الآن غير متصل';

  @override
  String get errorUpdatingStatus => 'خطأ في تحديث الحالة';

  @override
  String get appLoginCaption => 'التطبيق للعثور على محترفين مؤهلين.';

  @override
  String get mobileNumber => 'رقم الهاتف ';

  @override
  String get continueText => 'متابعة';

  @override
  String get byContinuingYouAgreeToOur => 'من خلال المتابعة، فإنك توافق علينا';

  @override
  String get termsOfUseAndPrivacyPolicy => 'شروط الاستخدام وسياسة الخصوصية ';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get monthlyRevenue => 'الإيرادات الشهرية';

  @override
  String get admins => 'المشرفون';

  @override
  String get banners => 'اللافتات';

  @override
  String get customers => 'العملاء';

  @override
  String get technicians => 'الفنيون';

  @override
  String get payouts => 'المدفوعات';

  @override
  String get faqs => 'الأسئلة الشائعة';

  @override
  String get totalPayoutAmount => 'إجمالي مبلغ الدفع';

  @override
  String get reviewPayoutDetails => 'مراجعة تفاصيل الدفع';

  @override
  String get manageOrders => 'إدارة الطلبات';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get rejectOrder => 'رفض الطلب';

  @override
  String get areYouSureYouWantToRejectThisOrder =>
      'هل أنت متأكد من رغبتك في رفض هذا الطلب؟';

  @override
  String get loadingAgents => 'جاري تحميل الفنيين...';

  @override
  String get bonusCardDesc => 'المكافأة المكتسبة سيتم تضمينها في محفظتك للدفع.';

  @override
  String get noReview => 'لا توجد مراجعات';

  @override
  String get areYouSureYouWantToAcceptThisNewTime =>
      'هل أنت متأكد من رغبتك في قبول هذا الوقت الجديد؟';

  @override
  String get reject => 'رفض';

  @override
  String get walletBalance => 'رصيد المحفظة';

  @override
  String get tip => 'إكرامية';

  @override
  String get availableToWork => 'متاح للعمل';

  @override
  String get notAvailableToWork => 'غير متاح للعمل';

  @override
  String get choose => 'اختر';

  @override
  String get availableLocations => 'المواقع المتاحة';

  @override
  String get workHoursPricing => 'تسعير ساعات العمل';

  @override
  String get workStartTime => 'وقت بدء العمل';

  @override
  String get workEndTime => 'وقت انتهاء العمل';

  @override
  String get onWorkPrice => 'سعر وقت العمل';

  @override
  String get offWorkPrice => 'سعر خارج وقت العمل';

  @override
  String get generalPrice => 'السعر العام';

  @override
  String get chooseLocations => 'اختر المواقع';

  @override
  String get pleaseEnterAnOnWorkPrice => 'يرجى إدخال سعر وقت العمل';

  @override
  String get pleaseEnterOffWorkPrice => 'يرجى إدخال سعر خارج وقت العمل';

  @override
  String get pleaseEnterAGeneralPrice => 'يرجى إدخال السعر العام';

  @override
  String get grantAdminAccess => 'منح صلاحيات المشرف';

  @override
  String get adminAccessManagement => 'إدارة صلاحيات المشرف';

  @override
  String get searchByBookingId => 'البحث باستخدام رقم الحجز';

  @override
  String get rejectingOrder => 'جارٍ رفض الطلب';

  @override
  String get failedToRejectOrder => 'فشل في رفض الطلب';

  @override
  String get assigningBookingTo => 'جارٍ تعيين الحجز إلى';

  @override
  String get failedToAssignBookingTo => 'فشل في تعيين الحجز إلى';

  @override
  String get completeOrder => 'إكمال الطلب';

  @override
  String get areYouSureYouWantToCompleteThisOrder =>
      'هل أنت متأكد من رغبتك في إكمال هذا الطلب؟';

  @override
  String get complete => 'إكمال';

  @override
  String get completingOrder => 'جارٍ إكمال الطلب';

  @override
  String get failedToCompleteOrder => 'فشل في إكمال الطلب';

  @override
  String get yourAccountHasBeenDeactivatedByAdmin =>
      'تم إلغاء تنشيط حسابك من قبل المسؤول';

  @override
  String get assignTo => 'تعيين إلى';

  @override
  String get agent => 'فني';

  @override
  String get assignToUser => 'تعيين للمستخدم';

  @override
  String get noAgentsAvailable => 'لا يوجد فنيين متاحين';

  @override
  String get scheduledFor => 'مجدول لـ';

  @override
  String get services => 'الخدمات';

  @override
  String get highlightedServices => 'الخدمات المميزة';

  @override
  String get manageBanners => 'إدارة البانرات';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String get delete => 'حذف';

  @override
  String get bannerDeleted => 'تم حذف البانر';

  @override
  String get failedToDeleteBanner => 'فشل في حذف البانر';

  @override
  String get failedToSaveBanner => 'فشل في حفظ البانر';

  @override
  String get active => 'نشط';

  @override
  String get showInPrimaryBanner => 'إظهار في البانر الرئيسي';

  @override
  String get ifDisabledItWillShowInSecondaryBanner =>
      'إذا تم تعطيله، فسيظهر في البانر الثانوي';

  @override
  String get pickImage => 'اختر صورة';

  @override
  String get upload => 'رفع';

  @override
  String get failedToSaveHighlightedService => 'فشل في حفظ الخدمة المميزة';

  @override
  String get done => 'تم';

  @override
  String get addService => 'إضافة خدمة';

  @override
  String get noServicesSelected => 'لم يتم اختيار خدمات';

  @override
  String get failedToSaveService => 'فشل في حفظ الخدمة';

  @override
  String get failedToCreateService => 'فشل في إنشاء الخدمة';

  @override
  String get failedToUpdateService => 'فشل في تحديث الخدمة';

  @override
  String get pleaseVerifyYourIqama =>
      'يرجى التحقق من الإقامة الخاصة بك من خلال تحديد مربع التأكيد';

  @override
  String get uploadYourIqama => 'رفع الإقامة الخاصة بك';

  @override
  String get locationPermissionsAreDenied => 'تم رفض أذونات الموقع';

  @override
  String get locationPermissionsArePermanentlyDenied =>
      'تم رفض أذونات الموقع نهائياً';

  @override
  String get errorDetectingLocation => 'خطأ في تحديد الموقع';

  @override
  String get errorGettingAddress => 'خطأ في الحصول على العنوان';

  @override
  String get pleaseSelectYourIdDocument => 'يرجى تحديد وثيقة الهوية الخاصة بك';

  @override
  String get pleaseSelectAtLeastOneJobRole =>
      'يرجى تحديد دور وظيفي واحد على الأقل';

  @override
  String get unknown => 'غير معروف';

  @override
  String get timedOut => 'انتهت المهلة';

  @override
  String get technicianNotFound => 'لم يتم العثور على فني';

  @override
  String get otpAutoVerified => 'تم التحقق التلقائي من رمز التحقق';

  @override
  String get somethingWentWrongTryAgain => 'حدث خطأ ما، يرجى المحاولة مرة أخرى';

  @override
  String get otpSent => 'تم إرسال رمز التحقق';

  @override
  String get otpHasbeensentto => 'تم إرسال رمز التحقق إلى';

  @override
  String get anErrorOccurredPleaseTryAgainLater =>
      'حدث خطأ، يرجى المحاولة مرة أخرى لاحقًا';

  @override
  String get pleaseEnterAValidPhoneNumber => 'يرجى إدخال رقم هاتف صحيح';

  @override
  String get invalidOtp => 'رمز التحقق غير صحيح';

  @override
  String get otpVerification => 'التحقق من رمز التحقق';

  @override
  String get enterTheOtpSentToTheNumber => 'أدخل رمز التحقق المرسل إلى الرقم';

  @override
  String get change => 'تغيير';

  @override
  String get enterOtp => 'أدخل رمز التحقق';

  @override
  String get verifyOtp => 'التحقق من رمز التحقق';

  @override
  String get language => 'اللغة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get areYouSureYouWantToLogout => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get account => 'الحساب';

  @override
  String get wishlist => 'قائمة المفضلين';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get failedToLoadCategories => 'فشل في تحميل الفئات';

  @override
  String get home => 'الصفحة الرئيسية';

  @override
  String get myBooking => 'الحجوزات ';

  @override
  String get categories => 'الفئات';

  @override
  String get error => 'خطأ';

  @override
  String get searchHere => 'ابحث هنا';

  @override
  String get availableServices => 'الخدمات المتاحة';

  @override
  String get failedToLoadLocations => 'فشل في تحميل المواقع';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get selectLocation => 'اختر الموقع';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get failedToUpdateProfile => 'فشل تحديث الملف الشخصي';

  @override
  String get profileManagement => 'إدارة الملف الشخصي';

  @override
  String get yourName => 'اسمك';

  @override
  String get nameIsRequired => 'الاسم المطلوب';

  @override
  String get enterAValidName => 'يرجى إدخال اسم صحيح';

  @override
  String get emailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get emailIsRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get enterAValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get locationIsRequired => 'الموقع مطلوب';

  @override
  String get buildingNumberIsRequired => 'رقم المبنى مطلوب';

  @override
  String get streetName => 'اسم الشارع';

  @override
  String get streetNameIsRequired => 'اسم الشارع مطلوب';

  @override
  String get cityName => 'اسم المدينة';

  @override
  String get cityNameIsRequired => 'اسم المدينة مطلوب';

  @override
  String get postcode => 'الرمز البريدي';

  @override
  String get postcodeIsRequired => 'الرمز البريدي مطلوب';

  @override
  String get extensionNumber => 'رقم داخلي';

  @override
  String get extensionNumberIsRequired => 'رقم الداخلي مطلوب';

  @override
  String get update => 'تحديث';

  @override
  String get accountCreatedSuccessfully => 'تم إنشاء الحساب بنجاح';

  @override
  String get failedToCreateAccount => 'فشل في إنشاء الحساب';

  @override
  String get pleaseFillTheInputBelowHereToContinue =>
      'يرجى ملء المعلومات أدناه للمتابعة';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get failedToLoadContent => 'فشل في تحميل المحتوى';

  @override
  String get noAddress => 'لا يوجد عنوان';

  @override
  String get searchForAService => 'ابحث عن خدمة';

  @override
  String get jobCategories => 'فئات الوظائف';

  @override
  String get failedToLoadDataPleaseTryAgainLater =>
      'فشل في تحميل البيانات. يرجى المحاولة مرة أخرى لاحقًا.';

  @override
  String get noBookings => 'لا يوجد طلبات';

  @override
  String get noBookingsFound => 'لا يوجد طلبات';

  @override
  String get searchServices => 'ابحث عن الخدمات...';

  @override
  String get noServicesInYourWishlist =>
      'لا توجد خدمات في قائمة المفضليين الخاصة بك';

  @override
  String get failedToSaveBooking => 'فشل حفظ الحجز';

  @override
  String get morning => 'صباحًا';

  @override
  String get afterNoon => 'بعد الظهر';

  @override
  String get confirmRequest => 'تأكيد الطلب';

  @override
  String get bonusAmount => 'مبلغ المكافأة';

  @override
  String get requestBonusPayout => 'طلب صرف المكافأة';

  @override
  String get noBonusAvailableToClaim => 'لا توجد مكافأة متاحة للمطالبة';

  @override
  String get monthlyBonusEarned => 'المكافأة الشهرية المكتسبة';

  @override
  String get areYouSureYouWantToRequestAPayoutForYourMonthlyBonus =>
      'هل أنت متأكد أنك تريد طلب صرف مكافأتك الشهرية؟';

  @override
  String get evening => 'مساءً';

  @override
  String get serviceBookedSuccessfully => 'تم حجز الخدمة بنجاح';

  @override
  String get checkForBookingStatus => 'تحقق من حالة الحجز في قسم \'حجوزاتي\'';

  @override
  String get selectDateTime => 'حدد التاريخ والوقت';

  @override
  String get completeYourBooking => 'أكمل عملية الحجز';

  @override
  String get selectDate => 'حدد التاريخ';

  @override
  String get availableTimeSlot => 'الفترات الزمنية المتاحة';

  @override
  String get addNotes => 'إضافة ملاحظات';

  @override
  String get cashInHand => 'الدفع نقدًا';

  @override
  String get netBankingUpiCard => 'التحويل البنكي الالكتروني / UPI / بطاقة';

  @override
  String get pleaseSelectADate => 'يرجى تحديد التاريخ';

  @override
  String get back => 'رجوع';

  @override
  String get bookAppointment => 'احجز موعدًا';

  @override
  String get filter => 'تصفية';

  @override
  String get price => 'السعر';

  @override
  String get clear => 'مسح';

  @override
  String get reviewSubmittedSuccessfully => 'تم إرسال المراجعة بنجاح';

  @override
  String get anErrorOccurred => 'حدث خطأ';

  @override
  String get submitAReview => 'إرسال المراجعة';

  @override
  String get overallRating => 'التقييم العام';

  @override
  String get writeYourReviewHere => 'اكتب مراجعتك هنا';

  @override
  String get pleaseWriteAReview => 'يرجى كتابة مراجعة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get bookingCancelled => 'تم إلغاء الحجز';

  @override
  String get failedToCancelBooking => 'فشل إلغاء الحجز';

  @override
  String get areYouSureToWantCancelBooking =>
      'هل أنت متأكد أنك تريد إلغاء هذا الحجز؟';

  @override
  String get youWillBeRefundedTheFullAmount => 'سيتم استرداد المبلغ بالكامل';

  @override
  String get no => 'لا';

  @override
  String get yesCancel => 'نعم، قم بالإلغاء';

  @override
  String get failedToLoadServices => 'فشل تحميل الخدمات';

  @override
  String get writeAReview => 'اكتب مراجعة';

  @override
  String get reviewSubmitted => 'تم تقديم المراجعة';

  @override
  String get canceled => 'ملغى';

  @override
  String get requestService => 'طلب خدمة';

  @override
  String get submit => 'إرسال';

  @override
  String get sar => 'ر.س';

  @override
  String get serviceDescription => 'وصف الخدمة';

  @override
  String get serviceInfo => 'معلومات الخدمة';

  @override
  String get serviceName => 'اسم الخدمة';

  @override
  String get customerInfo => 'بيانات العميل';

  @override
  String get bookingInfo => 'تفاصيل الحجز';

  @override
  String get agentInfo => 'بيانات الفني';

  @override
  String get reviewInfo => 'تفاصيل المراجعة';

  @override
  String get issueImage => 'صورة المشكلة';

  @override
  String get issueVideo => 'فيديو المشكلة';

  @override
  String get tapToZoom => 'اضغط للتكبير';

  @override
  String get email => 'البريد الالكتروني';

  @override
  String get location => 'الموقع';

  @override
  String get address => 'العنوان';

  @override
  String get buildingNumber => 'رقم المبنى';

  @override
  String get street => 'الشارع';

  @override
  String get city => 'المدينة';

  @override
  String get postCode => 'الرمز البريدي';

  @override
  String get bookedFor => 'حجز ل';

  @override
  String get paymentMode => 'طريقة الدفع';

  @override
  String get paymentStatus => 'حالة الدفع';

  @override
  String get bookingStatus => 'حالة الحجز';

  @override
  String get bookingNote => 'ملاحظة الحجز';

  @override
  String get bookedAt => 'حجز في';

  @override
  String get rating => 'التقييم';

  @override
  String get review => 'المراجعة';

  @override
  String get reviewedAt => 'تمت التقييم في';

  @override
  String get manage => 'ادارة';

  @override
  String get manageServices => 'ادارة الخدمات';

  @override
  String get manageHighlightedServices => 'ادارة الخدمات المميزة';

  @override
  String get manageAgents => 'ادارة الفنيين';

  @override
  String get pleaseEnterYourEmailToResetPassword =>
      'الرجاء ادخال بريدك الالكتروني لاستعادة كلمة المرور';

  @override
  String get passwordResetEmailSent => 'تم ارسال بريد استعادة كلمة المرور';

  @override
  String get pleaseEnterYourEmail => 'الرجاء ادخال بريدك الالكتروني';

  @override
  String get pleaseEnterYourPassword => 'الرجاء ادخال كلمة المرور';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get register => 'تسجيل';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get areYouSureYouWantToApproveAgent =>
      'هل انت متاكد انك تريد الموافقة على الفني';

  @override
  String get areYouSureYouWantToDisapproveAgent =>
      'هل انت متاكد انك تريد الغاء الموافقة على الفني';

  @override
  String get yesText => 'نعم';

  @override
  String get cropImage => 'قص الصورة';

  @override
  String get label => 'علامة';

  @override
  String get url => 'رابط';

  @override
  String get title => 'عنوان';

  @override
  String get titleArabic => 'عنوان (عربي)';

  @override
  String get name => 'اسم';

  @override
  String get nameArabic => 'اسم (عربي)';

  @override
  String get description => 'وصف';

  @override
  String get descriptionArabic => 'وصف (عربي)';

  @override
  String get category => 'قسم';

  @override
  String get sortOrder => 'ترتيب الفرز';

  @override
  String get pleaseEnterValidEmail => 'الرجاء ادخال بريد الكتروني صحيح';

  @override
  String get emailNotRegistered => 'البريد الالكتروني غير مسجل';

  @override
  String get invalidEmailFormat => 'صيغة البريد الالكتروني غير صحيحة';

  @override
  String get tooManyRequests => 'عدد كبير جدا من الطلبات';

  @override
  String get netError => 'خطأ في الشبكة';

  @override
  String get wrongPassword => 'كلمة المرور خاطئة';

  @override
  String get userNotFound => 'المستخدم غير موجود';

  @override
  String get userDisabled => 'حساب المستخدم معطل';

  @override
  String get deletingAccount => 'جاري حذف الحساب...';

  @override
  String get requiresRecentLogin =>
      'تتطلب هذه العملية مصادقة حديثة. يرجى تسجيل الخروج وتسجيل الدخول مرة أخرى.';

  @override
  String get resetPasswordError => 'خطأ في استعادة كلمة المرور';

  @override
  String get incorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get accountDisabled => 'الحساب معطل';

  @override
  String get invalidCredentials => 'بيانات الدخول غير صحيحة';

  @override
  String get loginError => 'خطأ في تسجيل الدخول';

  @override
  String get passwordMustBeAtleast6Characters =>
      'يجب ان تكون كلمة المرور على الاقل 6 احرف';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get rejected => 'مرفوض';

  @override
  String get accepted => 'مؤكد';

  @override
  String get cancelled => 'ملغي';

  @override
  String get bookings => 'الحجوزات';

  @override
  String get bookedOn => 'حجز في';

  @override
  String get agentsAvailable => 'الفنيين المتاحين';

  @override
  String get acceptedAt => 'مؤكد في';

  @override
  String get rejectedAt => 'مرفوض في';

  @override
  String get completedAt => 'مكتمل في';

  @override
  String get expiredOn => 'انتهى في';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get card => 'بطاقة';

  @override
  String get applePay => 'Apple Pay';

  @override
  String get cashOnHands => 'خارج التطبيق';

  @override
  String get ext => 'الامتداد البريدي';

  @override
  String get serviceAddedSuccessfully => 'تمت اضافة الخدمة بنجاح';

  @override
  String get serviceUpdatedSuccessfully => 'تم تحديث الخدمة بنجاح';

  @override
  String get editService => 'تعديل الخدمة';

  @override
  String get pleaseEnterAName => 'الرجاء ادخال الاسم';

  @override
  String get pleaseEnterNameInArabic => 'الرجاء ادخال الاسم باللغة العربية';

  @override
  String get textMustBeInArabic => 'يجب ان يكون النص باللغة العربية';

  @override
  String get pleaseEnterADescription => 'الرجاء ادخال الوصف';

  @override
  String get pleaseEnterDescriptionInArabic =>
      'الرجاء ادخال الوصف باللغة العربية';

  @override
  String get descriptionMustBeInArabic => 'يجب ان يكون الوصف باللغة العربية';

  @override
  String get pleaseEnterAPrice => 'الرجاء ادخال السعر';

  @override
  String get pleaseSelectACategory => 'الرجاء اختيار قسم';

  @override
  String get discountPercentage => 'نسبة الخصم (%)';

  @override
  String get pleaseEnterADiscountPercentage => 'الرجاء إدخال نسبة الخصم';

  @override
  String get highlightedServiceAddedSuccessfully =>
      'تم اضافة الخدمة المميزة بنجاح';

  @override
  String get highlightedServiceUpdatedSuccessfully =>
      'تم تحديث الخدمة المميزة بنجاح';

  @override
  String get selectServices => 'اختر الخدمات';

  @override
  String get addHighlightedService => 'اضافة خدمة مميزة';

  @override
  String get editHighlightedService => 'تعديل خدمة مميزة';

  @override
  String get pleaseEnterATitle => 'الرجاء ادخال العنوان';

  @override
  String get pleaseEnterTheTitleInArabic =>
      'الرجاء ادخال العنوان باللغة العربية';

  @override
  String get addBanner => 'اضافة بانر';

  @override
  String get editBanner => 'تعديل بانر';

  @override
  String get labelIsRequired => 'الملصق مطلوب';

  @override
  String get urlIsRequired => 'الرابط مطلوب';

  @override
  String get invalidUrl => 'الرابط غير صحيح';

  @override
  String get bannerAddedSuccessfully => 'تم اضافة البانر بنجاح';

  @override
  String get bannerUpdatedSuccessfully => 'تم تحديث البانر بنجاح';

  @override
  String get doYouWantToUploadThisImage => 'هل تريد تحميل هذه الصورة؟';

  @override
  String get pleaseSelectAnImage => 'الرجاء اختيار صورة';

  @override
  String get hasBeenApprovedAsAnAgent => 'تمت الموافقة كفني';

  @override
  String get hasBeenDisapprovedAsAnAgent => 'تم الغاء الموافقة كفني';

  @override
  String get jobRoles => 'وظائف العمل';

  @override
  String get document => 'وثيقة';

  @override
  String get jobRolesAreRequired => 'وظائف العمل مطلوبة';

  @override
  String get failedToDeleteAccount => 'فشل حذف الحساب';

  @override
  String get pleaseConfirmYourPassword =>
      'الرجاء التاكيد من كلمة المرور الخاصة بك';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور لا تتطابق';

  @override
  String get confirmPassword => 'تاكيد كلمة المرور';

  @override
  String get selectJobRoles => 'اختر وظائف العمل';

  @override
  String get failedToDetectLocation => 'فشل تحديد الموقع';

  @override
  String get failedToGetAddress => 'فشل الحصول على العنوان';

  @override
  String get addCustomJobRoles => 'اضافة وظائف عمل مخصصة';

  @override
  String get enterAdditionalJobRoles => 'ادخل وظائف عمل اضافية';

  @override
  String get detectCurrentLocation => 'تحديد الموقع الحالي';

  @override
  String get failedToGetLocation => 'فشل الحصول على الموقع';

  @override
  String get cannotCompleteTasksScheduledForTheFuture =>
      'لا يمكن اكمال المهام المجدولة للمستقبل';

  @override
  String get orders => 'طلبات';

  @override
  String get offers => 'العروض';

  @override
  String get failedToLoadUserData => 'فشل تحميل بيانات المستخدم';

  @override
  String get areYouSureYouWantToDeleteYourAccountThisActionCannotBeUndone =>
      'هل تريد حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه';

  @override
  String get completed => 'مُكتمل';

  @override
  String get addCategory => 'اضافة قسم';

  @override
  String get editCategory => 'تعديل قسم';

  @override
  String get manageCategories => 'إدارة الاقسام';

  @override
  String get bookingAccepted => 'تم تأكيد الحجز';

  @override
  String get yourBookingRequestHasBeenAccepted =>
      'تم تأكيد طلب الحجز الخاص بك! سيتواصل معك فريقنا قريباً.';

  @override
  String get bookingRejected => 'تم رفض الحجز';

  @override
  String get yourBookingRequestHasBeenRejected =>
      'للأسف، تم رفض طلب الحجز الخاص بك. يرجى المحاولة مرة أخرى أو الاتصال بالدعم.';

  @override
  String get sendingNotification => 'إرسال الإشعار للعميل';

  @override
  String get notificationSent => 'تم إرسال الإشعار للعميل';

  @override
  String get bookingCompleted => 'تم اكمال الحجز';

  @override
  String get yourBookingHasBeenCompleted => 'تم اكمال الحجز';

  @override
  String get notifications => 'الاشعارات';

  @override
  String get pleaseWaitAccountVerification =>
      'يتم حاليًا التحقق من الحساب من قبل الإدارة. يرجى مراجعة حالة حسابك لاحقًا.';

  @override
  String get goBack => 'العودة';

  @override
  String get deleteRegistrationConfirmation => 'هل تريد حذف تسجيلك؟';

  @override
  String get phoneNumberAlreadyExists => 'رقم الهاتف موجود بالفعل';

  @override
  String get keepImage => 'حفظ الصورة';

  @override
  String get keepImageDescription => 'هل تريد حفظ الصورة المحددة بدون تقسيمها؟';

  @override
  String get keep => 'حفظ';

  @override
  String get pleaseSelectAtLeastOneService =>
      'الرجاء اختيار على الاقل خدمة واحدة';

  @override
  String get deleteBannerConfirmation => 'هل تريد حذف هذا البانر؟';

  @override
  String get selectLocations => 'اختر المواقع';

  @override
  String get tapToSelectLocations => 'انقر لاختيار المواقع';

  @override
  String get locationsSelected => 'المواقع المحددة';

  @override
  String get locationSelected => 'الموقع المحدد';

  @override
  String get searchLocation => 'بحث عن الموقع';

  @override
  String get noLocationsFound => 'لم يتم العثور على مواقع';

  @override
  String get accountVerificationPending =>
      'يتم التحقق من حسابك من قبل المشرف، يرجى العودة لاحقًا';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get uploading => 'جاري التحميل...';

  @override
  String get enterAValidPhoneNumber => 'الرجاء ادخال رقم هاتف صحيح';

  @override
  String get manageTips => 'إدارة الإكراميات';

  @override
  String get cancelBooking => 'إلغاء الحجز';

  @override
  String get counterPropose => 'اقتراح بديل';

  @override
  String get proposeNewTime => 'اقتراح وقت جديد';

  @override
  String get counterOfferPending => 'اقتراح بديل قيد الانتظار';

  @override
  String get customerProposedNewTime => 'اقترح العميل وقتاً جديداً';

  @override
  String get acceptOffer => 'قبول العرض';

  @override
  String get rejectOffer => 'رفض العرض';

  @override
  String get newProposedTime => 'الوقت المقترح الجديد';

  @override
  String get waitingForCustomer => 'في انتظار رد العميل';

  @override
  String get proposedTime => 'الوقت المقترح';

  @override
  String get counterOfferSent => 'تم إرسال العرض بنجاح';

  @override
  String get counterOfferResponse => 'تم إرسال الرد بنجاح';

  @override
  String get counterProposalStarted => 'بدء الاقتراح البديل';

  @override
  String get counterProposalAccepted => 'تأكيد الاقتراح البديل';

  @override
  String get proposalRejected => 'تم رفض الاقتراح';

  @override
  String get proposalAccepted => 'تم تأكيد الاقتراح';

  @override
  String get customerRejectedProposal => 'رفض العميل اقتراحك.';

  @override
  String get youRejectedProposal => 'لقد رفضت اقتراح العميل.';

  @override
  String get appointmentRescheduledTo => 'تم إعادة جدولة الموعد إلى';

  @override
  String get rescheduleBookingTimeConfirmation =>
      'هل أنت متأكد من أنك تريد قبول وقت الموعد الجديد هذا؟ سيتم تحديث جدول الحجز على الفور.';

  @override
  String get startWork => 'بدء العمل';

  @override
  String get pleaseEnterSortOrder => 'الرجاء ادخال ترتيب الفرز';

  @override
  String get yes => 'نعم';

  @override
  String get categoryAddedSuccessfully => 'تمت إضافة القسم بنجاح';

  @override
  String get categoryUpdatedSuccessfully => 'تم تحديث القسم بنجاح';

  @override
  String get phoneNumberRequired => 'رقم الهاتف مطلوب';

  @override
  String get phoneNumberInvalid => 'رقم الهاتف غير صحيح';

  @override
  String get useCurrentLocation => 'استخدم الموقع الحالي';

  @override
  String get noNotifications => 'لا يوجد إشعارات';

  @override
  String get pleaseSelectALocation => 'الرجاء اختيار موقع';

  @override
  String get day => 'يوم';

  @override
  String get hour => 'ساعة';

  @override
  String get minute => 'دقيقة';

  @override
  String get justNow => 'الان';

  @override
  String get emailAlreadyExists => 'البريد الالكتروني موجود بالفعل';

  @override
  String get tippingCleared => 'تم حذف الإكراميات';

  @override
  String get failedToClearTipping => 'فشل في حذف الإكراميات';

  @override
  String get manageTipping => 'إدارة الإكراميات';

  @override
  String get noTipsAvailable => 'لا توجد إكراميات متاحة';

  @override
  String get noRecentActivity => 'لا يوجد نشاطات حديثة';

  @override
  String get tipInfo => 'تفاصيل الإكرامية';

  @override
  String get totalTips => 'مجموع الإكراميات';

  @override
  String get lastTipAmount => 'آخر مبلغ الإكرامية';

  @override
  String get lastUpdated => 'آخر تحديث';

  @override
  String get agentId => 'معرف الفني';

  @override
  String get sendAndClearWallet => 'إرسال وتصفير المحفظة';

  @override
  String get clearWallet => 'تصفير المحفظة';

  @override
  String get clearWalletWarning =>
      'هذا الإجراء لا يمكن التراجع عنه. سيتم تحويل جميع المبالغ في محفظتك وتعيين الرصيد إلى صفر.';

  @override
  String get areYouSureYouWantToSend => 'هل أنت متأكد أنك تريد إرسال';

  @override
  String get to => 'إلى';

  @override
  String get confirm => 'تأكيد';

  @override
  String get andClearTheirWallet => 'وتصفير محفظتهم';

  @override
  String get invalid => 'غير صحيح';

  @override
  String get locationPermissionDeniedForever => 'تم رفض إذن الموقع بشكل دائم';

  @override
  String get tracking => 'التتبع';

  @override
  String get uploadImage => 'تحميل صورة';

  @override
  String get pleaseUploadAnImage => 'يرجى تحميل صورة';

  @override
  String get searchBookings => 'البحث عن الحجوزات';

  @override
  String get item => 'العنصر';

  @override
  String get quantity => 'الكمية';

  @override
  String get warrantyRejectedTechnicians => 'الفنّيون الذين رفضوا الضمان';

  @override
  String get loadingBanners => 'جارٍ تحميل البانرات';

  @override
  String get cancelledDate => 'تاريخ الإلغاء';

  @override
  String get paymentPending => 'دفع قيد الانتظار';

  @override
  String get loadingHighlightedServices => 'جارٍ تحميل الخدمات المميزة';

  @override
  String get loadingServices => 'جارٍ تحميل الخدمات';

  @override
  String get completionDetails => 'تفاصيل الانتهاء';

  @override
  String get loadingFaqs => 'جارٍ تحميل الأسئلة الشائعة';

  @override
  String get loadingTechnicians => 'جاري تحميل الفنيين';

  @override
  String get bookingWasCancelledByCustomer => 'تم إلغاء الحجز من قبل العميل';

  @override
  String get deleteCategory => 'حذف القسم';

  @override
  String get deletedSuccessfully => 'تم حذف القسم بنجاح';

  @override
  String get deleteError => 'حدث خطأ في حذف القسم';

  @override
  String get deleteService => 'حذف الخدمة';

  @override
  String get serviceCompletedDescription =>
      'تم القيام بالعمل وتقديم الخدمة. سيتم تطبيق ضمان لمدة أسبوع.';

  @override
  String get paymentThroughApp => 'داخل التطبيق';

  @override
  String get paymentOutsideApp => 'خارج التطبيق';

  @override
  String get paymentThroughAppDesc => 'سيدفع العميل من خلال التطبيق.';

  @override
  String get paymentOutsideAppDesc => 'استلام الدفع خارج التطبيق.';

  @override
  String get deleteServiceConfirmation => 'هل أنت متأكد من حذف الخدمة؟';

  @override
  String get failedToLoadData => 'فشل تحميل البيانات';

  @override
  String get categoryNameAlreadyExists => 'اسم القسم موجود بالفعل';

  @override
  String get deleteCategoryConfirmation => 'هل أنت متأكد من حذف القسم؟';

  @override
  String get openSettings => 'افتح الإعدادات';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get completeWork => 'إنهاء العمل';

  @override
  String get gallery => 'معرض الصور';

  @override
  String get qty => 'الكمية';

  @override
  String get inspectionOnlyDescription =>
      'تم القيام بالفحص فقط ولم يتم تقديم خدمة';

  @override
  String get required => 'مطلوب';

  @override
  String get requests => 'طلبات';

  @override
  String get newtext => 'جديد';

  @override
  String get waitingForPayment => 'في انتظار الدفع';

  @override
  String get totalCost => 'التكلفة الكلية';

  @override
  String get inspectionOnly => 'فحص فقط';

  @override
  String get support => 'دعم';

  @override
  String get getHelpAnytime => 'الحصول على دعم في اي وقت';

  @override
  String get tierSystem => 'نظام المستوى';

  @override
  String get bronze => 'البرونزية';

  @override
  String get silver => 'الفضية';

  @override
  String get gold => 'الذهبية';

  @override
  String get platinum => 'بلاتينيوم';

  @override
  String get nobonus => 'لا يوجد مكافأة';

  @override
  String get fivepercentBonus => '5% مكافأة';

  @override
  String get tenpercentBonus => '10% مكافأة';

  @override
  String get fifteenpercentBonus => '15% مكافأة + بيج';

  @override
  String get greaterThan3dot5rating => 'تقييم 3.5+';

  @override
  String get greaterThan4dot0rating => 'تقييم 4.0+';

  @override
  String get greaterThan4dot5rating => 'تقييم 4.5+';

  @override
  String get greaterThan4dot8rating => 'تقييم 4.8+';

  @override
  String get searchByTechnicianName => 'البحث باسم الفنّي';

  @override
  String get bookingWasRejectedByAdmin => 'تم رفض الحجز بواسطة المسؤول';

  @override
  String get bonus => 'مكافأة';

  @override
  String get jobs => 'وظائف';

  @override
  String get twentyPlusJobs => 'أكثر من 20 وظيفة';

  @override
  String get thirtyPlusJobs => 'أكثر من 30 وظيفة';

  @override
  String get fortyPlusJobs => 'أكثر من 40 وظيفة';

  @override
  String get sixtyPlusJobs => 'أكثر من 60 وظيفة';

  @override
  String get earnings => 'الأرباح';

  @override
  String get exitAppTitle => 'الخروج من التطبيق';

  @override
  String get recentTransactions => 'المعاملات الحديثة';

  @override
  String get noTransactionsYet => 'لا يوجد معاملات حتى الان';

  @override
  String get id => 'الرقم التعريفي';

  @override
  String get exitAppMessage => 'هل تريد الخروج من التطبيق؟';

  @override
  String get exit => 'خروج';

  @override
  String get nextTierProgress => 'تقدم المستوى التالي';

  @override
  String get greaterThan20jobsPerMonth => '≥ 20 وظائف في الشهر';

  @override
  String get orderId => 'رقم الطلب';

  @override
  String get greaterThan40jobsPerMonth => '≥ 40 وظائف في الشهر';

  @override
  String get greaterThan60jobsPerMonth => '≥ 60 وظائف في الشهر';

  @override
  String get progressResetsMonthly => ' إعادة تعيين الشهري';

  @override
  String get progressResetsMonthlyDesc =>
      'يتم إعادة تصفير التقدم شهرياً. حافظ على تقييمات عالية وأكمل المزيد من المهام للحصول على مكافآت أفضل';

  @override
  String get zeroPercentBonus => '0% مكافأة';

  @override
  String get fivepercentBonusOnly => '5% مكافأة';

  @override
  String get tenpercentBonusOnly => '10% مكافأة';

  @override
  String get fifteenpercentBonusOnly => '15% مكافأة';

  @override
  String get viewYourRewards => 'عرض جوائزك';

  @override
  String get noSupportAvailable => 'لا يوجد دعم متاح';

  @override
  String get contactSupportOptions => 'خيارات الاتصال بالدعم';

  @override
  String get contactByEmail => 'الاتصال عبر البريد الإلكتروني';

  @override
  String get contactByPhone => 'الاتصال عبر الهاتف';

  @override
  String get contactByWhatsApp => 'الاتصال عبر واتساب';

  @override
  String get serviceCompleted => 'تم إنجاز الخدمة';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get serviceItems => 'عناصر الخدمة';

  @override
  String get enterServiceCost => 'أدخل تكلفة الخدمة';

  @override
  String get serviceCostMustBeGreaterThanZero =>
      'يجب أن تكون تكلفة الخدمة أكبر من صفر';

  @override
  String get pleaseEnterValidNumber => 'يرجى إدخال رقم صحيح';

  @override
  String get pleaseEnterServiceCost => 'يرجى إدخال تكلفة الخدمة';

  @override
  String get tapToUploadImage => 'اضغط لرفع الصورة';

  @override
  String get serviceCost => 'تكلفة الخدمة';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get camera => 'الكاميرا';

  @override
  String get pleaseAddAtleastOneServiceItem => 'يرجى إضافة عنصر واحد على الأقل';

  @override
  String get pleaseFillAllServiceItemFields => 'يرجى ملء جميع حقول العنصر';

  @override
  String get workingDays => 'أيام العمل';

  @override
  String get monday => 'الإثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get locationServiceRequired => 'خدمة الموقع مطلوبة';

  @override
  String get pleaseEnableLocationService => 'يرجى تفعيل خدمة الموقع';

  @override
  String get ok => 'حسنًا';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع';

  @override
  String get bioMetricAuthentication => 'تفعيل بصمة الدخول';

  @override
  String get confirmDeletion => 'تأكيد الحذف';

  @override
  String get accountDeleted => 'تم حذف الحساب';

  @override
  String get startTracking => 'بدء التتبع';

  @override
  String get stopTracking => 'إيقاف التتبع';

  @override
  String get arrivedAtLocation => 'تم الوصول للموقع';

  @override
  String get youHaveActiveBooking => 'لديك حجز نشط';

  @override
  String get areYouSureYouWantToStartTracking =>
      'هل أنت متأكد أنك تريد بدء التتبع لهذا الحجز؟ سيتم تفعيل تتبع الموقع.';

  @override
  String get start => 'بدء';

  @override
  String get areYouSureYouWantToStopTracking =>
      'هل أنت متأكد أنك تريد إيقاف التتبع لهذا الحجز؟ سيتم تعطيل تتبع الموقع.';

  @override
  String get stop => 'إيقاف';

  @override
  String get failedToStartTracking => 'فشل بدء التتبع';

  @override
  String get trackingStarted => 'تم بدء التتبع';

  @override
  String get locationServicesDisabled => 'خدمات الموقع معطّلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get trackingNote =>
      'ملاحظة: عند بدء العمل، يرجى الضغط على زر \'بدء التتبع\'. في حال توقف الزر أو تغيّر حالته، يرجى الضغط عليه مجددًا.';

  @override
  String get filterByLocation => 'تصفية حسب الموقع';

  @override
  String get allLocations => 'كل المواقع';

  @override
  String get clearFilter => 'مسح التصفية';

  @override
  String get agents => 'الفنيين';

  @override
  String get inSelectedLocation => 'في الموقع المحدد';

  @override
  String get totalAgents => 'مجموع الفنيين';

  @override
  String get filteredBy => 'تصفية بواسطة';

  @override
  String get notificationLanguage => 'لغة الاشعارات';

  @override
  String get areYouSureYouWantToCancelThisBooking =>
      'هل أنت متأكد أنك تريد إلغاء هذا الحجز؟';

  @override
  String get bookingTimeline => 'خط الحجز';

  @override
  String get trackingStartedAt => 'تم بدء التتبع في';

  @override
  String get createdAt => 'تم إنشاؤه في';

  @override
  String get enableBiometricAuthentication => 'تفعيل التحقق بواسطة البصمة';

  @override
  String get notificationLanguageUpdated => 'تم تحديث لغة الاشعارات';

  @override
  String get failedToLoadImage => 'فشل في تحميل الصورة';

  @override
  String get issueMedia => 'مرفقات المشكلة';

  @override
  String get loadingVideo => 'تحميل الفيديو';

  @override
  String get categoryAlreadyExists => 'القسم موجود بالفعل';

  @override
  String get noLocationsAvailable => 'لا يوجد مواقع متاحة';

  @override
  String get close => 'اغلاق';

  @override
  String get enterPasswordToConfirm => 'أدخل كلمة المرور للتأكيد';

  @override
  String get deleteAccountWarning =>
      'هل أنت متأكد أنك تريد حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه';

  @override
  String get logoutConfirmation => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get customerName => 'اسم العميل';

  @override
  String get call => 'اتصال';

  @override
  String get directions => 'اتجاهات';

  @override
  String get images => 'صور';

  @override
  String get video => 'فيديو';

  @override
  String get walletClearedSuccessfully => 'تم مسح المحفظة بنجاح';

  @override
  String get biometricNotSupported => 'ميزة البصمة غير مدعومة';

  @override
  String get pleaseAuthenticateToContinue => 'يرجى التحقق من هويتك للمتابعة';

  @override
  String get authenticationFailed => 'فشل التحقق';

  @override
  String get biometricNotAvailable => 'ميزة البصمة غير متوفرة';

  @override
  String get biometricTemporarilyLocked => 'ميزة البصمة مقفلة مؤقتًا';

  @override
  String get unexpectedErrorOccurred => 'حدث خطأ غير متوقع';

  @override
  String get ago => 'منذ';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get country => 'الدولة';

  @override
  String get languageCode => 'كود اللغة';

  @override
  String get accountStatus => 'حالة الحساب';

  @override
  String get adminStatus => 'حالة الادمن';

  @override
  String get verified => 'موثّق';

  @override
  String get systemInformation => 'معلومات النظام';

  @override
  String get userId => 'معرّف المستخدم';

  @override
  String get updatedAt => 'آخر تحديث';

  @override
  String get admin => 'الادمن';

  @override
  String get assignedRoles => 'الوظائف المخصصة';

  @override
  String get noAgentsFound => 'لم يتم العثور على فنيين';

  @override
  String get agentApproved => 'الفني موافق';

  @override
  String get agentDisapproved => 'الفني غير موافق';

  @override
  String get deleteBanner => 'حذف البانر';

  @override
  String get invalidImageUrl => 'رابط صورة غير صحيح';

  @override
  String get imageLoadError => 'خطأ في تحميل الصورة';

  @override
  String get imageCropError => 'خطأ في تقسيم الصورة';

  @override
  String get errorAddingCategory => 'خطأ في إضافة القسم';

  @override
  String get errorUpdatingCategory => 'خطأ في تحديث القسم';

  @override
  String get assign => 'تعيين';

  @override
  String get customerSubmittedBookingRequest => 'تم إرسال طلب الحجز من العميل';

  @override
  String get serviceProviderConfirmedAppointment => 'تم تأكيد موعد الخدمة';

  @override
  String get serviceTrackingInitiated => 'تم بدء تتبع الخدمة';

  @override
  String get serviceHasBeenSuccessfullyCompleted => 'تم إنجاز الخدمة بنجاح';

  @override
  String get bookingWasRejectedByServiceProvider => 'تم رفض الحجز من قبل الفني';

  @override
  String get bookingWasCancelled => 'تم إلغاء الحجز';

  @override
  String get serviceInProgress => 'الخدمة قيد التنفيذ';

  @override
  String get current => 'الحالي';

  @override
  String get serviceIsCurrentlyBeingPerformed => 'الخدمة قيد التنفيذ';

  @override
  String get waitingForServiceProvider => 'انتظار الفني';

  @override
  String get waitingForTechnicianToStartService => 'انتظار الفني لبدء الخدمة';

  @override
  String get waitingForAcceptance => 'انتظار الموافقة';

  @override
  String get waitingForServiceProviderResponse => 'انتظار رد الفني';

  @override
  String get waitingForAdmin => 'في انتظار المسؤول';

  @override
  String get waitingForAdminToReassign =>
      'في انتظار المسؤول لإعادة تعيين الفني';

  @override
  String get orderRejected => 'تم رفض الطلب';

  @override
  String get registrationSuccess => 'تم التسجيل بنجاح';

  @override
  String get registrationFailed => 'فشل التسجيل';

  @override
  String get confirmReject => 'تأكيد الرفض';

  @override
  String get updatedOn => 'تم التحديث';

  @override
  String get approvedOn => 'تم الموافقة على';

  @override
  String get confirmRejectMessage => 'هل أنت متأكد أنك تريد رفض هذا الطلب؟';

  @override
  String get bookingCancelledSuccessfully => 'تم إلغاء الحجز بنجاح';

  @override
  String get workMarkedAsComplete => 'تم تعيين العمل كمكتمل';

  @override
  String get areYouSureYouWantToStartTrackingThisBooking =>
      'هل أنت متأكد أنك تريد بدء تتبع هذا الحجز؟';

  @override
  String get areYouSureYouWantToPauseTrackingThisBooking =>
      'هل أنت متأكد أنك تريد إيقاف تتبع هذا الحجز مؤقتًا؟';

  @override
  String get areYouSureYouWantToStopTrackingThisBooking =>
      'هل أنت متأكد أنك تريد إيقاف تتبع هذا الحجز؟';

  @override
  String get pauseTracking => 'إيقاف مؤقت للتتبع';

  @override
  String get resumeTracking => 'استئناف التتبع';

  @override
  String get trackingPausedSuccessfully => 'تم إيقاف التتبع مؤقتًا بنجاح';

  @override
  String get areYouSureYouWantToCompleteThisWork =>
      'هل أنت متأكد أنك تريد إنجاز هذا العمل؟';

  @override
  String get useBiometric => 'استخدام بصمة الدخول';

  @override
  String get imageIsRequired => 'الصورة مطلوبة';

  @override
  String get bookingCompletedSuccessfully => 'تم إنجاز الحجز بنجاح';

  @override
  String get startedWorkingOnBookingSuccessfully => 'بدء العمل على الحجز بنجاح';

  @override
  String get stopTrackingBookingSuccessfully => 'إيقاف تتبع الحجز بنجاح';

  @override
  String get cards => 'داخل التطبيق';

  @override
  String get insideApp => 'داخل التطبيق';

  @override
  String get outsideApp => 'خارج التطبيق';

  @override
  String get goToLogin => 'الذهاب إلى تسجيل الدخول';

  @override
  String get failedToSendNotification => 'فشل في إرسال الإشعار للعميل';

  @override
  String get locationPermissionErrorIOS =>
      'حدث خطأ في إذن الموقع على نظام iOS. يرجى الذهاب إلى الإعدادات > الخصوصية والأمان > خدمات الموقع > Abo Glumbo Worker واختيار \'دائمًا\' لتمكين التتبع في الخلفية.';

  @override
  String get youHaveAnActiveBookingAlready => 'لديك حجز نشط بالفعل.';

  @override
  String get locationServicesDisabledPleaseEnable =>
      'تم تعطيل خدمات الموقع. يرجى تمكين خدمات الموقع.';

  @override
  String get openLocationSettings => 'افتح إعدادات الموقع';

  @override
  String get image => 'صورة';

  @override
  String get notificationTitle => 'عنوان الإشعار';

  @override
  String get enterYourNotificationMessageHere => 'أدخل رسالة الإشعار هنا';

  @override
  String get aboGlumboTechnician => 'لم يتم العثور على فنيين';

  @override
  String get now => 'الان';

  @override
  String get assigningTechnician => 'في انتظار الموافقة';

  @override
  String get selectProvince => 'اختر المحافظة';

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get rejectionHistory => 'تاريخ الرفض';

  @override
  String get selectNeighborhood => 'اختر الحي';

  @override
  String get recipients => 'المستلمون';

  @override
  String get techniciansRejectedThisClaim => 'تم رفض هذا الطلب من قبل الفنيين';

  @override
  String get technicianRejectedThisClaim => 'تم رفض هذا الطلب من قبل الفني';

  @override
  String get warrantyClaims => 'طلبات الضمان';

  @override
  String get expired => 'انتهت';

  @override
  String get tapToView => 'انقر للمشاهدة';

  @override
  String get rejections => 'الرفضات';

  @override
  String get exceedsMaxSize => 'تجاوز الحد الاقصى';

  @override
  String get sendNotifications => 'إرسال الإشعارات';

  @override
  String get sendNotification => 'إرسال إشعار';

  @override
  String get couldNotOpenFile => 'لا يمكن فتح الملف';

  @override
  String get noTechniciansFound => 'لم يتم العثور على فنيين';

  @override
  String get noTechniciansAvailable => 'لا يوجد فنيون متاحون';

  @override
  String get manageNotificationAlerts => 'ادارة الإشعارات';

  @override
  String get previewLanguage => 'معاينة اللغة';

  @override
  String get sendNotificationsToCustomer => 'إرسال الإشعارات إلى العميل';

  @override
  String get preview => 'معاينة';

  @override
  String get message => 'الرسالة';

  @override
  String get composeMessage => 'إنشاء رسالة';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get iqama => 'الإقامة';

  @override
  String get certificationsrelevantExperienceDocuments =>
      'وثائق الخبرة المرتبطة بالشهادات';

  @override
  String get filesSelected => 'الملفات المحددة';

  @override
  String get certificationsrelevantExperienceDocumentsOptional =>
      'وثائق الخبرة والشهادات (اختياري)';

  @override
  String get invoiceType => 'نوع الفاتورة';

  @override
  String get fullService => 'خدمة كامل';

  @override
  String get inspection => 'فحص';

  @override
  String get bookingId => 'رقم الحجز';

  @override
  String get typeMessageToCustomer => 'اكتب رسالة للعميل...';

  @override
  String get startConversationWithCustomer => 'ابدأ محادثة مع عميلك';

  @override
  String get chatWithCustomer => 'الدردشة مع العميل';

  @override
  String get startChat => 'بدء الدردشة';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'الامس';

  @override
  String get amountPaid => 'المبلغ المدفوع';

  @override
  String get continueChat => 'مواصلة الدردشة';

  @override
  String get failedToStartChat => 'فشل بدء الدردشة';

  @override
  String get creatingChatRoom => 'جاري انشاء غرفة الدردشة';

  @override
  String get loadingChat => 'جاري تحميل الدردشة';

  @override
  String get noMessages => 'لا توجد رسائل';

  @override
  String get errorLoadingMessages => 'خطأ في تحميل الرسائل';

  @override
  String get transactionId => 'رقم المعاملة';

  @override
  String get backgroundLocationPermissionRequired =>
      'تتطلب ميزة تتبع الموقع في الخلفية الحصول على إذن \'السماح دائماً\'. يرجى تفعيل هذا في إعدادات جهازك.';

  @override
  String get locationPermissionDeniedPleaseGrant =>
      'تم رفض إذن الموقع. يرجى منح إذن الموقع للمتابعة.';

  @override
  String get areYouSureYouWantToCompleteThisBooking =>
      'هل أنت متأكد أنك تريد إنجاز هذا الحجز؟';

  @override
  String get locationPermissionPermanentlyDeniedPleaseEnable =>
      'تم رفض إذن الموقع بشكل دائم. يرجى تمكين الوصول إلى الموقع من الإعدادات.';

  @override
  String get locationServicesDisabledCannotRestoreTracking =>
      'تم تعطيل خدمات الموقع، لا يمكن استعادة التتبع';

  @override
  String get locationPermissionDeniedCannotRestoreTracking =>
      'تم رفض إذن الموقع، لا يمكن استعادة التتبع';

  @override
  String get iosLocationPermissionErrorDuringRestore =>
      'خطأ في إذن الموقع على iOS أثناء الاستعادة - قد تحتاج إذن \"دائماً\"';

  @override
  String get locationTrackingRestoredSuccessfully =>
      'تم استعادة تتبع الموقع بنجاح';

  @override
  String get iosLocationPermissionIssueDuringRestore =>
      'مشكلة في إذن الموقع على iOS أثناء الاستعادة';

  @override
  String get iosOnlyWhenInUsePermissionGranted =>
      'iOS: تم منح إذن \"عند الاستخدام\" فقط. التتبع في الخلفية سيكون محدوداً.';

  @override
  String get iosAlwaysPermissionGranted =>
      'iOS: تم منح إذن \"دائماً\". التتبع الكامل في الخلفية متاح.';

  @override
  String get iosErrorRequestingAlwaysPermission =>
      'iOS: خطأ في طلب إذن \"دائماً\"';

  @override
  String get iosContinuingWithWhenInUsePermissionOnly =>
      'iOS: المتابعة مع إذن \"عند الاستخدام\" فقط.';

  @override
  String get batteryOptimizationEnabledMayAffectTracking =>
      'تحسين البطارية مفعل، قد يؤثر على تتبع الموقع في الخلفية';

  @override
  String get trackingYourLocationForServiceDelivery =>
      'تتبع موقعك لتسليم الخدمة';

  @override
  String get aboGlumboLocationTracking => 'أبو جلمبو - تتبع الموقع';

  @override
  String get backgroundLocationUpdated => 'تم تحديث الموقع تلقائيًا';

  @override
  String get errorUpdatingBackgroundLocation =>
      'حدث خطأ أثناء التحديث التلقائي للموقع';

  @override
  String get backgroundFetchTriggered => 'تم تشغيل التحديث التلقائي';

  @override
  String get backgroundFetchTimeout => 'انتهت مهلة التحديث التلقائي';

  @override
  String get locationStreamErrorDuringRestore =>
      'خطأ في استعادة تدفق بيانات الموقع';

  @override
  String get errorRestoringLocationTracking =>
      'حدث خطأ أثناء استعادة تتبع الموقع';

  @override
  String get backgroundFetchConfiguredAndStarted =>
      'تم إعداد وتشغيل التحديث التلقائي';

  @override
  String get errorConfiguringBackgroundFetch => 'خطأ في إعداد التحديث التلقائي';

  @override
  String get locationUpdated => 'تم تحديث الموقع';

  @override
  String get errorUpdatingLocationToFirestore =>
      'حدث خطأ في إرسال الموقع إلى قاعدة البيانات';

  @override
  String get errorStoppingBackgroundFetch =>
      'حدث خطأ أثناء إيقاف التحديث التلقائي';

  @override
  String get errorUpdatingBookingStatus => 'خطأ في تحديث حالة الحجز';

  @override
  String get locationTrackingStopped => 'تم إيقاف تتبع الموقع';

  @override
  String get deleteItemConfirmation =>
      'هل أنت متأكد أنك تريد حذف هذا العنصر؟';

  @override
  String get agentUnavailable => 'الفني غير متاح';

  @override
  String get timeConflictDetected => 'تم اكتشاف تعارض في الوقت';

  @override
  String get cannotAssignWorkTo => 'لا يمكن تعيين العمل إلى';

  @override
  String get alreadyAssignedAtExactSameTime => 'تم تعيينه بالفعل في نفس الوقت';

  @override
  String get currentBookingTime => 'وقت الحجز الحالي';

  @override
  String get technicianCannotBeAssignedMultipleTimes =>
      'لا يمكن تعيين فني لعدة حجوزات في نفس الوقت تمامًا. يرجى اختيار وقت مختلف أو اختيار فني آخر.';

  @override
  String get unknownTechnician => 'فني غير معروف';

  @override
  String get tryadifferentsearchterm => 'جرّب كلمة بحث أخرى';

  @override
  String get warrantyRepairRequested => 'تم طلب إصلاح الضمان';

  @override
  String get acceptWarrantyRepair => 'قبول إصلاح الضمان';

  @override
  String get customerRequestedRepairUnderWarranty =>
      'العميل طلب إصلاحًا تحت الضمان';

  @override
  String get warrantyRepairAccepted => 'تم تأكيد إصلاح الضمان';

  @override
  String get technicianAcceptedTheRequest => 'أكد الفني الطلب';

  @override
  String get warrantyRepairCompleted => 'تم إكمال إصلاح الضمان';

  @override
  String get originalServiceCompleted => 'تم إكمال الخدمة الأصلية';

  @override
  String get warrantyRejectedByAdmin => 'تم رفض الضمان من قبل الإدارة';

  @override
  String get warrantyRejectedByTechnician => 'تم رفض الضمان من قبل الفنّي';

  @override
  String get reasonforrejection => 'سبب الرفض';

  @override
  String get warrantyRequestWasRejectedByAdmin =>
      'تم رفض طلب الضمان من قبل الإدارة';

  @override
  String get warrantyRequestWasRejectedByTechnician =>
      'تم رفض طلب الضمان من قبل الفنّي';

  @override
  String get technicianCompletedTheRequest => 'قام الفنّي بإكمال الطلب';

  @override
  String get warrantyExpired => 'انتهت صلاحية الضمان';

  @override
  String get warrantyPeriodHasExpired => 'انتهت فترة الضمان';

  @override
  String get trackingStoppedAt => 'تم إيقاف التتبع عند';

  @override
  String get serviceTrackingStopped => 'تم إيقاف تتبع الخدمة';

  @override
  String get youCancelledThisRequest => 'لقد ألغيت هذا الطلب';

  @override
  String get youDeclinedThisWarrantyRequest => 'لقد رفضت طلب الضمان هذا';

  @override
  String get noresultsfound => 'لا توجد نتائج';

  @override
  String get technicianCancelled => 'تم إلغاء الفني';

  @override
  String get cancelledByTechnician => 'تم الغاء بواسطة الفني';

  @override
  String get technicianPreviouslyCancelled => 'تم إلغاء الفني مسبقاً';

  @override
  String get agentCancelledAtTimeSlot => 'الفني ألغى هذا الوقت مسبقًا';

  @override
  String get previouslyCancelledAt => 'تم الإلغاء سابقًا في';

  @override
  String get chooseDifferentAgent => 'اختر فنيًا مختلفًا';

  @override
  String get assignAnyway => 'تعيين على أي حال';

  @override
  String get cancelledAt => 'تم الإلغاء في';

  @override
  String get technicianCancelledAtTime =>
      'هذا الفني قام سابقًا بإلغاء حجز في نفس الوقت تمامًا. يُرجى التفكير في تعيين فني آخر لضمان موثوقية أفضل.';

  @override
  String get errorCheckingBatteryOptimization => 'خطأ في فحص تحسين البطارية';

  @override
  String get technicianRestrictedTitle => 'تم تقييد الفني';

  @override
  String get cannotAssignCancelledTechnician =>
      'لا يمكن تعيين فني تم إلغاء تعيينه سابقًا';

  @override
  String get lastCancellationOn => 'آخر إلغاء في';

  @override
  String get technicianCancelledRestrictionMessage =>
      'هذا الفني قام سابقًا بإلغاء حجز، وهو الآن مُقيَّد من استلام مهام جديدة. يرجى اختيار فني آخر.';

  @override
  String get understood => 'فهمت';

  @override
  String get cancelledThisBooking => 'ألغى هذا الحجز';

  @override
  String get alreadyBookedAt => 'محجوز بالفعل في';

  @override
  String get bookingAssignedTo => 'تم تعيين الحجز إلى';

  @override
  String get bookingAssignmentSuccessful => 'تم تعيين الحجز بنجاح';

  @override
  String get anotherAssignmentInProgress =>
      'يوجد تعيين آخر قيد التقدم. يرجى الانتظار...';

  @override
  String get assignmentInProgress => 'المهمة قيد التنفيذ. يرجى الانتظار...';

  @override
  String get checkingAvailabilityAndAssigning => 'فحص التوفر والتعيين...';

  @override
  String get thisBookingAlreadyAssignedToAnotherAgent =>
      'تم بالفعل تعيين هذا الحجز لفني آخر.';

  @override
  String get failedToAssignAgent =>
      'فشل في تعيين الفني. يرجى المحاولة مرة أخرى.';

  @override
  String get thisAgentCancelledSameBookingBefore =>
      'هذا الفني ألغى نفس هذا الحجز من قبل';

  @override
  String get gotIt => 'فهمت';

  @override
  String get showAllAgents => 'عرض جميع الفنيين';

  @override
  String get availableInSelectedLocation => 'متاحون في الموقع المحدد';

  @override
  String get cancelledThisBookingOn => 'ألغى هذا الحجز في';

  @override
  String get previouslyCancelledAgent => 'الفني ألغى سابقًا';

  @override
  String get agentPreviouslyCancelledWarning =>
      'هذا الفني ألغى نفس طلب الحجز سابقًا. يمكنك تعيينه، لكن من الأفضل اختيار فني أكثر موثوقية.';

  @override
  String get busyAt => 'مشغول في';

  @override
  String get managefaq => 'إدارة الأسئلة الشائعة';

  @override
  String technicianSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم اختيار $count فنيين',
      two: 'تم اختيار فنيين',
      one: 'تم اختيار فني واحد',
      zero: 'لم يتم اختيار أي فني',
    );
    return '$_temp0';
  }

  @override
  String get technicianArrived => 'وصل الفني';

  @override
  String get paymentRequested => 'تم طلب الدفع';

  @override
  String get reassignedAt => 'تمت إعادة التعيين في';

  @override
  String get newTechnicianAssigned => 'تم تعيين فني جديد';

  @override
  String get technicianStartedTracking => 'الفني في الطريق';

  @override
  String get technicianArrivedAtLocation => 'وصل الفني إلى الموقع';

  @override
  String get inspectionCompleted => 'اكتمل الفحص';

  @override
  String get fullServiceCompleted => 'اكتملت الخدمة بالكامل';

  @override
  String get cancelledByAdmin => 'تم الإلغاء بواسطة المسؤول';

  @override
  String get paymentCompleted => 'تم اكتمال الدفع';

  @override
  String get paymentSuccessfullyCompleted => 'تم اكتمال الدفع بنجاح';

  @override
  String get bookingCancelledByAdmin => 'تم إلغاء الطلب من قبل المسؤول';

  @override
  String get addFaq => 'إضافة سؤال شائع';

  @override
  String get noFaqEntriesFound => 'لا توجد أسئلة شائعة';

  @override
  String get manageFaqs => 'إدارة الأسئلة الشائعة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get question => 'السؤال';

  @override
  String get answer => 'الإجابة';

  @override
  String get questionIsRequired => 'السؤال مطلوب';

  @override
  String get answerIsRequired => 'الإجابة مطلوبة';

  @override
  String get faqAddedSuccessfully => 'تمت إضافة السؤال الشائع بنجاح';

  @override
  String get addEntry => 'إضافة سؤال شائع';

  @override
  String get addFaqEntry => 'إضافة سؤال شائع';

  @override
  String get questionMustBeInArabic => 'يجب أن يكون السؤال باللغة العربية';

  @override
  String get answerMustBeInArabic => 'يجب أن تكون الإجابة باللغة العربية';

  @override
  String get faqEntryDeletedSuccessfully => 'تم حذف السؤال الشائع بنجاح';

  @override
  String get position => 'الموقع';

  @override
  String get entryAlreadyExists => 'المُدخل موجود بالفعل';

  @override
  String get manageCustomers => 'ادارة العملاء';

  @override
  String get areYouSureYouWantToUnBlockThisCustomer =>
      'هل انت متاكد انك تريد فك الحظر عن هذا العميل؟';

  @override
  String get areYouSureYouWantToBlockThisCustomer =>
      'هل انت متاكد انك تريد حظر هذا العميل؟';

  @override
  String get customer => 'العميل';

  @override
  String get blocked => 'محظور';

  @override
  String get customerUnblockedSuccessfully => 'تم فك حظر العميل بنجاح';

  @override
  String get customerBlockedSuccessfully => 'تم حظر العميل بنجاح';

  @override
  String get noCustomersFound => 'لم يتم العثور على عملاء';

  @override
  String get blockCustomer => 'حظر العميل';

  @override
  String get unBlockCustomer => 'فك حظر العميل';

  @override
  String get checkingAvailability => 'فحص توفر الفنيين...';

  @override
  String get positionText => 'ترتيب';

  @override
  String get faqUpdatedSuccessfully => ' تم تحديث السؤال شائع بنجاح';

  @override
  String get deleteFaqEntry => 'حذف السؤال الشائع';

  @override
  String get manageTechnicians => 'ادارة الفنيين';

  @override
  String get manageCustomerSupport => 'ادارة خدمة العملاء';

  @override
  String get customerSupport => 'خدمة العملاء';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get addNewEmail => 'إضافة بريد جديد';

  @override
  String get add => 'اضافة';

  @override
  String get areYouSureYouWantToDeleteThisFaqEntry =>
      'هل انت متاكد انك تريد حذف هذا السؤال الشائع؟';

  @override
  String get thisActionCannotBeUndone => 'لا يمكن التراجع هذا الاجراء';

  @override
  String get supportContactDeletedSuccessfully => 'تم حذف جهة الدعم بنجاح';

  @override
  String get supportContactUpdatedSuccessfully => 'تم تحديث جهة الدعم بنجاح';

  @override
  String get supportContactAddedSuccessfully => 'تمت إضافة جهة الدعم بنجاح';

  @override
  String get noDataAvailable => 'لا توجد بيانات متاحة';

  @override
  String get deleteConfirmation => 'تأكيد الحذف';

  @override
  String get areYouSureYouWantToDeleteThisSupportContact =>
      'هل أنت متأكد أنك تريد حذف جهة الدعم؟';

  @override
  String get supportContact => 'جهة الدعم';

  @override
  String get phoneIsRequired => 'رقم الهاتف مطلوب';

  @override
  String get whatsappNumberIsRequired => 'رقم واتساب مطلوب';

  @override
  String get editEmail => 'تعديل البريد';

  @override
  String get addNewWhatsapp => 'إضافة رقم واتساب جديد';

  @override
  String get addNewPhone => 'إضافة رقم هاتف جديد';

  @override
  String get editWhatsapp => 'تعديل رقم واتساب';

  @override
  String get editPhone => 'تعديل رقم الهاتف';

  @override
  String get edit => 'تعديل';

  @override
  String get setAsPrimary => 'تعيينه كاساسي';

  @override
  String get primary => 'أساسي';

  @override
  String get search => 'بحث';

  @override
  String get all => 'الكل';

  @override
  String get disapproveAgent => 'رفض الفني';

  @override
  String get approveAgent => 'قبول الفني';

  @override
  String get areYouSureYouWantToDisapproveThisAgent =>
      'هل انت متاكد انك تريد رفض هذا الفني؟';

  @override
  String get areYouSureYouWantToApproveThisAgent =>
      'هل انت متاكد انك تريد قبول هذا الفني؟';

  @override
  String get tryAdjustingYourSearchCriteria =>
      'حاول تعديل معايير البحث الخاصة بك';

  @override
  String get noTechniciansMatchYourFilters => 'لا يوجد فنيين يطابقون فلتراتك';

  @override
  String get unblockCustomer => 'فك حظر العميل';

  @override
  String get filterByDate => 'تصفية حسب التاريخ';

  @override
  String get typeProvinceNameToSearch => 'اكتب اسم المنطقة للبحث...';

  @override
  String get typeCityNameToSearch => 'اكتب اسم المدينة للبحث...';

  @override
  String get typeNeighborhoodNameToSearch => 'اكتب اسم الحي للبحث...';

  @override
  String get areYouSureYouWantToUnblockThisCustomer =>
      'هل انت متاكد انك تريد فك حظر هذا العميل؟';

  @override
  String get noCustomersMatchYourSearch =>
      'لا يوجد عملاء يطابقون معايير البحث الخاصة بك';

  @override
  String get searchbyBookingIdnameTechnician =>
      'بحث عن رقم الحجز، اسم العميل، اسم الفني';

  @override
  String get block => 'حظر';

  @override
  String get days => 'أيام';

  @override
  String get hours => 'ساعات';

  @override
  String get minutes => 'دقائق';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get cancelledOn => 'تم الإلغاء في';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get selectDateRange => 'حدد نطاق التاريخ';

  @override
  String get unblock => 'فك الحظر';

  @override
  String get whatsappNumber => 'رقم واتساب';

  @override
  String get whatsappCondition =>
      'يرجى تأكيد رقم الهاتف الذي ادخلته بشكل صحيح. هذا النمط مطلوب لتعريف رقم الواتساب بشكل صحيح.';

  @override
  String get rewards => 'الجوائز';

  @override
  String get contactNotFound => 'جهة الاتصال غير موجودة';

  @override
  String get keepBooking => 'استمرار الحجز';

  @override
  String get orderCancelledSuccessfully => 'تم إلغاء الطلب بنجاح';

  @override
  String get failedToCancelOrder => 'فشل في إلغاء الطلب';

  @override
  String get accept => 'قبول';

  @override
  String get excellent => 'ممتاز';

  @override
  String get good => 'جيد';

  @override
  String get average => 'متوسط';

  @override
  String get poor => 'ضعيف';

  @override
  String get selected => 'محدد';

  @override
  String get selectAll => 'اختر الكل';

  @override
  String get inspectionFee => 'رسوم الفحص';

  @override
  String get cancelledBy => 'تم الإلغاء بواسطة';

  @override
  String get pleaseEnterInspectionFeeAmount => 'يرجى ادخال مبلغ رسوم الفحص';

  @override
  String get rejectBooking => 'رفض الحجز';

  @override
  String get pleaseuploadpaymentproof => 'يرجى تحميل بيانات الدفع';

  @override
  String get iban => 'IBAN';

  @override
  String get tapToUpload => 'انقر لرفع الصورة';

  @override
  String get selectSource => 'اختر المصدر';

  @override
  String get areYouSureYouWantToRejectThisBooking =>
      'هل أنت متأكد أنك تريد رفض هذا الحجز؟';

  @override
  String get acceptBooking => 'قبول الحجز';

  @override
  String get requestPayout => 'طلب دفعة';

  @override
  String get lastTip => 'آخر اكرامية';

  @override
  String get paymentBreakdown => 'تفاصيل الدفعات';

  @override
  String get cashPayments => 'مدفوعات نقدية';

  @override
  String get cardPayments => 'مدفوعات بالبطاقة';

  @override
  String get asOf => 'منذ';

  @override
  String get totalEarnings => 'إجمالي الأرباح';

  @override
  String get pleaseEnterAValidAmount => 'يرجى إدخال مبلغ صحيح';

  @override
  String get amountExceedsAvailableBalance => 'المبلغ يتجاوز الرصيد المتوفر';

  @override
  String get cashPaymentsAreAlreadyWithYou => 'المدفوعات النقدية بحوزتك بالفعل';

  @override
  String get amount => 'المبلغ';

  @override
  String get availableForPayout => 'متاح للسحب';

  @override
  String get theAdminWillProcessYourRequestWithin2to3days =>
      'سيتم معالجة طلبك من قبل الإدارة خلال يومين إلى ثلاثة أيام';

  @override
  String get availableBalance => 'الرصيد المتوفر';

  @override
  String get areYouSureYouWantToAcceptThisBooking =>
      'هل أنت متأكد أنك تريد قبول هذا الحجز؟';

  @override
  String get cancelledByCustomer => 'تم الإلغاء بواسطة العميل';

  @override
  String get bookingDetails => 'تفاصيل الحجز';

  @override
  String get confirmCancellation => 'تأكيد الإلغاء';

  @override
  String get adminCancelWarning =>
      'هل أنت متأكد أنك تريد إلغاء هذا الحجز؟ سيتم اشعار العميل. إلغاء هذا الحجز لن يقوم تلقائيًا برد المبلغ للعميل. يرجى التأكد من معالجة أي ردود أموال ضرورية يدويًا.';

  @override
  String get atleastOneContactIsrequired => 'مطلوب على الاقل جهة اتصال واحدة';

  @override
  String get cannotRemovePrimaryStatusFromTheOnlyContact =>
      'لا يمكن إزالة حالة \"أساسي\" من جهة الاتصال';

  @override
  String get submitRequest => 'إرسال الطلب';

  @override
  String get payoutAccounts => 'حسابات الدفع';

  @override
  String get noPayoutAccountsAdded => 'لم يتم إضافة حسابات دفع بعد';

  @override
  String get imageIsTooLargePleaseSelectAnImageSmallerThan5MB =>
      'الصورة كبيرة جدًا، يرجى اختيار صورة أصغر من 5MB';

  @override
  String get managePayouts => 'إدارة التحويلات المالية';

  @override
  String get requestedOn => 'تم الطلب في';

  @override
  String get selectedFileCouldNotBeFound => 'لم يتم العثور على الملف المحدد';

  @override
  String get errorPickingImage => 'حدث خطأ في اختيار الصورة';

  @override
  String get errorCroppingImage => 'حدث خطأ في القص';

  @override
  String get technicianInformation => 'معلومات الفني';

  @override
  String get noPayoutRequestsYet => 'لا توجد طلبات دفع حتى الآن';

  @override
  String get reviews => 'التقييمات';

  @override
  String get payoutHistory => 'تاريخ الدفع';

  @override
  String get searchByTechnicianNameOrAmount => 'ابحث باسم الفني أو المبلغ...';

  @override
  String get tipDetails => 'تفاصيل الإكرامية';

  @override
  String get tipsSummary => 'ملخص الإكرامية';

  @override
  String get noPayoutHistoryAvailable => 'لا يوجد تاريخ دفع متاح';

  @override
  String get smsRetrievalTimedOut =>
      'انتهت مهلة استرجاع رسالة الـ SMS. يرجى التحقق مما إذا كنت قد استلمت الرمز أو حاول مرة أخرى.';

  @override
  String get payoutRequirement =>
      'لطلب سحب الإكرامية، يجب أن يكون لديك ما لا يقل عن 10 ريالات متاحة للسحب.';

  @override
  String get notEnoughBalanceforRequestingTipPayout =>
      'لا يوجد كافية لطلب سحب الإكرامية';

  @override
  String get cashTips => 'نقاط الإكراميات النقدية';

  @override
  String get cardTips => 'نقاط الإكراميات بالبطاقة';

  @override
  String get am => 'صباحًا';

  @override
  String get pm => 'مساءً';

  @override
  String get inHand => 'كاش';

  @override
  String get errorLoadingReviews => 'حدث خطأ في تحميل التقييمات';

  @override
  String get noReviewsYet => 'لا توجد تقييمات حتى الآن';

  @override
  String get reviewsWillAppearHereAfterCustomersRateYourService =>
      'ستظهر التقييمات هنا بعد تقييم العملاء للخدمة';

  @override
  String get approved => 'موافق';

  @override
  String get total => 'المجموع';

  @override
  String get failedToLoadVideo => 'فشل تحميل الفيديو';

  @override
  String get payoutAmount => 'مبلغ الدفعة';

  @override
  String get bankAccountDetails => 'تفاصيل الحساب البنكي';

  @override
  String get approve => 'قبول';

  @override
  String get rejectPayout => 'رفض الدفعة';

  @override
  String get payoutApproved => 'تم الموافقة على الدفعة';

  @override
  String get approvePayout => 'قبول الدفعة';

  @override
  String get fileRequired => 'الملف مطلوب';

  @override
  String get transactionNumberRequired => 'رقم المعاملة مطلوب';

  @override
  String get viewAndManageEarnings => 'عرض وإدارة الأرباح';

  @override
  String get supportedFormats => 'الصيغ المدعومة:';

  @override
  String get lifetimeTips => 'اجمالي الاكراميات';

  @override
  String get pleaseProvideTransactionDetails =>
      'يرجى تقديم تفاصيل المعاملة لقبول طلب الدفعة.';

  @override
  String get pdfImageOrDocument => 'PDF, صورة أو مستند';

  @override
  String get tapToSelectFile => 'اضغط لتحديد الملف';

  @override
  String get lifetimeEarnings => 'إجمالي الأرباح';

  @override
  String get uploadProof => 'رفع الإثبات';

  @override
  String get notenoughtipstorequestpayoutminSAR10 =>
      'لا توجد إكرامية كافية لطلب الدفع (الحد الأدنى 10 ر.س)';

  @override
  String get requestTipPayout => 'طلب دفعة إكرامية';

  @override
  String get errorRequestingPayout => 'حدث خطأ في طلب الدفعة';

  @override
  String get payoutRequestSubmittedSuccessfully => 'تم إرسال طلب الدفعة بنجاح';

  @override
  String get areYouSureYouWantToRequestAPayoutForTheAccumulatedTips =>
      'هل أنت متأكد أنك تريد طلب دفعة للإكراميات؟';

  @override
  String get transactionNumber => 'رقم المعاملة';

  @override
  String get tipspayoutisdoneseparately => 'يتم دفع الإكراميات بشكل منفصل.';

  @override
  String get pleaseProvideARejectionReason => 'يرجى تقديم سبب الرفض';

  @override
  String get enterTransactionNumber => 'أدخل رقم المعاملة';

  @override
  String get youHaveNoPayoutAccountsgotoprofilesectionandaddanaccount =>
      'ليس لديك حسابات دفع بعد. اذهب إلى قسم الملف الشخصي وأضف حسابًا';

  @override
  String get payoutRejectedSuccessfully => 'تم رفض الدفعة بنجاح';

  @override
  String get payoutRejected => 'رفض الدفعة';

  @override
  String get rejectConfirmation => 'هل أنت متأكد أنك تريد رفض طلب الدفعة؟';

  @override
  String get reason => 'السبب';

  @override
  String get enterTheReason => 'أدخل سبب رفض طلب الدفعة';

  @override
  String get payoutRequests => 'طلبات الدفع';

  @override
  String get status => 'الحالة';

  @override
  String get noPayoutRequestsFound => 'لم يتم العثور على طلبات دفع';

  @override
  String get payoutRequestCancelled => 'تم إلغاء طلب الدفع';

  @override
  String get areYouSureYouWantToCancelThisPayoutRequest =>
      'هل أنت متأكد أنك تريد إلغاء طلب الدفعة؟';

  @override
  String get addAnAccountToReceivePayments => 'أضف حسابًا لاستلام الدفعات';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get accountNumber => 'رقم الحساب';

  @override
  String get ifscCode => 'كود IFSC';

  @override
  String get addFirstAccount => 'أضف حسابك الأول';

  @override
  String get enterAccountDetails => 'أدخل تفاصيل الحساب';

  @override
  String get manageBankAccounts => 'إدارة حسابات البنك';

  @override
  String get addAndManageYourPayoutAccounts => 'إدارة حسابات الدفع الخاصة بك';

  @override
  String get updateAccountDetails => 'تحديث تفاصيل الحساب';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get primaryAccountUpdated => 'تم تحديث الحساب الرئيسي';

  @override
  String get deleteAccountConfirmation =>
      'هل أنت متأكد أنك تريد حذف هذا الحساب؟';

  @override
  String get accountDeletedSuccessfully => 'تم حذف الحساب بنجاح';

  @override
  String get editAccount => 'تعديل الحساب';

  @override
  String get pleaseEnterAccountNumber => 'يرجى إدخال رقم الحساب';

  @override
  String get accountHolderName => 'اسم صاحب الحساب';

  @override
  String get nameMustBeAtLeast3Chars => 'يجب أن يكون الاسم أكثر من 3 أحرف';

  @override
  String get pleaseEnterAccountHolderName => 'يرجى إدخال اسم صاحب الحساب';

  @override
  String get bankName => 'اسم البنك';

  @override
  String get updateAccount => 'تحديث الحساب';

  @override
  String get setPrimary => 'تعيينه كحساب رئيسي';

  @override
  String get accountAddedSuccessfully => 'تمت إضافة الحساب بنجاح';

  @override
  String get accountUpdatedSuccessfully => 'تم تحديث الحساب بنجاح';

  @override
  String get savings => 'المدخرات';

  @override
  String get enterAccountHolderName => 'أدخل اسم صاحب الحساب';

  @override
  String get enterifscCode => 'أدخل كود IFSC';

  @override
  String get enterBankName => 'أدخل اسم البنك';

  @override
  String get enterAccountNumber => 'أدخل رقم الحساب';

  @override
  String get setAsPrimaryAccount => 'ضبط كحساب رئيسي';

  @override
  String get pleaseEnterBankName => 'يرجى إدخال اسم البنك';

  @override
  String get pleaseEnterIfscCode => 'يرجى إدخال كود IFSC';

  @override
  String get copyId => 'نسخ الرقم';

  @override
  String get notSelected => 'غير محدد';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get refresh => 'تحديث';

  @override
  String get loadingCustomers => 'جارٍ تحميل العملاء';

  @override
  String get processing => 'جارٍ المعالجة';

  @override
  String get allReviews => 'جميع التقييمات';

  @override
  String get service => 'خدمة';

  @override
  String get ratingDistribution => 'توزيع التقييمات';

  @override
  String get payoutRequestSuccessful => 'تم طلب الدفع بنجاح';

  @override
  String get rejectedBy => 'تم الرفض بواسطة';

  @override
  String get rejectedOn => 'تم الرفض في';

  @override
  String get acceptedOn => 'تم التأكيد في';

  @override
  String get acceptedBy => 'تم التأكيد بواسطة';

  @override
  String get completedOn => 'تم الاكتمال في';

  @override
  String get completedBy => 'تم الاكتمال بواسطة';

  @override
  String get confirmDetails => 'تأكيد البيانات';

  @override
  String get loadingCategories => 'جارٍ تحميل الأقسام...';

  @override
  String get pleaseUploadFiles => 'يرجى تحميل الملفات';

  @override
  String get confirmCompletion => 'تأكيد الانجاز';

  @override
  String get uploadFilesTitle => 'الوثائق / المستندات المساعدة';

  @override
  String get uploadHint =>
      'قم بتحميل صورة أو صورة الفاتورة لعرضها على العميل عند إكمال الخدمة';

  @override
  String get pleaseUploadFilesMessage =>
      'يرجى تحميل الوثائق / المستندات المساعدة';

  @override
  String get confirmCompletionMessage =>
      'هل أنت متأكد أنك تريد تأكيد انجاز هذا الحجز؟';

  @override
  String get cannotCancel =>
      'لا يمكن إلغاء الحجز أثناء التتبع. يرجى إيقاف التتبع أولًا ثم يمكنك إلغاء الحجز.';

  @override
  String get cannotCompleteBookingWhileTracking =>
      'لا يمكن إنهاء الحجز أثناء التتبع. يرجى إيقاف التتبع أولًا ثم يمكنك إنهاء الحجز.';

  @override
  String get editSelection => 'تعديل الاختيار';

  @override
  String get noRecipientsSelected => 'لم يتم اختيار أي مستلمين';

  @override
  String get apply => 'تطبيق';

  @override
  String get tapToUploadFiles => 'انقر لتحميل الملفات';

  @override
  String get addRecipients => 'إضافة المستلمين';

  @override
  String get serviceItemsCalculationNote =>
      'سيتم حساب التكلفة الإجمالية تلقائيًا على أساس (الكمية × السعر) لكل عنصر وإضافتها إلى رسوم الفحص.';

  @override
  String get addMoreFiles => 'اضافة الملفات';

  @override
  String get allowedFileTypes =>
      'الملفات المسموح بها: jpg, jpeg, png, pdf, doc,';

  @override
  String get uploadFiles => 'تحميل الملفات';

  @override
  String get filesAttached => 'الوثائق المرفقة';

  @override
  String get costBreakdown => 'تفصيل التكلفة';

  @override
  String get removeItem => 'إزالة العنصر';

  @override
  String get removeItemConfirmation =>
      'هل أنت متأكد أنك تريد إزالة هذا العنصر؟';

  @override
  String get remove => 'إزالة';

  @override
  String get noBannersAAddedYet => 'لا توجد بانرات حتى الآن';

  @override
  String get availableRoles => 'الوظائف المتاحة';

  @override
  String get fifteenpercentBonusOnEarningsandASpecialBadge =>
      'مكافأة 15% على الأرباح + شارة خاصة';

  @override
  String get tenpercentBonusOnEarnings => 'خصم 10% على الأرباح';

  @override
  String get fivepercentBonusOnEarnings => 'خصم 5% على الأرباح';

  @override
  String get invalidAccountNumberLength => 'طول رقم الحساب غير صحيح';

  @override
  String doneSelectedCount(int count) {
    return 'تم ($count محدد)';
  }

  @override
  String payoutRequestSuccessfulMessage(String amount) {
    return 'طلب الدفع ($amount ر.س) مقدم بنجاح';
  }

  @override
  String cashPaymentsMessage(String amount) {
    return 'المدفوعات النقدية ($amount ر.س) معك بالفعل';
  }

  @override
  String cannotDeleteLastContact(String contactType) {
    return 'لا يمكن حذف آخر جهة اتصال $contactType. مطلوب جهة اتصال واحدة على الأقل.';
  }

  @override
  String get personalInfo => 'معلومات شخصية';

  @override
  String get batteryOptimization => 'تحسينات البطارية';

  @override
  String get later => 'لاحقًا';

  @override
  String get locationError => 'خطأ في الموقع';

  @override
  String get locationServicesIos =>
      'هذا خطأ في أذونات الموقع على نظام iOS. يرجى التحقق من إعدادات الموقع.';

  @override
  String get locationServices => 'يرجى تفعيل خدمات الموقع من إعدادات جهازك.';

  @override
  String get locationPermission =>
      'يرجى منح إذن الموقع من الإعدادات واختيار \"السماح دائمًا\" لتتبع الخلفية.';

  @override
  String get batteryOptimizationWarning =>
      'لتمكين تتبع الموقع في الخلفية، يرجى تعطيل تحسينات البطارية لهذا التطبيق. هذا يضمن تحديث الموقع حتى عندما يكون التطبيق في الخلفية.';

  @override
  String get bookingHistory => 'تاريخ الحجز';

  @override
  String get pleaseSelectAtLeastOneRecipient =>
      'يرجى اختيار مستلم واحد على الأقل';

  @override
  String get fillInAtLeastEnglishOrArabicMessageContent =>
      'يرجى إدخال محتوى رسالة باللغة الإنجليزية أو العربية';

  @override
  String get searchByNameEmailOrPhone =>
      'بحث بالاسم أو البريد الإلكتروني أو رقم الهاتف...';

  @override
  String get noFcmTokenAvailable => 'لا يوجد رمز FCM';

  @override
  String get selectRecipients => 'اختر المستلمين';

  @override
  String get removeAll => 'إزالة الكل';

  @override
  String get documents => 'وثائق';

  @override
  String get allData => 'جميع البيانات المرتبطة';

  @override
  String get networkError => 'خطأ في الشبكة';

  @override
  String get biometricEnabled => 'تم تفعيل البصمة';

  @override
  String get biometricDisabled => 'تم تعطيل البصمة';

  @override
  String get disableBiometricWarning =>
      'تعطيل البصمة سيمنعك من تسجيل الدخول باستخدام البصمة';

  @override
  String get youWillNeedPhoneOtp =>
      'سوف تحتاج إلى استخدام رقم الهاتف وOTP لتسجيل الدخول';

  @override
  String get whatWillBeDeleted => 'سوف يتم حذف:';

  @override
  String get disable => 'تعطيل';

  @override
  String get disableBiometric => 'تعطيل البصمة';

  @override
  String get optional => 'اختياري';

  @override
  String get province => 'المنطقة/المحافظة';

  @override
  String get pleaseSelectCity => 'يرجى تحديد المدينة';

  @override
  String get pleaseSelectGovernorate => 'يرجى تحديد المحافظة';

  @override
  String get governorate => 'المحافظة';

  @override
  String get neighborhood => 'الحي';

  @override
  String get pleaseSelectNeighborhood => 'يرجى تحديد الحي';

  @override
  String get pleaseSelectProvince => 'يرجى تحديد المحافظة';

  @override
  String get otpExpired => 'OTP منتهي الصلاحية';

  @override
  String get invalidOTP => 'OTP غير صحيح';

  @override
  String get invalidPhoneNumber => 'رقم الهاتف غير صحيح';

  @override
  String get otpSentSuccessfully => 'تم إرسال OTP بنجاح';

  @override
  String get otpCode => 'رمز OTP';

  @override
  String get registerAsTechinicianInfo => 'سجّل رقم هاتفك لإنشاء حساب فني';

  @override
  String get phoneAlreadyRegistered => 'رقم الهاتف مسجل مسبقاً';

  @override
  String get invalidOtpCode => 'رمز OTP غير صحيح';

  @override
  String get quotaExceeded => 'تم تجاوز الكوتا';

  @override
  String get internalError => 'خطأ داخلي';

  @override
  String get resend => 'إعادة إرسال';

  @override
  String get or => 'أو';

  @override
  String get loginWithBiometric => 'تسجيل الدخول باستخدام البصمة';

  @override
  String get migratingData => 'تحويل البيانات';

  @override
  String get weAreMigratingYourData => 'نحن نقوم بتحويل بياناتك';

  @override
  String get pleaseDontCloseTheApp => 'يرجى لا تقطع التطبيق';

  @override
  String get transferringData => 'تحويل البيانات';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get sendingOTP => 'إرسال OTP';

  @override
  String get cancelRegistration => 'إلغاء التسجيل';

  @override
  String get loggingIn => 'تسجيل الدخول';

  @override
  String get didNotReceiveOTP => 'لم يتم استلام OTP؟';

  @override
  String get cancelRegistrationConfirmation =>
      'هل أنت متأكد أنك تريد إلغاء التسجيل؟';

  @override
  String get registrationSuccessful => 'تم التسجيل بنجاح';

  @override
  String get otpMustBe6Digits => 'OTP يجب أن يكون 6 أرقام';

  @override
  String get pleaseEnterOTP => 'يرجى إدخال OTP';

  @override
  String get resendOTP => 'إعادة إرسال OTP';

  @override
  String get enterReasonForCancel => 'الرجاء ادخال سبب الإلغاء';

  @override
  String get noTechnicianAssigned => 'لم يتم تعيين فنّي';

  @override
  String get enterReasonForReject => 'الرجاء ادخال سبب الرفض';

  @override
  String get noWarrantyRequests => 'لا توجد طلبات ضمان';

  @override
  String get completeWarrantyRepair => 'إكمال إصلاح الضمان';

  @override
  String get areYouSureYouWantToCompleteThisWarrantyRepairThisIsAFreeService =>
      'هل أنت متأكد أنك تريد إكمال إصلاح الضمان؟ هذه خدمة مجانية.';

  @override
  String get areYouSureYouWantToStopTrackingThisWarrantyRepair =>
      'هل أنت متأكد أنك تريد إيقاف تتبع إصلاح الضمان؟';

  @override
  String get areYouSureYouWantToStartTrackingThisWarrantyRepair =>
      'هل أنت متأكد أنك تريد بدء تتبع إصلاح الضمان؟';

  @override
  String get anotherBookingIsAlreadyBeingTracked =>
      'هناك حجز آخر يتم تتبعه بالفعل';

  @override
  String get requested => 'تم الطلب';

  @override
  String
  get areYouSureYouWantToCancelThisWarrantyRepairThisActionCannotBeUndone =>
      'هل أنت متأكد أنك تريد إلغاء إصلاح الضمان؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get reasonMustBeAtLeast10Characters =>
      'يجب أن يك تف السبب 10 أحرف على الأقل';

  @override
  String get cancelWarrantyRepair => 'إلغاء إصلاح الضمان';

  @override
  String get areYouSureYouWantToDeleteThisFile =>
      'هل أنت متأكد أنك تريد حذف هذا الملف؟';

  @override
  String get sendOtp => 'إرسال OTP';

  @override
  String get rejectWarrantyClaimMessage =>
      'هل أنت متأكد من رغبتك في رفض هذا الطلب؟';

  @override
  String get invalidPhoneNumberLength => 'طول رقم الهاتف غير صحيح';

  @override
  String get phoneNumberMustIncludeCountryCode =>
      'يجب أن يتضمن رقم الهاتف رمز الدولة';

  @override
  String get pleaseEnterPhoneNumber => 'يرجى إدخال رقم الهاتف';

  @override
  String get fileTooLarge => 'الملف كبير جداً';

  @override
  String get warrantyClaimRejected => 'تم رفض الطلب';

  @override
  String get rejectWarrantyClaim => 'رفض الطلب';

  @override
  String get workCompleted => 'تم إكمال العمل';

  @override
  String get resetFilters => 'إعادة التعيين';

  @override
  String get technician => 'الفني';

  @override
  String get noBankAccountDetailsAvailable => 'لا توجد تفاصيل حساب بنكي';

  @override
  String get acceptWarrantyClaim => 'قبول الطلب';

  @override
  String get areYouSureYouWantToRejectThisWarrantyClaim =>
      'هل أنت متأكد من رغبتك في رفض هذا الطلب؟';

  @override
  String get acceptWarrantyClaimMessage =>
      'هل أنت متأكد من رغبتك في قبول هذا الطلب؟';

  @override
  String get completeWorkMessage => 'هل أنت متأكد من رغبتك في إكمال هذا العمل؟';

  @override
  String get startWorkMessage => 'هل أنت متأكد من رغبتك في بدء العمل؟';

  @override
  String get stopTrackingMessage =>
      'هل أنت متأكد من رغبتك في إيقاف تتبع هذا العمل؟';

  @override
  String get warrantyClaimCancelled => 'تم إلغاء الطلب';

  @override
  String get cancelWarrantyClaim => 'إلغاء الطلب';

  @override
  String get cancelWork => 'إلغاء العمل';

  @override
  String get cancelWarrantyClaimMessage => 'الرجاء ادخال سبب الإلغاء';

  @override
  String get cropDocument => 'قص الوثائق';

  @override
  String get tapToRetry => 'اضغط للاعادة';

  @override
  String get completeRegistration => 'إكمال التسجيل';

  @override
  String get chooseFromList => 'اختر من القائمة';

  @override
  String get nameTooShort => 'اسم قصير جداً';

  @override
  String get pleaseEnterYourName => 'يرجى إدخال اسمك';

  @override
  String get uploadCertifications => 'تحميل الشهادات';

  @override
  String get certifications => 'الشهادات';

  @override
  String get idDocumentUploaded => 'تم تحميل الوثيقة الشخصية';

  @override
  String get uploadIdDocument => 'تحميل الوثيقة الشخصية';

  @override
  String get idDocument => 'الوثيقة الشخصية';

  @override
  String get pleaseUploadIdDocument => 'يرجى تحميل الوثيقة الشخصية';

  @override
  String get pleaseSelectLocation => 'يرجى اختيار الموقع';

  @override
  String get creatingAccount => 'يتم إنشاء الحساب';

  @override
  String get pleaseWait => 'يرجى الانتظار';

  @override
  String get noJobCategoriesAvailable => 'لا توجد فئات عمل متاحة';

  @override
  String get availabilityStatus => 'حالة التوافر';

  @override
  String get youAreNowOnline => 'أنت الآن متاح';

  @override
  String get youAreNowOffline => 'أنت الآن غير متاح';

  @override
  String get youAreCurrentlyUnavailable => 'أنت حالياً غير متاح للطلبات';

  @override
  String get youAreAvailableForRequests => 'أنت متاح للطلبات';

  @override
  String get files => 'الملفات';

  @override
  String get phoneNumberAlreadyUpdated => 'رقم الهاتف تم تحديثه مسبقاً';

  @override
  String get phoneNumberFormatHint => 'يجب أن يبدأ رقم الهاتف بـ 05';

  @override
  String get manageTransactions => 'إدارة المعاملات';

  @override
  String get noTransactionsFound => 'لا توجد معاملات';

  @override
  String get tooManyAttempts => 'عدد المحاولات أنتهي';

  @override
  String get cash => 'نقدي';

  @override
  String get transactions => 'معاملات';

  @override
  String get transactionDetails => 'تفاصيل المعاملة';

  @override
  String get pleaseSelectAllLocationFields => 'يرجى تحديد جميع حقول الموقع';

  @override
  String get bookingName => 'اسم الحجز';

  @override
  String get technicianName => 'اسم الفني';

  @override
  String get changeIdDocument => 'تغيير الوثيقة الشخصية';

  @override
  String get notAssigned => 'غير معين';

  @override
  String get date => 'التاريخ';

  @override
  String get removeFile => 'إزالة الملف';

  @override
  String get removeFileConfirmation => 'هل أنت متأكد أنك تريد إزالة هذا الملف؟';

  @override
  String get errorSendingNotifications => 'خطأ في إرسال الإشعارات';

  @override
  String get fillInBothEnglishAndArabicMessageContent =>
      'الرجاء تعبئة محتوى الرسالة باللغتين الإنجليزية والعربية';

  @override
  String notificationSenttoTechnicians(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إرسال الإشعار إلى $count فنّيين.',
      one: 'تم إرسال الإشعار إلى فنّي واحد.',
    );
    return '$_temp0';
  }

  @override
  String get locationTracking => 'تتبع الموقع';

  @override
  String get trackingInactive => 'الإيقاف غير النشط';

  @override
  String get trackingActive => 'الإيقاف النشط';

  @override
  String get fix => 'إصلاح';

  @override
  String get locationTrackingStartedSuccessfully => 'تم بدء تتبع الموقع بنجاح';

  @override
  String get locationTrackingHelpText =>
      'تتبع الموقع يساعد العملاء على تتبع تقدمك. تأكد من تفعيل خدمات الموقع.';

  @override
  String get batteryOptimizationEnabled =>
      'تم تفعيل تحسين البطارية. هذا قد يؤثر على تتبع الموقع في الخلفية.';

  @override
  String get agentAssignedSuccessfully => 'تم تعيين الفني بنجاح';

  @override
  String get orderRejectedSuccessfully => 'تم رفض الطلب بنجاح';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get couldNotLaunchPhone => 'تعذر فتح تطبيق الهاتف';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دقائق $count منذ',
      one: 'منذ 1 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام $count منذ',
      one: 'منذ 1 يوم',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ساعات $count منذ',
      one: 'منذ 1 ساعة',
    );
    return '$_temp0';
  }

  @override
  String get paymentCompletedAt => 'تم إكمال الدفع في';

  @override
  String get more => 'المزيد';

  @override
  String get amountToBePaid => 'المبلغ المطلوب دفعه';

  @override
  String get cannotRequestPayoutPendingRequest =>
      'لديك طلب سحب قيد المعالجة. يرجى الانتظار حتى يتم الموافقة عليه أو رفضه.';

  @override
  String get paidAmount => 'المبلغ المدفوع';

  @override
  String get customerInformation => 'معلومات العميل';

  @override
  String get serviceInformation => 'معلومات الخدمة';

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get termsOfUse => 'شروط الاستخدام';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get and => 'و';

  @override
  String get copy => 'نسخ';

  @override
  String get introduction => 'مقدمة';

  @override
  String get policy1title => 'البيانات التي نجمعها';

  @override
  String get policy2title => 'كيفية الاستخدام';

  @override
  String get policy3title => 'مشاركة البيانات';

  @override
  String get terms1title => 'المسؤولية عن الطلب';

  @override
  String get terms2title => 'رسوم المعاينة';

  @override
  String get terms3title => 'الدفع والتكلفة النهائية';

  @override
  String get terms4title => 'الضمان (الكفالة)';

  @override
  String get terms5title => 'التقييم';

  @override
  String get searchByCustomerName => 'بحث باسم العميل';

  @override
  String get phoneNumberUpdateInfo =>
      'أدخل رقم الهاتف الذي يبدأ بـ \"05\" لتحديث رقم الهاتف';

  @override
  String get termsIntroduction =>
      'يُعد استخدامك للتطبيق قبولاً كاملاً وغير مشروط لهذه الشروط. التطبيق هو منصة وساطة إلكترونية تربطك بمقدمي الخدمات الفنية فقط.';

  @override
  String get terms1 =>
      'تلتزم بتقديم وصف دقيق وكافٍ للمشكلة (نص، صورة، فيديو) وموقع الخدمة لتمكين الفني من الاستجابة.';

  @override
  String get terms2 =>
      'أنت مسؤول عن دفع رسوم المعاينة/الفحص المحددة (إذا وجدت) بمجرد قبول الفني للطلب وتوجهه إلى الموقع. هذه الرسوم غير قابلة للاسترداد عادةً.';

  @override
  String get terms3 =>
      'الدفع والتكلفة النهائية: يتم الاتفاق على التكلفة الإجمالية للخدمة مباشرة مع الفني بعد المعاينة، وتتم الموافقة عليها عبر التطبيق قبل بدء العمل. أنت مسؤول عن سداد المبلغ المتفق عليه كاملاً.';

  @override
  String get terms4p1 => 'يخضع العمل المنجز لـ';

  @override
  String get warrantyPolicy => 'سياسة الضمان';

  @override
  String get terms4p2 =>
      'الخاصة بالمنصة، والتي يمكنك الاطلاع على تفاصيلها الكاملة عبر الرابط المخصص.';

  @override
  String get terms5 =>
      'يحق لك تقييم أداء الفني بعد إتمام الخدمة، وتلتزم بأن تكون التقييمات صادقة وموضوعية.';

  @override
  String get policy1 =>
      'الاسم، رقم الهاتف، البريد الإلكتروني، عنوان الموقع الدقيق لتلقي الخدمة، سجل الطلبات، تقييمات الفنيين.';

  @override
  String get policy2 =>
      'تستخدم لربطك بالفنيين، وتسهيل عملية الحجز والدفع، وإرسال إشعارات الطلبات.';

  @override
  String get policy3 =>
      'يتم مشاركة الاسم ورقم الهاتف وعنوان الموقع فقط مع الفني الذي تم قبول طلبه لتمكينه من أداء الخدمة.';

  @override
  String get waitingForAdminAction => 'بانتظار إجراء المسؤول';

  @override
  String get whatsCovered => 'ما يغطيه الضمان';

  @override
  String get issueone => 'خطأ في التركيب أو سوء المصنعية.';

  @override
  String get issuetwo => 'أداء دون المستوى المطلوب من الفني.';

  @override
  String get issuethree => 'نفس العطل الأصلي الذي تم إصلاحه.';

  @override
  String get issuefour => 'صالح لمرة واحدة خلال ٧ أيام من تاريخ الإكمال';

  @override
  String get whatsNotCovered => 'ما لا يغطيه الضمان';

  @override
  String get notissueone => 'قطع غيار أو مواد معيبة.';

  @override
  String get notissuetwo => 'إساءة الاستخدام أو العبث بعد الخدمة.';

  @override
  String get notissuethree => 'تدخلات طرف ثالث.';

  @override
  String get notissuefour =>
      'زيادة التيار الكهربائي (Power surges)، تسربات المياه، الكوارث الطبيعية.';

  @override
  String get notissuefive => 'الاهتراء والتآكل الطبيعي.';

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get wallet => 'المحفظة';

  @override
  String get walletSynced => 'تمت مزامنة المحفظة بنجاح';

  @override
  String get payoutRequested => 'تم تقديم طلب السحب بنجاح';

  @override
  String get balanceBreakdown => 'تفاصيل الرصيد';

  @override
  String get selectAmounts => 'اختر المبالغ';

  @override
  String get available => 'المتاح';

  @override
  String get paid => 'المدفوع';

  @override
  String get tips => 'الإكراميات';

  @override
  String get payoutPending => 'طلب السحب قيد الانتظار';

  @override
  String get requestedAmount => 'المبلغ المطلوب';

  @override
  String get payoutNote =>
      'ملاحظة: سيتم إرسال هذا الطلب إلى الإدارة للموافقة. سيتم طلب كامل الرصيد المتاح.';

  @override
  String get noPayoutRequests => 'لا توجد طلبات سحب حتى الآن';

  @override
  String get max => 'الأعلى';

  @override
  String get min => 'الأدنى';

  @override
  String get useMax => 'استخدام الحد الأعلى';

  @override
  String get searchByWorkerName => 'ابحث باسم العامل';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get totalAmount => 'إجمالي المبلغ';

  @override
  String get payoutDetails => 'تفاصيل السحب';

  @override
  String get workerName => 'اسم العامل';

  @override
  String get payoutAccount => 'حساب السحب';

  @override
  String get requestDate => 'تاريخ الطلب';

  @override
  String get rejectionReason => 'سبب الرفض';

  @override
  String get enterTransactionId => 'أدخل رقم العملية';

  @override
  String get uploadPaymentProof => 'ارفع إثبات الدفع';

  @override
  String get proofUploaded => 'تم رفع الإثبات بنجاح';

  @override
  String get enterReason => 'أدخل السبب';

  @override
  String get cancelPayoutConfirmation =>
      'هل أنت متأكد أنك تريد إلغاء طلب السحب؟';

  @override
  String get payoutCancelled => 'تم إلغاء طلب السحب بنجاح';

  @override
  String get confirmPayoutRequest => 'أنت على وشك طلب سحب كامل رصيدك المتاح';

  @override
  String get bonusIncludedInWallet =>
      'المكافأة مدمجة ضمن محفظتك الموحدة. اطلب السحب من صفحة الأرباح.';

  @override
  String get claimText =>
      'للمطالبة بالضمان، قدّم طلبًا عبر التطبيق خلال ٧ أيام من إتمام الخدمة. ويمكن المطالبة بالضمان مرة واحدة فقط.';

  @override
  String get syncWallet => 'مزامنة المحفظة';

  @override
  String get alreadyInHand => 'بالفعل مستلم';

  @override
  String get minimumPayoutAmount => 'الحد الأدنى لمبلغ السحب هو 10 ريال';

  @override
  String get enableAvailability => 'تفعيل الجاهزية';

  @override
  String get welcomeDescription =>
      'لتبدأ في استقبال طلبات الحجز، يرجى تفعيل حالة الجاهزية في لوحة القيادة.';

  @override
  String get welcomeToAboGlumboTechnician => 'مرحباً بك في أبو جلمبو فني!';

  @override
  String get onlyMainAdminCanManageAdminAccess =>
      'فقط المشرف الرئيسي يمكنه إدارة الوصول';

  @override
  String get cannotModifyMainAdminAccount =>
      'لا يمكن تعديل حساب المشرف الرئيسي';

  @override
  String get adminAccessRevokedFor => 'تم إلغاء صلاحيات المشرف لـ';

  @override
  String get adminAccess => 'صلاحيات المشرف';

  @override
  String get selectAdminAccessLevelFor => 'اختر مستوى صلاحيات المشرف لـ';

  @override
  String get fullAdmin => 'مشرف كامل';

  @override
  String get customerService => 'خدمة العملاء';

  @override
  String get grantAccess => 'منح الصلاحيات';

  @override
  String get grantingAdminAccess => 'جارٍ منح صلاحيات المشرف';

  @override
  String get adminAccessGrantedTo => 'تم منح صلاحيات المشرف لـ';

  @override
  String get revokeAdminAccess => 'إلغاء صلاحيات المشرف';

  @override
  String get revokingAdminAccess => 'جارٍ إلغاء صلاحيات المشرف';

  @override
  String get revoke => 'إلغاء';

  @override
  String get switchToAdmin => 'التبديل إلى وضع المشرف';

  @override
  String get manageAdmins => 'إدارة المشرفين';

  @override
  String get searchAdmins => 'البحث عن المشرفين...';

  @override
  String get aboutUs => 'عننا';

  @override
  String get noAdminsFound => 'لم يتم العثور على مشرفين';

  @override
  String get loadingAdmins => 'جارٍ تحميل المشرفين...';

  @override
  String get noAdminsMatchYourFilters => 'لا يوجد مشرفون يطابقون عوامل التصفية';

  @override
  String get grantedOn => 'تم المنح في';

  @override
  String get selectRecipientType => 'اختر نوع المستلم';

  @override
  String get recipientsSelected => 'المستلمين محدد';

  @override
  String get areYouSureYouWantToRevokeAdminAccessFor =>
      'هل أنت متأكد أنك تريد إلغاء صلاحيات المشرف لـ';

  @override
  String get onlyTheMainAdminCanRevokeAdminAccess =>
      'يمكن للمشرف الرئيسي فقط إلغاء صلاحيات المشرفين';

  @override
  String get accessToAllAdminFeaturesExceptManagingOtherAdmins =>
      'الوصول إلى جميع ميزات الإدارة باستثناء إدارة المشرفين الآخرين';

  @override
  String get viewOnlyAccessToCustomersTechniciansAndSupport =>
      'صلاحية عرض فقط للعملاء والفنيين والدعم';

  @override
  String get loginDescription =>
      'جاهز للشغل؟ فرص عمل قريبة ودخل أفضل بانتظارك.';

  @override
  String get aboutUsTitle => 'من نحن';

  @override
  String get aboutUsHeadline => 'فرصتك للنمو الاحترافي تبدأ هنا';

  @override
  String get aboutUsIntro =>
      'انضم إلى شبكة الفنيين المعتمدة في تطبيقنا وخذ خطوتك التالية نحو الاستقلالية المالية والتميز المهني. نحن لا نقدم لك وظيفة، بل نقدم لك شريكاً يضمن لك الأفضل.';

  @override
  String get aboutRewardsTitle => 'المكاسب والتحفيز';

  @override
  String get aboutIncentiveTitle => 'نظام الحوافز المالي';

  @override
  String get aboutIncentiveDesc =>
      'ارتقِ في نظام المستويات الخاص بنا (Bronze, Silver, Gold, Platinum). كلما أكملت المزيد من الطلبات وحافظت على تقييم عالٍ (4.8+ في Platinum)، زادت نسبة البونص التي تحصل عليها (تصل إلى 15% بونص).';

  @override
  String get aboutEarningsTitle => 'أرباح شهرية شفافة';

  @override
  String get aboutEarningsDesc =>
      'تابع أرباحك الشهرية المكتسبة واطلب صرف مستحقاتك بسهولة عبر زر \"Request Payout\".';

  @override
  String get aboutSupportTitle => 'الكفاءة والدعم';

  @override
  String get aboutFlexibilityTitle => 'مرونة العمل الكاملة';

  @override
  String get aboutFlexibilityDesc =>
      'أنت من يحدد أوقات العمل والمناطق التي تغطيها. نعمل على توفير الطلبات لك بناءً على تفضيلاتك.';

  @override
  String get aboutNoHuntingTitle => 'تجنب البحث';

  @override
  String get aboutNoHuntingDesc =>
      'قل وداعاً للبحث عن العملاء. نحن نوفر لك طلبات عمل جاهزة من عملاء موثوقين، مما يضمن تدفقاً مستمراً للعمل.';

  @override
  String get aboutTransparencyTitle => 'ضمان الشفافية';

  @override
  String get aboutTransparencyDesc =>
      'يتم توثيق جميع تفاصيل الخدمة والأسعار مسبقاً، مما يضمن وضوح التعاملات المالية بينك وبين العميل.';

  @override
  String locationNumber(int number) {
    return 'موقع $number';
  }

  @override
  String get selectedLocation => 'الموقع المختار';

  @override
  String get mapPickerInstructions =>
      '• انقر على \'إضافة منطقة\' لبدء رسم منطقة جديدة\n• اضغط على الخريطة لإضافة نقاط الحدود (مطلوب 4 نقاط على الأقل)\n• انقر على \'إكمال المنطقة\' عند الانتهاء\n• أدخل تفاصيل الموقع وقم بالتأكيد\n• استخدم أيقونة التعديل لتحديث التفاصيل أو علامة X الحمراء لإزالة منطقة';

  @override
  String get tapOnMapToDrawPolygonPoints => 'اضغط على الخريطة لرسم نقاط المضلع';

  @override
  String get addRegion => 'إضافة منطقة';

  @override
  String get regionMustHaveAtLeast4Points =>
      'يجب أن تحتوي المنطقة على 4 نقاط على الأقل لتكتمل.';

  @override
  String completeRegionWithPts(int count) {
    return 'إكمال المنطقة ($count نقاط)';
  }

  @override
  String get clearDrawing => 'مسح الرسم';

  @override
  String get pleaseDrawPolygonFirst => 'يرجى رسم مضلع أولاً';

  @override
  String get pleaseDrawPolygonAreaFirst =>
      'يرجى رسم منطقة مضلعة على الخريطة أولاً';

  @override
  String get priority => 'الأولوية';

  @override
  String get enterPriority => 'أدخل الأولوية';

  @override
  String get pleaseEnterPriority => 'يرجى إدخال الأولوية';

  @override
  String pointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نقاط',
      one: 'نقطة واحدة',
    );
    return '$_temp0';
  }

  @override
  String locationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مواقع مختارة',
      one: 'موقع واحد مختار',
    );
    return '$_temp0';
  }

  @override
  String get addCurrentLocation => 'إضافة الموقع الحالي';

  @override
  String get howToUse => 'كيفية الاستخدام';

  @override
  String get searchForAPlace => 'بحث عن مكان';

  @override
  String get myLocation => 'موقعي';

  @override
  String get noLocationSelected => 'لم يتم اختيار موقع';

  @override
  String get tapOnMapToSelect => 'اضغط على الخريطة للاختيار';

  @override
  String get confirmLocations => 'تأكيد المواقع';

  @override
  String get radius => 'نصف القطر';

  @override
  String get locationAlreadyAdded => 'الموقع مضاف بالفعل';

  @override
  String get locationAddedToList => 'تم إضافة الموقع إلى القائمة';

  @override
  String get pleaseEnableLocationServices => 'يرجى تفعيل خدمات الموقع';

  @override
  String get locationNotFound => 'لم يتم العثور على الموقع';

  @override
  String get errorFindingLocation => 'خطأ في البحث عن الموقع';

  @override
  String get editLocation => 'تعديل الموقع';

  @override
  String get addLocation => 'إضافة الموقع';

  @override
  String get englishName => 'الاسم بالإنجليزية';

  @override
  String get pleaseEnterEnglishName => 'يرجى إدخال الاسم بالإنجليزية';

  @override
  String get arabicName => 'الاسم بالعربية';

  @override
  String get pleaseEnterArabicName => 'يرجى إدخال الاسم بالعربية';

  @override
  String get pleaseEnterArabicNameOnly => 'يرجى إدخال الاسم بالعربية فقط';

  @override
  String get radiusInMeters => 'نصف القطر بالأمتار';

  @override
  String get enterRadiusInMeters => 'أدخل نصف القطر بالأمتار';

  @override
  String get meters => 'أمتار';

  @override
  String get pleaseEnterRadius => 'يرجى إدخال نصف القطر';

  @override
  String get addArea => 'إضافة منطقة';

  @override
  String get gettingAddress => 'جاري الحصول على العنوان...';

  @override
  String get serviceRadius => 'نصف قطر الخدمة';

  @override
  String get km => 'كم';

  @override
  String get tapOnMapOrSearchToAddLocations =>
      'اضغط على الخريطة أو ابحث لإضافة مواقع';

  @override
  String get selectedLocations => 'المواقع المختارة';

  @override
  String get profileSentForVerification => 'لقد تم إرسال ملفك الشخصي للتحقق!';

  @override
  String get verificationPending => 'في انتظار التوثيق';

  @override
  String get waitingForTechnicianVerification =>
      'في انتظار تحقق الفني من الدفع';

  @override
  String get verifyPayment => 'التحقق من الدفع';

  @override
  String get confirmPaymentReceipt => 'تأكيد استلام الدفع';

  @override
  String get uploadTechnicianPaymentProof => 'رفع إثبات استلام الدفع';

  @override
  String get paymentVerifiedSuccessfully => 'تم التحقق من الدفع بنجاح';

  @override
  String get selectFiles => 'اختر الملفات';

  @override
  String get pleaseSelectAtLeastOneFile => 'يرجى اختيار ملف واحد على الأقل';

  @override
  String get errorUploading => 'خطأ أثناء الرفع';

  @override
  String get warranty => 'ضمان';

  @override
  String get warrantyAppliedOn => 'تم تطبيق الضمان في';

  @override
  String get bookingIdCopied => 'تم نسخ رقم الحجز';

  @override
  String get selectTime => 'اختر الوقت';

  @override
  String get submitCounterOffer => 'قدم عرض مضاد';

  @override
  String get pleaseSelectALaterTime => 'يرجى اختيار وقت لاحق';

  @override
  String get listeningForSms => 'بانتظار الرسائل القصيرة...';

  @override
  String get earningsInfoOnly => 'لأغراض إعلامية فقط';

  @override
  String get throughApp => 'عبر التطبيق';

  @override
  String get rebookTechnician => 'إعادة حجز الفني';

  @override
  String get selectService => 'اختر الخدمة';

  @override
  String get rejectionProfessionalMessage =>
      'هل أنت غير متاح حالياً لهذا الموعد؟ بدلاً من الرفض، يمكنك اقتراح وقت أكثر ملاءمة للعميل.';

  @override
  String get proposeAlternativeTime => 'اقتراح وقت بديل';

  @override
  String get areYouSure => 'هل أنت متأكد؟';

  @override
  String get notes => 'ملاحظات';

  @override
  String get time => 'الوقت';

  @override
  String get appointmentDetails => 'تفاصيل الموعد';
}
