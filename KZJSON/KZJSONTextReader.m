//
//  KZJSONTextReader.m
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/27/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#define KZ_INLINE inline __attribute__((always_inline)) static
#import "KZJSONTextReader.h"

KZ_INLINE BOOL peekByte(__unsafe_unretained KZJSONTextReader* self, uint8_t *output);
KZ_INLINE BOOL readByte(__unsafe_unretained KZJSONTextReader* self, uint8_t *output);
KZ_INLINE BOOL readBytes(__unsafe_unretained KZJSONTextReader* self, uint8_t *output, int size);
KZ_INLINE BOOL readUTF8(__unsafe_unretained KZJSONTextReader* self);
KZ_INLINE BOOL _fillPeekBuffer(__unsafe_unretained KZJSONTextReader* self);
KZ_INLINE BOOL _ensureFilled(__unsafe_unretained KZJSONTextReader* self);

const int kPeekBufferMax = 1024;

@implementation KZJSONTextReader {
@package
    NSInputStream *_stream;
    
    uint8_t _buffer[2048];
    int _bufferPos;
    int _bufferLength;
    
    BOOL _bomRead;
    NSStringEncoding _encoding;
    
    unichar _peekBuffer[kPeekBufferMax];
    int _peekBufferPos;
    int _peekBufferLength;
}

-(id)initWithStream:(NSInputStream *)stream {
    self = [super init];
    if(self) {
        _stream = stream;
        _bufferPos = 0;
        _peekBufferPos = 0;
    }
    return self;
}

// from the JSON specification - the first two chars are always ASCII
// such that the encoding can be determined without BOM
// http://www.ietf.org/rfc/rfc4627.txt
-(void)open {
    [_stream open];
    // read BOM
    uint8_t temp;
    // force buffer load
    if(!peekByte(self, &temp)) {
        [NSException raise:@"KZJSONTextReader" format:@"unexpected end of stream"];
    }
    
    if(_buffer[0] == 0 && _buffer[1] == 0 && _buffer[2] == 0 && _buffer[3] != 0) {
        _encoding = NSUTF32BigEndianStringEncoding;
    } else if(_buffer[0] == 0 && _buffer[1] != 0 && _buffer[2] == 0 && _buffer[3] != 0) {
        _encoding = NSUTF16BigEndianStringEncoding;
    } else if(_buffer[0] != 0 && _buffer[1] == 0 && _buffer[2] == 0 && _buffer[3] == 0) {
        _encoding = NSUTF32LittleEndianStringEncoding;
    } else if(_buffer[0] != 0 && _buffer[1] == 0 && _buffer[2] != 0 && _buffer[3] == 0) {
        _encoding = NSUTF16LittleEndianStringEncoding;
    } else {
        _encoding = NSUTF8StringEncoding;
    }
}

-(void)close {
    if([self isOpen]) {
        [_stream close];
        _stream = nil;
    }
}

-(BOOL)isOpen {
    return _stream.streamStatus == NSStreamStatusOpen;
}

-(void)dealloc {
    [self close];
}

-(BOOL)skipCharacter {
    if(!_ensureFilled(self)) {
        return NO;
    }
    
    _peekBufferPos++;
    return YES;
}

-(void)skipCharactersInSet:(NSCharacterSet *)set {
    if(!_ensureFilled(self)) {
        return;
    }
    
    for( ; _peekBufferPos < _peekBufferLength; ) {
        unichar c = _peekBuffer[_peekBufferPos];
        if(![set characterIsMember:c]) {
            return;
        }
        _peekBufferPos++;
        
        _ensureFilled(self);
    }
}

-(void)skipWhitespace {
    if(!_ensureFilled(self)) {
        return;
    }
    
    for( ; _peekBufferPos < _peekBufferLength; ) {
        unichar c = _peekBuffer[_peekBufferPos];
        switch(c) {
            case 0x09:
            case 0x0A:
            case 0x0D:
            case 0x20:
                break;
                
            default:
                return;
        }
        
        _peekBufferPos++;
        _ensureFilled(self);
    }
}

-(BOOL)peekCharacter:(out unichar*)uc {
    if(!_ensureFilled(self)) {
        return NO;
    }

    *uc = _peekBuffer[_peekBufferPos];
    return YES;
}

-(BOOL)peekCharacter:(out unichar*)uc atIndex:(int)index {
    if(![self hasCharactersRemaining:index + 1]) {
        return NO;
    }
    *uc = _peekBuffer[_peekBufferPos + index];
    return YES;
}

-(BOOL)getCharacter:(out unichar *)uc {
    if(!_ensureFilled(self)) {
        return NO;
    }
    
    *uc = _peekBuffer[_peekBufferPos++];
    return YES;
}

-(BOOL)getCharacters:(out unichar*)uc length:(int)length {
    if(![self hasCharactersRemaining:length]) {
        return NO;
    }
    
    memcpy(uc, &_peekBuffer[_peekBufferPos], length * sizeof(unichar));
    _peekBufferPos += length;
    return YES;
}


-(int)readCharacter {
    if(!_ensureFilled(self)) {
        return -1;
    }
    
    return _peekBuffer[_peekBufferPos++];
}

-(BOOL)hasCharactersRemaining:(int)length {
    NSAssert(length <= sizeof(_peekBuffer), @"cannot peek longer than peek max");
    
    if(!_ensureFilled(self)) {
        return NO;
    }
    
    int buffCount = _peekBufferLength - _peekBufferPos;
    int diff = buffCount - length;
    if(diff < 0) {
        memcpy(_peekBuffer, _peekBuffer + _peekBufferPos, buffCount * sizeof(unichar));
        _peekBufferLength -= _peekBufferPos;
        _peekBufferPos = 0;
        
        if(!_fillPeekBuffer(self) || _peekBufferLength < length) {
            return NO;
        }
    }
    return YES;
}

-(NSString*)peekStringOfLength:(int)length {
    if(![self hasCharactersRemaining:length]) {
        return nil;
    }
    NSString *retval = [NSString stringWithCharacters:_peekBuffer + _peekBufferPos length:length];
    return retval;
}

-(NSString*)getStringOfLength:(int)length {
    NSString *retval = [self peekStringOfLength:length];
    _peekBufferPos += length;
    return retval;
}

-(NSString*)stringWithCharactersInSet:(NSCharacterSet*)set {
    const int buffMax = 256;
    unichar buff[256];
    int buffLen = 0;
    NSMutableString *retval = [[NSMutableString alloc] init];
    
    unichar ch;
    while([self peekCharacter:&ch] && [set characterIsMember:ch]) {
        buff[buffLen++] = ch;
        
        if(buffLen == buffMax) {
            CFStringAppendCharacters((CFMutableStringRef)retval, buff, buffLen);
            buffLen = 0;
        }
        [self skipCharacter];
    }
    
    if(buffLen > 0) {
        CFStringAppendCharacters((CFMutableStringRef)retval, buff, buffLen);
    }
    return retval;
}

-(BOOL)skipCharacters:(int)length {
    if(![self hasCharactersRemaining:length]) {
        return NO;
    }

    _peekBufferPos += length;    
    return YES;
}

@end


KZ_INLINE
BOOL peekByte(__unsafe_unretained KZJSONTextReader* self, uint8_t *output) {
    int remainder = self->_bufferLength - self->_bufferPos;
    if(remainder < 1) {
        int retval = [self->_stream read:self->_buffer maxLength:sizeof(self->_buffer)];
        self->_bufferLength = retval;
        self->_bufferPos = 0;
        if(self->_bufferLength <= 0) {
            return NO;
        }
    }
    
    *output = self->_buffer[self->_bufferPos];
    return YES;
}

KZ_INLINE
BOOL readByte(__unsafe_unretained KZJSONTextReader* self, uint8_t *output) {
    if(peekByte(self, output)) {
        self->_bufferPos++;
        return YES;
    }
    
    return NO;
}

KZ_INLINE
BOOL readBytes(__unsafe_unretained KZJSONTextReader* self, uint8_t *output, int size) {
    int remainder = self->_bufferLength - self->_bufferPos;
    if(remainder < size) {
        memcpy(self->_buffer, self->_buffer + self->_bufferPos, remainder);
        self->_bufferPos = 0;
        self->_bufferLength = remainder;
        int val = [self->_stream read:self->_buffer + remainder maxLength:sizeof(self->_buffer) - remainder];
        if(val < 0) {
            return NO;
        }
        self->_bufferLength = remainder + val;
    }
    
    memcpy(output, self->_buffer + self->_bufferPos, size);
    self->_bufferPos += size;
    return YES;
}

// this isn't incredibly robust, but here it is
KZ_INLINE
BOOL readUTF8(__unsafe_unretained KZJSONTextReader* self) {
    uint8_t b;
    uint8_t bytes[6];
    unichar ch;
    if(!peekByte(self, &b)) {
        return NO;
    }
    
    // ASCII
    if((b & 0x80) == 0) {
        self->_peekBuffer[self->_peekBufferLength++] = b;
        self->_bufferPos++;
        return YES;
    }
    
    if((b & 0xE0) == 0xC0) {
        if(!readBytes(self, bytes, 2)) {
            return NO;
        }
        
        ch = (bytes[0] & 0x1F) << 6 |
        (bytes[1] & 0x3F);
        self->_peekBuffer[self->_peekBufferLength++] = ch;
        return YES;
    }
    
    if((b & 0xF0) == 0xE0) {
        if(!readBytes(self, bytes, 3)) {
            return NO;
        }
        
        ch = (bytes[0] & 0x0F) << 12 |
        (bytes[1] & 0x3F) << 6 |
        (bytes[2] & 0x3F);
        self->_peekBuffer[self->_peekBufferLength++] = ch;
        return YES;
    }
    
    if(self->_peekBufferLength + 2 >= kPeekBufferMax) {
        return NO;
    }
    
    uint32_t wch;
    if((b & 0xF8) == 0xF0) {
        if(!readBytes(self, bytes, 4)) {
            return NO;
        }
        wch = (bytes[0] & 0x07) << 18 |
        (bytes[1] & 0x3F) << 12 |
        (bytes[2] & 0x3F) << 6 |
        (bytes[3] & 0x3F);
    } else if((b & 0xFC) == 0xF8) {
        if(!readBytes(self, bytes, 5)) {
            return NO;
        }
        wch = (bytes[0] & 0x03) << 24 |
        ((bytes[1] & 0x3f) << 18) |
        ((bytes[2] & 0x3f) << 12) |
        ((bytes[3] & 0x3f) <<  6) |
        ((bytes[4] & 0x3f) <<  0);
    } else if((b & 0xFE) == 0xFC) {
        if(!readBytes(self, bytes, 6)) {
            return NO;
        }
        wch = (bytes[0] & 0x01) << 30 |
        (bytes[1] & 0x3fL) << 24 |
        (bytes[2] & 0x3fL) << 18 |
        (bytes[3] & 0x3fL) << 12 |
        (bytes[4] & 0x3fL) <<  6 |
        (bytes[5] & 0x3fL);
    } else {
        return NO;
    }
    
    // should never happen, but just in case
    if(wch < 0x10000) {
        self->_peekBuffer[self->_peekBufferLength++] = wch;
        return YES;
    }
    
    wch &= 0x10000;
    
    unichar c1 = 0xD800 | (wch >> 10);
    unichar c2 = 0xDC00 | (wch & 0x3FF);
    self->_peekBuffer[self->_peekBufferLength++] = c1;
    self->_peekBuffer[self->_peekBufferLength++] = c2;
    
    return YES;
}

KZ_INLINE
BOOL _fillPeekBuffer(__unsafe_unretained KZJSONTextReader* self) {
    uint16_t ret16;
    uint32_t ret32;
    BOOL retval = NO;
    
    for( ; self->_peekBufferLength < kPeekBufferMax; ) {
        switch(self->_encoding) {
            case NSUTF8StringEncoding:
                if(readUTF8(self)) {
                    retval |= YES;
                    break;
                }
                return retval;
                
            case NSUTF16BigEndianStringEncoding:
                if(readBytes(self, (uint8_t*)&ret16, sizeof(ret16))) {
                    self->_peekBuffer[self->_peekBufferLength++] = NSSwapBigShortToHost(ret16);
                    retval |= YES;
                    break;
                }
                return retval;
                
            case NSUTF16LittleEndianStringEncoding:
                if(readBytes(self, (uint8_t*)&ret16, sizeof(ret16))) {
                    self->_peekBuffer[self->_peekBufferLength++] = NSSwapBigShortToHost(ret16);
                    retval |= YES;
                    break;
                }
                return retval;
                
            // we are not writing the surrogate conversion code for UTF32... not today
            case NSUTF32BigEndianStringEncoding:
                if(readBytes(self, (uint8_t*)&ret32, sizeof(ret32))) {
                    self->_peekBuffer[self->_peekBufferLength++] = NSSwapBigIntToHost(ret32);
                    retval |= YES;
                    break;
                }
                return retval;
                
            case NSUTF32LittleEndianStringEncoding:
                if(readBytes(self, (uint8_t*)&ret32, sizeof(ret32))) {
                    self->_peekBuffer[self->_peekBufferLength++] = NSSwapLittleIntToHost(ret32);
                    retval |= YES;
                    break;
                }
                return retval;
                
            default:
                return NO;
        }
    }
    return retval;
}

KZ_INLINE BOOL _ensureFilled(__unsafe_unretained KZJSONTextReader *self) {
    if(self->_peekBufferPos == self->_peekBufferLength) {
        self->_peekBufferPos = 0;
        self->_peekBufferLength = 0;
        if(!_fillPeekBuffer(self)) {
            return NO;
        }
    }
    return YES;
}