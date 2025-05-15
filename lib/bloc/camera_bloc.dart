import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:camera_sensor/camera_page_bloc.dart';
import 'package:camera_sensor/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  late final List<CameraDescription> _cameras;

  CameraBloc() : super(CameraInitial()) {
    on<InitializeCamera>(_onInit);
    on<SwitchCamera>(_onSwitch);
    on<ToggleFlash>(_onToggleFlash);
    on<TapToFocus>(_onTapToFocus);
    on<PickGallery>(_onPickGallery);
    on<OpenCameraAndCapture>(_onOpenCamera);
    on<DeleteImage>(_onDeleteImage);
    on<ClearSnackBar>(_onClearSnackBar);
    on<RequestPermissions>(_onRequestPermissions);
  }

  Future<void> _onInit(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    _cameras = await availableCameras();
    await _setupController(emit, 0);
  }

  Future<void> _onSwitch(SwitchCamera event, Emitter<CameraState> emit) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final i = s.selectedIndex + 1 > _cameras.length;
    await _setupController(emit, i ? 0 : s.selectedIndex + 1);
  }

  Future<void> _onToggleFlash(
    ToggleFlash event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final next =
        s.flashMode == FlashMode.off
            ? FlashMode.auto
            : s.flashMode == FlashMode.auto
            ? FlashMode.always
            : FlashMode.off;
    await s.controller.setFlashMode(next);
    emit(s.copyWith(flashMode: next));
  }

  Future<void> _onTakePicture(
    TakePicture event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final file = await s.controller.takePicture();
    event.onPictureTaken(File(file.path));
  }

  Future<void> _onTapToFocus(
    TapToFocus event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final relative = Offset(
      event.position.dx / event.previewSize.width,
      event.position.dy / event.previewSize.height,
    );
    await s.controller.setFocusPoint(relative);
  }

  Future<void> _onPickGallery(
    PickGallery event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      emit(
        (state as CameraReady).copyWith(
          imageFile: File(xfile.path),
          snackbarMessage: 'Berhasil memilih dari galeri.',
        ),
      );
    }
  }

  Future<void> _onOpenCamera(
    OpenCameraAndCapture event,
    Emitter<CameraState> emit,
  ) async {
    print('[CameraBloc] OpenCameraAndCapture triggered');
    if (state is! CameraReady) {
      print('[CameraBloc] state is not ready, abort!');
      return;
    }

    final file = await Navigator.push<File>(
      event.context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: this, child: CameraPage()),
      ),
    );

    if (file != null) {
      final saved = await StorageHelper.saveImage(file, 'camera');
      emit(
        (state as CameraReady).copyWith(
          imageFile: saved,
          snackbarMessage: 'Disimpan: ${saved.path}',
        ),
      );
    }
  }

  Future<void> _onDeleteImage(
    DeleteImage event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    await s.imageFile?.delete();
    emit(
      CameraReady(
        controller: s.controller,
        selectedIndex: s.selectedIndex,
        flashMode: s.flashMode,
        imageFile: null,
        snackbarMessage: 'Gambar dihapus',
      ),
    );
  }

  Future<void> _onClearSnackBar(
    ClearSnackBar event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    emit(
      (state as CameraReady).copyWith(
        snackbarMessage: null,
        clearSnackbar: true,
      ),
    );
  }

  Future<void> _setupController(Emitter<CameraState> emit, int index) async {
    await (state as CameraReady?)?.controller.dispose();
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.max,
      enableAudio: false,
    );
    await controller.initialize();
    await controller.setFlashMode(FlashMode.off);

    emit(
      CameraReady(
        controller: controller,
        selectedIndex: index,
        flashMode: FlashMode.off,
        imageFile: null,
        snackbarMessage: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    if (state is CameraReady) {
      await (state as CameraReady).controller.dispose();
    }
    return super.close();
  }

  Future<void> _onRequestPermissions(
    RequestPermissions event,
    Emitter<CameraState> emit,
  ) async {
    final statuses =
        await [
          Permission.camera,
          Permission.storage,
          Permission.manageExternalStorage,
        ].request();

    final denied = statuses.entries.where((e) => !e.value.isGranted).toList();

    if (denied.isNotEmpty) {
      if (state is CameraReady) {
        emit(
          (state as CameraReady).copyWith(
            snackbarMessage: 'Izin kamera atau penyimpanan ditolak.',
          ),
        );
      }
    }
  }
}
