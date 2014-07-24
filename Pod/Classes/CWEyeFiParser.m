	//
//  EyeFiParser.m
//  EyeFiServer
//
//  Created by Michael Litvak on 7/23/14.
//  Copyright (c) 2014 codewhisper. All rights reserved.
//

#import "CWEyeFiParser.h"

@implementation CWEyeFiParser {
    NSXMLParser *_xmlParser;
    BOOL _insideNs1;
    
    NSString *_currentElement;
    NSMutableString *_currentValue;
    BOOL _insideElement;
}

- (id)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _xmlParser = [[NSXMLParser alloc] initWithData:data];
        [_xmlParser setDelegate:self];
        [_xmlParser setShouldResolveExternalEntities:NO];
        
        _insideNs1 = NO;
        
        _currentValue = [NSMutableString stringWithString:@""];
        _values = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)parseData {
    return [_xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    _currentElement = elementName;
    if ([elementName hasPrefix:@"ns1:"]) {
        _method = [elementName substringFromIndex:4];
        _insideNs1 = YES;
    } else if (_insideNs1) {
        _insideElement = YES;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_insideElement) {
        [_currentValue appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName hasPrefix:@"ns1:"]) {
        _insideNs1 = NO;
    } else if (_insideNs1) {
        [_values setObject:[NSString stringWithFormat:@"%@", _currentValue] forKey:_currentElement];
        [_currentValue setString:@""];
    }
}

@end
