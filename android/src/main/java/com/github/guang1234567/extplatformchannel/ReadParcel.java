package com.github.guang1234567.extplatformchannel;

import java.nio.ByteBuffer;

public class ReadParcel {
    private ExtStandardMessageCodec mMessageCodec;

    private ByteBuffer mReadBuffer;

    ReadParcel(ExtStandardMessageCodec messageCodec, ByteBuffer readBuffer) {
        mMessageCodec = messageCodec;
        mReadBuffer = readBuffer;
    }

    public <T> T readValue() {
        return (T) mMessageCodec.readValue(mReadBuffer, null);
    }

    public <T, C> T readValue(FlutterParcelable.Creator<C> creator) {
        return (T) mMessageCodec.readValue(mReadBuffer, creator);
    }
}
