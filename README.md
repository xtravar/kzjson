##KZJSON
KZJSON is a JSON library for Objective-C/iOS that resides between a full serializer and a simple tokenizer.  In terms of functionality, it is comparable to libxml2's xmltextreader or C#'s XmlReader.

Its purpose is to allow easy native object serialization/deserialization, rather than the current spectrum offered by APIs: tokenization or managed objects.

##Examples
For example, one might write the following code to read a model object:
```objective-c
KZJSONReader *jr = [[KZJSONReader alloc] initWithStream:is];
[jr open];
[jr readStartObject];
while(![jr isEndObject]) {
    // in real life scenarios, this should be validated, etc
    [object setValue:jr.value forKey:jr.key];
}
[jr close];
```

Similarly, there is a KZJSONWriter:
```objective-c
KZJSONWriter *jw = [[KZJSONWriter alloc] initWithStream:os];
[jw open];
[jw writeStartObject];
// for each property on the object
[jw writeString:object.property withKey:@"property"];
[jw writeEndObject];
[jw close];
```

##License
This code is provided under the MIT license.  However, if you do use it, I would very much appreciate hearing about it!

The MIT License (MIT)

Copyright (c) 2012, 2013 Mike Kasianowicz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.