package com.github.guang1234567.extplatformchannel;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class ExtPlatformChannelPlugin implements MethodCallHandler {

    public static void registerWith(Registrar registrar) {
    }

    @Override
    public void onMethodCall(MethodCall methodCall, Result result) {
        result.notImplemented();
    }
}
