//
//  HideStatusBarViewController.m
//  BJBStaticLog
//
//  Created by 李杰峰 on 2021/5/11.
//

#import "HideStatusBarViewController.h"

@interface HideStatusBarViewController ()

@end

@implementation HideStatusBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
