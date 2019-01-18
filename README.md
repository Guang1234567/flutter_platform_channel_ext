# ext_platform_channel

&quot;Flutter plugin : flutter platform channel extension.&quot;

## Getting Started

`io.flutter.plugin.common.StandardMessageCodec` in Flutter cannot serialize the instance of class that like  `Class People` below:

```java
class People implements FlutterParcelable {

    int age;
    String name;
    List<People> children;


    People(int age, String name, List<People> children) {
        this.age = age;
        this.name = name;
        this.children = children;
    }

    People(ReadParcel readParcel) {
        age = readParcel.readValue(); // 普通类型直接 readValue
        name = readParcel.readValue();
        children = readParcel.readValue(CREATOR); // 如果是 List<? extends Parcelable> 类型, 那么 readValue 要这种形式
    }

    public void writeToParcel(WriteParcel writeParcel) {
        writeParcel.writeValue(age);
        writeParcel.writeValue(name);
        writeParcel.writeValue(children);
    }

    public static final Creator<People> CREATOR = new Creator<People>() {
        @Override
        public People createFromParcel(ReadParcel readParcel) {
            return new People(readParcel);
        }
    };


    @Override
    public String toString() {
        return "People{" +
                "age=" + age +
                ", name='" + name + '\'' +
                ", children=" + children +
                '}';
    }
}
```


But `com.github.guang1234567.extplatformchannel.ExtStandardMessageCodec` can solve this problem.
Its Sprite is from Android's `android.os.Parcelable`
See below code.

Note: ios is not support!!! Only aavailable between Android and Flutter.



```dart

// flutter part


// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ext_platform_channel/ext_platform_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 要把 People 这种自定义的复合类型序列化反序列化, 需要 implements Parcelable.
class People implements Parcelable {

    int age;
    String name;
    List<People> children;


    People(this.age, this.name, this.children);

    People.readFromParcel(ReadParcel readParcel) {
        age = readParcel.readValue(); // 普通类型直接 readValue
        name = readParcel.readValue();
        children = readParcel.readValue<List<People>, People>(covertor: createFromParcel); // 如果是 List<? extends Parcelable> 类型, 那么 readValue 要这种形式
    }

    void writeToParcel(WriteParcel writeParcel) {
        writeParcel.writeValue(age);
        writeParcel.writeValue(name);
        writeParcel.writeValue(children);
    }

    static People createFromParcel(ReadParcel readParcel) {
        return new People.readFromParcel(readParcel);
    }

    @override
    String toString() {
        return 'People{age: $age, name: $name, children: $children}';
    }
}

class DemoMethodArgumentsCodec extends MethodArgumentsCodec {

    const DemoMethodArgumentsCodec() : super();

    void writeValue(String method, dynamic arguments, WriteParcel writeParcel) {
        writeParcel.writeValue(arguments);
    }

    dynamic readValue(dynamic method, ReadParcel readParcel) {
        if ("getBatteryLevel" == method) {
            return readParcel.readValue<People, People>(covertor: People.createFromParcel);
        }
        return readParcel.readValue();
    }
}

class PlatformChannel extends StatefulWidget {
    @override
    _PlatformChannelState createState() => _PlatformChannelState();
}

class _PlatformChannelState extends State<PlatformChannel> {


    static const ExtMethodChannel methodChannel =
    ExtMethodChannel('samples.flutter.io/battery', const ExtStandardMethodCodec(argumentsCodec: const DemoMethodArgumentsCodec()));


    static const EventChannel eventChannel =
    EventChannel('samples.flutter.io/charging');
    StreamSubscription _receiveBroadcastStream;


    String _batteryLevel = 'Battery level: unknown.';
    String _chargingStatus = 'Battery status: unknown.';

    People providePeopleForArgs() {
        List<People> rootChildren = [];
        People root = new People(100, "dart_root", rootChildren);

        List<People> child_01_Children = [];
        People child_01 = new People(90, "child_01", child_01_Children);
        rootChildren.add(child_01);

        List<People> child_02_Children = [];
        People child_02 = new People(91, "child_02", child_02_Children);
        rootChildren.add(child_02);

        List<People> child_01_01_Children = [];
        People child_01_01 = new People(81, "child_01_01", child_01_01_Children);
        child_01_Children.add(child_01_01);

        List<People> child_01_02_Children = [];
        People child_01_02 = new People(82, "child_01_02", child_01_02_Children);
        child_01_Children.add(child_01_02);

        List<People> child_02_01_Children = [];
        People child_02_01 = new People(83, "child_02_01", child_02_01_Children);
        child_02_Children.add(child_02_01);

        List<People> child_02_02_Children = [];
        People child_02_02 = new People(84, "child_02_02", child_02_02_Children);
        child_02_Children.add(child_02_02);

        return root;
    }

    Future<void> _getBatteryLevel() async {
        String batteryLevel;
        try {
            //final int result = await methodChannel.invokeMethod('getBatteryLevel');
            final People result = await methodChannel.invokeMethod('getBatteryLevel', providePeopleForArgs());
            print("Flutter_Side : ${result.toString()}");
            batteryLevel = 'Battery level: $result%.';
        } on PlatformException {
            batteryLevel = 'Failed to get battery level.';
        }
        setState(() {
            _batteryLevel = batteryLevel;
        });
    }

    @override
    void initState() {
        super.initState();
        _receiveBroadcastStream = eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    }

    @override
    void dispose() {
        _receiveBroadcastStream.cancel();
    }


    void _onEvent(Object event) {
        setState(() {
            _chargingStatus =
            "Battery status: ${event == 'charging' ? '' : 'dis'}charging.";
        });
    }

    void _onError(Object error) {
        setState(() {
            _chargingStatus = 'Battery status: unknown.';
        });
    }

    @override
    Widget build(BuildContext context) {
        return Material(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            Text(_batteryLevel, key: const Key('Battery level label')),
                            Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: RaisedButton(
                                    child: const Text('Refresh'),
                                    onPressed: _getBatteryLevel,
                                    ),
                                ),
                        ],
                        ),
                    Text(_chargingStatus),
                ],
                ),
            );
    }
}

void main() {
    runApp(MaterialApp(home: PlatformChannel()));
}


```




```java

//android part

package com.example.platformchannel;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.util.Log;

import com.github.guang1234567.extplatformchannel.ExtMethodChannel;
import com.github.guang1234567.extplatformchannel.ExtStandardMessageCodec;
import com.github.guang1234567.extplatformchannel.ExtStandardMethodCodec;
import com.github.guang1234567.extplatformchannel.FlutterParcelable;
import com.github.guang1234567.extplatformchannel.MethodArgumentsCodec;
import com.github.guang1234567.extplatformchannel.ReadParcel;
import com.github.guang1234567.extplatformchannel.WriteParcel;

import java.util.LinkedList;
import java.util.List;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String BATTERY_CHANNEL = "samples.flutter.io/battery";
    private static final String CHARGING_CHANNEL = "samples.flutter.io/charging";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        GeneratedPluginRegistrant.registerWith(this);

        new EventChannel(getFlutterView(), CHARGING_CHANNEL).setStreamHandler(
                new StreamHandler() {
                    private BroadcastReceiver chargingStateChangeReceiver;

                    @Override
                    public void onListen(Object arguments, EventSink events) {
                        chargingStateChangeReceiver = createChargingStateChangeReceiver(events);
                        registerReceiver(
                                chargingStateChangeReceiver, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        unregisterReceiver(chargingStateChangeReceiver);
                        chargingStateChangeReceiver = null;
                    }
                }
        );


        ExtStandardMessageCodec messageCodec = new ExtStandardMessageCodec();
        ExtStandardMethodCodec methodCodec = new ExtStandardMethodCodec(messageCodec, new DemoMethodArgumentsCodec(messageCodec));

        new ExtMethodChannel(getFlutterView(), BATTERY_CHANNEL, methodCodec).setMethodCallHandler(
                new ExtMethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, ExtMethodChannel.Result result) {
                        if (call.method.equals("getBatteryLevel")) {
                            int batteryLevel = getBatteryLevel();

                            Log.d("Android_Side", call.arguments.toString());

                            if (batteryLevel != -1) {
                                //result.success(batteryLevel);
                                result.success(providePeopleForArgs());
                            } else {
                                result.error("UNAVAILABLE", "Battery level not available.", null);
                            }
                        } else {
                            result.notImplemented();
                        }
                    }
                }
        );
    }

    private BroadcastReceiver createChargingStateChangeReceiver(final EventSink events) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                int status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1);

                if (status == BatteryManager.BATTERY_STATUS_UNKNOWN) {
                    events.error("UNAVAILABLE", "Charging status unavailable", null);
                } else {
                    boolean isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                            status == BatteryManager.BATTERY_STATUS_FULL;
                    events.success(isCharging ? "charging" : "discharging");
                }
            }
        };
    }

    private int getBatteryLevel() {
        if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            BatteryManager batteryManager = (BatteryManager) getSystemService(BATTERY_SERVICE);
            return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
        } else {
            Intent intent = new ContextWrapper(getApplicationContext()).
                    registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
            return (intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100) /
                    intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
        }
    }

    People providePeopleForArgs() {
        List<People> rootChildren = new LinkedList<>();
        People root = new People(100, "java_root", rootChildren);

        List<People> child_01_Children = new LinkedList<>();
        People child_01 = new People(90, "child_01", child_01_Children);
        rootChildren.add(child_01);

        List<People> child_02_Children = new LinkedList<>();
        People child_02 = new People(91, "child_02", child_02_Children);
        rootChildren.add(child_02);

        List<People> child_01_01_Children = new LinkedList<>();
        People child_01_01 = new People(81, "child_01_01", child_01_01_Children);
        child_01_Children.add(child_01_01);

        List<People> child_01_02_Children = new LinkedList<>();
        People child_01_02 = new People(82, "child_01_02", child_01_02_Children);
        child_01_Children.add(child_01_02);

        List<People> child_02_01_Children = new LinkedList<>();
        People child_02_01 = new People(83, "child_02_01", child_02_01_Children);
        child_02_Children.add(child_02_01);

        List<People> child_02_02_Children = new LinkedList<>();
        People child_02_02 = new People(84, "child_02_02", child_02_02_Children);
        child_02_Children.add(child_02_02);

        return root;
    }
}


class DemoMethodArgumentsCodec extends MethodArgumentsCodec {

    DemoMethodArgumentsCodec(ExtStandardMessageCodec messageCodec) {
        super(messageCodec);
    }

    public void writeValue(String method, Object arguments, WriteParcel writeParcel) {
        writeParcel.writeValue(arguments);
    }

    public Object readValue(Object method, ReadParcel readParcel) {
        if ("getBatteryLevel".equals(method)) {
            return readParcel.readValue(People.CREATOR);
        }
        return readParcel.readValue();
    }
}

class People implements FlutterParcelable {

    int age;
    String name;
    List<People> children;


    People(int age, String name, List<People> children) {
        this.age = age;
        this.name = name;
        this.children = children;
    }

    People(ReadParcel readParcel) {
        age = readParcel.readValue(); // 普通类型直接 readValue
        name = readParcel.readValue();
        children = readParcel.readValue(CREATOR); // 如果是 List<? extends Parcelable> 类型, 那么 readValue 要这种形式
    }

    public void writeToParcel(WriteParcel writeParcel) {
        writeParcel.writeValue(age);
        writeParcel.writeValue(name);
        writeParcel.writeValue(children);
    }

    public static final Creator<People> CREATOR = new Creator<People>() {
        @Override
        public People createFromParcel(ReadParcel readParcel) {
            return new People(readParcel);
        }
    };


    @Override
    public String toString() {
        return "People{" +
                "age=" + age +
                ", name='" + name + '\'' +
                ", children=" + children +
                '}';
    }
}



```
