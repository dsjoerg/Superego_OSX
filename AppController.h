//
//  AppController.h
//  Snapback
//
//  Created by Steve Cook on 4/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import "BezelWindow.h"
#import "JumpcutStore.h"
#import "SGHotKey.h"
#import "DBSyncPromptDelegate.h"

@class SGHotKey;

@interface AppController : NSObject {
    BezelWindow					*bezel;
	SGHotKey					*mainHotKey;
	IBOutlet NSPanel			*prefsPanel;
	int							mainHotkeyModifiers;
	BOOL						isBezelDisplayed;
	BOOL						isBezelPinned; // Currently not used
	NSString					*currentKeycodeCharacter;
	int							stackPosition;
	
	// The below were pulled in from JumpcutController
	JumpcutStore				*clippingStore;
	

    // Status item -- the little icon in the menu bar
    NSStatusItem *statusItem;
    // The menu attatched to same
    IBOutlet NSMenu *jcMenu;
    IBOutlet NSSlider * heightSlider;
    IBOutlet NSSlider * widthSlider;
    // A timer which will let us check the pasteboard;
    // this should default to every .5 seconds but be user-configurable
    NSTimer *pollPBTimer;
    // We want an interface to the pasteboard
    NSPasteboard *jcPasteboard;
    // Track the clipboard count so we only act when its contents change
    NSNumber *pbCount;
    //stores PasteboardCount for internal Jumpcut pasteboard actions so they don't trigger any events
    NSNumber *pbBlockCount;
    //Preferences
	NSDictionary *standardPreferences;
    int jcDisplayNum;
	BOOL issuedRememberResizeWarning;
    BOOL dropboxSync;
    
    IBOutlet NSButtonCell * dropboxCheckbox;
}

//@property(retain, nonatomic) IBOutlet NSButtonCell * dropboxCheckbox;

// Basic functionality
-(void) hideApp;

// Menu related
-(void) updateMenu;
-(IBAction) activateAndOrderFrontStandardAboutPanel:(id)sender;

// Preference related
-(IBAction) showPreferencePanel:(id)sender;
-(IBAction) toggleLoadOnStartup:(id)sender;

@end
