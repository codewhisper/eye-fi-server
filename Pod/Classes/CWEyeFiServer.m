//
//  EyeFiServer.m
//  TPA
//
//  Created by Michael Litvak on 7/23/14.
//  Copyright (c) 2014 Robert Palmer. All rights reserved.
//

#import "CWEyeFiServer.h"
#import "CWEyeFiConnection.h"

static const UInt16 EYEFI_PORT = 59278;

@implementation CWEyeFiServer

- (id)initWithUploadKey:(NSString *)uploadKey {
    self = [super init];
    if (self) {
        _uploadKey = uploadKey;
        
        [self setType:@"_http._tcp."];
        [self setPort:EYEFI_PORT];
        [self setConnectionClass:[CWEyeFiConnection class]];
        
        // set documentRoot to Documents folder
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        self.documentRoot = basePath;
    }
    return self;
}

@end
