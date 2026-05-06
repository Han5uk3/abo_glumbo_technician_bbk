import 'dart:io';

import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/main.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingTrackerService tracker;
  BookingBloc(this.tracker) : super(BookingInitial()) {
    on<CancelBooking>(_cancelBookingWorker);
    on<CompleteBooking>(_completeBookingWorker);
    on<StartWorkingOnBooking>(_startBookingWorker);
    on<StopWorkingOnBooking>(_stopWorkingOnBookingWorker);
    on<PauseWorkingOnBooking>(_pauseWorkingOnBookingWorker);
  }

  Future<void> _cancelBookingWorker(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingCancelLoading());
    try {
      bool isSuccess = await AppServices.cancelBooking(
        event.bookingId,
        agentUid: event.agentUid,
        agentName: event.agentName,
      );
      if (isSuccess) {
        emit(BookingCancelSuccess());
      } else {
        emit(BookingCancelFailure(error: "Failed to cancel booking"));
      }
    } catch (e) {
      emit(BookingCancelFailure(error: e.toString()));
    }
  }

  Future<void> _completeBookingWorker(
    CompleteBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingCompleteLoading());
    try {
      // Step 1: Upload files (images and documents) to Firebase Storage
      List<String> fileUrls = [];
      for (int i = 0; i < event.selectedFiles.length; i++) {
        String fileUrl = await _uploadFileToStorage(
          event.selectedFiles[i],
          '${event.bookingId}_file_$i', // Unique name for each file
        );
        fileUrls.add(fileUrl);
      }

      // Step 2: Prepare service items data
      List<Map<String, dynamic>> serviceItemsData = event.serviceItems
          .map((item) => item.toMap())
          .toList();

      // Step 4: Update booking status using existing service
      bool isSuccess = await AppServices.completeBooking(
        bookingId: event.bookingId,
        technicianId: event.technicianId,
        mode: event.mode,
        fileUrls: fileUrls,
        serviceCost: event.serviceCost,
        serviceItems: serviceItemsData,
        totalCost: event.totalCost,
        inspectionFee: event.inspectionFee,
      );

      if (isSuccess) {
        emit(BookingCompleteSuccess());
      } else {
        emit(BookingCompleteFailure(error: "Failed to update booking status"));
      }
    } catch (e) {
      emit(BookingCompleteFailure(error: e.toString()));
    }
  }

  // Updated upload method to handle both images and documents
  Future<String> _uploadFileToStorage(File file, String fileName) async {
    try {
      // Get file extension to determine content type
      String extension = file.path.split('.').last.toLowerCase();
      String contentType;

      // Set appropriate content type
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      // Create reference with proper extension
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('booking_files')
          .child('$fileName.$extension');

      // Upload with metadata
      final metadata = SettableMetadata(contentType: contentType);

      await storageRef.putFile(file, metadata);

      // Get download URL
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Save booking completion data to Firestore

  Future<void> _startBookingWorker(
    StartWorkingOnBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingStartWorkingLoading());
    try {
      await tracker.startWorking(
        context: event.context,
        bookingId: event.bookingId,
        uid: event.uid,
      );

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
            backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
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

      emit(BookingStartWorkingSuccess());
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('PlatformException') &&
          errorMessage.contains('1')) {
        final localizations = AppLocalizations.of(event.context);
        errorMessage =
            localizations?.locationPermissionErrorIOS ??
            'Location permission error on iOS. Please enable location access in Settings.';
      }

      emit(BookingStartWorkingFailure(error: errorMessage));
    }
  }

  Future<void> _stopWorkingOnBookingWorker(
    StopWorkingOnBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingStopWorkingLoading());
    try {
      await tracker.stopTracking();
      emit(BookingStopWorkingSuccess());
    } catch (e) {
      emit(BookingStopWorkingFailure(error: e.toString()));
    }
  }

  Future<void> _pauseWorkingOnBookingWorker(
    PauseWorkingOnBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingPauseWorkingLoading());
    try {
      await tracker.pauseTracking();
      emit(BookingPauseWorkingSuccess());
    } catch (e) {
      emit(BookingPauseWorkingFailure(error: e.toString()));
    }
  }
}
