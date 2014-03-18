//
//  UVLCollectionViewLayoutSwell.m
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

#define kUIDefaultCellContracted      88.f
#define kUIDefaultCellExpanded        240.f
#define kUIDefaultCellExpandedArea    (kUIDefaultCellExpanded - kUIDefaultCellContracted)
#define kUIOptimalInterval 180.f

#import "UVLCollectionViewLayoutSwell.h"

@interface UVLCollectionViewLayoutSwell()

@property (nonatomic, strong) NSMutableArray *cellRects;

@end

@implementation UVLCollectionViewLayoutSwell

- (id)init
{
    self = [super init];
    if (self)
    {
        self.cellRects = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Frame Queries

- (CGRect)frameForCellWithIndex:(NSUInteger)index
{
    if (index < self.cellRects.count)
    {
        return [[self.cellRects objectAtIndex:index] CGRectValue];
    }
    
    return CGRectZero;
}

#pragma mark - UICollectionViewLayout view code

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (void)prepareLayout
{
    NSUInteger totalItems = [self.collectionView numberOfItemsInSection:0];
    CGPoint contentOffset = self.collectionView.contentOffset;
    CGFloat cellPercent = MAX(contentOffset.y / kUIOptimalInterval, 0);
    
    NSUInteger currentIndex = MAX(MIN(floorf(cellPercent), totalItems - 1), 0);
    CGFloat percentOffset = 1.f - fmodf(cellPercent, 1.f); // fmodf to 1 to get just the decimal part of the number
    
    NSUInteger nextIndex = MIN(currentIndex + 1, totalItems - 1);
    if (nextIndex == currentIndex)
    {
        nextIndex = NSNotFound;
    }
    
    [self.cellRects removeAllObjects];
    
    CGFloat runningHeight = 0;
    
    for (NSUInteger i = 0; i < totalItems; ++i)
    {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGRect frame = CGRectZero;
        CGSize contractedCellSize = CGSizeMake(width, kUIDefaultCellContracted);
        
        if (i < currentIndex)
        {
            frame = CGRectMake(0, 0, contractedCellSize.width, contractedCellSize.height);
            [self.cellRects addObject:[NSValue valueWithCGRect:frame]];
        }
        else if (i > currentIndex)
        {
            if (i == nextIndex)
            {
                contractedCellSize.height = contractedCellSize.height + ((1 - percentOffset) * kUIDefaultCellExpandedArea);
            }
            
            frame = CGRectMake(0, runningHeight, contractedCellSize.width, contractedCellSize.height);
            
            [self.cellRects addObject:[NSValue valueWithCGRect:frame]];
            
            runningHeight += frame.size.height;
        }
        else //if (i == self.currentIndex)
        {
            CGFloat offsetY = MAX(contentOffset.y - (contractedCellSize.height * (1 - percentOffset)), 0);
            frame = CGRectMake(0, offsetY, contractedCellSize.width, contractedCellSize.height + (kUIDefaultCellExpandedArea * percentOffset));
            
            [self.cellRects addObject:[NSValue valueWithCGRect:frame]];
            
            runningHeight += CGRectGetMaxY(frame);
        }
    }
    
    if (self.cellRects.count > 0 && currentIndex > 0)
    {
        // set frames for items below active index now that active index is generated
        CGRect expandedFrame = [[self.cellRects objectAtIndex:currentIndex] CGRectValue];
        runningHeight = expandedFrame.origin.y;
        
        for (NSInteger i = (NSInteger)currentIndex - 1; i >= 0; --i)
        {
            CGRect frame = [[self.cellRects objectAtIndex:(NSUInteger)i] CGRectValue];
            runningHeight -= frame.size.height;
            
            frame.origin.y = runningHeight;
            [self.cellRects replaceObjectAtIndex:(NSUInteger)i withObject:[NSValue valueWithCGRect:frame]];
        }
    }
}

- (CGSize)collectionViewContentSize
{
    NSValue *lastRectAsValue = [self.cellRects lastObject];
    if (lastRectAsValue)
    {
        return CGSizeMake(self.collectionView.frame.size.width, CGRectGetMaxY([lastRectAsValue CGRectValue]));
    }
    
    return CGSizeZero;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *layoutAttributes = [NSMutableArray array];
    
    if (self.isTransitioning)
    {
        // while transitioning, draw lots of cells off and on screen
        rect = CGRectInset(rect, 0, -([UIScreen mainScreen].bounds.size.height * 2));
    }
    
    NSUInteger totalItems = [self.collectionView numberOfItemsInSection:0];
    [self.cellRects enumerateObjectsUsingBlock:^(NSValue *value, NSUInteger idx, BOOL *stop) {
        CGRect frame = [value CGRectValue];
        
        if (CGRectIntersectsRect(rect, frame) && (NSInteger)idx < totalItems)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(NSInteger)idx inSection:0];
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            [layoutAttributes addObject:attributes];
        }
    }];
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    attributes.frame = [self frameForCellWithIndex:(NSUInteger)indexPath.item];
    
    return attributes;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    if (proposedContentOffset.y < 0)
    {
        return proposedContentOffset;
    }
    
    NSUInteger totalItems = [self.collectionView numberOfItemsInSection:0];
    
    CGFloat cellPercent = MAX(proposedContentOffset.y / kUIOptimalInterval, 0);
    
    NSUInteger currentIndex = MAX(MIN(floorf(cellPercent), totalItems - 1), 0);
    CGFloat percentOffset = 1.f - fmodf(cellPercent, 1.f); // fmodf to 1 to get just the decimal part of the number
    
    if (percentOffset < 0.5f)
    {
        currentIndex = MIN(currentIndex + 1, totalItems - 1);
    }
    
    proposedContentOffset.y = kUIOptimalInterval * currentIndex;
    
    return proposedContentOffset;
}

- (CGPoint)targetContentOffsetForCollectionView:(UICollectionView *)collectionView
{    
    NSArray *indexPathsForVisibleItems = [collectionView indexPathsForVisibleItems];
    NSInteger lowestInteger = NSIntegerMax;
    for (NSIndexPath *indexPath in indexPathsForVisibleItems)
    {
        if (indexPath.item < lowestInteger)
            lowestInteger = indexPath.item;
    }
    
    NSIndexPath *targetIndexPath = [NSIndexPath indexPathForItem:lowestInteger inSection:0];
    
    return CGPointMake(collectionView.contentOffset.x, targetIndexPath.item * kUIOptimalInterval);
}

@end
