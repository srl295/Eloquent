//
//  BibleCombiViewController.h
//  MacSword2
//
//  Created by Manfred Bergmann on 15.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoLogger/CocoLogger.h>
#import <CocoPCRE/CocoPCRE.h>
#import <HostableViewController.h>
#import <ModuleViewController.h>
#import <ProtocolHelper.h>
#import <Indexer.h>

#define BIBLECOMBIVIEW_NIBNAME   @"BibleCombiView"

@class SwordModule, SwordBible, SwordCommentary, ScrollSynchronizableView;

@interface BibleCombiViewController : HostableViewController <NSCoding, TextDisplayable, SubviewHosting, MouseTracking> {
    // the lookup field
    IBOutlet NSTextField *lookupTF;
    IBOutlet NSButton *okBtn;
    
    IBOutlet NSSplitView *horiSplitView;
    IBOutlet NSSplitView *parBibleSplitView;
    IBOutlet NSSplitView *parMiscSplitView;
    
    /** options */
    IBOutlet NSMenu *displayOptionsMenu;
    IBOutlet NSMenu *modDisplayOptionsMenu;
    IBOutlet NSView *referenceOptionsView;
    NSMutableDictionary *modDisplayOptions;
    NSMutableDictionary *displayOptions;
    
    NSMutableArray *parBibleViewControllers;
    NSMutableArray *parMiscViewControllers;
    
    // default width parMiscSplitView
    float defaultMiscViewHeight;
    
    // the current right ScrollSynchronizableView
    ScrollSynchronizableView *currentSyncView;
    
    // the regex that will find out the versekey
    MBRegex *regex;
    
    // search type
    SearchType searchType;
    // search text
    NSString *reference;
    
    // force redisplay
    BOOL forceRedisplay;
}

@property (retain, readwrite) NSString *reference;
@property (readwrite) BOOL forceRedisplay;

// initializers
- (id)initWithDelegate:(id)aDelegate;
- (id)initWithDelegate:(id)aDelegate andInitialModule:(SwordBible *)aBible;

// the index view of combibible
- (NSView *)listContentView;

// methods
- (void)addNewBibleViewWithModule:(SwordBible *)aModule;
- (void)addNewCommentViewWithModule:(SwordCommentary *)aModule;
- (NSView *)referenceOptionsView;

// actions
- (IBAction)displayOptionShowStrongs:(id)sender;
- (IBAction)displayOptionShowMorphs:(id)sender;
- (IBAction)displayOptionShowFootnotes:(id)sender;
- (IBAction)displayOptionShowCrossRefs:(id)sender;
- (IBAction)displayOptionShowRedLetterWords:(id)sender;
- (IBAction)displayOptionVersesOnOneLine:(id)sender;

// method called by subview
- (void)contentViewInitFinished:(HostableViewController *)aViewController;
- (void)removeSubview:(HostableViewController *)aViewController;
- (NSNumber *)bibleViewCount;

// protocol
- (void)displayTextForReference:(NSString *)aReference;
- (void)displayTextForReference:(NSString *)aReference searchType:(SearchType)aType;

// Mouse tracking protocol implementation
- (void)mouseEntered:(NSView *)theView;
- (void)mouseExited:(NSView *)theView;

// NSCoding
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end
