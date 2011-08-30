package com.definition
{
	import flash.display.Sprite;
	import flash.events.*;
	
    import flash.display.Loader;
	import flash.net.URLRequest;
	
	import flash.system.Security;
			
	
	// http://code.google.com/apis/youtube/flash_api_reference.html
	
	public class YouTubeVideoAPI extends Sprite implements VideoAPI {
		
		// allow access to YouTube API
		Security.allowDomain("www.youtube.com");
		
		private var player:Player;					// parent
		private var ready:Boolean = false;
		
		private var qualityLevel:Number = 0;		// set initial quality/videofile
		private var qualityLevels:Array = new Array();
		
		const QUALITY_DEFAULT = 'medium';
		const QUALITY_HIGH = 'large';
		
		private var videoDisplayWidth:Number;
		private var videoDisplayHeight:Number;
		
		public var hidePlayIconOverlay:Boolean = true;
		

		private var videoMetaLoaded:Boolean = false;
		private var videoLoaded:Boolean = false;
		private var videoPlaying:Boolean = false;
		private var videoComplete:Boolean = false;
		
		private var currentVolume:Number = 100;		// default to max volume
		
		// YouTube loader
		private var loader:Loader;
		private var YouTubePlayer:Object;
		
		// video states (YouTube)
		const STATE_UNSTARTED = -1;
		const STATE_ENDED = 0;
		const STATE_PLAYING = 1;
		const STATE_PAUSED = 2
		const STATE_BUFFERING = 3;
		const STATE_CUED = 5;


		// custom mouse event listener vars (workaround)
		private var mouseEventOverlay:Sprite;
		private var youtubeLogoWidth:uint = 95;		// don't cover YouTube logo (TOS)
		
		
		// constructor
		public function YouTubeVideoAPI(player:Player, width:Number, height:Number):void {
			
			// set reference
			this.player = player;
			
			videoDisplayWidth = width;
			videoDisplayHeight = height;
			
			// set default quality level
			qualityLevel = QUALITY_DEFAULT;
		}
		
		// init: call after event listeners are assigned
		public function init():void {
			
			// load the YouTube AS3 chromeless player
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT, onLoaderInit);
			loader.load(new URLRequest("http://www.youtube.com/apiplayer?version=3"));
			
			// add to hierarchy
			player.videoContainer.addChild(loader);

			// setup mouse event area to workaround YT chromeless player stage mouse event blackhole (stage.mouseMove event doesn't fire over player)
			mouseEventOverlay = new Sprite();
			mouseEventOverlay.addChild(Utilities.drawBox({color:0xFFFFFF, alpha:0, width:1, height:1}));
			player.videoContainer.addChild(mouseEventOverlay);
			mouseEventOverlay.addEventListener(MouseEvent.MOUSE_MOVE, player.stageMouseMove);
		}
		
		function onLoaderInit(event:Event):void {
			loader.content.addEventListener("onReady", onPlayerReady);
			loader.content.addEventListener("onError", onPlayerError);
			loader.content.addEventListener("onStateChange", onPlayerStateChange);
			loader.content.addEventListener("onPlaybackQualityChange", onVideoPlaybackQualityChange);
		}
		
		function onPlayerReady(event:Event):void {
			// Event.data contains the event parameter, which is the Player API ID 
			trace("player ready:", Object(event).data);
		
			// Once this event has been dispatched by the player, we can use
			// cueVideoById, loadVideoById, cueVideoByUrl and loadVideoByUrl
			// to load a particular YouTube video.
			YouTubePlayer = loader.content;
			
			// Set appropriate player dimensions for your application
			setSize(videoDisplayWidth, videoDisplayHeight);
			
			// url formats supported:
			//	http://www.youtube.com/v/hDcnBeY_t3c
			//	http://www.youtube.com/watch?v=hDcnBeY_t3c
			
			// get video ID from URL
			var url:String = player.videoFiles[0].path;
			var ytVideoId:String = null;
			
			trace('loading youtube url', url);
			
			// parse URL (preferred format)
			var urlPattern1:RegExp = /http:\/\/www.youtube.com\/v\/(.+)$/i;
			var result1:Object = urlPattern1.exec(url);
			if(result1 != null) ytVideoId = result1[1];
			
			// parse URL (alternate format)
			if(ytVideoId == null) {
				trace('trying YouTube URL alternate format');
				var urlPattern2:RegExp = /v=(.+)&?/i;
				var result2:Object = urlPattern2.exec(url);
				if(result2 != null) ytVideoId = result2[1];
			}
			
			trace('ytVideoId', ytVideoId);
			
			if(ytVideoId != null) {
				// cue video
				YouTubePlayer.cueVideoById(ytVideoId, player.videoStart, QUALITY_DEFAULT);
			} else {
				// error
				dispatchEvent(new CustomEvent("error", false, false, {message:"The YouTube video ID could not be fetched from the URL."}));
			}
		}
		
		function onPlayerError(event:Event):void {
			// Event.data contains the event parameter, which is the error code
			var errorCode:Number = Object(event).data;
			
			trace("player error:", errorCode);
			var errorMsg:String = "YouTube API error code " + errorCode;
			
			switch(errorCode) {
				case 2:
					errorMsg = "The requested YouTube video was not found (invalid ID).";
					break;
				case 100:
					errorMsg = "The requested YouTube video was not found or has been removed.";
					break;
				case 101:
					errorMsg = "The requested YouTube video does not allow playback in embedded players.";
					break;
				case 150:
					// same as 101
					errorMsg = "The requested YouTube video does not allow playback in embedded players.";
					break;
			}
			
			// dispatch custom error event
			dispatchEvent(new CustomEvent("error", false, false, {message:errorMsg}));
					
			// reset status var
			ready = false;
			
		}
		
		function onPlayerStateChange(event:Event):void {
			// Event.data contains the event parameter, which is the new player state
			
			var playerState:Number = Object(event).data;
			
			trace("youtube API player state:", playerState);
			
			// evaluate playing status
			if(playerState == STATE_PLAYING) {
				// update status
				videoLoaded = true;		// initial load action
				videoPlaying = true;
				
				// get metadata
				if(!videoMetaLoaded) {
					var duration:Number = YouTubePlayer.getDuration();
					trace('playing video duration:', duration);
					if(duration > 0) {
						videoMetaLoaded = true;
						// update player duration & redraw controls (required to draw quality controls)
						player.videoDuration = duration;
						player.controls.redraw();
					}
				}
			} else if(playerState != STATE_BUFFERING) {		// state will intermittently report buffering after playback has begun
				videoPlaying = false;
			}
			
			if(playerState == STATE_CUED) {
				ready = true;						// video is ready for playback
				dispatchEvent(new Event("ready"));	// dispatch custom ready event
			}
			
			if(playerState == STATE_ENDED) {
				videoComplete = true;
			}
			
			// dispatch custom event
			dispatchEvent(new CustomEvent("stateChange", false, false, {state:playerState}));
			
		}
		
		function onVideoPlaybackQualityChange(event:Event):void {
			// Event.data contains the event parameter, which is the new video quality
			trace("video quality changed:", Object(event).data);
		}
		
		
		// getters
		
		public function isReady():Boolean {
			return ready;
		}
		
		public function isLoaded():Boolean {
			return videoLoaded;
		}
		
		public function isPlaying():Boolean {
			return videoPlaying;
		}
		
		public function isComplete():Boolean {
			return videoComplete;
		}
		
		public function hasBusyIndicator():Boolean {
			return true;
		}
		
		public function hasPosterImage():Boolean {
			return true;
		}
		
		public function getCurrentTime():Number {
			return (isLoaded()) ? YouTubePlayer.getCurrentTime() : player.videoStart;
		}
		
		public function getDuration():Number {
			return player.videoDuration;
		}
		
		public function getVolume():Number {
			return currentVolume;
			//return YouTubePlayer.getVolume();		// 0-100
		}
		
		public function getBytesLoaded():Number {
			return YouTubePlayer.getVideoBytesLoaded();
		}
		
		public function getBytesTotal():Number {
			return YouTubePlayer.getVideoBytesTotal();
		}
		
		public function getQualityLevels():Array {
			if(ready) qualityLevels = YouTubePlayer.getAvailableQualityLevels();
			return qualityLevels;
		}
		
		// playback controls
		
		public function play():void {
			YouTubePlayer.playVideo();
		}
		
		public function pause():void {
			YouTubePlayer.pauseVideo();
		}
		
		public function mute():void {
			YouTubePlayer.mute();
		}
		
		public function unMute():void {
			YouTubePlayer.unMute();
		}
		
		public function seekTo(seconds:int):void {
			YouTubePlayer.seekTo(seconds, true);		// seconds:Number, allowSeekAhead:Boolean
		}
		
		// resize
		
		public function setSize(width:Number, height:Number):void {
			trace('YouTubeVideoAPI.setSize');
			YouTubePlayer.setSize(width, height);
			
			// resize mouse event target
			mouseEventOverlay.width = width-youtubeLogoWidth;
			mouseEventOverlay.height = height/3;
			mouseEventOverlay.x = 0;
			mouseEventOverlay.y = height - mouseEventOverlay.height;
		}
		
		
		public function setQualityLevel(level:*):void {		// string-based quality
						
			trace("YouTube: set quality level: " + level);
			
			YouTubePlayer.setPlaybackQuality(level);
			
		}
		
	}
	
}