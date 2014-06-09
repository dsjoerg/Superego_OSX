#import "AppController.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

@implementation AppController

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

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

- (void)awakeFromNib
{
    [self setupLogging];
    [self buildStatusBarMenu];
	
	[NSApp activateIgnoringOtherApps: YES];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(wakeUpAndDoStuff) userInfo:nil repeats:YES];
    // fire it once right away to get things off on the right foot
    [timer fire];
    
    DDLogDebug(@"Hi, currently executing from %@", [[NSBundle mainBundle] bundlePath]);
    [self writeLaunchAgentFile];
    [self loadLaunchAgent];
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
    return [NSString stringWithFormat:@"%@://%@", protocol, apiHost];
}

-(NSString *)curfewActivePath
{
    return @"/api/v1/curfew/is_active";
}

-(NSString *)curfewPath
{
    return @"/api/v1/curfew/compute";
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
        DDLogDebug(@"Got an answer! %@", responseString);
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


-(IBAction) showPreferencePanel:(id)sender
{
	if ([prefsPanel respondsToSelector:@selector(setCollectionBehavior:)])
		[prefsPanel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[NSApp activateIgnoringOtherApps: YES];
	[prefsPanel makeKeyAndOrderFront:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
}


-(void)hideApp
{
	[NSApp hide:self];
}


- (void)applicationWillTerminate:(NSNotification *)notification {

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
    NSString *basePath = [paths objectAtIndex:0];
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

-(void) loadLaunchAgent
{
    // ARGH is there a way to load a LaunchAgent without triggering a re-launch of the process?!?

    // http://stackoverflow.com/questions/16056831/using-launchctl-in-from-nstask
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/launchctl"];
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects: @"load", [self launchAgentFilePath], nil];
    [task setArguments: arguments];
    
    [task launch];
}

@end
