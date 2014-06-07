#import "AppController.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "AFHTTPClient.h"

@implementation AppController

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

- (id)init
{
	return [super init];
}

- (void)awakeFromNib
{
	// Build the statusbar menu
    statusItem = [[[NSStatusBar systemStatusBar]
            statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setHighlightMode:YES];
    id theImage = [NSImage imageNamed:@"Status"];
    [statusItem setImage:theImage];
	[statusItem setMenu:jcMenu];
    [statusItem setEnabled:YES];
	
	[NSApp activateIgnoringOtherApps: YES];
    
    [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(wakeUpAndDoStuff) userInfo:nil repeats:YES];
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

-(void) wakeUpAndDoStuff
{
    BOOL developmentServer = YES;
    NSString *protocol;
    NSString *apiHost;
    
    if (developmentServer) {
        protocol = @"http";
        apiHost = @"localhost:3000";
    } else {
        protocol = @"https";
        apiHost = @"superego.herokuapp.com";
    }
    NSString *urlString = [NSString stringWithFormat:@"%@://%@", protocol, apiHost];
    
    // hit superego server and find out whether we need to kill everything
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:urlString]];
    [client getPath:@"/api/v1/curfew/is_active" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        DDLogDebug(@"Got an answer! %@", responseString);
        if ([responseString isEqualToString:@"true"]) {
            [self killEverythingDead];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogDebug(@"Failed! With error %@", error);
    }];
}

-(IBAction) activateAndOrderFrontStandardAboutPanel:(id)sender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
}


-(IBAction) showPreferencePanel:(id)sender
{
	if ([prefsPanel respondsToSelector:@selector(setCollectionBehavior:)])
		[prefsPanel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[NSApp activateIgnoringOtherApps: YES];
	[prefsPanel makeKeyAndOrderFront:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    
    [DDLog addLogger:fileLogger];
}


-(void)hideApp
{
	[NSApp hide:self];
}


- (void)applicationWillTerminate:(NSNotification *)notification {

}


@end
