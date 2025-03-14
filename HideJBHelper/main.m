#include <stdio.h>
#include <spawn.h>
#include <signal.h>

extern char **environ;

int main(int argc, char *argv[], char *envp[]) {
    setuid(0);
    setgid(0);  

    if (!argv[1]) {
        NSLog(@"invalid operation");
        return 1;
    }

    NSString *operation = [NSString stringWithUTF8String:argv[1]];
    NSString *option = nil;
    if (argv[2])
        option = [NSString stringWithUTF8String:argv[2]];

    //NSLog(@"KLPD JBHelper %@ %@",operation,option);

    if ([operation isEqualToString:@"hide"]) {
        NSArray *jailbreakApps = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/jb/Applications" error:nil];
        if (jailbreakApps.count) {
            for (NSString *jailbreakApp in jailbreakApps) {
                NSString *jailbreakAppPath = [@"/var/jb/Applications" stringByAppendingPathComponent:jailbreakApp];
                pid_t pid;
                const char *args[] = {"/var/jb/usr/bin/uicache", "-u", [jailbreakAppPath UTF8String], NULL};
                posix_spawn(&pid, args[0], NULL, NULL, (char *const *)args, envp);
                int status;
                waitpid(pid, &status, 0);
            }
        }
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/jb" error:nil];  
    }
    else if ([operation isEqualToString:@"unhide"]) {
        if (!option) {
            NSLog(@"Symlink destination not provided");
            return 2;
        }

        if (![[NSFileManager defaultManager] fileExistsAtPath:option]) {
            NSLog(@"Symlink destination path doesn't exist");
            return 3;
        }            

        [[NSFileManager defaultManager] createSymbolicLinkAtPath:@"/var/jb" withDestinationPath:option error:nil];

        NSArray *jailbreakApps = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/jb/Applications" error:nil];
        if (jailbreakApps.count) {
            for (NSString *jailbreakApp in jailbreakApps) {
                NSString *jailbreakAppPath = [@"/var/jb/Applications" stringByAppendingPathComponent:jailbreakApp];
                pid_t pid;
                const char *args[] = {"/var/jb/usr/bin/uicache", "-a", [jailbreakAppPath UTF8String], NULL};
                posix_spawn(&pid, args[0], NULL, NULL, (char *const *)args, envp);
                int status;
                waitpid(pid, &status, 0);
            }
        }        
    }

	return 0;
}