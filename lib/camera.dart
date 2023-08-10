// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialog_shower/flutter_dialog_shower.dart';

class Camera extends StatefulWidget {
  const Camera({Key? key}) : super(key: key);

  @override
  CameraState createState() => CameraState();
}

class CameraState extends State<Camera> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;

  List<CameraDescription>? _availableCameras;

  List<XFile>? _images;

  Timer? _autoTimer;
  bool? _autoNextStopFlag;

  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // get camera
    () async {
      _availableCameras = await availableCameras();
      if (_availableCameras?.isNotEmpty == true) {
        CameraDescription? camera = _availableCameras?[0];
        if (camera != null) {
          onNewCameraSelected(camera);
          return;
        }
      }
      OverlayWidgets.showToast('Can not open the camera device');
    }();

    _images = <XFile>[];
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraController = null;
    _images?.clear();
    _images = null;
    _autoTimer?.cancel();
    _autoTimer = null;
    _scrollController?.dispose();
    _scrollController = null;
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
      if (mounted) setState(() {});
      if (_cameraController?.value.hasError == true) {
        print('Camera error ${_cameraController?.value.errorDescription}');
      }
    });

    try {
      await _cameraController?.initialize();
      await _cameraController?.lockCaptureOrientation(DeviceOrientation.landscapeRight);
      if (mounted) setState(() {});
    } catch (e) {
      print('Camera controller initialize exception: $e');
    }
  }

  Future<XFile?> take() async {
    if (_cameraController == null ||
        _cameraController?.value.hasError == true ||
        _cameraController?.value.isInitialized == false) {
      print('Camera controller not initialized');
      return null;
    }

    if (_cameraController?.value.isTakingPicture == true) {
      print('Camera controller taking picture');
      return null;
    }

    // DialogShower? loadingDialog;
    try {
      // loadingDialog = DialogWidgets.showLoading(text: "Taking picture...");
      final XFile? file = await _cameraController?.takePicture();
      return file;
    } catch (e, s) {
      print('Camera controller take picture exception: $e, $s');
    } finally {
      // loadingDialog?.dismiss();
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

    void updateUI(XFile? file) {
      if (file != null) {
        _images?.add(file);
        if (!mounted) return;
        // _scrollController?.animateTo(180.0, duration: const Duration(milliseconds: 500), curve: Curves.ease);
        setState(() {});
      }
    }

    Future<void> takeOnce() async {
      _autoNextStopFlag = _autoNextStopFlag == true ? false : true;
      XFile? file = await take();
      updateUI(file);
    }

    Future<void> takeAuto() async {
      if (_autoNextStopFlag == true) {
        _autoTimer?.cancel();
        _autoTimer = null;
        return;
      }

      /// 1. using a timer
      // _autoTimer?.cancel();
      // _autoTimer = null;
      // _autoTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) async {
      //   await takeOnce();
      // });

      /// 2. using call recursively
      XFile? file = await take();
      updateUI(file);
      await Future.delayed(const Duration(seconds: 1));
      await takeAuto();
    }

    return Column(
      children: [
        CameraPreview(_cameraController!),
        const SizedBox(height: 10),
        Wrap(
          children: [
            CupertinoButton(onPressed: takeOnce, child: const Text('Take')),
            CupertinoButton(
                onPressed: takeAuto, child: Text('Take Auto ${(_images?.length ?? 0) == 0 ? '' : _images?.length}')),
            CupertinoButton(child: const Text('Close'), onPressed: () => DialogWrapper.dismissTopDialog()),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            reverse: true,
            controller: _scrollController,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...?_images?.map((e) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Image.file(File(e.path)),
                  );
                }).toList()
              ],
            ),
          ),
        )
      ],
    );
  }
}
