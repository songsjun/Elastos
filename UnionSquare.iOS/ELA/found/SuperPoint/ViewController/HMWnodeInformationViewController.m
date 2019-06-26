//
//  HMWnodeInformationViewController.m
//  ELA
//
//  Created by  on 2019/1/6.
//  Copyright © 2019 HMW. All rights reserved.
//

#import "HMWnodeInformationViewController.h"

#import "HMWtheCandidateListViewController.h"
#import "FLNotePointDBManager.h"
#import "HMWFMDBManager.h"
#import "nodeInformationDetailsView.h"
@interface HMWnodeInformationViewController ()
//@property (weak, nonatomic) IBOutlet UIView *infoBGView;
//
//@property (weak, nonatomic) IBOutlet UILabel *nickNameLab;
//@property (weak, nonatomic) IBOutlet UILabel *nodePubKeyLab;
//@property (weak, nonatomic) IBOutlet UILabel *ticketNumbLab;
//@property (weak, nonatomic) IBOutlet UILabel *ticketRateLab;
//@property (weak, nonatomic) IBOutlet UILabel *contryCodeLab;
//@property (weak, nonatomic) IBOutlet UILabel *urlLab;
//
//@property (weak, nonatomic) IBOutlet UILabel *tagNickNameLab;
//@property (weak, nonatomic) IBOutlet UILabel *tagNodePubKeyLab;
//@property (weak, nonatomic) IBOutlet UILabel *tagTicketNumbLab;
//@property (weak, nonatomic) IBOutlet UILabel *tagTicketRateLab;
//@property (weak, nonatomic) IBOutlet UILabel *tagContryCodeLab;
//@property (weak, nonatomic) IBOutlet UILabel *tagUrlLab;
//
//
//@property (weak, nonatomic)IBOutlet UIImageView *iconImageView;
//@property (weak, nonatomic) IBOutlet UIButton *joinTheCandidateListButton;
//@property (weak, nonatomic) IBOutlet UIButton *lookAtTheCandidateListButton;

@property(nonatomic,assign)BOOL hasModel;
/*
 *
 */
@property(strong,nonatomic)UIImageView *siconImageView;
/*
 *<# #>
 */
//@property(strong,nonatomic)UILabel *nodeNameTextLabel;
/*
 *<# #>
 */
@property(strong,nonatomic)UILabel *nodeNameLabel;
/*
 *<# #>
// */
//@property(strong,nonatomic)UILabel *nodeAddressTextLabel;
///*
// *<# #>
// */
//@property(strong,nonatomic)UILabel *nodeAddressLabel;
///*
// *<# #>
// */
//@property(strong,nonatomic)UILabel *currantVotesTextLabel;
///*
// *<# #>
// */
//@property(strong,nonatomic)UILabel *currantVotesLabel;
///*
// *<# #>
// */
//@property(strong,nonatomic)UILabel *votePercentageTextLabel;
///*
// *<# #>
// */
//@property(strong,nonatomic)UILabel *votePercentageLabel;
///*
// *<# #>
// */
//@property(strong,nonatomic)UILabel *countryRegionTextLabel;
///*
// *<# #>
// */
//@property(strong,nonatomic)UILabel *countryRegionLabel;
//@property(strong,nonatomic)UILabel *URLTextLabel;
//@property(strong,nonatomic)UILabel *URLLabel;
/*
 *<# #>
 */
@property(strong,nonatomic)UIButton*copURLButton;
/*
 *<# #>
 */
@property(strong,nonatomic)UIButton *joinTheCandidateListButton;
/*
 *<# #>
 */
@property(copy,nonatomic)UIButton *lookAtTheCandidateListButton;
/*
 *<# #>
 */
@property(strong,nonatomic)nodeInformationDetailsView *nodeInformationDetailsV;


@end

         
         
@implementation HMWnodeInformationViewController
- (void)viewDidLoad {
   [super viewDidLoad];
    NSLog(@"viewDidLoad");
  [self defultWhite];
    [self setBackgroundImg:@""];
     self.title=NSLocalizedString(@"节点信息", nil) ;
    [self makeUI];
    

   

    
    
}
-(UIButton *)lookAtTheCandidateListButton{
    if (!_lookAtTheCandidateListButton) {
        _lookAtTheCandidateListButton =[[UIButton alloc]init];
        [_lookAtTheCandidateListButton setTitle:NSLocalizedString(@"查看候选列表", nil) forState:UIControlStateNormal];
        [_lookAtTheCandidateListButton setImage:[UIImage imageNamed:@"found_vote_look_over"] forState:UIControlStateNormal];
       _lookAtTheCandidateListButton.titleLabel.font =[UIFont systemFontOfSize:14];
        [[HMWCommView share]makeBordersWithView:_lookAtTheCandidateListButton];
        [_lookAtTheCandidateListButton addTarget:self action:@selector(lookAtTheCandidateListEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _lookAtTheCandidateListButton;
}
-(UIButton *)joinTheCandidateListButton{
    if (!_joinTheCandidateListButton) {
        _joinTheCandidateListButton =[[UIButton alloc]init];
       
        [_joinTheCandidateListButton setImage:[UIImage imageNamed:@"found_vote_add"] forState:UIControlStateNormal];
        _joinTheCandidateListButton.titleLabel.font =[UIFont systemFontOfSize:14];
         [[HMWCommView share]makeBordersWithView:_joinTheCandidateListButton];
        [_joinTheCandidateListButton addTarget:self action:@selector(joinTheCandidateListEvent:) forControlEvents:UIControlEventTouchUpInside];
        NSArray *walletArray=[NSArray arrayWithArray:[[HMWFMDBManager sharedManagerType:walletType] allRecordWallet]];
  
        
             FMDBWalletModel *model=walletArray[[[STANDARD_USER_DEFAULT valueForKey:selectIndexWallet] integerValue]];
           BOOL ret = [[FLNotePointDBManager defultWithWalletID:model.walletID]hasModel:self.model];
            self.hasModel = ret;
            if (ret) {
                [self.joinTheCandidateListButton setTitle:NSLocalizedString(@"移出候选列表", nil) forState:UIControlStateNormal];
            }else{
                 [_joinTheCandidateListButton setTitle:NSLocalizedString(@"加入候选列表", nil)  forState:UIControlStateNormal];
            }
        
            if (self.model.active==0) {
                self.joinTheCandidateListButton.enabled = NO;
            }else{
                self.joinTheCandidateListButton.enabled = YES;
            }
        
    }
    return _joinTheCandidateListButton;
}
-(UIButton *)copURLButton{
    if (!_copURLButton) {
        _copURLButton =[[UIButton alloc]init];
        [_copURLButton setImage:[UIImage imageNamed:@"asset_transfer_copyW"] forState:UIControlStateNormal];
        [_copURLButton addTarget:self action:@selector(copyURLEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _copURLButton;
}
-(UIImageView *)siconImageView{
    if (!_siconImageView) {
        _siconImageView =[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 56, 30)];
        _siconImageView.layer.cornerRadius  =1.f;
        _siconImageView.layer.borderWidth   =1.f;
        _siconImageView.layer.borderColor   =RGBA(255, 255, 255, 0.8).CGColor;
        _siconImageView.image=[UIImage imageNamed:@"found_vote_initial"];
    }
    return _siconImageView;
}
-(void)makeUI{
    UIView *BGView =[[UIView alloc]init];
    BGView.backgroundColor=RGBA(0, 0, 0, 0.5);
    [self.view addSubview:BGView];
    [[HMWCommView share]makeBordersWithView:BGView];
    [BGView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).mas_equalTo(74);
        make.left.equalTo(self.view.mas_left).mas_offset(15);
        make.right.equalTo(self.view.mas_right).mas_offset(-15);
        make.height.mas_equalTo(@400);
    }];
    [BGView addSubview:self.siconImageView];
    [self.siconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(BGView.mas_top).mas_offset(36);
        make.size.mas_equalTo(CGSizeMake(55, 30));
        
    }];
    self.nodeNameLabel=[self labeWithTextColor:[UIColor whiteColor] withText:self.model.nickname withTextFont:14 withTextAlignment:NSTextAlignmentCenter];
    [BGView addSubview:self.nodeNameLabel];
    [self.nodeNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(BGView.mas_right).offset(-15);
        make.top.equalTo(self.siconImageView.mas_bottom).offset(15);
        make.height.mas_equalTo(@15);
        make.left.equalTo(BGView.mas_left).offset(15);
    }];
    [BGView addSubview:self.nodeInformationDetailsV];
    [self.nodeInformationDetailsV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nodeNameLabel.mas_bottom).offset(15);
        make.bottom.equalTo(BGView);
        make.left.equalTo(BGView.mas_left).offset(15);
        make.right.equalTo(BGView.mas_right).offset(-15);
    }];
    [self.view addSubview:self.lookAtTheCandidateListButton];
    [self.lookAtTheCandidateListButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(63);
        make.right.equalTo(self.view.mas_right).offset(-63);
        make.bottom.equalTo(self.view.mas_bottom).offset(-40);
        make.height.mas_equalTo(@40);
        
    }];
    [self.view addSubview:self.joinTheCandidateListButton];
    [self.joinTheCandidateListButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(63);
        make.right.equalTo(self.view.mas_right).offset(-63);
    make.bottom.equalTo(self.lookAtTheCandidateListButton.mas_top).offset(-20);
        make.height.mas_equalTo(@40);
        
    }];
  
    dispatch_group_t group =  dispatch_group_create();
 __block NSString *URL;
    __block NSString *countries;
    if (self.model.iconImageUrl.length>0) {
        URL=self.model.iconImageUrl;
    }
    if (self.model.url.length>0&&self.model.iconImageUrl.length==0) {
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        URL=[[FLTools share] getImageViewURLWithURL:self.model.url];
    });
        
    }
   
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      countries=[[FLTools share]contryNameTransLateByCode:  self.model.location.integerValue];
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        self.nodeInformationDetailsV.countryRegionLabel.text=countries;
        if (URL.length>0&&self.model.url.length>0) {
           [self.siconImageView sd_setImageWithURL:[NSURL URLWithString:URL] placeholderImage:[UIImage imageNamed:@"found_vote_initial"]];
        }
    });
    [self upInfo];

}
-(nodeInformationDetailsView *)nodeInformationDetailsV{
    if (!_nodeInformationDetailsV) {
        _nodeInformationDetailsV =[[nodeInformationDetailsView alloc]init];
        _nodeInformationDetailsV.model=self.model;
        [_nodeInformationDetailsV.copURLButton addTarget:self action:@selector(copyURLEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nodeInformationDetailsV;
}
-(void)upInfo{
    NSArray *walletArray=[NSArray arrayWithArray:[[HMWFMDBManager sharedManagerType:walletType] allRecordWallet]];
   FMDBWalletModel *model=walletArray[[[STANDARD_USER_DEFAULT valueForKey:selectIndexWallet] integerValue]];
        BOOL ret = [[FLNotePointDBManager defultWithWalletID:model.walletID]hasModel:self.model];
        self.hasModel = ret;

        [self.joinTheCandidateListButton setTitle:NSLocalizedString(@"加入候选列表", nil)  forState:UIControlStateNormal];
          [self.lookAtTheCandidateListButton setTitle:NSLocalizedString(@"查看候选列表", nil)  forState:UIControlStateNormal];
        if (ret) {
            [self.joinTheCandidateListButton setTitle:NSLocalizedString(@"移出候选列表", nil) forState:UIControlStateNormal];
        }
        if (self.model.active==0) {
            self.joinTheCandidateListButton.enabled = NO;
        }else{
            self.joinTheCandidateListButton.enabled = YES;
        }


}
- (IBAction)copyURLEvent:(id)sender {
    [UIPasteboard generalPasteboard].string = self.model.url;
}
- (IBAction)lookAtTheCandidateListEvent:(id)sender {
  
    HMWtheCandidateListViewController *theCandidateListVC=[[HMWtheCandidateListViewController alloc]init];
    
    [self.navigationController pushViewController:theCandidateListVC animated:YES];
}
- (IBAction)joinTheCandidateListEvent:(id)sender {
    
    NSArray *walletArray=[NSArray arrayWithArray:[[HMWFMDBManager sharedManagerType:walletType] allRecordWallet]];
    FMDBWalletModel *model =walletArray[[[STANDARD_USER_DEFAULT valueForKey:selectIndexWallet] integerValue]];
    if (self.hasModel) {
        BOOL ret =  [[FLNotePointDBManager defultWithWalletID:model.walletID]delectRecord:self.model];
        if (ret) {
            [[FLTools share]showErrorInfo:NSLocalizedString(@"删除成功",nil)];

            [self.navigationController popViewControllerAnimated:YES];
        }else{
            [[FLTools share]showErrorInfo:NSLocalizedString(@"删除失败", nil)];
        }
    }else{
       
        
    BOOL ret =  [[FLNotePointDBManager defultWithWalletID:model.walletID]addRecord:self.model];
    if (ret) {
        [self.joinTheCandidateListButton setTitle:NSLocalizedString(@"移出候选列表", nil) forState:UIControlStateNormal];
        self.hasModel = YES;
        [[FLTools share]showErrorInfo:NSLocalizedString(@"添加成功",nil)];

    }else{
        [[FLTools share]showErrorInfo:NSLocalizedString(@"添加失败", nil)];
    }
    }
}
-(void)setModel:(FLCoinPointInfoModel *)model
{
    _model = model;
}
-(UILabel*)labeWithTextColor:(UIColor*)color withText:(NSString*)text withTextFont:(CGFloat)font withTextAlignment:(NSTextAlignment)TextA{
    UILabel *labe =[[UILabel alloc]init];
    labe.text=text;
    labe.textAlignment=TextA;
    labe.font=[UIFont systemFontOfSize:font];
    labe.numberOfLines=0;
    labe.textColor=color;
    return labe;
}

@end
