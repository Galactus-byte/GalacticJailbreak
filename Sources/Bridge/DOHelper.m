#import "DOHelper.h"
#import "../../Dopamine/Application/Dopamine/UI/DOUIManager.h"
#import "../../Dopamine/Application/Dopamine/Jailbreak/DOJailbreaker.h"
#import "../../Dopamine/Application/Dopamine/Jailbreak/DOBootstrapper.h"
#import "../../Dopamine/Application/Dopamine/Jailbreak/DOEnvironmentManager.h"
#import "../../Dopamine/Application/Dopamine/Jailbreak/DOPreferenceManager.h"

@implementation DOHelper

// MARK: - Environment

+ (BOOL)isEnvironmentSupported {
    return [[DOEnvironmentManager sharedManager] isSupported];
}

+ (BOOL)isDeviceJailbroken {
    return [[DOEnvironmentManager sharedManager] isJailbroken];
}

+ (void)markDeviceJailbroken:(BOOL)jailbroken {
    [[DOEnvironmentManager sharedManager] setJailbroken:jailbroken];
}

// MARK: - Main jailbreak

+ (NSError * _Nullable)runJailbreak {
    DOJailbreaker *jailbreaker = [[DOJailbreaker alloc] init];
    NSError *error = nil;
    BOOL didRemove = NO;
    BOOL showLogs = NO;
    [jailbreaker runWithError:&error didRemoveJailbreak:&didRemove showLogs:&showLogs];
    return error;
}

+ (void)finalizeJailbreaker {
    DOJailbreaker *jailbreaker = [[DOJailbreaker alloc] init];
    [jailbreaker finalize];
}

+ (void)respring {
    [[DOEnvironmentManager sharedManager] respring];
}

// MARK: - Bootstrap

+ (void)prepareBootstrapWithCompletion:(void(^)(NSError * _Nullable))completion {
    DOBootstrapper *bootstrapper = [[DOBootstrapper alloc] init];
    [bootstrapper prepareBootstrapWithCompletion:completion];
}

+ (NSError * _Nullable)updateVarJbSymlink {
    DOBootstrapper *bootstrapper = [[DOBootstrapper alloc] init];
    return [bootstrapper updateVarJbSymlink];
}

+ (NSError * _Nullable)installPackageManagers {
    DOBootstrapper *bootstrapper = [[DOBootstrapper alloc] init];
    return [bootstrapper installPackageManagers];
}

+ (NSError * _Nullable)finalizeBootstrap {
    DOBootstrapper *bootstrapper = [[DOBootstrapper alloc] init];
    return [bootstrapper finalizeBootstrap];
}

// MARK: - Package manager preference

+ (void)setPreferredPackageManager:(NSString *)bundleID {
    // Persist preference — DOPreferenceManager reads this during installPackageManagers
    [[NSUserDefaults standardUserDefaults] setObject:bundleID
                                              forKey:@"galactic.preferred_pm"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
