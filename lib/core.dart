part of ext_platform_channel;


typedef T ReadParcelConvertor<T>(ReadParcel readParcel);

/// interface
abstract class Parcelable {

    void writeToParcel(WriteParcel writeParcel);
}


class WriteParcel {

    final ExtStandardMessageCodec _messageCodec;

    final WriteBuffer _writeBuffer;

    WriteParcel._(this._messageCodec, this._writeBuffer);

    void writeValue<T>(T value) {
        _messageCodec.writeValue(_writeBuffer, value);
    }

}

class ReadParcel {

    final ExtStandardMessageCodec _messageCodec;

    final ReadBuffer _readBuffer;

    ReadParcel._(this._messageCodec, this._readBuffer);

    T readValue<T, C>({ReadParcelConvertor<C> covertor}) {
        return _messageCodec.readValue(_readBuffer, covertor: covertor);
    }

}

/// A codec for method calls and enveloped results.
///
/// All operations throw an exception, if conversion fails.
///
/// See also:
///
/// * [MethodChannel], which use [MethodCodec]s for communication
///   between Flutter and platform plugins.
/// * [EventChannel], which use [MethodCodec]s for communication
///   between Flutter and platform plugins.
abstract class ExtMethodCodec {
    /// Encodes the specified [methodCall] into binary.
    ByteData encodeMethodCall(MethodCall methodCall);

    /// Decodes the specified [methodCall] from binary.
    MethodCall decodeMethodCall(ByteData methodCall);

    /// Decodes the specified result [envelope] from binary.
    ///
    /// Throws [PlatformException], if [envelope] represents an error, otherwise
    /// returns the enveloped result.
    dynamic decodeEnvelope(String method, ByteData envelope);

    /// Encodes a successful [result] into a binary envelope.
    ByteData encodeSuccessEnvelope(String method, dynamic result);

    /// Encodes an error result into a binary envelope.
    ///
    /// The specified error [code], human-readable error [message], and error
    /// [details] correspond to the fields of [PlatformException].
    ByteData encodeErrorEnvelope(String method, {@required String code, String message, dynamic details});
}


abstract class MethodArgumentsCodec {

    final ExtStandardMessageCodec messageCodec;

    const MethodArgumentsCodec([this.messageCodec = const ExtStandardMessageCodec()]);

    void writeValue(String method, dynamic arguments, WriteParcel writeParcel);

    dynamic readValue(dynamic method, ReadParcel readParcel);
}


/// [MethodCodec] using the Flutter standard binary encoding.
///
/// The standard codec is guaranteed to be compatible with the corresponding
/// standard codec for FlutterMethodChannels on the host platform. These parts
/// of the Flutter SDK are evolved synchronously.
///
/// Values supported as method arguments and result payloads are those supported
/// by [StandardMessageCodec].
class ExtStandardMethodCodec implements ExtMethodCodec {
    // The codec method calls, and result envelopes as outlined below. This format
    // must match the Android and iOS counterparts.
    //
    // * Individual values are encoded using [StandardMessageCodec].
    // * Method calls are encoded using the concatenation of the encoding
    //   of the method name String and the arguments value.
    // * Reply envelopes are encoded using first a single byte to distinguish the
    //   success case (0) from the error case (1). Then follows:
    //   * In the success case, the encoding of the result value.
    //   * In the error case, the concatenation of the encoding of the error code
    //     string, the error message string, and the error details value.

    /// Creates a [MethodCodec] using the Flutter standard binary encoding.
    const ExtStandardMethodCodec({this.messageCodec = const ExtStandardMessageCodec(), this.argumentsCodec});

    /// The message codec that this method codec uses for encoding values.
    final ExtStandardMessageCodec messageCodec;

    final MethodArgumentsCodec argumentsCodec;

    @override
    ByteData encodeMethodCall(MethodCall call) {
        final WriteBuffer buffer = WriteBuffer();
        messageCodec.writeValue(buffer, call.method);
        //messageCodec.writeValue(buffer, call.arguments);
        if (argumentsCodec == null) {
            messageCodec.writeValue(buffer, call.arguments);
        } else {
            argumentsCodec.writeValue(call.method, call.arguments, new WriteParcel._(messageCodec, buffer));
        }
        return buffer.done();
    }

    @override
    MethodCall decodeMethodCall(ByteData methodCall) {
        final ReadBuffer buffer = ReadBuffer(methodCall);
        final dynamic method = messageCodec.readValue(buffer);
        //final dynamic arguments = messageCodec.readValue(buffer);
        dynamic arguments;
        if (argumentsCodec == null) {
            arguments = messageCodec.readValue(buffer);
        } else {
            arguments = argumentsCodec.readValue(method, new ReadParcel._(messageCodec, buffer));
        }
        if (method is String && !buffer.hasRemaining)
            return MethodCall(method, arguments);
        else
            throw const FormatException('Invalid method call');
    }

    @override
    ByteData encodeSuccessEnvelope(String method, dynamic result) {
        final WriteBuffer buffer = WriteBuffer();
        buffer.putUint8(0);
        //messageCodec.writeValue(buffer, result);
        if (argumentsCodec == null) {
            messageCodec.writeValue(buffer, result);
        } else {
            argumentsCodec.writeValue(method, result, new WriteParcel._(messageCodec, buffer));
        }
        return buffer.done();
    }

    @override
    ByteData encodeErrorEnvelope(String method, {@required String code, String message, dynamic details}) {
        final WriteBuffer buffer = WriteBuffer();
        buffer.putUint8(1);
        /*messageCodec.writeValue(buffer, code);
        messageCodec.writeValue(buffer, message);
        messageCodec.writeValue(buffer, details);*/
        if (argumentsCodec == null) {
            messageCodec.writeValue(buffer, code);
            messageCodec.writeValue(buffer, message);
            messageCodec.writeValue(buffer, details);
        } else {
            argumentsCodec.writeValue(method, code, new WriteParcel._(messageCodec, buffer));
            argumentsCodec.writeValue(method, message, new WriteParcel._(messageCodec, buffer));
            argumentsCodec.writeValue(method, details, new WriteParcel._(messageCodec, buffer));
        }
        return buffer.done();
    }

    @override
    dynamic decodeEnvelope(String method, ByteData envelope) {
        // First byte is zero in success case, and non-zero otherwise.
        if (envelope.lengthInBytes == 0)
            throw const FormatException('Expected envelope, got nothing');
        final ReadBuffer buffer = ReadBuffer(envelope);
        if (buffer.getUint8() == 0) {
            //return messageCodec.readValue(buffer);
            if (argumentsCodec == null) {
                return messageCodec.readValue(buffer);
            } else {
                return argumentsCodec.readValue(method, new ReadParcel._(messageCodec, buffer));
            }
        }

        /*final dynamic errorCode = messageCodec.readValue(buffer);
        final dynamic errorMessage = messageCodec.readValue(buffer);
        final dynamic errorDetails = messageCodec.readValue(buffer);*/
        dynamic errorCode;
        dynamic errorMessage;
        dynamic errorDetails;
        if (argumentsCodec == null) {
            errorCode = messageCodec.readValue(buffer);
            errorMessage = messageCodec.readValue(buffer);
            errorDetails = messageCodec.readValue(buffer);
        } else {
            errorCode = argumentsCodec.readValue(method, new ReadParcel._(messageCodec, buffer));
            errorMessage = argumentsCodec.readValue(method, new ReadParcel._(messageCodec, buffer));
            errorDetails = argumentsCodec.readValue(method, new ReadParcel._(messageCodec, buffer));
        }

        if (errorCode is String && (errorMessage == null || errorMessage is String) && !buffer.hasRemaining)
            throw PlatformException(code: errorCode, message: errorMessage, details: errorDetails);
        else
            throw const FormatException('Invalid envelope');
    }
}


/// [MessageCodec] using the Flutter standard binary encoding.
///
/// Supported messages are acyclic values of these forms:
///
///  * null
///  * [bool]s
///  * [num]s
///  * [String]s
///  * [Uint8List]s, [Int32List]s, [Int64List]s, [Float64List]s
///  * [List]s of supported values
///  * [Map]s from supported values to supported values
///
/// Decoded values will use `List<dynamic>` and `Map<dynamic, dynamic>`
/// irrespective of content.
///
/// On Android, messages are represented as follows:
///
///  * null: null
///  * [bool]\: `java.lang.Boolean`
///  * [int]\: `java.lang.Integer` for values that are representable using 32-bit
///    two's complement; `java.lang.Long` otherwise
///  * [double]\: `java.lang.Double`
///  * [String]\: `java.lang.String`
///  * [Uint8List]\: `byte[]`
///  * [Int32List]\: `int[]`
///  * [Int64List]\: `long[]`
///  * [Float64List]\: `double[]`
///  * [List]\: `java.util.ArrayList`
///  * [Map]\: `java.util.HashMap`
///
/// On iOS, messages are represented as follows:
///
///  * null: nil
///  * [bool]\: `NSNumber numberWithBool:`
///  * [int]\: `NSNumber numberWithInt:` for values that are representable using
///    32-bit two's complement; `NSNumber numberWithLong:` otherwise
///  * [double]\: `NSNumber numberWithDouble:`
///  * [String]\: `NSString`
///  * [Uint8List], [Int32List], [Int64List], [Float64List]\:
///    `FlutterStandardTypedData`
///  * [List]\: `NSArray`
///  * [Map]\: `NSDictionary`
///
/// The codec is extensible by subclasses overriding [writeValue] and
/// [readValueOfType].
class ExtStandardMessageCodec implements MessageCodec<dynamic> {
    /// Creates a [MessageCodec] using the Flutter standard binary encoding.
    const ExtStandardMessageCodec();

    // The codec serializes messages as outlined below. This format must
    // match the Android and iOS counterparts.
    //
    // * A single byte with one of the constant values below determines the
    //   type of the value.
    // * The serialization of the value itself follows the type byte.
    // * Numbers are represented using the host endianness throughout.
    // * Lengths and sizes of serialized parts are encoded using an expanding
    //   format optimized for the common case of small non-negative integers:
    //   * values 0..253 inclusive using one byte with that value;
    //   * values 254..2^16 inclusive using three bytes, the first of which is
    //     254, the next two the usual unsigned representation of the value;
    //   * values 2^16+1..2^32 inclusive using five bytes, the first of which is
    //     255, the next four the usual unsigned representation of the value.
    // * null, true, and false have empty serialization; they are encoded directly
    //   in the type byte (using _kNull, _kTrue, _kFalse)
    // * Integers representable in 32 bits are encoded using 4 bytes two's
    //   complement representation.
    // * Larger integers are encoded using 8 bytes two's complement
    //   representation.
    // * doubles are encoded using the IEEE 754 64-bit double-precision binary
    //   format.
    // * Strings are encoded using their UTF-8 representation. First the length
    //   of that in bytes is encoded using the expanding format, then follows the
    //   UTF-8 encoding itself.
    // * Uint8Lists, Int32Lists, Int64Lists, and Float64Lists are encoded by first
    //   encoding the list's element count in the expanding format, then the
    //   smallest number of zero bytes needed to align the position in the full
    //   message with a multiple of the number of bytes per element, then the
    //   encoding of the list elements themselves, end-to-end with no additional
    //   type information, using two's complement or IEEE 754 as applicable.
    // * Lists are encoded by first encoding their length in the expanding format,
    //   then follows the recursive encoding of each element value, including the
    //   type byte (Lists are assumed to be heterogeneous).
    // * Maps are encoded by first encoding their length in the expanding format,
    //   then follows the recursive encoding of each key/value pair, including the
    //   type byte for both (Maps are assumed to be heterogeneous).
    static const int _valueNull = 0;
    static const int _valueTrue = 1;
    static const int _valueFalse = 2;
    static const int _valueInt32 = 3;
    static const int _valueInt64 = 4;
    static const int _valueLargeInt = 5;
    static const int _valueFloat64 = 6;
    static const int _valueString = 7;
    static const int _valueUint8List = 8;
    static const int _valueInt32List = 9;
    static const int _valueInt64List = 10;
    static const int _valueFloat64List = 11;
    static const int _valueList = 12;
    static const int _valueMap = 13;
    static const int _valueParcelable = 14;

    @override
    ByteData encodeMessage(dynamic message) {
        if (message == null)
            return null;
        final WriteBuffer buffer = WriteBuffer();
        writeValue(buffer, message);
        return buffer.done();
    }

    @override
    dynamic decodeMessage(ByteData message) {
        if (message == null)
            return null;
        final ReadBuffer buffer = ReadBuffer(message);
        final dynamic result = readValue(buffer);
        if (buffer.hasRemaining)
            throw const FormatException('Message corrupted');
        return result;
    }

    /// Writes [value] to [buffer] by first writing a type discriminator
    /// byte, then the value itself.
    ///
    /// This method may be called recursively to serialize container values.
    ///
    /// Type discriminators 0 through 127 inclusive are reserved for use by the
    /// base class.
    ///
    /// The codec can be extended by overriding this method, calling super
    /// for values that the extension does not handle. Type discriminators
    /// used by extensions must be greater than or equal to 128 in order to avoid
    /// clashes with any later extensions to the base class.
    void writeValue(WriteBuffer buffer, dynamic value) {
        if (value == null) {
            buffer.putUint8(_valueNull);
        } else if (value is bool) {
            buffer.putUint8(value ? _valueTrue : _valueFalse);
        } else if (value is int) {
            if (-0x7fffffff - 1 <= value && value <= 0x7fffffff) {
                buffer.putUint8(_valueInt32);
                buffer.putInt32(value);
            } else {
                buffer.putUint8(_valueInt64);
                buffer.putInt64(value);
            }
        } else if (value is double) {
            buffer.putUint8(_valueFloat64);
            buffer.putFloat64(value);
        } else if (value is String) {
            buffer.putUint8(_valueString);
            final List<int> bytes = utf8.encoder.convert(value);
            writeSize(buffer, bytes.length);
            buffer.putUint8List(bytes);
        } else if (value is Uint8List) {
            buffer.putUint8(_valueUint8List);
            writeSize(buffer, value.length);
            buffer.putUint8List(value);
        } else if (value is Int32List) {
            buffer.putUint8(_valueInt32List);
            writeSize(buffer, value.length);
            buffer.putInt32List(value);
        } else if (value is Int64List) {
            buffer.putUint8(_valueInt64List);
            writeSize(buffer, value.length);
            buffer.putInt64List(value);
        } else if (value is Float64List) {
            buffer.putUint8(_valueFloat64List);
            writeSize(buffer, value.length);
            buffer.putFloat64List(value);
        } else if (value is List) {
            buffer.putUint8(_valueList);
            writeSize(buffer, value.length);
            for (final dynamic item in value) {
                writeValue(buffer, item);
            }
        } else if (value is Map) {
            buffer.putUint8(_valueMap);
            writeSize(buffer, value.length);
            value.forEach((dynamic key, dynamic value) {
                writeValue(buffer, key);
                writeValue(buffer, value);
            });
        } else if (value is Parcelable) {
            buffer.putUint8(_valueParcelable);
            value.writeToParcel(new WriteParcel._(this, buffer));
        } else {
            throw ArgumentError.value(value);
        }
    }

    /// Reads a value from [buffer] as written by [writeValue].
    ///
    /// This method is intended for use by subclasses overriding
    /// [readValueOfType].
    T readValue<T, C>(ReadBuffer buffer, {ReadParcelConvertor<C> covertor}) {
        if (!buffer.hasRemaining)
            throw const FormatException('Message corrupted');
        final int type = buffer.getUint8();
        return readValueOfType(type, buffer, covertor: covertor);
    }

    /// Reads a value of the indicated [type] from [buffer].
    ///
    /// The codec can be extended by overriding this method, calling super
    /// for types that the extension does not handle.
    T readValueOfType<T, C>(int type, ReadBuffer buffer, {ReadParcelConvertor<C> covertor}) {
        dynamic result;
        switch (type) {
            case _valueNull:
                result = null;
                break;
            case _valueTrue:
                result = true;
                break;
            case _valueFalse:
                result = false;
                break;
            case _valueInt32:
                result = buffer.getInt32();
                break;
            case _valueInt64:
                result = buffer.getInt64();
                break;
            case _valueLargeInt:
            // Flutter Engine APIs to use large ints have been deprecated on
            // 2018-01-09 and will be made unavailable.
            // TODO(mravn): remove this case once the APIs are unavailable.
                final int length = readSize(buffer);
                final String hex = utf8.decoder.convert(buffer.getUint8List(length));
                result = int.parse(hex, radix: 16);
                break;
            case _valueFloat64:
                result = buffer.getFloat64();
                break;
            case _valueString:
                final int length = readSize(buffer);
                result = utf8.decoder.convert(buffer.getUint8List(length));
                break;
            case _valueUint8List:
                final int length = readSize(buffer);
                result = buffer.getUint8List(length);
                break;
            case _valueInt32List:
                final int length = readSize(buffer);
                result = buffer.getInt32List(length);
                break;
            case _valueInt64List:
                final int length = readSize(buffer);
                result = buffer.getInt64List(length);
                break;
            case _valueFloat64List:
                final int length = readSize(buffer);
                result = buffer.getFloat64List(length);
                break;
            case _valueList:
                final int length = readSize(buffer);
                result = List<C>(length);
                for (int i = 0; i < length; i++) {
                    result[i] = readValue<C, C>(buffer, covertor: covertor);
                }
                break;
            case _valueMap:
                final int length = readSize(buffer);
                result = <C, C>{};
                for (int i = 0; i < length; i++) {
                    result[readValue(buffer, covertor: covertor)] = readValue(buffer, covertor: covertor);
                }
                break;
            case _valueParcelable:
                ArgumentError.checkNotNull(covertor, "ReadParcelConvertor");
                result = covertor(new ReadParcel._(this, buffer));
                break;
            default:
                throw const FormatException('Message corrupted');
        }

        return result;
    }

    /// Writes a non-negative 32-bit integer [value] to [buffer]
    /// using an expanding 1-5 byte encoding that optimizes for small values.
    ///
    /// This method is intended for use by subclasses overriding
    /// [writeValue].
    void writeSize(WriteBuffer buffer, int value) {
        assert(0 <= value && value <= 0xffffffff);
        if (value < 254) {
            buffer.putUint8(value);
        } else if (value <= 0xffff) {
            buffer.putUint8(254);
            buffer.putUint16(value);
        } else {
            buffer.putUint8(255);
            buffer.putUint32(value);
        }
    }

    /// Reads a non-negative int from [buffer] as written by [writeSize].
    ///
    /// This method is intended for use by subclasses overriding
    /// [readValueOfType].
    int readSize(ReadBuffer buffer) {
        final int value = buffer.getUint8();
        switch (value) {
            case 254:
                return buffer.getUint16();
            case 255:
                return buffer.getUint32();
            default:
                return value;
        }
    }
}


/// A named channel for communicating with platform plugins using asynchronous
/// method calls.
///
/// Method calls are encoded into binary before being sent, and binary results
/// received are decoded into Dart values. The [MethodCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a method channel counterpart of this channel on the
/// platform side. The Dart type of arguments and results is `dynamic`,
/// but only values supported by the specified [MethodCodec] can be used.
/// The use of unsupported values should be considered programming errors, and
/// will result in exceptions being thrown. The null value is supported
/// for all codecs.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
///
/// See: <https://flutter.io/platform-channels/>
class ExtMethodChannel {
    /// Creates a [MethodChannel] with the specified [name].
    ///
    /// The [codec] used will be [StandardMethodCodec], unless otherwise
    /// specified.
    ///
    /// Neither [name] nor [codec] may be null.
    const ExtMethodChannel(this.name, [this.codec = const ExtStandardMethodCodec()]);

    /// The logical channel on which communication happens, not null.
    final String name;

    /// The message codec used by this channel, not null.
    final ExtMethodCodec codec;

    /// Invokes a [method] on this channel with the specified [arguments].
    ///
    /// The static type of [arguments] is `dynamic`, but only values supported by
    /// the [codec] of this channel can be used. The same applies to the returned
    /// result. The values supported by the default codec and their platform-specific
    /// counterparts are documented with [StandardMessageCodec].
    ///
    /// Returns a [Future] which completes to one of the following:
    ///
    /// * a result (possibly null), on successful invocation;
    /// * a [PlatformException], if the invocation failed in the platform plugin;
    /// * a [MissingPluginException], if the method has not been implemented by a
    ///   platform plugin.
    ///
    /// The following code snippets demonstrate how to invoke platform methods
    /// in Dart using a MethodChannel and how to implement those methods in Java
    /// (for Android) and Objective-C (for iOS).
    ///
    /// {@tool sample}
    ///
    /// The code might be packaged up as a musical plugin, see
    /// <https://flutter.io/developing-packages/>:
    ///
    /// ```dart
    /// class Music {
    ///   static const MethodChannel _channel = MethodChannel('music');
    ///
    ///   static Future<bool> isLicensed() async {
    ///     // invokeMethod returns a Future<dynamic>, and we cannot pass that for
    ///     // a Future<bool>, hence the indirection.
    ///     final bool result = await _channel.invokeMethod('isLicensed');
    ///     return result;
    ///   }
    ///
    ///   static Future<List<Song>> songs() async {
    ///     // invokeMethod here returns a Future<dynamic> that completes to a
    ///     // List<dynamic> with Map<dynamic, dynamic> entries. Post-processing
    ///     // code thus cannot assume e.g. List<Map<String, String>> even though
    ///     // the actual values involved would support such a typed container.
    ///     final List<dynamic> songs = await _channel.invokeMethod('getSongs');
    ///     return songs.map(Song.fromJson).toList();
    ///   }
    ///
    ///   static Future<void> play(Song song, double volume) async {
    ///     // Errors occurring on the platform side cause invokeMethod to throw
    ///     // PlatformExceptions.
    ///     try {
    ///       await _channel.invokeMethod('play', <String, dynamic>{
    ///         'song': song.id,
    ///         'volume': volume,
    ///       });
    ///     } on PlatformException catch (e) {
    ///       throw 'Unable to play ${song.title}: ${e.message}';
    ///     }
    ///   }
    /// }
    ///
    /// class Song {
    ///   Song(this.id, this.title, this.artist);
    ///
    ///   final String id;
    ///   final String title;
    ///   final String artist;
    ///
    ///   static Song fromJson(dynamic json) {
    ///     return Song(json['id'], json['title'], json['artist']);
    ///   }
    /// }
    /// ```
    /// {@end-tool}
    ///
    /// {@tool sample}
    ///
    /// Java (for Android):
    ///
    /// ```java
    /// // Assumes existence of an Android MusicApi.
    /// public class MusicPlugin implements MethodCallHandler {
    ///   @Override
    ///   public void onMethodCall(MethodCall call, Result result) {
    ///     switch (call.method) {
    ///       case "isLicensed":
    ///         result.success(MusicApi.checkLicense());
    ///         break;
    ///       case "getSongs":
    ///         final List<MusicApi.Track> tracks = MusicApi.getTracks();
    ///         final List<Object> json = ArrayList<>(tracks.size());
    ///         for (MusicApi.Track track : tracks) {
    ///           json.add(track.toJson()); // Map<String, Object> entries
    ///         }
    ///         result.success(json);
    ///         break;
    ///       case "play":
    ///         final String song = call.argument("song");
    ///         final double volume = call.argument("volume");
    ///         try {
    ///           MusicApi.playSongAtVolume(song, volume);
    ///           result.success(null);
    ///         } catch (MusicalException e) {
    ///           result.error("playError", e.getMessage(), null);
    ///         }
    ///         break;
    ///       default:
    ///         result.notImplemented();
    ///     }
    ///   }
    ///   // Other methods elided.
    /// }
    /// ```
    /// {@end-tool}
    ///
    /// {@tool sample}
    ///
    /// Objective-C (for iOS):
    ///
    /// ```objectivec
    /// @interface MusicPlugin : NSObject<FlutterPlugin>
    /// @end
    ///
    /// // Assumes existence of an iOS Broadway Play Api.
    /// @implementation MusicPlugin
    /// - (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    ///   if ([@"isLicensed" isEqualToString:call.method]) {
    ///     result([NSNumber numberWithBool:[BWPlayApi isLicensed]]);
    ///   } else if ([@"getSongs" isEqualToString:call.method]) {
    ///     NSArray* items = [BWPlayApi items];
    ///     NSMutableArray* json = [NSMutableArray arrayWithCapacity:items.count];
    ///     for (BWPlayItem* item in items) {
    ///       [json addObject:@{@"id":item.itemId, @"title":item.name, @"artist":item.artist}];
    ///     }
    ///     result(json);
    ///   } else if ([@"play" isEqualToString:call.method]) {
    ///     NSString* itemId = call.arguments[@"song"];
    ///     NSNumber* volume = call.arguments[@"volume"];
    ///     NSError* error = nil;
    ///     BOOL success = [BWPlayApi playItem:itemId volume:volume.doubleValue error:&error];
    ///     if (success) {
    ///       result(nil);
    ///     } else {
    ///       result([FlutterError errorWithCode:[NSString stringWithFormat:@"Error %ld", error.code]
    ///                                  message:error.domain
    ///                                  details:error.localizedDescription]);
    ///     }
    ///   } else {
    ///     result(FlutterMethodNotImplemented);
    ///   }
    /// }
    /// // Other methods elided.
    /// @end
    /// ```
    /// {@end-tool}
    ///
    /// See also:
    ///
    /// * [StandardMessageCodec] which defines the payload values supported by
    ///   [StandardMethodCodec].
    /// * [JSONMessageCodec] which defines the payload values supported by
    ///   [JSONMethodCodec].
    /// * <https://docs.flutter.io/javadoc/io/flutter/plugin/common/MethodCall.html>
    ///   for how to access method call arguments on Android.
    Future<dynamic> invokeMethod(String method, [dynamic arguments]) async {
        assert(method != null);
        final dynamic result = await BinaryMessages.send(
            name,
            codec.encodeMethodCall(MethodCall(method, arguments)),
            );
        if (result == null)
            throw MissingPluginException('No implementation found for method $method on channel $name');
        return codec.decodeEnvelope(method, result);
    }

    /// Sets a callback for receiving method calls on this channel.
    ///
    /// The given callback will replace the currently registered callback for this
    /// channel, if any. To remove the handler, pass null as the
    /// `handler` argument.
    ///
    /// If the future returned by the handler completes with a result, that value
    /// is sent back to the platform plugin caller wrapped in a success envelope
    /// as defined by the [codec] of this channel. If the future completes with
    /// a [PlatformException], the fields of that exception will be used to
    /// populate an error envelope which is sent back instead. If the future
    /// completes with a [MissingPluginException], an empty reply is sent
    /// similarly to what happens if no method call handler has been set.
    /// Any other exception results in an error envelope being sent.
    void setMethodCallHandler(Future<dynamic> handler(MethodCall call)) {
        BinaryMessages.setMessageHandler(
            name,
            handler == null ? null : (ByteData message) => _handleAsMethodCall(message, handler),
            );
    }

    /// Sets a mock callback for intercepting method invocations on this channel.
    ///
    /// The given callback will replace the currently registered mock callback for
    /// this channel, if any. To remove the mock handler, pass null as the
    /// `handler` argument.
    ///
    /// Later calls to [invokeMethod] will result in a successful result,
    /// a [PlatformException] or a [MissingPluginException], determined by how
    /// the future returned by the mock callback completes. The [codec] of this
    /// channel is used to encode and decode values and errors.
    ///
    /// This is intended for testing. Method calls intercepted in this manner are
    /// not sent to platform plugins.
    ///
    /// The provided `handler` must return a `Future` that completes with the
    /// return value of the call. The value will be encoded using
    /// [MethodCodec.encodeSuccessEnvelope], to act as if platform plugin had
    /// returned that value.
    void setMockMethodCallHandler(Future<dynamic> handler(MethodCall call)) {
        BinaryMessages.setMockMessageHandler(
            name,
            handler == null ? null : (ByteData message) => _handleAsMethodCall(message, handler),
            );
    }

    Future<ByteData> _handleAsMethodCall(ByteData message, Future<dynamic> handler(MethodCall call)) async {
        final MethodCall call = codec.decodeMethodCall(message);
        try {
            return codec.encodeSuccessEnvelope(call.method, await handler(call));
        } on PlatformException catch (e) {
            return codec.encodeErrorEnvelope(
                call.method,
                code: e.code,
                message: e.message,
                details: e.details,
                );
        } on MissingPluginException {
            return null;
        } catch (e) {
            return codec.encodeErrorEnvelope(call.method, code: 'error', message: e.toString(), details: null);
        }
    }
}