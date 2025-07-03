#import "AutoHideJB.h"

#define kTWEAK_PREF_PATH @"/var/jb/var/mobile/Library/Preferences/com.p2kdev.autohidejb.plist"

static NSString *jbrootPath = nil;
static NSString *jbrootExecPath = nil;
NSMutableArray *protectedApps;
static BOOL isJBHiddenByTweak = NO;

void refreshProtectedApps() {
   NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:kTWEAK_PREF_PATH];
   if (prefs)
      protectedApps = [[prefs objectForKey:@"protectedApps"] mutableCopy];
   else
      protectedApps = [NSMutableArray new];
}

void updatedProtectedAppsForBundleID(NSString *bundleID) {
   NSMutableDictionary *prefs = [NSMutableDictionary new];

   if ([protectedApps containsObject:bundleID])
      [protectedApps removeObject:bundleID];
   else
      [protectedApps addObject:bundleID]; 

   [prefs setObject:protectedApps forKey:@"protectedApps"];

   [prefs writeToFile:kTWEAK_PREF_PATH atomically:YES];
}

void hideJB() {  
   if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"]) {                     
      isJBHiddenByTweak = YES;
      pid_t pidHideJB;
      int statusHideJB;
      const char* argsHideJB[] = {"hidejbhelper", "hide", NULL};
      posix_spawn(&pidHideJB, [jbrootExecPath UTF8String], NULL, NULL, (char* const*)argsHideJB, NULL);	
      waitpid(pidHideJB, &statusHideJB, WEXITED);  
   }
}   

void unhideJBIfNecessary() {
   if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"] && isJBHiddenByTweak) {
      pid_t pidHideJB;
      const char* argsHideJB[] = {"hidejbhelper","unhide", [jbrootPath UTF8String],NULL};
      posix_spawn(&pidHideJB, [jbrootExecPath UTF8String], NULL, NULL, (char* const*)argsHideJB, NULL);	                               
      isJBHiddenByTweak = NO;
   }
}

%hook SpringBoard

    -(void)frontDisplayDidChange:(id)arg1 {
      %orig;
      if (arg1 == nil) {
         unhideJBIfNecessary();
      }
    }    

%end

%hook SBIconView

   - (NSArray *)applicationShortcutItems
   {
      NSArray *orig = %orig;

      NSString *applicationID;
      if ([self respondsToSelector:@selector(applicationBundleIdentifier)]) {
         applicationID = [self applicationBundleIdentifier];
      }
      else if ([self respondsToSelector:@selector(applicationBundleIdentifierForShortcuts)]) {
         applicationID = [self applicationBundleIdentifierForShortcuts];
      }

      if (!applicationID) {
         return orig;
      }

      BOOL isProtectionEnabled = [protectedApps containsObject:applicationID];  

      SBSApplicationShortcutItem *appLockItem = [[%c(SBSApplicationShortcutItem) alloc] init];
      NSString *imageName;

      if (isProtectionEnabled) {
         appLockItem.localizedTitle = @"Stop Hiding JB";
         imageName = @"eye.fill";
      }
      else {
         appLockItem.localizedTitle = @"Hide JB";
         imageName = @"eye.slash.fill";
      }

      appLockItem.icon = [[%c(SBSApplicationShortcutCustomImageIcon) alloc] initWithImageData:UIImagePNGRepresentation([UIImage systemImageNamed:imageName]) dataType:0 isTemplate:1];

      appLockItem.bundleIdentifierToLaunch = nil;
      appLockItem.type = @"com.p2kdev.autohidejb.toggleProtection";

      return [orig arrayByAddingObject:appLockItem];
   }

   + (void)activateShortcut:(SBSApplicationShortcutItem *)item withBundleIdentifier:(NSString *)bundleID forIconView:(id)iconView
   {
      if ([[item type] isEqualToString:@"com.p2kdev.autohidejb.toggleProtection"]) {         
         updatedProtectedAppsForBundleID(bundleID);
         return;
      }

      %orig;
   }

%end

%hook SBMainWorkspace

   - (void)setCurrentTransaction:(SBWorkspaceTransaction *)trans {
      if (!trans) {
         return %orig;         
      }

      if ([trans isKindOfClass:objc_getClass("SBAppToAppWorkspaceTransaction")]) {
         NSArray *activatingApplications = [[[trans transitionRequest] toApplicationSceneEntities] allObjects];
         if (activatingApplications.count == 0)
            return %orig;

         SBApplication *app = [(SBApplicationSceneEntity*)activatingApplications[0] application];
         NSString *bundle = [app bundleIdentifier];

         BOOL shouldHideJB = [protectedApps containsObject:bundle];   
         if (!shouldHideJB) {      
            return %orig;
         }
         else {
            //NSLog(@"KLPD pid %d processState %lld",app.processState.pid,app.processState.taskState);
            if (app.processState && app.processState.pid > 0)
               return %orig;
            else {
               hideJB();
               if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sileo"]] || [[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"]) {
                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                     return %orig;
                  });
               }
               else
                  return %orig;
            }
         }
      } 
      else
         return %orig;
   }
%end

%ctor {
   refreshProtectedApps();
   jbrootPath = [[NSFileManager defaultManager]  destinationOfSymbolicLinkAtPath:@"/var/jb" error:nil];
   jbrootExecPath = [NSString stringWithFormat:@"%@/usr/libexec/hidejbhelper",jbrootPath];
   NSLog(@"KLPD JBRoot %@ Exec %@",jbrootPath,jbrootExecPath);
}