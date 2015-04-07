//
//  ViewController.m
//  LxDragToDismissBadgeLabelDemo
//
//  Created by Jin on 15-4-7.
//  Copyright (c) 2015年 etiantian. All rights reserved.
//

#import "ViewController.h"
#import "LxDragToDismissBadgeLabel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LxDragToDismissBadgeLabel * badgeLabel = [[LxDragToDismissBadgeLabel alloc]initWithCenter:CGPointMake(160, 200) radius:20];
    badgeLabel.text = @"999+";
    badgeLabel.maxStretchDistance = 200;
    badgeLabel.dismissAction = ^(CGPoint dragLocation, CGFloat dragDistance) {
        NSLog(@"dragLocation = %@", NSStringFromCGPoint(dragLocation));    //
        NSLog(@"dragDistance = %@", @(dragDistance));    //
    };
    [self.view addSubview:badgeLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
