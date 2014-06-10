
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>


@interface AppController : NSObject {
    
	IBOutlet NSPanel			*prefsPanel;

    // Status item -- the little icon in the menu bar
    NSStatusItem *statusItem;
    
    // The menu attatched to same
    IBOutlet NSMenu *jcMenu;
    
    // The hidden main menu
    IBOutlet NSMenu *mainMenu;

    // The menu item where we show what time tonight's curfew is
    IBOutlet NSMenuItem *curfewMenuItem;
    
    IBOutlet NSTextField *emailTextField;
    
    NSString *email;
}

// Basic functionality
-(void) hideApp;

// Menu related
-(IBAction) activateAndOrderFrontStandardAboutPanel:(id)sender;

// Preference related
-(IBAction) showPreferencePanel:(id)sender;

// Termination that has been authorized by entering the passcode
-(IBAction) properTermination:(id)sender;

-(void) controlTextDidEndEditing:(NSNotification *)aNotification;

@end
