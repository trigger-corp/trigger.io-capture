package io.trigger.forge.android.modules.capture;

import io.trigger.forge.android.core.ForgeActivity;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeFile;
import io.trigger.forge.android.core.ForgeIntentResultHandler;
import io.trigger.forge.android.core.ForgeTask;

import android.Manifest;
import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.DialogInterface;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import androidx.core.content.FileProvider;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.text.SimpleDateFormat;
import java.util.Date;

import static android.app.Activity.RESULT_CANCELED;
import static android.app.Activity.RESULT_OK;

public class API {
    // i8n strings
    public static String io_trigger_dialog_capture_camera_description;
    public static String io_trigger_dialog_capture_source_camera;
    public static String io_trigger_dialog_capture_source_gallery;
    public static String io_trigger_dialog_capture_pick_source;

    public static void getImage(final ForgeTask task) {
        final Runnable camera = new Runnable() {
            @Override
            public void run() {
                ForgeApp.getActivity().requestPermission(Manifest.permission.CAMERA, new ForgeActivity.EventAccessBlock() {
                    @Override
                    public void run(boolean granted) {
                        if (!granted) {
                            task.error("Permission denied. User didn't grant access to camera.", "EXPECTED_FAILURE", null);
                            return;
                        }
                        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                        // define the file-name to save photo taken by Camera
                        // activity
                        String fileName = String.valueOf(new java.util.Date().getTime()) + ".jpg";
                        // create parameters for Intent with filename
                        Uri imageUri = null;
                        String tmpReturnUri = null;
                        if (task.params.has("saveLocation") && task.params.get("saveLocation").getAsString().equals("file")) {
                            java.io.File dir = null;
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
                                dir = ForgeApp.getActivity().getExternalFilesDir(Environment.DIRECTORY_PICTURES);
                            }
                            if (dir == null) {
                                dir = Environment.getExternalStorageDirectory();
                                dir = new java.io.File(dir, "Android/data/" + ForgeApp.getActivity().getApplicationContext().getPackageName() + "/files/");
                            }
                            dir.mkdirs();
                            java.io.File file = new java.io.File(dir, fileName);
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                imageUri = FileProvider.getUriForFile(ForgeApp.getActivity(), ForgeApp.getFileProviderAuthority(), file);
                            } else {
                                imageUri = Uri.fromFile(file);
                            }
                            tmpReturnUri = imageUri.toString();
                        } else {
                            ContentValues values = new ContentValues();
                            values.put(MediaStore.MediaColumns.TITLE, fileName);
                            values.put(MediaStore.Images.ImageColumns.DESCRIPTION, io_trigger_dialog_capture_camera_description);
                            values.put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg");
                            imageUri = ForgeApp.getActivity().getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
                            tmpReturnUri = imageUri.toString();
                        }

                        final String returnUri = tmpReturnUri;
                        intent.putExtra(MediaStore.EXTRA_OUTPUT, imageUri);

                        ForgeIntentResultHandler handler = new ForgeIntentResultHandler() {
                            @Override
                            public void result(int requestCode, int resultCode, Intent data) {
                                if (resultCode == RESULT_OK) {
                                    task.success(returnUri);
                                } else if (resultCode == RESULT_CANCELED) {
                                    task.error("User cancelled image capture", "EXPECTED_FAILURE", null);
                                } else {
                                    task.error("Unknown error capturing image", "UNEXPECTED_FAILURE", null);
                                }
                            }
                        };
                        ForgeApp.intentWithHandler(intent, handler);
                    }
                });
            }
        };

        final Runnable gallery = new Runnable() {
            @Override
            public void run() {
                ForgeApp.getActivity().requestPermission("com.google.android.apps.photos.permission.GOOGLE_PHOTOS", new ForgeActivity.EventAccessBlock() {
                    @Override
                    public void run(boolean granted) {
                        // TODO ignore 'granted' as not all devices have this permission and there does not seem to be a way to check for it
                        Intent intent = new Intent(Intent.ACTION_PICK);
                        intent.setType("image/*");
                        ForgeIntentResultHandler handler = new ForgeIntentResultHandler() {
                            @Override
                            public void result(int requestCode, int resultCode, Intent data) {

                                if (resultCode == RESULT_OK) {
                                    Uri uri = data.getData();
                                    // crosswalk has issues accessing google photos image content :-/
                                    if (!ForgeApp.getActivity().isCrosswalk()) {
                                        task.success(ForgeFile.fixImageUri(data.getData()).toString());
                                        return;
                                    } else if (!uri.toString().startsWith("content://com.google.android.apps.photos.contentprovider")) {
                                        task.success(ForgeFile.fixImageUri(data.getData()).toString());
                                        return;
                                    }
                                    // If this file comes from Google Photos we to need to cache it locally
                                    // as Marshmallow's braindead permissions model won't let it be used
                                    // Crosswalk.
                                    String filename = "temp_forge_file_image_" + (new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()));
                                    File output = null;
                                    try {
                                        output = File.createTempFile(filename, "");
                                        FileInputStream input = (FileInputStream) ForgeApp.getActivity().getContentResolver().openInputStream(uri);
                                        FileChannel src = input.getChannel();
                                        FileChannel dst = new FileOutputStream(output).getChannel();
                                        dst.transferFrom(src, 0, src.size());
                                        src.close();
                                        dst.close();
                                        task.success(Uri.fromFile(output).toString());
                                    } catch (IOException e) {
                                        task.error("Error retrieving video: " + e.getLocalizedMessage(), "UNEXPECTED_FAILURE", null);
                                    }

                                } else if (resultCode == RESULT_CANCELED) {
                                    task.error("User cancelled image capture", "EXPECTED_FAILURE", null);
                                } else {
                                    task.error("Unknown error capturing image", "UNEXPECTED_FAILURE", null);
                                }
                            }
                        };
                        ForgeApp.intentWithHandler(intent, handler);
                    }
                });
            }
        };

        ForgeApp.getActivity().requestPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, new ForgeActivity.EventAccessBlock() {
            @Override
            public void run(boolean granted) {
                if (!granted) {
                    task.error("Permission denied. User didn't grant access to storage.", "EXPECTED_FAILURE", null);
                    return;
                }
                final DialogInterface.OnClickListener clickListener = new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int item) {
                        switch (item) {
                            case 0:
                                camera.run();
                                break;
                            case 1:
                            default:
                                gallery.run();
                                break;
                        }
                    }
                };
                final DialogInterface.OnCancelListener cancelListener = new DialogInterface.OnCancelListener() {
                    @Override
                    public void onCancel(DialogInterface dialog) {
                        task.error("User cancelled image capture", "EXPECTED_FAILURE", null);
                    }
                };

                if (task.params.has("source") && task.params.get("source").getAsString().equals("camera")) {
                    clickListener.onClick(null, 0);
                } else if (task.params.has("source") && task.params.get("source").getAsString().equals("gallery")) {
                    clickListener.onClick(null, 1);
                } else {
                    task.performUI(new Runnable() {
                        @Override
                        public void run() {
                            final CharSequence[] items = {io_trigger_dialog_capture_source_camera, io_trigger_dialog_capture_source_gallery};
                            AlertDialog.Builder builder = new AlertDialog.Builder(ForgeApp.getActivity());
                            builder.setTitle(io_trigger_dialog_capture_pick_source);
                            builder.setItems(items, clickListener);
                            builder.setCancelable(true);
                            builder.setOnCancelListener(cancelListener);
                            AlertDialog alert = builder.create();
                            alert.show();
                        }
                    });
                }

            }
        });
    }

    public static void getVideo(final ForgeTask task) {
        final Runnable camera = new Runnable() {
            @Override
            public void run() {
                ForgeApp.getActivity().requestPermission(Manifest.permission.CAMERA, new ForgeActivity.EventAccessBlock() {
                    @Override
                    public void run(boolean granted) {
                        if (!granted) {
                            task.error("Permission denied. User didn't grant access to camera.", "EXPECTED_FAILURE", null);
                            return;
                        }
                        Intent intent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);
                        if (task.params.has("videoQuality") && task.params.get("videoQuality").getAsString().equalsIgnoreCase("low")) {
                            intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 0);
                        } else {
                            intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 1);
                        }
                        if (task.params.has("videoDuration")) {
                            intent.putExtra(MediaStore.EXTRA_DURATION_LIMIT, task.params.get("videoDuration").getAsInt());
                        }


                        ForgeIntentResultHandler handler = new ForgeIntentResultHandler() {
                            @Override
                            public void result(int requestCode, int resultCode, Intent data) {
                                if (resultCode == RESULT_OK) {
                                    if (data.getData() == null) {
                                        if (Build.VERSION.SDK_INT >= 18) {
                                            // Bug in Nexus 4.3 devices (maybe other 4.3 devices so try this trick on all 4.3 devices that return null)
                                            // https://code.google.com/p/android/issues/detail?id=57996
                                            long max_val = 0;
                                            Cursor cursor = ForgeApp.getActivity().getContentResolver().query(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, new String[]{"MAX(_id) as max_id"}, null, null, "_id");
                                            if (cursor.moveToFirst()) {
                                                max_val = cursor.getLong(cursor.getColumnIndex("max_id"));
                                                task.success(MediaStore.Video.Media.EXTERNAL_CONTENT_URI.toString() + "/" + max_val);
                                                return;
                                            }
                                        } else {
                                            task.error("Unknown error capturing video", "UNEXPECTED_FAILURE", null);
                                        }
                                    } else {
                                        task.success(data.getData().toString());
                                    }
                                } else if (resultCode == RESULT_CANCELED) {
                                    task.error("User cancelled video capture", "EXPECTED_FAILURE", null);
                                } else {
                                    task.error("Unknown error capturing video", "UNEXPECTED_FAILURE", null);
                                }
                            }
                        };
                        ForgeApp.intentWithHandler(intent, handler);
                    }
                });
            }
        };

        final Runnable gallery = new Runnable() {
            @Override
            public void run() {
                ForgeApp.getActivity().requestPermission("com.google.android.apps.photos.permission.GOOGLE_PHOTOS", new ForgeActivity.EventAccessBlock() {
                    @Override
                    public void run(boolean granted) {
                        // TODO ignore 'granted' as not all devices have this permission and there does not seem to be a way to check for it
                        Intent intent = new Intent(Intent.ACTION_PICK);
                        intent.setType("video/*");
                        ForgeIntentResultHandler handler = new ForgeIntentResultHandler() {
                            @Override
                            public void result(int requestCode, int resultCode, Intent data) {
                                if (resultCode == RESULT_OK) {
                                    // check if we need to transcode the video
                                    String videoQuality = task.params.has("videoQuality") ? task.params.get("videoQuality").getAsString() : "default";
                                    if (!videoQuality.equalsIgnoreCase("default")) {
                                        // TODO transcode video once min API level hits 18 and we can rely on MediaCodec being present
                                    }

                                    Uri uri = data.getData();
                                    if (!uri.toString().startsWith("content://com.google.android.apps.photos.contentprovider")) {
                                        task.success(data.toUri(0));
                                        return;
                                    }

                                    // If this file comes from Google Photos we to need to cache it locally
                                    // as Marshmallow's braindead permissions model won't let it be used
                                    // by external intents.
                                    String filename = "temp_forge_file_video_" + (new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()));
                                    File output = null;
                                    try {
                                        output = File.createTempFile(filename, "mp4");
                                        FileInputStream input = (FileInputStream) ForgeApp.getActivity().getContentResolver().openInputStream(uri);
                                        FileChannel src = input.getChannel();
                                        FileChannel dst = new FileOutputStream(output).getChannel();
                                        dst.transferFrom(src, 0, src.size());
                                        src.close();
                                        dst.close();
                                        task.success(Uri.fromFile(output).toString());
                                    } catch (IOException e) {
                                        task.error("Error retrieving video: " + e.getLocalizedMessage(), "UNEXPECTED_FAILURE", null);
                                    }
                                } else if (resultCode == RESULT_CANCELED) {
                                    task.error("User cancelled video capture", "EXPECTED_FAILURE", null);
                                } else {
                                    task.error("Unknown error capturing video", "UNEXPECTED_FAILURE", null);
                                }
                            }
                        };
                        ForgeApp.intentWithHandler(intent, handler);
                    }
                });
            }
        };

        ForgeApp.getActivity().requestPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, new ForgeActivity.EventAccessBlock() {
            @Override
            public void run(boolean granted) {
                if (!granted) {
                    task.error("Permission denied. User didn't grant access to storage.", "EXPECTED_FAILURE", null);
                    return;
                }
                final DialogInterface.OnClickListener clickListener = new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int item) {
                        Intent intent;
                        switch (item) {
                            case 0:
                                camera.run();
                                break;
                            case 1:
                            default:
                                gallery.run();
                                break;
                        }
                    }
                };

                if (task.params.has("source") && task.params.get("source").getAsString().equals("camera")) {
                    clickListener.onClick(null, 0);
                } else if (task.params.has("source") && task.params.get("source").getAsString().equals("gallery")) {
                    clickListener.onClick(null, 1);
                } else {
                    task.performUI(new Runnable() {
                        @Override
                        public void run() {
                            final CharSequence[] items = {io_trigger_dialog_capture_source_camera, io_trigger_dialog_capture_source_gallery};
                            AlertDialog.Builder builder = new AlertDialog.Builder(ForgeApp.getActivity());
                            builder.setTitle(io_trigger_dialog_capture_pick_source);
                            builder.setItems(items, clickListener);
                            builder.setCancelable(false);
                            AlertDialog alert = builder.create();
                            alert.show();
                        }
                    });
                }
            }
        });

    }

}
