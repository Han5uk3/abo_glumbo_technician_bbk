import 'dart:convert';
import 'dart:io';

void main() {
  final keys = [
    'bookingDate','yourAccountIsBeingVerified','aboGlumboWorker',
    'workerCannotBeAssignedMultipleTimes','unknownWorker','workerCancelled',
    'cancelledByWorker','workerPreviouslyCancelled','workerCancelledAtTime',
    'workerRestrictedTitle','cannotAssignCancelledWorker',
    'workerCancelledRestrictionMessage','managefaqs','manageWorkers',
    'noWorkersMatchYourFilters','workerInformation','loadingWorkers',
    'serviceDeletedSuccessfully','netTechnicianror','urdu','allTime'
  ];
  final ar = json.decode(File('lib/l10n/app_ar.arb').readAsStringSync()) as Map<String,dynamic>;
  final ur = json.decode(File('lib/l10n/app_ur.arb').readAsStringSync()) as Map<String,dynamic>;
  for (final k in keys) {
    print('$k => ar:${ar[k]}, ur:${ur[k]}');
  }
}
