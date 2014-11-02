//
//  TweetsViewController.m
//  TwitterApp
//
//  Created by Rishit Shroff on 10/30/14.
//  Copyright (c) 2014 Rishit Shroff. All rights reserved.
//

#import "TweetsViewController.h"
#import "TwitterClient.h"
#import "User.h"
#import "Tweet.h"
#import "TweetCellTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "NewTweetUIViewController.h"
#import "DetailedTweetViewController.h"

@interface TweetsViewController ()

@property(nonatomic, strong) NSArray *tweets;
@property(nonatomic, strong) UIRefreshControl *refreshController;
@property(nonatomic, assign) long long maxId;
@property(nonatomic, assign) long long sinceId;

@end

@implementation TweetsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(onLogoutPressed)];
    
    [logoutButton setTintColor:[UIColor whiteColor]];
    
    UIBarButtonItem *newTweetButton = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(onNewTweetPressed)];
    [newTweetButton setTintColor:[UIColor whiteColor]];
    
    [self setTitle:@"Home"];
    [self.navigationItem setLeftBarButtonItem:logoutButton];
    [self.navigationItem setRightBarButtonItem:newTweetButton];
    
    if (self) {
        self.tweets = [NSMutableArray array];
        self.maxId = -1;
    }

    // Set the Background Color
    long rgbValue = 0x55ACEE;
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TweetCellTableViewCell" bundle:nil ] forCellReuseIdentifier:@"TweetCellTableViewCell"];
    
    [self.tableView setRowHeight:UITableViewAutomaticDimension];

    [self getData];
    // Refresh Controller
    self.refreshController = [[UIRefreshControl alloc] init];
    [self.refreshController addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshController atIndex:0];
}

-(void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onLogoutPressed {
    [User setCurrentUser:nil];
    [[TwitterClient sharedInstance].requestSerializer removeAccessToken];
}

- (void)onNewTweetPressed {
    [self presentNewTweetController:nil];
}

- (void)presentNewTweetController:(Tweet *)tweet {
    NewTweetUIViewController *nvc = [[NewTweetUIViewController alloc] init];
    
    if (tweet != nil) {
        [nvc setTweet:tweet];
    }
    [self presentViewController:nvc animated:true completion:nil];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:true];
    
    DetailedTweetViewController *dvc = [[DetailedTweetViewController alloc] init];
    dvc.tweet = self.tweets[indexPath.row];
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:dvc];
    [self presentViewController:nvc animated:YES completion:nil];
}

- (void) getData {
    [[TwitterClient sharedInstance] getTweets:self.maxId callback:^(NSArray *tweets, NSError *error) {
        [self.refreshController endRefreshing];
        if (error == nil) {
            self.tweets = tweets;
            //  [self.tableView setRowHeight:UITableViewAutomaticDimension];
            [self.tableView reloadData];
        }
    }];
}

-(void)onRefresh {
    // Issue the Async request;
    [[TwitterClient sharedInstance] getTweets:self.maxId callback:^(NSArray *tweets, NSError *error) {
        [self.refreshController endRefreshing];
        if (error == nil) {
            self.tweets = tweets;
            //  [self.tableView setRowHeight:UITableViewAutomaticDimension];
            [self.tableView reloadData];
        }
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TweetCellTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TweetCellTableViewCell" forIndexPath:indexPath];
    cell.delegate = self;
    [cell setTweet:self.tweets[indexPath.row]];
    return cell;
}

- (void) TweetCellTableViewCell:(TweetCellTableViewCell *)cell
                 didSelectReply:(BOOL)selected {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self presentNewTweetController:self.tweets[indexPath.row]];
}

- (void) TweetCellTableViewCell:(TweetCellTableViewCell *)cell
                     didreTweet:(BOOL)selected {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Tweet *tw = self.tweets[indexPath.row];
    [tw didRetweet];
}

- (void) TweetCellTableViewCell:(TweetCellTableViewCell *)cell
                   didFavorited:(BOOL)selected {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Tweet *tw = self.tweets[indexPath.row];
    [tw didFavoritedUser];
 }

@end
