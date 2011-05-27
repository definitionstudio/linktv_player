package com.definition
{
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.utils.ByteArray;
		
	public class Utilities {
		
		public static function convertHexColor(hexColorStr:String):uint {	// ex. '#FF0000'
			var color:uint = parseInt(hexColorStr.replace(/#/,"0x"),16);
			return color;
		}
		
		public static function drawBox(params:Object):Shape {		// params: color, alpha, width, height
			var box:Shape = new Shape(); 
			box.graphics.beginFill(params.color, params.alpha);
			box.graphics.drawRect(0, 0, params.width, params.height); 
			box.graphics.endFill(); 
			return box;
		}
		
		public static function formatTime(secs:Number):String {
			var mins:Number = Math.floor(secs/60);
			var minutes:String = mins.toString();
			if(mins < 10) minutes = "0" + minutes;		// leading 0 on mins
			secs = Math.floor(secs%60);
			var seconds:String = secs.toString();
			if(secs < 10) seconds = "0" + seconds;		// leading 0 on seconds
			return minutes + ":" + seconds;
		}
		
		public static function copyObject(o:Object):Object {
			var bytes:ByteArray = new ByteArray();
			bytes.writeObject(o);
			bytes.position = 0;
			return bytes.readObject();
		}
		
		public static function stripHTML(value:String):String {
			return value.replace(/<.*?>/g, "");
		}
		
	}
	
}