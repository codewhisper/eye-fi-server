//
//  EyeFiConnection.h
//  EyeFiServer
//
//  Created by Michael Litvak on 7/22/14.
//  Copyright (c) 2014 codewhisper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTTPConnection.h"
#import "MultipartFormDataParser.h"

@interface CWEyeFiConnection : HTTPConnection <MultipartFormDataParserDelegate>

@end
