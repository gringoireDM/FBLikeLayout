//
//  FBLikeLayout.m
//  FPhoto Manager
//
//  Created by Giuseppe Lanza on 27/12/14.
//  Copyright (c) 2014 lanuovaera. All rights reserved.
//

#import "FBLikeLayout.h"

@interface FBLikeLayout()

@property (nonatomic, strong) NSMutableArray  *nonSquaredRects;

@property (nonatomic, strong) NSMutableDictionary *attributesForIndexPath;
@property (nonatomic, strong) NSMutableDictionary *framesForHeaderSection;
@property (nonatomic, strong) NSMutableDictionary *framesForFooterSection;

@property (nonatomic, assign) CGSize contentSize;

@property (nonatomic, assign) CGRect referringBounds;

@end

#ifndef DLog
	#if DEBUG
		#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
	#else
		#define DLog(...)
	#endif
#endif

@implementation FBLikeLayout

#if DEBUG

-(void)dealloc{
	DLog(@"Dealloc called");
}

#endif

-(NSMutableDictionary *)attributesForIndexPath{
	if(!_attributesForIndexPath){
		_attributesForIndexPath = [NSMutableDictionary new];
	}
	
	return _attributesForIndexPath;
}

-(NSMutableDictionary *)framesForHeaderSection{
	if(!_framesForHeaderSection) _framesForHeaderSection = [NSMutableDictionary new];
	
	return _framesForHeaderSection;
}

-(NSMutableDictionary *)framesForFooterSection{
	if(!_framesForFooterSection) _framesForFooterSection = [NSMutableDictionary new];
	
	return _framesForFooterSection;
}

-(NSMutableArray *)nonSquaredRects{
	if(!_nonSquaredRects)
		_nonSquaredRects = [NSMutableArray new];
	
	return _nonSquaredRects;
}

-(void)prepareLayout{
	if(self.singleCellWidth == 0){
		self.singleCellWidth = (MIN(self.collectionView.bounds.size.width, self.collectionView.bounds.size.height)-self.collectionView.contentInset.left-self.collectionView.contentInset.right-2*self.minimumInteritemSpacing)/3.0;
	}
	
	if(self.fullImagePercentageOfOccurrency == 0)
		self.fullImagePercentageOfOccurrency = 70;
	
	CGFloat cellWidthToUse = self.singleCellWidth;
	
	if(self.maxCellSpace == 0)
		self.maxCellSpace = 3;
	
	NSInteger sections = [self.collectionView numberOfSections];
	CGPoint offset = CGPointZero;
	
	int columns = floorf((self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right)/cellWidthToUse);
	
	CGFloat realInteritemSpacing = MAX(self.minimumInteritemSpacing, (self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right-(float)columns*cellWidthToUse)/(columns-1));
	
	if(self.forceCellWidthForMinimumInteritemSpacing && realInteritemSpacing != self.minimumInteritemSpacing){
		cellWidthToUse = (self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right-self.minimumInteritemSpacing*(columns-1))/columns;
		
		realInteritemSpacing = self.minimumInteritemSpacing;
	}
	
	CGFloat maxH = 0;
	
	if(!CGRectEqualToRect(self.referringBounds, self.collectionView.frame)){
		[self.nonSquaredRects removeAllObjects];
		[self.attributesForIndexPath removeAllObjects];
		[self.framesForFooterSection removeAllObjects];
		[self.framesForHeaderSection removeAllObjects];
		
		self.referringBounds = self.collectionView.frame;
	}
	
	for(NSInteger section = 0; section < sections; section++){
		NSInteger items = [self.collectionView numberOfItemsInSection:section];
		
		if([self.collectionView.delegate conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)] && [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]){
			CGSize headerSize = [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
			
			CGRect headerFrame = CGRectMake(-self.collectionView.contentInset.left, (section == 0? 0: realInteritemSpacing)+maxH, self.collectionView.bounds.size.width, headerSize.height);
			self.framesForHeaderSection[@(section)] = [NSValue valueWithCGRect:headerFrame];
			
			maxH += headerFrame.size.height+realInteritemSpacing;
			offset.x = 0;
			offset.y = maxH;
		}
		
		for(NSInteger item = 0; item < items; item++){
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
			CGSize thisCellSize = CGSizeMake(cellWidthToUse, cellWidthToUse);
			BOOL foundANonSquared = NO;
			
			NSInteger currentColumn = offset.x/(cellWidthToUse+realInteritemSpacing);
			if(!self.attributesForIndexPath[indexPath]){
				if([self.collectionView.delegate conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)] && [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]){
					CGSize preferredItemSize = [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
					
					//if it is > 1 then the photo is in landscape else it is in portrait or it is squared
					CGFloat cellRatio = preferredItemSize.width/preferredItemSize.height;
					
					
					NSInteger leftColumns = columns-currentColumn;
					for(NSDictionary *thisNonSquaredFrameDict in self.nonSquaredRects){
						CGRect thisRect = [thisNonSquaredFrameDict[@"frame"] CGRectValue];
						if(offset.y < CGRectGetMaxY(thisRect) && offset.x <= thisRect.origin.x){
							//				NSInteger nonSquaredColumns = (lastNonSquaredRect.size.width+realInteritemSpacing)/(cellWidthToUse+realInteritemSpacing);
							
							//it should be minimum 0
							leftColumns = MIN([thisNonSquaredFrameDict[@"column"] integerValue]-currentColumn, leftColumns);
						}
					}
					DLog(@"current column %li leftColumns %li", (long)currentColumn, (long)leftColumns);
					
					if(self.fullImagePercentageOfOccurrency != -1 && currentColumn < columns && leftColumns >= self.maxCellSpace-1){
						int roll = 1+arc4random()%100;
						
						if(roll >= 100-self.fullImagePercentageOfOccurrency){
							NSInteger numberOfWColumns = MIN((cellRatio <= 1 ? self.maxCellSpace-1: self.maxCellSpace), leftColumns);
							NSInteger numberOfYColumns = MAX(1, roundf(numberOfWColumns/cellRatio));
							
							if(fabs(numberOfYColumns-numberOfWColumns) >= 1){
								
								DLog(@"nonSquaredCell: %li x %li", (long)numberOfWColumns, (long)numberOfYColumns);
								
								CGFloat width = cellWidthToUse*numberOfWColumns + (numberOfWColumns-1)*realInteritemSpacing;
								CGFloat height = cellWidthToUse*numberOfYColumns + (numberOfYColumns-1)*realInteritemSpacing;
								
								thisCellSize = CGSizeMake(width, height);
								
								foundANonSquared = YES;
							}
						}
					}
					
				}
				
				CGRect thisCellRect = CGRectMake(offset.x, offset.y, thisCellSize.width, thisCellSize.height);
				if(foundANonSquared){
					[self.nonSquaredRects addObject:@{@"frame": [NSValue valueWithCGRect:thisCellRect], @"column": @(currentColumn)}];
				}
				
				BOOL goodRect = NO;
				while (goodRect == NO) {
					offset.x += realInteritemSpacing+cellWidthToUse;
					
					if(offset.x >= self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right){
						offset.x = 0;
						offset.y += cellWidthToUse+realInteritemSpacing;
					}
					
					goodRect = YES;
					for(NSDictionary *thisNonSquaredFrameDict in self.nonSquaredRects){
						CGRect thisRect = [thisNonSquaredFrameDict[@"frame"] CGRectValue];
						if(CGRectContainsPoint(thisRect, offset)){
							goodRect = NO;
						}
					}
				}
				
				if(maxH < CGRectGetMaxY(thisCellRect)){
					maxH = CGRectGetMaxY(thisCellRect);
				}
				
				
				UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
				attributes.frame = thisCellRect;
				
				self.attributesForIndexPath[indexPath] = attributes;
			} else {
				NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:item+1 inSection:section];
				CGRect thisCellRect = [self.attributesForIndexPath[indexPath] frame];
				
				if(!self.attributesForIndexPath[nextIndexPath]){
					BOOL goodRect = NO;
					while (goodRect == NO) {
						offset.x += realInteritemSpacing+cellWidthToUse;
						
						if(offset.x >= self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right){
							offset.x = 0;
							offset.y += cellWidthToUse+realInteritemSpacing;
						}
						
						goodRect = YES;
						for(NSDictionary *thisNonSquaredFrameDict in self.nonSquaredRects){
							CGRect thisRect = [thisNonSquaredFrameDict[@"frame"] CGRectValue];
							if(CGRectContainsPoint(thisRect, offset)){
								goodRect = NO;
							}
						}
					}
				} else {
					CGRect nextCellRect = [self.attributesForIndexPath[nextIndexPath] frame];
					offset = nextCellRect.origin;
				}
				
				if(maxH < CGRectGetMaxY(thisCellRect)){
					maxH = CGRectGetMaxY(thisCellRect);
				}
			}
		}
		
		//section footer
		
		if([self.collectionView.delegate conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)] && [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]){
			CGSize footerSize = [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:section];
			
			CGRect footerFrame = CGRectMake(-self.collectionView.contentInset.left, maxH+realInteritemSpacing, self.collectionView.bounds.size.width, footerSize.height);
			self.framesForFooterSection[@(section)] = [NSValue valueWithCGRect:footerFrame];
			
			maxH += footerFrame.size.height;
			offset.x = 0;
			offset.y = maxH;
		}
	}
	
	self.contentSize = CGSizeMake(self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right, maxH);
}

-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
	NSMutableArray *layoutAttributes = [NSMutableArray array];
	
	for (NSInteger section = 0, n = [self.collectionView numberOfSections]; section < n; section++) {
		NSIndexPath *sectionIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
		
		UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind: UICollectionElementKindSectionHeader atIndexPath:sectionIndexPath];
		
		if (!CGSizeEqualToSize(headerAttributes.frame.size, CGSizeZero) && CGRectIntersectsRect(headerAttributes.frame, rect)){
			[layoutAttributes addObject:headerAttributes];
		}
		
		/* It is simpler... but a lot lower!!
		for (int i = 0; i < [self.collectionView numberOfItemsInSection:section]; i++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
			UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
			if (CGRectIntersectsRect(rect, attributes.frame)) {
				[layoutAttributes addObject:attributes];
			}
		}*/
		if([self.collectionView numberOfItemsInSection:section]){
			//Binary algorithm to find matching rects! ^_^ A LOT faster.
			NSInteger mid = [self.collectionView numberOfItemsInSection:section]/2;
			NSInteger firstMatch = NSNotFound;
			
			NSInteger left = 0;
			NSInteger right = [self.collectionView numberOfItemsInSection:section];
			
			do {
				NSIndexPath *indexPath = [NSIndexPath indexPathForItem:mid inSection:section];
				UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
				
				if (CGRectIntersectsRect(rect, attributes.frame)) {
					firstMatch = mid;
				} else {
					if(attributes.frame.origin.y >= CGRectGetMaxY(rect)){
						right = mid-1;
					} else if(CGRectGetMaxY(attributes.frame) <= rect.origin.y){
						left = mid+1;
					}
					
					mid = (left+right)/2;
				}
			} while (mid >= 0 && mid < [self.collectionView numberOfItemsInSection:section] && firstMatch == NSNotFound && left > right);
			
			if(firstMatch != NSNotFound){
				//left part
				NSInteger killCount = 15;
				for(NSInteger j = firstMatch; j >= 0; j--){
					NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:section];
					UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
					if (CGRectIntersectsRect(rect, attributes.frame)) {
						[layoutAttributes insertObject:attributes atIndex:0];
					} else if(killCount == 0){
						break;
					} else {
						killCount--;
					}
				}
				
				killCount = 15;
				
				for(NSInteger j = firstMatch+1; j < [self.collectionView numberOfItemsInSection:section]; j++){
					NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:section];
					UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
					if (CGRectIntersectsRect(rect, attributes.frame)) {
						[layoutAttributes addObject:attributes];
					} else if(killCount == 0){
						break;
					} else {
						killCount--;
					}
				}
			}
		}
		
		
		UICollectionViewLayoutAttributes *footerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:sectionIndexPath];
		
		if (! CGSizeEqualToSize(footerAttributes.frame.size, CGSizeZero) && CGRectIntersectsRect(footerAttributes.frame, rect)){
			[layoutAttributes addObject:footerAttributes];
		}
	}
	
	return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
	
	if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
		attributes.frame = [self.framesForHeaderSection[@(indexPath.section)] CGRectValue];
	} else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
		attributes.frame = [self.framesForFooterSection[@(indexPath.section)] CGRectValue];
	}
	
	// If there is no header or footer, we need to return nil to prevent a crash from UICollectionView private methods.
	if(CGRectIsEmpty(attributes.frame)) {
		attributes = nil;
	}
	
	return attributes;
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
	return self.attributesForIndexPath[indexPath];
}

-(CGSize)collectionViewContentSize{
	return self.contentSize;
}

-(void) invalidateLayout{
	[super invalidateLayout];
	
	DLog(@"layout Invalidated");
}

@end
