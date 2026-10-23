part of 'login_bloc.dart';

@immutable
sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final UserModel user;
  LoginSuccess({required this.user});
}

final class LoginFailure extends LoginState {
  final String error;
  LoginFailure({required this.error});
}

final class OTPSentSuccess extends LoginState {
  final String verificationId;
  final int? resendToken;

  OTPSentSuccess({required this.verificationId, this.resendToken});

  @override
  List<Object?> get props => [verificationId, resendToken];
}

final class OTPSentFailure extends LoginState {
  final String error;
  OTPSentFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

final class OTPVerifiedForRegistration extends LoginState {
  final String uid;

  OTPVerifiedForRegistration({required this.uid});

  @override
  List<Object?> get props => [uid];
}

/// Android verified the number by itself (instant verification): no SMS was
/// sent and there is no code to type. The user is already signed in.
final class OTPAutoVerified extends LoginState {
  final UserCredential userCredential;

  OTPAutoVerified({required this.userCredential});
}

final class LoginRememberMeToggled extends LoginState {
  final bool value;
  LoginRememberMeToggled(this.value);
}

final class LoginLoadWorkerData extends LoginState {
  final UserModel user;
  LoginLoadWorkerData({required this.user});
}

final class LoginLoadWorkerDataFailure extends LoginState {
  final String error;
  LoginLoadWorkerDataFailure({required this.error});
}

final class RegistrationLoading extends LoginState {}

final class RegisterSuccess extends LoginState {
  final bool isSuccess;
  RegisterSuccess({required this.isSuccess});

  @override
  List<Object?> get props => [isSuccess];
}

final class RegisterFailure extends LoginState {
  final String error;
  RegisterFailure({required this.error});
}
