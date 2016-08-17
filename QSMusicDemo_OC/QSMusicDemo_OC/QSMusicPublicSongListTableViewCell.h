//
//  QSMusicPublicSongListTableViewCell.h
//  QSMusicDemo_OC
//
//  Created by 陈少文 on 16/8/5.
//  Copyright © 2016年 qqqssa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QSMusicSongDatas.h"

@interface QSMusicPublicSongListTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgV;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIView *line;

- (void)updateWithData:(NSDictionary *)data;
- (void)updateWithModel:(QSMusicSongDatas *)model;

@end
