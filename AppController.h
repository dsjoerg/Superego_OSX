
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>


@interface AppController : NSObject {
    
	IBOutlet NSPanel			*prefsPanel;

    // Status item -- the little icon in the menu bar
    NSStatusItem *statusItem;
    
    // The menu attatched to same
    IBOutlet NSMenu *jcMenu;
    
    //Preferences
	NSDictionary *standardPreferences;
}

// Basic functionality
-(void) hideApp;

// Menu related
-(IBAction) activateAndOrderFrontStandardAboutPanel:(id)sender;

// Preference related
-(IBAction) showPreferencePanel:(id)sender;

@end
