//
//  CWViewController.m
//  CWEyeFiServer
//
//  Created by Michael Litvak on 07/24/2014.
//  Copyright (c) 2014 Michael Litvak. All rights reserved.
//

#import "CWViewController.h"
#import <CWEyeFiServer/CWEyeFiServer.h>

@interface CWViewController ()

@end

@implementation CWViewController {
    UITableView *_tableView;
    
    NSMutableArray *_files;
    
    CWEyeFiServer *_eyeFiServer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _files = [NSMutableArray array];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
    
    // upload key from ~/Library/Eye-Fi/Settings.xml
    _eyeFiServer = [[CWEyeFiServer alloc] initWithUploadKey:@"414e04d29f91352dedabdb95674d612d"];
    
    NSError *error;
    [_eyeFiServer start:&error];
    
    if (error) {
        NSLog(@"Failed to start server: %@", error);
    } else {
        NSLog(@"Eye-Fi server started");
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileStatusNotification:) name:CWNotificationFileStatus object:nil];
}

- (void)fileStatusNotification:(NSNotification *)note {
    NSString *status = [note.userInfo valueForKey:@"status"];
    NSString *filePath = [note.userInfo valueForKey:@"path"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([status isEqual:@(FileStatusUploading)]) {
        } else if ([status isEqual:@(FileStatusReady)]) {
            [_files addObject:[filePath lastPathComponent]];
            [_tableView reloadData];
        }
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_files count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileCell"];
    }
    
    cell.textLabel.text = [_files objectAtIndex:indexPath.row];
    
    return cell;
}

@end
