//
//  TPlusMentaRewardVideoCustomAdapter.m
//  Ads-Global-AdsGlobalSDK
//
//  Created by jdy_office on 2025/6/20.
//

#import "TPlusMentaRewardVideoCustomAdapter.h"
#import <MentaMediationGlobal/MentaMediationGlobal-umbrella.h>

@interface TPlusMentaRewardVideoCustomAdapter () <MentaMediationRewardVideoDelegate>
@property (nonatomic, strong) MentaMediationRewardVideo *rewardVideo;
@property (nonatomic, assign) BOOL isC2S;
@property (nonatomic, assign) BOOL isRewarded;

@end

@implementation TPlusMentaRewardVideoCustomAdapter
- (BOOL)extraActWithEvent:(NSString *)event info:(NSDictionary *)config {
    NSLog(@"%s", __FUNCTION__);
    if ([event isEqualToString:@"C2SBidding"]) {
        self.isC2S = YES;
        [self loadAdWithWaterfallItem:self.waterfallItem];
    } else if ([event isEqualToString:@"LoadAdC2SBidding"]) {
        if ([self.rewardVideo isAdReady]) {
            [self AdLoadFinsh];
        } else {
            //无效时返回加载失败
            NSError *loadError = [NSError errorWithDomain:@"menta.interstitial"
                                                     code:402
                                                 userInfo:@{NSLocalizedDescriptionKey : @"C2S Interstitial not ready"}];
            [self AdLoadFailWithError:loadError];
        }
    } else if ([event isEqualToString:@"C2SLoss"]) {
        [self sendC2sLoss:config];
    } else {
        return NO;
    }
    return YES;
}

- (void)loadAdWithWaterfallItem:(TradPlusAdWaterfallItem *)item {
    [self initMentaSDK:item];
    self.isRewarded = NO;
    NSString *placementID = item.config[@"PlacementaID"];
    self.rewardVideo = [[MentaMediationRewardVideo alloc] initWithPlacementID:placementID];
    self.rewardVideo.delegate = self;
    [self.rewardVideo loadAd];
    NSLog(@"%s", __FUNCTION__);
}

- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    [self.rewardVideo showAdFromRootViewController:rootViewController];
}

- (BOOL)isReady {
    return [self.rewardVideo isAdReady];
}

- (void)initMentaSDK:(TradPlusAdWaterfallItem *)item {
    NSLog(@"%s", __FUNCTION__);
    MentaAdSDK *menta = [MentaAdSDK shared];
    if (menta.isInitialized) {
        return;
    }
    NSString *appID = item.config[@"AppID"];
    NSString *appKey = item.config[@"AppKey"];
    if (!appID || !appKey) {
        [self AdConfigError];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[MentaAdSDK shared] startWithAppID:appID appKey:appKey finishBlock:^(BOOL success, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!success && error) {
            [strongSelf AdConfigError];
        }
    }];
}

- (void)sendC2sLoss:(NSDictionary *)config {
    [self.rewardVideo sendLossNotificationWithWinnerPrice:@"" info:config];
}

- (void)sendC2sWin {
    [self.rewardVideo sendWinnerNotificationWith:@{}];
}
#pragma mark - MentaMediationRewardVideoDelegate
// 广告素材加载成功
- (void)menta_rewardVideoDidLoad:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
}

// 广告素材加载失败
- (void)menta_rewardVideoLoadFailedWithError:(NSError *)error rewardVideo:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
    if (self.isC2S) {
        //加载失败，将错误信息回传给TradPlusSDK
        NSString *errorStr = [NSString stringWithFormat:@"%@", error];
        NSDictionary *dic = @{@"error":errorStr};
        [self ADLoadExtraCallbackWithEvent:@"C2SBiddingFail" info:dic];
    } else {
        [self AdLoadFailWithError:error];
    }
}

// 广告素材渲染成功
// 此时可以获取 ecpm
- (void)menta_rewardVideoRenderSuccess:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
    if (self.isC2S) {
        //三方版本号
        NSString *version = [[MentaAdSDK shared] sdkVersion];
        //广告对象的ECPM
        NSString *ecpmStr = [rewardVideo eCPM];
        //通过接口返回给SDK
        NSDictionary *dic = @{
            @"ecpm":ecpmStr ?: @"",
            @"version":version ? : @""
        };
        [self ADLoadExtraCallbackWithEvent:@"C2SBiddingFinish" info:dic];
    } else {
        [self AdLoadFinsh];
    }
}

// 广告素材渲染失败
- (void)menta_rewardVideoRenderFailureWithError:(NSError *)error rewardVideo:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
    if (self.isC2S) {
        //加载失败，将错误信息回传给TradPlusSDK
        NSString *errorStr = [NSString stringWithFormat:@"%@", error];
        NSDictionary *dic = @{@"error":errorStr};
        [self ADLoadExtraCallbackWithEvent:@"C2SBiddingFail" info:dic];
    } else {
        [self AdLoadFailWithError:error];
    }
}

// 激励视频广告即将展示
- (void)menta_rewardVideoWillPresent:(MentaMediationRewardVideo *)rewardVide {
    NSLog(@"%s", __FUNCTION__);
}

// 激励视频广告展示失败
- (void)menta_rewardVideoShowFailWithError:(NSError *)error rewardVideo:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
}

// 激励视频广告曝光
- (void)menta_rewardVideoExposed:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
    [self AdShow];
    if (self.isC2S) {
        [self sendC2sWin];
    }
}

// 激励视频广告点击
- (void)menta_rewardVideoClicked:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
    [self AdClick];
}

// 激励视频广告跳过
- (void)menta_rewardVideoSkiped:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
}

// 激励视频达到奖励节点
- (void)menta_rewardVideoDidEarnReward:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
    self.isRewarded = YES;
}

// 激励视频播放完成
- (void)menta_rewardVideoPlayCompleted:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
}

// 激励视频广告关闭
-(void)menta_rewardVideoClosed:(MentaMediationRewardVideo *)rewardVideo {
    NSLog(@"%s", __FUNCTION__);
    if (self.isRewarded) {
        [self AdRewardedWithInfo:nil];
    }
    [self AdClose];
}

@end
