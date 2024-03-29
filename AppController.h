
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
	IBOutlet NSButton *setEmailButton;
	IBOutlet NSButton *setPasscodeButton;
	
	IBOutlet NSPanel *setPasscodePanel;
	IBOutlet NSPanel *changePasscodePanel;
	IBOutlet NSPanel *enterPasscodePanel;
	
	IBOutlet NSTextField *firstPasscodeEntry;
	IBOutlet NSTextField *secondPasscodeEntry;
    IBOutlet NSTextField *passcodeDoesntMatch;

	IBOutlet NSTextField *oldPasscodeEntry;
	IBOutlet NSTextField *oldPasscodeNotCorrect;
	IBOutlet NSTextField *newFirstPasscodeEntry;
	IBOutlet NSTextField *newSecondPasscodeEntry;
    IBOutlet NSTextField *newPasscodeDoesntMatch;

	IBOutlet NSTextField *actionLabel;
	IBOutlet NSTextField *passcodeEntry;
	IBOutlet NSTextField *passcodeNotCorrect;
	
    NSString *email;
	
	id problemSound;
}

// Menu related
-(IBAction) activateAndOrderFrontStandardAboutPanel:(id)sender;

// Preference related
-(IBAction) showPreferencePanel:(id)sender;

-(IBAction) attemptToQuit:(id)sender;

-(IBAction) showSetPasscodePanel:(id)sender;
-(IBAction) showChangePasscodePanel:(id)sender;

-(IBAction) setPasscode:(id)sender;
-(IBAction) changePasscode:(id)sender;

-(IBAction) enterPasscode:(id)sender;
-(IBAction) cancelEnterPasscode:(id)sender;


@end
