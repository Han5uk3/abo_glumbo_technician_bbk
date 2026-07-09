import 'dart:developer';
import 'package:aboglumbo_bbk_panel/common_widget/saving_stack.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/shimmer_loading.dart';
import '/models/highlighted_services.dart';
import '/models/service.dart';

class AddHighlightedServices extends StatefulWidget {
  const AddHighlightedServices({super.key, this.service});
  final HighlightedServicesModel? service;

  @override
  State<AddHighlightedServices> createState() => _AddHighlightedServicesState();
}

class _AddHighlightedServicesState extends State<AddHighlightedServices> {
  final _formKey = GlobalKey<FormState>();

  bool isSaving = false;

  List<String> selectedServices = [];
  bool isActive = false;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController titleArController = TextEditingController();
  final TextEditingController sortOrderController = TextEditingController();
  int? sortOrder;

  Map<String, ServiceModel> cachedServices = {};

  final arabicFullRegex = RegExp(r'''^[\u0600-\u06FF
       \u0750-\u077F
       \u08A0-\u08FF
       \uFB50-\uFDFF
       \uFE70-\uFEFF
       \u0660-\u0669
       \u06F0-\u06F9
       \u200C-\u200F
       \s\n\r\d
       \.\,\!\?\،\؛\؟\:\-\(\)\[\]\"\'\u061F]+$''', multiLine: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fillContents();
    });
  }

  void fillContents() async {
    if (widget.service != null) {
      log('widget.service: ${widget.service?.toJson()}');
      titleController.text = widget.service?.title ?? '';
      titleArController.text = widget.service?.title_ar ?? '';
      sortOrder = widget.service!.sortOrder ?? 0;
      sortOrderController.text = sortOrder.toString();
      setState(() {
        isActive = widget.service!.active ?? false;
        selectedServices = widget.service!.services ?? [];
      });

      await loadSelectedServices();
    } else {
      sortOrder = 0;
      sortOrderController.text = '0';
    }
  }

  Future<void> loadSelectedServices() async {
    for (String serviceId in selectedServices) {
      if (!cachedServices.containsKey(serviceId)) {
        try {
          final doc = await AppFirestore.servicesCollectionRef
              .doc(serviceId)
              .get();
          if (doc.exists) {
            cachedServices[serviceId] = ServiceModel.fromDocumentSnapshot(doc);
          }
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSingleService(String serviceId) async {
    if (!cachedServices.containsKey(serviceId)) {
      try {
        final doc = await AppFirestore.servicesCollectionRef
            .doc(serviceId)
            .get();
        if (doc.exists) {
          if (mounted) {
            setState(() {
              cachedServices[serviceId] = ServiceModel.fromDocumentSnapshot(
                doc,
              );
            });
          }
        }
      } catch (e) {
        log(e.toString());
      }
    }
  }

  Future saveContent() async {
    if (isSaving) return;
    if (_formKey.currentState!.validate()) {
      if (selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.pleaseSelectAtLeastOneService ??
                  'Please select at least one service',
            ),
          ),
        );
        return;
      }

      if (titleArController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.pleaseEnterTheTitleInArabic ??
                  'Please enter the title in Arabic',
            ),
          ),
        );
        return;
      }

      if (!arabicFullRegex.hasMatch(titleArController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.descriptionMustBeInArabic ??
                  'Description must be in Arabic',
            ),
          ),
        );
        return;
      }

      setState(() => isSaving = true);
      try {
        HighlightedServicesModel service = HighlightedServicesModel(
          title: titleController.text.trim(),
          title_ar: titleArController.text.trim(),
          services: selectedServices,
          sortOrder: sortOrder,
          active: isActive,
          updatedAt: Timestamp.now(),
        );
        if (widget.service != null) {
          service = service.copyWith(id: widget.service!.id);
        } else {
          service.createdAt = Timestamp.now();
        }

        if (widget.service == null) {
          await AppFirestore.highlightedServicesCollectionRef.add(
            service.toJson(),
          );
        } else {
          final updateData = service.toEditJson(previous: widget.service!);
          if (updateData.isNotEmpty) {
            await AppFirestore.highlightedServicesCollectionRef
                .doc(widget.service!.id)
                .update(updateData);
          }
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.service == null
                    ? AppLocalizations.of(
                        context,
                      )!.highlightedServiceAddedSuccessfully
                    : AppLocalizations.of(
                        context,
                      )!.highlightedServiceUpdatedSuccessfully,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.failedToSaveHighlightedService ??
                    'Failed to save Highlighted service',
              ),
              action: SnackBarAction(
                label: AppLocalizations.of(context)?.retry ?? 'Retry',
                onPressed: saveContent,
              ),
            ),
          );
        }
      }
    }
    setState(() => isSaving = false);
  }

  void selectServiceBottomSheet() {
    List<String> tempSelectedServices = List.from(selectedServices);
    Map<String, ServiceModel> tempCachedServices = Map.from(cachedServices);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)?.selectServices ??
                        'Select Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedServices = tempSelectedServices;
                        cachedServices = tempCachedServices;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)?.done ?? 'Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: AppFirestore.servicesCollectionRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)?.failedToLoadServices ??
                            'Failed to load services',
                      ),
                    );
                  }
                  final services = snapshot.data?.docs ?? [];
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return ListView.builder(
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final ServiceModel service =
                              ServiceModel.fromQueryDocumentSnapshot(
                                services[index],
                              );
                          return CheckboxListTile(
                            secondary: CachedNetworkImage(
                              imageUrl: service.image ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const ImageShimmer(width: 50, height: 50),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                            title: Text(
                              service.nameLocalized(
                                    languageCode:
                                        AppLocalizations.of(
                                          context,
                                        )?.localeName ??
                                        'en',
                                  ) ??
                                  service.name ??
                                  '',
                            ),
                            value: tempSelectedServices.contains(service.id),
                            onChanged: (value) {
                              setState(() {
                                if (value!) {
                                  tempSelectedServices.add(service.id!);
                                  tempCachedServices[service.id!] = service;
                                } else {
                                  tempSelectedServices.remove(service.id);
                                  tempCachedServices.remove(service.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    titleArController.dispose();
    sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    return PopScope(
      canPop: !isSaving,
      child: AbsorbPointer(
        absorbing: isSaving,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.service == null
                  ? AppLocalizations.of(context)!.addHighlightedService
                  : AppLocalizations.of(context)!.editHighlightedService,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: isSaving ? null : saveContent,
              ),
            ],
          ),
          body: SavingStackWidget(
            isSaving: isSaving,
            isLoading: false,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: safePadding.bottom,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SwitchListTile(
                      activeThumbColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppLocalizations.of(context)?.active ?? 'Active',
                      ),
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)?.title ?? 'Title',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.pleaseEnterATitle;
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: titleArController,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)?.titleArabic ??
                            'Title (Arabic)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.pleaseEnterTheTitleInArabic;
                        } else if (!arabicFullRegex.hasMatch(value)) {
                          return AppLocalizations.of(
                            context,
                          )!.descriptionMustBeInArabic;
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.services ?? 'Services',
                        ),
                        TextButton.icon(
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              AppColors.primary,
                            ),
                          ),
                          onPressed: selectServiceBottomSheet,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            AppLocalizations.of(context)?.addService ??
                                'Add Service',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 127,
                    child: selectedServices.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(
                                    context,
                                  )?.noServicesSelected ??
                                  "No services selected",
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedServices.length,
                            itemBuilder: (context, index) {
                              final serviceId = selectedServices[index];
                              final service = cachedServices[serviceId];

                              if (service == null) {
                                _loadSingleService(serviceId);
                                return Container(
                                  height: 127,
                                  width: 127,
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(right: 13),
                                  child: const ImageShimmer(
                                    width: 127,
                                    height: 127,
                                  ),
                                );
                              }

                              return Container(
                                height: 127,
                                width: 127,
                                margin: const EdgeInsets.only(right: 13),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    SizedBox(
                                      height: 127,
                                      width: 127,
                                      child: CachedNetworkImage(
                                        imageUrl: service.image ?? '',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const ImageShimmer(),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                    ),
                                    Container(
                                      height: 88,
                                      width: 127,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          stops: [0, 1],
                                          begin: Alignment.center,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black,
                                          ],
                                        ),
                                      ),
                                      alignment:
                                          Directionality.of(context) ==
                                              TextDirection.rtl
                                          ? Alignment.bottomRight
                                          : Alignment.bottomLeft,
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        service.nameLocalized(
                                              languageCode:
                                                  AppLocalizations.of(
                                                    context,
                                                  )?.localeName ??
                                                  'en',
                                            ) ??
                                            service.name ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 32),
                    child: TextFormField(
                      controller: sortOrderController,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)?.sortOrder ??
                            'Sort Order',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        int? parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          setState(() {
                            sortOrder = parsedValue;
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
