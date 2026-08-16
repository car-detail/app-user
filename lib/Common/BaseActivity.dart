import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'CommonWidget.dart';

class BaseActivity {
  static bool checkEmptyField(
      {required TextEditingController editingController,
      required String message,
      required BuildContext context}) {
    if (editingController.text.toString() == "") {
      CommonWidget.errorShowSnackBarFor(context, message);
      return true;
    } else {
      return false;
    }
  }

  static Future<List<XFile>?> pickmultipleImageAndroid13() async {
    final ImagePicker imagePicker = ImagePicker();
    /*final pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);

*/
    try {
      final pickedImage =
          await imagePicker.pickMultiImage(maxHeight: 1000, maxWidth: 1000);
      return pickedImage;
        } catch (e) {
    }
    return null;
  }

  static Future<List<File>?> pickmedia(bool allowMultiple) async {
    List<File> files = [];
    try {
      final ImagePicker picker = ImagePicker();
      if (allowMultiple) {
        final List<XFile> pickedImages = await picker.pickMultiImage();
        if (pickedImages.isNotEmpty) {
          files.addAll(pickedImages.map((xFile) => File(xFile.path)).toList());
        }
      } else {
        final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (pickedImage != null) {
          files.add(File(pickedImage.path));
        }
      }
      return files.isNotEmpty ? files : null;
    } catch (e) {
      debugPrint("Error in pickmedia: $e");
    }
    return null;
  }

  /*static Future<List<File>?> pickImage(bool allowMultiple) async {
    List<File> file = [];
    try {
      FilePickerResult? _imagePicker = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.image,
      );
      if (_imagePicker != null) {
        file.addAll(_imagePicker.paths.map((path) => File(path!)).toList());
      }
      return file;
    } catch (e) {
    }
  }*/
  static Future<List<File>?> pickImage(bool allowMultiple) async {
    List<File> files = [];
    try {
      final ImagePicker picker = ImagePicker();
      if (allowMultiple) {
        final List<XFile> pickedImages = await picker.pickMultiImage();
        if (pickedImages.isNotEmpty) {
          files.addAll(pickedImages.map((xFile) => File(xFile.path)).toList());
        }
      } else {
        final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (pickedImage != null) {
          files.add(File(pickedImage.path));
        }
      }
    } catch (e) {
      debugPrint("Error in pickImage: $e");
    }
    return files.isNotEmpty ? files : null;
  }

  /// Opens the image picker directly — no dialog, no file option.
  /// [allowMultipleImage] controls whether multiple images can be selected.
  static Future<void> showFilePicker(
      BuildContext context,
      Function(List<File>? list) onTeacherSelected,
      {
      @Deprecated('No longer used — file upload removed') List<String> allowedExtensions = const [],
      @Deprecated('No longer used — always image only') bool isFile = false,
      @Deprecated('No longer used — always image only') bool isPhoto = true,
      @Deprecated('No longer used — always image only') bool isOnlyPhoto = true,
      bool allowMultipleImage = true,
      }) async {
    final list = await pickmedia(allowMultipleImage);
    onTeacherSelected(list);
  }
}
