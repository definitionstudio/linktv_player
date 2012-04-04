package com.definition
{
	import flash.display.Sprite;
	import flash.events.*;
	
    import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.net.URLRequest;
	
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.system.Security;
			
	
	// http://support.brightcove.com/en/docs/using-actionscript-flash-only-player-api
	// http://docs.brightcove.com/en/player/com/brightcove/api/modules/VideoPlayerModule.html
	// http://support.brightcove.com/en/docs/player-configuration-parameters
	
	public class BrightcoveVideoAPI extends Sprite implements VideoAPI {
				
		private var player:Player;					// parent
		private var ready:Boolean = false;
		
		private var qualityLevel:Number = 0;		// set initial quality/videofile
		private var qualityLevels:Array = new Array();
		
		private var videoDisplayWidth:Number;
		private var videoDisplayHeight:Number;
		
		public var hidePlayIconOverlay:Boolean = true;
		

		private var videoMetaLoaded:Boolean = false;
		private var videoLoaded:Boolean = false;
		private var videoPlaying:Boolean = false;
		private var videoComplete:Boolean = false;
		
		private var currentVolume:Number = 100;		// default to max volume
		
		// video states (YouTube-compatible)
		const STATE_UNSTARTED = -1;
		const STATE_ENDED = 0;
		const STATE_PLAYING = 1;
		const STATE_PAUSED = 2
		const STATE_BUFFERING = 3;
		const STATE_CUED = 5;
		
		// Brightcove player objects
		private var bcPlayer:Object;
		private var bcVideoPlayer:Object;
		
		
		// constructor
		public function BrightcoveVideoAPI(player:Player, width:Number, height:Number):void {
			
			Security.allowDomain("http://admin.brightcove.com");
			Security.allowDomain("c.brightcove.com");
			
			// set reference
			this.player = player;
			
			videoDisplayWidth = width;
			videoDisplayHeight = height;
		}
		
		// init: call after event listeners are assigned
		public function init():void {
			
			var config:Object = {
				bgcolor: "#000000",
				width: videoDisplayWidth,
				height: videoDisplayHeight,
				isVid: true,
				isUI: true,
				dynamicStreaming: true,
				playerID: player.config.brightcovePlayerId,
				playerKey: player.config.brightcovePlayerKey,
				'@videoPlayer': player.videoFiles[0].path,
				linkBaseURL: player.videoPermalinkURL,
				autoStart: player.videoAutoPlay
			}
			
			createPlayer(config);
		}
		
		private function onPlayerLoadInit(event:Event):void {
			trace('**** onPlayerLoadInit');
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;
			var loader:Loader = loaderInfo.loader;
			bcPlayer = loaderInfo.content as Sprite;	
			addChild(bcPlayer as Sprite);
			if (contains(loader)) removeChild(loader);
		}

		private function onPlayerLoadProgress(event:ProgressEvent):void {
			dispatchEvent(event);
		}

		private function createPlayer(config:Object):void {
			var cacheServerServices:String = "http://c.brightcove.com/services";
			
			var configItems:String = "";
			for (var i:String in config) {
				if (i == "width" || i == "height") continue;
				configItems += "&" + i + "=" + escape(config[i]);
			}

			var file:String = cacheServerServices + "/viewer/federated_f9?" +
				"&playerWidth="+escape(config["width"])+
				"&playerHeight="+escape(config["height"])+
				"&dynamicStreaming=true"+
				"&isVid=1"+
				"&isUI=1"+
				configItems;

			var bcLoader:Loader = new Loader();
			addChild(bcLoader);
			
			bcLoader.contentLoaderInfo.addEventListener(Event.INIT, onPlayerLoadInit);
			bcLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onPlayerLoadProgress);
			var context:LoaderContext = new LoaderContext();
			context.applicationDomain = ApplicationDomain.currentDomain;
			bcLoader.load(new URLRequest(file), context);
		}

		public function onTemplateLoaded():void {
			trace('****** bc onTemplateLoaded');
			dispatchEvent(new Event("templateLoaded"));

			bcVideoPlayer = getModule("videoPlayer");
			bcVideoPlayer.addEventListener("mediaError", onMediaError);
			bcVideoPlayer.addEventListener("mediaChange", onMediaChange);
			bcVideoPlayer.addEventListener("mediaPlay", onMediaPlay);
			bcVideoPlayer.addEventListener("mediaStop", onMediaStop);
			bcVideoPlayer.addEventListener("mediaComplete", onMediaComplete);
			bcVideoPlayer.addEventListener("mediaBufferBegin", onMediaBufferBegin);
			bcVideoPlayer.addEventListener("mediaBufferComplete", onMediaBufferComplete);
			
			player.videoContainer.addChild(this);
			
			ready = true;						// video is ready for playback
			dispatchEvent(new Event("ready"));	// dispatch custom ready event
		}

		public function getModule(module:String):Object {
			return Object(bcPlayer).getModule(module);
		}
		
		// Brightcove media event listeners
		
		function onMediaError(event:Event):void {
			videoPlaying = false;
			dispatchEvent(new CustomEvent("error", false, false, {message:"The video could not be loaded."}));
		}
		function onMediaChange(event:Event):void {
			videoLoaded = true;					// initial load action
			dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_CUED}));
		}
		function onMediaPlay(event:Event):void {
			videoPlaying = true;
			dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_PLAYING}));
		}
		function onMediaStop(event:Event):void {
			videoPlaying = false;
			dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_PAUSED}));
		}
		function onMediaComplete(event:Event):void {
			videoPlaying = false;
			dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_ENDED}));
		}
		function onMediaBufferBegin(event:Event):void {
			dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_BUFFERING}));
		}
		function onMediaBufferComplete(event:Event):void {
			dispatchEvent(new CustomEvent("stateChange", false, false, {state:STATE_PLAYING}));
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
		
		public function hasControls():Boolean {
			return true;
		}
		
		public function getCurrentTime():Number {
			return (isLoaded()) ? bcVideoPlayer.getVideoPosition() : player.videoStart;
		}
		
		public function getDuration():Number {
			return (isLoaded()) ? bcVideoPlayer.getVideoDuration() : player.videoDuration;
		}
		
		public function getVolume():Number {
			return currentVolume;
			//return YouTubePlayer.getVolume();		// 0-100
		}
		
		public function getBytesLoaded():Number {
			return bcVideoPlayer.getVideoBytesLoaded();
		}
		
		public function getBytesTotal():Number {
			return bcVideoPlayer.getVideoBytesTotal();
		}
		
		public function getQualityLevels():Array {
			return qualityLevels;
		}
		
		// playback controls
		
		public function play():void {
			if(videoComplete) videoComplete = false;
			bcVideoPlayer.play();
		}
		
		public function pause():void {
			bcVideoPlayer.pause();
		}
		
		public function mute():void {
			bcVideoPlayer.mute(true);
		}
		
		public function unMute():void {
			bcVideoPlayer.mute(false);
		}
		
		public function seekTo(seconds:int, autoPlay:Boolean=false):void {
			bcVideoPlayer.seek(seconds);
			if(autoPlay && !videoPlaying) play();
		}
		
		// resize
		
		public function setSize(width:Number, height:Number):void {
			trace('setSize');
			bcVideoPlayer.setSize(width, height);
		}
		
		public function setQualityLevel(level:*):void {		// string-based quality
		}
		
	}
	
}