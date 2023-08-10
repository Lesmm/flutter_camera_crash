// ignore_for_file: avoid_print

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialog_shower/flutter_dialog_shower.dart';

class CameraEx extends StatefulWidget {
  const CameraEx({Key? key}) : super(key: key);

  @override
  CameraExState createState() => CameraExState();
}

class CameraExState extends State<CameraEx> with WidgetsBindingObserver, TickerProviderStateMixin {
  static const String kTAG = 'CameraEx';
  
  CameraController? _cameraController;

  List<CameraDescription>? _availableCameras;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // get camera
    () async {
      _availableCameras = await availableCameras();
      print('>>>$kTAG availableCameras: ${_availableCameras?.length}, $_availableCameras');
      if (_availableCameras?.isNotEmpty == true) {
        CameraDescription? camera = _availableCameras?[0];
        if (camera != null) {
          onNewCameraSelected(camera);
          return;
        }
      }
      OverlayWidgets.showToast('Can not open the camera device');
    }();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || _cameraController?.value.isInitialized == false) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      CameraDescription? description = _cameraController?.description;
      if (description != null) {
        onNewCameraSelected(description);
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    await _cameraController?.dispose();
    _cameraController = null;
    _cameraController = CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    _cameraController?.addListener(() {
      print(''
          '>>>$kTAG listener '
          'isInitialized: ${_cameraController?.value.isInitialized}, '
          'hasError: ${_cameraController?.value.hasError}, '
          'error: ${_cameraController?.value.errorDescription}'
          '');

      if (mounted) setState(() {});
    });

    // initialize
    try {
      await _cameraController?.initialize();
      await _cameraController?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (mounted) setState(() {});
      print('>>>$kTAG controller initialize done');

      // auto take picture
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (mounted) {
          XFile? file;
          // file = await take();  //
          DialogWrapper.popOrDismiss(result: file);
        }
      });
    } catch (e) {
      print('>>>$kTAG controller initialize exception: $e');
    }
  }

  Future<XFile?> take() async {
    if (_cameraController == null ||
        _cameraController?.value.hasError == true ||
        _cameraController?.value.isInitialized == false) {
      print('>>>$kTAG controller not initialized');
      return null;
    }

    if (_cameraController?.value.isTakingPicture == true) {
      print('>>>$kTAG controller is taking picture');
      return null;
    }

    DialogShower? loadingDialog;
    try {
      loadingDialog = DialogWidgets.showLoading(text: "Taking picture...");
      final XFile? file = await _cameraController?.takePicture();
      return file;
    } catch (e, s) {
      print('>>>$kTAG controller take picture exception: $e, $s');
    } finally {
      loadingDialog?.dismiss();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        _cameraController?.value.hasError == true ||
        _cameraController?.value.isInitialized == false) {
      String msg = 'Initialing ...';
      if (_cameraController?.value.hasError == true) {
        msg = _cameraController?.value.errorDescription ?? 'Initialized error';
      }
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(msg, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
      );
    }

    return Column(
      children: [
        Expanded(child: CameraPreview(_cameraController!)),
      ],
    );
  }
}
