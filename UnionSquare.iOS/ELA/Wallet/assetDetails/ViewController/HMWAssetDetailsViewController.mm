//
//  HMWAssetDetailsViewController.m
//  ELA
//
//  Created by  on 2018/12/26.
//  Copyright © 2018 HMW. All rights reserved.
//

#import "HMWAssetDetailsViewController.h"
#import "HMWAssetDetailsTableViewCell.h"
#import "HMWcollectionViewController.h"
#import "HMWtransferViewController.h"
#import "HMWChooseSideChainViewController.h"
#import "HMWtransferTransactionDetailsViewController.h"
#import "assetDetailsModel.h"
#import "HMWTop_upPageForDetailsViewController.h"
#import "ELWalletManager.h"
#import "showOwnerAddressTableViewCell.h"



static NSString *cellString=@"HMWAssetDetailsTableViewCell";
static NSString *showOwnerAddressCellString=@"showOwnerAddressTableViewCell";




@interface HMWAssetDetailsViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIButton *transferButton;
@property (weak, nonatomic) IBOutlet UIButton *topUpButton;

@property (weak, nonatomic) IBOutlet UIButton *collectionButton;
@property (weak, nonatomic) IBOutlet UITableView *baseTableView;

@property (weak, nonatomic) IBOutlet UILabel *balanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *currencyNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *updateTimeLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewHeightOff;

@property (weak, nonatomic) IBOutlet UILabel *noDataSourceTextLabel;

/*
 *<# #>
 */
@property(assign,nonatomic)NSInteger currentIndex;
/*
 *<# #>
 */
@property(assign,nonatomic)NSInteger allTotal;
/*
 *<# #>
 */
@property(strong,nonatomic)NSMutableArray *allListArray;

/*
 *<# #>
 */
@property(assign,nonatomic)BOOL isUpdate;
/*
 *<# #>
 */
@property(assign,nonatomic)NSInteger allTotalMAXCount;
/*
 *<# #>
 */
@property(strong,nonatomic)NSArray *allAddressAaary;
@property (weak, nonatomic) IBOutlet UILabel *transactionRecordsTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *voteBlanceLabel;

@property (weak, nonatomic) IBOutlet UILabel *voteElaLabel;
@property (weak, nonatomic) IBOutlet UILabel *allBlanceTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *voteBlanceTextLabel;
/*
 *<# #>
 */
@property(strong,nonatomic)NSMutableArray * NodeReturnsMutableArray;
/*
 *<# #>
 */
@property(assign,nonatomic)NSInteger NodeReturnsCurrentIndex;
/*
 *<# #>
 */
@property(assign,nonatomic)NSInteger NodeReturnsAllTotal;


/*
 *<# #>
 */
@property(assign,nonatomic)BOOL NodeReturnsIsUpdate;
/*
 *<# #>
 */
@property(assign,nonatomic)NSInteger NodeReturnsAllTotalMAXCount;
@property (weak, nonatomic) IBOutlet UIButton *anyChangeInTheWholeButton;
@property (weak, nonatomic) IBOutlet UIButton *transactionRecordsBtton;
@property (weak, nonatomic) IBOutlet UIButton *EarningsRecordButton;
/*
 *<# #>
 */
@property(copy,nonatomic)NSString *leftOrRight;
/*
 *<# #>
 */
@property(copy,nonatomic)NSString *OwnerAddressString;
@end

@implementation HMWAssetDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     [self defultWhite];

   [self setBackgroundImg:@""];
    [self makeView];
    self.isUpdate=NO;
    self.balanceLabel.text=[NSString stringWithFormat:@"%@",[[FLTools share]elaScaleConversionWith: self.model.iconBlance]];
    self.currencyNameLabel.text=@"ELA";
    self.updateTimeLabel.text=self.model.updateTime;
    self.currentIndex=0;
    [self loadAllTransactionWithIndex:self.currentIndex];
    
    [self.transferButton setTitle:NSLocalizedString(@"转账", nil) forState:UIControlStateNormal];
     [self.collectionButton setTitle:NSLocalizedString(@"收款", nil) forState:UIControlStateNormal];
    [self.transactionRecordsBtton setTitle:NSLocalizedString(@"交易记录", nil) forState:UIControlStateNormal];
    [self.EarningsRecordButton setTitle:NSLocalizedString(@"收益记录", nil) forState:UIControlStateNormal];
    self.topUpButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.anyChangeInTheWholeButton setTitle:NSLocalizedString(@"零钱换整", nil) forState:UIControlStateNormal];
    [self transactionRecordsAction:nil];
    [self.baseTableView setBackgroundColor:RGB(107, 133, 135)];
   
    if ([self.model.iconName isEqualToString:@"ELA"]) {
        [self GetRegisteredProducerInfo];
      
        
        
    }
}
-(void)GetRegisteredProducerInfo{
    ELWalletManager *manager   =  [ELWalletManager share];
    
    IMainchainSubWallet *mainchainSubWallet = [manager getWalletELASubWallet:manager.currentWallet.masterWalletID];
    
    nlohmann::json info = mainchainSubWallet->GetRegisteredProducerInfo();
    NSString *dataStr = [NSString stringWithUTF8String:info.dump().c_str()];
    
    NSDictionary *param = [NSJSONSerialization JSONObjectWithData:[dataStr  dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    
    NSString *Status = param[@"Status"];
    if ([Status isEqualToString:@"Registered"]){
        [self loadGetOwnerAddress];
        [self GetRegisteredProducerInfo];
    }else if([Status isEqualToString:@"Canceled"]){
        [self loadGetOwnerAddress];
        [self GetRegisteredProducerInfo];
    }else if([Status isEqualToString:@"Unregistered"]){
        
    }else if ([Status isEqualToString:@"ReturnDeposit"]){
        
        [self loadGetOwnerAddress];
        [self GetRegisteredProducerInfo];
    }
    
}
-(void)loadGetOwnerAddress{
   self.OwnerAddressString=[[ELWalletManager share]GetOwnerAddressWithID:self.currentWallet.masterWalletID];
    [self.NodeReturnsMutableArray addObject:self.OwnerAddressString];
    
    
}
-(NSMutableArray *)NodeReturnsMutableArray{
    if (!_NodeReturnsMutableArray) {
        _NodeReturnsMutableArray =[[NSMutableArray alloc]init];
    }
    return _NodeReturnsMutableArray;
}
-(void)lockVoiteLoadDataSource{
    
    invokedUrlCommand *mommand=[[invokedUrlCommand alloc]initWithArguments:@[self.currentWallet.masterWalletID,self.model.iconName,@0] callbackId:self.currentWallet.walletID className:@"Wallet" methodName:@"getBalance"];
    PluginResult * result =[[ELWalletManager share]getBalance:mommand];
    
    NSString *status=[NSString stringWithFormat:@"%@",result.status];
    if ([status isEqualToString:@"1"]){
          NSString *blanceString=[NSString stringWithFormat:@"%@",result.message[@"success"]];
        
        self.voteBlanceLabel.text=[NSString stringWithFormat:@"%@",[[FLTools share] elaScaleConversionWith:blanceString ]];
        
    }
    
}
-(NSMutableArray *)allListArray{
    if (!_allListArray) {
        _allListArray =[[NSMutableArray alloc]init];
    }
    return _allListArray;
}
-(void)loadGetAllCoinBaseTransactionWithIndex:(NSInteger)index{
    invokedUrlCommand *mommand=[[invokedUrlCommand alloc]initWithArguments:@[self.currentWallet.masterWalletID,self.model.iconName,@(index),@"20",@""] callbackId:self.currentWallet.walletID className:@"Wallet" methodName:@"getAllTransaction"];
    PluginResult * result =[[ELWalletManager share]GetAllCoinBaseTransaction:mommand];
    if (self.NodeReturnsIsUpdate) {
        [self.NodeReturnsMutableArray removeAllObjects];
        [self.NodeReturnsMutableArray addObject:self.OwnerAddressString];
    }
    NSInteger a=[result.message[@"success"][@"MaxCount"] integerValue];
    self.NodeReturnsAllTotal=a;
    NSArray *tranList=[NSArray modelArrayWithClass:assetDetailsModel.class json:result.message[@"success"][@"Transactions"]];
    self.NodeReturnsCurrentIndex=self.currentIndex+tranList.count;
    [self.NodeReturnsMutableArray addObjectsFromArray:tranList];
    if (self.NodeReturnsMutableArray.count==1) {
self.noDataSourceTextLabel.text=NSLocalizedString(@"暂无收益记录", nil);
        self.noDataSourceTextLabel.alpha=1.f;
    }else{
        self.noDataSourceTextLabel.alpha=0.f;
    }
    [self.baseTableView reloadData];
    [self  baseTableViewEndRF];
    
}
-(void)loadAllTransactionWithIndex:(NSInteger)index{
    invokedUrlCommand *mommand=[[invokedUrlCommand alloc]initWithArguments:@[self.currentWallet.masterWalletID,self.model.iconName,@(index),@"20",@""] callbackId:self.currentWallet.walletID className:@"Wallet" methodName:@"getAllTransaction"];
    PluginResult * result =[[ELWalletManager share]getAllTransaction:mommand];
    if (self.isUpdate) {
        [self.allListArray removeAllObjects];
    }
//    self.allTotalMAXCount=[result.message[@"success"][@"MaxCount"] integerValue];
        NSInteger a=[result.message[@"success"][@"MaxCount"] integerValue];
    self.allTotal=a;
    NSArray *tranList=[NSArray modelArrayWithClass:assetDetailsModel.class json:result.message[@"success"][@"Transactions"]];
    self.currentIndex=self.currentIndex+tranList.count;
    [self.allListArray addObjectsFromArray:tranList];
    if (self.allListArray.count==0) {
        self.noDataSourceTextLabel.alpha=1.f;
        self.noDataSourceTextLabel.text=NSLocalizedString(@"暂无交易记录", nil);
    }else{
        self.noDataSourceTextLabel.alpha=0.f;
        
    }
    [self.baseTableView reloadData];
    [self  baseTableViewEndRF];
    
}
- (IBAction)anyChangeInTheWholeAction:(id)sender {
    // 零钱换整
    
}
- (IBAction)transactionRecordsAction:(id)sender {
    self.leftOrRight=@"0";
    [self selecttState:self.transactionRecordsBtton];
    [self theNormalState:self.EarningsRecordButton];
    [self.baseTableView reloadData];
    if (self.allListArray.count==0) {
        self.noDataSourceTextLabel.alpha=1.f;
        self.noDataSourceTextLabel.text=NSLocalizedString(@"暂无交易记录", nil);
    }else{
        self.noDataSourceTextLabel.alpha=0.f;
        
    }
    
}
- (IBAction)EarningsRecordAction:(id)sender {
    self.leftOrRight=@"1";
    if (self.NodeReturnsMutableArray.count==1) {
        [self loadGetAllCoinBaseTransactionWithIndex:0];
    }
    [self selecttState:self.EarningsRecordButton];
    [self theNormalState:
     self.transactionRecordsBtton];
    [self.baseTableView reloadData];
    if (self.NodeReturnsMutableArray.count==1) {
        self.noDataSourceTextLabel.text=NSLocalizedString(@"暂无收益记录", nil);
        self.noDataSourceTextLabel.alpha=1.f;
    }else{
        self.noDataSourceTextLabel.alpha=0.f;
    }
}
- (IBAction)transferEvent:(id)sender {
    self.transferButton.userInteractionEnabled=NO;
    HMWtransferViewController *transferVC=[[HMWtransferViewController alloc]init];
    transferVC.currentWallet=self.currentWallet;
    transferVC.model=self.model;
    
    if (self.allAddressAaary.count==0) {
        self.allAddressAaary=nil;
//        return;
    }
    transferVC.addressArray=self.allAddressAaary;
    transferVC.supportOfTheCurrencyArray=self.supportOfTheCurrencyArray;
    [self.navigationController pushViewController:transferVC animated:YES];
    self.transferButton.userInteractionEnabled=YES;

}
- (IBAction)top_upEvent:(id)sender {
    
    if (![self.title isEqualToString:@"ELA"]) {
        HMWTop_upPageForDetailsViewController *top_upPageForDetailsVC=[[HMWTop_upPageForDetailsViewController alloc]init];
        top_upPageForDetailsVC.title=NSLocalizedString(@"主链提现", nil);
        top_upPageForDetailsVC.selectmModel=self.elaModel;
        top_upPageForDetailsVC.currentWallet=self.currentWallet;
        top_upPageForDetailsVC.fromModel=self.model;
        top_upPageForDetailsVC.type=mainChainWithdrawalType;
        top_upPageForDetailsVC.substringAddress=self.allAddressAaary.firstObject;
        [self.navigationController pushViewController:top_upPageForDetailsVC animated:YES];
        
        
    }else{
    HMWChooseSideChainViewController *chooseSideChainVC=[[HMWChooseSideChainViewController alloc]init];
    chooseSideChainVC.title=self.topUpButton.titleLabel.text;
    
    chooseSideChainVC.currentWallet=self.currentWallet;
    chooseSideChainVC.model=self.model;
    chooseSideChainVC.type=chooseSideChainType;
    chooseSideChainVC.addressArray=self.allAddressAaary;
    chooseSideChainVC.supportOfTheCurrencyArray=self.supportOfTheCurrencyArray;
        [self.navigationController pushViewController:chooseSideChainVC animated:YES];
        
    }
}
- (IBAction)collectionEvent:(id)sender {
    self.collectionButton.userInteractionEnabled=NO;
        invokedUrlCommand *mommand=[[invokedUrlCommand alloc]initWithArguments:@[self.currentWallet.masterWalletID,self.model.iconName] callbackId:self.currentWallet.walletID className:@"Wallet" methodName:@"createAddress"];
        PluginResult * result =[[ELWalletManager share]createAddress:mommand];
        NSString *status=[NSString stringWithFormat:@"%@",result.status];
        if ([status isEqualToString:@"1"]) {
            HMWcollectionViewController*collectionVC=[[HMWcollectionViewController alloc]init];
            NSArray *addrestStringArray=[NSArray arrayWithArray:self.allAddressAaary];
            if (addrestStringArray.count==0) {
                self.allAddressAaary=nil;
            }
            collectionVC.addrestStringArray=self.allAddressAaary;
            collectionVC.iconAddress=[NSString stringWithFormat:@"%@",result.message[@"success"]];
            [self.navigationController pushViewController:collectionVC animated:YES];
        }

    
    
      self.collectionButton.userInteractionEnabled=YES;
}
-(NSArray *)allAddressAaary{
    if (!_allAddressAaary) {
        
        _allAddressAaary=[NSArray arrayWithArray:[self loadAddress]];
    }
    
    return _allAddressAaary;
}
-(NSArray*)loadAddress{

    invokedUrlCommand *mommand=[[invokedUrlCommand alloc]initWithArguments:@[self.currentWallet.masterWalletID,self.model.iconName,@"0",@"100"] callbackId:self.currentWallet.walletID className:@"Wallet" methodName:@"getAllSubWalletAddress"];
    PluginResult * result =[[ELWalletManager share]getAllSubWalletAddress:mommand];
    NSString *status=[NSString stringWithFormat:@"%@",result.status];
   
    if ([status isEqualToString:@"1"]) {
       NSArray *addressArray=[NSArray arrayWithArray:result.message[@"success"][@"Addresses"]];
        return   addressArray;
    }
    return NULL;
 
    
    
}

-(void)makeView{
    
    if ([self.title isEqualToString:@"ELA"]) {
        [self.topUpButton setTitle:NSLocalizedString(@"侧链充值", nil) forState:UIControlStateNormal];
//        [self.topUpButton setImage:[UIImage imageNamed:@"asset_trade_side_recharge"] forState:UIControlStateNormal];
    }else{
          [self.topUpButton setTitle:NSLocalizedString(@"主链提现", nil) forState:UIControlStateNormal];
       [self.topUpButton setImage:[UIImage imageNamed:@"asset_trade_main_withdraw"] forState:UIControlStateNormal];
    }
    
    
    self.baseTableView.delegate=self;
    self.baseTableView.dataSource=self;
    self.baseTableView.rowHeight=70;
 __weak __typeof(self) _self = self;
    self.baseTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
         __strong __typeof(_self) self = _self;
        if ([self.leftOrRight isEqualToString:@"0"]) {
            self.isUpdate=YES;
            
            self.currentIndex=0;
            [self  loadAllTransactionWithIndex: self.currentIndex];
        }else{
            self.NodeReturnsIsUpdate=YES;
            self.NodeReturnsCurrentIndex=0;
            [self loadGetAllCoinBaseTransactionWithIndex:self.NodeReturnsCurrentIndex];
            
        }
        
    }];
    self.baseTableView.mj_footer=[MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        __strong __typeof(_self) self = _self;
        if ([self.leftOrRight isEqualToString:@"0"]) {
         self.isUpdate=NO;
        if (self.allTotal<=self.currentIndex) {
            
            [self  baseTableViewEndRF];
            
            return ;
        }
       
            [self  loadAllTransactionWithIndex: self.currentIndex];
            
        }else{
            self.NodeReturnsIsUpdate=NO;
            if (self.NodeReturnsAllTotal<=self.NodeReturnsCurrentIndex) {
                [self  baseTableViewEndRF];
                
                return ;
            }
             [self loadGetAllCoinBaseTransactionWithIndex:self.NodeReturnsCurrentIndex];
            
        }
    }];
    
    self.baseTableView.separatorInset=UIEdgeInsetsMake(-0, 15, 0, 15);
  
    [self.baseTableView registerNib:[UINib nibWithNibName:cellString bundle:nil] forCellReuseIdentifier:cellString];
    [self.baseTableView registerNib:[UINib nibWithNibName:showOwnerAddressCellString bundle:nil] forCellReuseIdentifier:showOwnerAddressCellString];
    
    
    self.baseTableView.tableFooterView=[[UIView alloc]initWithFrame:CGRectZero];
    
    
}
-(void)baseTableViewEndRF{
    [self.baseTableView.mj_header endRefreshing];
    [self.baseTableView.mj_footer endRefreshing];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ([self.leftOrRight isEqualToString:@"0"]) {
        return self.allListArray.count;
    }
    return  self.NodeReturnsMutableArray.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (![self.leftOrRight isEqualToString:@"0"]&&indexPath.row==0) {
        showOwnerAddressTableViewCell *showCell=[tableView dequeueReusableCellWithIdentifier:showOwnerAddressCellString];
        showCell.selectionStyle = UITableViewCellSelectionStyleNone;
        showCell.addreCopyTextLabel.text=self.OwnerAddressString;
        return  showCell;
    }
    
    HMWAssetDetailsTableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellString];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.backgroundColor=[UIColor clearColor];
//    cell.niceNameString=self.model.iconName;
    cell.niceNameString=@"ELA";
    if ([self.leftOrRight isEqualToString:@"0"]) {
        cell.model=self.allListArray[indexPath.row];
    }else{
        cell.model=self.NodeReturnsMutableArray[indexPath.row-1];
    }
    
   
    return cell;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.leftOrRight isEqualToString:@"0"]) {
        [self loadTheOrderDetailsWithIndex:indexPath.row];
    }else{
        [self loadGetAllCoinBaseTransactionDetailsWithIndex:indexPath.row-1];
    }
    
   
    
 
    
}
-(void)loadGetAllCoinBaseTransactionDetailsWithIndex:(NSInteger)index{
    assetDetailsModel *model= self.NodeReturnsMutableArray[index];
    invokedUrlCommand *mommand=[[invokedUrlCommand alloc]initWithArguments:@[self.currentWallet.masterWalletID,self.model.iconName,@"0",@"20",model.TxHash] callbackId:self.currentWallet.walletID className:@"Wallet" methodName:@"getAllTransaction"];
    PluginResult * result =[[ELWalletManager share]GetAllCoinBaseTransaction:mommand];
    NSString *status=[NSString stringWithFormat:@"%@",result.status];
    
    NSArray * OutputPayload=[NSArray arrayWithArray:result.message[@"success"][@"Transactions"][0][@"OutputPayload"]];
    
    if (![status isEqualToString:@"1"]) {
        return;
    }
    
    NSArray *tranList=[NSArray modelArrayWithClass:assetDetailsModel.class json:result.message[@"success"][@"Transactions"]];
    
    if (tranList.count==0) {
        [[FLTools share]showErrorInfo:NSLocalizedString(@"暂无数据,请耐心等待!", nil)];
        return;
    }
    assetDetailsModel *detailsM=tranList.firstObject;
    HMWtransferTransactionDetailsViewController *transferTransactionDetailsVC=[[HMWtransferTransactionDetailsViewController alloc]init];
    
    detailsM.Amount=[NSString stringWithFormat:@"%@ELA",[[FLTools share]elaScaleConversionWith:detailsM.Amount]];
    detailsM.Fee=[NSString stringWithFormat:@"%@ELA",[[FLTools share]elaScaleConversionWith:detailsM.Fee]];
    //    transferTransactionDetailsVC.iconNameString=@"ELA";
    transferTransactionDetailsVC.iconNameString=self.model.iconName;
    int type=[detailsM.Type intValue];
    transferTransactionDetailsVC.TypeString=[NSString stringWithFormat:@"%@",detailsM.Type];
    switch (type) {
            
        case 0:
            detailsM.Type=NSLocalizedString(@"创币交易", nil);
            break;
        case 1:
            detailsM.Type=NSLocalizedString(@"注册资产交易", nil);
            break;
        case 2:
            detailsM.Type=NSLocalizedString(@"普通转账交易", nil);
            break;
        case 3:
            detailsM.Type=NSLocalizedString(@"记录交易", nil);
            break;
        case 4:
            detailsM.Type=NSLocalizedString(@"部署交易", nil);
            break;
        case 5:
            detailsM.Type=NSLocalizedString(@"侧链挖矿交易", nil);
            break;
        case 6:
            detailsM.Type=NSLocalizedString(@"侧链充值交易", nil);
            break;
        case 7:
            detailsM.Type=NSLocalizedString(@"侧链提现交易", nil);
            break;
        case 8:
            transferTransactionDetailsVC.PayloadInfoString=[NSString stringWithFormat:@"%@\n%@ %@",result.message[@"success"][@"Transactions"][0][@"Payload"][@"CrossChainAddress"][0],[[FLTools share] elaScaleConversionWith:result.message[@"success"][@"Transactions"][0][@"Payload"][@"CrossChainAmount"][0]],@"ELA"];
            detailsM.Type=NSLocalizedString(@"跨链交易", nil);
            break;
        case 9:
            detailsM.Type=NSLocalizedString(@"注册参选交易", nil);
            break;
        case 10:
            detailsM.Type=NSLocalizedString(@"取消参选交易", nil);
            break;
        case 11:
            detailsM.Type=NSLocalizedString(@"更新参选交易", nil);
            break;
        case 12:
            detailsM.Type=NSLocalizedString(@"取回参选优质抵押资产交易", nil);
            break;
            
        default:
            break;
    }
    
    detailsM.Timestamp=[[FLTools share]YMDCommunityTimeConversToAllFromTimesTamp:detailsM.Timestamp];
    
    if ([detailsM.Direction isEqualToString:@"Received"]) {
        transferTransactionDetailsVC.type=transactionMultipleIntoType;
    }else if ([detailsM.Direction isEqualToString:@"Sent"]){
        transferTransactionDetailsVC.type=transactionSingleRollOutType;
    }else if (OutputPayload.count>0){
        detailsM.Type=NSLocalizedString(@"投票交易", nil);
        transferTransactionDetailsVC.type=rotationToVoteType;
        transferTransactionDetailsVC.votesString=[[FLTools share]elaScaleConversionWith:OutputPayload[0][@"Amount"]];
    }
    else{
        transferTransactionDetailsVC.type=transactionSingleIntoType;
    }
    transferTransactionDetailsVC.model=detailsM;
    
    [self.navigationController pushViewController:transferTransactionDetailsVC animated:YES];
    
}
-(void)loadTheOrderDetailsWithIndex:(NSInteger)index{
   assetDetailsModel *model= self.allListArray[index];
    invokedUrlCommand *mommand=[[invokedUrlCommand alloc]initWithArguments:@[self.currentWallet.masterWalletID,self.model.iconName,@"0",@"20",model.TxHash] callbackId:self.currentWallet.walletID className:@"Wallet" methodName:@"getAllTransaction"];
    PluginResult * result =[[ELWalletManager share]getAllTransaction:mommand];
    NSString *status=[NSString stringWithFormat:@"%@",result.status];
    
    NSArray * OutputPayload=[NSArray arrayWithArray:result.message[@"success"][@"Transactions"][0][@"OutputPayload"]];
    
    if (![status isEqualToString:@"1"]) {
        return;
    }

      NSArray *tranList=[NSArray modelArrayWithClass:assetDetailsModel.class json:result.message[@"success"][@"Transactions"]];
   
    if (tranList.count==0) {
        [[FLTools share]showErrorInfo:NSLocalizedString(@"暂无数据,请耐心等待!", nil)];
         return;
    }
    assetDetailsModel *detailsM=tranList.firstObject;
    HMWtransferTransactionDetailsViewController *transferTransactionDetailsVC=[[HMWtransferTransactionDetailsViewController alloc]init];
    
    detailsM.Amount=[NSString stringWithFormat:@"%@ELA",[[FLTools share]elaScaleConversionWith:detailsM.Amount]];
    detailsM.Fee=[NSString stringWithFormat:@"%@ELA",[[FLTools share]elaScaleConversionWith:detailsM.Fee]];
//    transferTransactionDetailsVC.iconNameString=@"ELA";
    transferTransactionDetailsVC.iconNameString=self.model.iconName;
    int type=[detailsM.Type intValue];
    transferTransactionDetailsVC.TypeString=[NSString stringWithFormat:@"%@",detailsM.Type];
    switch (type) {
            
        case 0:
            detailsM.Type=NSLocalizedString(@"创币交易", nil);
            break;
        case 1:
             detailsM.Type=NSLocalizedString(@"注册资产交易", nil);
            break;
        case 2:
              detailsM.Type=NSLocalizedString(@"普通转账交易", nil);
            break;
        case 3:
            detailsM.Type=NSLocalizedString(@"记录交易", nil);
            break;
        case 4:
             detailsM.Type=NSLocalizedString(@"部署交易", nil);
            break;
        case 5:
             detailsM.Type=NSLocalizedString(@"侧链挖矿交易", nil);
            break;
        case 6:
             detailsM.Type=NSLocalizedString(@"侧链充值交易", nil);
            break;
        case 7:
             detailsM.Type=NSLocalizedString(@"侧链提现交易", nil);
            break;
        case 8:
     transferTransactionDetailsVC.PayloadInfoString=[NSString stringWithFormat:@"%@\n%@ %@",result.message[@"success"][@"Transactions"][0][@"Payload"][@"CrossChainAddress"][0],[[FLTools share] elaScaleConversionWith:result.message[@"success"][@"Transactions"][0][@"Payload"][@"CrossChainAmount"][0]],@"ELA"];
            detailsM.Type=NSLocalizedString(@"跨链交易", nil);
            break;
        case 9:
             detailsM.Type=NSLocalizedString(@"注册参选交易", nil);
            break;
        case 10:
             detailsM.Type=NSLocalizedString(@"取消参选交易", nil);
            break;
        case 11:
            detailsM.Type=NSLocalizedString(@"更新参选交易", nil);
            break;
        case 12:
             detailsM.Type=NSLocalizedString(@"取回参选优质抵押资产交易", nil);
            break;
            
        default:
            break;
    }
    
    detailsM.Timestamp=[[FLTools share]YMDCommunityTimeConversToAllFromTimesTamp:detailsM.Timestamp];

    if ([detailsM.Direction isEqualToString:@"Received"]) {
transferTransactionDetailsVC.type=transactionMultipleIntoType;
    }else if ([detailsM.Direction isEqualToString:@"Sent"]){
transferTransactionDetailsVC.type=transactionSingleRollOutType;
    }else if (OutputPayload.count>0){
        detailsM.Type=NSLocalizedString(@"投票交易", nil);
        transferTransactionDetailsVC.type=rotationToVoteType;
        transferTransactionDetailsVC.votesString=[[FLTools share]elaScaleConversionWith:OutputPayload[0][@"Amount"]];
    }
    else{
transferTransactionDetailsVC.type=transactionSingleIntoType;
    }
        transferTransactionDetailsVC.model=detailsM;
    
    [self.navigationController pushViewController:transferTransactionDetailsVC animated:YES];
    
}
-(void)setModel:(assetsListModel *)model{
    _model=model;
    
}
-(void)setCurrentWallet:(FLWallet *)currentWallet{
    _currentWallet=currentWallet;
}
-(void)setElaModel:(assetsListModel *)elaModel{
    _elaModel=elaModel;
}
-(void)theNormalState:(UIButton*)button{
    [button setTitleColor:RGB(160, 175, 177) forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor clearColor]];
    
    
}
-(void)selecttState:(UIButton*)button{
    
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:RGB(107, 133, 135)];
    
}

@end
