package com.github.guang1234567.extplatformchannel;

public abstract class MethodArgumentsCodec {

    private ExtStandardMessageCodec mMessageCodec;

    public MethodArgumentsCodec(ExtStandardMessageCodec messageCodec) {
        mMessageCodec = messageCodec;
    }

    public abstract void writeValue(String method, Object arguments, WriteParcel writeParcel);

    public abstract Object readValue(Object method, ReadParcel readParcel);
}
