//
//  ISItemViewController.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 12/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISItemViewController.h"

@interface ISItemViewController ()

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation ISItemViewController

- (id)initWithItem:(NSString *)item
{
  self = [super init];
  if (self) {
    self.item = item;
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.imageView];
    
    // Load the image.
    
    
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
