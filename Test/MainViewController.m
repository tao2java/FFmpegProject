//
//  MainViewController.m
//  Test
//
//  Created by shikee_app03 on 16/3/2.
//  Copyright © 2016年 lianqiang. All rights reserved.
//
#import "avformat.h"

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor whiteColor];
    [self getInputFormat];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)getInputFormat
{
    char info[40000] = { 0 };
    av_register_all();
    AVInputFormat *in_temp=av_iformat_next(NULL);
    AVOutputFormat *of_temp = av_oformat_next(NULL);
    while(in_temp!=NULL){
        sprintf(info, "%s[In ]%10s\n", info, in_temp->name);
        in_temp=in_temp->next;
    }
    //Output
    while (of_temp != NULL){
        sprintf(info, "%s[Out]%10s\n", info, of_temp->name);
        of_temp = of_temp->next;
    }
    //printf("%s", info);
    NSString * info_ns = [NSString stringWithFormat:@"%s", info];
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
