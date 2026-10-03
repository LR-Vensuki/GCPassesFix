// Passbook: accept unsigned, edited and expired passes.
//
// The hooks are SigPass by bag.xml and ObscureMosquito (GPLv3),
// https://github.com/bag-xml/SigPass, kept as they are in SigPass 0.0.1,
// which bag.xml tested on iOS 6. Only the setup differs: each class is hooked
// only where it exists, so SpringBoard on iOS 5 (no PassKit) is left alone.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

%group PKPassHooks
%hook PKPass

- (BOOL)isRevoked {
	return NO;
}

- (id)initWithData:(NSData *)data error:(NSError **)error {
	return %orig(data, nil);
}

- (BOOL)supportsSecureCoding {
	return YES;
}

%end
%end

%group PKLocalPassHooks
%hook PKLocalPass

// returns an error; nil means the pass is valid
- (id)validatePassURL:(id)url {
	%orig;
	return nil;
}

%end
%end

%group WDCardFileManagerHooks
%hook WDCardFileManager

- (void)_deletePossibleInvalidCardWithUniqueID:(id)uniqueID {
}

- (id)validatePassURL:(id)url {
	return @YES;
}

- (id)manifestHashFromPassURL:(id)url {
	return [NSData data];
}

%end
%end

%group WDNetworkTaskManagerHooks
%hook WDNetworkTaskManager

- (void)invalidate {
}

%end
%end

%ctor {
	if (objc_getClass("PKPass")) %init(PKPassHooks);
	if (objc_getClass("PKLocalPass")) %init(PKLocalPassHooks);
	if (objc_getClass("WDCardFileManager")) %init(WDCardFileManagerHooks);
	if (objc_getClass("WDNetworkTaskManager")) %init(WDNetworkTaskManagerHooks);
}
