#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Swift-friendly wrapper around Dopamine's Objective-C classes.
/// Resolves BOOL* bridging issues, nullable NSError returns, and
/// singleton naming differences between ObjC and Swift.
@interface DOHelper : NSObject

// MARK: - Environment
+ (BOOL)isEnvironmentSupported;
+ (BOOL)isDeviceJailbroken;
+ (void)markDeviceJailbroken:(BOOL)jailbroken;

// MARK: - Main jailbreak (DOJailbreaker)
+ (NSError * _Nullable)runJailbreak;
+ (void)finalizeJailbreaker;
+ (void)respring;

// MARK: - Bootstrap (DOBootstrapper)
+ (void)prepareBootstrapWithCompletion:(void(^)(NSError * _Nullable error))completion;
+ (NSError * _Nullable)updateVarJbSymlink;
+ (NSError * _Nullable)installPackageManagers;
+ (NSError * _Nullable)finalizeBootstrap;

// MARK: - Package manager preference
+ (void)setPreferredPackageManager:(NSString *)bundleID;

@end

NS_ASSUME_NONNULL_END
