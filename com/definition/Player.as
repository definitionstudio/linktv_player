
package com.definition
{
	import flash.display.DisplayObject;
	import flash.display.Bitmap;
    import flash.display.BitmapData;
	import flash.text.Font;
	import flash.geom.Matrix;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
	import flash.text.TextLineMetrics;
	import flash.text.AntiAliasType;
    import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.StyleSheet;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.Loader;
    import flash.events.*;
	import flash.utils.*;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Rectangle;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	
	// requires as3corelib SWC be present in lib/as3corelib/lib
	import com.adobe.serialization.json.JSON;
	
	// requires analytics_flash SWC be present in lib/gaforflash/lib
	import com.google.analytics.AnalyticsTracker; 
	import com.google.analytics.GATracker;
	
	// utility classes
	import com.definition.CustomEvent;
	import com.definition.Utilities;
	import com.definition.Scroller;
	
	// video player controls
	import com.definition.Controls;
	
	// video APIs
	import com.definition.StdVideoAPI;
	import com.definition.YouTubeVideoAPI;
	
		
	public class Player extends Sprite {
		
		// controls object
		internal var controls:Controls;
		
		// video API object
		internal var video:Object;
		
		private var debug:Boolean = false;					// DEBUG switch
		private var loadError:Boolean = false;
		private var uiDrawn:Boolean = false;
		private var now:Date = new Date();					// anti-caching (use now.getTime() in requests)
		
		internal var flashVars:Object;
		internal var embeddedMode:Boolean = false;
		internal var externalEventHandler:String = null;	// JS event callback
		internal var resizeEnabled:Boolean = false;
		internal var fullscreenEnabled:Boolean = true;
		private var playerDOMId:String = null;
		
		private var trackedEvents:Array = new Array();		// analytics tracking (one-time events)
		private var GoogleTracker:AnalyticsTracker;
		private var trackingMode:String = "AS3";
		
		private var videoViewTime:uint = 0;					// ms
		private var videoViewTimeStart:uint = 0;
		
		private var config:Object = new Object();
		private var configUrl:String = null;
		private var configLoader:URLLoader;
		private var configLoaded:Boolean = false;
		
		internal var settings:Object = new Object();
		internal var defaultSettings:Object = new Object();
		
		// video & poster img containers
		internal var videoContainer:Sprite;
		internal var posterImgContainer:Sprite;
		
		// video data
		internal var videoStart:Number = 0;
		internal var videoTitle:String = null;
		internal var videoDuration:Number = 0;
		internal var videoSegments:Array = new Array();
		internal var videoFiles:Array = new Array();
		internal var mediaServerURL:String = null;			// set to null for progressive video
		
		private var videoPermalinkId:String = null;
		private var videoPermalinkURL:String = null;
		private var videoDescription:String = null;
		private var videoMediaType:String = 'internal';		// default
		
		internal var videoSegmentThumbs:Array = new Array();
		private var videoSegmentThumbLoadId:int = 0;
		
		internal var currentVideoSegmentIdx:Number = 0;
		internal var segmentChangeLock:Boolean = false;
		internal var scrubPlayState:String = null;
		internal var isHighQuality:Boolean = false;
		internal var isLargeSize:Boolean = false;			// player dimensions (expanded)
		
		// image loaders
		internal var posterImg:Bitmap = new Bitmap();
		internal var posterImgLoaded:Boolean = false;
		private var posterImgURL:String = null;
		private var posterImgAttribution:String = null;
		private var posterImgAttributionSprite:Sprite;
		private var posterImgLoadError:Boolean = false;
		private var posterImageTween:Tween;					// use class var to prevent garbage collection during tween
		
		internal var mouseOffStage:Boolean = true;
				
		// timer for updating display
		private var timer:Timer = new Timer(500);			// in ms		
		
		// in FLA Library
		internal var loading:bufferingMC = new bufferingMC();
		internal var thumbMask:thumbnailMask = new thumbnailMask();
		internal var playOverlay:playOverlayButton = new playOverlayButton();
		internal var uiFont:Font = new ui_font();
		
		// user feedback
		internal var userFeedback:String = "";
		internal var userFeedbackTF:TextField;
		
		// textformats
		internal var uiTF:TextFormat;
		internal var tooltipTF:TextFormat;
		internal var imgAttributionTF:TextFormat;
		internal var segmentTitleTF:TextFormat;
		internal var headerTitleTF:TextFormat;
		internal var headerDescrTF:TextFormat;
		internal var headerMoreLinkTF:TextFormat;
		
		internal var styles:StyleSheet;
		
		// header elements
		private var header:Sprite;							// header container
		private var headerOpen:Boolean = false;
		private var headerBg:Sprite;
		private var headerBgShape:Shape;
		private var headerTitle:TextField;
		private var headerDescr:TextField;
		private var headerMore:TextField;
		private var headerPadding:uint = 5;
		private var scrollBar:Scroller;
		
		
		// constructor
		public function Player() {
			// set XML defaults
			XML.ignoreWhitespace = true;
			XML.ignoreComments = true;
			
			// adjust stage scalemode & alignment
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			// ensure class is initialized
			addEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
		}
		
		private function _addedToStageHandler(evt:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
			// Internet Explorer stage size workaround
			if(!stage.stageWidth || !stage.stageHeight) {
				stage.addEventListener(Event.RESIZE, _ieStageSizeInit);
			} else {
				_init();
			}
		}
		
		private function _ieStageSizeInit(evt:Event):void {
			trace('_ieStageSizeInit');
			if(stage.stageWidth && stage.stageHeight) {
				stage.removeEventListener(Event.RESIZE, _ieStageSizeInit);
				_init();
			}
		}
			
		private function _init():void {
			trace('***** INIT *****');
			trace('STAGE SIZE', stage.stageWidth, stage.stageHeight);
			
			// resize background
			playerBackground.width = stage.stageWidth;
			playerBackground.height = stage.stageHeight;
			
			// display load indicator
			showLoading();
			
			// init controls object
			controls = new Controls(this);

			// init container sprites
			videoContainer = new Sprite();
			posterImgContainer = new Sprite();
			addChild(videoContainer);
			addChild(posterImgContainer);

			// process flashVars
			flashVars = this.loaderInfo.parameters;
			
			trace('*** flashvars ***');
			for(var f:String in flashVars) { trace('* ' + f + ': ' + flashVars[f]); }
			
			if(flashVars['configUrl'] != undefined) configUrl = flashVars['configUrl'];
			if(flashVars['config'] != undefined) {
				try {
					trace("local config data present");
					config = JSON.decode(flashVars['config']);
					configLoaded = true;
				} catch(e:Error) {
					trace('caught error', e);
					if(!configUrl) {
						loadError = true;
						displayMessage("Error loading configuration data. Please try again.");
					}
				}
			}
			
			// set STAGE event handlers
			stage.addEventListener(Event.RESIZE, stageResizeHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, stageMouseRelease);				// handle all mouse up events (stop scrubbing, etc.)
			stage.addEventListener(Event.MOUSE_LEAVE, stageMouseLeave);					// handle controls hiding
			stage.addEventListener(MouseEvent.MOUSE_MOVE, stageMouseMove);
			
			// init default player settings
			_setDefaults();
									
			// load configuration
			_loadConfig();
			
			// init the timer listeners
			timer.addEventListener(TimerEvent.TIMER, updateDisplay);
			
			// init EXTERNAL callbacks
			_initExternalCallbacks();
		}
		
		/* ============================ */
		/* = LOAD/PARSE CONFIGURATION = */
		/* ============================ */
		
		private function _setDefaults():void {
			
			defaultSettings.controlsBgColor = '#CCCCCC';
			defaultSettings.controlsBgOpacity = 0.9;
			defaultSettings.controlsTextColor = '#000000';
			
			defaultSettings.progressBarTrackColor = '#EEEEEE';
			defaultSettings.progressBarTrackOpacity = 0.9;
			defaultSettings.progressBarLoadColor = '#CCCCCC';
			defaultSettings.progressBarColor = '#FFCC00';
			
			defaultSettings.segmentNavColor = '#FFFFFF';
			defaultSettings.segmentNavOpacity = 0.5;
			defaultSettings.segmentNavActiveColor = '#FFCC00';
			defaultSettings.segmentNavActiveOpacity = 0.9;
			
			defaultSettings.segmentInfoBgColor = '#FFFFFF';
			defaultSettings.segmentInfoBgOpacity = 0.9;
			defaultSettings.segmentInfoTextColor = '#000000';
			
			defaultSettings.headerBgColor = '#333333';
			defaultSettings.headerBgOpacity = 0.9;
			defaultSettings.headerTextColor = '#FFFFFF';
			defaultSettings.linkTextColor = '#FFCC00';
			
			defaultSettings.tooltipBgColor = '#333333';
			defaultSettings.tooltipBgOpacity = 0.9;
			defaultSettings.tooltipTextColor = '#FFFFFF';
			
		}
		
		private function _initStyles():void {
			
			// create textformats
			uiTF = new TextFormat();
			uiTF.color = Utilities.convertHexColor(settings.controlsTextColor);
			uiTF.font = uiFont.fontName;
			uiTF.size = 10;
			
			tooltipTF = new TextFormat();
			tooltipTF.color = Utilities.convertHexColor(settings.tooltipTextColor);
			tooltipTF.font = uiFont.fontName;
			tooltipTF.size = 10;
			
			segmentTitleTF = new TextFormat();
			segmentTitleTF.color = Utilities.convertHexColor(settings.segmentInfoTextColor);
			segmentTitleTF.font = uiFont.fontName;
			segmentTitleTF.size = 10;
			segmentTitleTF.leading = 1;
			
			imgAttributionTF = new TextFormat();
			imgAttributionTF.color = 0xDDDDDD
			imgAttributionTF.font = uiFont.fontName;
			imgAttributionTF.size = 10;
			imgAttributionTF.letterSpacing = 1;
			imgAttributionTF.align = TextFormatAlign.CENTER;
			
			headerTitleTF = new TextFormat();
			headerTitleTF.color = Utilities.convertHexColor(settings.headerTextColor);
			headerTitleTF.font = uiFont.fontName;
			headerTitleTF.size = 18;
			headerTitleTF.leading = 1;
			
			headerDescrTF = new TextFormat();
			headerDescrTF.color = Utilities.convertHexColor(settings.headerTextColor);
			headerDescrTF.font = uiFont.fontName;
			headerDescrTF.size = 11.5;
			headerDescrTF.leading = 4;
			
			headerMoreLinkTF = new TextFormat();
			headerMoreLinkTF.color = Utilities.convertHexColor(settings.linkTextColor);
			headerMoreLinkTF.font = uiFont.fontName;
			headerMoreLinkTF.size = 11.5;
			
			// init stylesheet
			styles = new StyleSheet();
			styles.setStyle("a", {color:settings.linkTextColor});
			styles.setStyle("p", {display:"block"});
			styles.setStyle(".more-info-header", {fontWeight:"bold",fontSize:14,leading:24});
			
		}
		
		private function _loadConfig():void {
			if(configLoaded) {
				_parseConfig();
			} else if(configUrl) {
				trace('configUrl: ' + configUrl);
				var configRequest:URLRequest = new URLRequest(configUrl);
				configLoader = new URLLoader(configRequest);
				configLoader.addEventListener(Event.COMPLETE, _configLoaded);
				configLoader.addEventListener(IOErrorEvent.IO_ERROR, _configIoErrorHandler);
				configLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _configSecurityErrorHandler);
			} else {
				// no config present
				loadError = true;
				displayMessage("Error loading player configuration.");
			}
		}
		
		private function _configLoaded(event:Event):void {
			trace("config data received");
			trace(typeof configLoader.data, configLoader.data);
			try {
				if(typeof configLoader.data == 'object') {
					config = configLoader.data;
				} else {
					config = JSON.decode(configLoader.data);
				}
				configLoaded = true;
				_parseConfig();
			} catch(e:Error) {
				trace('Caught exception', e);
				loadError = true;
				displayMessage("Error loading video data. Please try again.");
			}
		}
		
		private function _configIoErrorHandler(event:IOErrorEvent):void {
			loadError = true;
			displayMessage("Error loading video data. Please try again.");
		}
		
		private function _configSecurityErrorHandler(event:SecurityErrorEvent):void {
			loadError = true;
			displayMessage("Error loading video data. Please try again.");
		}
		
		private function _parseConfig():void {
			
			if(config.embedded) embeddedMode = true;
			if(config.resize) resizeEnabled = true;
			if(config.fullscreen == false) fullscreenEnabled = false;
			if(config.eventHandler) externalEventHandler = config.eventHandler;
			if(config.playerId) playerDOMId = config.playerId;
			if(config.startTime) videoStart = Number(config.startTime);
			if(isNaN(videoStart)) videoStart = 0;	// fix invalid start time
			
			// init video status
			var videoStatusAvailable = false;
			var videoStatusMsg = "The requested video is not available.";
			
			try {
				if(config.mediaStatus.available) videoStatusAvailable = true;
				if(!videoStatusAvailable && config.mediaStatus.message != '') videoStatusMsg = config.mediaStatus.message;
				if(!config.media.length) videoStatusAvailable = false;
			} catch(e:Error) {
				videoStatusAvailable = false;
			}
			
			if(!videoStatusAvailable) {
				displayMessage(videoStatusMsg);		// error & die
				hideLoading();
				return;
			}
			
			// continue processing
			
			if(config.mediaType) videoMediaType = config.mediaType; 
			if(config.streamHost) mediaServerURL = config.streamHost;
			if(config.posterImage) posterImgURL = config.posterImage;
			if(config.posterAttribution) posterImgAttribution = config.posterAttribution;
			
			// video metadata
			if(config.permalinkId) videoPermalinkId = config.permalinkId;
			if(config.permalinkUrl) videoPermalinkURL = config.permalinkUrl;
			if(config.title) videoTitle = config.title;
			if(config.description) videoDescription = config.description;
			if(config.additionalInfo) {
				if(videoDescription) {
					videoDescription += '<br><br><p class="more-info-header">MORE INFO</p>';
					videoDescription += config.additionalInfo;
				} else {
					videoDescription = config.additionalInfo;
				}
			}
			if(config.duration) videoDuration = config.duration;			// used for building controls before video metadata is loaded
						
			// parse video files
			for each (var media:Object in config.media) {
				videoFiles.push( { path:media.url, filesize:media.size } );
			}
			
			// Sort media by filesize (smaller first) for pseudo-quality levels
			videoFiles.sortOn("filesize", Array.NUMERIC);
			
			// parse SEGMENTS
			if(config.segments) {
				for each (var segment in config.segments) {
					videoSegments.push({ id: segment.id, time: Number(segment.startTime), title: segment.title, thumbnail_url: segment.thumbnail });
				}
				// Sort segments by start time
				videoSegments.sortOn("time", Array.NUMERIC);
				
				// set initial video segment
				for(var i:Number = videoSegments.length-1; i>=0; i--) {
					if(videoStart >= videoSegments[i].time) {
						currentVideoSegmentIdx = i;
						break;
					}
				}
				
				if(currentVideoSegmentIdx > 0) segmentChangeLock = true;
			}
			
			// init player settings
			for(var s:String in defaultSettings) {
				if(config.player) {
					settings[s] = (config.player[s] == undefined) ? defaultSettings[s] : config.player[s];
				} else {
					settings[s] = defaultSettings[s];
				}
			}
			
			// init styles
			_initStyles();
			
			// setup Google Analytics tracker
			if(config.googleAnalyticsMode) trackingMode = config.googleAnalyticsMode;
			if(trackingMode == "AS3") {
				try {
					GoogleTracker = new GATracker(this, config.googleAnalyticsId, trackingMode, debug);	// display object, property ID, tracking mode, debug mode
				} catch(e:Error) {
					trace("error setting up Google Analytics tracker. Probably invalid property ID");
				}
			}
			
			// init video player
			try {
				_initVideoAPI();
			} catch(e:Error) {
				loadError = true;
				trace(e);
				displayMessage('Error loading video player API.');
			}
			
			// load poster img (load VideoAPI before calling this)
			_loadPosterImage();
			
			// load segment thumbnails
			_loadSegmentThumbnails();
			
			// start timer
			timer.start();
		}
		
		
		/* =================== */
		/* = PLAYER CONTROLS = */
		/* =================== */
		
		private function _initControls(controlsMode:String):void {
			
			if(loadError) return;	// don't draw controls on loadError
			trace("_initControls: " + controlsMode);
			try {
				controls.draw(controlsMode);
			} catch(e:Error) {
				trace(e);
				loadError = true;
				displayMessage('Error initializing player controls.');
			}
		}
		
		/* ====================== */
		/* = VIDEO API HANDLERS = */
		/* ====================== */
		
		private function _initVideoAPI():void {
						
			// load video object
			switch(videoMediaType.toLowerCase()) {
				case 'internal':
					video = new StdVideoAPI(this, stage.stageWidth, stage.stageHeight);
					break;
				case 'youtube':
					video = new YouTubeVideoAPI(this, stage.stageWidth, stage.stageHeight);
					break;
				default:
					displayMessage('Error loading video player.');
					return;
			}
			
			// event listeners
			video.addEventListener('ready', videoAPIReadyHandler);
			video.addEventListener('stateChange', videoAPIStateChangeHandler);
			video.addEventListener('error', videoAPIErrorHandler);
			
			// init API
			video.init();
		}
		
		private function videoAPIReadyHandler(evt:Event):void {
            trace('# videoAPIready dispatched #');
			
			if(!uiDrawn && !loadError) {
				// init controls
				_initControls('default');
				// init keyboard controls
				_initKeyboardControls();
				// load overlay icon
				_initPlayOverlay();
				// set status
				uiDrawn = true;
			}
			
			if(posterImgLoaded || posterImgLoadError) hideLoading();
        }
		
		private function videoAPIStateChangeHandler(evt:CustomEvent):void {
            trace('videoAPIStateChangeHandler dispatched');
			trace('state:', evt.data.state);
			stopVideoViewTimeTracker();
			switch(evt.data.state) {
				case video.STATE_PLAYING:
					startVideoViewTimeTracker();
					controls.updatePlayState(true);			// update controls
					playOverlay.visible = false;			// hide overlay icon
					posterImgContainer.visible = false;		// hide poster img
					hideLoading();							// hide loader
					hideHeader();							// hide header overlay
					trackEvent('Play');						// analytics
					break;
				case video.STATE_PAUSED:
					controls.updatePlayState(false);		// update controls
					showHeader();							// display header (if applicable)
					break;
				case video.STATE_BUFFERING:
					if(!video.isComplete() && !video.hasBusyIndicator()) showLoading();		// show loader
					break;
				case video.STATE_ENDED:
					controls.updatePlayState(false);		// update controls
					hideLoading();							// hide loader
					showHeader();							// display header (if applicable)
					break;
			}
        }
		
		private function videoAPIErrorHandler(evt:CustomEvent):void {
            trace('videoAPIError dispatched');
			var errorMsg:String = evt.data.message;
			displayMessage(errorMsg);
        }
		
		
		/* ===================== */
		/* = KEYBOARD CONTROLS = */
		/* ===================== */
		
		private function _initKeyboardControls():void {
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
		
		function keyUpHandler(e:KeyboardEvent):void {
			trace('keyUpHandler, code: ' + e.keyCode);
			
			if(e.keyCode == 32) {		// SPACE bar
				(video.isPlaying()) ? video.pause() : video.play();
			}
		}
		
		
		/* ================ */
		/* = POSTER IMAGE = */
		/* ================ */
		
		private function _loadPosterImage():void {
			if(posterImgURL) {
				trace('loading poster img', posterImgURL);
				var posterImgLoader:Loader = new Loader();
				posterImgLoader.load(new URLRequest(posterImgURL));
				posterImgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, posterImgCompleteHandler);
				posterImgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, posterImgIoErrorHandler);
			} else {
				posterImgLoadError = true;
				// init header
				_initHeader();
				// hide loader
				if(video.isReady()) hideLoading();
			}
		}
		
		private function posterImgCompleteHandler(e:Event):void{
			
			posterImg = Bitmap(e.currentTarget.content);
			
			if(!video.hasPosterImage()) {
				var imgAspect:Number = posterImg.width/posterImg.height;
				posterImg.alpha = 0;
				posterImg.smoothing = true;
				posterImg.width = (imgAspect > 1) ? stage.stageWidth : stage.stageHeight*imgAspect;
				posterImg.height = (imgAspect > 1) ? stage.stageWidth/imgAspect : stage.stageHeight;
				posterImg.x = (imgAspect > 1) ? 0 : (stage.stageWidth-posterImg.width)/2;
				posterImg.y = (imgAspect > 1) ? (stage.stageHeight-posterImg.height)/2 : 0;
			
				// add image to stage
				posterImgContainer.addChild(posterImg);
				drawPosterImgAttribution();
				posterImageTween = new Tween(posterImg, "alpha", Strong.easeOut, 0, 1, 1, true);
			}
			
			posterImgLoaded = true; 
			
			// init header
			_initHeader();
			
			// hide loader
			if(video.isReady()) hideLoading();
		}
		
		private function posterImgIoErrorHandler(e:IOErrorEvent):void {
			
			posterImgLoadError = true;
			
			// init header anyway
			_initHeader();
			
			// hide loader
			if(video.isReady()) hideLoading();
        }

		private function drawPosterImgAttribution():void {
			// attribution text
			if(posterImgContainer.visible && !video.hasPosterImage() && posterImgAttribution != null) {
				// clear
				try {
					posterImgContainer.removeChild(posterImgAttributionSprite);
				} catch(e:Error) {}
				posterImgAttributionSprite = new Sprite();
				// draw
				var padding:Number = 6;
				var attribution:TextField = new TextField();
				attribution.width = stage.stageHeight - (padding*2);
				attribution.autoSize = TextFieldAutoSize.LEFT;
				attribution.selectable = false;
				attribution.wordWrap = true;
				attribution.embedFonts = true;
				attribution.antiAliasType = AntiAliasType.ADVANCED;
				attribution.sharpness = 200;
				attribution.defaultTextFormat = imgAttributionTF;
				attribution.text = posterImgAttribution;
				attribution.rotation = -90;
				attribution.y = stage.stageHeight-padding;
				attribution.x = stage.stageWidth - attribution.textHeight - padding;
				// bcakground
				var bg:Shape = Utilities.drawBox({
					color: 0x000000,
					alpha: 0.4,
					width: attribution.textHeight + padding,
					height: stage.stageHeight});
				bg.x = stage.stageWidth-bg.width;
				// attach
				posterImgAttributionSprite.addChild(bg);
				posterImgAttributionSprite.addChild(attribution);
				posterImgContainer.addChild(posterImgAttributionSprite);
			}
		}
		
		
		/* ====================== */
		/* = SEGMENT THUMBNAILS = */
		/* ====================== */
		
		private function _loadSegmentThumbnails():void {
			
			if(videoSegmentThumbLoadId < videoSegments.length) {
				var segment:Object = videoSegments[videoSegmentThumbLoadId];
				if(segment.thumbnail_url) {
					var thumbnailLoader:Loader = new Loader();
					thumbnailLoader.load(new URLRequest(segment.thumbnail_url));
					thumbnailLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, segmentThumbCompleteHandler);
					thumbnailLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, segmentThumbErrorHandler);
				} else {
					// load next
					videoSegmentThumbLoadId++;
					_loadSegmentThumbnails();
				}
			}
		}
		
		private function segmentThumbCompleteHandler(e:Event):void{
			
			trace("segmentThumbCompleteHandler: " + e);
			videoSegmentThumbs[videoSegmentThumbLoadId] = Bitmap(e.currentTarget.content);
			
			// load next
			videoSegmentThumbLoadId++;
			_loadSegmentThumbnails();
		}
		
		private function segmentThumbErrorHandler(e:IOErrorEvent):void {
            trace("segmentThumbErrorHandler: " + e);
			
			// ignore error & load next thumb
			videoSegmentThumbLoadId++;
			_loadSegmentThumbnails();
			
        }
		
		
		/* ============= */
		/* = PLAY ICON = */
		/* ============= */
		
		private function _initPlayOverlay():void {
			if(!video.hidePlayIconOverlay) {
				playOverlay.alpha = 0.7;
				playOverlay.x = (stage.stageWidth/2)-(playOverlay.width/2);
				playOverlay.y = (stage.stageHeight/2)-(playOverlay.height/2)-10;
				playOverlay.addEventListener(MouseEvent.MOUSE_OVER, playOverlayMouseOver);
				playOverlay.addEventListener(MouseEvent.MOUSE_OUT, playOverlayMouseOut);
				playOverlay.addEventListener(MouseEvent.CLICK, playOverlayClick);
				playOverlay.buttonMode = true;
				addChild(playOverlay);
			}
		}
		
		private function playOverlayMouseOver(e:MouseEvent):void {
			playOverlay.alpha = 0.9;
		}
		private function playOverlayMouseOut(e:MouseEvent):void {
			playOverlay.alpha = 0.7;
		}
		private function playOverlayClick(e:MouseEvent):void {
			video.play();
		}
		
		
		/* ================== */
		/* = HEADER DISPLAY = */
		/* ================== */
		
		private function _initHeader():void {

			if(header != null) removeChild(header);
			
			header = new Sprite();
			headerBg = new Sprite();
			headerBgShape = Utilities.drawBox({
				color: settings.headerBgColor,
				alpha: 1,
				width: stage.stageWidth,
				height: thumbMask.height+10});
			headerBg.alpha = settings.headerBgOpacity;
			headerBg.addChild(headerBgShape);
			//headerBg.addEventListener(MouseEvent.CLICK, headerBgClick);		// handled by stage mouse release
			header.addChild(headerBg);
						
			if(posterImgLoaded) {
				var thumbImg = new Bitmap(posterImg.bitmapData.clone());
				var imgAspect:Number = thumbImg.width/thumbImg.height;
				
				thumbImg.smoothing = true;
				thumbImg.height = thumbMask.height;
				thumbImg.width = Math.ceil(thumbMask.height*imgAspect);
				thumbImg.x = headerPadding-Math.floor((thumbImg.width-thumbMask.width)/2);		// center
				thumbImg.y = headerPadding;
				thumbImg.mask = thumbMask;
				thumbMask.x = headerPadding;
				thumbMask.y = headerPadding;
				
				var thumbImgSprite:Sprite = new Sprite();	// workaround for no buttonMode support for Bitmaps
				thumbImgSprite.addChild(thumbImg);
				if(embeddedMode) {
					thumbImgSprite.addEventListener(MouseEvent.CLICK, headerTitleClick);
					thumbImgSprite.buttonMode = true;
				}
				header.addChild(thumbImgSprite);
			}
			
			// title text
			headerTitle = new TextField();
			headerTitle.x = posterImgLoaded ? thumbMask.x+thumbMask.width+(headerPadding*2) : headerPadding;
			headerTitle.y = 10;
			headerTitle.width = posterImgLoaded ? stage.stageWidth-(thumbMask.x+thumbMask.width)-(headerPadding*2) : stage.stageWidth-(headerPadding*2);
			headerTitle.height = 25;
			headerTitle.multiline = true;
			headerTitle.wordWrap = true;
			headerTitle.autoSize = TextFieldAutoSize.LEFT;
			headerTitle.selectable = false;
			headerTitle.mouseWheelEnabled = false;
			headerTitle.defaultTextFormat = headerTitleTF;
			headerTitle.text = videoTitle;
		
			if(headerTitle.numLines > 1) {
				// max 2 lines, with elipses
				if(headerTitle.numLines > 2) {
					var lastChar:uint = headerTitle.getLineOffset(1) + headerTitle.getLineLength(1);
					headerTitle.replaceText(lastChar, headerTitle.length, '');
					headerTitle.replaceText(lastChar-3, lastChar, '...');
				}
				headerTitle.y = headerPadding;
			}
			
			var headerTitleSprite:Sprite = new Sprite();	// workaround for no buttonMode support for TextFields
			headerTitleSprite.addChild(headerTitle);
			if(embeddedMode) {
				headerTitleSprite.addEventListener(MouseEvent.CLICK, headerTitleClick);
				headerTitleSprite.buttonMode = true;
				headerTitleSprite.mouseChildren = false;
			}
			header.addChild(headerTitleSprite);
			
			// descr text
			if(videoDescription) {
				headerDescr = new TextField();
				headerDescr.x = posterImgLoaded ? thumbMask.x+thumbMask.width+11 : headerPadding;
				headerDescr.y = headerTitle.y + headerTitle.height - Number(headerTitleTF.leading);
				headerDescr.width = posterImgLoaded ? stage.stageWidth-(thumbMask.x+thumbMask.width)-70 : stage.stageWidth-(headerPadding*2)-70;
				headerDescr.height = 20;
				headerDescr.selectable = false;
				headerDescr.mouseWheelEnabled = false;
				headerDescr.multiline = true;
				headerDescr.wordWrap = true;
				headerDescr.defaultTextFormat = headerDescrTF;
				headerDescr.styleSheet = styles;
				headerDescr.htmlText = videoDescription;
				header.addChild(headerDescr);

				var descrMetrics:TextLineMetrics = headerDescr.getLineMetrics(0);

				// more link
				headerMore = new TextField();
				headerMore.x = headerDescr.x + descrMetrics.width + headerPadding;
				headerMore.y = headerTitle.y + headerTitle.height;
				headerMore.width = 50;
				headerMore.height = 20;
				headerMore.selectable = false;
				headerMore.defaultTextFormat = headerMoreLinkTF;
				headerMore.text = "(more...)";

				var headerMoreSprite:Sprite = new Sprite();		// workaround for no buttonMode support for TextFields
				headerMoreSprite.addChild(headerMore);
				headerMoreSprite.addEventListener(MouseEvent.CLICK, headerMoreClick);
				headerMoreSprite.buttonMode = true;
				headerMoreSprite.mouseChildren = false;
				header.addChild(headerMoreSprite);
			}
			
			headerBgResize(false);
			header.visible = false;
			addChild(header);
			showHeader();
		}
		
		private function headerBgResize(expanded:Boolean) {
			if(expanded) {
				headerBgShape.height = stage.stageHeight;
				headerBg.alpha = (settings.headerBgOpacity > 0.9) ? settings.headerBgOpacity : 0.9;
			} else {
				try {
					headerBgShape.height = headerTitle.y + headerTitle.height + headerDescr.height + headerPadding;
				} catch(e:Error) {
					headerBgShape.height = headerTitle.y + headerTitle.height + headerPadding;
				}
				var minHeight:uint = thumbMask.height+(headerPadding*2);
				if(posterImgLoaded && headerBgShape.height < minHeight) headerBgShape.height = minHeight;
				headerBg.alpha = settings.headerBgOpacity;
			}
		}
		
		
		private function headerTitleClick(e:MouseEvent):void {			
			// navigate to video permalink page
			var videoPageRequest:URLRequest = new URLRequest(videoPermalinkURL);
			try {
			  navigateToURL(videoPageRequest, '_blank');
			} catch (e:Error) {
			  trace("Error");
			}
		}
		
		private function headerMoreClick(e:MouseEvent):void {
			if(video.isPlaying()) video.pause();
			
			headerBgResize(true);
			headerDescr.height = stage.stageHeight - headerDescr.y - 40;
			headerDescr.mouseWheelEnabled = true;
			
			scrollBar = new Scroller();
			scrollBar.setTarget(headerDescr);
			header.addChild(scrollBar);
			
			headerMore.visible = false;
			
			// bring to front
			setChildIndex(header, numChildren-1);
			
			// set status var
			headerOpen = true;
		}
		
		private function headerMoreHide():void {
			header.removeChild(scrollBar);
			headerDescr.height = 20;
			headerDescr.scrollV = 1;
			headerDescr.mouseWheelEnabled = false;
			
			headerBgResize(false);
			
			headerMore.visible = true;
			
			// set status var
			headerOpen = false;
		}
		
		private function showHeader():void {
			trace("showHeader()");
			if((embeddedMode || stage.displayState == StageDisplayState.FULL_SCREEN) && !video.isPlaying()) {
				header.visible = true;
			}
		}
		
		private function hideHeader():void {
			trace("hideHeader()");
			try {
				header.visible = false;		// hide header
			} catch (error:Error) {
				trace("header not available");
			}
		}
		
		
		/* ============= */
		/* = ANALYTICS = */
		/* ============= */
		
		public function trackEvent(eventName:String, eventValue:uint = 0):void {
			
			var actionEvents:Array = ["Play"];
			var valueEvents:Array = ["Time Watched", "Percent Watched"];
			var validEvents:Array = actionEvents.concat(valueEvents);
			if(validEvents.indexOf(eventName) == -1) return;
			
			if(trackedEvents.indexOf(eventName) == -1) {
				
				trace("tracking event: " + eventName);
				trace("eventValue", eventValue);
				
				// google analytics
				var category:String = (embeddedMode) ? "Embedded Videos" : "Videos";
				if(valueEvents.indexOf(eventName) != -1) {
					trace('Google Analytics', category, eventName, videoPermalinkId, eventValue);
					processGAEvent(category, eventName, videoPermalinkId, eventValue);
				} else {
					trace('Google Analytics', category, eventName, videoPermalinkId);
					processGAEvent(category, eventName, videoPermalinkId);
				}
				
				// app view count (Play event)
				if(eventName == "Play" && config.trackPlayUrl) {
					var loader:URLLoader = new URLLoader();
					var request:URLRequest = new URLRequest(config.trackPlayUrl);				
					var variables:URLVariables = new URLVariables();
					variables._method = 'post';
					if(videoPermalinkId) variables.permalink = videoPermalinkId;
					if(config.userId) variables.user_id = config.userId;
					request.method = URLRequestMethod.POST;
					request.data = variables;

					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, genericSecurityErrorHandler);
					loader.addEventListener(IOErrorEvent.IO_ERROR, genericIOErrorHandler);
					loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, genericHTTPStatusHandler);

					trace("tracking play event: " + request.url);
					try {
						loader.load(request);
					} catch (error:Error) {
						trace("Unable to load app tracker");
					}
				}
				
				// prevent additional tracking
				trackedEvents.push(eventName);
			}
			
		}
		
		private function processGAEvent(category:String, action:String, label:String, value:Number = NaN) {
			try {
				if(trackingMode == "AS3") {
					if(!isNaN(value)) GoogleTracker.trackEvent(category, action, label, value);
					else GoogleTracker.trackEvent(category, action, label);
				} else {
					if(!isNaN(value)) ExternalInterface.call('_gaq.push', ['_trackEvent', category, action, label, value]);
					else ExternalInterface.call('_gaq.push', ['_trackEvent', category, action, label]);
				}
			} catch (error:Error) {
				trace("Unable to track GoogleAnalytics event", trackingMode, error.toString());
			}
		}
		
		private function genericSecurityErrorHandler(event:SecurityErrorEvent):void {
            trace("genericSecurityErrorHandler: " + event);
        }
        private function genericIOErrorHandler(event:IOErrorEvent):void {
            trace("genericIOErrorHandler: " + event);
        }
		private function genericHTTPStatusHandler(event:HTTPStatusEvent):void {
            trace("genericHTTPStatusHandler: " + event);
        }

		private function startVideoViewTimeTracker():void {
			trace('startVideoViewTimeTracker');
			var now:Date = new Date();
			videoViewTimeStart = now.getTime();
		}
		
		private function stopVideoViewTimeTracker():uint {
			trace('stopVideoViewTimeTracker');
			if(!videoViewTimeStart) return videoViewTime;
			var now:Date = new Date();
			videoViewTime += (now.getTime() - videoViewTimeStart);	// ms
			videoViewTimeStart = 0;	// reset
			trace('videoViewTime', videoViewTime);
			return videoViewTime;
		}
		
		
		/* ======================== */
		/* = STAGE EVENT HANDLERS = */
		/* ======================== */
		
		// RESIZE handler
		private function stageResizeHandler(e:Event):void {
			trace('stageResizeHandler');
			resizePlayer();
		}
		
		private function stageMouseRelease(e:MouseEvent):void {
			trace("stageMouseRelease");
			
			// handle scrub
			if(controls.isScrubbing()) stopScrub();
			
			// handle header close event
			if(headerOpen && !scrollBar.isScrolling()) {
				headerMoreHide();
			}
		}
		
		private function stageMouseLeave(e:Event):void {
			trace('stageMouseLeave');
			mouseOffStage = true;
		}
		
		public function stageMouseMove(e:MouseEvent):void {			// public for YouTubeVideoAPI mouse event workaround
			if (e.stageX >= 0 && e.stageX <= stage.stageWidth && e.stageY >= 0 && e.stageY <= stage.stageHeight) {
				mouseOffStage = false;
				controls.resetTimer();
			}
		}
		
		public function resizePlayer():void {
			trace('resizePlayer', stage.stageWidth, stage.stageHeight)
		
			var resizeMode:String = (stage.displayState == StageDisplayState.FULL_SCREEN) ? 'fullscreen' : 'default';
			
			// redraw controls
			controls.redraw(resizeMode);

			// resize background
			playerBackground.width = stage.stageWidth;
			playerBackground.height = stage.stageHeight;

			// redraw header
			_initHeader();
			
			// resize poster img
			posterImg.width = stage.stageWidth;
			posterImg.height = stage.stageHeight;
			drawPosterImgAttribution();
			
			// reposition play overlay
			playOverlay.x = (stage.stageWidth/2)-(playOverlay.width/2);
			playOverlay.y = (stage.stageHeight/2)-(playOverlay.height/2);
			
			// update video player size
			video.setSize(stage.stageWidth, stage.stageHeight);
		}
		
		
		/* ================= */
		/* = SCRUB METHODS = */
		/* ================= */
		
		internal function startScrub() {
			scrubPlayState = video.isPlaying() ? 'playing' : 'paused';
			if(video.isPlaying()) video.pause();
		}
		internal function stopScrub() {
			if(!video.isLoaded() && video.isReady()) {
				// initial load/play
				video.seekTo(Math.round(controls.getScrubPosition()*videoDuration / stage.stageWidth));
			} else if(scrubPlayState == 'playing') {
				video.play();	// resume video
			}
			scrubPlayState = null;
			controls.stopScrubbing();
		}
		
		
		/* ======================== */
		/* = TIMER EVENT HANDLERS = */
		/* ======================== */

		private function updateDisplay(e:TimerEvent):void {
			try {

				if(video.isLoaded()) {
					
					var currentVideoTime = video.getCurrentTime();
					
					if(segmentChangeLock && currentVideoTime > videoSegments[currentVideoSegmentIdx].time) {
						// target segment start time reached
						segmentChangeLock = false;
						trace('** UNLOCK ** segmentIdx:', currentVideoSegmentIdx, ' current time:', currentVideoTime, 'unlock time:', videoSegments[currentVideoSegmentIdx].time);
					}
				
					if(controls.isScrubbing()) {
						segmentChangeLock = false;
						var targetVideoTime:Number = Math.round(controls.getScrubPosition()*videoDuration / stage.stageWidth);
						if(targetVideoTime != Math.round(currentVideoTime)) {
							trace('SEEKING', targetVideoTime);
							video.seekTo(targetVideoTime);
						}
					} else {
						// determine current segment from video time
						var segmentIdx:Number = 0;
						
						for(var sIdx:Number = videoSegments.length-1; sIdx >= 0; sIdx--) {
							if(currentVideoTime >= videoSegments[sIdx].time) {
								segmentIdx = sIdx;
								break;
							}
						}
						
						if(segmentIdx != currentVideoSegmentIdx) {
							if(!segmentChangeLock) {
								trace('SEGMENT CHANGE');
								updateCurrentVideoSegment(segmentIdx);
							} else {
								trace('segment change event DEFERRED ***');
								trace('current time:', currentVideoTime, 'unlock time:', videoSegments[currentVideoSegmentIdx].time);
							}
						}
						
						// update progress bar display
						controls.updateProgress();
					}
				}
				
			} catch (error:Error) {
				trace('updateDisplay error caught',error);
			}
		}
		
		internal function updateCurrentVideoSegment(segmentIdx:Number):void {
			// update UI
			controls.updateActiveSegment(currentVideoSegmentIdx, segmentIdx);
			// trigger external event
			triggerExternalEvent( { type:'segmentChange', segment:videoSegments[segmentIdx].id } );
			// update var
			currentVideoSegmentIdx = segmentIdx;
			// set lock
			segmentChangeLock = true;
		}

		
		/* ================= */
		/* = USER FEEDBACK = */
		/* ================= */
		
		public function showLoading():void {
			// show loading sym
			loading.x = stage.stageWidth/2;
			loading.y = stage.stageHeight/2+60;
			if(loading.parent == null) addChild(loading);
		}
		
		public function hideLoading():void {
			if(loading.parent != null) removeChild(loading);
		}
		
		private function displayMessage(msg:String):void {
			// display a message to the user
			var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.color = 0xFFFFFF;
            format.size = 14;
            format.align = TextFormatAlign.CENTER;
			
			trace(msg);
			if(userFeedback == "") {
				userFeedbackTF = new TextField();
				userFeedbackTF.width = 320;
				userFeedbackTF.autoSize = TextFieldAutoSize.CENTER;
				userFeedbackTF.defaultTextFormat = format;
				addChild(userFeedbackTF);
			}
			userFeedback += ' '+msg;
			userFeedbackTF.text = userFeedback;
			userFeedbackTF.x = (stage.stageWidth-userFeedbackTF.width)/2;
			userFeedbackTF.y = (stage.stageHeight-userFeedbackTF.height)/2;
			
			// hide play button & controls
			if(playOverlay) playOverlay.visible = false;
			if(controls) controls.visible = false;
		}
		
		
		/* =================== */
		/* = EXTERNAL EVENTS = */
		/* =================== */
		
		internal function triggerExternalEvent(eventObj:Object):Object {
			
			trace("triggerExternalEvent", JSON.encode(eventObj), externalEventHandler);
			
			var result:Object = {};
			
			// add player DOM id
			eventObj.playerId = playerDOMId;
			
			if(externalEventHandler != null) {
                try {
					// call JS function
					result = ExternalInterface.call(externalEventHandler,eventObj);
                } catch (error:SecurityError) {
                    trace("A SecurityError occurred: " + error.message + "\n");
                } catch (error:Error) {
                    trace("An Error occurred: " + error.message + "\n");
                }
			}
			return result;
		}
		
		private function _initExternalCallbacks():void {
			if(ExternalInterface.available) {
				ExternalInterface.addCallback("getCurrentTime", getCurrentTime);
				ExternalInterface.addCallback("seekToSegment", seekToSegment);
				ExternalInterface.addCallback("trackViewTime", trackViewTime);
			}
		}

		// EXTERNAL METHOD
		public function getCurrentTime():Number {
			var currentTime:Number = 0
			try {
				currentTime = video.getCurrentTime();
			} catch(e:Error) {
				currentTime = 0;
			}
			return currentTime;
		}
		
		// EXTERNAL METHOD
		public function seekToSegment(id:String):void {
			trace("seekToSegment, id:" + id);
			var seekTime:Number = 0;
			var segmentIdx:Number = 0;
			for each(var segment:Object in videoSegments) {
				if(segment.id == id) {
					seekTime = segment.time;
					break;
				}
				segmentIdx++;
			}
			try {
				updateCurrentVideoSegment(segmentIdx);
				video.seekTo(seekTime, true);
			} catch(e:Error) {
				trace('seekToSegment ERROR', e.message);
			}
		}
		
		// EXTERNAL METHOD
		public function trackViewTime():void {
			trace("trackViewTime");
			try {
				var videoViewSecs:uint = Math.round(stopVideoViewTimeTracker()/1000);
				if(!videoViewSecs) return;
				trackEvent("Time Watched", videoViewSecs);
				var viewPercent:uint = Math.round((videoViewSecs/videoDuration)*100);
				trackEvent("Percent Watched", viewPercent);
			} catch(e:Error) {
				trace('trackViewTime error', e);
			}
		}
		
	}
	
}