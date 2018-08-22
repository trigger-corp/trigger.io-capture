package io.trigger.forge.android.modules.capture;

import android.os.Bundle;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeEventListener;

public class EventListener extends ForgeEventListener {
	@Override
	public void onCreate(Bundle savedInstanceState) {
		// initialize i8n strings
		API.io_trigger_dialog_capture_camera_description = ForgeApp.getActivity().getString(R.string.io_trigger_dialog_capture_camera_description);
		API.io_trigger_dialog_capture_source_camera = ForgeApp.getActivity().getString(R.string.io_trigger_dialog_capture_source_camera);
		API.io_trigger_dialog_capture_source_gallery = ForgeApp.getActivity().getString(R.string.io_trigger_dialog_capture_source_gallery);
		API.io_trigger_dialog_capture_pick_source = ForgeApp.getActivity().getString(R.string.io_trigger_dialog_capture_pick_source);
	}
}
