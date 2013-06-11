//
//  KZJSONTextReader.h
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/27/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import <Foundation/Foundation.h>

// the JSON format defaults to UTF-8 but could be other unicode formats
// this object reads from a byte stream and converts accordingly

// more at http://www.ietf.org/rfc/rfc4627.txt
@interface KZJSONTextReader : NSObject
@property (nonatomic, readonly) NSInputStream *stream;

-(id)initWithStream:(NSInputStream*)stream;
-(void)open;
-(void)close;

-(BOOL)isOpen;

// gets the next character(s) from the stream - returns NO if end of stream
-(BOOL)getCharacter:(out unichar*)uc;
-(BOOL)getCharacters:(out unichar*)uc length:(int)length;

-(int)readCharacter;

// skips the next character(s) from the stream - returns NO if end of stream
-(BOOL)skipCharacter;
-(BOOL)skipCharacters:(int)count;

// skips characters in the set
-(void)skipCharactersInSet:(NSCharacterSet*)set;

// skips json whitespace - 0x09, 0x0A, 0x0D, 0x20
-(void)skipWhitespace;

// peeks the next character(s) from the stream - returns NO if end of stream
-(BOOL)peekCharacter:(out unichar*)uc;
-(BOOL)peekCharacter:(out unichar*)uc atIndex:(int)index;

// peeks a string from the stream - returns nil if not enough characters or end of stream
-(NSString*)peekStringOfLength:(int)length;

// retrieves a string from the stream - returns nil if not enough characters or end of stream
-(NSString*)getStringOfLength:(int)length;

// returns YES if at least length characters are remaining
-(BOOL)hasCharactersRemaining:(int)length;

// reads characters from the stream into a string if they are in the set
-(NSString*)stringWithCharactersInSet:(NSCharacterSet*)set;

@end
