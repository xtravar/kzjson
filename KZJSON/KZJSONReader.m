//
//  KZJSONReader.m
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/29/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import "KZJSONReader.h"
#import "KZJSONTextReader.h"

#define KZ_INLINE inline __attribute__((always_inline)) static

KZ_INLINE void _readValue(__unsafe_unretained KZJSONReader *self);
KZ_INLINE NSNumber *_readNumber(__unsafe_unretained KZJSONTextReader *stream);
KZ_INLINE NSString *_readString(__unsafe_unretained KZJSONTextReader *stream);

KZ_INLINE BOOL _readHexChar(__unsafe_unretained KZJSONTextReader *stream, unichar* ch);
KZ_INLINE BOOL _readEscapedChar(__unsafe_unretained KZJSONTextReader *stream, unichar* c);

#if DEBUG
#define AssertReadString(str) { \
    NSString *str2 = [_stream getStringOfLength:str.length]; \
    NSAssert(str2, @"unexpected end of stream (expected %@", str); \
    NSAssert([str isEqualToString:str2], @"unexpected string: %@ (expected %@)", str2, str); \
}
#else
#define AssertReadString(str)
#endif

#define AssertReadChar(ch) { \
    unichar ch2 = 0; \
    if(![_stream getCharacter:&ch2]) { [NSException raise:@"KZJSONReaderException" format:@"unexpected end of stream (expected %C)", (unichar)ch]; } \
    NSAssert(ch == ch2, @"unexpected character: %C (expected %C)", ch2, (unichar)ch); \
}

#define kMaxNodeLevel 32
#define TOP_NODE (self->_nodeCount > 0 ? self->_nodeStack[self->_nodeCount-1] : KZJSONNodeTypeInvalid)

@implementation KZJSONReader {
@package
    KZJSONTextReader *_stream;
    
    int _nodeCount;
    KZJSONNodeType _nodeStack[kMaxNodeLevel];
    
    BOOL _expectsValue;
    BOOL _requiresComma;
    
    //property ivars redeclared so they can be seen in the inlined function
    NSString *_key;
    id _value;
    KZJSONNodeType _nodeType;
}

-(id)init {
    [NSException raise:@"KZJSONReaderException" format:@"Operation unsupported"];
    return nil;
}

-(id)initWithStream:(NSInputStream *)stream {
    self = [super init];
    if(self) {
        _stream = [[KZJSONTextReader alloc] initWithStream:stream];
        _nodeStack[0] = KZJSONNodeTypeInvalid;
        _expectsValue = YES;
        _requiresComma = NO;
    }

    return self;
}

-(void)dealloc {
    [self close];
}

-(void)open {
    [_stream open];
    [self read];
}

-(void)close {
    if([_stream isOpen]) {
        [_stream close];
        _stream = nil;
    }
}

-(BOOL)isOpen {
    return [_stream isOpen];
}

-(BOOL)read {
    _key = nil;
    _value = nil;
    _nodeType = KZJSONNodeTypeInvalid;
    
    unichar ch;
    
    [_stream skipWhitespace];
    
    if(![_stream peekCharacter:&ch]) {
        return NO;
    }
    
    int curLevel = _nodeCount;
    
    switch(ch) {
        case ']':
            NSAssert(TOP_NODE == KZJSONNodeTypeArray, @"closing array with no matching open");
            _nodeType = KZJSONNodeTypeEndArray;
            _value = nil;
            _nodeCount--;
            [_stream skipCharacter];
            break;
            
        case '}':
            NSAssert(TOP_NODE == KZJSONNodeTypeObject, @"closing object with no matching open");
            _nodeType = KZJSONNodeTypeEndObject;
            _value = nil;
            _nodeCount--;
            [_stream skipCharacter];
            break;
            
        default:
            _readValue(self);
            break;
    }
    
    if(curLevel >= _nodeCount) {
        KZJSONNodeType type = TOP_NODE;
        switch(type) {
            case KZJSONNodeTypeArray:
                _expectsValue = YES;
            case KZJSONNodeTypeObject:
                _requiresComma = YES;
                break;
                
            default:
                break;
        }
    }
    
    //NSLog(@"type: %C, key: %@, value: %@", _nodeType, _key, _value);
    return YES;
}

-(BOOL)hasValue {
    switch(_nodeType){
        case KZJSONNodeTypeNull:
        case KZJSONNodeTypeBool:
        case KZJSONNodeTypeString:
        case KZJSONNodeTypeNumber:
            return YES;
            
        default:
            break;
    }
    return NO;
}

-(NSString*)readString {
    id retval;
    switch(_nodeType) {
        case KZJSONNodeTypeNull:
            retval = nil;
            break;
            
        case KZJSONNodeTypeString:
            retval = _value;
            break;
            
        default:
            [NSException raise:@"KZJSONException" format:@"Unexpected token"];
    }
    
    [self read];
    return retval;
}

-(NSNumber*)readNumber {
    id retval;
    if(_nodeType == KZJSONNodeTypeBool || _nodeType == KZJSONNodeTypeNumber) {
        retval = _value;
    } else {
        [NSException raise:@"KZJSONException" format:@"Unexpected token"];
    }
    [self read];
    return retval;
}

-(BOOL)readBool {
    BOOL retval;
    if(_nodeType == KZJSONNodeTypeBool) {
        retval = [_value boolValue];
    } else {
        [NSException raise:@"KZJSONException" format:@"Unexpected token"];
    }
    [self read];
    return retval;
}

-(void)_skipArray {
    [self read];
    while(_nodeType != KZJSONNodeTypeEndArray) {
        [self skip];
    }
    [self read];
}

-(void)_skipObject {
    [self read];
    while(_nodeType != KZJSONNodeTypeEndObject) {
        [self skip];
    }
    [self read];
}

-(void)skip {
    switch(_nodeType) {
        case KZJSONNodeTypeInvalid:
            break;
            
        case KZJSONNodeTypeArray:
            [self _skipArray];
            break;
            
        case KZJSONNodeTypeObject:
            [self _skipObject];
            break;
            
        case KZJSONNodeTypeNull:
        case KZJSONNodeTypeNumber:
        case KZJSONNodeTypeString:
        case KZJSONNodeTypeBool:
        case KZJSONNodeTypeEndArray:
        case KZJSONNodeTypeEndObject:
            [self read];
            break;
            
    }
}
@end


KZ_INLINE void _readValue(__unsafe_unretained KZJSONReader *self) {
    SEL _cmd = @selector(_readValue:);
    __unsafe_unretained KZJSONTextReader *_stream = self->_stream;
    BOOL _requiresComma = self->_requiresComma;
    if(_requiresComma) {
        AssertReadChar(',');
        [_stream skipWhitespace];
    }
    
    if(TOP_NODE == KZJSONNodeTypeObject) {
        NSString *str = _readString(_stream);
        NSAssert(str != nil, @"invalid string or unexpected end of stream when reading object key");
        [_stream skipWhitespace];
        AssertReadChar(':');
        [_stream skipWhitespace];
        self->_key = str;
        self->_expectsValue = YES;
    }
    
    unichar ch;
    if(![_stream peekCharacter:&ch]) {
        [NSException raise:@"KZJSONException" format:@"unexpected end of stream"];
    }
    
    NSAssert(self->_expectsValue, @"reading value where unexpected");
    switch(ch) {
        case '[':
            self->_nodeType = KZJSONNodeTypeArray;
            self->_value = nil;
            self->_nodeStack[self->_nodeCount++] = KZJSONNodeTypeArray;
            [_stream skipCharacter];
            self->_requiresComma = NO;
            self->_expectsValue = YES;
            break;
            
        case '{':
            self->_nodeType = KZJSONNodeTypeObject;
            self->_value = nil;
            self->_nodeStack[self->_nodeCount++] = KZJSONNodeTypeObject;
            [_stream skipCharacter];
            self->_requiresComma = NO;
            self->_expectsValue = NO;
            break;
            
        case 'n':
            AssertReadString(@"null");
            self->_nodeType = KZJSONNodeTypeNull;
            self->_value = nil;
            break;
            
        case 't':
            AssertReadString(@"true");
            self->_nodeType = KZJSONNodeTypeBool;
            self->_value = @YES;
            break;
            
        case 'f':
            AssertReadString(@"false");
            self->_nodeType = KZJSONNodeTypeBool;
            self->_value = @NO;
            break;
            
        case '"':
            self->_nodeType = KZJSONNodeTypeString;
            self->_value = _readString(_stream);
            break;
            
        case '0' ... '9':
        case '-':
            self->_nodeType = KZJSONNodeTypeNumber;
            self->_value = _readNumber(_stream);
            break;
    }
}

KZ_INLINE BOOL _readHexChar(__unsafe_unretained KZJSONTextReader *stream, unichar* ch) {
    
    unichar b[4];
    if(![stream getCharacters:b length:4]) {
        return NO;
    }
    
    int retval = 0;
    
    for(int i = 0; i < 4; i++) {
        char digit = b[i];
        
        if(digit >= '0' && digit <= '9') {
            retval = (retval * 16) + digit - '0';
        } else if(digit >= 'a' && digit <= 'f') {
            retval = (retval * 16) + digit - 'a' + 10;
        } else if(digit >= 'A' && digit <= 'F') {
            retval = (retval * 16) + digit - 'A' + 10;
        } else {
            return NO;
        }
    }
    
    *ch = retval;
    return YES;
}

KZ_INLINE BOOL _readEscapedChar(__unsafe_unretained KZJSONTextReader *stream, unichar* c) {
    if(![stream getCharacter:c]) {
        return NO;
    }
    
    unichar ch = *c;
    switch(ch) {
        case '"':
        case '\\':
        case '/':
            break;
            
        case 'b':
            ch = '\b';
            break;
            
        case 'f':
            ch = '\f';
            break;
            
        case 'n':
            ch = '\n';
            break;
            
        case 'r':
            ch = '\r';
            break;
            
        case 't':
            ch = '\t';
            break;
            
        case 'u':
            if(!_readHexChar(stream, &ch)) {
                return NO;
            }
            break;
            
        default:
            return NO;
            
    }
    
    *c = ch;
    return YES;
}


KZ_INLINE NSString* _readString(__unsafe_unretained KZJSONTextReader *stream) {
    [stream skipCharacter];
    NSMutableString *ms = nil;
    const int maxBuff = 1024;
    unichar buff[maxBuff];
    int buffLength = 0;
    
    int chi;
    while((chi = [stream readCharacter]) > -1) {
        unichar ch = (unichar)chi;
        if(ch == '"') {
            break;
        }
        if(ch == '\\' && !_readEscapedChar(stream, &ch)) {
            return nil;
        }
        
        buff[buffLength++] = ch;
        if(buffLength == maxBuff) {
            if(ms == nil) {
                ms = [[NSMutableString alloc] initWithCharacters:buff length:buffLength];
            } else {
                CFStringAppendCharacters((CFMutableStringRef)ms, buff, buffLength);
            }
            buffLength = 0;
        }
    }
    if(buffLength > 0) {
        if(ms == nil) {
            //return [[NSString alloc] initWithCharacters:buff length:buffLength];
            return (__bridge_transfer NSString*)CFStringCreateWithCharacters(NULL, buff, buffLength);
        } else {
            CFStringAppendCharacters((CFMutableStringRef)ms, buff, buffLength);
        }
    }
    if(ms == nil) {
        return @"";
    }
    return ms;
}


// ([1-9].(0-9)+
KZ_INLINE NSNumber *_readNumber(__unsafe_unretained KZJSONTextReader *stream) {
#if 0
    static NSCharacterSet *charSet;
    static NSNumberFormatter *numFormat;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        charSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789-=Ee."];
        numFormat = [[NSNumberFormatter alloc] init];
        [numFormat setNumberStyle:NSNumberFormatterDecimalStyle];
    });
    
    NSString *str = [_stream stringWithCharactersInSet:charSet];
    
    NSScanner *scan = [NSScanner scannerWithString:str];
    NSNumber *value;
    NSString *err;
    if([numFormat getObjectValue:&value
                       forString:str
                errorDescription:&err]) {
        _value = value;
        _nodeType = KZJsonNodeTypeNumber;
    } else {
        _value = nil;
        _nodeType = KZJSonNodeTypeInvalid;
    }
#else
    NSNumber *retval = nil;
    unichar ch;
    [stream getCharacter:&ch];
    BOOL negative = NO;
    unsigned long long mantissa = 0;
    BOOL hasExponent = NO;
    short exponent = 0;
    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    
    if(ch == '-') {
        negative = YES;
        if(![stream getCharacter:&ch]) {
            return nil;
        }
    }
    
    if(ch < '0' || ch > '9') {
        return nil;
    }
    
    if(ch == '0') {
        mantissa = 0;
    } else {
        mantissa = ch - '0';
        while([stream peekCharacter:&ch] && [digits characterIsMember:ch]) {
            mantissa = mantissa * 10 + (ch - '0');
            [stream skipCharacter];
        }
    }
    
    if(![stream peekCharacter:&ch]) {
        goto NUMRETURN;
    }
    
    if(ch == '.') {
        hasExponent = YES;
        [stream skipCharacter];
        if(![stream getCharacter:&ch] || ch < '0' || ch > '9') {
            return nil;
        }
        
        mantissa = mantissa * 10 + (ch - '0');
        exponent--;
        
        while([stream peekCharacter:&ch] && [digits characterIsMember:ch]) {
            mantissa = mantissa * 10 + (ch - '0');
            exponent--;
            [stream skipCharacter];
        }
        
        if(![stream peekCharacter:&ch]) {
            goto NUMRETURN;
        }
    }
    
    if(ch == 'e' || ch == 'E') {
        [stream skipCharacter];
        BOOL negativeExp = NO;
        short exponent2 = 0;
        
        if(![stream getCharacter:&ch]) {
            return nil;
        }
        if(ch == '-') {
            negativeExp = YES;
            if(![stream getCharacter:&ch]) {
                return nil;
            }
        } else if(ch == '+') {
            negativeExp = NO;
            if(![stream getCharacter:&ch]) {
                return nil;
            }
        }
        
        exponent2 = ch - '0';
        while([stream peekCharacter:&ch] && [digits characterIsMember:ch]) {
            exponent2 = exponent2 * 10 + (ch - '0');
            [stream skipCharacter];
        }
        
        if(negativeExp) {
            exponent -= exponent2;
        } else {
            exponent += exponent2;
        }
        hasExponent = YES;
    }
    
NUMRETURN:
    if(hasExponent) {
        retval = [NSDecimalNumber decimalNumberWithMantissa:mantissa exponent:exponent isNegative:negative];
    } else if(negative) {
        retval = [NSNumber numberWithLongLong:-1 * (long long)mantissa];
    } else {
        retval = [NSNumber numberWithUnsignedLongLong:mantissa];
    }
    return retval;
#endif
}


