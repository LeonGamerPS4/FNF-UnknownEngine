package substates;

import flixel.FlxObject;
import flixel.FlxG;
import flixel.FlxSprite;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import flixel.group.FlxGroup.FlxTypedGroup;

import flixel.math.FlxMath;

import flixel.util.FlxTimer;
import flixel.util.FlxGradient;
import flixel.util.FlxColor;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.PlayState;

import backend.ClientPrefs;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.Note;

//import seedyrng.Random;

using StringTools;

class ChartSubstate extends MusicBeatSubstate
{
    var menuItems:FlxTypedGroup<FlxSprite>;
    var optionShit:Array<String> = ['standard', 'flip', 'chaos'/*, 'onearrow', 'dualarrow', 'dualchaos', 'stair', 'wave'*/];
    var selectedSomethin:Bool = false;
    public static var curSelected:Int = 0;
    var camFollow:FlxObject;
    var camLerp:Float = 0.32;

    var boombox:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('Boombox'));
    var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(95, 80, 190, 160, true, 0x338F34EB, 0x0));
	var gradientBar:FlxSprite = new FlxSprite(0,0).makeGraphic(FlxG.width, 300, 0xFFAA00AA);

    var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	
	public static var flip:Bool = false;
	public static var chaos:Bool = false;

    public function new()
    {
        super();

        add(blackBarThingie);
        blackBarThingie.scrollFactor.set();

        gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x55FF70E7, 0xAA94EBFF], 1, 90, true); 
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);

		grid.velocity.set(40, 40);
		add(grid);
		grid.scrollFactor.set(0.07, 0.07);

        gradientBar.alpha = grid.alpha = 0;
        FlxTween.tween(grid, { alpha:1}, 1.2, { ease: FlxEase.quartInOut});
        FlxTween.tween(gradientBar, { alpha:1}, 1.2, { ease: FlxEase.quartInOut});

        menuItems = new FlxTypedGroup<FlxSprite>();
        add(menuItems);
        
		var tex = Paths.getSparrowAtlas('chartTypes');

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(-250, 30);
			menuItem.frames = tex;
            menuItem.animation.addByPrefix('idle', optionShit[i] + " idle", 24, true);
            menuItem.animation.addByPrefix('select', optionShit[i] + " select", 24, true);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
            menuItem.y = 720 + i * menuItem.height;
			menuItem.scrollFactor.set();
            menuItem.antialiasing = true;
            menuItem.scrollFactor.x = 0;
            menuItem.scrollFactor.y = 1;

            menuItem.x = 2000;
            FlxTween.tween(menuItem, { x: 800}, 0.15, { ease: FlxEase.expoInOut });
        }

        camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

        new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				selectable = true;
                FlxG.camera.follow(camFollow, null, camLerp);
			});
    }

    var selectable:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        boombox.screenCenter();

        if (selectable && !selectedSomethin)
        {
            if (controls.UI_UP_P)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'));
                changeItem(-1);
            }
    
            if (controls.UI_DOWN_P)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'));
                changeItem(1);
            }

            if (controls.BACK)
                {
                    FlxG.resetState();
                    selectedSomethin = true;
                }
        
            if (controls.ACCEPT)
            {
                selectedSomethin = true;

                FlxG.sound.playMusic(Paths.music("titleShoot"));

                if (optionShit[curSelected] == 'flip')
				{
					flip = true;
					chaos = false;
				}
				else if (optionShit[curSelected] == 'chaos')
				{
					flip = false;
					chaos = true;
				}
				else
				{
					flip = false;
					chaos = false;
				}
				
                FlxG.sound.play(Paths.sound('confirmMenu'));

                #if sys
				DiscordClient.changePresence("Time to play!", null);
                #end

                FlxG.sound.music.fadeOut(2.1, 0);

                FlxTween.tween(FlxG.camera, { zoom:1.4}, 1.3, { ease: FlxEase.quartInOut});
                FlxTween.tween(camFollow, { y:5000}, 1.3, { ease: FlxEase.quartInOut});

                add(boombox);
			    boombox.scale.set(0,0);
                boombox.scrollFactor.set();
			    boombox.alpha = 0;

                //PlayState.chartType = Std.string(optionShit[curSelected]);

				FlxTween.tween(boombox, { alpha:1, 'scale.x':0.5, 'scale.y':0.5}, 1.3, { ease: FlxEase.quartInOut});

			    new FlxTimer().start(2.1, function(tmr:FlxTimer)
				{
                    FlxG.sound.music.stop();
                    FlxG.sound.music.kill();
					boombox.visible = false;
					if (FlxG.keys.pressed.SHIFT) {
						LoadingState.loadAndSwitchState(new ChartingState());
					} else {
						LoadingState.loadAndSwitchState(new PlayState());
					}
				});
            }
        }

        menuItems.forEach(function(spr:FlxSprite)
            {
                if (spr.ID == curSelected && !selectedSomethin && selectable)
                {
                    camFollow.y = FlxMath.lerp(camFollow.y, spr.getGraphicMidpoint().y, camLerp/(ClientPrefs.data.framerate/60));
                    camFollow.x = 0;
                    spr.x = FlxMath.lerp(spr.x, -1300, camLerp/(ClientPrefs.data.framerate/60));
                }

                spr.x = FlxMath.lerp(spr.x, 600, camLerp/(ClientPrefs.data.framerate/60));
            });
    }

    function changeItem(huh:Int = 0)
        {
            curSelected += huh;
        
            if (curSelected >= menuItems.length)
                curSelected = 0;
            if (curSelected < 0)
                curSelected = menuItems.length - 1;

            menuItems.forEach(function(spr:FlxSprite)
                {
                    spr.animation.play('idle');
        
                    if (spr.ID == curSelected)
                    {
                        spr.animation.play('select'); 
                    }
            
                    spr.updateHitbox();
                });
        }
}