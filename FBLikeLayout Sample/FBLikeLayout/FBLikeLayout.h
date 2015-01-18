//
//  FBLikeLayout.h
//  FPhoto Manager
//
//  Created by Giuseppe Lanza on 27/12/14.
//  Copyright (c) 2014 lanuovaera. All rights reserved.
//

#import <UIKit/UIKit.h>


//WARNING: in order to get this layout working you MUST implement the collectionView:layout:sizeForItemAtIndexPath: delegate method, or you will have only squared cells.

@interface FBLikeLayout : UICollectionViewFlowLayout

//The minimum width for a single cell This is intended as the width when the cell is a square.
@property (nonatomic, assign) CGFloat singleCellWidth;

//The max number of cells space that a single cell can have horizontally. Defaults to 3. A single cell space is intended to be the single square place.
@property (nonatomic, assign) NSInteger maxCellSpace;

//set to YES if you want the minimumInteritemSpace to be respected ALWAYS. The singleCellWidth Will be at this point the MINIMUM cell width, and will be resized in order to fit the criteria.
@property (nonatomic, assign) BOOL forceCellWidthForMinimumInteritemSpacing;

//The probability that the cell will be a full image cell expressed in percentage (1 to 100). Defaults to 30. set to -1 if you only need squared cells. No full images would be displayed in this case.
@property (nonatomic, assign) NSInteger fullImagePercentageOfOccurrency;

@end
