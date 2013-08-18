//
//  Guess_The_IntroViewController.h
//  Guess The Intro
//
//  Created by Daniel Kennett on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CocoaLibSpotify.h"
#import "SPPlaybackManager.h"
#import "BLE.h"

@interface Guess_The_IntroViewController : UIViewController <SPSessionDelegate, SPPlaybackManagerDelegate, SPLoginViewControllerDelegate, BLEDelegate> {
	UILabel *currentYearLabel;
	UIActivityIndicatorView *isLoadingView;
	UIButton *track1Button;
	
	SPPlaylist *playlist;
	SPPlaybackManager *playbackManager;
    
	SPTrack *firstSuggestion;
	
	BOOL canPushOne;
    
	NSInteger year;
}

@property (nonatomic, readwrite, strong) SPPlaybackManager *playbackManager;

@property (nonatomic, strong, readwrite) SPTrack *firstSuggestion;

@property (nonatomic, readwrite) BOOL canPushOne;

@property (nonatomic, readwrite) NSInteger year;

@property (nonatomic, strong) IBOutlet UILabel *currentYearLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *isLoadingView;

@property (nonatomic, strong) IBOutlet UIButton *track1Button;

@property (nonatomic, strong) BLE *ble;

// Getting tracks 

-(void)waitAndFillTrackPool;
-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder;
-(NSArray *)tracksFromPlaylistItems:(NSArray *)items;


// Game logic

-(void)startNewYear;

-(void)startPlaybackOfTrack:(SPTrack *)aTrack;

@end
