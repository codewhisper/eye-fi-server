//
//  EyeFiConnection.m
//  EyeFiServer
//
//  Created by Michael Litvak on 7/22/14.
//  Copyright (c) 2014 codewhisper. All rights reserved.
//

#import "CWEyeFiConnection.h"
#import "CWEyeFiParser.h"
#import "CWEyeFiServer.h"

#import "HTTPFileResponse.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "MultipartMessageHeaderField.h"

#import "NSData+EyeFi.h"
#import "NSString+EyeFi.h"

#import "Brett.h"

@implementation CWEyeFiConnection {
    MultipartFormDataParser *_parser;
    NSData *_postData;
    
    NSFileHandle *_storeFile;
    NSString *_storeFilePath;
    NSMutableArray *_uploadedFiles;
    
    NSString *_uploadDir;
}

- (id)init {
    self = [super init];
    if (self) {
        _uploadDir = @"camera1";
    }
    return self;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    if ([method isEqualToString:@"POST"]) {
        if ([path isEqualToString:@"/api/soap/eyefilm/v1"]) {
            return YES;
        }
        
        if ([path isEqualToString:@"/api/soap/eyefilm/v1/upload"]) {
            return YES;
        }
    }
    
    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path {
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/api/soap/eyefilm/v1/upload"]) {
        NSString *contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if (paramsSeparator == NSNotFound) {
            return NO;
        }
        
        if (paramsSeparator >= contentType.length - 1) {
            return NO;
        }
        
        NSString *type = [contentType substringToIndex:paramsSeparator];
        if (![type isEqualToString:@"multipart/form-data"]) {
            return NO;
        }
        
        NSArray *params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for (NSString *param in params) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if (paramsSeparator == NSNotFound || paramsSeparator >= param.length - 1) {
                continue;
            }
            
            NSString *paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString *paramValue = [param substringFromIndex:paramsSeparator+1];
            
            if ([paramName isEqualToString:@"boundary"]) {
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        
        if (![request headerField:@"boundary"]) {
            return NO;
        }
        
        return YES;
    }
    
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/api/soap/eyefilm/v1/upload"]) {
        
        NSData *responseData = [[NSString stringWithFormat:[CWEyeFiConnection stringForTemplate:@"UploadPhotoResponse"],
                                 @"true"] dataUsingEncoding:NSUTF8StringEncoding];
        
        return [[HTTPDataResponse alloc] initWithData:responseData];
        
    } else if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/api/soap/eyefilm/v1"]) {
        CWEyeFiParser *eyeFiParser = [[CWEyeFiParser alloc] initWithData:_postData];
        [eyeFiParser parseData];
        
#ifdef DEBUG
        NSLog(@"%@", eyeFiParser.method);
#endif
        
        if ([eyeFiParser.method isEqualToString:@"StartSession"]) {
            
            NSString *credential = [self credentialFromMacaddress:[eyeFiParser.values objectForKey:@"macaddress"]
                                                            nonce:[eyeFiParser.values objectForKey:@"cnonce"]];
            NSString *snonce = [NSString randomStringWithLength:32];
            NSString *transfermode = [NSString stringWithFormat:@"%@", [eyeFiParser.values objectForKey:@"transfermode"]];
            NSString *transfermodetimestamp = [NSString stringWithFormat:@"%@", [eyeFiParser.values objectForKey:@"transfermodetimestamp"]];
            
            NSString *responseString = [NSString stringWithFormat:[CWEyeFiConnection stringForTemplate:@"StartSessionResponse"],
                                        credential,
                                        snonce,
                                        transfermode,
                                        transfermodetimestamp,
                                        @"false"
                                        ];
            
            NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            
            return [[HTTPDataResponse alloc] initWithData:responseData];
            
        } else if ([eyeFiParser.method isEqualToString:@"GetPhotoStatus"]) {
            
            NSData *responseData = [[NSString stringWithFormat:[CWEyeFiConnection stringForTemplate:@"GetPhotoStatusResponse"],
                                     @"1", // fileid
                                     @"0" // cnonce
                                     ] dataUsingEncoding:NSUTF8StringEncoding];
            
            return [[HTTPDataResponse alloc] initWithData:responseData];
            
        } else if ([eyeFiParser.method isEqualToString:@"MarkLastPhotoInRoll"]) {
            
            NSData *responseData = [[CWEyeFiConnection stringForTemplate:@"MarkLastPhotoInRollResponse"] dataUsingEncoding:NSUTF8StringEncoding];
            
            return [[HTTPDataResponse alloc] initWithData:responseData];
        }
    }
    
    return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength {
    NSString* boundary = [request headerField:@"boundary"];
    _parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    _parser.delegate = self;
}

- (void)processBodyData:(NSData *)postDataChunk {
    [_parser appendData:postDataChunk];
    _postData = postDataChunk;
}

#pragma mark - Data Parser Delegate

- (void)processStartOfPartWithHeader:(MultipartMessageHeader *)header {
    MultipartMessageHeaderField *disposition = [header.fields objectForKey:@"Content-Disposition"];
    NSString *filename = [[disposition.params objectForKey:@"filename"] lastPathComponent];
    
    if (!filename || [filename isEqualToString:@""]) {
        return;
    }
    
    CWEyeFiServer *server = (CWEyeFiServer *)config.server;
    NSString *uploadDirPath = server.documentRoot;
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:uploadDirPath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *filePath = [uploadDirPath stringByAppendingPathComponent:filename];
    
    BOOL fileExists = NO;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if (![[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]) {
#ifdef DEBUG
            NSLog(@"Can't create file %@", filePath);
#endif
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CWNotificationFileStatus
                                                                object:self
                                                              userInfo:@{
                                                                         @"path": [_storeFilePath stringByDeletingPathExtension],
                                                                         @"status": @(FileStatusError)
                                                                         }];
        } else {
            fileExists = YES;
        }
    } else {
        fileExists = YES;
    }
    
    if (fileExists) {
        _storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
        _storeFilePath = filePath;
        [_uploadedFiles addObject:_storeFile];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CWNotificationFileStatus
                                                            object:self
                                                          userInfo:@{
                                                                     @"path": [_storeFilePath stringByDeletingPathExtension],
                                                                     @"status": @(FileStatusUploading)
                                                                     }];
    }
}

- (void)processContent:(NSData *)data WithHeader:(MultipartMessageHeader *)header {
    if (_storeFile) {
        [_storeFile writeData:data];
    }
}

- (void)processEndOfPartWithHeader:(MultipartMessageHeader *)header {
    [_storeFile closeFile];
    
    if (_storeFilePath) {
        NSError *error;
        NSString *destination = nil;
        [Brett untarFileAtPath:_storeFilePath withError:&error destinationPath:&destination];
        
        if (error) {
#ifdef DEBUG
            NSLog(@"Error untaring file %@: %@", _storeFilePath, error);
#endif
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CWNotificationFileStatus
                                                                object:self
                                                              userInfo:@{
                                                                         @"path": [_storeFilePath stringByDeletingPathExtension],
                                                                         @"status": @(FileStatusError),
                                                                         @"error": error
                                                                         }];
            
        } else {
#ifdef DEBUG
            NSLog(@"untarred file in %@", _storeFilePath);
#endif
            
            // remove tar extension
            NSString *imagePath = [_storeFilePath stringByDeletingPathExtension];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CWNotificationFileStatus
                                                                object:self
                                                              userInfo:@{
                                                                         @"path": imagePath,
                                                                         @"status": @(FileStatusReady)
                                                                         }];
        }
    }
    
    _storeFile = nil;
    _storeFilePath = nil;
}

#pragma mark - Helpers

+ (NSString *)stringForTemplate:(NSString *)template {
    NSError *error;
    
    NSString *file = [[NSBundle mainBundle] pathForResource:template ofType:@"xml"];
    return [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
}

- (NSString *)credentialFromMacaddress:(NSString *)macaddress nonce:(NSString *)nnonce {
    NSString *uploadKey = ((CWEyeFiServer *)config.server).uploadKey;
    NSData *data = [self createDataWithHexString:[NSString stringWithFormat:@"%@%@%@", macaddress, nnonce, uploadKey]];
    return [data md5];
}

- (NSData *)createDataWithHexString:(NSString *)inputString {
    NSUInteger inLength = [inputString length];
    
    unichar *inCharacters = alloca(sizeof(unichar) * inLength);
    [inputString getCharacters:inCharacters range:NSMakeRange(0, inLength)];
    
    UInt8 *outBytes = malloc(sizeof(UInt8) * ((inLength / 2) + 1));
    
    NSInteger i, o = 0;
    UInt8 outByte = 0;
    for (i = 0; i < inLength; i++) {
        UInt8 c = inCharacters[i];
        SInt8 value = -1;
        
        if      (c >= '0' && c <= '9') value =      (c - '0');
        else if (c >= 'A' && c <= 'F') value = 10 + (c - 'A');
        else if (c >= 'a' && c <= 'f') value = 10 + (c - 'a');
        
        if (value >= 0) {
            if (i % 2 == 1) {
                outBytes[o++] = (outByte << 4) | value;
                outByte = 0;
            } else {
                outByte = value;
            }
            
        } else {
            if (o != 0) break;
        }
    }
    
    return [[NSData alloc] initWithBytesNoCopy:outBytes length:o freeWhenDone:YES];
}

@end
