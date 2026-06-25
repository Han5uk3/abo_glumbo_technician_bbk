import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PayoutAccountsPage extends StatefulWidget {
  const PayoutAccountsPage({super.key});

  @override
  State<PayoutAccountsPage> createState() => _PayoutAccountsPageState();
}

class _PayoutAccountsPageState extends State<PayoutAccountsPage> {
  late final String userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgBlueTint,
      appBar: _buildAppBar(localizations),
      body: Column(
        children: [
          _buildHeader(localizations),
          Expanded(child: _buildAccountsList(colorScheme)),
        ],
      ),
      floatingActionButton: _buildFAB(localizations),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations localizations) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        localizations.payoutAccounts,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              localizations.addAndManageYourPayoutAccounts,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(ColorScheme colorScheme) {
    return StreamBuilder<List<PayoutAccountModel>>(
      stream: AppServices.getPayoutAccount(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorStateWidget(error: snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Loader(size: 45, color: colorScheme.primary));
        }

        final accounts = snapshot.data ?? [];

        if (accounts.isEmpty) {
          return _EmptyStateWidget(onAddAccount: _showAddEditDialog);
        }

        return ListView.separated(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          itemCount: accounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _AccountCard(
            account: accounts[index],
            onEdit: () => _showAddEditDialog(account: accounts[index]),
            onSetPrimary: () => _setPrimaryAccount(accounts[index].id!),
            onDelete: () => _deleteAccount(accounts[index].id!),
          ),
        );
      },
    );
  }

  Widget _buildFAB(AppLocalizations localizations) {
    return FloatingActionButton.extended(
      onPressed: _showAddEditDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        localizations.addAccount,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showAddEditDialog({PayoutAccountModel? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => AddEditAccountDialog(account: account, userId: userId),
    );
  }

  Future<void> _setPrimaryAccount(String accountId) async {
    if (_isLoading) return;

    // Remove setState here - only update the loading flag
    _isLoading = true;

    try {
      await AppServices.setPrimaryPayoutAccount(
        userId: userId,
        accountId: accountId,
      );

      if (!mounted) return;
      _showSuccessSnackBar(AppLocalizations.of(context)!.primaryAccountUpdated);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) _isLoading = false; // Don't wrap in setState
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await _showDeleteConfirmation(localizations);

    if (confirmed != true || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await AppServices.deletePayoutAccount(
        userId: userId,
        accountId: accountId,
      );

      if (!mounted) return;
      _showSuccessSnackBar(localizations.accountDeletedSuccessfully);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showDeleteConfirmation(AppLocalizations localizations) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.deleteAccount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.deleteAccountConfirmation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.cancel,
                      style: TextStyle(
                        color: Colors.black38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.delete,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('${localizations?.error}: $error')),
          ],
        ),
        backgroundColor: colorScheme.error,
      ),
    );
  }
}

// Extracted to StatelessWidget for better performance
class _EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAddAccount;

  const _EmptyStateWidget({required this.onAddAccount});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations.noPayoutAccountsAdded,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.addAnAccountToReceivePayments,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: onAddAccount,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                localizations.addFirstAccount,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorStateWidget extends StatelessWidget {
  final String error;

  const _ErrorStateWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations?.error ?? 'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final PayoutAccountModel account;
  final VoidCallback onEdit;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onSetPrimary,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: account.isPrimary
            ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colorScheme, localizations),
                const SizedBox(height: 24),
                _buildDetailsSection(context, colorScheme, localizations),
                const SizedBox(height: 24),
                _buildActionButtons(context, colorScheme, localizations),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localizations,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: account.isPrimary
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.bgBlueTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            color: account.isPrimary ? AppColors.primary : Colors.black45,
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account.accountHolderName ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (account.isPrimary)
                    _PrimaryBadge(colorScheme: colorScheme),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                account.bankName ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgBlueTint.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _AccountDetailRow(
            icon: Icons.numbers_rounded,
            label: localizations.accountNumber,
            value: _maskAccountNumber(account.accountNumber ?? ''),
          ),
          const SizedBox(height: 16),
          _AccountDetailRow(
            icon: Icons.code_rounded,
            label: localizations.ifscCode,
            value: account.ifscCode ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localizations,
  ) {
    return Row(
      children: [
        if (!account.isPrimary) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onSetPrimary,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                localizations.setPrimary,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: onEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.08),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              localizations.edit,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '•••• $lastFour';
  }

  // String _capitalizeFirst(String text) {
  //   if (text.isEmpty) return text;
  //   return text[0].toUpperCase() + text.substring(1);
  // }
}

class _PrimaryBadge extends StatelessWidget {
  final ColorScheme colorScheme;

  const _PrimaryBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: colorScheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            localizations.primary,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.black45),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Dialog remains largely the same but with minor optimizations
class AddEditAccountDialog extends StatefulWidget {
  final PayoutAccountModel? account;
  final String userId;

  const AddEditAccountDialog({super.key, this.account, required this.userId});

  @override
  State<AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends State<AddEditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountHolderNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _ifscCodeController;
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accountHolderNameController = TextEditingController(
      text: widget.account?.accountHolderName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.account?.accountNumber ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.account?.bankName ?? '',
    );
    _ifscCodeController = TextEditingController(
      text: widget.account?.ifscCode ?? '',
    );
    _isPrimary = widget.account?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildDialogHeader(context, colorScheme, localizations),
            _buildDialogForm(context, colorScheme, localizations),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localizations,
  ) {
    final isEdit = widget.account != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? localizations.editAccount : localizations.addAccount,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEdit
                      ? localizations.updateAccountDetails
                      : localizations.enterAccountDetails,
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.black45),
            style: IconButton.styleFrom(backgroundColor: AppColors.bgBlueTint),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogForm(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations localizations,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _accountHolderNameController,
              label: localizations.accountHolderName,
              hint: localizations.enterAccountHolderName,
              icon: Icons.person_rounded,
              colorScheme: colorScheme,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterAccountHolderName;
                }
                if (value.length < 3) {
                  return localizations.nameMustBeAtLeast3Chars;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _accountNumberController,
              label: localizations.accountNumber,
              hint: localizations.enterAccountNumber,
              icon: Icons.account_balance_wallet_rounded,
              colorScheme: colorScheme,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterAccountNumber;
                }
                if (value.length < 9 || value.length > 18) {
                  return localizations.invalidAccountNumberLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bankNameController,
              label: localizations.bankName,
              hint: localizations.enterBankName,
              icon: Icons.account_balance_rounded,
              colorScheme: colorScheme,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterBankName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ifscCodeController,
              label: localizations.ifscCode,
              hint: localizations.enterifscCode,
              icon: Icons.tag_rounded,
              colorScheme: colorScheme,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterIfscCode;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildPrimaryCheckbox(colorScheme, localizations),
            const SizedBox(height: 32),
            _buildActionButtons(colorScheme, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppColors.primary.withOpacity(0.5),
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.bgBlueTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: TextStyle(
              color: Colors.black26,
              fontWeight: FontWeight.normal,
            ),
          ),
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }

  // DropdownMenuItem<String> _buildDropdownItem(
  //   String value,

  //   String label,
  //   ColorScheme colorScheme,
  // ) {
  //   return DropdownMenuItem(
  //     value: value,
  //     child: Row(children: [Text(label)]),
  //   );
  // }

  Widget _buildPrimaryCheckbox(
    ColorScheme colorScheme,
    AppLocalizations localizations,
  ) {
    return InkWell(
      onTap: () => setState(() => _isPrimary = !_isPrimary),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isPrimary
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.bgBlueTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPrimary
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: _isPrimary ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isPrimary ? AppColors.primary : Colors.black12,
                  width: 1.5,
                ),
              ),
              child: _isPrimary
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.setAsPrimaryAccount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isPrimary ? AppColors.primary : Colors.black54,
                ),
              ),
            ),
            Icon(
              Icons.star_rounded,
              size: 20,
              color: _isPrimary ? AppColors.primary : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    ColorScheme colorScheme,
    AppLocalizations localizations,
  ) {
    final isEdit = widget.account != null;
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              localizations.cancel,
              style: TextStyle(
                color: Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: Loader(size: 16, color: Colors.white),
                  )
                : Text(
                    isEdit
                        ? localizations.updateAccount
                        : localizations.addAccount,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.account != null;
      if (isEdit) {
        await AppServices.updatePayoutAccount(
          userId: widget.userId,
          accountId: widget.account!.id!,
          accountHolderName: _accountHolderNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          bankName: _bankNameController.text.trim(),
          ifscCode: _ifscCodeController.text.trim(),
          isPrimary: _isPrimary,
        );
      } else {
        await AppServices.addPayoutAccount(
          userId: widget.userId,
          accountHolderName: _accountHolderNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          bankName: _bankNameController.text.trim(),
          ifscCode: _ifscCodeController.text.trim(),

          isPrimary: _isPrimary,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);

      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEdit
                      ? localizations.accountUpdatedSuccessfully
                      : localizations.accountAddedSuccessfully,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('${localizations?.error}: $e')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
