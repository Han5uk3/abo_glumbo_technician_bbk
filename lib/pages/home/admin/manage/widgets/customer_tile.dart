import "package:aboglumbo_bbk_panel/styles/color.dart";
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:flutter/material.dart';

class CustomerTileMinimal extends StatelessWidget {
  const CustomerTileMinimal({
    super.key,
    required this.customer,
    required this.isBlocked,
    this.onTap,
    this.onApprovalToggle,
  });

  final CustomerModel customer;
  final bool isBlocked;
  final VoidCallback? onTap;
  final VoidCallback? onApprovalToggle;

  Future<void> _showApprovalDialog(BuildContext context) async {
    final bool approve = isBlocked;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final TextTheme textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          actionsAlignment: MainAxisAlignment.start,
          title: Text(
            (approve
                    ? AppLocalizations.of(
                        context,
                      )?.areYouSureYouWantToUnBlockThisCustomer
                    : AppLocalizations.of(
                        context,
                      )?.areYouSureYouWantToBlockThisCustomer) ??
                (approve
                    ? "Are you sure you want to unblock this customer?"
                    : "Are you sure you want to block this customer?"),
            style: textTheme.titleMedium,
          ),
          content: Text(
            "${AppLocalizations.of(context)?.customer ?? 'Customer'}: ${customer.name ?? 'No Name'}\n${AppLocalizations.of(context)?.email ?? 'Email'}: ${customer.email ?? 'No Email'}",
            style: textTheme.bodyMedium,
          ),
          actions: [
            eButton(
              text: "",
              onPressed: () {
                Navigator.pop(context, false);
              },
              widget: Text(AppLocalizations.of(context)?.cancel ?? "Cancel"),
              context: context,
              textColor: Colors.black,
              backgroundColor: AppColors.bgWhite,
            ),
            eButton(
              text: "",
              onPressed: () {
                Navigator.pop(context, true);
              },
              widget: Text(AppLocalizations.of(context)?.yesText ?? "Yes"),
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.green,
            ),
          ],
        );
      },
    );

    // If user confirmed, execute the original callback
    if (result == true && onApprovalToggle != null) {
      onApprovalToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isBlocked
              ? Colors.red.withOpacity(0.1)
              : Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          isBlocked ? Icons.shield : Icons.verified_user,
          color: isBlocked ? Colors.red.shade800 : Colors.green,
        ),
      ),
      title: Text(
        customer.name ?? 'No Name',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.email ?? 'No Email',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isBlocked
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isBlocked
                  ? AppLocalizations.of(context)?.blocked ?? 'Blocked'
                  : AppLocalizations.of(context)?.active ?? 'Active',
              style: TextStyle(
                color: isBlocked ? Colors.red.shade800 : Colors.green.shade800,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      onTap: onTap,
      trailing: IconButton(
        onPressed: () => _showApprovalDialog(context),
        icon: Icon(
          isBlocked ? Icons.approval : Icons.block,
          color: isBlocked
              ? Theme.of(context).primaryColor
              : Colors.red.shade600,
        ),
        tooltip: isBlocked
            ? AppLocalizations.of(context)?.unBlockCustomer
            : AppLocalizations.of(context)?.blockCustomer,
      ),
      isThreeLine: true,
    );
  }
}
