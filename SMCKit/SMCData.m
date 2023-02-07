/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2023, Jean-David Gadina - www.xs-labs.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the Software), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

#import "SMCData.h"
#import "SMCHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMCData()

@property( nonatomic, readwrite, assign           ) uint32_t   key;
@property( nonatomic, readwrite, assign           ) uint32_t   type;
@property( nonatomic, readwrite, strong           ) NSData   * data;
@property( nonatomic, readwrite, strong           ) NSString * keyName;
@property( nonatomic, readwrite, strong           ) NSString * typeName;
@property( nonatomic, readwrite, strong, nullable ) id         value;

@end

NS_ASSUME_NONNULL_END

@implementation SMCData

- ( instancetype )initWithKey: ( uint32_t )key type: ( uint32_t )type data: ( NSData * )data
{
    if( ( self = [ super init ] ) )
    {
        self.key      = key;
        self.type     = type;
        self.data     = data;
        self.keyName  = [ SMCHelper fourCCString: key ];
        self.typeName = [ SMCHelper fourCCString: type ];
        self.value    = [ SMCHelper valueForData: data type: type ];
    }

    return self;
}

@end
