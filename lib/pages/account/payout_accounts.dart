import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
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
      backgroundColor: AppColors.bgWhite,
      appBar: _buildAppBar(localizations, colorScheme),
      body: Column(
        children: [
          _buildHeader(localizations, theme, colorScheme),
          Expanded(child: _buildAccountsList(colorScheme)),
        ],
      ),
      floatingActionButton: _buildFAB(localizations),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AppLocalizations localizations,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      title: Text(
        localizations.payoutAccounts,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.primary,
    );
  }

  Widget _buildHeader(
    AppLocalizations localizations,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 2),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          localizations.addAndManageYourPayoutAccounts,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      icon: const Icon(Icons.add_rounded),
      label: Text(localizations.addAccount),
      elevation: 2,
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
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgWhite,
        actionsAlignment: MainAxisAlignment.start,
        icon: Icon(
          Icons.delete_outline_rounded,
          size: 48,
          color: colorScheme.error,
        ),
        title: Text(localizations.deleteAccount),
        content: Text(localizations.deleteAccountConfirmation),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          eButton(
            onPressed: () => Navigator.pop(context, false),
            text: localizations.cancel,
            context: context,
            textColor: Colors.white,
            backgroundColor: colorScheme.primary,
          ),
          eButton(
            onPressed: () => Navigator.pop(context, true),
            text: localizations.delete,
            context: context,
            textColor: Colors.white,
            backgroundColor: colorScheme.error,
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noPayoutAccountsAdded,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.addAnAccountToReceivePayments,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddAccount,
              icon: const Icon(Icons.add_rounded),
              label: Text(localizations.addFirstAccount),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
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
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.error ?? 'Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
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

    return Card.filled(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: account.isPrimary
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: account.isPrimary ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, colorScheme, localizations),
              const SizedBox(height: 20),
              _buildDetailsSection(context, colorScheme, localizations),
              const SizedBox(height: 16),
              _buildActionButtons(context, colorScheme, localizations),
            ],
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: account.isPrimary
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            color: account.isPrimary
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            size: 24,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _AccountDetailRow(
            icon: Icons.numbers_rounded,
            label: localizations.accountNumber,
            value: _maskAccountNumber(account.accountNumber ?? ''),
          ),
          const SizedBox(height: 12),
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
            child: OutlinedButton.icon(
              onPressed: onSetPrimary,
              icon: const Icon(Icons.star_outline_rounded, size: 18),
              label: Text(localizations.setPrimary),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(localizations.edit),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
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
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(context, colorScheme, localizations),
            _buildDialogForm(context, colorScheme, localizations),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEdit ? Icons.edit_rounded : Icons.add_rounded,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? localizations.editAccount : localizations.addAccount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEdit
                      ? localizations.updateAccountDetails
                      : localizations.enterAccountDetails,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
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
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
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
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPrimary ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: CheckboxListTile(
        value: _isPrimary,
        onChanged: (value) => setState(() => _isPrimary = value ?? false),
        title: Row(
          children: [
            Icon(
              Icons.star_rounded,
              size: 20,
              color: _isPrimary
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              localizations.setAsPrimaryAccount,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(localizations.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _isLoading ? null : _saveAccount,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 35,
                    child: Loader(size: 16, color: colorScheme.onPrimary),
                  )
                : Text(
                    isEdit
                        ? localizations.updateAccount
                        : localizations.addAccount,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
