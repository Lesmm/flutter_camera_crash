# flutter_camera_crash

A new Flutter project.

## Only On Android

    ````
    Thread Name: 'CameraBackground'
    Back traces starts.
    java.lang.NullPointerException: Attempt to invoke virtual method 'void android.hardware.camera2.CameraCaptureSession.close()' on a null object reference
    at io.flutter.plugins.camera.Camera.closeCaptureSession(Camera.java:1228)
    at io.flutter.plugins.camera.Camera$1.onClosed(Camera.java:348)
    at android.hardware.camera2.impl.CameraDeviceImpl$5.run(CameraDeviceImpl.java:252)
    at android.os.Handler.handleCallback(Handler.java:942)
    at android.os.Handler.dispatchMessage(Handler.java:99)
    at android.os.Looper.loopOnce(Looper.java:223)
    at android.os.Looper.loop(Looper.java:324)
    at android.os.HandlerThread.run(HandlerThread.java:67)
    Back traces ends.
    ````

### Issue

    https://github.com/flutter/flutter/issues/114012


### Occasionally reproduce this crash:

Continuously enter and exit the camera page, crash occurs between the 100th and 300th time.


### 100% Re-Produce the issue steps:

1. Set two breakpoints in `io.flutter.plugins.camera.Camera` [Camera.java](https://github.com/flutter/packages/blob/camera_android-v0.10.8%252B5/packages/camera/camera_android/android/src/main/java/io/flutter/plugins/camera/Camera.java) :
   * breakpoint 1: [Line 1228](https://github.com/flutter/packages/blob/867f2a4c929a0afe881ca4277f27d260952f4fb2/packages/camera/camera_android/android/src/main/java/io/flutter/plugins/camera/Camera.java#L1228) `captureSession.close();`
   * breakpoint 2: [Line 1263](https://github.com/flutter/packages/blob/867f2a4c929a0afe881ca4277f27d260952f4fb2/packages/camera/camera_android/android/src/main/java/io/flutter/plugins/camera/Camera.java#L1263) `captureSession = null;`
2. Push the camera view in then pop it out after the camera is working.
3. Continue the thread from breakpoint 2 -> breakpoint 1, crash raised.

### How-to fix:
Just add `synchronized` key to this three close method

    synchronized void closeCaptureSession() {
    // on Line 1224
    ...
    
    synchronized public void close() {
    // on Line 1233
    ...
    
    synchronized private void stopAndReleaseCamera() {
    // on Line 1256
    ...