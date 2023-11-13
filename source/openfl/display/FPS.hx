package openfl.display;

import haxe.Timer;

import openfl.display.FPS;

import openfl.events.Event;

import openfl.system.System;

import openfl.text.TextField;

import openfl.text.TextFormat;

import flixel.math.FlxMath;

import flixel.util.FlxColor;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/

class FPS extends TextField

{

    private var times:Array<Float>;

    private var memPeak:Float = 0;



    public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000) 

    {

        super();
        x = inX;
        y = inY;
        selectable = false;
        defaultTextFormat = new TextFormat("_sans", 12, inCol);
        text = "FPS: ";
        times = [];
        addEventListener(Event.ENTER_FRAME, onEnter);
        width = 150;
        height = 70;

    }
	
	var array:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 255),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(255, 255, 0),
		FlxColor.fromRGB(255, 127, 0),
		FlxColor.fromRGB(255, 0, 0)
	];

	var skippedFrames = 0;

	public static var currentColor = 0;

    private function onEnter(_)

    {
		
        var now = Timer.stamp();
        times.push(now);
        while (times[0] < now - 1)

            times.shift();

        //var mem:Float = Math.abs(Math.round(System.totalMemory / 1024 / 1024 * 100) / 100);
        var mem:Float = Math.abs(Math.round(System.totalMemory / (1e+6)));
		
		textColor = 0xFFFFFFFF;
		if (mem > 3000 || times.length <= ClientPrefs.data.framerate / 2) {
			textColor = 0xFFFF0000;
		}

        if (mem > memPeak) memPeak = mem;
        if (visible)
        {
            text = times.length + " FPS \nRAM: " + mem + " MB / " + memPeak + " MB\nREDUX v" + states.MainMenuState.funkinReduxVersion;
        }
    }
}