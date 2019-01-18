package com.github.guang1234567.extplatformchannel;

import java.util.List;

public interface FlutterParcelable {

    void writeToParcel(WriteParcel writeParcel);

    interface Creator<C> {

        public C createFromParcel(ReadParcel readParcel);
    }
}
