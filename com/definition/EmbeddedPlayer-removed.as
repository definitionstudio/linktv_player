package com.definition
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
    import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	

	import flash.display.Loader;
	
	
	import com.definition.Globals;
	
		
	public class EmbeddedPlayer extends Sprite {
		
		public var configXML_url:String;
		
		public var playerLoader:Loader;
		public var player:Object;
		
		// constructor
		public function EmbeddedPlayer() {
			
			Globals.EmbeddedPlayer = true;
			Globals.FlashVars = this.loaderInfo.parameters;		// pass URL and flashVar params
				
			trace("embedded player loading");
			
			// generate timestamp for anti-caching
			var now:Date = new Date();
			var timestamp:Number = now.getTime();

			// parse remote host			
			var siteHost:String = (Globals.FlashVars['host'] != undefined) ? Globals.FlashVars['host'] : '';

			if(siteHost != '') Globals.FlashVars['configUrl'] = siteHost + Globals.FlashVars['configUrl'];	// full URL for remote embeds
			
			var playerUrl:String = siteHost + Globals.FlashVars['player'] + '?nocache=' + timestamp;	// anti-cache param
			trace(playerUrl);
			
			playerLoader = new Loader();
			playerLoader.contentLoaderInfo.addEventListener(Event.INIT, initListener);
			playerLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			playerLoader.load(new URLRequest(playerUrl));
			
		}
		
		private function initListener (e:Event):void{
			trace("Player Initialized");
			addChild(playerLoader.content);
			player = playerLoader.content;
			//player.init({'configUrl': configXML_url});
			player.init();
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
            trace("ioErrorHandler: " + event);
			
			// TODO: display error
			
        }
		
	}
	
	
}