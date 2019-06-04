#import "PhotosLibraryPlugin.h"
@import Photos;

static NSString *const PhotosLibraryPluginChannelName = @"flutter.yang.me/photos_library";

@interface PHAsset (FlutterObject)
- (NSDictionary *)assetDictionary;
@end

@interface PhotosLibraryPlugin ()
@property (nonatomic, readwrite, strong) NSObject<FlutterBinaryMessenger>* messenger;
@end

@implementation PhotosLibraryPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:PhotosLibraryPluginChannelName
                                     binaryMessenger:[registrar messenger]];
    
    PhotosLibraryPlugin* instance = [[PhotosLibraryPlugin alloc] init];
    instance.messenger = registrar.messenger;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (BOOL)handlePlatformVersion:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
        return TRUE;
    }
    return FALSE;
}

- (BOOL)handleAuthorizationStatus:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([@"getAuthorizationStatus" isEqualToString:call.method]) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        result(@(status));
        return TRUE;
    }
    return FALSE;
}

- (BOOL)handleRequestAuthorization:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([@"requestAuthorization" isEqualToString:call.method]) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            result(@(status));
        }];
        return TRUE;
    }
    return FALSE;
}

- (BOOL)handleFetchMediaWithType:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([@"fetchMediaWithType" isEqualToString:call.method]) {
        if(call.arguments && [call.arguments isKindOfClass:[NSArray class]]) {
            NSArray* arguments = call.arguments;
            if(1 == arguments.count) {
                NSNumber *typeN = arguments[0];
                int type = typeN.intValue;
                PHAssetMediaType mediaType = PHAssetMediaTypeUnknown;
                switch (type) {
                    case 1:
                        mediaType = PHAssetMediaTypeImage;
                        break;
                    case 2:
                        mediaType = PHAssetMediaTypeVideo;
                        break;
                    case 0:
                    default:
                        // cannot handle unknown type
                        break;
                }
                if(PHAssetMediaTypeUnknown != mediaType) {
                    PHFetchResult<PHAsset *>* fetchedResults = [PHAsset fetchAssetsWithMediaType:mediaType options:nil];
                    NSMutableArray* assets = [NSMutableArray arrayWithCapacity:fetchedResults.count];
                    for (PHAsset* asset in fetchedResults) {
                        [assets addObject:asset.assetDictionary];
                    }
                    result([assets copy]);
                    return TRUE;
                }
            }
        }
        // Not correct arguments
        result(FlutterMethodNotImplemented);
        return TRUE;
    }
    return FALSE;
}

- (BOOL)handleRequestThumbnail:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([@"requestThumbnail" isEqualToString:call.method]) {
        if(call.arguments && [call.arguments isKindOfClass:[NSArray class]]) {
            NSArray* arguments = call.arguments;
            if(3 == arguments.count) {
                if([arguments[0] isKindOfClass:[NSString class]]) {
                    NSString *identifier = arguments[0];
                    int width = -1;
                    int height = -1;
                    if([arguments[1] isKindOfClass:[NSNumber class]]) {
                        NSNumber* widthN = arguments[1];
                        width = widthN.intValue;
                    }
                    else {
                        width = 200;
                    }
                    if([arguments[2] isKindOfClass:[NSNumber class]]) {
                        NSNumber* heightN = arguments[2];
                        height = heightN.intValue;
                    }
                    else {
                        height = 200;
                    }
                    CGSize size = CGSizeMake(width * 1.0f, height * 1.0f);
                    PHFetchResult<PHAsset *> * results = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
                    if (results.count > 0) {
                        PHAsset* asset = results[0];
                        PHImageRequestOptions* options = [PHImageRequestOptions new];
                        options.version = PHImageRequestOptionsVersionCurrent;
                        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
                        options.resizeMode = PHImageRequestOptionsResizeModeFast;
                        options.networkAccessAllowed = NO;
                        PHImageRequestID ID = [PHImageManager.defaultManager requestImageForAsset:asset
                                                                                       targetSize:size
                                                                                      contentMode:PHImageContentModeAspectFill
                                                                                          options:options
                                                                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                                                        NSString *channelName = [PhotosLibraryPluginChannelName stringByAppendingFormat:@"/image/%@", identifier];
                                                                                        NSData *imageData = UIImagePNGRepresentation(result);
                                                                                        [self.messenger sendOnChannel:channelName message:imageData];
                                                                                    }];
                        if(PHInvalidImageRequestID != ID) {
                            result(@YES);
                            return TRUE;
                        }
                    }
                }
            }
        }
        result(@NO);
        return TRUE;
    }
    return FALSE;
}


- (void)requestVideoPath:(FlutterMethodCall*)call withCompletion:(void (^)(NSString *resultVideoPath))block{
    if([@"requestVideoPath" isEqualToString:call.method]) {
        if (@available(iOS 9.0, *)) {
            
            
            if(call.arguments && [call.arguments isKindOfClass:[NSArray class]]) {
                NSArray* arguments = call.arguments;
                if([arguments[0] isKindOfClass:[NSString class]]) {
                    NSString *identifier = arguments[0];
                    
                    PHFetchResult<PHAsset *> * results = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
                    
                    if (results.count > 0) {
                        PHAsset* asset = results[0];
                        PHVideoRequestOptions* options = [PHVideoRequestOptions new];
                        options.version = PHVideoRequestOptionsVersionOriginal;
                        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                        options.networkAccessAllowed = YES;
                        
                        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler: ^(AVAsset * _Nullable avasset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info)
                         {
                             NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];
                             NSString *filename = ((PHAssetResource*)resources[0]).originalFilename;
                             
                             NSString *pathToWrite = [NSTemporaryDirectory() stringByAppendingString:filename];
                             NSURL *localpath = [NSURL fileURLWithPath:pathToWrite];
                             PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
                             options.networkAccessAllowed = YES;
                             
                             NSFileManager *fileManager = [NSFileManager defaultManager];
                             
                             if ([fileManager fileExistsAtPath:pathToWrite]){
                                 NSLog(@"Yes file is there");
                                 
                                 NSFileManager *fileManager = [NSFileManager defaultManager];
                                 NSError *error;
                                 BOOL success = [fileManager removeItemAtPath:pathToWrite error:&error];
                                 if (success) {
                                     
                                     NSLog(@"File Deleted");
                                     [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resources[0] toFile:localpath options:options completionHandler:^(NSError * _Nullable error) {
                                         if (error) {
                                             //                                     [Sys MyLog: [NSString stringWithFormat:@"Failed to write a resource: %@",[error localizedDescription]]];
                                         }
                                         
                                         block(localpath.absoluteString);
                                     }];
                                 }
                                 else
                                 {
                                     NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
                                 }
                                 
                             }
                             else {
                                 NSLog(@"File is not there");
                                 [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resources[0] toFile:localpath options:options completionHandler:^(NSError * _Nullable error) {
                                     if (error) {
                                         //                                     [Sys MyLog: [NSString stringWithFormat:@"Failed to write a resource: %@",[error localizedDescription]]];
                                     }
                                     
                                     block(localpath.absoluteString);
                                 }];
                             }
                             
                             
                             
                         }];
                        
                        
                        
                    }
                }
                
            }
            
        }
        
        
    }
    
}

-(BOOL)deleteFilePath:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    if([@"deleteFilePath" isEqualToString:call.method]) {
        if(call.arguments && [call.arguments isKindOfClass:[NSArray class]]) {
            NSArray* arguments = call.arguments;
            if([arguments[0] isKindOfClass:[NSString class]]) {
                NSString *fileToDelete = arguments[0];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:fileToDelete]){
                    NSLog(@"Yes file is there");
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSError *error;
                    BOOL success = [fileManager removeItemAtPath:fileToDelete error:&error];
                    if (success) {
                        NSLog(@"File Deleted");
                        result(@YES);
                        return success;
                    }
                    else
                    {
                        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
                        result(@NO);
                        return FALSE;
                    }
                }
            }
        }
    }
    
    
    return FALSE;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([self handlePlatformVersion:call result:result]) {
        
    }
    else if([self handleAuthorizationStatus:call result:result]) {
        
    }
    else if([self handleRequestAuthorization:call result:result]) {
        
    }
    else if([self handleFetchMediaWithType:call result:result]) {
        
    }
    else if([self handleRequestThumbnail:call result:result]) {
        
    }
    else if([call.method isEqualToString:@"requestVideoPath"]) {
        [self requestVideoPath:call withCompletion:^(NSString *videoPath) {
            
            videoPath = [videoPath stringByReplacingOccurrencesOfString:@"file:///"
                                                 withString:@"/"];
            result(videoPath);
        }];
    }
    else if([self deleteFilePath:call result:result]) {
        
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

@end

@implementation PHAsset(FlutterObject)
- (NSDictionary *)assetDictionary
{
    return @{
             @"identifier": self.localIdentifier,
             @"width": @(self.pixelWidth),
             @"height": @(self.pixelHeight),
             @"type": @(self.mediaType),
             @"subtype": @(self.mediaSubtypes),
             @"sourcetype": @(self.sourceType),
             };
}
@end
