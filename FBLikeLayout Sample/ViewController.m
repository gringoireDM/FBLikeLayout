//
//  ViewController.m
//  FBLikeLayout Sample
//
//  Created by Giuseppe Lanza on 18/01/15.
//  Copyright (c) 2015 La Nuova Era. All rights reserved.
//

#import "ViewController.h"
#import "FBLikeLayout.h"
#import "ImageCollectionViewCell.h"

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray * sourceArray;

@end

@implementation ViewController

-(NSString *) sampleImagesBundlePath{
	return [[NSBundle mainBundle] pathForResource:@"SampleImages" ofType:@"bundle"];
}

-(NSMutableArray *) sourceArray {
	if(!_sourceArray){
		NSString *path = [self sampleImagesBundlePath];
		_sourceArray = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] mutableCopy];
	}
	
	return _sourceArray;
}

-(void)viewDidLayoutSubviews{
	[super viewDidLayoutSubviews];
	
	if(![self.collectionView.collectionViewLayout isKindOfClass:[FBLikeLayout class]]){
		FBLikeLayout *layout = [FBLikeLayout new];
		layout.minimumInteritemSpacing = 4;
		layout.singleCellWidth = (MIN(self.collectionView.bounds.size.width, self.collectionView.bounds.size.height)-self.collectionView.contentInset.left-self.collectionView.contentInset.right-8)/3.0;
		layout.maxCellSpace = 3;
		layout.forceCellWidthForMinimumInteritemSpacing = YES;
		layout.fullImagePercentageOfOccurrency = 25;
		self.collectionView.collectionViewLayout = layout;
		
		[self.collectionView reloadData];
	} else {
		//[self.collectionView.collectionViewLayout invalidateLayout];
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.title = @"FBLikeLayout";
	
	self.collectionView.contentInset = UIEdgeInsetsMake(4, 4, 4, 4);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (IBAction)addItemAction:(id)sender {
	static NSInteger position;
	NSString *objectToAdd = self.sourceArray[arc4random()%self.sourceArray.count];
	[self.sourceArray insertObject:objectToAdd atIndex:position];
	NSLog(@"Insert position = %li", (long)position);
	
	[self.collectionView performBatchUpdates:^{
		[self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:position inSection:0]]];
	} completion:nil];
	
	position++;
	if(position > 10)
		position = 0;
}

#pragma mark - CollectionView DataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return self.sourceArray.count;
}

-(UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	ImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
	cell.backgroundColor = [UIColor whiteColor];
	NSString *imagePath = [[self sampleImagesBundlePath] stringByAppendingPathComponent:self.sourceArray[indexPath.item]];
	
	cell.photoImageView.image = [UIImage imageWithContentsOfFile:imagePath];
	
	return cell;
}


-(CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	
	NSString *imagePath = [[self sampleImagesBundlePath] stringByAppendingPathComponent:self.sourceArray[indexPath.item]];
	CGSize finalSize = [UIImage imageWithContentsOfFile:imagePath].size;
	
	return finalSize;
}

@end
