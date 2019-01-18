#import "ExtPlatformChannelPlugin.h"
#import <ext_platform_channel/ext_platform_channel-Swift.h>

@implementation ExtPlatformChannelPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftExtPlatformChannelPlugin registerWithRegistrar:registrar];
}
@end
