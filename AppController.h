
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>


@interface AppController : NSObject {
    
	IBOutlet NSPanel			*prefsPanel;

    // Status item -- the little icon in the menu bar
    NSStatusItem *statusItem;
    
    // The menu attatched to same
    IBOutlet NSMenu *jcMenu;
    IBOutlet NSSlider * heightSlider;
    IBOutlet NSSlider * widthSlider;
    
    //Preferences
	NSDictionary *standardPreferences;
}

// Basic functionality
-(void) hideApp;

// Menu related
-(void) updateMenu;
-(IBAction) activateAndOrderFrontStandardAboutPanel:(id)sender;

// Preference related
-(IBAction) showPreferencePanel:(id)sender;
-(IBAction) toggleLoadOnStartup:(id)sender;

@end
