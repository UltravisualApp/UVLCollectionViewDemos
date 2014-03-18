//
//  UVLCollectionViewController.m
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

#import "UVLCollectionViewController.h"

// layouts
#import "UVLCollectionViewLayoutGrid.h"
#import "UVLCollectionViewLayoutList.h"
#import "UVLCollectionViewLayoutSwell.h"
#import "UVLCollectionViewLayoutTransform.h"

#import "UVLCollectionViewTransitionLayout.h"

// cells
#import "UVLCollectionViewImageCell.h"

@interface UVLCollectionViewController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *assets;
@property (nonatomic, strong) NSMutableArray *buttons;

@property (nonatomic, strong) UVLCollectionViewLayoutGrid *gridLayout;
@property (nonatomic, strong) UVLCollectionViewLayoutList *listLayout;
@property (nonatomic, strong) UVLCollectionViewLayoutSwell *swellLayout;
@property (nonatomic, strong) UVLCollectionViewLayoutTransform *transformLayout;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat transitionProgress;
@property (nonatomic, strong) UVLCollectionViewTransitionLayout *transitionLayout;
@property (nonatomic, strong) dispatch_block_t completionBlock;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGFloat startSpacing;
@property (nonatomic, strong) NSIndexPath *startIndexPath;
@property (nonatomic, assign) CGFloat startOffset;

@end

@implementation UVLCollectionViewController

- (id)init
{
    self = [super initWithCollectionViewLayout:[[UICollectionViewLayout alloc] init]];
    if (self)
    {
        self.gridLayout = [[UVLCollectionViewLayoutGrid alloc] init];
        self.listLayout = [[UVLCollectionViewLayoutList alloc] init];
        self.swellLayout = [[UVLCollectionViewLayoutSwell alloc] init];
        self.transformLayout = [[UVLCollectionViewLayoutTransform alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set background color
    [self.collectionView setBackgroundColor:[UIColor blackColor]];
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    
    [self.collectionView setCollectionViewLayout:self.listLayout animated:NO];
    
    // load all the assets from the images folder into an array we can reference later
    NSMutableArray *theAssets = [NSMutableArray array];
    NSURL *theURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"Images"];
    NSEnumerator *theEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:theURL includingPropertiesForKeys:NULL options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];
    for (theURL in theEnumerator)
    {
        if ([[theURL pathExtension] isEqualToString:@"jpg"])
        {
            [theAssets addObject:theURL];
        }
    }
    self.assets = theAssets;
    
    // register the cell class(s)
    [self.collectionView registerClass:[UVLCollectionViewImageCell class] forCellWithReuseIdentifier:NSStringFromClass([UVLCollectionViewImageCell class])];
    
    // layout selector
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 44, CGRectGetWidth(self.view.frame), 44)];
    [self.view addSubview:toolbar];
    
    NSMutableArray *barButtonItems = [NSMutableArray array];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [barButtonItems addObject:flexSpace];
    
    self.buttons = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < 4; ++i) {
        
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%i", (i + 1)] style:UIBarButtonItemStyleBordered target:self action:@selector(onBarButtonItemPress:)];
        barButtonItem.tintColor = [UIColor blackColor];
        [barButtonItems addObject:barButtonItem];
        [self.buttons addObject:barButtonItem];
        
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [barButtonItems addObject:flexSpace];
    }
    [toolbar setItems:barButtonItems];
    
    // pan stuff
//    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)];
//    self.panGesture.delegate = self;
//    [self.collectionView addGestureRecognizer:self.panGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.assets count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger imageIndex = indexPath.row%[self.assets count];
    NSURL *theURL = [self.assets objectAtIndex:imageIndex];
    
    UVLCollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([UVLCollectionViewImageCell class]) forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithContentsOfFile:theURL.path];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - Button Callbacks

- (void)onBarButtonItemPress:(UIBarButtonItem *)barButtonItem
{
    NSUInteger index = [self.buttons indexOfObject:barButtonItem];
    typeof (self) __strong s_self = self;
    if (index == 0 && ![self.collectionView.collectionViewLayout isEqual:self.listLayout])
    {
        // list
        
        self.view.userInteractionEnabled = NO;
        self.panGesture.enabled = NO;
        
        [self.collectionView setCollectionViewLayout:self.listLayout animated:YES completion:^(BOOL finished) {
           s_self.collectionView.decelerationRate = UIScrollViewDecelerationRateNormal;
            s_self.view.userInteractionEnabled = YES;
            s_self.panGesture.enabled = YES;
        }];
    }
    else if (index == 1 && ![self.collectionView.collectionViewLayout isEqual:self.gridLayout])
    {
        // grid
        
        self.view.userInteractionEnabled = NO;
        self.panGesture.enabled = NO;
        
        [self.collectionView setCollectionViewLayout:self.gridLayout animated:YES completion:^(BOOL finished) {
            s_self.collectionView.decelerationRate = UIScrollViewDecelerationRateNormal;
            s_self.view.userInteractionEnabled = YES;
        }];
    }
    else if (index == 2 && ![self.collectionView.collectionViewLayout isEqual:self.transformLayout])
    {
        // transform
        
        self.view.userInteractionEnabled = NO;
        self.panGesture.enabled = NO;
        
        CGPoint targetContentOffset = [self.transformLayout targetContentOffsetForCollectionView:self.collectionView];
        
        UICollectionViewLayout *currentLayout = self.collectionView.collectionViewLayout;
        if ([currentLayout respondsToSelector:@selector(setIsTransitioning:)])
        {
            [(id)currentLayout setIsTransitioning:YES];
            [currentLayout invalidateLayout];
        }
        
        self.transitionLayout = [[UVLCollectionViewTransitionLayout alloc] initWithCurrentLayout:self.collectionView.collectionViewLayout nextLayout:self.transformLayout];
        self.transitionLayout.targetContentOffset = targetContentOffset;
        [self.collectionView setCollectionViewLayout:self.transitionLayout];
        
        self.transitionProgress = 0;
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLinkTick:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        self.completionBlock = ^() {
            if ([currentLayout respondsToSelector:@selector(setIsTransitioning:)])
            {
                [(id)currentLayout setIsTransitioning:NO];
            }
            
            [s_self.collectionView setCollectionViewLayout:s_self.transformLayout animated:YES];
            [s_self.collectionView setContentOffset:targetContentOffset];
            s_self.view.userInteractionEnabled = YES;
            s_self.collectionView.decelerationRate = UIScrollViewDecelerationRateNormal;
        };
    }
    else if (index == 3 && ![self.collectionView.collectionViewLayout isEqual:self.swellLayout])
    {
        // swell
        
        self.view.userInteractionEnabled = NO;
        self.panGesture.enabled = NO;
        
        [self.collectionView setContentOffset:CGPointZero animated:YES];
        
        CGPoint targetContentOffset = [self.swellLayout targetContentOffsetForCollectionView:self.collectionView];
     
        self.swellLayout.isTransitioning = YES;
        
        self.transitionLayout = [[UVLCollectionViewTransitionLayout alloc] initWithCurrentLayout:self.collectionView.collectionViewLayout nextLayout:self.swellLayout];
        self.transitionLayout.targetContentOffset = targetContentOffset;
        [self.collectionView setCollectionViewLayout:self.transitionLayout];
        
        self.transitionProgress = 0;
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLinkTick:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        self.completionBlock = ^() {
            s_self.swellLayout.isTransitioning = NO;
            [s_self.collectionView setCollectionViewLayout:s_self.swellLayout animated:YES];
            [s_self.collectionView setContentOffset:targetContentOffset];
            s_self.view.userInteractionEnabled = YES;
            s_self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        };
    }
}

- (void)onDisplayLinkTick:(CADisplayLink *)displayLink
{
    CGFloat delta = (1 - self.transitionProgress);
    if (delta < 0.01f)
    {
        [displayLink invalidate];
        
        self.transitionProgress = 1;
        [self.transitionLayout setTransitionProgress:self.transitionProgress];
        
        if (self.completionBlock)
        {
            self.completionBlock();
        }
    }
    else
    {
        self.transitionProgress += delta * 0.3f;
        [self.transitionLayout setTransitionProgress:self.transitionProgress];
    }
}

#pragma mark - pan gesture

- (void)onPanGesture:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateBegan)
    {
        self.startSpacing = self.listLayout.minimumLineSpacing;
        self.collectionView.panGestureRecognizer.enabled = NO;
        
        UICollectionViewCell *centerCell = [self.collectionView.visibleCells firstObject];
        CGFloat cellDistToCenter = CGFLOAT_MAX;
        CGFloat midY = CGRectGetMidY(self.collectionView.frame);
        
        for (UICollectionViewCell *cell in self.collectionView.visibleCells)
        {
            CGPoint cellCenter = [self.collectionView convertPoint:cell.center toView:self.collectionView.superview];
            CGFloat dCenter = fabsf(midY - cellCenter.y);
            if (dCenter < cellDistToCenter)
            {
                centerCell = cell;
                cellDistToCenter = dCenter;
            }
        }
        
        self.startIndexPath = [self.collectionView indexPathForCell:centerCell];
        self.startOffset = self.collectionView.contentOffset.y - (self.listLayout.itemSize.height * self.startIndexPath.item + self.listLayout.minimumLineSpacing * self.startIndexPath.item);
    }
    else if (panGesture.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [panGesture translationInView:self.collectionView];
        CGFloat newSpacing = MAX(self.startSpacing + translation.x, 0);
        self.listLayout.minimumLineSpacing = newSpacing;
        [self.listLayout invalidateLayout];
        
        CGFloat offsetY = self.listLayout.itemSize.height * self.startIndexPath.item + newSpacing * self.startIndexPath.item;
        [self.collectionView setContentOffset:CGPointMake(0, offsetY + self.startOffset) animated:NO];
    }
    else if (panGesture.state == UIGestureRecognizerStateCancelled ||
             panGesture.state == UIGestureRecognizerStateEnded)
    {
        self.collectionView.panGestureRecognizer.enabled = YES;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isEqual:self.panGesture])
    {
        CGPoint translation = [self.panGesture translationInView:self.collectionView];
        if (fabsf(translation.y) > 0)
            return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
