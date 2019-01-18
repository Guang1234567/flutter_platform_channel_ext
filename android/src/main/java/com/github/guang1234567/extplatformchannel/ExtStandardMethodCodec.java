package com.github.guang1234567.extplatformchannel;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodCodec;
import io.flutter.plugin.common.StandardMessageCodec;


/**
 * A {@link MethodCodec} using the Flutter standard binary encoding.
 *
 * <p>This codec is guaranteed to be compatible with the corresponding
 * <a href="https://docs.flutter.io/flutter/services/StandardMethodCodec-class.html">StandardMethodCodec</a>
 * on the Dart side. These parts of the Flutter SDK are evolved synchronously.</p>
 *
 * <p>Values supported as method arguments and result payloads are those supported by
 * {@link StandardMessageCodec}.</p>
 */
public final class ExtStandardMethodCodec implements ExtMethodCodec {

    private final ExtStandardMessageCodec messageCodec;

    private final MethodArgumentsCodec argumentsCodec;

    /**
     * Creates a new method codec based on the specified message codec.
     */
    public ExtStandardMethodCodec(ExtStandardMessageCodec messageCodec, MethodArgumentsCodec argumentsCodec) {
        this.messageCodec = messageCodec;
        this.argumentsCodec = argumentsCodec;
    }

    @Override
    public ByteBuffer encodeMethodCall(MethodCall methodCall) {
        final ExtStandardMessageCodec.ExposedByteArrayOutputStream stream = new ExtStandardMessageCodec.ExposedByteArrayOutputStream();
        messageCodec.writeValue(stream, methodCall.method);
        //messageCodec.writeValue(stream, methodCall.arguments);
        if (argumentsCodec == null) {
            messageCodec.writeValue(stream, methodCall.arguments);
        } else {
            argumentsCodec.writeValue(methodCall.method, methodCall.arguments, new WriteParcel(messageCodec, stream));
        }
        final ByteBuffer buffer = ByteBuffer.allocateDirect(stream.size());
        buffer.put(stream.buffer(), 0, stream.size());
        return buffer;
    }

    @Override
    public MethodCall decodeMethodCall(ByteBuffer methodCall) {
        methodCall.order(ByteOrder.nativeOrder());
        final Object method = messageCodec.readValue(methodCall);
        //final Object arguments = messageCodec.readValue(methodCall);
        Object arguments = null;
        if (argumentsCodec == null) {
            arguments = messageCodec.readValue(methodCall);
        } else {
            arguments = argumentsCodec.readValue(method, new ReadParcel(messageCodec, methodCall));
        }

        if (method instanceof String && !methodCall.hasRemaining()) {
            return new MethodCall((String) method, arguments);
        }
        throw new IllegalArgumentException("Method call corrupted");
    }

    @Override
    public ByteBuffer encodeSuccessEnvelope(String method, Object result) {
        final ExtStandardMessageCodec.ExposedByteArrayOutputStream stream = new ExtStandardMessageCodec.ExposedByteArrayOutputStream();
        stream.write(0);
        //messageCodec.writeValue(stream, result);
        if (argumentsCodec == null) {
            messageCodec.writeValue(stream, result);
        } else {
            argumentsCodec.writeValue(method, result, new WriteParcel(messageCodec, stream));
        }
        final ByteBuffer buffer = ByteBuffer.allocateDirect(stream.size());
        buffer.put(stream.buffer(), 0, stream.size());
        return buffer;
    }

    @Override
    public ByteBuffer encodeErrorEnvelope(String method, String errorCode, String errorMessage,
                                          Object errorDetails) {
        final ExtStandardMessageCodec.ExposedByteArrayOutputStream stream = new ExtStandardMessageCodec.ExposedByteArrayOutputStream();
        stream.write(1);
        /*messageCodec.writeValue(stream, errorCode);
        messageCodec.writeValue(stream, errorMessage);
        messageCodec.writeValue(stream, errorDetails);*/
        if (argumentsCodec == null) {
            messageCodec.writeValue(stream, errorCode);
            messageCodec.writeValue(stream, errorMessage);
            messageCodec.writeValue(stream, errorDetails);
        } else {
            argumentsCodec.writeValue(method, errorCode, new WriteParcel(messageCodec, stream));
            argumentsCodec.writeValue(method, errorMessage, new WriteParcel(messageCodec, stream));
            argumentsCodec.writeValue(method, errorDetails, new WriteParcel(messageCodec, stream));
        }
        final ByteBuffer buffer = ByteBuffer.allocateDirect(stream.size());
        buffer.put(stream.buffer(), 0, stream.size());
        return buffer;
    }

    @Override
    public Object decodeEnvelope(String method, ByteBuffer envelope) {
        envelope.order(ByteOrder.nativeOrder());
        final byte flag = envelope.get();
        switch (flag) {
            case 0: {
                //final Object result = messageCodec.readValue(envelope);
                Object result = null;
                if (argumentsCodec == null) {
                    result = messageCodec.readValue(envelope);
                } else {
                    result = argumentsCodec.readValue(method, new ReadParcel(messageCodec, envelope));
                }
                if (!envelope.hasRemaining()) {
                    return result;
                }
            }
            // Falls through intentionally.
            case 1: {
                /*final Object code = messageCodec.readValue(envelope);
                final Object message = messageCodec.readValue(envelope);
                final Object details = messageCodec.readValue(envelope);*/
                Object code = null;
                Object message = null;
                Object details = null;
                if (argumentsCodec == null) {
                    code = messageCodec.readValue(envelope);
                    message = messageCodec.readValue(envelope);
                    details = messageCodec.readValue(envelope);
                } else {
                    code = argumentsCodec.readValue(method, new ReadParcel(messageCodec, envelope));
                    message = argumentsCodec.readValue(method, new ReadParcel(messageCodec, envelope));
                    details = argumentsCodec.readValue(method, new ReadParcel(messageCodec, envelope));
                }


                if (code instanceof String
                        && (message == null || message instanceof String)
                        && !envelope.hasRemaining()) {
                    throw new FlutterException((String) code, (String) message, details);
                }
            }
        }
        throw new IllegalArgumentException("Envelope corrupted");
    }
}
