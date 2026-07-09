import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CounterProposeSheet extends StatefulWidget {
  final BookingModel? booking;
  final String? requestId;
  final String? offerId;
  final String? customerId;
  final DateTime currentBookingTime;

  const CounterProposeSheet({
    super.key,
    this.booking,
    this.requestId,
    this.offerId,
    this.customerId,
    required this.currentBookingTime,
  });

  @override
  State<CounterProposeSheet> createState() => _CounterProposeSheetState();
}

class _CounterProposeSheetState extends State<CounterProposeSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    
    // Start with now + 30 mins
    DateTime baseTime = now.add(const Duration(minutes: 30));

    _selectedDate = baseTime;
    
    // Round to next 30 min interval
    int minutes = baseTime.minute;
    int hour = baseTime.hour;
    
    if (minutes > 0 && minutes <= 30) {
      minutes = 30;
    } else if (minutes > 30) {
      minutes = 0;
      hour += 1;
    } else {
      minutes = 0;
    }
    
    // Ensure it's within 6 AM - 10 PM
    if (hour < 6) hour = 6;
    if (hour > 22 || (hour == 22 && minutes > 0)) {
      hour = 6;
      minutes = 0;
      _selectedDate = baseTime.add(const Duration(days: 1));
    }
    
    _selectedTime = TimeOfDay(hour: hour, minute: minutes);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: widget.currentBookingTime.isAfter(DateTime.now()) 
          ? widget.currentBookingTime 
          : DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  List<TimeOfDay> _generateTimeSlots() {
    List<TimeOfDay> slots = [];
    for (int hour = 6; hour <= 22; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour < 22) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
    return slots;
  }

  Future<void> _pickTime() async {
    final slots = _generateTimeSlots();
    
    final TimeOfDay? picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.selectTime,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isSelected = _selectedTime?.hour == slot.hour && 
                                     _selectedTime?.minute == slot.minute;
                    
                    // Check if slot is valid (after now and before original booking time)
                    final bookingDate = widget.currentBookingTime;
                    final now = DateTime.now();
                    final selectedSlotDateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      slot.hour,
                      slot.minute,
                    );
                    
                    final isValid = selectedSlotDateTime.isAfter(now) && 
                                    selectedSlotDateTime.isBefore(bookingDate);
                    
                    return InkWell(
                      onTap: isValid ? () => Navigator.pop(context, slot) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primary 
                              : (isValid ? Colors.grey[50] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.primary 
                                : (isValid ? Colors.grey[200]! : Colors.grey[200]!.withOpacity(0.5)),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot.format(context),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected 
                                ? Colors.white 
                                : (isValid ? Colors.black87 : Colors.grey[400]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final originalDateTime = widget.currentBookingTime;
    final now = DateTime.now();

    if (!selectedDateTime.isAfter(now) || !selectedDateTime.isBefore(originalDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a valid time between now and original booking time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final bool success = await AppServices.sendCounterOffer(
      bookingId: widget.booking?.id ?? widget.requestId ?? '',
      offerId: widget.offerId,
      proposedBy: 'technician',
      proposedByUid: LocalStore.getUID() ?? '',
      proposedByName: LocalStore.getCachedUserData()?.name ?? 'Technician',
      proposedTime: Timestamp.fromDate(selectedDateTime),
      customerId: widget.booking?.customer.uid ?? widget.customerId ?? '',
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.counterOfferSent),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToSendCounter ?? 'Failed to send counter offer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = _selectedDate == null 
        ? l10n.selectDate 
        : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);
    final timeStr = _selectedTime == null 
        ? l10n.selectTime 
        : _selectedTime!.format(context);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            l10n.proposeNewTime,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (AppLocalizations.of(context)?.selectNewDateAppointment ?? 'Select a new date and time for the appointment'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Date Selector
          _buildPickerRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: dateStr,
            onTap: _pickDate,
          ),
          
          const SizedBox(height: 16),
          
          // Time Selector
          _buildPickerRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: timeStr,
            onTap: _pickTime,
          ),
          
          const SizedBox(height: 40),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      l10n.submitCounterOffer,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
