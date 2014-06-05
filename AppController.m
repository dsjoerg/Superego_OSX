

#import "AppController.h"
#import "NSWindow+TrueCenter.h"
#import "NSWindow+ULIZoomEffect.h"

#define _DISPLENGTH 40

@implementation AppController

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
	issuedRememberResizeWarning = NO;
}

-(IBAction)toggleLoadOnStartup:(id)sender {
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

}


- (void)applicationWillTerminate:(NSNotification *)notification {

}


- (void) dealloc {
	[super dealloc];
}

@end
