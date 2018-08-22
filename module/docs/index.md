``capture``: File access methods requiring Camera and/or Microphone access
==========================================================================

The ``forge.capture`` namespace allows capturing images with the camera or selecting them from the users saved photos.

- File objects are simple JavaScript objects which contain at least a
   ``uri``. They can be serialised using JSON.stringify and safely
   stored in Forge preferences.
- The ``uri`` parameter can be used directly on some platforms. This is
   not recommended - instead use the provided helper function
   ``forge.file.URL``.
- Image orientation is automatically handled where possible: if a
   camera photo contains rotation information it will be correctly
   rotated before it is displayed or uploaded.



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

> ::Important:: On iOS devices, the first time your app reads from the gallery, the
user will be prompted to allow the app to access your location. This
is because the EXIF data in images stored there could be used to
infer a user's geolocation. For more information, see
modules-file-permissions.

The optional parameters can contain any combination of the following:

-  ``width`` (number): The maximum height of the image when used, if the returned
   image is larger than this it will be automatically resized before
   display. The stored image will not be resized.
-  ``height`` (number): As ``width`` but sets a maximum height, both ``height``
   and ``width`` can be set.
-  ``source``: By default the user will be prompted to use the camera or
   select an image from the photo gallery, if you want to limit this
   choice you can set this to ``"camera"`` or ``"gallery"``.
-  ``saveLocation``: By default camera photos will be saved to the
   device photo album, with this setting they can be forced to be saved
   within your application by using ``"file"``.

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

-  ``source``: By default the user will be prompted to use the camera or
   select a video from the photo gallery, if you want to limit this
   choice you can set this to ``"camera"`` or ``"gallery"``.
- ``videoQuality``: Sets the video quality. Valid options are: `"default"`, `"low"`, "`medium`" and `"high"`.
- ``videoDuration``: If the user records a new video then the video duration will be limited to the given length in seconds.

Returned files will be accessible to the app as long as they exist on
the device.

Please note that tt is hard to predict the quantifiable properties of videos that have been transcoded with the `videoQuality` setting as it van vary greatly between operating system and device versions. Generally the `"high"` setting corresponds to the highest-quality video recording supported for the active camera on the device.


## Permissions

On Android this module will add the ``WRITE_EXTERNAL_STORAGE``
permission to your app, users will be prompted to accept this when they
install your app.

On iOS, accessing files in the device's gallery causes the user to be
prompted to give your app access to their location. This is because
files in the gallery may contain EXIF data, including geolocation and
timestamps.

To avoid the user being shown this prompt, you could save your image
into a file rather than the gallery, using the ``saveLocation``
parameter. This is not yet supported when capturing videos.

If a user chooses not to share their location with your app, the error
callback of the method trying to read files from the gallery will be
invoked.
