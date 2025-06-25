//
//  TPlusMentaBannerCustomAdapter.m
//  Ads-Global-AdsGlobalSDK
//
//  Created by jdy_office on 2025/6/20.
//

#import "TPlusMentaBannerCustomAdapter.h"
#import <MentaMediationGlobal/MentaMediationGlobal-umbrella.h>

@interface TPlusMentaBannerCustomAdapter () <MentaMediationBannerDelegate>
@property (nonatomic, strong) MentaMediationBanner *banner;
@property (nonatomic, strong) UIView *bannerView;
@property (nonatomic, assign) BOOL isC2S;

@end

@implementation TPlusMentaBannerCustomAdapter

- (BOOL)extraActWithEvent:(NSString *)event info:(NSDictionary *)config {
    NSLog(@"%s", __FUNCTION__);
    if ([event isEqualToString:@"C2SBidding"]) {
        self.isC2S = YES;
        [self loadAdWithWaterfallItem:self.waterfallItem];
    } else if ([event isEqualToString:@"LoadAdC2SBidding"]) {
        if ([self.banner isAdReady]) {
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
    self.banner = [[MentaMediationBanner alloc] initWithPlacementID:placementID];
    self.banner.delegate = self;
    [self.banner loadAd];
    NSLog(@"%s", __FUNCTION__);
}

- (id)getCustomObject {
    return self.bannerView;
}

- (BOOL)isReady {
    return [self.banner isAdReady];
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
    [self.banner sendLossNotificationWithWinnerPrice:@"" info:config];
}

- (void)sendC2sWin {
    [self.banner sendWinnerNotificationWith:@{}];
}

#pragma mark - MentaMediationBannerDelegate

// 广告素材加载成功
- (void)menta_bannerAdDidLoad:(MentaMediationBanner *)banner {
    NSLog(@"%s", __FUNCTION__);
}

// 广告素材加载失败
- (void)menta_bannerAdLoadFailedWithError:(NSError *)error banner:(MentaMediationBanner *)banner {
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
- (void)menta_bannerAdRenderSuccess:(MentaMediationBanner *)banner bannerAdView:(UIView *)bannerAdView {
    NSLog(@"%s", __FUNCTION__);
    self.bannerView = bannerAdView;
    if (self.isC2S) {
        //三方版本号
        NSString *version = [[MentaAdSDK shared] sdkVersion];
        //广告对象的ECPM
        NSString *ecpmStr = [banner eCPM];
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
- (void)menta_bannerAdRenderFailureWithError:(NSError *)error banner:(MentaMediationBanner *)banner {
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

// 广告曝光
- (void)menta_bannerAdExposed:(MentaMediationBanner *)banner {
    NSLog(@"%s", __FUNCTION__);
    [self AdShow];
    if (self.isC2S) {
        [self sendC2sWin];
    }
}

// 广告点击
- (void)menta_bannerAdClicked:(MentaMediationBanner *)banner {
    NSLog(@"%s", __FUNCTION__);
    [self AdClick];
}

// 广告关闭
-(void)menta_bannerAdClosed:(MentaMediationBanner *)banner {
    NSLog(@"%s", __FUNCTION__);
    [self AdClose];
}

@end
