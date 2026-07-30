import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/warranty.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'warranty_event.dart';
part 'warranty_state.dart';

class WarrantyBloc extends Bloc<WarrantyEvent, WarrantyState> {
  final BookingTrackerService tracker;

  WarrantyBloc(this.tracker) : super(WarrantyInitial()) {
    on<AcceptWarranty>(_onAcceptWarranty);
    on<AssignWarrantyTechnician>(_onAssignWarrantyTechnician);
    on<RejectWarranty>(_onRejectWarranty);
    on<AdminRejectWarranty>(_onAdminRejectWarranty);
    on<CancelWarranty>(_onCancelWarranty);
    on<CompleteWarranty>(_onCompleteWarranty);
    on<StartWorkingOnWarranty>(_onStartWorkingOnWarranty);
    on<StopWorkingOnWarranty>(_onStopWorkingOnWarranty);
    on<PauseWorkingOnWarranty>(_onPauseWorkingOnWarranty);
  }

  Future<void> _onAcceptWarranty(
    AcceptWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyAcceptLoading());

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.warrantyStatusCode': 'S',
        'warranty.acceptedAt': Timestamp.now(),
        'warranty.updatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      emit(WarrantyAcceptSuccess());
    } catch (e) {
      emit(WarrantyAcceptFailure(e.toString()));
    }
  }

  Future<void> _onRejectWarranty(
    RejectWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyRejectLoading());

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.assignedTechnician': FieldValue.delete(),
        'warranty.assignedTechnicianId': FieldValue.delete(),
        'warranty.rejectedAt': Timestamp.now(),
        'warranty.updatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        // Clear chatroom when rejecting warranty
        'chatroomId': FieldValue.delete(),
      });

      emit(WarrantyRejectSuccess());
    } catch (e) {
      emit(WarrantyRejectFailure(e.toString()));
    }
  }

  Future<void> _onAdminRejectWarranty(
    AdminRejectWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyRejectLoading());

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.assignedTechnician': FieldValue.delete(),
        'warranty.assignedTechnicianId': FieldValue.delete(),
        'warranty.warrantyStatusCode': 'X',
        'warranty.availability': false,
        'warranty.rejectedAt': Timestamp.now(),
        'warranty.updatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        // Clear chatroom when rejecting warranty
        'chatroomId': FieldValue.delete(),
      });

      emit(WarrantyRejectSuccess());
    } catch (e) {
      emit(WarrantyRejectFailure(e.toString()));
    }
  }

  Future<void> _onCancelWarranty(
    CancelWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyCancelLoading());

      final bookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(event.bookingId)
          .get();

      final booking = BookingModel.fromDocumentSnapshot(bookingDoc);
      final rejectedTechs = booking.warranty?.rejectedTechnicians ?? [];

      rejectedTechs.add(
        RejectedTechnicianModel(
          uid: event.technicianUid,
          name: event.technicianName,
          phone: event.technicianPhone,
          reason: event.rejectionReason,
          rejectedAt: Timestamp.now(),
        ),
      );

      final rejectedTechsList = rejectedTechs.map((e) => e.toJson()).toList();

      // Check if warranty period is still valid
      final expiredOn = booking.warranty?.expiredOn;
      final isWarrantyExpired =
          expiredOn != null && expiredOn.toDate().isBefore(DateTime.now());

      if (isWarrantyExpired) {
        // Warranty has expired — close the claim
        await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
          'warranty.assignedTechnician': FieldValue.delete(),
          'warranty.assignedTechnicianId': FieldValue.delete(),
          'warranty.warrantyStatusCode': 'E',
          'warranty.availability': false,
          'warranty.rejectedTechnicians': rejectedTechsList,
          'warranty.updatedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'chatroomId': FieldValue.delete(),
        });
        emit(WarrantyCancelSuccess());
        return;
      }

      // Warranty is still valid — set back to Requested for admin
      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.assignedTechnician': FieldValue.delete(),
        'warranty.assignedTechnicianId': FieldValue.delete(),
        'warranty.warrantyStatusCode': 'R',
        'warranty.availability': true,
        'warranty.rejectedTechnicians': rejectedTechsList,
        'warranty.updatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'chatroomId': FieldValue.delete(),
      });

      emit(WarrantyCancelSuccess());
    } catch (e) {
      emit(WarrantyCancelFailure(error: e.toString()));
    }
  }

  Future<void> _onCompleteWarranty(
    CompleteWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyCompleteLoading());

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.warrantyStatusCode': 'C',
        'warranty.availability': false,
        // The claim is resolved, so this no longer counts as an active claim
        // in progress — clears the flag that keeps the Directions button
        // showing on the technician app's completed warranty card.
        'warranty.claimrequested': false,
        'warranty.completedAt': Timestamp.now(),
        'warranty.updatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        // Zero-fee enforcement for warranty repairs
        'warranty.totalCost': 0,
        'warranty.serviceCost': 0,
        'warranty.inspectionFee': 0,
      });

      emit(WarrantyCompleteSuccess());
    } catch (e) {
      emit(WarrantyCompleteFailure(error: e.toString()));
    }
  }

  Future<void> _onStartWorkingOnWarranty(
    StartWorkingOnWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    emit(WarrantyStartWorkingLoading());
    try {
      await tracker.startWorkingWarranty(
        context: event.context,
        bookingId: event.bookingId,
        uid: event.uid,
      );

      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.warrantyStatusCode': 'S',
        'warranty.updatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Configure background fetch with error handling
      try {
        await BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            startOnBoot: true,
            enableHeadless: true,
          ),
          (String taskId) async {
            // Background fetch callback
            BackgroundFetch.finish(taskId);
          },
          (String taskId) {
            BackgroundFetch.finish(taskId);
          },
        );
      } catch (backgroundFetchError) {
        if (kDebugMode) {
          print('Background fetch configuration failed: $backgroundFetchError');
        }
      }

      emit(WarrantyStartWorkingSuccess());
    } catch (e) {
      emit(WarrantyStartWorkingFailure(error: e.toString()));
    }
  }

  Future<void> _onAssignWarrantyTechnician(
    AssignWarrantyTechnician event,
    Emitter<WarrantyState> emit,
  ) async {
    try {
      emit(WarrantyAssignLoading());

      // Store the entire technician UserModel instead of just the UID
      await AppFirestore.bookingsCollectionRef.doc(event.bookingId).update({
        'warranty.assignedTechnician': event.technician.toJson(),
        'warranty.assignedTechnicianId': event.technician.uid,
        'warranty.warrantyStatusCode': 'R',
        'warranty.availability': false,
        // Assignment is not acceptance — the claim goes back to 'R' and waits for
        // the new technician to accept, which is what stamps `acceptedAt`. Writing
        // `acceptedAt` here used to backdate an acceptance that had not happened,
        // so the timeline showed "Warranty Repair Accepted" the moment the admin
        // assigned. Any acceptance carried over from the previous technician is
        // cleared for the same reason.
        'warranty.assignedAt': Timestamp.now(),
        'warranty.acceptedAt': FieldValue.delete(),
        'warranty.rejectedAt': FieldValue.delete(),
        'warranty.updatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        // Clear any old chatroom to ensure fresh start with new technician
        'chatroomId': FieldValue.delete(),
      });

      emit(WarrantyAssignSuccess(technician: event.technician));
    } catch (e) {
      emit(WarrantyAssignFailure(error: e.toString()));
    }
  }

  Future<void> _onStopWorkingOnWarranty(
    StopWorkingOnWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    emit(WarrantyStopWorkingLoading());
    try {
      await tracker.stopTrackingWarranty();
      emit(WarrantyStopWorkingSuccess());
    } catch (e) {
      emit(WarrantyStopWorkingFailure(error: e.toString()));
    }
  }

  Future<void> _onPauseWorkingOnWarranty(
    PauseWorkingOnWarranty event,
    Emitter<WarrantyState> emit,
  ) async {
    emit(WarrantyPauseWorkingLoading());
    try {
      await tracker.pauseTrackingWarranty();
      emit(WarrantyPauseWorkingSuccess());
    } catch (e) {
      emit(WarrantyPauseWorkingFailure(error: e.toString()));
    }
  }
}
