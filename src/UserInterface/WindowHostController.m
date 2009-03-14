//
//  WindowHostController.m
//  MacSword2
//
//  Created by Manfred Bergmann on 05.11.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "WindowHostController.h"
#import "globals.h"
#import "MBPreferenceController.h"
#import "AppController.h"
#import "SearchTextObject.h"
#import "LeftSideBarViewController.h"
#import "RightSideBarViewController.h"
#import "SwordManager.h"
#import "ScopeBarView.h"
#import "NSImage+Additions.h"
#import "FullScreenSplitView.h"

@implementation WindowHostController

@synthesize delegate;
@dynamic searchType;
@synthesize currentSearchText;

typedef enum _NavigationDirectionType {
    DirectionBackward = 1,
    DirectionForward
}NavigationDirectionType;

#pragma mark - initializers

- (id)init {
    
    self = [super init];
    if(self) {
        hostLoaded = NO;
        navigationAction = NO;
        
        [self setCurrentSearchText:[[SearchTextObject alloc] init]];
        
        // load leftSideBar
        lsbViewController = [[LeftSideBarViewController alloc] initWithDelegate:self];
        [lsbViewController setHostingDelegate:self];
        
        // load rightSideBar
        rsbViewController = [[RightSideBarViewController alloc] initWithDelegate:self];
        [rsbViewController setHostingDelegate:self];        
    }
    
    return self;
}

- (void)awakeFromNib {
    
    // set default widths for sbs
    defaultLSBWidth = 200;
    defaultRSBWidth = 200;
    
    // set main split vertical
    [mainSplitView setVertical:YES];
    [mainSplitView setDividerStyle:NSSplitViewDividerStyleThin];
    [mainSplitView setDelegate:self];

    // set content split vertical
    [contentSplitView setVertical:YES];
    [contentSplitView setDividerStyle:NSSplitViewDividerStyleThin];
    [contentSplitView setDelegate:self];
    
    // init toolbar identifiers
    tbIdentifiers = [[NSMutableDictionary alloc] init];
    
    NSToolbarItem *item = nil;
    NSImage *image = nil;
    
    // ----------------------------------------------------------------------------------------
    // toggle module list view
    /*
    item = [[NSToolbarItem alloc] initWithItemIdentifier:TB_TOGGLE_MODULES_ITEM];
    [item setLabel:NSLocalizedString(@"ToggleModulesLabel", @"")];
    [item setPaletteLabel:NSLocalizedString(@"ToggleModulesLabel", @"")];
    [item setToolTip:NSLocalizedString(@"ToggleModulesToolTip", @"")];
    image = [NSImage imageNamed:@"agt_add-to-autorun.png"];
    [item setImage:image];
    [item setTarget:self];
    [item setAction:@selector(toggleModulesTB:)];
    [tbIdentifiers setObject:item forKey:TB_TOGGLE_MODULES_ITEM];
     */
    
    /*
    if([self moduleType] == bible) {
        // add bibleview
        item = [[NSToolbarItem alloc] initWithItemIdentifier:TB_ADD_BIBLE_ITEM];
        [item setLabel:NSLocalizedString(@"AddBibleLabel", @"")];
        [item setPaletteLabel:NSLocalizedString(@"AddBibleLabel", @"")];
        [item setToolTip:NSLocalizedString(@"AddBibleToolTip", @"")];
        image = [NSImage imageNamed:@"add.png"];
        [item setImage:image];
        [item setTarget:self];
        [item setAction:@selector(addBibleTB:)];
        [tbIdentifiers setObject:item forKey:TB_ADD_BIBLE_ITEM];
    }
     */
    
    /*
     // search type
     searchTypePopup = [[NSPopUpButton alloc] init];
     [searchTypePopup setFrame:NSMakeRect(0,0,140,32)];
     [searchTypePopup setPullsDown:NO];
     //[[searchTypePopup cell] setUsesItemFromMenu:YES];
     // create menu
     NSMenu *searchTypeMenu = [[NSMenu alloc] init];
     NSMenuItem *mItem = [[NSMenuItem alloc] initWithTitle:@"Reference" action:@selector(searchType:) keyEquivalent:@""];
     [mItem setTag:ReferenceSearchType];
     [searchTypeMenu addItem:mItem];
     mItem = [[NSMenuItem alloc] initWithTitle:@"Index" action:@selector(searchType:) keyEquivalent:@""];
     [mItem setTag:IndexSearchType];
     [searchTypeMenu addItem:mItem];
     //    mItem = [[NSMenuItem alloc] initWithTitle:@"View" action:@selector(searchType:) keyEquivalent:@""];
     //    [mItem setTag:ViewSearchType];
     //    [searchTypeMenu addItem:mItem];
     [searchTypePopup setMenu:searchTypeMenu];
     [searchTypePopup selectItemWithTitle:@"Reference"];
     // item toolbaritem
     item = [[NSToolbarItem alloc] initWithItemIdentifier:TB_SEARCH_TYPE_ITEM];
     [item setLabel:NSLocalizedString(@"SearchTypeLabel", @"")];
     [item setPaletteLabel:NSLocalizedString(@"SearchTypePalette", @"")];
     [item setToolTip:NSLocalizedString(@"SearchTypeTooltip", @"")];
     // use popUpButton as view
     [item setView:searchTypePopup];
     [item setMinSize:[searchTypePopup frame].size];
     [item setMaxSize:[searchTypePopup frame].size];
     // add toolbar item to dict
     [tbIdentifiers setObject:item forKey:TB_SEARCH_TYPE_ITEM];
     */
    
    float segmentControlHeight = 32.0;
    float segmentControlWidth = (2*64.0);
    
    // Vavigation Control
    navigationSegControl = [[NSSegmentedControl alloc] init];
    [navigationSegControl setFrame:NSMakeRect(0.0, 0.0, segmentControlWidth, segmentControlHeight)];
    [navigationSegControl setSegmentCount:2];
    // set tracking style
    [[navigationSegControl cell] setTrackingMode:NSSegmentSwitchTrackingMomentary];
    // insert image for segments
    image = [NSImage imageNamed:NSImageNameGoLeftTemplate];
    [navigationSegControl setImage:image forSegment:0];
    [[navigationSegControl cell] setTag:DirectionBackward forSegment:0];
    image = [NSImage imageNamed:NSImageNameGoRightTemplate];
    [navigationSegControl setImage:image forSegment:1];
    [[navigationSegControl cell] setTag:DirectionForward forSegment:1];
    [navigationSegControl sizeToFit];
    [navigationSegControl setAction:@selector(navigationAction:)];
    [navigationSegControl setTarget:self];
    // resize the height to what we have defined
    [navigationSegControl setFrameSize:NSMakeSize([navigationSegControl frame].size.width, segmentControlHeight)];
    if([self moduleType] != bible && [self moduleType] != commentary) {
        [[navigationSegControl cell] setEnabled:NO forSegment:0];
        [[navigationSegControl cell] setEnabled:NO forSegment:1];        
    }
    // the Toolbar itemitem
    item = [[NSToolbarItem alloc] initWithItemIdentifier:TB_NAVIGATION_TYPE_ITEM];
    [item setLabel:NSLocalizedString(@"NavigationItemLabel", @"")];
    [item setPaletteLabel:NSLocalizedString(@"NavigationItemPalette", @"")];
    [item setToolTip:NSLocalizedString(@"NavigationItemTooltip", @"")];
    [item setMinSize:[navigationSegControl frame].size];
    [item setMaxSize:[navigationSegControl frame].size];
    // set the segmented control as the view of the toolbar item
    [item setView:navigationSegControl];
    [tbIdentifiers setObject:item forKey:TB_NAVIGATION_TYPE_ITEM];
    
    // Search Control
    searchTypeSegControl = [[NSSegmentedControl alloc] init];
    [searchTypeSegControl setFrame:NSMakeRect(0.0, 0.0, segmentControlWidth, segmentControlHeight)];
    [searchTypeSegControl setSegmentCount:2];
    // style
    [[searchTypeSegControl cell] setSegmentStyle:NSSegmentStyleTexturedRounded];
    // set tracking style
    [[searchTypeSegControl cell] setTrackingMode:NSSegmentSwitchTrackingSelectOne];
    // insert text only segments
    [searchTypeSegControl setFont:FontStdBold];
    //[searchTypeSegControl setLabel:NSLocalizedString(@"Reference", @"") forSegment:0];
    [searchTypeSegControl setImage:[NSImage imageNamed:NSImageNameListViewTemplate] forSegment:0];		
    //[searchTypeSegControl setLabel:NSLocalizedString(@"Index", "") forSegment:1];
    [searchTypeSegControl setImage:[NSImage imageNamed:NSImageNameRevealFreestandingTemplate] forSegment:1];
    [[searchTypeSegControl cell] setTag:ReferenceSearchType forSegment:0];
    [[searchTypeSegControl cell] setTag:IndexSearchType forSegment:1];
    if([self moduleType] == genbook) {
        [[searchTypeSegControl cell] setEnabled:NO forSegment:0];
        [[searchTypeSegControl cell] setEnabled:YES forSegment:1];
        [[searchTypeSegControl cell] setSelected:NO forSegment:0];
        [[searchTypeSegControl cell] setSelected:YES forSegment:1];        
    } else {        
        [[searchTypeSegControl cell] setEnabled:YES forSegment:0];
        [[searchTypeSegControl cell] setEnabled:YES forSegment:1];
        [[searchTypeSegControl cell] setSelected:YES forSegment:0];
        [[searchTypeSegControl cell] setSelected:NO forSegment:1];
    }
    [searchTypeSegControl sizeToFit];
    // resize the height to what we have defined
    [searchTypeSegControl setFrameSize:NSMakeSize([searchTypeSegControl frame].size.width,segmentControlHeight)];
    [searchTypeSegControl setTarget:self];
    [searchTypeSegControl setAction:@selector(searchType:)];
    // the Toolbar item
    item = [[NSToolbarItem alloc] initWithItemIdentifier:TB_SEARCH_TYPE_ITEM];
    [item setLabel:NSLocalizedString(@"SearchTypeLabel", @"")];
    [item setPaletteLabel:NSLocalizedString(@"SearchTypePalette", @"")];
    [item setToolTip:NSLocalizedString(@"SearchTypeTooltip", @"")];
    [item setMinSize:[searchTypeSegControl frame].size];
    [item setMaxSize:[searchTypeSegControl frame].size];
    // set the segmented control as the view of the toolbar item
    [item setView:searchTypeSegControl];
    [tbIdentifiers setObject:item forKey:TB_SEARCH_TYPE_ITEM];
    
    // search text
    searchTextField = [[NSSearchField alloc] initWithFrame:NSMakeRect(0,0,350,32)];
    [searchTextField sizeToFit];
    [searchTextField setTarget:self];
    [searchTextField setAction:@selector(searchInput:)];
    if([self moduleType] == dictionary) {
        [searchTextField setContinuous:YES];
        [[searchTextField cell] setSendsSearchStringImmediately:YES];
        //[[searchTextField cell] setSendsWholeSearchString:NO];
    } else {
        [searchTextField setContinuous:NO];
        [[searchTextField cell] setSendsSearchStringImmediately:NO];
        [[searchTextField cell] setSendsWholeSearchString:YES];        
    }
    // the item itself
    item = [[NSToolbarItem alloc] initWithItemIdentifier:TB_SEARCH_TEXT_ITEM];
    [item setLabel:NSLocalizedString(@"TextSearchLabel", @"")];
    [item setPaletteLabel:NSLocalizedString(@"TextSearchLabel", @"")];
    [item setToolTip:NSLocalizedString(@"TextSearchTooltip", @"")];
    [item setView:searchTextField];
    [item setMinSize:NSMakeSize(100, NSHeight([searchTextField frame]))];
    [item setMaxSize:NSMakeSize(350, NSHeight([searchTextField frame]))];
    [tbIdentifiers setObject:item forKey:TB_SEARCH_TEXT_ITEM];
    
    // add button
    segmentControlHeight = 32.0;
    segmentControlWidth = 64.0;
    NSSegmentedControl *addBookmarkSegControl = [[NSSegmentedControl alloc] init];
    [addBookmarkSegControl setFrame:NSMakeRect(0.0, 0.0, segmentControlWidth, segmentControlHeight)];
    [addBookmarkSegControl setSegmentCount:1];
    // style
    [[addBookmarkSegControl cell] setSegmentStyle:NSSegmentStyleTexturedRounded];
    // set tracking style
    [[addBookmarkSegControl cell] setTrackingMode:NSSegmentSwitchTrackingMomentary];
    // insert text only segments
    [addBookmarkSegControl setFont:FontStdBold];
    [addBookmarkSegControl setImage:[NSImage imageNamed:NSImageNameAddTemplate] forSegment:0];		
    [addBookmarkSegControl sizeToFit];
    // resize the height to what we have defined
    [addBookmarkSegControl setFrameSize:NSMakeSize([addBookmarkSegControl frame].size.width, segmentControlHeight)];
    [addBookmarkSegControl setTarget:lsbViewController];
    [addBookmarkSegControl setAction:@selector(bookmarkDialog:)];    
    // add bookmark item
    item = [[NSToolbarItem alloc] initWithItemIdentifier:TB_ADDBOOKMARK_TYPE_ITEM];
    [item setLabel:NSLocalizedString(@"AddBookmarkLabel", @"")];
    [item setPaletteLabel:NSLocalizedString(@"AddBookmarkPalette", @"")];
    [item setToolTip:NSLocalizedString(@"AddBookmarkTooltip", @"")];
    [item setMinSize:[addBookmarkSegControl frame].size];
    [item setMaxSize:[addBookmarkSegControl frame].size];
    // set the segmented control as the view of the toolbar item
    [item setView:addBookmarkSegControl];
    [addBookmarkSegControl release];
    [tbIdentifiers setObject:item forKey:TB_ADDBOOKMARK_TYPE_ITEM];
    
    // module installer item
    item = [[NSToolbarItem alloc] initWithItemIdentifier:TB_MODULEINSTALLER_ITEM];
    [item setLabel:NSLocalizedString(@"ModuleInstallerLabel", @"")];
    [item setPaletteLabel:NSLocalizedString(@"ModuleInstallerLabel", @"")];
    [item setToolTip:NSLocalizedString(@"ModuleInstallerTooltip", @"")];
    image = [NSImage imageNamed:@"ModuleManager.png"];
    [item setImage:image];
    [item setTarget:[AppController defaultAppController]];
    [item setAction:@selector(showModuleManager:)];
    [tbIdentifiers setObject:item forKey:TB_MODULEINSTALLER_ITEM];
    
    // add std items
    [tbIdentifiers setObject:[NSNull null] forKey:NSToolbarFlexibleSpaceItemIdentifier];
    [tbIdentifiers setObject:[NSNull null] forKey:NSToolbarSpaceItemIdentifier];
    [tbIdentifiers setObject:[NSNull null] forKey:NSToolbarSeparatorItemIdentifier];
    [tbIdentifiers setObject:[NSNull null] forKey:NSToolbarPrintItemIdentifier];
    
    [self setupToolbar];
    
    // activate mouse movement in subviews
    [[self window] setAcceptsMouseMovedEvents:YES];
    // set window status bar
	[self.window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	[self.window setContentBorderThickness:35.0f forEdge:NSMinYEdge];
    
    // set up left and right side bar
    if([lsbViewController viewLoaded]) {
        [mainSplitView addSubview:[lsbViewController view] positioned:NSWindowBelow relativeTo:nil];
        NSSize s = [[lsbViewController view] frame].size;
        s.width = lsbWidth;
        [[lsbViewController view] setFrameSize:s];
    }
    /*
    if([rsbViewController viewLoaded]) {
        [contentSplitView addSubview:[rsbViewController view] positioned:NSWindowAbove relativeTo:nil];
        NSSize s = [[rsbViewController view] frame].size;
        s.width = rsbWidth;
        [[rsbViewController view] setFrameSize:s];
    }
     */
    
    
    // lets show the images in sidebar seg control
    [self showingLSB];
    [self showingRSB];
    [leftSideBottomSegControl sizeToFit];
    [rightSideBottomSegControl sizeToFit];
}

- (void)setSearchType:(SearchType)aType {
    [currentSearchText setSearchType:aType];
}

- (SearchType)searchType; {
    return [currentSearchText searchType];
}

#pragma mark - toolbar stuff

// ============================================================
// NSToolbar Related Methods
// ============================================================
/**
 \brief create a toolbar and add it to the window. Set the delegate to this object.
 */
- (void)setupToolbar {
    
    MBLOG(MBLOG_DEBUG, @"[SingleViewHostController -setupToolbar]");
    
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: @"SingleViewHostToolbar"];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
	//[toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    
    // We are the delegate
    [toolbar setDelegate:self];
    
    /*
    SInt32 MacVersion;
    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
        if (MacVersion >= 0x1040) {
            // this call is Tiger only
            [toolbar setShowsBaselineSeparator:NO];
        }
    }
     */

    // Attach the toolbar to the document window 
    [[self window] setToolbar:toolbar];
}

/**
 \brief returns array with allowed toolbar item identifiers
 */
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar  {
	return [tbIdentifiers allKeys];
}

/**
 \brief returns array with all default toolbar item identifiers
 */
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar  {
	NSArray *defaultItemArray = [NSArray arrayWithObjects:
                                 TB_NAVIGATION_TYPE_ITEM,
                                 NSToolbarFlexibleSpaceItemIdentifier,
                                 TB_SEARCH_TYPE_ITEM,
                                 TB_SEARCH_TEXT_ITEM,
                                 NSToolbarFlexibleSpaceItemIdentifier,
                                 TB_MODULEINSTALLER_ITEM,
                                 nil];
	
	return defaultItemArray;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = nil;
    
	item = [tbIdentifiers valueForKey:itemIdentifier];
	
    return item;
}

#pragma mark - toolbar actions

- (void)addBibleTB:(id)sender {
}

- (void)toggleModulesTB:(id)sender {
    if(![self showingLSB]) {
        [self showLeftSideBar:YES];
        [userDefaults setBool:YES forKey:DefaultsShowLSB];
    } else {
        [self showLeftSideBar:NO];
        [userDefaults setBool:NO forKey:DefaultsShowLSB];
    }
}

- (void)searchInput:(id)sender {
    // buffer search text string
    SearchType type = [currentSearchText searchType];
    NSString *searchText = [sender stringValue];
    [currentSearchText setSearchText:searchText forSearchType:type];
    
    if(!navigationAction) {
        // add to recent searches
        NSMutableArray *recentSearches = [currentSearchText recentSearchsForType:type];
        [recentSearches addObject:searchText];
        // remove everything above 10 searches
        int len = [recentSearches count];
        if(len > 10) {
            [recentSearches removeObjectAtIndex:0];
        }        
    }
    
    // unset
    navigationAction = NO;
}

- (void)searchType:(id)sender {

    SearchType type;
    if([(NSSegmentedControl *)sender selectedSegment] == 0) {
        type = ReferenceSearchType;
    } else {
        type = IndexSearchType;
    }
    [self setSearchUIType:type searchString:nil];
}

#pragma mark - Actions

- (IBAction)leftSideBarHideShow:(id)sender {
    [self toggleLSB];
}

- (IBAction)rightSideBarHideShow:(id)sender {
    [self toggleRSB];
}

- (IBAction)leftSideBottomSegChange:(id)sender {
    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
    if(clickedSegmentTag == 0) {
        [self toggleLSB];
    }
}

- (IBAction)rightSideBottomSegChange:(id)sender {
    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
    if(clickedSegmentTag == 0) {
        [self toggleRSB];
    }    
}

- (IBAction)switchToRefLookup:(id)sender {
    [self setSearchUIType:ReferenceSearchType searchString:nil];
}

- (IBAction)switchToIndexLookup:(id)sender {
    [self setSearchUIType:IndexSearchType searchString:nil];
}

- (IBAction)navigationAction:(id)sender {
    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
    
    if(clickedSegmentTag == DirectionBackward) {
        [self navigationBack:nil];
    } else {
        [self navigationForward:nil];
    }
}


- (IBAction)navigationBack:(id)sender {
    // get recent searches
    NSArray *rs = [currentSearchText recentSearchsForType:[currentSearchText searchType]];
    NSString *sstr = nil;
    if([rs count] > 0) {
        // find the index of the currect search text
        int index = [rs indexOfObject:[currentSearchText searchTextForType:[currentSearchText searchType]]];
        if(index > 0) {
            // get the last
            sstr = [rs objectAtIndex:index - 1];                
        }
    }

    if(sstr) {
        // this is a navigation action
        navigationAction = YES;
        [self setSearchText:sstr];
    }
}

- (IBAction)navigationForward:(id)sender {
    // get recent searches
    NSArray *rs = [currentSearchText recentSearchsForType:[currentSearchText searchType]];
    NSString *sstr = nil;
    if([rs count] > 0) {
        // find the index of the currect search text
        int index = [rs indexOfObject:[currentSearchText searchTextForType:[currentSearchText searchType]]];
        if(index < [rs count] - 1) {
            // get next
            sstr = [rs objectAtIndex:index + 1];
        }
    }
    
    if(sstr) {
        // this is a navigation action
        navigationAction = YES;
        [self setSearchText:sstr];
    }    
}

#pragma mark - Events

- (void)keyDown:(NSEvent *)theEvent {
    // Escape key?
    if([theEvent keyCode] == '\033') {
        // are we in full screen mode?
        if([mainSplitView isFullScreenMode]) {
            [mainSplitView setFullScreenMode:NO];
        }        
    }
}

#pragma mark - Methods

- (NSView *)view {
    return view;
}

- (void)setView:(NSView *)aView {
    view = aView;
}

- (BOOL)showingLSB {
    BOOL ret = YES;
    if([[lsbViewController view] frame].size.width == 0) {
        ret = NO;
        // show image play to right
        [leftSideBottomSegControl setImage:[NSImage imageNamed:NSImageNameSlideshowTemplate] forSegment:0];
    } else {
        // show image play to left
        [leftSideBottomSegControl setImage:[(NSImage *)[NSImage imageNamed:NSImageNameSlideshowTemplate] mirrorVertically] forSegment:0];
    }
    
    return ret;
}

- (BOOL)showingRSB {
    BOOL ret = NO;
    if([[contentSplitView subviews] containsObject:[rsbViewController view]]) {
        ret = YES;
        // show image play to left
        [rightSideBottomSegControl setImage:[(NSImage *)[NSImage imageNamed:NSImageNameSlideshowTemplate] mirrorVertically] forSegment:0];    
    } else {
        // show image play to right
        [rightSideBottomSegControl setImage:[NSImage imageNamed:NSImageNameSlideshowTemplate] forSegment:0];
    }
    
    return ret;
}

- (void)toggleLSB {
    BOOL show = ![self showingLSB];
    [self showLeftSideBar:show];
    
    // store in user defaults
    [userDefaults setBool:show forKey:DefaultsShowLSB];
}

- (void)toggleRSB {
    BOOL show = ![self showingRSB];
    [self showRightSideBar:show];

    // store in user defaults
    [userDefaults setBool:show forKey:DefaultsShowRSB];
}

- (void)showLeftSideBar:(BOOL)flag {
    if(flag) {
        // if size is 0 set to default size
        if(lsbWidth == 0) {
            lsbWidth = defaultLSBWidth;
        }        
        // change size of view
        NSView *v = [lsbViewController view];
        NSSize size = [v frame].size;
        size.width = lsbWidth;
        [[v animator] setFrameSize:size];
        // show image play to left
        [leftSideBottomSegControl setImage:[(NSImage *)[NSImage imageNamed:NSImageNameSlideshowTemplate] mirrorVertically] forSegment:0];
    } else {
        // shrink the view
        NSView *v = [lsbViewController view];
        NSSize size = [v frame].size;
        if(size.width > 0) {
            lsbWidth = size.width;
        }
        size.width = 0;
        [[v animator] setFrameSize:size];
        // show image play to right
        [leftSideBottomSegControl setImage:[NSImage imageNamed:NSImageNameSlideshowTemplate] forSegment:0];
    }
    
    // we need to redisplay
    [mainSplitView setNeedsDisplay:YES];
}

- (void)showRightSideBar:(BOOL)flag {
    if(flag) {
        // if size is 0 set to default size
        if(rsbWidth == 0) {
            rsbWidth = defaultRSBWidth;
        }
        // change size of view
        NSView *v = [rsbViewController view];
        NSSize size = [v frame].size;
        size.width = rsbWidth;
        // add
        [contentSplitView addSubview:v positioned:NSWindowAbove relativeTo:nil];
        // change size
        [[v animator] setFrameSize:size];
        // show image play to right
        [rightSideBottomSegControl setImage:[NSImage imageNamed:NSImageNameSlideshowTemplate] forSegment:0];
    } else {
        // shrink the view
        NSView *v = [rsbViewController view];
        NSSize size = [v frame].size;
        if(size.width > 0) {
            rsbWidth = size.width;
        }
        /*
        size.width = 0;
        [[v animator] setFrameSize:size];
         */
        
        // remove
        [[v animator] removeFromSuperview];
        // show image play to left
        [rightSideBottomSegControl setImage:[(NSImage *)[NSImage imageNamed:NSImageNameSlideshowTemplate] mirrorVertically] forSegment:0];
    }
    
    // we need to redisplay
    [contentSplitView setNeedsDisplay:YES];
    [contentSplitView adjustSubviews];
}

/** used to set text to the search field from outside */
- (void)setSearchText:(NSString *)aString {
    [searchTextField setStringValue:aString];
    [self searchInput:searchTextField];
}

/** sets the type of search to UI */
- (void)setSearchUIType:(SearchType)aType searchString:(NSString *)aString {
    
    SearchType oldType = [currentSearchText searchType];
    [currentSearchText setSearchType:aType];
    
    // set UI
    [searchTypeSegControl selectSegmentWithTag:aType];
    
    NSString *text = @"";
    // if the new search type is the same, we don't need to set anything
    if(aType != oldType) {
        text = [currentSearchText searchTextForType:aType];    
    }
    // if aString is not nil, the search text can be overriden here
    if(aString != nil) {
        text = aString;
    }
    // display last search result
    [self setSearchText:text];
    
    // switch recentSearches
    NSArray *recentSearches = [currentSearchText recentSearchsForType:aType];
    [searchTextField setRecentSearches:recentSearches];
    
    // change searchfield behaviour for dictionary
    if([self moduleType] == dictionary || [self moduleType] == genbook) {
        if(aType == ReferenceSearchType) {
            [searchTextField setContinuous:YES];
            [[searchTextField cell] setSendsSearchStringImmediately:YES];
            //[[searchTextField cell] setSendsWholeSearchString:NO];            
        } else {
            // <CR> required
            [searchTextField setContinuous:NO];
            [[searchTextField cell] setSendsSearchStringImmediately:NO];
            [[searchTextField cell] setSendsWholeSearchString:YES];            
        }
    }            
}

- (void)adaptUIToCurrentlyDisplayingModuleType {
    
    ModuleType type = [self moduleType];
    if(type == dictionary) {
        [searchTextField setContinuous:YES];
        [[searchTextField cell] setSendsSearchStringImmediately:YES];
        //[[searchTextField cell] setSendsWholeSearchString:NO];        
    } else {
        [searchTextField setContinuous:NO];
        [[searchTextField cell] setSendsSearchStringImmediately:NO];
        [[searchTextField cell] setSendsWholeSearchString:YES];        
    }
    
    // set search type
    SearchType stype = [currentSearchText searchType];
    // set text according search type
    NSString *buf = [currentSearchText searchTextForType:stype];
    [searchTextField setStringValue:buf];
    // switch recentSearches
    NSArray *bufAr = [currentSearchText recentSearchsForType:stype];
    [searchTextField setRecentSearches:bufAr];

    if(type == genbook) {
        [currentSearchText setSearchType:IndexSearchType];
        [[searchTypeSegControl cell] setEnabled:NO forSegment:0];
        [[searchTypeSegControl cell] setEnabled:YES forSegment:1];
        [[searchTypeSegControl cell] setSelected:NO forSegment:0];
        [[searchTypeSegControl cell] setSelected:YES forSegment:1];        
    } else {        
        [[searchTypeSegControl cell] setEnabled:YES forSegment:0];
        [[searchTypeSegControl cell] setEnabled:YES forSegment:1];
        switch(stype) {
            case ReferenceSearchType:
                [[searchTypeSegControl cell] setSelected:YES forSegment:0];
                [[searchTypeSegControl cell] setSelected:NO forSegment:1];
                break;
            case IndexSearchType:
                [[searchTypeSegControl cell] setSelected:NO forSegment:0];
                [[searchTypeSegControl cell] setSelected:YES forSegment:1];
                break;
            case ViewSearchType:
                // not used but make compiler happy
                break;
        }
    }
    
    // navigation
    if([self moduleType] == bible || [self moduleType] == commentary) {
        [[navigationSegControl cell] setEnabled:YES forSegment:0];
        [[navigationSegControl cell] setEnabled:YES forSegment:1];    
    } else {
        [[navigationSegControl cell] setEnabled:NO forSegment:0];
        [[navigationSegControl cell] setEnabled:NO forSegment:1];        
    }    
}

#pragma mark - NSSplitView delegate methods

/*
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
    MBLOGV(MBLOG_DEBUG, @"[WindowHostController -splitView:resizeSubviewsWithOldSize:] width:%f, height:%i", oldSize.width, oldSize.height);
}
*/
 
- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
    return ((subview == [lsbViewController view]) || (subview == [rsbViewController view]));
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
    return proposedMin + 60.0;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
    return proposedMax - 90.0;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    NSSplitView *sv = [aNotification object];
    if(sv == mainSplitView) {
        /*
        NSSize s = [[lsbViewController view] frame].size;
        if(s.width > 10) {
            lsbWidth = (int)s.width;
        }
         */
    } else if(sv == contentSplitView) {
        /*
        NSSize s = [[rsbViewController view] frame].size;
        if(s.width > 10) {
            rsbWidth = (int)s.width;
        }
         */
    }
}

#pragma mark - NSWindow delegate methods

- (void)windowDidBecomeKey:(NSNotification *)notification {
    /*
    [scopeBarView setWindowActive:YES];
    [scopeBarView setNeedsDisplay:YES];
     */
}

- (void)windowDidResignMain:(NSNotification *)notification {
    /*
    [scopeBarView setWindowActive:NO];
    [scopeBarView setNeedsDisplay:YES];
     */
}

- (void)windowWillClose:(NSNotification *)notification {
    MBLOG(MBLOG_DEBUG, @"[WindowHostController -windowWillClose:]");
    // tell delegate that we are closing
    if(delegate && [delegate respondsToSelector:@selector(hostClosing:)]) {
        [delegate performSelector:@selector(hostClosing:) withObject:self];
    } else {
        MBLOG(MBLOG_WARN, @"[WindowHostController -windowWillClose:] delegate does not respond to selector!");
    }
}

#pragma mark - WindowHosting protocol

/** abstract method */
- (ModuleType)moduleType {
    return bible;   // default is bible
}

#pragma mark - FullScreenCapability protocol

- (BOOL)isFullScreenMode {
    return [mainSplitView isInFullScreenMode];
}

- (void)setFullScreenMode:(BOOL)flag {
    [mainSplitView setFullScreenMode:flag];
}

- (IBAction)fullScreenModeOnOff:(id)sender {
    [mainSplitView fullScreenModeOnOff:sender];
}

#pragma mark - SubviewHosting protocol

- (void)contentViewInitFinished:(HostableViewController *)aView {
    MBLOG(MBLOG_DEBUG, @"[WindowHostController -contentViewInitFinished:]");

    if([aView isKindOfClass:[LeftSideBarViewController class]]) {
        [mainSplitView addSubview:[aView view] positioned:NSWindowBelow relativeTo:placeHolderView];
        NSSize s = [[lsbViewController view] frame].size;
        s.width = lsbWidth;
        [[lsbViewController view] setFrameSize:s];
    } else if([aView isKindOfClass:[RightSideBarViewController class]]) {
        /*
        [contentSplitView addSubview:[aView view] positioned:NSWindowAbove relativeTo:nil];
         */
        NSSize s = [[rsbViewController view] frame].size;
        s.width = rsbWidth;
        [[rsbViewController view] setFrameSize:s];
    }
}

- (void)removeSubview:(HostableViewController *)aViewController {
    [[aViewController view] removeFromSuperview];
}

#pragma mark - NSCoding protocol

- (id)initWithCoder:(NSCoder *)decoder {
    
    // load lsb view
    lsbWidth = [decoder decodeIntForKey:@"LSBWidth"];
    if(lsbViewController == nil) {
        lsbViewController = [[LeftSideBarViewController alloc] initWithDelegate:self];
        [lsbViewController setHostingDelegate:self];    
    }
    // load rsb view
    rsbWidth = [decoder decodeIntForKey:@"RSBWidth"];
    if(rsbViewController == nil) {
        rsbViewController = [[RightSideBarViewController alloc] initWithDelegate:self];
        [rsbViewController setHostingDelegate:self];    
    }
    
    // set window frame
    NSRect frame;
    frame.origin = [decoder decodePointForKey:@"WindowOriginEncoded"];
    frame.size = [decoder decodeSizeForKey:@"WindowSizeEncoded"];
    if(frame.size.width > 0 && frame.size.height > 0) {
        [[self window] setFrame:frame display:YES];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    // encode LSB and RSB width
    int w = lsbWidth;
    if([self showingLSB]) {
        w = [[lsbViewController view] frame].size.width;
    }
    [encoder encodeInt:w forKey:@"LSBWidth"];
    w = rsbWidth;
    if([self showingRSB]) {
        w = [[rsbViewController view] frame].size.width;
    }
    [encoder encodeInt:w forKey:@"RSBWidth"];
    
    // encode searchQuery
    [encoder encodeObject:currentSearchText forKey:@"SearchTextObject"];
    // encode window frame
    [encoder encodePoint:[[self window] frame].origin forKey:@"WindowOriginEncoded"];
    [encoder encodeSize:[[self window] frame].size forKey:@"WindowSizeEncoded"];
}

@end
