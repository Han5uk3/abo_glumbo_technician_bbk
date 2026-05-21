import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:aboglumbo_bbk_panel/services/auth_services.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthServices _authServices = AuthServices();

  LoginBloc() : super(LoginInitial()) {
    on<SendOTPPressed>(_sendOTPWorker);
    on<VerifyOTPPressed>(_verifyOTPWorker);
    on<VerifyOTPForRegistration>(_verifyOTPForRegistration);
    on<RememberMeToggled>(_rememberMeToggled);
    on<LoadWorkerData>(_loadWorkerData);
    on<RefreshUserData>(_refreshUserData);
    on<RegisterButtonPressed>(_registerWorker);
  }

  // ✅ FIXED: Use Completer for proper async callback handling
  Future<void> _sendOTPWorker(
    SendOTPPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      // ✅ Use Completer to properly wait for callbacks
      final Completer<Map<String, dynamic>> completer = Completer();

      await _authServices.sendOTP(
        event.context,
        phoneNumber: event.phoneNumber,
        onCodeSent: (String verificationId, {int? resendToken}) {
          if (!completer.isCompleted) {
            if (kDebugMode) {
              print('✅ OTP sent successfully. VerificationId: $verificationId');
            }
            completer.complete({
              'success': true,
              'verificationId': verificationId,
              'resendToken': resendToken,
            });
          }
        },
        onError: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            if (kDebugMode) {
              print('❌ OTP send failed: ${e.code} - ${e.message}');
            }
            completer.complete({'success': false, 'error': e.code});
          }
        },
      );

      // ✅ Wait for the callback to complete (with 120 second timeout for iOS reCAPTCHA)
      final result = await completer.future.timeout(
        Duration(seconds: Platform.isIOS ? 120 : 30),
        onTimeout: () => {'success': false, 'error': 'timeout'},
      );

      if (result['success'] == true) {
        emit(
          OTPSentSuccess(
            verificationId: result['verificationId'] as String,
            resendToken: result['resendToken'] as int?,
          ),
        );
      } else {
        emit(
          OTPSentFailure(
            error: result['error'] as String? ?? 'Failed to send OTP',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Send OTP error: $e');
      }
      emit(OTPSentFailure(error: e.toString()));
    }
  }

  Future<void> _verifyOTPWorker(
    VerifyOTPPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      UserCredential? userCredential = await _authServices.verifyOTP(
        event.context,
        event.smsCode,
        verificationId: event.verificationId,
        smsCode: event.smsCode,
        phoneNumber: event.phoneNumber,
      );

      if (userCredential != null && userCredential.user != null) {
        if (kDebugMode) {
          print('✅ OTP verified. UID: ${userCredential.user!.uid}');
        }

        // Check if user exists in WORKERS collection with role "technician"
        UserModel? user = await _checkWorkerUser(userCredential.user!.uid);

        // If user not found as technician, check admin by UID
        if (user == null || (user.name == null || user.name!.isEmpty)) {
          UserModel? admin = await _checkAdminUser(userCredential.user!.uid);
          if (admin != null) {
            user = admin;
          }
        }

        // If still not found, check admins collection by phone number
        if (user == null || (user.name == null || user.name!.isEmpty)) {
          final phone = userCredential.user!.phoneNumber;
          if (phone != null && phone.isNotEmpty) {
            UserModel? adminByPhone = await _checkAdminByPhone(
              userCredential.user!.uid,
              phone,
            );
            if (adminByPhone != null) {
              user = adminByPhone;
            }
          }
        }

        // If still not found, check users collection by phone (prevents duplicate accounts)
        if (user == null || (user.name == null || user.name!.isEmpty)) {
          final phone = userCredential.user!.phoneNumber;
          if (phone != null && phone.isNotEmpty) {
            UserModel? techByPhone = await _checkWorkerByPhone(
              userCredential.user!.uid,
              phone,
            );
            if (techByPhone != null) {
              user = techByPhone;
            }
          }
        }

        if (user != null && (user.name != null && user.name!.isNotEmpty)) {
          // Update FCM token AFTER identifying correctly
          _updateToken(user);
          emit(LoginSuccess(user: user));
        } else {
          if (kDebugMode) {
            print('📝 User not found in any collection — redirecting to signup');
          }
          // No account found → redirect to create account page
          emit(OTPVerifiedForRegistration(uid: userCredential.user!.uid));
        }
      } else {
        if (kDebugMode) {
          print('❌ OTP verification returned null');
        }
        emit(LoginFailure(error: "invalid-verification-code"));
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth error: ${e.code}');
      }
      emit(LoginFailure(error: e.code));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Verify OTP error: $e');
      }
      emit(LoginFailure(error: e.toString()));
    }
  }

  Future<void> _verifyOTPForRegistration(
    VerifyOTPForRegistration event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      UserCredential? userCredential = await _authServices.verifyOTP(
        event.context,
        event.smsCode,
        verificationId: event.verificationId,
        smsCode: event.smsCode,
        phoneNumber: event.phoneNumber,
      );

      if (userCredential != null && userCredential.user != null) {
        final uid = userCredential.user!.uid;

        if (kDebugMode) {
          print('✅ OTP verified for registration. UID: $uid');
        }

        // Emit state with UID to navigate to signup
        emit(OTPVerifiedForRegistration(uid: uid));
      } else {
        if (kDebugMode) {
          print('❌ OTP verification returned null');
        }
        emit(LoginFailure(error: "invalid-verification-code"));
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth error: ${e.code}');
      }
      emit(LoginFailure(error: e.code));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Verify OTP error: $e');
      }
      emit(LoginFailure(error: e.toString()));
    }
  }

  Future<void> _rememberMeToggled(
    RememberMeToggled event,
    Emitter<LoginState> emit,
  ) async {
    if (kDebugMode) {
      print('RememberMeToggled - value: ${event.value}');
    }

    if (event.value) {
      await LocalStore.putRememberMe(true);
      if (event.phone != null && event.phone!.isNotEmpty) {
        await LocalStore.rememberPhone(event.phone!);
        if (kDebugMode) {
          print('Saved phone to local storage');
        }
      }
    } else {
      await LocalStore.putRememberMe(false);
      await LocalStore.clearRememberedPhone();
      if (kDebugMode) {
        print('Remember me disabled, cleared phone');
      }
    }
    emit(LoginRememberMeToggled(event.value));
  }

  Future<void> _loadWorkerData(
    LoadWorkerData event,
    Emitter<LoginState> emit,
  ) async {
    try {
      final uid = event.uid ?? LocalStore.getUID()!;
      UserModel? user = await _checkWorkerUser(uid);
      
      // If user not found in workers OR they have no name (possible placeholder doc), 
      // check if they are an admin
      if (user == null || (user.name == null || user.name!.isEmpty)) {
        UserModel? admin = await _checkAdminUser(uid);
        if (admin != null) {
          user = admin;
        }
      }

      if (user == null || user.uid == null || user.uid!.isEmpty) {
        emit(LoginLoadWorkerDataFailure(error: "User not found"));
      } else {
        // Update FCM token AFTER identifying correctly
        _updateToken(user);
        emit(LoginLoadWorkerData(user: user));
      }
    } catch (e) {
      emit(LoginLoadWorkerDataFailure(error: e.toString()));
    }
  }

  Future<void> _refreshUserData(
    RefreshUserData event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // Always fetch fresh data from Firebase for refresh events
      final uid = event.uid ?? LocalStore.getUID()!;
      UserModel? user = await _checkWorkerUser(uid);

      if (user == null || (user.name == null || user.name!.isEmpty)) {
        UserModel? admin = await _checkAdminUser(uid);
        if (admin != null) {
          user = admin;
        }
      }

      if (user == null || user.uid == null || user.uid!.isEmpty) {
        emit(LoginLoadWorkerDataFailure(error: "User not found"));
      } else {
        // Update FCM token AFTER identifying correctly
        _updateToken(user);
        emit(LoginLoadWorkerData(user: user));
      }
    } catch (e) {
      emit(LoginLoadWorkerDataFailure(error: e.toString()));
    }
  }

  Future<void> _registerWorker(
    RegisterButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(RegistrationLoading());
    try {
      // Check if phone is already registered as worker
      bool phoneExists = await _isPhoneRegisteredAsWorker(event.phoneNumber);

      if (!phoneExists) {
        emit(RegisterSuccess(isSuccess: true));
      } else {
        emit(RegisterSuccess(isSuccess: false));
      }
    } catch (e) {
      emit(RegisterFailure(error: e.toString()));
    }
  }

  // Helper method: Check if user exists in workers collection with role "technician"
  Future<UserModel?> _checkWorkerUser(String uid) async {
    try {
      final userDoc = await AppFirestore.usersCollectionRef.doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final data = userData ?? {};
        if (data['uid'] == null) {
          data['uid'] = uid;
        }

        final user = UserModel.fromJson(data);
        final userRole = user.role.toLowerCase();

        // Only accept users with role "technician"
        if (userRole != 'technician') {
          if (kDebugMode) {
            print('❌ User found but role is "$userRole", not "technician". Skipping.');
          }
          return null;
        }

        LocalStore.putUID(userData?['uid'] ?? uid);
        LocalStore.putlogoutStatus(false);

        if (kDebugMode) {
          print('✅ Worker user found with role "technician": ${userData?['name']}');
        }

        // Caching for local access
        LocalStore.storeUserData(user);
        
        return user;
      } else {
        if (kDebugMode) {
          print('❌ Worker user not found in users collection');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching worker user: $e');
      }
      return null;
    }
  }

  // Helper method: Check if user exists in admins collection
  Future<UserModel?> _checkAdminUser(String uid) async {
    try {
      final adminDoc = await AppFirestore.adminsCollectionRef.doc(uid).get();

      if (adminDoc.exists) {
        final adminData = adminDoc.data() as Map<String, dynamic>?;
        
        // Map AdminModel fields to UserModel structure for Home compatibility
        final user = UserModel(
          uid: uid,
          name: adminData?['name'] ?? 'Admin',
          email: adminData?['email'],
          phone: adminData?['phoneNumber'],
          isAdmin: true,
          isVerified: true,
          role: 'admin',
          adminAccessLevel: adminData?['accessLevel'],
          createdAt: adminData?['createdAt'],
        );

        LocalStore.putUID(uid);
        LocalStore.putlogoutStatus(false);
        
        if (kDebugMode) {
          print('✅ Admin user found: ${user.name}');
        }

        // Store both in local storage
        LocalStore.storeUserData(user);
        LocalStore.storeAdminData(AdminModel.fromJson(adminData ?? {}, id: uid));
        
        return user;
      }
      return null;
    } catch (e) {
       if (kDebugMode) {
        print('❌ Error fetching admin user: $e');
      }
      return null;
    }
  }

  // Helper method: Check if phone belongs to a technician (by phone number query)
  // Prevents duplicate accounts when Firebase Auth assigns a new UID
  Future<UserModel?> _checkWorkerByPhone(String uid, String phone) async {
    try {
      final techByPhoneQuery = await AppFirestore.usersCollectionRef
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (techByPhoneQuery.docs.isNotEmpty) {
        final oldData = techByPhoneQuery.docs.first.data() as Map<String, dynamic>;
        final oldDocId = techByPhoneQuery.docs.first.id;

        final userRole = oldData['role']?.toString().toLowerCase() ?? 'technician';
        if (userRole != 'technician') {
          if (kDebugMode) {
            print('❌ User found by phone but role is "$userRole", not "technician". Skipping.');
          }
          return null;
        }

        if (kDebugMode) {
          print('✅ Technician found by phone: $phone (old UID: $oldDocId)');
        }

        // Migrate doc to new UID
        oldData['uid'] = uid;
        oldData['updatedAt'] = Timestamp.now();
        await AppFirestore.usersCollectionRef.doc(uid).set(oldData);

        // Delete old document
        if (oldDocId != uid) {
          await AppFirestore.usersCollectionRef.doc(oldDocId).delete();
          if (kDebugMode) {
            print('🔄 Technician doc migrated from $oldDocId to $uid');
          }
        }

        final user = UserModel.fromJson(oldData);

        LocalStore.putUID(uid);
        LocalStore.putlogoutStatus(false);
        LocalStore.storeUserData(user);

        return user;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking technician by phone: $e');
      }
      return null;
    }
  }

  // Helper method: Check if phone belongs to an admin (by phone number query)
  Future<UserModel?> _checkAdminByPhone(String uid, String phone) async {
    try {
      final adminByPhoneQuery = await AppFirestore.adminsCollectionRef
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (adminByPhoneQuery.docs.isNotEmpty) {
        final adminData = adminByPhoneQuery.docs.first.data() as Map<String, dynamic>?;
        final oldDocId = adminByPhoneQuery.docs.first.id;

        if (kDebugMode) {
          print('✅ Admin found by phone: $phone, accessLevel: ${adminData?['accessLevel']}');
        }

        // Create admin model
        final adminModel = AdminModel.fromJson(adminData ?? {}, id: oldDocId);

        // If the admin doc UID differs from current UID, migrate admin doc
        if (oldDocId != uid) {
          await AppFirestore.adminsCollectionRef.doc(uid).set(
            adminModel.copyWith(uid: uid).toJson(),
          );
          await AppFirestore.adminsCollectionRef.doc(oldDocId).delete();
          if (kDebugMode) {
            print('🔄 Admin doc migrated from $oldDocId to $uid');
          }
        }

        // Map AdminModel fields to UserModel structure for Home compatibility
        final user = UserModel(
          uid: uid,
          name: adminData?['name'] ?? 'Admin',
          email: adminData?['email'],
          phone: adminData?['phoneNumber'],
          isAdmin: true,
          isVerified: true,
          role: 'admin',
          adminAccessLevel: adminData?['accessLevel'],
          createdAt: adminData?['createdAt'],
        );

        LocalStore.putUID(uid);
        LocalStore.putlogoutStatus(false);

        // Store both in local storage
        LocalStore.storeUserData(user);
        LocalStore.storeAdminData(AdminModel.fromJson(adminData ?? {}, id: uid));

        return user;
      } else {
        // If not found in active admins, check in pendingAdminsCollectionRef
        if (kDebugMode) {
          print('🔍 Checking pending admins for phone: $phone');
        }
        final pendingAdminQuery = await AppFirestore.pendingAdminsCollectionRef
            .where('phoneNumber', isEqualTo: phone)
            .limit(1)
            .get();

        if (pendingAdminQuery.docs.isNotEmpty) {
          final pendingData = pendingAdminQuery.docs.first.data() as Map<String, dynamic>;
          final pendingDocId = pendingAdminQuery.docs.first.id;

          if (kDebugMode) {
            print('✅ Pending admin found by phone: $phone, promoting to active admin');
          }

          // Create admin model using the pending data and the pending doc ID
          final pendingAdminModel = AdminModel.fromJson(pendingData, id: pendingDocId);

          // Promote to active admin: set document in admins collection keyed by user auth uid
          await AppFirestore.adminsCollectionRef.doc(uid).set(
            pendingAdminModel.copyWith(uid: uid).toJson(),
          );

          // Delete from pending collection
          await AppFirestore.pendingAdminsCollectionRef.doc(pendingDocId).delete();

          if (kDebugMode) {
            print('🔄 Pending admin $pendingDocId promoted to active admin under UID: $uid');
          }

          // Map to UserModel structure for Home compatibility
          final user = UserModel(
            uid: uid,
            name: pendingData['name'] ?? 'Admin',
            email: pendingData['email'],
            phone: pendingData['phoneNumber'],
            isAdmin: true,
            isVerified: true,
            role: 'admin',
            adminAccessLevel: pendingData['accessLevel'],
            createdAt: pendingData['createdAt'],
          );

          LocalStore.putUID(uid);
          LocalStore.putlogoutStatus(false);

          // Store both in local storage
          LocalStore.storeUserData(user);
          LocalStore.storeAdminData(AdminModel.fromJson(pendingData, id: uid));

          return user;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking admin by phone: $e');
      }
      return null;
    }
  }

  // Helper method: Check if phone is registered
  Future<bool> _isPhoneRegisteredAsWorker(String phone) async {
    try {
      final querySnapshot = await AppFirestore.usersCollectionRef
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      bool exists = querySnapshot.docs.isNotEmpty;

      if (kDebugMode) {
        print(
          exists
              ? '⚠️ Phone already registered as worker'
              : '✅ Phone available for registration',
        );
      }

      return exists;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking phone registration: $e');
      }
      return false;
    }
  }

  // Update FCM token in the correct collection after identification
  Future<void> _updateToken(UserModel user) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await AppServices.updateFCMToken(token, isAdmin: user.isAdmin ?? false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error updating FCM token: $e');
      }
    }
  }
}
