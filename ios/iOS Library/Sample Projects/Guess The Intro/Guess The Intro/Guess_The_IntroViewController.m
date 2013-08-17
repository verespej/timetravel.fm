//
//  Guess_The_IntroViewController.m
//  Guess The Intro
//
//  Created by Daniel Kennett on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Guess_The_IntroViewController.h"
#import "SPArrayExtensions.h"
#import <QuartzCore/QuartzCore.h>

static NSUInteger const kLoadingTimeout = 10;
static NSTimeInterval const kRoundDuration = 20.0;
static NSTimeInterval const kGameDuration = 60 * 5; // 5 mins
static NSTimeInterval const kGameCountdownThreshold = 30.0;

@interface Guess_The_IntroViewController ()
-(NSString *)stringFromScore:(NSInteger)aScore;
@property (weak, nonatomic) IBOutlet UILabel *prevYearLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextYearLabel;
@end

@implementation Guess_The_IntroViewController

@synthesize currentYearLabel;
@synthesize isLoadingView;
@synthesize track1Button;

@synthesize playbackManager;
@synthesize playlist;

@synthesize firstSuggestion;
@synthesize canPushOne;

@synthesize userTopList;
@synthesize regionTopList;

@synthesize year;
@synthesize trackPool;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(NSString *)stringFromScore:(NSInteger)aScore {
	return [formatter stringFromNumber:[NSNumber numberWithInteger:aScore]];
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.track1Button.layer.borderColor = [UIColor darkGrayColor].CGColor;
	self.track1Button.layer.borderWidth = 1.0;
		
	formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
			
	[self addObserver:self forKeyPath:@"firstSuggestion.name" options:NSKeyValueObservingOptionInitial context:nil];
	[self addObserver:self forKeyPath:@"firstSuggestion.artists" options:NSKeyValueObservingOptionInitial context:nil];
	[self addObserver:self forKeyPath:@"firstSuggestion.album.cover.image" options:NSKeyValueObservingOptionInitial context:nil];
	
	[self addObserver:self forKeyPath:@"canPushOne" options:NSKeyValueObservingOptionInitial context:nil];
	
	[self addObserver:self forKeyPath:@"year" options:NSKeyValueObservingOptionInitial context:nil];
    
    UITapGestureRecognizer* gesturePrev = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(movePrevYear:)];
    [[self nextYearLabel] setUserInteractionEnabled:YES];
    [[self nextYearLabel] addGestureRecognizer:gesturePrev];
    
    UITapGestureRecognizer* gestureNext = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveNextYear:)];
    [[self nextYearLabel] setUserInteractionEnabled:YES];
    [[self nextYearLabel] addGestureRecognizer:gestureNext];
}

- (void)viewDidUnload
{
    [self setCurrentYearLabel:nil];
    [self setTrack1Button:nil];
	[self setIsLoadingView:nil];
	
	[self removeObserver:self forKeyPath:@"firstSuggestion.name"];
	[self removeObserver:self forKeyPath:@"firstSuggestion.artists"];
	[self removeObserver:self forKeyPath:@"firstSuggestion.album.cover.image"];
		
	[self removeObserver:self forKeyPath:@"canPushOne"];
	
	[self removeObserver:self forKeyPath:@"year"];
	
	formatter = nil;

    [self setNextYearLabel:nil];
    [self setPrevYearLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath hasPrefix:@"firstSuggestion"]) {
		[self.track1Button setImage:self.firstSuggestion.album.cover.image 
						   forState:UIControlStateNormal];
	} else if ([keyPath hasPrefix:@"canPush"]) {
		self.track1Button.enabled = self.canPushOne;
    } else if ([keyPath isEqualToString:@"year"]) {
        NSLog(@"Year: %@", keyPath);
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark SPLoginViewController Delegate

-(void)loginViewController:(SPLoginViewController *)controller didCompleteSuccessfully:(BOOL)didLogin {
	
	[self dismissModalViewControllerAnimated:YES];

	self.isLoadingView.hidden = YES;//!self.roundProgressIndicator.hidden;
	
	self.regionTopList = [SPToplist toplistForLocale:[SPSession sharedSession].locale
										   inSession:[SPSession sharedSession]];
	self.userTopList = [SPToplist toplistForCurrentUserInSession:[SPSession sharedSession]];
	
	//if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CreatePlaylist"])
	//	self.playlist = [[[SPSession sharedSession] userPlaylists] createPlaylistWithName:self.playlistNameField.stringValue];
	
	[self waitAndFillTrackPool];
}

#pragma mark -
#pragma mark SPSession Delegates

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {
	// Invoked by SPSession after a successful login.
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
    
	// Invoked by SPSession after a failed login.
	// Forward to login view
    if ([self.modalViewController respondsToSelector:@selector(session:didFailToLoginWithError:)])
		[self.modalViewController performSelector:@selector(session:didFailToLoginWithError:) withObject:aSession withObject:error];
}

-(void)sessionDidLogOut:(SPSession *)aSession; {}
-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
													message:aMessage
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

#pragma mark -
#pragma mark Game UI Actions

- (IBAction)moveNextYear:(id)sender {	
    if (year < 2013) {
        self.year++;
    }
	self.canPushOne = NO;
    [self startNewYear];
}

- (IBAction)movePrevYear:(id)sender {
	if (1950 < year) {
        self.year--;
    }
	self.canPushOne = NO;
    [self startNewYear];
}

#pragma mark -
#pragma mark Finding Tracks

-(void)waitAndFillTrackPool {
	
	[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession] timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedession, NSArray *notLoadedSession) {
		
		// The session is logged in and loaded — now wait for the userPlaylists to load.
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Session loaded.");
		
		[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession].userPlaylists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedContainers, NSArray *notLoadedContainers) {
			
			// User playlists are loaded — wait for playlists to load their metadata.
			NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Container loaded.");
			
			NSMutableArray *playlists = [NSMutableArray array];
			[playlists addObject:[SPSession sharedSession].starredPlaylist];
			[playlists addObject:[SPSession sharedSession].inboxPlaylist];
			[playlists addObjectsFromArray:[SPSession sharedSession].userPlaylists.flattenedPlaylists];
			
			[SPAsyncLoading waitUntilLoaded:playlists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedPlaylists, NSArray *notLoadedPlaylists) {
				
				// All of our playlists have loaded their metadata — wait for all tracks to load their metadata.
				NSLog(@"[%@ %@]: %@ of %@ playlists loaded.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), 
					  [NSNumber numberWithInteger:loadedPlaylists.count], [NSNumber numberWithInteger:loadedPlaylists.count + notLoadedPlaylists.count]);
				
				NSArray *playlistItems = [loadedPlaylists valueForKeyPath:@"@unionOfArrays.items"];
				NSArray *tracks = [self tracksFromPlaylistItems:playlistItems];
				
				[SPAsyncLoading waitUntilLoaded:tracks timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedTracks, NSArray *notLoadedTracks) {
					
					// All of our tracks have loaded their metadata. Hooray!
					NSLog(@"[%@ %@]: %@ of %@ tracks loaded.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), 
						  [NSNumber numberWithInteger:loadedTracks.count], [NSNumber numberWithInteger:loadedTracks.count + notLoadedTracks.count]);
					
					NSMutableArray *theTrackPool = [NSMutableArray arrayWithCapacity:loadedTracks.count];
					
					for (SPTrack *aTrack in loadedTracks) {
						if (aTrack.availability == SP_TRACK_AVAILABILITY_AVAILABLE && [aTrack.name length] > 0)
							[theTrackPool addObject:aTrack];
					}
					
					self.trackPool = [NSMutableArray arrayWithArray:[[NSSet setWithArray:theTrackPool] allObjects]];
					// ^ Thin out duplicates.
					
					[self startNewYear];
					
				}];
			}];
		}];
	}];
}

-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder {
	
	NSMutableArray *playlists = [NSMutableArray arrayWithCapacity:[[aFolder playlists] count]];
	
	for (id playlistOrFolder in aFolder.playlists) {
		if ([playlistOrFolder isKindOfClass:[SPPlaylist class]]) {
			[playlists addObject:playlistOrFolder];
		} else {
			[playlists addObjectsFromArray:[self playlistsInFolder:playlistOrFolder]];
		}
	}
	return [NSArray arrayWithArray:playlists];
}

-(NSArray *)tracksFromPlaylistItems:(NSArray *)items {
	
	NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:items.count];
	
	for (SPPlaylistItem *anItem in items) {
		if (anItem.itemClass == [SPTrack class]) {
			[tracks addObject:anItem.item];
		}
	}
	
	return [NSArray arrayWithArray:tracks];
}



#pragma mark -
#pragma mark Game Logic

-(void)startNewYear {
	
	if (self.playbackManager.currentTrack != nil) {
		[self.playlist addItem:self.playbackManager.currentTrack atIndex:self.playlist.items.count callback:^(NSError *error) {
			if (error) NSLog(@"%@", error);
		}];
	}
	
	// Starting a new year means resetting, selecting tracks then starting the timer again 
	// when the audio starts playing.
	
	self.playbackManager.isPlaying = NO;
	self.firstSuggestion = nil;
	
	self.isLoadingView.hidden = YES;

	SPTrack *theOne = [self.trackPool randomObject];
    
	if (theOne != nil) {
		
		NSMutableArray *array = [NSMutableArray arrayWithObjects:theOne, nil];
		self.firstSuggestion = [array randomObject];
		//[array removeObject:self.firstSuggestion];
		
		//Disable buttons until playback starts
		self.canPushOne = NO;
		
		[self startPlaybackOfTrack:theOne];
		
	}
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//self.year = 2013;
	[self waitAndFillTrackPool];
}

#pragma mark -
#pragma mark Playback

- (void)startPlaybackOfTrack:(SPTrack *)aTrack {
	
	[SPAsyncLoading waitUntilLoaded:aTrack timeout:5.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		[self.playbackManager playTrack:aTrack callback:^(NSError *error) {
			
			if (!error) return;
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't Play"
															message:error.localizedDescription
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}];
	}];
}

-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager {

	self.isLoadingView.hidden = YES;	
	self.canPushOne = YES;	
}


- (void)dealloc {
}

@end
