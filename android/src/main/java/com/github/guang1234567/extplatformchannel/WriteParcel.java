package com.github.guang1234567.extplatformchannel;

import java.io.ByteArrayOutputStream;

public class WriteParcel {

    private ExtStandardMessageCodec mMessageCodec;

    private ByteArrayOutputStream mStream;

    WriteParcel(ExtStandardMessageCodec messageCodec, ByteArrayOutputStream stream) {
        mMessageCodec = messageCodec;
        mStream = stream;
    }

    public <T> void writeValue(T value) {
        mMessageCodec.writeValue(mStream, value);
    }
}
