//
//  EyeFiParser.h
//  EyeFiServer
//
//  Created by Michael Litvak on 7/23/14.
//  Copyright (c) 2014 codewhisper. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWEyeFiParser : NSObject <NSXMLParserDelegate>

@property NSString *method;

@property NSMutableDictionary *values;

- (id)initWithData:(NSData *)data;

- (BOOL)parseData;

@end
