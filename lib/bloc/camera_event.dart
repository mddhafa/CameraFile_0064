import 'dart:io';
import 'package:flutter/material.dart';

sealed class CameraEvent {}

final class InitializeCamera extends CameraEvent {}

final class SwitchCamera extends CameraEvent {}

final class ToggleFlash extends CameraEvent {}

final class TakePicture extends CameraEvent {
  final void Function(File imageFile) onPictureTaken;
  TakePicture(this.onPictureTaken);
}

final class TapToFocus extends CameraEvent {
  final Offset position;
  final Size previewSize;
  TapToFocus(this.position, this.previewSize);
}

final class PickGallery extends CameraEvent {}

final class OpenCameraAndCapture extends CameraEvent {
  final BuildContext context;
  OpenCameraAndCapture(this.context);
}

final class DeleteImage extends CameraEvent {}

final class ClearSnackBar extends CameraEvent {}

final class RequestPermissions extends CameraEvent {}
