/* global forge, module, asyncTest, start, ok, askQuestion */

module("forge.capture");


// permissions module native code has to be baked into the capture module to avoid app store rejections
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
                "read": "photos_read"
            },
            camera: {
                "read": "camera_read"
            },
            microphone: {
                "record": "microphone_record"
            },
        };
        function resolve(permission) {
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
            }, function () {
                ok(false, "API method returned failure");
                start();
            });
        };
        forge.permissions.check(forge.permissions.camera.read, function (allowed) {
            if (allowed) {
                ok(true, "Already have permission");
                start();
            } else {
                askQuestion("When prompted, deny the permission request", { Ok: runTest });
            }
        });

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
            }, function () {
                ok(false, "API method returned failure");
                start();
            });
        };
        askQuestion("If prompted, allow the permission request", { Ok: runTest });
    });
}


if (forge.file) {
    asyncTest("Select image from camera roll and check file info", 2, function() {
        var runTest = function () {
            forge.capture.getImage(function (file) {
                forge.file.info(file, function (info) {
                    ok(true, "file.info claims success");
                    askQuestion("Does the following file information describe the file: " +
                                JSON.stringify(info), {
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
            }, function (e) {
                ok(false, "API call failure: " + e.message);
                start();
            });
        };
        askQuestion("When prompted take a picture with the camera or select a file from the gallery", { Ok: runTest });
    });


    asyncTest("Saving camera output to Gallery", 1, function() {
        var runTest = function () {
            forge.capture.getImage({
                source: "camera",
                width: 100,
                height: 100
            }, function (file) {
                forge.file.URL(file, function (url) {
                    askQuestion("Is this your image:<br><img src='"+url+"' style='max-width: 100px; max-height: 100px'>", {
                        Yes: function () {
                            ok(true, "Success with forge.file.URL");
                            start();
                        },
                        No: function () {
                            ok(false, "User claims failure with forge.file.URL");
                            start();
                        }
                    });
                }, function (e) {
                    ok(false, "API call failure: "+e.message);
                    start();
                });
            }, function (e) {
                ok(false, "API call failure: "+e.message);
                start();
            });
        };
        askQuestion("When prompted take a picture with the camera", { Ok: runTest });
    });


    asyncTest("Camera", 5, function() {
        forge.capture.getImage({
            source: "camera",
            saveLocation: "file",
            width: 100,
            height: 100
        }, function (file) {
            askQuestion("Were you just prompted to use the camera?", {
                Yes: function () {
                    ok(true, "Success");
                    forge.file.isFile(file, function (is) {
                        if (is) {
                            ok(true, "forge.file.isFile is true");
                        } else {
                            ok(false, "forge.file.isFile is false");
                        }
                        forge.file.isFile(file, function (is) {
                            if (is) {
                                ok(true, "forge.file.isFile is true");
                            } else {
                                ok(false, "forge.file.isFile is false");
                            }
                            forge.file.URL(file, function (url) {
                                askQuestion("Is this your image:<br><img src='"+url+"' style='max-width: 100px; max-height: 100px'>", { Yes: function () {
                                    ok(true, "Success with forge.file.URL");
                                    forge.file.base64(file, function (data) {
                                        askQuestion("Is this also your image:<br><img src='data:image/jpg;base64,"+data+"' style='max-width: 100px; max-height: 100px'>", { Yes: function () {
                                            ok(true, "Success with forge.file.base64");
                                            start();

                                        }, No: function () {
                                            ok(false, "User claims failure with forge.file.base64");
                                            start();
                                        }});
                                    }, function (e) {
                                        ok(false, "API call failure: "+e.message);
                                        start();
                                    });
                                }, No: function () {
                                    ok(false, "User claims failure with forge.file.URL");
                                    start();
                                }});
                            }, function (e) {
                                ok(false, "API call failure: "+e.message);
                                start();
                            });
                        }, function (e) {
                            ok(false, "API call failure: "+e.message);
                            start();
                        });
                    }, function (e) {
                        ok(false, "API call failure: "+e.message);
                        start();
                    });

                },
                No: function () {
                    ok(false, "User claims failure");
                    start();
                }});
        }, function (e) {
            ok(false, "API call failure: "+e.message);
            start();
        });
    });

    asyncTest("Record a video with the camera and check file info", 2, function() {
        var runTest = function () {
            forge.capture.getVideo({
                source: "camera",
                videoQuality: "high"
            }, function (file) {
                forge.file.info(file, function (info) {
                    ok(true, "file.info claims success");
                    askQuestion("Does the following file information describe the file: " +
                                JSON.stringify(info), {
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
        askQuestion("Record a video", { Ok: runTest });
    });


    if (forge.is.ios()) {
        asyncTest("Select a video with low quality and check file info", 2, function() {
            var runTest = function () {
                forge.file.getVideo({
                    source: "gallery",
                    videoQuality: "low"
                }, function (file) {
                    forge.file.info(file, function (info) {
                        ok(true, "file.info claims success");
                        askQuestion("Is the file size smaller: " +
                                    JSON.stringify(info), {
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
            askQuestion("When prompted select the video you recorded from the gallery", { Ok: runTest });
        });
    }
}


if (forge.media && forge.file) {

    asyncTest("Camera Video Player", 1, function() {
        forge.capture.getVideo({
            source: "camera",
            videoDuration: 2
        }, function (file) {
            askQuestion("Was the video capture limited to 2 seconds?", {
                Yes: function () {
                    forge.file.URL(file, function (url) {
                        forge.media.videoPlay(url, function () {
                            askQuestion("Did your video just play?", {
                                Yes: function () {
                                    ok(true, "video capture successful");
                                    start();
                                },
                                No: function () {
                                    ok(false, "didn't play back just-captured video");
                                    start();
                                }
                            });
                        }, function (e) {
                            ok(false, "API call failure: "+e.message);
                            start();
                        });
                    }, function (e) {
                        ok(false, "API call failure: "+e.message);
                        start();
                    });
                },
                No: function () {
                    ok(false, "video wasn't limited to 2 seconds");
                    start();
                }
            });
        },	function (e) {
            ok(false, "API call failure: "+e.message);
            start();
        });
    });

}

asyncTest("Cancel", 1, function() {
    var runTest = function () {
        forge.capture.getImage(function () {
            ok(false, "forge.capture.getImage returned success");
            start();
        }, function (e) {
            ok(true, "API error callback: "+e.message);
            start();
        });
    };
    askQuestion("In this test use the camera or gallery, but press back or cancel rather than choosing an image", { Ok: runTest });
});


if (forge.file && forge.request) {
    var upload_url = "https://httpbin.org/post";

    asyncTest("Raw File upload", 1, function() {
        forge.capture.getVideo(function (file) {
            forge.request.ajax({
                url: upload_url,
                files: [file],
                fileUploadMethod: "raw",
                success: function (data) {
                    try {
                        data = JSON.parse(data);
                    } catch (e) {
                        forge.logging.error("Error parsing response: " + JSON.stringify(e));
                        ok(false);
                        start();
                        return;
                    }
                    forge.logging.log("Response: " + JSON.stringify(data.headers));
                    ok(true);
                    start();
                },
                progress: function (size) {
                    forge.logging.log(size.done + " of " + size.total);
                },
                error: function () {
                    ok(false, "Ajax error callback");
                    start();
                }
            });
        });
    });


    asyncTest("File upload", 1, function() {
        forge.capture.getVideo(function (file) {
            forge.request.ajax({
                url: upload_url,
                files: [file],
                success: function (data) {
                    try {
                        data = JSON.parse(data);
                    } catch (e) {
                        forge.logging.error("Error parsing response: " + JSON.stringify(e));
                        ok(false);
                        start();
                        return;
                    }
                    forge.logging.log("Response: " + JSON.stringify(data.headers));
                    ok(true);
                    start();
                },
                progress: function (size) {
                    forge.logging.log(size.done + " of " + size.total);
                },
                error: function () {
                    ok(false, "Ajax error callback");
                    start();
                }
            });
        });
    });
}
