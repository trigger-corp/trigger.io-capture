package io.trigger.forge.android.modules.capture;

import android.Manifest;
import android.content.ContentValues;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.net.Uri;
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
        final int videoDuration = task.params.has("videoDuration") ? task.params.get("videoDuration").getAsInt() : 0;

        Intent intent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);

        if (videoQuality.equalsIgnoreCase("high")) {
            intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 1);
        } else if (videoQuality.equalsIgnoreCase("medium")) {
            intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 0);
        } else if (videoQuality.equalsIgnoreCase("low")) {
            intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 0);
        }

        if (videoDuration > 0) {
            intent.putExtra(MediaStore.EXTRA_DURATION_LIMIT, videoDuration);
        }

        String filename = ForgeStorage.temporaryFileNameWithExtension("mp4");
        ForgeFile forgeFile = new ForgeFile(ForgeStorage.EndpointId.Documents, filename);
        File temporaryFile = Paths.get(ForgeStorage.getNativeURL(forgeFile).getPath()).toFile();

        Uri uri = null;

        if (saveLocation.equalsIgnoreCase("gallery")) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.TITLE, filename);
            values.put(MediaStore.Images.ImageColumns.DESCRIPTION, API.getApplicationName());
            values.put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4");
            uri = ForgeApp.getActivity().getContentResolver().insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values);
        } else {
            uri = FileProvider.getUriForFile(ForgeApp.getActivity(), ForgeApp.getFileProviderAuthority(), temporaryFile);

        }

        final Uri temporaryUri = uri;
        intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);

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

                ForgeFile forgeFile = null;
                try {
                    forgeFile = Storage.writeVideoUriToTemporaryFile(temporaryUri, videoQuality);
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

    private static String getApplicationName() {
        ApplicationInfo applicationInfo = ForgeApp.getActivity().getApplicationInfo();
        int stringId = applicationInfo.labelRes;
        return stringId == 0 ? applicationInfo.nonLocalizedLabel.toString()
                : ForgeApp.getActivity().getString(stringId);
    }
}
