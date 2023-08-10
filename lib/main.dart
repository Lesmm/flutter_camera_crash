// ignore_for_file: avoid_print

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_crash/camera.dart';
import 'package:flutter_camera_crash/camera_ex.dart';
import 'package:flutter_dialog_shower/flutter_dialog_shower.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          /// init the dialog shower & overly shower
          DialogShower.init(context);
          OverlayShower.init(context);
          DialogWrapper.centralOfShower ??= (DialogShower shower, {Widget? child}) {
            shower
              // null indicate that: dismiss keyboard first while keyboard is showing, else dismiss dialog immediately
              ..barrierDismissible = null
              ..containerShadowColor = Colors.grey
              ..containerShadowBlurRadius = 20.0
              ..containerBorderRadius = 10.0;
            return null;
          };
          OverlayWrapper.centralOfShower ??= (OverlayShower shower) {
            print("a new overlay show: $shower");
          };

          /// init the size utilities with context
          ScreensUtils.context = context;
          return const Home();
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  List<XFile>? _images;

  bool autoTakeFlag = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera crash  ${(_images?.length ?? 0) == 0 ? '' : _images?.length}')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                reverse: true,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...?_images?.map((e) {
                      return Container(
                        width: 50,
                        height: 50,
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
        ),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(child: const Icon(Icons.add), onPressed: () => onEventStartCameraCaptureView()),
          const SizedBox(height: 8),
          FloatingActionButton(child: const Icon(Icons.adb), onPressed: () => onEventStartAutoTakePictureView()),
        ],
      ),
    );
  }

  /// Events
  void onEventStartCameraCaptureView() {
    _images?.clear();
    if (mounted) {
      setState(() {});
    }
    DialogWrapper.pushRoot(const Camera());
  }

  Future<void> onEventStartAutoTakePictureView() async {
    void updateUI(XFile? file) {
      if (file == null) return;
      (_images ??= []).add(file);
      print('########### Already take photo image count: ${_images?.length}');
      if (mounted) {
        setState(() {});
      }
    }

    autoTakeFlag = !autoTakeFlag;
    while (autoTakeFlag) {
      XFile? file = await ((DialogWrapper.showRight(const CameraEx())..padding = EdgeInsets.zero).future);
      updateUI(file);
      await Future.delayed(const Duration(milliseconds: 500)); // 250 failed ...
    }
  }
}
