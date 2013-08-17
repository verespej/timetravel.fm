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

@interface Guess_The_IntroViewController : UIViewController <SPSessionDelegate, SPPlaybackManagerDelegate, SPLoginViewControllerDelegate> {
	UILabel *currentYearLabel;
	UIActivityIndicatorView *isLoadingView;
	UIButton *track1Button;

	NSUInteger loginAttempts;
	NSNumberFormatter *formatter;
	
	SPPlaylist *playlist;
	SPPlaybackManager *playbackManager;
	
	SPToplist *regionTopList;
	SPToplist *userTopList;
	
	NSMutableArray *trackPool;
	SPTrack *firstSuggestion;
	
	BOOL canPushOne;
    
	NSUInteger year; // The current score
}

@property (nonatomic, readwrite, strong) SPPlaybackManager *playbackManager;

@property (nonatomic, readwrite, strong) SPPlaylist	*playlist;

@property (nonatomic, strong, readwrite) SPToplist *regionTopList;
@property (nonatomic, strong, readwrite) SPToplist *userTopList;

@property (nonatomic, strong, readwrite) SPTrack *firstSuggestion;

@property (nonatomic, readwrite) BOOL canPushOne;

@property (nonatomic, readwrite) NSUInteger year;
@property (nonatomic, readwrite, strong) NSMutableArray *trackPool;

@property (nonatomic, strong) IBOutlet UILabel *currentYearLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *isLoadingView;

@property (nonatomic, strong) IBOutlet UIButton *track1Button;

- (IBAction)guessOne:(id)sender;

// Getting tracks 

-(void)waitAndFillTrackPool;
-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder;
-(NSArray *)tracksFromPlaylistItems:(NSArray *)items;


// Game logic

-(void)startNewYear;

-(void)startPlaybackOfTrack:(SPTrack *)aTrack;

@end
