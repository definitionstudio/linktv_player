Link TV Player
==============
Link TV Player is a standalone Flash® video player, written in ActionScript 3. 
Developed for [ViewChange.org](http://www.viewchange.org) and
[Link TV Platform](https://github.com/definitionstudio/linktv_platform),
the player supports streaming and progressive video sources, as well as YouTube videos.


Features
--------
* Streaming (RTMP) or progressive (HTTP) video playback
* MP4 (H.264) and FLV/F4V media support
* YouTube video support, via the [YouTube Chromeless Player API](http://code.google.com/apis/youtube/flash_api_reference.html).
* "High quality" video option
* Segment/chapter support
* Embedded display mode


Dependencies
------------
* [Flash Player](http://www.adobe.com/go/getflash/) version 9.0.115 or higher
* [JSON-js](https://github.com/douglascrockford/JSON-js) or equivalent JSON serializer


Configuration
-------------

### Flashvars:

* config (string): JSON-encoded config object (see below)
* configUrl (string): URL of JSON config data (valid only if _config_ not provided)

### Config object:

* startTime (integer): Video start time (default: 0)
* playerId (string): Player DOM ID (required when passing eventHandler)
* eventHandler (string): JavaScript callback for handling player events
* embedded (boolean): true for embedded display mode (iframe)
* fullscreen (boolean): false to disable fullscreen controls
* resize (boolean): true to enable resize controls (requires _eventHandler_, ignored if _embedded_ = true)
* permalinkId (string): Video GUID
* permalinkUrl (string): Video URL
* streamHost (string): RTMP host, with prefix
* mediaType (string): "internal" or "youtube"
* mediaStatus (object)
	* available (boolean)
	* message (string)
* media (array)
	* (object):
		* url (string): Internal or YouTube URL
		* size (integer): File size, in bytes
* duration (integer): Video duration, in seconds
* title (string): Video title
* description (string): Video description text
* posterImage (string): Image URL
* posterAttribution (string): Image attribution text
* segments (array):
	* (object):
		* id (integer): Numeric ID
		* startTime (integer): Start time, in seconds
		* title (string): Segment title
		* thumbnail (string): Image URL
* trackPlayUrl (string): URL for tracking play event (POST)
* userId (string): Optional user ID for play event tracking
* googleAnalyticsId (string): Google Analytics ID for GA event tracking
* googleAnalyticsMode (string): "AS3" or "Bridge" (default: "AS3"). Bridge mode supports [GA async tracking](http://code.google.com/apis/analytics/docs/tracking/asyncUsageGuide.html). See [gaforflash docs](http://code.google.com/apis/analytics/docs/tracking/flashTrackingIntro.html#trackingModes) for more info.
* player (object): Player UI customizations
	* controlsBgColor (string): Hex color
	* controlsBgOpacity (float): Decimal, 0.0 – 1.0
	* controlsTextColor (string): Hex color
	* progressBarTrackColor (string): Hex color
	* progressBarTrackOpacity (float): Decimal, 0.0 – 1.0
	* progressBarLoadColor (string): Hex color
	* progressBarColor (string): Hex color
	* segmentNavColor (string): Hex color
	* segmentNavOpacity (float): Decimal, 0.0 – 1.0
	* segmentNavActiveColor (string): Hex color
	* segmentNavActiveOpacity (float): Decimal, 0.0 – 1.0
	* segmentInfoBgColor (string): Hex color
	* segmentInfoBgOpacity (float): Decimal, 0.0 – 1.0
	* segmentInfoTextColor (string): Hex color
	* headerBgColor (string): Hex color
	* headerBgOpacity (float): Decimal, 0.0 – 1.0
	* headerTextColor (string): Hex color
	* linkTextColor (string): Hex color
	* tooltipBgColor (string): Hex color
	* tooltipBgOpacity (float): Decimal, 0.0 – 1.0
	* tooltipTextColor (string): Hex color


External Methods
----------------
* getCurrentTime(): Returns playhead time, in seconds
* seekToSegment(segmentId): Seek to beginning of segment


Player Events
-------------
Player events are dispatched to the JavaScript callback function defined in the _eventHandler_ config option. The _eventHandler_ callback will receive a single event object argument. The following events are currently dispatched by the player:

* segmentChange (object): for multi-segment videos, dispatched when playback of a new segment begins
	* type (string): "segmentChange"
	* segment (integer): ID of segment beginning playback
	* playerId: player DOM ID
* scaleUp (object): dispatched when resize control is clicked (scaling up)
	* type (string): "scaleUp"
	* playerId: player DOM ID
* scaleDown (object): dispatched when resize control is clicked (scaling down)
	* type (string): "scaleDown"
	* playerId: player DOM ID


Examples
--------
See the _examples_ directory for embedding examples using [SWFObject](http://code.google.com/p/swfobject/). You may encounter Flash Player security warnings 
if attempting to run the files locally.


Customization
-------------
You are free to modify the player without restriction. You will need Adobe Flash CS4 or higher to publish the player SWF.


Acknowledgements
----------------
* Developed by [Rob DiCiuccio](https://github.com/robdiciuccio) for [Definition LLC](http://www.definitionstudio.com)
* Produced by [Link Media, Inc.](http://www.linktv.org)

Google Analytics Tracking For Adobe Flash, an Apache 2.0-licensed project, is bundled with this distribution.
More information available at <http://code.google.com/p/gaforflash/>


License
-------
Distributed under the MIT License, copyright (c) 2011 Definition LLC.
A project of Link Media, Inc.