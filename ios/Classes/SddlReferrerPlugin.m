#import <Flutter/Flutter.h>

@interface SddlReferrerPlugin : NSObject<FlutterPlugin>
@end

@implementation SddlReferrerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel =
            [FlutterMethodChannel methodChannelWithName:@"sddl_referrer"
                                        binaryMessenger:[registrar messenger]];
    SddlReferrerPlugin* instance = [[SddlReferrerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getInstallReferrer" isEqualToString:call.method]) {
        result(@{}); // iOS: no-op
    } else {
        result(FlutterMethodNotImplemented);
    }
}
@end