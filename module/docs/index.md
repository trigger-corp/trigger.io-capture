``capture``: File access methods requiring Camera and/or Microphone access
==========================================================================

The ``forge.capture`` namespace allows capturing images and videos with the camera.


## Config options

usage_description
:   This key lets you describe the reason your app accesses the user's camera and photo library. When the system prompts the user to allow access, this string is displayed as part of the alert.


## API

!method: forge.capture.getImage([params], success, error)
!param: params `object` an optional object of parameters
!param: success `function(file)` callback to be invoked when no errors occur (argument is the returned file)
!description: Returns a file object for a image selected by the user from their photo gallery or (if possible on the device) taken using their camera.
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

The optional parameters can contain any combination of the following:

-  ``width``  (number): The maximum height of the image returned.
-  ``height`` (number): The maximum width of the image returned.
-  ``saveLocation``: By default camera photos will be saved to a
   temporary location on the device. By setting this option to
   ``"gallery"`` returned images will also be saved to the device
   gallery.

Returned files will be accessible to the app as long as they exist on
the device.

!method: forge.capture.getVideo([params], success, error)
!param: params `object` an optional object of parameters
!param: success `function(file)` callback to be invoked when no errors occur (argument is the returned file)
!description: Returns a file object for a video selected by the user from their photo gallery or (if possible on the device) taken using their camera.
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

> ::Important:: On iOS devices, the first time your app reads from the gallery, the
user will be prompted to allow the app to access your location. This
is because the EXIF data in files stored there could be used to
infer a user's geolocation. For more information, see
modules-file-permissions.

The optional parameters can contain any combination of the following:

- ``videoQuality``: Sets the video quality. Valid options are:
  `"default"`, `"low"`, "`medium`" and `"high"`.
- ``videoDuration``: If the user records a new video then the video
  duration will be limited to the given length in seconds.
-  ``saveLocation``: By default videos will be saved to a temporary
   location on the device. By setting this option to ``"gallery"``
   returned videos will also be saved to the device gallery.

Please note that tt is hard to predict the quantifiable properties of
videos that have been transcoded with the `videoQuality` setting as it
van vary greatly between operating system and device versions. On some
devices it may have no effect at all.

Generally the `"high"` setting corresponds to the highest-quality
video recording supported for the active camera on the device.


## Permissions

On Android this module will add the ``WRITE_EXTERNAL_STORAGE``
permission to your app, users will be prompted to accept this when
they install your app.
