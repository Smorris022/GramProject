//
//  ViewController.m
//  GramProject
//
//  Created by stephan morris on 5/28/16.
//  Copyright © 2016 morrs. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *logIn;
@property (weak, nonatomic) IBOutlet UIButton *logOutBtn;

@property (weak, nonatomic) IBOutlet UIButton *refreshBtn;
@property (weak, nonatomic) IBOutlet UIImageView *gramPic;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logOutBtn.enabled = false;
    self.refreshBtn.enabled = false;
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logInPressed:(id)sender {
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Instagram"];
    self.logIn.enabled = false;
    self.logOutBtn.enabled = true;
    self.refreshBtn.enabled = true;
}
- (IBAction)logOutPressed:(id)sender {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *instagramAccounts = [store accountsWithAccountType:@"Instagram"];
    for (id acct in instagramAccounts)
        [store removeAccount:acct];
    self.logOutBtn.enabled = false;
    self.refreshBtn.enabled = false;
    self.logIn.enabled = true;
}
- (IBAction)refreshPressed:(id)sender {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *instagramAccounts = [store accountsWithAccountType:@"Instagram"];
    if ([instagramAccounts count] == 0){
        NSLog(@"Warning: %ld accounts are logged in", (long)[instagramAccounts count]);
        return;
    }
    NXOAuth2Account *acct = instagramAccounts[0];
    NSString *token = acct.accessToken.accessToken;
    NSString *urlstr = [@"https://api.instagram.com/v1/users/self/media/recent/?access_token=" stringByAppendingString:token];
    NSURL *url = [NSURL URLWithString:urlstr];
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    
    [[urlSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        //check for network error
        if (error) {
            NSLog(@"Error: Couldn't finish request: %@", error);
            return;
        }
        
        //check for http error
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *) response;
        if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
            NSLog(@"Error: Got status code %ld", (long) httpResp.statusCode);
            return;
        }
        
        //Check for JSON parse error
        NSError *parseErr;
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseErr];
        if (!pkg) {
            NSLog(@"Error: Couldn't parse response: %@", parseErr);
            return;
        }
        
        NSString *imgageURLStr = pkg[@"data"][0][@"images"][@"standard_resolution"][@"url"];
        NSURL *imageURL = [NSURL URLWithString:imgageURLStr];
        [[urlSession dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
            //check for network error
            if (error) {
                NSLog(@"Error: Couldn't finish request: %@", error);
                return;
            }
            
            //check for http error
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *) response;
            if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
                NSLog(@"Error: Got status code %ld", (long) httpResp.statusCode);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.gramPic.image = [UIImage imageWithData:data];
            });

        }
          ]resume];
            
            
            
            
    }]resume];
}

@end
