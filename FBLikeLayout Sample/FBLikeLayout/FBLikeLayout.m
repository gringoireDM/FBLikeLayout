//
//  FBLikeLayout.m
//  FPhoto Manager
//
//  Created by Giuseppe Lanza on 27/12/14.
//  Copyright (c) 2014 lanuovaera. All rights reserved.
//

#import "FBLikeLayout.h"

@interface MatrixElement : NSObject

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSInteger columns;
@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, copy) NSIndexPath *indexPath;
@property (nonatomic, strong) UICollectionViewLayoutAttributes *attributes;

@end

@implementation MatrixElement

-(instancetype)init{
	self = [super init];
	
	if(self){
		self.frame = CGRectZero;
		self.columns = 0;
		self.rows = 0;
		self.indexPath = nil;
	}
	
	return self;
}

-(NSString *)description{
	return [NSString stringWithFormat:@"MatrixElemnt %lix%li for indexPath: %li - %li, frame: %@", self.columns, self.rows, self.indexPath.item, self.indexPath.section, NSStringFromCGRect(self.frame)];
}

@end

@interface FBLikeLayout()

@property (nonatomic, strong) NSMutableDictionary *attributesForIndexPath;
@property (nonatomic, strong) NSMutableDictionary *framesForHeaderSection;
@property (nonatomic, strong) NSMutableDictionary *framesForFooterSection;
@property (nonatomic, strong) NSMutableArray *sectionMatrices;

@property (nonatomic, assign) CGSize contentSize;

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
	//DLog(@"Dealloc called");
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

-(NSMutableArray *)sectionMatrices{
	if(!_sectionMatrices)
		_sectionMatrices = [NSMutableArray new];
	
	return _sectionMatrices;
}

-(NSInteger) voidElementsInRow:(NSArray *) row fromColumn:(NSInteger)column{
	NSInteger count = 0;
	
	for(NSInteger i = column; i < row.count; i++){
		if(CGRectIsEmpty([(MatrixElement *)row[i] frame])){
			count++;
		} else {
			break;
		}
	}
	
	return count;
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
	
	int columns = floorf((self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right)/cellWidthToUse);
	
	CGFloat realInteritemSpacing = MAX(self.minimumInteritemSpacing, (self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right-(float)columns*cellWidthToUse)/(columns-1));
	
	if(self.forceCellWidthForMinimumInteritemSpacing && realInteritemSpacing != self.minimumInteritemSpacing){
		cellWidthToUse = (self.collectionView.bounds.size.width-self.collectionView.contentInset.left-self.collectionView.contentInset.right-self.minimumInteritemSpacing*(columns-1))/columns;
		
		realInteritemSpacing = self.minimumInteritemSpacing;
	}
	
	NSInteger sections = [self.collectionView numberOfSections];

	CGFloat maxH = 0;
	
	__block CGPoint offset = CGPointZero;

	for(NSInteger section = 0; section < sections; section++){
		NSInteger items = [self.collectionView numberOfItemsInSection:section];
		
		//Section Header
		if([self.collectionView.delegate conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)] && [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]){
			CGSize headerSize = [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
			
			CGRect headerFrame = CGRectMake(-self.collectionView.contentInset.left, (section == 0? 0: 2*realInteritemSpacing)+maxH, self.collectionView.bounds.size.width, headerSize.height);
			self.framesForHeaderSection[@(section)] = [NSValue valueWithCGRect:headerFrame];
			
			maxH += headerFrame.size.height+realInteritemSpacing+(section == 0? 0: 2*realInteritemSpacing);
			offset.x = 0;
			offset.y = maxH;
		}
		
		NSInteger currentRow = 0;
		NSInteger currentColumn = 0;
		
		NSMutableArray *reticleMatrix = nil;
		NSMutableDictionary *boundedMatrices = nil;
		
		if(section < self.sectionMatrices.count){
			 boundedMatrices = self.sectionMatrices[section];
			
		} else {
			boundedMatrices = [NSMutableDictionary new];
			[self.sectionMatrices addObject:boundedMatrices];
		}
		
		
		if(boundedMatrices[NSStringFromCGSize(self.collectionView.bounds.size)]){
			reticleMatrix = boundedMatrices[NSStringFromCGSize(self.collectionView.bounds.size)];
		} else{
			reticleMatrix = [NSMutableArray new];
			boundedMatrices[NSStringFromCGSize(self.collectionView.bounds.size)] = reticleMatrix;
		}
		CGFloat oldOffset = [boundedMatrices[@"sectionOffset"] floatValue];
		boundedMatrices[@"sectionOffset"] = @(maxH);
		BOOL lastCached = NO;

		for(NSInteger item = 0; item < items; item++){
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SUBQUERY(SELF.indexPath, $a, $a == %@).@count != 0", indexPath];
			
			NSArray *row = [[reticleMatrix filteredArrayUsingPredicate:predicate] firstObject];
			
			MatrixElement *thisElement = nil;
			if(row){
				for(MatrixElement *element in row){
					if([element.indexPath isEqual:indexPath])
						thisElement = element;
				}
				
				currentRow = [reticleMatrix indexOfObject:row];
				currentColumn = [row indexOfObject:thisElement];
				//DLog(@"Restoring item %li, %li", currentRow, currentColumn);
				
				CGRect frame = thisElement.frame;
				frame.origin.y -= oldOffset;
				frame.origin.y += [boundedMatrices[@"sectionOffset"] floatValue];
				
				offset.x = frame.origin.x;
				offset.y = frame.origin.y;
				
				thisElement.frame = frame;
				thisElement.attributes.frame = frame;
				
				if(maxH < CGRectGetMaxY(frame)){
					maxH = CGRectGetMaxY(frame);
				}
				
				self.attributesForIndexPath[indexPath] = thisElement.attributes;
				
				//update the current row and column and offsets
				lastCached = YES;
			} else {
				if(lastCached){
					[self findNextFreeCell:&currentRow currentColumn:&currentColumn reticleMatrix:reticleMatrix withdidAddRowBlock:^{
						offset.y += cellWidthToUse+realInteritemSpacing;
					}];
				}
				
				lastCached = NO;
				
				CGSize thisCellSize = CGSizeMake(cellWidthToUse, cellWidthToUse);
				
				NSMutableArray *currentRowArray = nil;
				if (currentColumn == 0 && reticleMatrix.count <= currentRow){
					currentRowArray = [self addRowOfItems:columns];
					[reticleMatrix addObject:currentRowArray];
				} else {
					currentRowArray = [reticleMatrix objectAtIndex:currentRow];
				}
				
				offset.x = currentColumn*(cellWidthToUse+realInteritemSpacing);
				
				MatrixElement *thisCellElement = currentRowArray[currentColumn];
				thisCellElement.indexPath = indexPath;
				thisCellElement.columns = 1;
				thisCellElement.rows = 1;
				
				if([self.collectionView.delegate conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)] && [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]){
					CGSize preferredItemSize = [(id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
					
					//if it is > 1 then the photo is in landscape else it is in portrait or it is squared
					CGFloat cellRatio = preferredItemSize.width/preferredItemSize.height;
					
					NSInteger leftColumns = [self voidElementsInRow:currentRowArray fromColumn:currentColumn];
					//DLog(@"current column %li leftColumns %li", (long)currentColumn, (long)leftColumns);
					
					if(self.fullImagePercentageOfOccurrency != -1 && currentColumn < columns && leftColumns >= self.maxCellSpace-1){
						int roll = 1+arc4random()%100;
						
						if(roll >= 100-self.fullImagePercentageOfOccurrency){
							NSInteger numberOfWColumns = MIN((cellRatio <= 1 ? self.maxCellSpace-1: self.maxCellSpace), leftColumns);
							NSInteger numberOfYColumns = MAX(1, roundf(numberOfWColumns/cellRatio));
							
							if(fabs(numberOfYColumns-numberOfWColumns) >= 1){
								
								//DLog(@"nonSquaredCell: %li x %li", (long)numberOfWColumns, (long)numberOfYColumns);
								
								CGFloat width = cellWidthToUse*numberOfWColumns + (numberOfWColumns-1)*realInteritemSpacing;
								CGFloat height = cellWidthToUse*numberOfYColumns + (numberOfYColumns-1)*realInteritemSpacing;
								
								thisCellSize = CGSizeMake(width, height);
								
								thisCellElement.columns = numberOfWColumns;
								thisCellElement.rows = numberOfYColumns;
								
								for(NSInteger j = currentRow; j < currentRow+numberOfYColumns; j++){
									NSMutableArray *processingRow = nil;
									if(reticleMatrix.count <= j){
										processingRow = [self addRowOfItems:columns];
										[reticleMatrix addObject:processingRow];
									} else {
										processingRow = reticleMatrix[j];
									}
									
									for(NSInteger i = currentColumn; i < currentColumn+numberOfWColumns; i++){
										[processingRow replaceObjectAtIndex:i withObject:thisCellElement];
									}
								}
							}
						}
					}
					
					CGRect thisCellRect = CGRectMake(offset.x, offset.y, thisCellSize.width, thisCellSize.height);
					thisCellElement.frame = thisCellRect;
					
					if(maxH < CGRectGetMaxY(thisCellRect)){
						maxH = CGRectGetMaxY(thisCellRect);
					}
					
					UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
					attributes.frame = thisCellRect;
					
					thisCellElement.attributes = attributes;
					self.attributesForIndexPath[indexPath] = thisCellElement.attributes;
					
					//next free cell
					[self findNextFreeCell:&currentRow currentColumn:&currentColumn reticleMatrix:reticleMatrix withdidAddRowBlock:^{
						offset.y += cellWidthToUse+realInteritemSpacing;
					}];
				}
				
			}
			
		}
		
		
		//[self printMatrix:reticleMatrix];
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

-(void) findNextFreeCell:(NSInteger *) currentRow currentColumn:(NSInteger *)currentColumn reticleMatrix:(NSMutableArray *) reticleMatrix withdidAddRowBlock:(void(^)()) didAddRow{
	BOOL found = NO;
	NSInteger startingRow = *currentRow;
	for(NSInteger j = startingRow; j < reticleMatrix.count; j++){
		NSMutableArray *row = reticleMatrix[j];
		for(NSInteger i = (j== startingRow? *currentColumn+1: 0); i < row.count; i++){
			MatrixElement *element = row[i];
			if(CGRectIsEmpty(element.frame)){
				*currentColumn = i;
				found = YES;
				break;
			}
		}
		if(!found){
			*currentRow += 1;
			*currentColumn = 0;
			
			if(didAddRow)
				didAddRow();
		} else
			break;
	}
}

-(void) printMatrix:(NSMutableArray *) matrix{
	NSString *description = @"\n";
	for(NSInteger i = 0; i < matrix.count; i++){
		NSMutableArray *row = matrix[i];
		for(NSInteger j = 0; j < row.count; j++){
			MatrixElement *element = row[j];
			description = [description stringByAppendingFormat:@"\t %li", element.indexPath.item];
		}
		description = [description stringByAppendingString:@"\n"];
	}
	DLog(@"Matrix: %@", description);
}

-(NSMutableArray *) addRowOfItems:(NSInteger) items{
	NSMutableArray *row = [NSMutableArray new];
	for(NSInteger i = 0; i < items; i++){
		[row addObject:[MatrixElement new]];
	}
	
	return row;
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
			} while (mid >= 0 && mid < [self.collectionView numberOfItemsInSection:section] && firstMatch == NSNotFound && left < right);
			
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

-(void)prepareForCollectionViewUpdates:(NSArray *)updateItems{
	for(UICollectionViewUpdateItem *thisUpdate in updateItems){
		NSIndexPath *indexPath = nil;
		
		if(thisUpdate.updateAction == UICollectionUpdateActionDelete){
			indexPath = [thisUpdate indexPathBeforeUpdate];
		} else if(thisUpdate.updateAction == UICollectionUpdateActionInsert){
			indexPath = [thisUpdate indexPathAfterUpdate];
		}
		
		NSMutableDictionary *boundedMatrices = nil;
		
		if(indexPath.section < self.sectionMatrices.count){
			boundedMatrices = self.sectionMatrices[indexPath.section];
		}
		
		for(NSMutableArray *reticleMatrix in [boundedMatrices allValues]){
			if([reticleMatrix isKindOfClass:[NSMutableArray class]]){
				NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SUBQUERY(SELF.indexPath, $a, $a == %@).@count != 0", indexPath];
				NSMutableArray *row = [[reticleMatrix filteredArrayUsingPredicate:predicate] firstObject];
				if(row){
					NSInteger rowsToDeleteFrom = -1;
					NSInteger rowIndex = [reticleMatrix indexOfObject:row];
					for(NSInteger i = rowIndex; i < reticleMatrix.count; i++){
						NSMutableArray *thisRow = reticleMatrix[i];
						NSInteger replacedCount = 0;
						for(NSInteger j = 0; j < thisRow.count; j++){
							if([(MatrixElement *)thisRow[j] indexPath].item >= indexPath.item){
								[thisRow replaceObjectAtIndex:j withObject:[MatrixElement new]];
								replacedCount++;
							}
						}
						
						if(replacedCount == thisRow.count){
							rowsToDeleteFrom = i;
							break;
						}
					}
					
					if(rowsToDeleteFrom != -1){
						[reticleMatrix removeObjectsInRange:NSMakeRange(rowsToDeleteFrom, reticleMatrix.count-rowsToDeleteFrom)];
					}
					[self printMatrix:reticleMatrix];
				}
			}
		}
		
		NSArray *keysToDelete = [[self.attributesForIndexPath allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"section == %@ && item >= %@", @(indexPath.section), @(indexPath.item)]];
		[self.attributesForIndexPath removeObjectsForKeys:keysToDelete];
	}
	
	[self invalidateLayout];
}

-(void) invalidateLayout{
	[super invalidateLayout];
	
	//DLog(@"layout Invalidated");
}

@end
