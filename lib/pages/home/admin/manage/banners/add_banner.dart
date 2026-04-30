import 'dart:io';

import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/regex.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/banner.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class AddBanner extends StatefulWidget {
  final BannerModel? banner;
  const AddBanner({super.key, this.banner});

  @override
  State<AddBanner> createState() => _AddBannerState();
}

class _AddBannerState extends State<AddBanner> {
  final formKey = GlobalKey<FormState>();
  int setction = 1;
  final TextEditingController labelController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  bool isActive = false;
  XFile? selectedImage;
  XFile? tempSelectedImage;
  bool showImageConfirmation = false;
  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        // Check if file exists
        final file = File(image.path);
        if (!await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.selectedFileCouldNotBeFound ??
                      'Selected file could not be found. Please try again.',
                ),

                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => tempSelectedImage = image);
        await cropImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorPickingImage}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future cropImage() async {
    try {
      if (tempSelectedImage == null) return;

      CroppedFile? res = await ImageCropper().cropImage(
        sourcePath: tempSelectedImage!.path,
        aspectRatio: const CropAspectRatio(ratioX: 370, ratioY: 136),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
          ),
          IOSUiSettings(
            title: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (res != null) {
        setState(() {
          selectedImage = XFile(res.path);
          tempSelectedImage = null;
          showImageConfirmation = false;
        });
      } else {
        final bool? shouldKeepImage = await showCropConfirmDialog(context);

        if (shouldKeepImage == true) {
          setState(() {
            selectedImage = tempSelectedImage;
            tempSelectedImage = null;
          });
        } else {
          setState(() {
            selectedImage = null;
            tempSelectedImage = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorCroppingImage}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        selectedImage = null;
        tempSelectedImage = null;
      });
    }
  }

  void fillContents() {
    if (widget.banner != null) {
      labelController.text = widget.banner!.label ?? '';
      urlController.text = widget.banner!.url ?? '';
      setState(() {
        isActive = widget.banner!.active ?? false;
      });
    }
  }

  @override
  void initState() {
    fillContents();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is BannerAddError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
        if (state is BannerAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bannerAddedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
        if (state is BannerUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
        if (state is BannerUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bannerUpdatedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.banner == null
                ? AppLocalizations.of(context)!.addBanner
                : AppLocalizations.of(context)!.editBanner,
          ),
          actions: [
            BlocBuilder<ManageAppBloc, ManageAppState>(
              builder: (context, state) {
                return IconButton(
                  icon: state is AddingBanner || state is UpdatingBanner
                      ? Padding(
                          padding: EdgeInsets.only(right: 16, left: 16),
                          child: Loader(size: 10, color: Colors.white),
                        )
                      : Icon(Icons.save),
                  onPressed: (state is AddingBanner || state is UpdatingBanner)
                      ? null
                      : () {
                          final isLoading =
                              state is AddingBanner || state is UpdatingBanner;
                          if (isLoading) return;

                          if (formKey.currentState!.validate()) {
                            // Check if image is mandatory for new banners
                            if (widget.banner == null &&
                                selectedImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.imageIsRequired ??
                                        'Image is required',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Check if image is mandatory for existing banners without image
                            if (widget.banner != null &&
                                selectedImage == null &&
                                (widget.banner?.image == null ||
                                    widget.banner!.image!.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.imageIsRequired ??
                                        'Image is required',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            widget.banner == null
                                ? context.read<ManageAppBloc>().add(
                                    AddBannerEvent(
                                      BannerModel(
                                        url: urlController.text,
                                        image: selectedImage?.path ?? '',
                                        label: labelController.text,
                                        active: isActive,
                                        section: setction,
                                      ),
                                      imageFile: selectedImage,
                                    ),
                                  )
                                : context.read<ManageAppBloc>().add(
                                    UpdateBannerEvent(
                                      widget.banner!,
                                      imageFile: selectedImage,
                                    ),
                                  );
                          }
                        },
                );
              },
            ),
          ],
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: EdgeInsets.only(
              left: safePadding.left + 16,
              right: safePadding.right + 16,
              top: 16,
              bottom: safePadding.bottom + 70,
            ),
            children: [
              SwitchListTile(
                activeThumbColor: AppColors.primary,
                value: isActive,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => isActive = value),
                title: Text(AppLocalizations.of(context)?.active ?? 'Active'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                activeThumbColor: AppColors.primary,
                value: setction == 1,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => setction = value ? 1 : 2),
                title: Text(
                  AppLocalizations.of(context)?.showInPrimaryBanner ??
                      'Show in Primary Banner',
                ),
                subtitle: Text(
                  AppLocalizations.of(
                        context,
                      )?.ifDisabledItWillShowInSecondaryBanner ??
                      'If disabled, it will show in secondary banner',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.label ?? 'Label',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.labelIsRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.url ?? 'URL',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.urlIsRequired;
                  }
                  if (!Regex.urlRegex.hasMatch(value)) {
                    return AppLocalizations.of(context)!.invalidUrl;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(AppColors.primary),
                  ),
                  onPressed: pickImage,
                  child: Text(
                    AppLocalizations.of(context)?.pickImage ?? 'Pick Image',
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: selectedImage != null
                        ? Image.file(File(selectedImage!.path), height: 130)
                        : widget.banner?.image != null
                        ? CachedNetworkImage(
                            imageUrl: widget.banner?.image ?? "",
                            height: 130,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
