//
//  TPlusMentaInterstitialCustomAdapter.m
//  Ads-Global-AdsGlobalSDK
//
//  Created by jdy_office on 2025/6/20.
//

#import "TPlusMentaInterstitialCustomAdapter.h"
#import <MentaMediationGlobal/MentaMediationGlobal-umbrella.h>

@interface TPlusMentaInterstitialCustomAdapter () <MentaMediationInterstitialDelegate>
@property (nonatomic, strong) MentaMediationInterstitial *interstitialAd;
@property (nonatomic, assign) BOOL isC2S;

@end

@implementation TPlusMentaInterstitialCustomAdapter

- (BOOL)extraActWithEvent:(NSString *)event info:(NSDictionary *)config {
    NSLog(@"%s", __FUNCTION__);
    if ([event isEqualToString:@"C2SBidding"]) {
        self.isC2S = YES;
        [self loadAdWithWaterfallItem:self.waterfallItem];
    } else if ([event isEqualToString:@"LoadAdC2SBidding"]) {
        if ([self.interstitialAd isAdReady]) {
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
    
    NSString *placementID = item.config[@"PlacementaID"];
    self.interstitialAd = [[MentaMediationInterstitial alloc] initWithPlacementID:placementID];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadAd];
    NSLog(@"%s", __FUNCTION__);
}

- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    [self.interstitialAd showAdFromRootViewController:rootViewController];
}

- (BOOL)isReady {
    return [self.interstitialAd isAdReady];
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
    [self.interstitialAd sendLossNotificationWithWinnerPrice:@"" info:config];
}

- (void)sendC2sWin {
    [self.interstitialAd sendWinnerNotificationWith:@{}];
}

#pragma mark - MentaMediationInterstitialDelegate
// 广告素材加载成功
- (void)menta_interstitialDidLoad:(MentaMediationInterstitial *)interstitial {
    NSLog(@"%s", __FUNCTION__);
}

// 广告素材加载失败
- (void)menta_interstitialLoadFailedWithError:(NSError *)error interstitial:(MentaMediationInterstitial *)interstitial {
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
- (void)menta_interstitialRenderSuccess:(MentaMediationInterstitial *)interstitial {
    NSLog(@"%s", __FUNCTION__);
    if (self.isC2S) {
        //三方版本号
        NSString *version = [[MentaAdSDK shared] sdkVersion];
        //广告对象的ECPM
        NSString *ecpmStr = [interstitial eCPM];
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
- (void)menta_interstitialRenderFailureWithError:(NSError *)error interstitial:(MentaMediationInterstitial *)interstitial {
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

// 广告即将展示
- (void)menta_interstitialWillPresent:(MentaMediationInterstitial *)interstitial {
    NSLog(@"%s", __FUNCTION__);
}

// 广告展示失败
- (void)menta_interstitialShowFailWithError:(NSError *)error interstitial:(MentaMediationInterstitial *)interstitial {
    NSLog(@"%s", __FUNCTION__);
    [self AdShowFailWithError:error];
}

// 广告曝光
- (void)menta_interstitialExposed:(MentaMediationInterstitial *)interstitial {
    NSLog(@"%s", __FUNCTION__);
    [self AdShow];
    if (self.isC2S) {
        [self sendC2sWin];
    }
}

// 广告点击
- (void)menta_interstitialClicked:(MentaMediationInterstitial *)interstitial {
    NSLog(@"%s", __FUNCTION__);
    [self AdClick];
}

// 视频播放完成
- (void)menta_interstitialPlayCompleted:(MentaMediationInterstitial *)interstitial {
    NSLog(@"%s", __FUNCTION__);
}

// 广告关闭
-(void)menta_interstitialClosed:(MentaMediationInterstitial *)interstitial {
    NSLog(@"%s", __FUNCTION__);
    [self AdClose];
}

@end
