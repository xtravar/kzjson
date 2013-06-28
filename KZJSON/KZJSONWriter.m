//
//  KZJSONWriter.m
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/29/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import "KZJSONWriter.h"
#import "KZJSON.h"

#define kMaxNodeLevel 128
#define KZ_INLINE inline __attribute__((always_inline)) static

KZ_INLINE void writeData(KZJSONWriter* self, const void *data, int length);
KZ_INLINE KZJSONNodeType topNode(KZJSONWriter *self);
KZ_INLINE void writeString(KZJSONWriter *self, NSString *value, BOOL escaped);

@implementation KZJSONWriter {
    @package
    NSOutputStream *_stream;
    int _nodeCount;
    KZJSONNodeType _nodeStack[kMaxNodeLevel];
    
    BOOL _requiresComma;
    BOOL _insideString;
}

-(id)init {
    [NSException raise:@"KZJSONWriterException" format:@"Operation unsupported"];
    return nil;
}

-(id)initWithStream:(NSOutputStream*)stream {
    self = [super init];
    if(self) {
        _stream = stream;
        _nodeStack[0] = KZJSONNodeTypeInvalid;
        _requiresComma = NO;
    }
    return self;
}

-(void)dealloc {
    [self close];
}


#pragma mark Stream control
-(void)open {
    [_stream open];
}

-(void)close {
    if([self isOpen]) {
        [self writeFullEndObjectAndArray];
        [_stream close];
        _stream = nil;
    }
}

-(BOOL)isOpen {
    return _stream.streamStatus == NSStreamStatusOpen;
}
#pragma mark -


#pragma mark Helper methods

-(void)_writeStartValue:(BOOL)string {
    if(_insideString) {
        [self _writeEndValue];
    }
    
    if(_requiresComma) {
        writeData(self, ",", 1);
    }
    if(string) {
        writeData(self, "\"", 1);
        _insideString = YES;
    }
}

-(void)_writeEndValue {
    if(_insideString) {
        writeData(self, "\"", 1);
        _insideString = NO;
    }
    
    KZJSONNodeType type = topNode(self);
    switch(type) {
        case KZJSONNodeTypeArray:
        case KZJSONNodeTypeObject:
            _requiresComma = YES;
            break;
            
        default:
            break;
    }
}

#pragma mark -

#pragma mark Structures
-(void)writeKey:(NSString*)string {
    if(_insideString) {
        [self _writeEndValue];
    }
    NSAssert(topNode(self) == KZJSONNodeTypeObject, @"keys may only be written in dictionaries in JSON");
    if(_requiresComma) {
        writeData(self, ",", 1);
    }
    
    writeData(self, "\"", 1);
    writeString(self, string, YES);
    writeData(self, "\"", 1);
    writeData(self, ":", 1);
    _requiresComma = NO;
}

-(void)writeStartObject {
    [self _writeStartValue:NO];
    _nodeStack[_nodeCount++] = KZJSONNodeTypeObject;
    writeData(self, "{", 1);
    _requiresComma = NO;
}

-(void)writeEndObject {
    NSAssert(topNode(self) == KZJSONNodeTypeObject, @"end of object does not match beginning");
    if(_insideString) {
        [self _writeEndValue];
    }
    writeData(self, "}", 1);
    _nodeCount--;
    [self _writeEndValue];
}

-(void)writeStartArray {
    [self _writeStartValue:NO];
    _nodeStack[_nodeCount++] = KZJSONNodeTypeArray;
    writeData(self, "[", 1);
    _requiresComma = NO;
}

-(void)writeEndArray {
    NSAssert(topNode(self) == KZJSONNodeTypeArray, @"end of array does not match beginning");
    if(_insideString) {
        [self _writeEndValue];
    }
    writeData(self, "]", 1);
    _nodeCount--;
    [self _writeEndValue];
}

-(void)writeFullEndObjectAndArray {
    KZJSONNodeType type = topNode(self);
    while(type != KZJSONNodeTypeInvalid) {
        if(type == KZJSONNodeTypeArray) {
            [self writeEndArray];
        } else if(type == KZJSONNodeTypeObject) {
            [self writeEndObject];
        } else {
            NSAssert(YES, @"unknown node type - something really bad happened");
        }
    }
}
#pragma mark -

#pragma mark Value writing
-(void)writeNull {
    [self _writeStartValue:NO];
    writeData(self, "null", 4);
    [self _writeEndValue];
}

-(void)writeBool:(BOOL)b {
    [self _writeStartValue:NO];
    if(b) {
        writeData(self, "true", 4);
    } else {
        writeData(self, "false", 5);
    }
    [self _writeEndValue];
}

-(void)writeNumber:(NSNumber*)number {
    [self _writeStartValue:NO];
    if(!number) {
        writeData(self, "null", 4);
    } else {
        NSString *str = [number stringValue];
        const char *bytes = [str UTF8String];
        writeData(self, bytes, strlen(bytes));
    }
    [self _writeEndValue];
}

-(void)writeString:(NSString*)string {
    if(!string) {
        [self writeNull];
        return;
    }
    
    [self _writeStartValue:YES];
    writeString(self, string, YES);
}

-(void)writeString:(NSString *)string escaped:(BOOL)escaped {
    if(!string) {
        [self writeNull];
        return;
    }
    
    [self _writeStartValue:YES];
    writeString(self, string, escaped);
}

-(void)writeStringFragment:(NSString *)string {
    if(!_insideString) {
        [self _writeStartValue:YES];
    }
    writeString(self, string, YES);
}

-(void)writeStringFragment:(NSString *)string escaped:(BOOL)escaped {
    if(!_insideString) {
        [self _writeStartValue:YES];
    }
    writeString(self, string, escaped);
}

#pragma mark -

@end


KZ_INLINE void writeData(KZJSONWriter* self, const void *data, int length) {
    SEL _cmd = @selector(writeData:);
    int writeLength = [self->_stream write:data maxLength:length];
    NSAssert(writeLength == length, @"stream write failed");
}

KZ_INLINE KZJSONNodeType topNode(KZJSONWriter *self) {
    int _nodeCount = self->_nodeCount;
    return (_nodeCount > 0 ? self->_nodeStack[_nodeCount-1] : KZJSONNodeTypeInvalid);
}

KZ_INLINE void writeString(KZJSONWriter *self, NSString* string, BOOL escaped) {
    const uint8_t *bytes = (const uint8_t*)[string UTF8String];
    int length = strlen((const char*)bytes);
    if(!escaped) {
        writeData(self, bytes, length);
        return;
    }
    
    uint8_t uBuff[] = "\\u0000"; // first 2 digits never used
    
    for(int i = 0; i < length; i++) {
        uint8_t ch = bytes[i];
        switch(ch) {
                // special cases
            case 8:
                writeData(self, "\\b", 2);
                break;
                
            case 9:
                writeData(self, "\\t", 2);
                break;
                
            case 10:
                writeData(self, "\\n", 2);
                break;
                
            case 12:
                writeData(self, "\\f", 2);
                break;
                
            case 13:
                writeData(self, "\\r", 2);
                break;
                
            case 34:
                writeData(self, "\\\"", 2);
                break;
                
            case 92:
                writeData(self, "\\\\", 2);
                break;
                
            case 0 ... 7:
                uBuff[4] = '0';
                uBuff[5] = '0' + ch;
                writeData(self, uBuff, 6);
                break;
                
            case 11:
            case 14 ... 15:
                uBuff[4] = '0';
                uBuff[5] = 'a' + ch;
                writeData(self, uBuff, 6);
                break;
                
            case 16 ... 25:
                uBuff[4] = '1';
                uBuff[5] = '0' + ch;
                writeData(self, uBuff, 6);
                break;
                
            case 26 ... 31:
                uBuff[4] = '1';
                uBuff[5] = 'a' + ch;
                writeData(self, uBuff, 6);
                break;
                
            case 32 ... 33:
            case 35 ... 91:
            case 93 ... 0x7F:
                writeData(self, &ch, 1);
                break;
                
                // 2 char utf-8
            case 0xC0 ... 0xDF:
                writeData(self, &bytes[i], 2);
                i++;
                break;
                
                // 3 char utf-8
            case 0xE0 ... 0xEF:
                writeData(self, &bytes[i], 3);
                i += 2;
                break;
                
                // 4 char utf-8
            case 0xF0 ... 0xF7:
                writeData(self, &bytes[i], 4);
                i += 3;
                break;
                
                // 5 char utf-8
            case 0xF8 ... 0xFB:
                writeData(self, &bytes[i], 5);
                i += 4;
                break;
                
                // 6 char utf-8
            case 0xFC ... 0xFD:
                writeData(self, &bytes[i], 6);
                i += 5;
                break;
                
            default:
                NSLog(@"unexpected byte in UTF8 string while writing json");
                break;
                
        }
    }
}


