
#import "MBPreferenceController.h"
#import "ObjCSword/SwordManager.h"
#import "IndexingManager.h"
#import "globals.h"
#import "NSDictionary+ModuleDisplaySettings.h"
#import "NSMutableDictionary+ModuleDisplaySettings.h"

@interface MBPreferenceController ()

- (void)applyFontPreviewText;
- (void)applyFontTextFieldPreviewHeight;

- (void)moduleFontsTableViewDoubleClick:(id)sender;

@end

@implementation MBPreferenceController

@synthesize delegate;
@synthesize sheetWindow;

static MBPreferenceController *instance;

+ (MBPreferenceController *)defaultPrefsController {
    if(instance == nil) {
        instance = [[MBPreferenceController alloc] init];
    }
    
    return instance;
}

- (id)init {
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id)aDelegate {
	CocoLog(LEVEL_DEBUG,@"");
	
	self = [super initWithWindowNibName:@"Preferences" owner:self];
	if(self == nil) {
		CocoLog(LEVEL_ERR, @"cannot init!");		
	} else {
        instance = self;
        delegate = aDelegate;
        moduleFontAction = NO;
        currentModuleName = nil;
	}
	
	return self;
}

- (void)windowWillClose:(NSNotification *)notification {
    CocoLog(LEVEL_DEBUG, @"");
    // tell delegate that we are closing
    if(delegate && [delegate respondsToSelector:@selector(auxWindowClosing:)]) {
        [delegate performSelector:@selector(auxWindowClosing:) withObject:self];
    } else {
        CocoLog(LEVEL_WARN, @"delegate does not respond to selector!");
    }
}

/**
\brief dealloc of this class is called on closing this document
 */
- (void)finalize {
	// dealloc object
	[super finalize];
}

- (NSArray *)moduleNamesOfTypeBible {
    return [[SwordManager defaultManager] modulesForType:Bible];
}

- (NSArray *)moduleNamesOfTypeDictionary {
    return [[SwordManager defaultManager] modulesForType:Dictionary];
}

- (NSArray *)moduleNamesOfTypeStrongsGreek {
    return [[SwordManager defaultManager] modulesForFeature:SWMOD_CONF_FEATURE_GREEKDEF];
}

- (NSArray *)moduleNamesOfTypeStrongsHebrew {
    return [[SwordManager defaultManager] modulesForFeature:SWMOD_CONF_FEATURE_HEBREWDEF];
}

- (NSArray *)moduleNamesOfTypeMorphHebrew {
    return [[SwordManager defaultManager] modulesForFeature:SWMOD_CONF_FEATURE_HEBREWPARSE];
}

- (NSArray *)moduleNamesOfTypeMorphGreek {
    return [[SwordManager defaultManager] modulesForFeature:SWMOD_CONF_FEATURE_GREEKPARSE];
}

- (NSArray *)moduleNamesOfTypeDailyDevotion {
    return [[SwordManager defaultManager] modulesForFeature:SWMOD_CONF_FEATURE_DAILYDEVOTION];
}

- (WebPreferences *)defaultWebPreferences {
    return [self defaultWebPreferencesForModuleName:nil];
}

- (WebPreferences *)defaultWebPreferencesForModuleName:(NSString *)aModName {
    // init web preferences
    WebPreferences *webPreferences = [[WebPreferences alloc] init];
    [webPreferences setAutosaves:NO];
    // set defaults
    [webPreferences setJavaEnabled:NO];
    [webPreferences setJavaScriptEnabled:NO];
    [webPreferences setPlugInsEnabled:NO];
    // set default font
    if(aModName == nil) {
        [webPreferences setStandardFontFamily:[userDefaults stringForKey:DefaultsBibleTextDisplayFontFamilyKey]];
        [webPreferences setDefaultFontSize:[userDefaults integerForKey:DefaultsBibleTextDisplayFontSizeKey]];                
    } else {
        NSFont *defaultFont = [self normalDisplayFontForModuleName:aModName];
        [webPreferences setStandardFontFamily:[defaultFont familyName]];
        [webPreferences setDefaultFontSize:(int)[defaultFont pointSize]];
    }
    
    return webPreferences;    
}

- (NSFont *)normalDisplayFontForModuleName:(NSString *)aModName {
    NSString *fontFamily = [userDefaults stringForKey:DefaultsBibleTextDisplayFontFamilyKey];
    int fontSize = [userDefaults integerForKey:DefaultsBibleTextDisplayFontSizeKey];
    NSFont *displayFont = [NSFont fontWithName:fontFamily size:(float)fontSize];

    NSDictionary *settings = [[userDefaults objectForKey:DefaultsModuleDisplaySettingsKey] objectForKey:[aModName lowercaseString]];
    if(settings) {
        displayFont = [settings displayFont];
    }
    
    return displayFont;
}

- (NSFont *)boldDisplayFontForModuleName:(NSString *)aModName {
    NSString *fontFamily = [userDefaults stringForKey:DefaultsBibleTextDisplayBoldFontFamilyKey];
    int fontSize = [userDefaults integerForKey:DefaultsBibleTextDisplayFontSizeKey];
    NSFont *displayFont = [NSFont fontWithName:fontFamily size:(float)fontSize];
    
    NSDictionary *settings = [[userDefaults objectForKey:DefaultsModuleDisplaySettingsKey] objectForKey:[aModName lowercaseString]];
    if(settings) {
        displayFont = [settings displayFontBold];
    }
    
    return displayFont;    
}

//--------------------------------------------------------------------
//----------- bundle delegates ---------------------------------------
//--------------------------------------------------------------------
- (void)awakeFromNib {
	CocoLog(LEVEL_DEBUG,@"[MBPreferenceController -awakeFromNib]");
	
    generalViewRect = [generalView frame];
    bibleDisplayViewRect = [bibleDisplayView frame];
    moduleFontsViewRect = [moduleFontsView frame];
    printPrefsViewRect = [printPrefsView frame];
    
    [moduleFontsTableView setTarget:self];
    [moduleFontsTableView setDoubleAction:@selector(moduleFontsTableViewDoubleClick:)];
    
    // calculate margins
    southMargin = [prefsTabView frame].origin.y;
    northMargin = [[self window] frame].size.height - [prefsTabView frame].size.height + 50;
    sideMargin = ([[self window] frame].size.width - [prefsTabView frame].size.width) / 2;
    
    // topTabViewmargin
    topTabViewMargin = [prefsTabView frame].size.height - [prefsTabView contentRect].size.height;
    
    // init tabview
    //preselect tabitem general
    NSTabViewItem *tvi = [prefsTabView tabViewItemAtIndex:0];
    [prefsTabView selectTabViewItem:tvi];
    // call delegate directly
    [self tabView:prefsTabView didSelectTabViewItem:tvi];
    
    [self applyFontPreviewText];
}

- (void)changeFont:(id)sender {
	CocoLog(LEVEL_DEBUG,@"[MBPreferenceController -changeFont]");
    
    NSFont *newFont = [sender convertFont:bibleDisplayFont];
    // get font data
    //NSString *displayName = [newFont displayName];
    NSString *fontFamily = [newFont familyName];
    float fontSize = [newFont pointSize];
    NSString *fontBoldName = [NSString stringWithString:fontFamily];
    if(![fontBoldName hasSuffix:@"Bold"]) {
        NSString *fontBoldNameTemp = [NSString stringWithFormat:@"%@ Bold", fontFamily];
        if([[fontManager availableFontFamilies] containsObject:fontBoldNameTemp]) {
            fontBoldName = fontBoldNameTemp;
        }
    }
    
    if(!moduleFontAction) {
        [userDefaults setObject:fontFamily forKey:DefaultsBibleTextDisplayFontFamilyKey];
        [userDefaults setObject:fontBoldName forKey:DefaultsBibleTextDisplayBoldFontFamilyKey];
        [userDefaults setObject:[NSNumber numberWithInt:(int)fontSize] forKey:DefaultsBibleTextDisplayFontSizeKey];
        
        [self applyFontPreviewText];        
    } else {
        NSMutableDictionary *moduleSettings = [NSMutableDictionary dictionaryWithDictionary:[userDefaults objectForKey:DefaultsModuleDisplaySettingsKey]];
        NSMutableDictionary *settings = [moduleSettings objectForKey:currentModuleName];
        if(!settings) {
            settings = [NSMutableDictionary dictionary];
        } else {
            settings = [settings mutableCopy];
        }
        [settings setDisplayFont:[NSFont fontWithName:fontFamily size:(float)fontSize]];
        [settings setDisplayFontBold:[NSFont fontWithName:fontBoldName size:(float)fontSize]];

        [moduleSettings setObject:settings forKey:currentModuleName];
        [userDefaults setObject:moduleSettings forKey:DefaultsModuleDisplaySettingsKey];
        
        [moduleFontsTableView noteNumberOfRowsChanged];
        [moduleFontsTableView reloadData];
    }
}

- (void)applyFontPreviewText {
    NSString *fontFamily = [userDefaults stringForKey:DefaultsBibleTextDisplayFontFamilyKey];
    int fontSize = [userDefaults integerForKey:DefaultsBibleTextDisplayFontSizeKey];
    NSString *fontText = [NSString stringWithFormat:@"%@ - %i", fontFamily, fontSize];
    bibleDisplayFont = [NSFont fontWithName:fontFamily size:(float)fontSize];
    [bibleFontTextField setStringValue:fontText];
    
    [self applyFontTextFieldPreviewHeight];
}

- (void)applyFontTextFieldPreviewHeight {
    CGFloat newHeight = [bibleDisplayFont pointSize] + ([bibleDisplayFont pointSize] / 1.3);
    CGFloat heightDiff = [bibleFontTextField frame].size.height - newHeight;
    NSRect previewRect = [bibleFontTextField frame];
    previewRect.size.height = newHeight;
    previewRect.origin.y = previewRect.origin.y + heightDiff;
    [bibleFontTextField setFrame:previewRect];
}

//--------------------------------------------------------------------
// NSTabView delegates
//--------------------------------------------------------------------
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	// alter the size of the sheet to display the tab
	NSRect viewframe;
    viewframe.size.height = 0;
    viewframe.size.width = 0;
    
	NSView *prefsView = nil;
	
	// set nil contentview
	//[tabViewItem setView:prefsView];
	
	if([[tabViewItem identifier] isEqualToString:@"general"]) {
		// set view
		viewframe = generalViewRect;
		prefsView = generalView;
	} else if([[tabViewItem identifier] isEqualToString:@"bibledisplay"]) {
		// set view
		viewframe = bibleDisplayViewRect;
		prefsView = bibleDisplayView;
	} else if([[tabViewItem identifier] isEqualToString:@"modulefonts"]) {
		// set view
		viewframe = moduleFontsViewRect;
		prefsView = moduleFontsView;
	} else if([[tabViewItem identifier] isEqualToString:@"printing"]) {
		// set view
		viewframe = printPrefsViewRect;
		prefsView = printPrefsView;
    }
	
	// calculate the difference in size
	//NSRect contentFrame = [[sheet contentView] frame];
	NSRect newFrame = [[self window] frame];
	newFrame.size.height = viewframe.size.height + northMargin + southMargin;
	newFrame.size.width = viewframe.size.width + (2 * sideMargin) + 20;
	
	// set new origin
	newFrame.origin.x = [[self window] frame].origin.x - ((newFrame.size.width - [[self window] frame].size.width) / 2);
	newFrame.origin.y = [[self window] frame].origin.y - (newFrame.size.height - [[self window] frame].size.height);
	
	// set new frame
	[[self window] setFrame:newFrame display:YES animate:YES];
	
	// set frame of box
	//NSRect boxFrame = [prefsViewBox frame];
	[prefsTabView setFrameSize:NSMakeSize((viewframe.size.width + 20),(viewframe.size.height + topTabViewMargin))];
	[prefsTabView setNeedsDisplay:YES];
	
	// set new view
	[tabViewItem setView:prefsView];	
	
	// display complete sheet again
	[[self window] display];
}

//--------------------------------------------------------------------
//----------- sheet stuff --------------------------------------
//--------------------------------------------------------------------
/**
 \brief the sheet return code
*/
- (int)sheetReturnCode {
	return sheetReturnCode;
}

/**
 \brief bring up this sheet. if docWindow is nil this will be an Window
*/
- (void)beginSheetForWindow:(NSWindow *)docWindow {
	[self setSheetWindow:docWindow];
	
	[NSApp beginSheet:[self window]
	   modalForWindow:docWindow
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:nil];
}

/**
 \brief end this sheet
*/
- (void)endSheet {
	[NSApp endSheet:[self window] returnCode:0];
}

// end sheet callback
- (void)sheetDidEnd:(NSWindow *)sSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	// hide sheet
	[sSheet orderOut:nil];
	
	sheetReturnCode = returnCode;
}

//--------------------------------------------------------------------
//----------- Actions ---------------------------------------
//--------------------------------------------------------------------
- (IBAction)toggleBackgroundIndexer:(id)sender {
    if([userDefaults boolForKey:DefaultsBackgroundIndexerEnabled]) {
        [[IndexingManager sharedManager] triggerBackgroundIndexCheck];
    } else {
        [[IndexingManager sharedManager] invalidateBackgroundIndexer];
    }
}

/**
 \brief opens the system fonts panel
 */
- (IBAction)openFontsPanel:(id)sender {
    moduleFontAction = NO;
	NSFontPanel *fp = [NSFontPanel sharedFontPanel];
	[fp setIsVisible:YES];
    
    // set current font to FontManager
    NSFont *font = [NSFont fontWithName:[userDefaults stringForKey:DefaultsBibleTextDisplayFontFamilyKey] 
                                   size:[userDefaults integerForKey:DefaultsBibleTextDisplayFontSizeKey]];
    [fontManager setSelectedFont:font isMultiple:NO];
}

#pragma mark - ModuleFont NSTableView

- (void)moduleFontsTableViewDoubleClick:(id)sender {
    moduleFontAction = YES;
	NSFontPanel *fp = [NSFontPanel sharedFontPanel];
	[fp setIsVisible:YES];
    
    int clickedRow = [moduleFontsTableView clickedRow];
    currentModuleName = [[[SwordManager defaultManager] sortedModuleNames] objectAtIndex:clickedRow];
    
    [fontManager setSelectedFont:[self normalDisplayFontForModuleName:currentModuleName] isMultiple:NO];
}

- (IBAction)resetModuleFont:(id)sender {
    int clickedRow = [moduleFontsTableView clickedRow];
    NSString *moduleName = [[[SwordManager defaultManager] sortedModuleNames] objectAtIndex:clickedRow];
    
    // remove from user defaults. this will apply the default font
    NSMutableDictionary *moduleSettings = [NSMutableDictionary dictionaryWithDictionary:[userDefaults objectForKey:DefaultsModuleDisplaySettingsKey]];
    [moduleSettings removeObjectForKey:moduleName];
    [userDefaults setObject:moduleSettings forKey:DefaultsModuleDisplaySettingsKey];
    
    [moduleFontsTableView noteNumberOfRowsChanged];
    [moduleFontsTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[[SwordManager defaultManager] moduleNames] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if([[aTableColumn identifier] isEqualToString:@"module"]) {
        return [[[SwordManager defaultManager] sortedModuleNames] objectAtIndex:rowIndex];        
    } else if([[aTableColumn identifier] isEqualToString:@"font"]) {
        NSString *moduleName = [[[SwordManager defaultManager] sortedModuleNames] objectAtIndex:rowIndex];
        NSFont *displayFont = [self normalDisplayFontForModuleName:moduleName];
        return [NSString stringWithFormat:@"%@ - %i", [displayFont familyName], (int)[displayFont pointSize]];
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if([[aTableColumn identifier] isEqualToString:@"module"] || 
       [[aTableColumn identifier] isEqualToString:@"font"]) {
        NSString *moduleName = [[[SwordManager defaultManager] sortedModuleNames] objectAtIndex:rowIndex];
        NSFont *displayFont = [self normalDisplayFontForModuleName:moduleName];
        [aCell setFont:displayFont];        
    }     
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    NSString *moduleName = [[[SwordManager defaultManager] sortedModuleNames] objectAtIndex:row];
    
    CGFloat pointSize = [[self normalDisplayFontForModuleName:moduleName] pointSize];
    CGFloat newHeight = pointSize + (pointSize / 1.3);
    return newHeight;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

@end
