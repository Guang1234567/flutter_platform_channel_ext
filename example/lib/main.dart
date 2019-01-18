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
