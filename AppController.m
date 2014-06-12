#import "AppController.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import <CommonCrypto/CommonDigest.h>

@implementation AppController

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

static const NSString *emailPrefsKey = @"email";
static const NSString *passcodeMD5Key = @"passcodeMD5";


- (id)init
{
    return [super init];
}


-(void) setupLogging
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    
    [DDLog addLogger:fileLogger];
}

- (void)buildStatusBarMenu
{
    statusItem = [[[NSStatusBar systemStatusBar]
                   statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setHighlightMode:YES];
    id theImage = [NSImage imageNamed:@"Status"];
    [statusItem setImage:theImage];
    [statusItem setMenu:jcMenu];
    [statusItem setEnabled:YES];
}

-(void) killEverythingDead
{
    NSArray *runningApplications = [[NSWorkspace sharedWorkspace] runningApplications];
    
    DDLogDebug(@"Hi! There are %lu running applications.", (unsigned long)[runningApplications count]);
    
    //    NSArray *killThese = @[@"Safari", @"Firefox", @"Google Chrome", @"StarCraft II", @"Hearthstone"];
    NSArray *killThese = @[@"Safari", @"Firefox", @"StarCraft II", @"Hearthstone"];
    
    for (NSRunningApplication *app in runningApplications) {
        //        DDLogDebug(@"%d: %@ %@", [app processIdentifier], [app localizedName], [app bundleIdentifier]);
        if ([killThese containsObject:[app localizedName]]) {
            DDLogDebug(@"Killing %@", [app localizedName]);
            BOOL result = [app terminate];
            DDLogDebug(@"And... %hhd", result);
        }
    }
}

-(NSString *)baseServerURL
{
    BOOL developmentServer = NO;
    NSString *protocol;
    NSString *apiHost;
    
    if (developmentServer) {
        protocol = @"http";
        apiHost = @"localhost:3000";
    } else {
        protocol = @"https";
        apiHost = @"superego.herokuapp.com";
    }
    return [NSString stringWithFormat:@"%@://%@", protocol, apiHost];
}

-(NSString *)curfewActivePath
{
    return [NSString stringWithFormat:@"/api/v1/curfew/is_active?email=%@", email];
}

-(NSString *)curfewPath
{
    return [NSString stringWithFormat:@"/api/v1/curfew/compute?email=%@", email];
}

-(NSString *) curfewFromJSON:(id)JSON
{
    NSArray *values = [JSON allValues];
    return values[0];
}

-(void) updateDisplayedCurfew
{
    NSString *requestString = [NSString stringWithFormat:@"%@/%@", [self baseServerURL], [self curfewPath]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *curfew = [self curfewFromJSON:JSON];
        NSString *menuTitle = [NSString stringWithFormat:@"Curfew: %@", curfew];
        [curfewMenuItem setTitle:menuTitle];

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DDLogDebug(@"Failed! With error %@", error);
    }];
    [operation start];
}

-(void) killEverythingIfAfterCurfew
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:[self baseServerURL]]];
    [client getPath:[self curfewActivePath] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        if ([responseString isEqualToString:@"true"]) {
            [self killEverythingDead];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogDebug(@"Failed! With error %@", error);
    }];
}

-(void) wakeUpAndDoStuff
{
    [self updateDisplayedCurfew];
    [self killEverythingIfAfterCurfew];
}

-(IBAction) activateAndOrderFrontStandardAboutPanel:(id)sender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
}

-(void) showPanel:(NSPanel *)panel
{
    if ([panel respondsToSelector:@selector(setCollectionBehavior:)])
        [panel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    [NSApp activateIgnoringOtherApps: YES];
	[panel center];
    [panel makeKeyAndOrderFront:self];
}

-(IBAction) showPreferencePanel:(id)sender
{
	[emailTextField setStringValue:email];
	[self showPanel:prefsPanel];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self setupLogging];
    [self buildStatusBarMenu];
	
	problemSound = [NSSound soundNamed:@"Basso"];
	
	// to reset your passcode when testing
//	[self setPasscodeToString:nil];
    
    // gotta do this so that edit commands work as expected.
    [NSApp setMainMenu:mainMenu];
    
    email = [[NSUserDefaults standardUserDefaults] stringForKey:(NSString *)emailPrefsKey];
    [emailTextField setStringValue:email];
	
	NSString *passcodeMD5 = [[NSUserDefaults standardUserDefaults] stringForKey:(NSString *)passcodeMD5Key];
	if (passcodeMD5 != nil && [passcodeMD5 length] > 0) {
		[setPasscodeButton setTitle:@"Change Passcode"];
		[setPasscodeButton setAction:@selector(showChangePasscodePanel:)];
	}
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(wakeUpAndDoStuff) userInfo:nil repeats:YES];
    // fire it once right away to get things off on the right foot
    [timer fire];
    
    DDLogDebug(@"Hi, currently executing from %@", [[NSBundle mainBundle] bundlePath]);
    [self writeLaunchAgentFile];
	
	// comment out during testing, but do not commit!
    [self loadLaunchAgentAndDie];
}


-(void)hideApp
{
    [NSApp hide:self];
}


- (void)applicationWillTerminate:(NSNotification *)notification {
    DDLogDebug(@"appWillTerminate");
}

// returns NO if a passcode has been set up and the user does not enter it.
// otherwise YES
-(BOOL) passcodeGateway:(NSString *)actionDescription
{
	BOOL clearedToProceed = YES;
	
	NSString *passcodeMD5 = [[NSUserDefaults standardUserDefaults] stringForKey:(NSString *)passcodeMD5Key];
	if (passcodeMD5 != nil) {
//		DDLogDebug(@"before runModalForWindow");
		[actionLabel setStringValue:[NSString stringWithFormat:@"You need to enter your Passcode to %@.", actionDescription]];
		[self showPanel:enterPasscodePanel];
		NSInteger modalResult = [NSApp runModalForWindow:enterPasscodePanel];
		[enterPasscodePanel close];
//		DDLogDebug(@"after runModalForWindow: %ld", (long)modalResult);
		if (modalResult != NSModalResponseStop) {
			clearedToProceed = NO;
		}
	}

	DDLogWarn(@"passcodeGateway: %hhd", clearedToProceed);
	return clearedToProceed;
}

-(IBAction) attemptToQuit:(id)sender
{
	if ([self passcodeGateway:@"quit"]) {
		[self properTermination];
	}
}

-(void) properTermination
{
    NSString *unloadResult = [self launchAgentLoad:NO];
    DDLogDebug(@"Unloading, result=%@", unloadResult);
    [[NSApplication sharedApplication] terminate:nil];
}

-(NSMutableDictionary *) propertyListForSuperegoLaunchAgent
{
    NSString *appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/MacOS/Superego"];
    NSMutableDictionary *rootObj = [NSMutableDictionary dictionaryWithCapacity:2];
    [rootObj setObject:@"com.davidjoerg.superego" forKey:@"Label"];

    // Deprecated as of OS X 10.5: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html
    //    [rootObj setObject:@NO forKey:@"OnDemand"];

    [rootObj setObject:@YES forKey:@"KeepAlive"];

    [rootObj setObject:@[appPath] forKey:@"ProgramArguments"];

    return rootObj;
}

-(NSString *)launchAgentFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if ([paths count] == 0) {
        DDLogError(@"Can't find where to put the LaunchAgent file");
        return nil;
    }
    NSString *basePath = paths[0];
    return [[basePath stringByAppendingPathComponent:@"LaunchAgents"] stringByAppendingPathComponent:@"com.davidjoerg.superego.plist"];
}

-(void) writeLaunchAgentFile
{
    NSString *error;
    NSString *launchAgentFilePath = [self launchAgentFilePath];
    if (launchAgentFilePath) {
        NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:[self propertyListForSuperegoLaunchAgent] format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
        [plistData writeToFile:launchAgentFilePath atomically:YES];
    }
}

-(NSString *) launchAgentLoad:(BOOL)load
{
    // http://stackoverflow.com/questions/16056831/using-launchctl-in-from-nstask
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/launchctl"];
    
    NSString *command = load ? @"load" : @"unload";
    NSArray *arguments;
    arguments = @[command, [self launchAgentFilePath]];
    [task setArguments: arguments];
    NSPipe * out = [NSPipe pipe];
    [task setStandardError:out];
    
    [task launch];
    [task waitUntilExit];
    [task release];
    
    NSFileHandle *read = [out fileHandleForReading];
    NSData *dataRead = [read readDataToEndOfFile];
    NSString *loadStatusMessage = [[[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding] autorelease];

    return loadStatusMessage;
}

-(void) loadLaunchAgentAndDie
{
    NSString *loadStatusMessage = [self launchAgentLoad:YES];
    
    DDLogDebug(@"load command returned string of length %lu: %@", (unsigned long)[loadStatusMessage length], loadStatusMessage);
    
    if ([loadStatusMessage length] == 0) {
        // load succeeded. this also causes a copy of ourselves to be launched.
        // time for us to die.  the launchctl-launched version will live on.
        [[NSApplication sharedApplication] terminate:nil];
    }
    // the message might be:
    // "Already loaded"
    // or
    // "Some shit went totally wrong"
    // we should complain to DJ if something went wrong.
}

- (void)updateEmailFromTextField
{
	NSString *desiredEmail = [emailTextField stringValue];
	if ([desiredEmail isEqualToString:email]) {
		return;
	}

	if ([self passcodeGateway:@"change your email address"]) {
		email = desiredEmail;
		[[NSUserDefaults standardUserDefaults] setValue:email forKey:(NSString *)emailPrefsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[self wakeUpAndDoStuff];
	} else {
		[emailTextField setStringValue:email];
	}
}

-(IBAction) setEmail:(id)sender
{
	[self updateEmailFromTextField];
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
	[setEmailButton setHidden:NO];
}

-(IBAction) showSetPasscodePanel:(id)sender
{
	[firstPasscodeEntry setStringValue:@""];
	[secondPasscodeEntry setStringValue:@""];
	[self showPanel:setPasscodePanel];
}

-(IBAction) showChangePasscodePanel:(id)sender
{
	[oldPasscodeEntry setStringValue:@""];
	[newFirstPasscodeEntry setStringValue:@""];
	[newSecondPasscodeEntry setStringValue:@""];
	[self showPanel:changePasscodePanel];
}

-(NSString *) md5hash:(NSString *)someNSString
{
	const char *cStr = [someNSString UTF8String];
	unsigned char resultChar[16];
	CC_MD5( cStr, strlen(cStr), resultChar);
	NSString *md5 = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                 resultChar[0], resultChar[1], resultChar[2], resultChar[3],
                 resultChar[4], resultChar[5], resultChar[6], resultChar[7],
                 resultChar[8], resultChar[9], resultChar[10], resultChar[11],
                 resultChar[12], resultChar[13], resultChar[14], resultChar[15]];
	return md5;
}

-(void) setPasscodeToString:(NSString *)passcode
{
	if (passcode == nil) {
		DDLogWarn(@"Clearing passcode!");
		[[NSUserDefaults standardUserDefaults] setValue:nil forKey:(NSString *)passcodeMD5Key];
		[setPasscodeButton setTitle:@"Set Passcode"];
		[setPasscodeButton setAction:@selector(showSetPasscodePanel:)];
	} else {
		[[NSUserDefaults standardUserDefaults] setValue:[self md5hash:passcode] forKey:(NSString *)passcodeMD5Key];
		[setPasscodeButton setTitle:@"Change Passcode"];
		[setPasscodeButton setAction:@selector(showChangePasscodePanel:)];
	}
}

-(IBAction) setPasscode:(id)sender
{
	NSString *firstPasscode = [firstPasscodeEntry stringValue];
	NSString *secondPasscode = [secondPasscodeEntry stringValue];
	
	if ([firstPasscode isEqualToString:secondPasscode]) {
		[self setPasscodeToString:firstPasscode];
		[passcodeDoesntMatch setHidden:YES];
		[setPasscodePanel close];
	} else {
		[self problemBeep];
		[passcodeDoesntMatch setHidden:NO];
	}
}

-(IBAction) changePasscode:(id)sender
{
	NSString *oldPasscode = [oldPasscodeEntry stringValue];
	NSString *passcodeMD5 = [[NSUserDefaults standardUserDefaults] stringForKey:(NSString *)passcodeMD5Key];
	if (![[self md5hash:oldPasscode] isEqualToString:passcodeMD5]) {
		[self problemBeep];
		[oldPasscodeNotCorrect setHidden:NO];
		return;
	} else {
		[oldPasscodeNotCorrect setHidden:YES];
	}
	
	NSString *firstPasscode = [newFirstPasscodeEntry stringValue];
	NSString *secondPasscode = [newSecondPasscodeEntry stringValue];
	DDLogDebug(@"change passcode! %@ %@", firstPasscode, secondPasscode);
	
	if ([firstPasscode isEqualToString:secondPasscode]) {
		[self setPasscodeToString:firstPasscode];
		[newPasscodeDoesntMatch setHidden:YES];
		[changePasscodePanel close];
	} else {
		[self problemBeep];
		[newPasscodeDoesntMatch setHidden:NO];
	}
}

-(IBAction) enterPasscode:(id)sender
{
	NSString *enteredPasscode = [passcodeEntry stringValue];
	NSString *enteredPasscodeMD5 = [self md5hash:enteredPasscode];
	NSString *passcodeMD5 = [[NSUserDefaults standardUserDefaults] stringForKey:(NSString *)passcodeMD5Key];
	if ([passcodeMD5 isEqualToString:enteredPasscodeMD5]) {
		[[NSApplication sharedApplication] stopModal];
	} else {
		[self problemBeep];
		[passcodeNotCorrect setHidden:NO];
	}
}

-(IBAction) cancelEnterPasscode:(id)sender
{
	[[NSApplication sharedApplication] abortModal];
}

-(void) problemBeep
{
	[problemSound play];
}


@end
