

#import "AppController.h"
#import "SGHotKey.h"
#import "SGHotKeyCenter.h"
#import "UKLoginItemRegistry.h"
#import "NSWindow+TrueCenter.h"
#import "NSWindow+ULIZoomEffect.h"
#import "DBUserDefaults.h"

#define _DISPLENGTH 40

@implementation AppController

- (id)init
{
	[[DBUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:10],
		@"displayNum",
		[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:9],[NSNumber numberWithLong:1179648],nil] forKeys:[NSArray arrayWithObjects:@"keyCode",@"modifierFlags",nil]],
		@"ShortcutRecorder mainHotkey",
		[NSNumber numberWithInt:40],
		@"rememberNum",
		[NSNumber numberWithInt:1],
		@"savePreference",
		[NSNumber numberWithInt:0],
		@"menuIcon",
		[NSNumber numberWithFloat:.25],
		@"bezelAlpha",
		[NSNumber numberWithBool:YES],
		@"stickyBezel",
		[NSNumber numberWithBool:NO],
		@"wraparoundBezel",
		[NSNumber numberWithBool:NO],// No by default
		@"loadOnStartup",
		[NSNumber numberWithBool:YES], 
		@"menuSelectionPastes",
        // Flycut new options
        [NSNumber numberWithFloat:500.0],
        @"bezelWidth",
        [NSNumber numberWithFloat:320.0],
        @"bezelHeight",
        [NSDictionary dictionary],
        @"store",
        [NSNumber numberWithBool:YES],
        @"skipPasswordFields",
        [NSNumber numberWithBool:NO],
        @"removeDuplicates",
        [NSNumber numberWithBool:YES],
        @"popUpAnimation",
        [NSNumber numberWithBool:NO],
        @"pasteMovesToTop",
        nil]];
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
}

-(IBAction) activateAndOrderFrontStandardAboutPanel:(id)sender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
}


-(IBAction) showPreferencePanel:(id)sender
{                                    
	int checkLoginRegistry = [UKLoginItemRegistry indexForLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
	if ( checkLoginRegistry >= 1 ) {
		[[DBUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES]
												 forKey:@"loadOnStartup"];
	} else {
		[[DBUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO]
												 forKey:@"loadOnStartup"];
	}
	
	if ([prefsPanel respondsToSelector:@selector(setCollectionBehavior:)])
		[prefsPanel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[NSApp activateIgnoringOtherApps: YES];
	[prefsPanel makeKeyAndOrderFront:self];
	issuedRememberResizeWarning = NO;
}

-(IBAction)toggleLoadOnStartup:(id)sender {
	if ( [[DBUserDefaults standardUserDefaults] boolForKey:@"loadOnStartup"] ) {
		[UKLoginItemRegistry addLoginItemWithPath:[[NSBundle mainBundle] bundlePath] hideIt:NO];
	} else {
		[UKLoginItemRegistry removeLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
	}
}





- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
}


-(void)hideApp
{
	[NSApp hide:self];
}

- (void) applicationWillResignActive:(NSApplication *)app; {
}


- (void)updateMenu {
    
    NSArray *returnedDisplayStrings = [clippingStore previousDisplayStrings:[[DBUserDefaults standardUserDefaults] integerForKey:@"displayNum"]];
    
    NSArray *menuItems = [[[jcMenu itemArray] reverseObjectEnumerator] allObjects];
    
    NSArray *clipStrings = [[returnedDisplayStrings reverseObjectEnumerator] allObjects];

    int passedSeparator = 0;
	
    //remove clippings from menu
    for (NSMenuItem *oldItem in menuItems) {
		if( [oldItem isSeparatorItem]) {
            passedSeparator++;
        } else if ( passedSeparator == 2 ) {
            [jcMenu removeItem:oldItem];
        }     
    }
	
    for(NSString *pbMenuTitle in clipStrings) {
        NSMenuItem *item;
        item = [[NSMenuItem alloc] initWithTitle:pbMenuTitle
										  action:@selector(processMenuClippingSelection:)
								   keyEquivalent:@""];
        [item setTarget:self];
        [item setEnabled:YES];
        [jcMenu insertItem:item atIndex:0];
        // Way back in 0.2, failure to release the new item here was causing a quite atrocious memory leak.
        [item release];
	} 
}


- (void)applicationWillTerminate:(NSNotification *)notification {
	if ( [[DBUserDefaults standardUserDefaults] integerForKey:@"savePreference"] >= 1 ) {
		NSLog(@"Saving on exit");
    } else {
        NSLog(@"Saving preferences on exit");
        [[DBUserDefaults standardUserDefaults] synchronize];
    }

}


- (void) dealloc {
	[super dealloc];
}

@end
