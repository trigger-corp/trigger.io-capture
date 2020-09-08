package io.trigger.forge.android.modules.capture;

import android.Manifest;
import android.content.ContentValues;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;

import androidx.core.content.FileProvider;

import com.llamalab.safs.Paths;

import java.io.File;
import java.io.IOException;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeFile;
import io.trigger.forge.android.core.ForgeIntentResultHandler;
import io.trigger.forge.android.core.ForgeStorage;
import io.trigger.forge.android.core.ForgeTask;

import static android.app.Activity.RESULT_CANCELED;
import static android.app.Activity.RESULT_OK;


public class API {

    private static String getApplicationName() {
        ApplicationInfo applicationInfo = ForgeApp.getActivity().getApplicationInfo();
        int stringId = applicationInfo.labelRes;
        return stringId == 0 ? applicationInfo.nonLocalizedLabel.toString()
                : ForgeApp.getActivity().getString(stringId);
    }

    public static void getImage(final ForgeTask task) {
        final int width = task.params.has("width") ? task.params.get("width").getAsInt() : 0;
        final int height = task.params.has("height") ? task.params.get("height").getAsInt() : 0;
        final String saveLocation = task.params.has("saveLocation") ? task.params.get("saveLocation").getAsString() : "file";

        String filename = ForgeStorage.temporaryFileNameWithExtension("jpg");
        ForgeFile forgeFile = new ForgeFile(ForgeStorage.EndpointId.Documents, filename);
        File temporaryFile = Paths.get(ForgeStorage.getNativeURL(forgeFile).getPath()).toFile();

        Uri uri = null;
        if (saveLocation.equalsIgnoreCase("gallery")) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.TITLE, filename);
            values.put(MediaStore.Images.ImageColumns.DESCRIPTION, API.getApplicationName());
            values.put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg");
            uri = ForgeApp.getActivity().getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
        } else {
            uri = FileProvider.getUriForFile(ForgeApp.getActivity(), ForgeApp.getFileProviderAuthority(), temporaryFile);
        }
        final Uri temporaryUri = uri;

        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        intent.putExtra(MediaStore.EXTRA_OUTPUT, temporaryUri);

        ForgeIntentResultHandler resultHandler = new ForgeIntentResultHandler() {
            @Override
            public void result(int requestCode, int resultCode, Intent data) {
                if (resultCode == RESULT_CANCELED) {
                    task.error("User cancelled image capture", "EXPECTED_FAILURE", null);
                    return;
                } else if (resultCode != RESULT_OK) {
                    task.error("Unknown error capturing image", "UNEXPECTED_FAILURE", null);
                    return;
                }

                ForgeFile forgeFile = null;
                try {
                    forgeFile = Storage.writeImageUriToTemporaryFile(temporaryUri, width, height);
                    if (temporaryFile.exists()) {
                        temporaryFile.delete();
                    }
                } catch (IOException e) {
                    task.error("Error saving image: " + e.getLocalizedMessage(), "UNEXPECTED_FAILURE", null);
                    return;
                }

                task.success(forgeFile.toScriptObject());
            }
        };

        task.withPermission(Manifest.permission.CAMERA, () -> {
            task.withPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, () -> {
                ForgeApp.intentWithHandler(intent, resultHandler);
            });
        });
    }


    public static void getVideo(final ForgeTask task) {
        final String saveLocation = task.params.has("saveLocation") ? task.params.get("saveLocation").getAsString() : "file";
        final String videoQuality = task.params.has("videoQuality") ? task.params.get("videoQuality").getAsString() : "default";

        Intent intent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);

        if (task.params.has("videoQuality") && task.params.get("videoQuality").getAsString().equalsIgnoreCase("low")) {
            intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 0);
        } else {
            intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 1);
        }

        if (task.params.has("videoDuration")) {
            intent.putExtra(MediaStore.EXTRA_DURATION_LIMIT, task.params.get("videoDuration").getAsInt());
        }

        ForgeIntentResultHandler resultHandler = new ForgeIntentResultHandler() {
            @Override
            public void result(int requestCode, int resultCode, Intent data) {
                if (resultCode == RESULT_CANCELED) {
                    task.error("User cancelled video capture", "EXPECTED_FAILURE", null);
                    return;
                } else if (resultCode != RESULT_OK) {
                    task.error("Unknown error capturing video", "UNEXPECTED_FAILURE", null);
                    return;
                }

                Uri uri = data.getData();
                if (uri == null) {
                    if (Build.VERSION.SDK_INT >= 18) {
                        // Bug in Nexus 4.3 devices (maybe other 4.3 devices so try this trick on all 4.3 devices that return null)
                        // https://code.google.com/p/android/issues/detail?id=57996
                        long max_val = 0;
                        Cursor cursor = ForgeApp.getActivity().getContentResolver().query(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, new String[]{"MAX(_id) as max_id"}, null, null, "_id");
                        if (cursor.moveToFirst()) {
                            max_val = cursor.getLong(cursor.getColumnIndex("max_id"));
                            uri = Uri.parse(MediaStore.Video.Media.EXTERNAL_CONTENT_URI.toString() + "/" + max_val);
                        }
                    }
                }

                if (uri == null) {
                    task.error("Unknown error capturing video", "UNEXPECTED_FAILURE", null);
                    return;
                }

                // TODOsave uri

                task.success(uri.toString());
            }
        };

        task.withPermission(Manifest.permission.CAMERA, () -> {
            task.withPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, () -> {
                ForgeApp.intentWithHandler(intent, resultHandler);
            });
        });
    }
}
