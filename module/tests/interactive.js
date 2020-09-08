/* global forge, module, asyncTest, start, ok, askQuestion */

module("forge.capture");


// permissions module native code has to be baked into the capture module to avoid app store rejections
/*
if (forge.is.ios()) {
    if (!forge.permissions) {
        forge.permissions = {
            check: function (permission, success, error) {
                forge.internal.call("capture.permissions_check", {
                    permission: resolve(permission)
                }, success, error);

            },
            request: function (permission, rationale, success, error) {
                forge.internal.call("capture.permissions_request", {
                    permission: resolve(permission),
                    rationale: rationale
                }, success, error);
            },
            photos: {
                "write": "photos_write"
            },
            camera: {
                "read": "camera_read"
            },
            microphone: {
                "record": "microphone_record"
            },
        };
        function resolve(permission) {
            if (forge.permissions.photos.write) {
                return "ios.permission.photos_write";
            if (forge.permissions.camera.read) {
                return "ios.permission.camera";
            } else if (forge.permissions.microphone.record) {
                return "ios.permission.microphone";
            } else {
                throw "Unknown permission: " + permission;
            }
        }
    }

    var rationale = "Can haz captureburger?";

    asyncTest("Camera permission request denied.", 1, function() {
        var runTest = function() {
            forge.permissions.request(forge.permissions.camera.read, rationale, function (allowed) {
                if (!allowed) {
                    ok(true, "Permission request denied.");
                    start();
                } else {
                    ok(false, "Permission request was allowed. Expected permission denied.");
                    start();
                }
            }, apiError("permissions.request"));
        };

        forge.permissions.check(forge.permissions.camera.read, function (allowed) {
            if (allowed) {
                ok(true, "Already have permission");
                start();
            } else {
                askQuestion("When prompted, deny the permission request", { Ok: runTest });
            }
        }, apiError("permissions.check"));
    });

    asyncTest("Camera permission request allowed.", 1, function() {
        var runTest = function() {
            forge.permissions.request(forge.permissions.camera.read, rationale, function (allowed) {
                if (allowed) {
                    ok(true, "Permission request allowed.");
                    start();
                } else {
                    ok(false, "Permission request was denied. Expected permission allowed.");
                    start();
                }
            }, apiError("permissions.request"));
        };
        askQuestion("If prompted, allow the permission request", { Ok: runTest });
    });
}
*/


if (forge.file) {
    asyncTest("Saving camera output to Gallery", 1, function() {
        var runTest = function () {
            forge.capture.getImage({
                saveLocation: "gallery",
                width: 256,
                height: 256
            }, function (file) {
                forge.file.getScriptURL(file, function (url) {
                    askQuestion("Is this your image:<br><img src='" + url + "' style='max-width: 512px; max-height: 512px'>", {
                        Yes: function () {
                            ok(true, "Success");
                            start();
                        },
                        No: function () {
                            ok(false, "User claims failure");
                            start();
                        }
                    });
                }, apiError("file.getScriptURL"));
            }, apiError("capture.getImage"));
        };
        askQuestion("When prompted take a picture with the camera", { Ok: runTest });
    });


    asyncTest("Saving camera output to file", 4, function() {
        forge.capture.getImage({
            saveLocation: "file",
            width: 256,
            height: 256
        }, function (file) {
            askQuestion("Were you just prompted to use the camera?", {
                Yes: function () {
                    ok(true, "Success");
                    forge.file.exists(file, function (exists) {
                        ok(exists, "forge.file.exists");
                        forge.file.getScriptURL(file, function (url) {
                            askQuestion("Is this your image:<br><img src='" + url + "' style='max-width: 512px; max-height: 512px'>", {
                                Yes: function () {
                                    ok(true, "Success with forge.file.URL");
                                    forge.file.base64(file, function (data) {
                                        askQuestion("Is this also your image:<br><img src='data:image/jpg;base64," + data + "' style='max-width: 512px; max-height: 512px'>", {
                                            Yes: function () {
                                                ok(true, "Success");
                                                start();
                                            },
                                            No: function () {
                                                ok(false, "User claims failure with forge.file.base64");
                                                start();
                                            }});
                                    }, apiError("file.base64"));
                                },
                                No: function () {
                                    ok(false, "User claims failure");
                                    start();
                                }});
                        }, apiError("file.getScriptURL"));
                    }, apiError("file.exists"));
                },
                No: function () {
                    ok(false, "User claims failure");
                    start();
                }});
        }, apiError("capture.getImage"));
    });


    asyncTest("Record a video with the camera and check file info", 2, function() {
        var runTest = function () {
            forge.capture.getVideo({
                saveLocation: "file",
                videoQuality: "high",
                videoDuration: 2,
            }, function (file) {
                forge.file.info(file, function (info) {
                    ok(true, "file.info claims success");
                    askQuestion("Does the following file information describe the file: " + JSON.stringify(info), {
                        Yes: function () {
                            ok(true, "File information is correct");
                            start();
                        },
                        No: function () {
                            ok(false, "User claims failure");
                            start();
                        }
                    });
                }, apiError("file.info"));
            }, apiError("capture.getVideo"));
        };
        askQuestion("Record a video", { Ok: runTest });
    });


    asyncTest("Record a video with low quality and check file info", 2, function() {
        var runTest = function () {
            forge.capture.getVideo({
                saveLocation: "file",
                videoQuality: "low",
                videoDuration: 2
            }, function (file) {
                forge.file.info(file, function (info) {
                    ok(true, "file.info claims success");
                    askQuestion("Is the file size smaller this time: " + JSON.stringify(info), {
                        Yes: function () {
                            ok(true, "File information is correct");
                            start();
                        },
                        No: function () {
                            ok(false, "User claims failure");
                            start();
                        }
                    });
                }, function (e) {
                    ok(false, "API call failure: " + e.message);
                    start();
                });
            });
        };
        askQuestion("Record another video", { Ok: runTest });
    });


    asyncTest("Camera Video Player", 1, function() {
        var runTest = function () {
            forge.capture.getVideo({
                saveLocation: "gallery",
            }, function (file) {
                askQuestion("Was the video capture time unlimited?", {
                    Yes: function () {
                        forge.file.getScriptURL(file, function (url) {
                            askQuestion("Did your video just play: <video controls autoplay playsinline style='max-width:512px; max-height:512px' src='" + url + "'></video>", {
                                Yes: function () {
                                    ok(true, "video playback successful");
                                    start();
                                }, No: function () {
                                    ok(false, "video playback failed");
                                    start();
                                }
                            });
                        }, apiError("file.getScriptURL"));
                    },
                    No: function () {
                        ok(false, "video capture was limited");
                        start();
                    }
                });
            }, apiError("capture.getVideo"));
        };
        askQuestion("Record a video which is longer than two seconds", { Ok: runTest });
    });
}


asyncTest("Cancel", 1, function() {
    var runTest = function () {
        forge.capture.getImage(function () {
            ok(false, "forge.capture.getImage returned success");
            start();
        }, function () {
            ok(true, "forge.capture.getImage was cancelled");
            start();
        });
    };
    askQuestion("In this test use the camera or gallery, but press back or cancel rather than choosing an image", { Ok: runTest });
});
