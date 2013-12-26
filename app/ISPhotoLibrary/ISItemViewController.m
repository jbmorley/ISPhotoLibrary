//
//  ISItemViewController.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 12/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISItemViewController.h"
#import <ISCache/ISCache.h>

@interface ISItemViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation ISItemViewController

static NSString *kServiceRoot = @"http://localhost:8051";

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.imageView.alpha = 0.0f;
  self.progressView.alpha = 0.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  NSLog(@"Identifier: %@", self.identifier);
  NSString *url = [kServiceRoot stringByAppendingFormat:
                   @"/%@",
                   self.identifier];
  
  ISCache *defaultCache = [ISCache defaultCache];
  [defaultCache item:url
             context:kCacheContextURL
               block:^(ISCacheItemInfo *info) {
                 CGFloat progress = (CGFloat)info.totalBytesRead / (CGFloat)info.totalBytesExpectedToRead;
                 self.progressView.progress = progress;
                 if (info.state == ISCacheItemStateFound) {
                   self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
                   [UIView animateWithDuration:0.3f
                                    animations:^{
                                      self.progressView.alpha = 0.0f;
                                      self.imageView.alpha = 1.0f;
                                    }
                                    completion:^(BOOL finished) {
                                      self.progressView.hidden = YES;
                                    }];
                 }
               }];
  
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

@end
