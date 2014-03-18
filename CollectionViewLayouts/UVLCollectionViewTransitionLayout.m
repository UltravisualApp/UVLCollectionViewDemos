//
//  UVLCollectionViewTransitionLayout.m
//  CollectionViewLayouts
//
//  Created by Andrew Poes on 3/17/14.
//  Copyright (c) 2014 Ultravisual. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//

#import "UVLCollectionViewTransitionLayout.h"

@interface UVLCollectionViewTransitionLayout()

@property (nonatomic, assign) CGPoint startContentOffset;

@end

@implementation UVLCollectionViewTransitionLayout

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (id)initWithCurrentLayout:(UICollectionViewLayout *)currentLayout nextLayout:(UICollectionViewLayout *)newLayout
{
    if (self = [super initWithCurrentLayout:currentLayout nextLayout:newLayout]) {
        self.startContentOffset = currentLayout.collectionView.contentOffset;
    }
    return self;
}

- (void) setTransitionProgress:(CGFloat)transitionProgress
{
    [super setTransitionProgress:transitionProgress];
    
    CGFloat p = transitionProgress;
    CGFloat invp = 1 - self.transitionProgress;
    CGPoint offset = CGPointMake(invp * self.startContentOffset.x + p * self.targetContentOffset.x, invp * self.startContentOffset.y + p * self.targetContentOffset.y);
    [self.collectionView setContentOffset:offset animated:NO];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end
