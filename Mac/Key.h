/*
 * Key.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class KeyItem, KeyApplication, KeyColor, KeySlideshow, KeyWindow, KeyAttributeRun, KeyCharacter, KeyParagraph, KeyText, KeyAttachment, KeyWord, KeyAppTheme, KeyAppTransition, KeyDocTheme, KeyMasterSlide, KeySlide, KeySlideTransition, KeyPrintSettings;

enum KeySavo {
	KeySavoAsk = 'ask ' /* Ask the user whether or not to save the file. */,
	KeySavoNo = 'no  ' /* Do not save the file. */,
	KeySavoYes = 'yes ' /* Save the file. */
};
typedef enum KeySavo KeySavo;

enum KeyKCct {
	KeyKCctArea_2d = 'are2' /* two-dimensional area chart. */,
	KeyKCctArea_3d = 'are3' /* three-dimensional area chart */,
	KeyKCctHorizontal_bar_2d = 'hbr2' /* two-dimensional horizontal bar chart */,
	KeyKCctHorizontal_bar_3d = 'hbr3' /* three-dimensional horizontal bar chart */,
	KeyKCctLine_2d = 'lin2' /*  two-dimensional line chart. */,
	KeyKCctLine_3d = 'lin3' /* three-dimensional line chart */,
	KeyKCctPie_2d = 'pie2' /* two-dimensional pie chart */,
	KeyKCctPie_3d = 'pie3' /* three-dimensional pie chart. */,
	KeyKCctScatterplot_2d = 'scp2' /* two-dimensional scatterplot chart */,
	KeyKCctStacked_area_2d = 'sar2' /* two-dimensional stacked area chart */,
	KeyKCctStacked_area_3d = 'sar3' /* three-dimensional stacked area chart */,
	KeyKCctStacked_horizontal_bar_2d = 'shb2' /* two-dimensional stacked horizontal bar chart */,
	KeyKCctStacked_horizontal_bar_3d = 'shb3' /* three-dimensional stacked horizontal bar chart */,
	KeyKCctStacked_vertical_bar_2d = 'svb2' /* two-dimensional stacked vertical bar chart */,
	KeyKCctStacked_vertical_bar_3d = 'svb3' /* three-dimensional stacked bar chart */,
	KeyKCctVertical_bar_2d = 'vbr2' /* two-dimensional vertical bar chart */,
	KeyKCctVertical_bar_3d = 'vbr3' /* three-dimensional vertical bar chart */
};
typedef enum KeyKCct KeyKCct;

enum KeyKCgb {
	KeyKCgbColumn = 'KCgc' /* group by column */,
	KeyKCgbRow = 'KCgr' /* group by row */
};
typedef enum KeyKCgb KeyKCgb;

enum KeyEnum {
	KeyEnumStandard = 'lwst' /* Standard PostScript error handling */,
	KeyEnumDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum KeyEnum KeyEnum;



/*
 * Standard Suite
 */

// A scriptable object.
@interface KeyItem : SBObject

@property (copy) NSDictionary *properties;  // All of the object's properties.

- (void) closeSaving:(KeySavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.
- (void) addChartColumnNames:(NSString *)columnNames data:(NSInteger)data groupBy:(KeyKCgb)groupBy rowNames:(NSString *)rowNames type:(KeyKCct)type;  // Add a chart to a slide
- (void) addFilePath:(NSString *)path;  // Add an image to a slide
- (void) advance;  // Advance one build or slide
- (void) makeImageSlidesPaths:(NSString *)paths master:(KeyMasterSlide *)master setTitles:(BOOL)setTitles;  // Make a series of slides from a list of image paths.  Returns a list of paths from which new slides could not be made.
- (void) pauseSlideshow;  // Pause the slideshow
- (void) resumeSlideshow;  // Resume the slideshow
- (void) showNext;  // Advance one build or slide
- (void) showPrevious;  // Go to the previous slide
- (void) start;  // Play an object.
- (void) startFrom;  // Play the containing slideshow starting with this object
- (void) stopSlideshow;  // Stop the slideshow

@end

// An application's top level scripting object.
@interface KeyApplication : SBApplication

- (SBElementArray *) slideshows;
- (SBElementArray *) windows;

@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *name;  // The name of the application.
@property (copy, readonly) NSString *version;  // The version of the application.

- (KeySlideshow *) open:(NSURL *)x;  // Open an object.
- (void) print:(NSURL *)x printDialog:(BOOL)printDialog withProperties:(KeyPrintSettings *)withProperties;  // Print an object.
- (void) quitSaving:(KeySavo)saving;  // Quit an application.
- (void) acceptSlideSwitcher;  // Hide the slide switcher, going to the slide it has selected
- (void) cancelSlideSwitcher;  // Hide the slide switcher without changing slides
- (void) GetURL:(NSString *)x;  // Open and start the document at the given URL.  Must be a file URL.
- (void) moveSlideSwitcherBackward;  // Move the slide switcher backward one slide
- (void) moveSlideSwitcherForward;  // Move the slide switcher forward one slide
- (void) pause;  // Pause the slideshow
- (void) showSlideSwitcher;  // Show the slide switcher in play mode

@end

// A color.
@interface KeyColor : KeyItem


@end

// A document.
@interface KeySlideshow : KeyItem

@property (readonly) BOOL modified;  // Has the document been modified since the last save?
@property (copy) NSString *name;  // The document's name.
@property (copy) NSString *path;  // The document's path.


@end

// A window.
@interface KeyWindow : KeyItem

@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (copy, readonly) KeySlideshow *document;  // The document whose contents are being displayed in the window.
@property (readonly) BOOL floating;  // Whether the window floats.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property (readonly) BOOL miniaturizable;  // Whether the window can be miniaturized.
@property BOOL miniaturized;  // Whether the window is currently miniaturized.
@property (readonly) BOOL modal;  // Whether the window is the application's current modal window.
@property (copy) NSString *name;  // The full title of the window.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property (readonly) BOOL titled;  // Whether the window has a title bar.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.


@end



/*
 * Text Suite
 */

// This subdivides the text into chunks that all have the same attributes.
@interface KeyAttributeRun : KeyItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// This subdivides the text into characters.
@interface KeyCharacter : KeyItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// This subdivides the text into paragraphs.
@interface KeyParagraph : KeyItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// Rich (styled) text
@interface KeyText : KeyItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) GetURL;  // Open and start the document at the given URL.  Must be a file URL.

@end

// Represents an inline text attachment.  This class is used mainly for make commands.
@interface KeyAttachment : KeyText

@property (copy) NSString *fileName;  // The path to the file for the attachment


@end

// This subdivides the text into words.
@interface KeyWord : KeyItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end



/*
 * Keynote Suite
 */

// Keynote's top level scripting object.
@interface KeyApplication (KeynoteSuite)

- (SBElementArray *) appThemes;
- (SBElementArray *) appTransitions;

@property BOOL frozen;  // Is Keynote frozen during playback?  When true, the show is playing but no motion occurs.
@property (readonly) BOOL playing;  // Is Keynote playing a show?
@property (readonly) BOOL slideSwitcherVisible;  // Is the slide selector visible?

@end

// The themes available to the appliction
@interface KeyAppTheme : KeyItem

- (NSInteger) id;  // The unique identifier of this slide.
@property (copy, readonly) NSString *name;  // The name of the theme, as it would appear in the theme chooser.


@end

// The transistions available for applying to a slide.
@interface KeyAppTransition : KeyItem

@property (copy, readonly) NSDictionary *attributes;  // Map of attribute names to potential values
@property (copy, readonly) NSString *name;  // The name of the transition.


@end

// A theme as applied to a document
@interface KeyDocTheme : KeyItem

- (SBElementArray *) masterSlides;


@end

// A master slide in a document's theme.
@interface KeyMasterSlide : KeyItem

- (SBElementArray *) slides;

- (NSInteger) id;  // The unique identifier of this slide.
@property (copy, readonly) NSString *name;  // The name of the master slide.


@end

// A slide in a slideshow
@interface KeySlide : KeyItem

@property (copy) NSString *body;  // The body text of this slide.
- (NSInteger) id;  // The unique identifier of this slide.
@property (copy) KeyMasterSlide *master;  // The master of the slide.
@property (copy) NSString *notes;  // The speaker's notes for this slide.
@property BOOL skipped;  // Whether the slide is hidden.
@property (readonly) NSInteger slideNumber;  // index of the slide in the document
@property (copy) NSString *title;  // The title of this slide.
@property (copy, readonly) KeySlideTransition *transition;  // The transition of the slide

- (void) jumpTo;  // Jump to the given slide
- (void) show;  // Show (or jump to) the recipient.

@end

// A slideshow
@interface KeySlideshow (KeynoteSuite)

- (SBElementArray *) docThemes;
- (SBElementArray *) masterSlides;
- (SBElementArray *) slides;

@property (copy) KeySlide *currentSlide;  // The slide that is currently selected.
@property (readonly) BOOL playing;  // Is Keynote playing the receiving document?

@end

// The transition of a slide
@interface KeySlideTransition : KeyItem

@property (copy, readonly) NSDictionary *attributes;  // Map of attribute names to values
@property (copy) KeyAppTransition *type;  // The type of the transition


@end



/*
 * Type Definitions
 */

@interface KeyPrintSettings : SBObject

@property NSInteger copies;  // the number of copies of a document to be printed
@property BOOL collating;  // Should printed copies be collated?
@property NSInteger startingPage;  // the first page of the document to be printed
@property NSInteger endingPage;  // the last page of the document to be printed
@property NSInteger pagesAcross;  // number of logical pages laid across a physical page
@property NSInteger pagesDown;  // number of logical pages laid out down a physical page
@property (copy) NSDate *requestedPrintTime;  // the time at which the desktop printer should print the document
@property KeyEnum errorHandling;  // how errors are handled
@property (copy) NSString *faxNumber;  // for fax number
@property (copy) NSString *targetPrinter;  // for target printer

- (void) closeSaving:(KeySavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.
- (void) addChartColumnNames:(NSString *)columnNames data:(NSInteger)data groupBy:(KeyKCgb)groupBy rowNames:(NSString *)rowNames type:(KeyKCct)type;  // Add a chart to a slide
- (void) addFilePath:(NSString *)path;  // Add an image to a slide
- (void) advance;  // Advance one build or slide
- (void) makeImageSlidesPaths:(NSString *)paths master:(KeyMasterSlide *)master setTitles:(BOOL)setTitles;  // Make a series of slides from a list of image paths.  Returns a list of paths from which new slides could not be made.
- (void) pauseSlideshow;  // Pause the slideshow
- (void) resumeSlideshow;  // Resume the slideshow
- (void) showNext;  // Advance one build or slide
- (void) showPrevious;  // Go to the previous slide
- (void) start;  // Play an object.
- (void) startFrom;  // Play the containing slideshow starting with this object
- (void) stopSlideshow;  // Stop the slideshow

@end

