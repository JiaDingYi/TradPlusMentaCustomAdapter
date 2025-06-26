//
//  TPlusMentaNativeSelfRenderCustomAdapter.m
//  
//
//  Created by jdy_office on 2025/6/20.
//

#import "TPlusMentaNativeSelfRenderCustomAdapter.h"
#import <MentaMediationGlobal/MentaMediationGlobal-umbrella.h>

@interface TPlusMentaNativeSelfRenderCustomAdapter () <MentaNativeSelfRenderDelegate, MentaMediationNativeExpressDelegate>
@property (nonatomic, strong) MentaMediationNativeSelfRender *nativeAd;
@property (nonatomic, strong) UIView<MentaMediationNativeSelfRenderViewProtocol> *nativeAdView; // adView
@property (nonatomic, strong) MentaMediationNativeSelfRenderModel *nativeAdData; // adData
@property (nonatomic, assign) BOOL selfRenderAdLoaded;

@property (nonatomic, strong) MentaMediationNativeExpress *nativeExpress;
@property (nonatomic, strong) UIView *nativeExpressAdView; // adView

@property (nonatomic, assign) BOOL isExpressAd;
@property (nonatomic, assign) BOOL isC2S;
 
@end

@implementation TPlusMentaNativeSelfRenderCustomAdapter

- (BOOL)extraActWithEvent:(NSString *)event info:(NSDictionary *)config {
    NSLog(@"%s", __FUNCTION__);
    if ([event isEqualToString:@"C2SBidding"]) {
        self.isC2S = YES;
        [self loadAdWithWaterfallItem:self.waterfallItem];
    } else if ([event isEqualToString:@"LoadAdC2SBidding"]) {
        if (self.isExpressAd && [self.nativeExpress isAdReady]) {
            [self AdLoadFinsh];
        } else if (self.selfRenderAdLoaded) {
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
    NSString *isExpressAd = item.config[@"isExpressAd"];
    if (isExpressAd) {
        NSLog(@"menta native isExpressAd");
        self.isExpressAd = YES;
        self.nativeExpress = [[MentaMediationNativeExpress alloc] initWithPlacementID:placementID];
        self.nativeExpress.delegate = self;
        
        [self.nativeExpress loadAd];
    } else {
        self.nativeAd = [[MentaMediationNativeSelfRender alloc] initWithPlacementID:placementID];
        self.nativeAd.delegate = self;
        
        [self.nativeAd loadAd];
    }
    NSLog(@"%s", __FUNCTION__);
}

- (UIView *)endRender:(NSDictionary *)viewInfo clickView:(NSArray *)array {
    if([viewInfo valueForKey:kTPRendererAdView]) {
        UIView *view = viewInfo[kTPRendererAdView];
        self.nativeAdView.frame = view.bounds;
        [self.nativeAdView addSubview:view];
    }
    [self.nativeAdView menta_registerClickableViews:array closeableViews:nil];
    return self.nativeAdView;
}

- (BOOL)isReady {
    if (self.isExpressAd) {
        return [self.nativeExpress isAdReady];
    } else {
        return self.selfRenderAdLoaded;
    }
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
    if (self.isExpressAd) {
        [self.nativeExpress sendLossNotificationWithWinnerPrice:@"" info:config];
    } else {
        [self.nativeAd sendLossNotificationWithWinnerPrice:@"" info:config];
    }
}

- (void)sendC2sWin {
    if (self.isExpressAd) {
        [self.nativeExpress sendWinnerNotificationWith:nil];
    } else {
        [self.nativeAd sendWinnerNotificationWith:nil];
    }
}

#pragma mark - MentaNativeSelfRenderDelegate
- (void)menta_nativeSelfRenderLoadSuccess:(NSArray<MentaMediationNativeSelfRenderModel *> *)nativeSelfRenderAds
                         nativeSelfRender:(MentaMediationNativeSelfRender *)nativeSelfRender {
    NSLog(@"%s", __FUNCTION__);
    self.nativeAdData = nativeSelfRenderAds.firstObject;
    self.nativeAdView = self.nativeAdData.selfRenderView;
    
    TradPlusAdRes *res = [[TradPlusAdRes alloc] init];
    //绑定元素
    res.title = self.nativeAdData.title;
    res.body = self.nativeAdData.des;
    res.iconImageURL = self.nativeAdData.iconURL;
    if (self.nativeAdData.isVideo) {
//        res.mediaType = TPAdResMediaTypeView;
        res.mediaView = self.nativeAdView.mediaView;
    } else {
//        res.mediaType = TPAdResMediaTypeURLString;
        res.mediaImageURL = self.nativeAdData.materialURL;
    }
    self.waterfallItem.adRes = res;
    self.selfRenderAdLoaded = YES;
    if (self.isC2S) {
        //三方版本号
        NSString *version = [[MentaAdSDK shared] sdkVersion];
        //广告对象的ECPM
        NSString *ecpmStr = [nativeSelfRender eCPM];
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

- (void)menta_nativeSelfRenderLoadFailure:(NSError *)error
                         nativeSelfRender:(MentaMediationNativeSelfRender *)nativeSelfRender {
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

- (void)menta_nativeSelfRenderViewExposed {
    NSLog(@"%s", __FUNCTION__);
    [self AdShow];
    if (self.isC2S) {
        [self sendC2sWin];
    }
}

- (void)menta_nativeSelfRenderViewClicked {
    NSLog(@"%s", __FUNCTION__);
    [self AdClick];
}

- (void)menta_nativeSelfRenderViewClosed {
    NSLog(@"%s", __FUNCTION__);
    [self AdClose];
}

#pragma mark - MentaMediationNativeExpressDelegate
// 广告素材加载成功
- (void)menta_nativeExpressAdDidLoad:(MentaMediationNativeExpress *)nativeExpress {
    NSLog(@"%s", __FUNCTION__);
}

// 广告素材加载失败
- (void)menta_nativeExpressAdLoadFailedWithError:(NSError *)error nativeExpress:(MentaMediationNativeExpress *)nativeExpress {
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
- (void)menta_nativeExpressAdRenderSuccess:(MentaMediationNativeExpress *)nativeExpress nativeExpressView:(UIView *)nativeExpressView {
    NSLog(@"%s", __FUNCTION__);
    //新建 TradPlusAdRes
    TradPlusAdRes *res = [[TradPlusAdRes alloc] init];
    self.nativeExpressAdView = nativeExpressView;
    //设置模版view
    res.adView = self.nativeExpressAdView;
    //设置 Res
    self.waterfallItem.adRes = res;
    //加载成功
    if (self.isC2S) {
        //三方版本号
        NSString *version = [[MentaAdSDK shared] sdkVersion];
        //广告对象的ECPM
        NSString *ecpmStr = [nativeExpress eCPM];
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
- (void)menta_nativeExpressAdRenderFailureWithError:(NSError *)error nativeExpress:(MentaMediationNativeExpress *)nativeExpress {
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
- (void)menta_nativeExpressAdExposed:(MentaMediationNativeExpress *)nativeExpress {
    NSLog(@"%s", __FUNCTION__);
    [self AdShow];
    if (self.isC2S) {
        [self sendC2sWin];
    }
}

// 广告点击
- (void)menta_nativeExpressrAdClicked:(MentaMediationNativeExpress *)nativeExpress {
    NSLog(@"%s", __FUNCTION__);
    [self AdClick];
}

// 广告关闭
-(void)menta_nativeExpressAdClosed:(MentaMediationNativeExpress *)nativeExpress {
    NSLog(@"%s", __FUNCTION__);
    [self AdClose];
}

@end
