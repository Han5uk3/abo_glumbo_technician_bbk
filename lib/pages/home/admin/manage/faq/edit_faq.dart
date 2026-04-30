import "package:aboglumbo_bbk_panel/styles/color.dart";
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/faq.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddFaqPage extends StatefulWidget {
  final bool isEdit;
  final FaqModel? faq;
  const AddFaqPage({super.key, required this.isEdit, this.faq});

  @override
  State<AddFaqPage> createState() => _AddFaqPageState();
}

class _AddFaqPageState extends State<AddFaqPage> {
  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.faq != null) {
      id = widget.faq!.id;
      _questionEnController.text = widget.faq!.questionEn;
      _answerEnController.text = widget.faq!.answerEn;
      _questionOtherController.text = widget.faq!.questionAr;
      _answerOtherController.text = widget.faq!.answerAr;
      standController.text = widget.faq!.stand.toString();
      stand = widget.faq!.stand;
    }
  }

  final _formKey = GlobalKey<FormState>();
  int? stand = 0;
  String? id;

  bool _isDialogShowing = false;

  final TextEditingController _questionEnController = TextEditingController();
  final TextEditingController _answerEnController = TextEditingController();
  final TextEditingController _questionOtherController =
      TextEditingController();
  final TextEditingController _answerOtherController = TextEditingController();
  final TextEditingController standController = TextEditingController();

  @override
  void dispose() {
    _questionEnController.dispose();
    _answerEnController.dispose();
    _questionOtherController.dispose();
    _answerOtherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.addFaqEntry),
          actions: [
            BlocBuilder<ManageAppBloc, ManageAppState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    final isLoading =
                        state is AddingFaq || state is UpdatingFaq;
                    if (isLoading) return;

                    if (widget.isEdit) {
                      if (_formKey.currentState!.validate()) {
                        final faqEntry = FaqModel(
                          id: widget.faq!.id,
                          widget.faq!.stand,
                          questionEn: _questionEnController.text.trim(),
                          questionAr: _questionOtherController.text.trim(),
                          answerEn: _answerEnController.text.trim(),
                          answerAr: _answerOtherController.text.trim(),
                        );
                        context.read<ManageAppBloc>().add(
                          UpdateFaqEvent(faqEntry),
                        );
                      }
                    } else {
                      if (_formKey.currentState!.validate()) {
                        final faqEntry = FaqModel(
                          id: "",
                          stand,
                          questionEn: _questionEnController.text.trim(),
                          questionAr: _questionOtherController.text.trim(),
                          answerEn: _answerEnController.text.trim(),
                          answerAr: _answerOtherController.text.trim(),
                        );
                        context.read<ManageAppBloc>().add(
                          AddFaqEvent(faqEntry),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: BlocListener<ManageAppBloc, ManageAppState>(
          listener: (context, state) async {
            if (_isDialogShowing) {
              try {
                Navigator.of(context, rootNavigator: true).pop();
              } catch (_) {}
              _isDialogShowing = false;
            }
            if (state is UpdatingFaq) {
              if (!_isDialogShowing) {
                _isDialogShowing = true;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  useRootNavigator: true,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.bgWhite,
                    // constraints: BoxConstraints(
                    //   maxWidth: 100,
                    //   minWidth: 100,
                    //   maxHeight: 100,
                    // ),
                    content: Center(
                      child: SizedBox(height: 24, child: Loader()),
                    ),
                  ),
                ).then((_) {
                  // Dialog
                  _isDialogShowing = false;
                });
              }
              return;
            }
            if (state is FaqUpdateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.amber,
                  content: Text(
                    '${AppLocalizations.of(context)!.error}: ${state.error}',
                  ),
                ),
              );
            }
            if (state is FaqUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    AppLocalizations.of(context)!.faqUpdatedSuccessfully,
                  ),
                ),
              );
              if (mounted) Navigator.of(context).pop();
            }
            if (state is AddingFaq) {
              if (!_isDialogShowing) {
                _isDialogShowing = true;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  useRootNavigator: true,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.bgWhite,
                    // constraints: BoxConstraints(
                    //   maxWidth: 100,
                    //   minWidth: 100,
                    //   maxHeight: 100,
                    // ),
                    content: Center(
                      child: SizedBox(height: 24, child: Loader()),
                    ),
                  ),
                ).then((_) {
                  // Dialog
                  _isDialogShowing = false;
                });
              }
              return;
            }

            if (state is FaqAdded) {
              // Show a yellow (amber) snackbar and then close this page after
              // the SnackBar has been dismissed so the user sees the message.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    AppLocalizations.of(context)!.faqAddedSuccessfully,
                  ),
                ),
              );
              if (mounted) Navigator.of(context).pop();
              return;
            }

            if (state is FaqAddError) {
              state.error.contains('already exists')
                  ? ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.amber,
                        content: Text(
                          AppLocalizations.of(context)!.entryAlreadyExists,
                        ),
                      ),
                    )
                  : ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.amber,
                        content: Text(
                          '${AppLocalizations.of(context)!.error}: ${state.error}',
                        ),
                      ),
                    );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  IgnorePointer(
                    ignoring: widget.isEdit,
                    child: TextFormField(
                      controller: standController,
                      decoration: InputDecoration(
                        counterText: "",
                        labelText:
                            AppLocalizations.of(context)?.positionText ??
                            'Position',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,

                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        int? parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          setState(() {
                            stand = parsedValue;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(
                                context,
                              )?.pleaseEnterSortOrder ??
                              'Please enter sort order';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.english,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _questionEnController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.question,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    validator: (value) => value == null || value.isEmpty
                        ? AppLocalizations.of(context)!.questionIsRequired
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _answerEnController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.answer,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,

                    validator: (value) => value == null || value.isEmpty
                        ? AppLocalizations.of(context)!.answerIsRequired
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.arabic,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _questionOtherController,

                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.question,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.questionIsRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _answerOtherController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.answer,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.answerIsRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
