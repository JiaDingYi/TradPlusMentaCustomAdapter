//
//  TPlusMentaSplashCustomAdapter.m
//  Ads-Global-AdsGlobalSDK
//
//  Created by jdy_office on 2025/6/20.
//

#import "TPlusMentaSplashCustomAdapter.h"
#import <MentaMediationGlobal/MentaMediationGlobal-umbrella.h>

@interface TPlusMentaSplashCustomAdapter () <MentaMediationSplashDelegate>
@property (nonatomic, strong) MentaMediationSplash *splash;
@property (nonatomic, assign) BOOL isC2S;

@end

@implementation TPlusMentaSplashCustomAdapter
- (BOOL)extraActWithEvent:(NSString *)event info:(NSDictionary *)config {
    NSLog(@"%s", __FUNCTION__);
    if ([event isEqualToString:@"C2SBidding"]) {
        self.isC2S = YES;
        [self loadAdWithWaterfallItem:self.waterfallItem];
    } else if ([event isEqualToString:@"LoadAdC2SBidding"]) {
        if ([self.splash isAdReady]) {
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
    self.splash = [[MentaMediationSplash alloc] initWithPlacementID:placementID];
    self.splash.delegate = self;
    [self.splash loadSplashAd];
    NSLog(@"%s", __FUNCTION__);
}

- (void)showAdInWindow:(UIWindow *)window bottomView:(UIView *)bottomView {
    [self.splash showAdInWindow:window];
}

- (BOOL)isReady {
    return [self.splash isAdReady];
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
    [self.splash sendLossNotificationWithWinnerPrice:@"" info:config];
}

- (void)sendC2sWin {
    [self.splash sendWinnerNotificationWith:@{}];
}

#pragma mark - MentaMediationSplashDelegate
// 广告素材加载成功
- (void)menta_splashAdDidLoad:(MentaMediationSplash *)splash {
    NSLog(@"%s", __FUNCTION__);
}

// 广告素材加载失败
- (void)menta_splashAdLoadFailedWithError:(NSError *)error splash:(MentaMediationSplash *)splash {
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
- (void)menta_splashAdRenderSuccess:(MentaMediationSplash *)splash {
    NSLog(@"%s", __FUNCTION__);
    if (self.isC2S) {
        //三方版本号
        NSString *version = [[MentaAdSDK shared] sdkVersion];
        //广告对象的ECPM
        NSString *ecpmStr = [splash eCPM];
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
- (void)menta_splashAdRenderFailureWithError:(NSError *)error splash:(MentaMediationSplash *)splash {
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

// 开屏广告即将展示
- (void)menta_splashAdWillPresent:(MentaMediationSplash *)splash {
    NSLog(@"%s", __FUNCTION__);
}

// 开屏广告展示失败
- (void)menta_splashAdShowFailWithError:(NSError *)error splash:(MentaMediationSplash *)splash {
    NSLog(@"%s", __FUNCTION__);
    [self AdShowFailWithError:error];
}

// 开屏广告曝光
- (void)menta_splashAdExposed:(MentaMediationSplash *)splash {
    NSLog(@"%s", __FUNCTION__);
    [self AdShow];
    if (self.isC2S) {
        [self sendC2sWin];
    }
}

// 开屏广告点击
- (void)menta_splashAdClicked:(MentaMediationSplash *)splash {
    NSLog(@"%s", __FUNCTION__);
    [self AdClick];
}

// 开屏广告关闭
-(void)menta_splashAdClosed:(MentaMediationSplash *)splash {
    NSLog(@"%s", __FUNCTION__);
    [self AdClose];
}

@end
