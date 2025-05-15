import 'dart:io';
import 'package:camera/camera.dart';

sealed class CameraState {}

final class CameraInitial extends CameraState {}

final class CameraReady extends CameraState {
  final CameraController controller;
  final int selectedIndex;
  final FlashMode flashMode;
  final File? imageFile;
  final String? snackbarMessage;

  CameraReady({
    required this.controller,
    required this.selectedIndex,
    required this.flashMode,
    this.imageFile,
    this.snackbarMessage,
  });

  CameraReady copyWith({
    CameraController? controller,
    int? selectedIndex,
    FlashMode? flashMode,
    File? imageFile,
    String? snackbarMessage,
    bool clearSnackbar = false,
  }) {
    return CameraReady(
      controller: controller ?? this.controller,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      flashMode: flashMode ?? this.flashMode,
      imageFile: imageFile ?? this.imageFile,
      snackbarMessage:
          clearSnackbar ? null : snackbarMessage ?? this.snackbarMessage,
    );
  }
}
