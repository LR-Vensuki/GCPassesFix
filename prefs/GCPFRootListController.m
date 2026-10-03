#import "GCPFRootListController.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <spawn.h>
#import <sys/wait.h>
#import <unistd.h>

// The buttons shell out to /usr/bin/gcpassesfix as root. The prefs bundle runs
// inside Preferences (mobile), so the work is handed to the setuid root helper
// /usr/libexec/gcpassesfix-run, installed by the package.

static NSString *runHelper(NSString *verb) {
	const char *argv[] = { "/usr/libexec/gcpassesfix-run", [verb UTF8String], NULL };
	int outPipe[2];
	if (pipe(outPipe) != 0) return @"Could not start helper.";

	posix_spawn_file_actions_t fa;
	posix_spawn_file_actions_init(&fa);
	posix_spawn_file_actions_adddup2(&fa, outPipe[1], STDOUT_FILENO);
	posix_spawn_file_actions_adddup2(&fa, outPipe[1], STDERR_FILENO);
	posix_spawn_file_actions_addclose(&fa, outPipe[0]);

	pid_t pid;
	int rc = posix_spawn(&pid, argv[0], &fa, NULL, (char *const *)argv, NULL);
	posix_spawn_file_actions_destroy(&fa);
	close(outPipe[1]);
	if (rc != 0) {
		close(outPipe[0]);
		return @"Helper is missing (/usr/libexec/gcpassesfix-run).";
	}

	NSMutableData *data = [NSMutableData data];
	char buf[1024];
	ssize_t n;
	while ((n = read(outPipe[0], buf, sizeof(buf))) > 0) [data appendBytes:buf length:n];
	close(outPipe[0]);
	int status = 0;
	waitpid(pid, &status, 0);

	NSString *out = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return out.length ? out : @"Done.";
}

@implementation GCPFRootListController

- (NSArray *)specifiers {
	if (!_specifiers)
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	return _specifiers;
}

- (void)alertWithTitle:(NSString *)title message:(NSString *)message {
	UIAlertView *a = [[UIAlertView alloc] initWithTitle:title
	                                            message:message
	                                           delegate:nil
	                                  cancelButtonTitle:@"OK"
	                                  otherButtonTitles:nil];
	[a show];
}

- (void)confirm:(NSString *)message onConfirm:(SEL)sel {
	UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"GCPassesFix"
	                                            message:message
	                                           delegate:self
	                                  cancelButtonTitle:@"Cancel"
	                                  otherButtonTitles:@"Continue", nil];
	objc_setAssociatedObject(a, "sel", NSStringFromSelector(sel), OBJC_ASSOCIATION_RETAIN);
	[a show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
	if (index == alertView.cancelButtonIndex) return;
	NSString *selName = objc_getAssociatedObject(alertView, "sel");
	if (selName) {
		SEL sel = NSSelectorFromString(selName);
		if ([self respondsToSelector:sel])
			((void (*)(id, SEL))objc_msgSend)(self, sel);
	}
}

#pragma mark - Buttons

- (void)installCerts {
	NSString *out = runHelper(@"certs");
	[self alertWithTitle:@"Root certificates" message:out];
}

- (void)resetGameCenter {
	[self confirm:@"Back up and clear Game Center, iTunes Store and Setup state? "
	               @"Your passes, apps and files are left untouched. After this, "
	               @"reboot and the device should start in Setup for a clean sign-in. "
	               @"You can undo this with Restore."
	    onConfirm:@selector(doResetGameCenter)];
}

- (void)doResetGameCenter {
	NSString *out = runHelper(@"reset");
	[self alertWithTitle:@"Reset done" message:out];
}

- (void)restoreGameCenter {
	NSString *out = runHelper(@"restore");
	[self alertWithTitle:@"Restore" message:out];
}

- (void)showStatus {
	NSString *out = runHelper(@"status");
	[self alertWithTitle:@"Status" message:out];
}

- (void)reboot {
	[self confirm:@"Reboot now?" onConfirm:@selector(doReboot)];
}

- (void)doReboot {
	runHelper(@"reboot");
}

@end
