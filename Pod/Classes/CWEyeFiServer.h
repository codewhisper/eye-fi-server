//
//  EyeFiServer.h
//  TPA
//
//  Created by Michael Litvak on 7/23/14.
//  Copyright (c) 2014 Robert Palmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPServer.h"

typedef enum {
    FileStatusUploading,
    FileStatusReady
} FileStatus;

static NSString *CWNotificationFileStatus = @"com.codewhisper.EyeFiServer.FileStatusNotification";

@interface CWEyeFiServer : HTTPServer

@property NSString *uploadKey;

- (id)initWithUploadKey:(NSString *)uploadKey;

@end
