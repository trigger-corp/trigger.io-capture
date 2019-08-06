/* global forge, module, asyncTest, start, ok, askQuestion */

module("forge.capture");

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
            });
        };
        askQuestion("When prompted take a picture with the camera or select a file from the gallery", { Ok: runTest });
    });


    asyncTest("Record a video with the camera and check file info", 2, function() {
        var runTest = function () {
            forge.file.getVideo({
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
        askQuestion("When prompted select a video from the gallery", { Ok: runTest });
    });


    asyncTest("Saving camera output to Gallery", 1, function() {
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
    var upload_url = "http://httpbin.org/post";

    asyncTest("File upload", 1, function() {
        forge.capture.getVideo(function (file) {
            forge.request.ajax({
                url: upload_url,
                files: [file],
                success: function (data) {
                    data = JSON.parse(data);
                    forge.logging.log("Response: " + JSON.stringify(data.headers));
                    start();
                },
                error: function () {
                    ok(false, "Ajax error callback");
                    start();
                }
            });
        });
    });

    asyncTest("Raw File upload", 1, function() {
        forge.capture.getVideo(function (file) {
            forge.request.ajax({
                url: upload_url,
                files: [file],
                fileUploadMethod: "raw",
                success: function (data) {
                    data = JSON.parse(data);
                    forge.logging.log("Response: " + JSON.stringify(data.headers));
                    ok(true);
                    start();
                },
                error: function () {
                    ok(false, "Ajax error callback");
                    start();
                }
            });
        });
    });

}
