// Minimal stub — satisfies DOJailbreaker.m, DOBootstrapper.m, DOEnvironmentManager.m
// which only use [DOUIManager sharedInstance] sendLog:debug:
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DOUIManager : NSObject
+ (instancetype)sharedInstance;
- (void)sendLog:(NSString *)log debug:(BOOL)debug;
- (void)sendLog:(NSString *)log debug:(BOOL)debug update:(BOOL)update;
- (void)startLog;
- (NSArray *)enabledPackageManagers;
- (NSString *)bootlogoPath;
- (void)renderBootLogo;
@end

NS_ASSUME_NONNULL_END
