//
//  NSString+EyeFi.h
//  EyeFiServer
//
//  Created by Michael Litvak on 7/23/14.
//  Copyright (c) 2014 codewhisper. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSString (EyeFi)

- (NSString *)md5;
+ (NSString *)randomStringWithLength:(NSUInteger)length;

@end
