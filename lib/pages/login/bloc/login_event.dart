part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

class SendOTPPressed extends LoginEvent {
  final String phoneNumber;
  final BuildContext context;

  SendOTPPressed({
    required this.phoneNumber,
    required this.context,
  });

  @override
  String toString() => 'SendOTPPressed { phoneNumber: $phoneNumber }';
}

class VerifyOTPPressed extends LoginEvent {
  final String verificationId;
  final String smsCode;
  final String phoneNumber;
  final BuildContext context;

  VerifyOTPPressed({
    required this.verificationId,
    required this.smsCode,
    required this.phoneNumber,
    required this.context,
  });

  @override
  String toString() =>
      'VerifyOTPPressed { verificationId: $verificationId, phoneNumber: $phoneNumber }';
}

class VerifyOTPForRegistration extends LoginEvent {
  final String verificationId;
  final String smsCode;
  final String phoneNumber;
  final BuildContext context;

  VerifyOTPForRegistration({
    required this.verificationId,
    required this.smsCode,
    required this.phoneNumber,
    required this.context,
  });

  @override
  String toString() =>
      'VerifyOTPForRegistration { phoneNumber: $phoneNumber }';
}

class RememberMeToggled extends LoginEvent {
  final bool value;
  final String? phone;

  RememberMeToggled(this.value, {this.phone});

  @override
  String toString() => 'RememberMeToggled { value: $value, phone: $phone }';
}

class LoadWorkerData extends LoginEvent {
  final String? uid;

  LoadWorkerData({this.uid});

  @override
  List<Object?> get props => [uid];
}

class RefreshUserData extends LoginEvent {
  final String? uid;

  RefreshUserData({this.uid});

  @override
  List<Object?> get props => [uid];
}

class RegisterButtonPressed extends LoginEvent {
  final String phoneNumber;

  RegisterButtonPressed({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}
