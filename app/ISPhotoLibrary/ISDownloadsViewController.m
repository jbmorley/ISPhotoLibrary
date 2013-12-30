//
//  ISDownloadsViewController.m
//  
//
//  Created by Jason Barrie Morley on 29/12/2013.
//
//

#import "ISDownloadsViewController.h"

@interface ISDownloadsViewController ()

@end

@implementation ISDownloadsViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (IBAction)doneClicked:(id)sender
{
  [self.delegate downloadsViewControllerDidFinish:self];
}

@end
