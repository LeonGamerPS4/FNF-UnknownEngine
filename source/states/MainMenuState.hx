package states;

import flixel.util.FlxTimer;
import flixel.util.FlxGradient;

import flixel.FlxObject;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import flixel.group.FlxGroup.FlxTypedGroup;

import lime.app.Application;
import flixel.math.FlxMath;

import states.editors.MasterEditorMenu;
import options.OptionsState;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var unknownEngineVersion:String = '2.5 Beta'; // Used for updating and also PlayState
	public static var micdUpVersion:String = '2.0.3';
	public static var psychEngineVersion:String = '0.7.2';

	public static var curSelected:Int = 0;
	public static var nightly:String = "a";

	private var camMenu:FlxCamera;
	private var camAchievement:FlxCamera;
	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
		'play',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('mBG_Main'));
	var beef:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('doodle'));
	var side:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('Main_Side'));

	public var menuItem:FlxSprite;
	public var yScroll:Float;
	
	var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(95, 80, 190, 160, true, 0x33FC03DB, 0x0));
	
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 300, 0xFFAA00AA);
	
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	
	var isTweening:Bool = false;
	var lastString:String = '';
	var camLerp:Float = 0.1;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();
		
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		
		if(FlxG.sound.music != null)
			if (!FlxG.sound.music.playing)
			{	
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
        		FlxG.sound.music.time = 9400;
				FlxTween.tween(FlxG.sound.music, {volume: 0.7}, 0.4);
			}

		camMenu = initPsychCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camMenu];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		yScroll = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.angle = 179;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		
		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x55AE59E4, 0xAA19ECFF], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);
		
		grid.velocity.set(45, 16);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);
		grid.scrollFactor.set(0, 0.07);

		beef.scrollFactor.x = 0;
		beef.scrollFactor.y = 0;
		beef.antialiasing = true;
		beef.setGraphicSize(Std.int(bg.width * 0.32));
		beef.updateHitbox();
		beef.screenCenter();
		beef.x = 1000;
		beef.y = 115;
		add(beef);

		side.scrollFactor.x = 0;
		side.scrollFactor.y = 0;
		side.setGraphicSize(Std.int(side.width * 0.75));
		side.updateHitbox();
		side.screenCenter();
		side.antialiasing = true;
		side.x = -500;
		side.y = -90;
		add(side);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;

		for (i in 0...optionShit.length)
		{
			menuItem = new FlxSprite(0, (i * 70));
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			FlxTween.tween(menuItem, {x: menuItem.width / 4 + (i * 60) - 55}, 1.3, {ease: FlxEase.expoInOut});
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
				
			menuItem.scale.set(0.8, 0.8);
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.updateHitbox();
		}

		camMenu.follow(camFollow, null, camLerp);

		camMenu.zoom = 3;
		FlxTween.tween(camMenu, {zoom: 1}, 1.1, {ease: FlxEase.expoInOut});
		FlxTween.tween(bg, {angle: 0}, 1, {ease: FlxEase.quartInOut});
		FlxTween.tween(side, {x: -80}, 0.9, {ease: FlxEase.quartInOut});
		FlxTween.tween(beef, {x: 725}, 0.9, {ease: FlxEase.quartInOut});

		camMenu.follow(camFollowPos, null, 1);
		
		#if !html5
		var psychVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var unknownVer:FlxText = new FlxText(12, FlxG.height - 24, 1250, "Unknown Engine v" + Application.current.meta.get('version') + " \\ Friday Night Funkin' v0.2.8", 12);
		unknownVer.scrollFactor.set();
		unknownVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(unknownVer);
		var micdUpVer:FlxText = new FlxText(12, FlxG.height - 24,  FlxG.width - 24, "Mic'd Up v" + micdUpVersion, 12);
		micdUpVer.scrollFactor.set();
		micdUpVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(micdUpVer);
		#else
		var piracyVer:FlxText = new FlxText(12, FlxG.height - 44, 1250, "this is not an official unknown engine build.\nthis might be pirated lol.", 12);
		piracyVer.scrollFactor.set();
		piracyVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(piracyVer);
		#end

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end
		
		#if desktop
		MusicBeatState.windowNameSuffix = " - Main Menu";
		#end

		super.create();
		
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			selectable = true;
		});
	}

	var selectable:Bool = false;
	var selectedSomethin:Bool = false;
	var timer:Float = 0;

	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		FlxG.watch.addQuick("beatShit", curBeat);
	
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.scale.set(FlxMath.lerp(spr.scale.x, 0.8, camLerp / (ClientPrefs.data.framerate / 60)),
				FlxMath.lerp(spr.scale.y, 0.8, 0.4 / (ClientPrefs.data.framerate / 60)));
			spr.y = FlxMath.lerp(spr.y, -20 + (spr.ID * 100), 0.4 / (ClientPrefs.data.framerate / 60));

			if (spr.ID == curSelected)
			{
				spr.scale.set(FlxMath.lerp(spr.scale.x, 1.1, camLerp / (ClientPrefs.data.framerate / 60)),
					FlxMath.lerp(spr.scale.y, 1.1, 0.4 / (ClientPrefs.data.framerate / 60)));
				spr.y = FlxMath.lerp(spr.y, -90 + (spr.ID * 100), 0.4 / (ClientPrefs.data.framerate / 60));
			}

			spr.updateHitbox();
		});

		if (!selectedSomethin && selectable)
		{
			var shiftMult:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftMult = 3;

			if (FlxG.mouse.wheel != 0)
				changeItem(-FlxG.mouse.wheel);
			
			if (controls.UI_UP_P)
			{
				changeItem(-shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				changeItem(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeItem((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || FlxG.mouse.justPressedRight)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;

					menuItems.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(camMenu, {zoom: 10}, 1.6, {ease: FlxEase.expoIn});
						FlxTween.tween(bg, {angle: 90}, 1.6, {ease: FlxEase.expoIn});
						FlxTween.tween(spr, {x: -600}, 0.6, {
							ease: FlxEase.backIn,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
						FlxTween.tween(side, {x: -500}, 1.2, {ease: FlxEase.quartInOut});
						FlxTween.tween(beef, {x: 1000}, 1.2, {ease: FlxEase.quartInOut});
						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							var daChoice:String = optionShit[curSelected];

							switch (daChoice)
							{
								case 'play':
									MusicBeatState.switchState(new GamemodesMenuState());
								#if MODS_ALLOWED
								case 'mods':
									MusicBeatState.switchState(new ModsMenuState());
								#end
								case 'awards':
									MusicBeatState.switchState(new AchievementsMenuState());
								case 'credits':
									MusicBeatState.switchState(new CreditsState());
								case 'options':
									options.OptionsState.onPlayState = false;
									
									if (PlayState.SONG != null)
									{
										PlayState.SONG.arrowSkin = null;
										PlayState.SONG.splashSkin = null;
									}
									
									LoadingState.loadAndSwitchState(new options.OptionsState());
									FlxG.sound.music.stop();
                                    FlxG.sound.music == null;
							}
						});
					});
					
					for (i in 0...menuItems.members.length)
					{
						if (i == curSelected)
							continue;
						FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								menuItems.members[i].kill();
							}
						});
					}
				}
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
			}
			#end
		}

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.ID == curSelected)
			{
				camFollow.y = FlxMath.lerp(camFollow.y, spr.getGraphicMidpoint().y, camLerp / (ClientPrefs.data.framerate / 60));
				camFollow.x = spr.getGraphicMidpoint().x;
			}
		});
		
		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();
		
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
	}
}