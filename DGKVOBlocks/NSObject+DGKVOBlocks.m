//*******************************************************************************

// Copyright (c) 2011 Danny Greg

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Created by Danny Greg on 02/10/2011

//*******************************************************************************

#import "NSObject+DGKVOBlocks.h"

#import <objc/runtime.h>

//***************************************************************************

NSString *DGKVOBlocksObservationContext = @"DGKVOBlocksObservationContext";

//***************************************************************************

@interface DGKVOBlocksObserver : NSObject 

@property (copy) DGKVOObserverBlock block;
@property (copy) NSString *keyPath;
@property (retain) NSOperationQueue *queue;

@end

@implementation DGKVOBlocksObserver

@synthesize block = _block;
@synthesize keyPath = _keyPath;
@synthesize queue = _queue;

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [_keyPath release];
    [_queue release];
    [_block release];
    
    [super dealloc];
}
#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
    if (context == &DGKVOBlocksObservationContext) {
        if (self.queue == nil) {
            self.block(change);
            return;
        }
        
        [self.queue addOperationWithBlock: ^ {
            self.block(change);
        }];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

//***************************************************************************

@implementation NSObject (DGKVOBlocks)

- (id)dgkvo_addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options queue:(NSOperationQueue *)queue usingBlock:(DGKVOObserverBlock)block
{
    if (block == nil)
        return nil;
    
    DGKVOBlocksObserver *newBlocksObserver = [[DGKVOBlocksObserver alloc] init];
    newBlocksObserver.block = block;
    newBlocksObserver.keyPath = keyPath;
    newBlocksObserver.queue = queue;
    
    [self addObserver:newBlocksObserver forKeyPath:keyPath options:options context:&DGKVOBlocksObservationContext];
    
    // Reference counting:  we retain the observer until client removes it
    // GC:                  the caller is responsible for keeping strong ref to the observer
    return newBlocksObserver;
}

- (void)dgkvo_removeObserver:(id)observer
{
    [self removeObserver:observer forKeyPath:[observer keyPath]];
    
    // Reference counting:  we retained the observer when added, so must release now to balance
    // GC:                  no-op
    [observer release];
}

@end
