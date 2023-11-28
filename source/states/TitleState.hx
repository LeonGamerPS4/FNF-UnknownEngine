package states;

import backend.ColorblindFilters;
import backend.WeekData;
import backend.Highscore;

import flixel.util.FlxGradient;
import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import shaders.ColorSwap;

import states.StoryMenuState;
import states.OutdatedState;
import states.MainMenuState;

typedef TitleData =
{

	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	
	public static var isPlaying:Bool = false;

	var blackScreen:FlxSprite;
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 1, 0xFFAA00AA);
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var FNF_Logo:FlxSprite;
	var UE_Logo:FlxSprite;
	var psychSpr:FlxSprite;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];
	
	var gradientTimer:Float = 0;

	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	var easterEggKeys:Array<String> = [
		'BOYFRIEND'
	];
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	var mustUpdate:Bool = false;

	var titleJSON:TitleData;

	public static var updateVersion:String = '';

	override public function create():Void
	{
		Paths.clearStoredMemory();

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		swagShader = new ColorSwap();
		super.create();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();

		#if CHECK_FOR_UPDATES
		if(ClientPrefs.data.checkForUpdates && !closedState) {
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/LeonGamerPS4/FNF-UnknownEngine/main/gitVersion.txt");

			http.onData = function (data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.unknownEngineVersion.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion) {
					trace('versions arent matching!');
					mustUpdate = true;
				}
			}

			http.onError = function (error) {
				trace('error: $error');
			}

			http.request();
		}
		#end

		Highscore.load();

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		#if TITLE_SCREEN_EASTER_EGG
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention
		switch(FlxG.save.data.psychDevsEasterEgg.toUpperCase())
		{
			case 'SHADOW':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'RIVER':
				titleJSON.gfx += 180;
				titleJSON.gfy += 40;
			case 'BBPANZU':
				titleJSON.gfx += 45;
				titleJSON.gfy += 100;
		}
		#end

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				//trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			if (initialized)
				startIntro();
			else
			{
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					startIntro();
				});
			}
		}
		#end
	}

	var logoBl:FlxSprite;
	var logo:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	function startIntro()
	{
		if (!initialized)
		{
			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}
		
		ColorblindFilters.applyFiltersOnGame();

		Conductor.bpm = titleJSON.bpm;
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
		}else{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}

		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		swagShader = new ColorSwap();
		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		gfDance.y = 1000;

		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		if(easterEgg == null) easterEgg = ''; //html5 fix

		switch(easterEgg.toUpperCase())
		{
			#if TITLE_SCREEN_EASTER_EGG
			case 'SHADOW':
				gfDance.frames = Paths.getSparrowAtlas('ShadowBump');
				gfDance.animation.addByPrefix('danceLeft', 'Shadow Title Bump', 24);
				gfDance.animation.addByPrefix('danceRight', 'Shadow Title Bump', 24);
			case 'RIVER':
				gfDance.frames = Paths.getSparrowAtlas('RiverBump');
				gfDance.animation.addByIndices('danceLeft', 'River Title Bump', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'River Title Bump', [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			case 'BBPANZU':
				gfDance.frames = Paths.getSparrowAtlas('BBBump');
				gfDance.animation.addByIndices('danceLeft', 'BB Title Bump', [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'BB Title Bump', [27, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], "", 24, false);
			#end

			default:
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
				gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
				gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		}

		add(gfDance);
		
		if (FileSystem.exists(Paths.modsImages('logoBumpin')) && !FileSystem.exists(Paths.modsImages('titlelogo'))) {
			logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
			logoBl.frames = Paths.getSparrowAtlas('logoBumpin');

			logoBl.antialiasing = ClientPrefs.data.antialiasing;
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logoBl.animation.play('bump');
			logoBl.updateHitbox();

			add(logoBl);
		} else {
			logo = new FlxSprite().loadGraphic(Paths.image('titlelogo'));
			logo.x = 250;
			logo.y = 100;
			logo.antialiasing = ClientPrefs.data.antialiasing;
			add(logo);
		}
		
		if(swagShader != null)
		{
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
			logo.shader = swagShader.shader;
			gradientBar.shader = swagShader.shader;
		}

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.screenCenter();
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);
	
		FNF_Logo = new FlxSprite(0, 0).loadGraphic(Paths.image('FNF_Logo'));
		UE_Logo = new FlxSprite(0, 0).loadGraphic(Paths.image('UE_Logo'));
		add(FNF_Logo);
		add(UE_Logo);
		UE_Logo.scale.set(0.6, 0.6);
		FNF_Logo.scale.set(0.6, 0.6);
		UE_Logo.updateHitbox();
		FNF_Logo.updateHitbox();
		UE_Logo.antialiasing = true;
		FNF_Logo.antialiasing = true;

		UE_Logo.x = -1500;
		UE_Logo.y = 300;
		FNF_Logo.x = -1500;
		FNF_Logo.y = 300;
		
		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x553D0468, 0xAABF1943], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		gradientBar.scale.y = 0;
		gradientBar.updateHitbox();
		add(gradientBar);
		FlxTween.tween(gradientBar, {'scale.y': 1.3}, 4, {ease: FlxEase.quadInOut});

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		psychSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('psych_logo'));
		add(psychSpr);
		psychSpr.visible = false;
		psychSpr.setGraphicSize(Std.int(psychSpr.width * 0.8));
		psychSpr.updateHitbox();
		psychSpr.screenCenter(X);

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt', Paths.getSharedPath());
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
        FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, 0.95);
		
		gradientTimer += 1;
		gradientBar.scale.y += Math.sin(gradientTimer / 10) * 0.001;
		gradientBar.updateHitbox();
		gradientBar.y = FlxG.height - gradientBar.height;
		// gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), Math.round(gradientBar.height), [0x00ff0000, 0xaaAE59E4, 0xff19ECFF], 1, 90, true);
		
		if (skippedIntro)
			logo.angle = Math.sin(gradientTimer / 270) * 5 / (ClientPrefs.data.framerate / 60);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (newTitle) {
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		// EASTER EGG

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				FlxG.camera.zoom += 0.090;
                FlxTween.tween(FlxG.camera, {zoom: 1.04}, 0.2, {ease: FlxEase.cubeInOut, type: ONESHOT, startDelay: 0});
                FlxTween.tween(FlxG.camera, {zoom: 1}, 0.2, {ease: FlxEase.cubeInOut, type: ONESHOT, startDelay: 0.25});
				FlxTween.tween(gfDance, {y:2000}, 2.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(titleText, {y: 2000}, 2.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(gradientBar, {y: 2000}, 2.5, {ease: FlxEase.expoInOut});
	        	if (logoBl != null) FlxTween.tween(logoBl, {alpha: 0}, 1.2, {ease: FlxEase.expoInOut});
				if (logoBl != null) FlxTween.tween(logoBl, {y: 2000}, 2.5, {ease: FlxEase.expoInOut});
	        	if (logo != null) FlxTween.tween(logo, {alpha: 0}, 1.2, {ease: FlxEase.expoInOut});
				if (logo != null) FlxTween.tween(logo, {y: 2000}, 2.5, {ease: FlxEase.expoInOut});

				transitioning = true;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					if (mustUpdate) {
						MusicBeatState.switchState(new OutdatedState());
					} else {
						MusicBeatState.switchState(new MainMenuState());
					}
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					//trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							//trace('YOOO! ' + word);
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('ToggleJingle'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState());
								}
							});
							FlxG.sound.music.fadeOut();
							if(FreeplayState.vocals != null)
							{
								FreeplayState.vocals.fadeOut();
							}
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		if (!ModsMenuState.waitingToRestart)
		{
			for (i in 0...textArray.length)
			{
				var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
				money.x = -1500;
				FlxTween.quadMotion(money, -300, -100, 30 
					+ (i * 70), 150 
					+ (i * 130), 100 
					+ (i * 70), 
					80 
					+ (i * 130), 0.4, true, {
						ease: FlxEase.quadInOut
					});
				if(credGroup != null && textGroup != null) {
					credGroup.add(money);
					textGroup.add(money);
				}
			}
		}
		else
		{
			for (i in 0...textArray.length)
			{
				var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
				money.screenCenter(X);
				money.y += (i * 60) + 200 + offset;
				if(credGroup != null && textGroup != null) {
					credGroup.add(money);
					textGroup.add(money);
				}
				money.y -= 350;
				FlxTween.tween(money, {y: money.y + 350}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.0});
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if (!ModsMenuState.waitingToRestart)
		{
			if(textGroup != null && credGroup != null) {
				var coolText:Alphabet = new Alphabet(0, 0, text, true);
				FlxTween.quadMotion(coolText, -300, -100, 10
					+ (textGroup.length * 40), 150
					+ (textGroup.length * 130), 30
					+ (textGroup.length * 40),
					80
					+ (textGroup.length * 130), 0.4, true, {
						ease: FlxEase.quadInOut
					});
				credGroup.add(coolText);
				textGroup.add(coolText);
			}
		}
		else
		{
			if(textGroup != null && credGroup != null) {
				var coolText:Alphabet = new Alphabet(0, 0, text, true);
				coolText.screenCenter(X);
				coolText.y += (textGroup.length * 60) + 200 + offset;
				credGroup.add(coolText);
				textGroup.add(coolText);
				coolText.y += 750;
				FlxTween.tween(coolText, {y: coolText.y - 750}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.0});
			}
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

        if(curBeat % 1 == 0)
        	FlxG.camera.zoom += 0.035;

		if(logoBl != null)
			logoBl.animation.play('bump', true);
			
		if (logo != null) {
			logo.scale.set(1.05, 1.05);
			FlxTween.tween(logo, {'scale.x': 0.95, 'scale.y': 0.95}, 0.35, {ease: FlxEase.backOut});
		}

		if(gfDance != null) {
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
					isPlaying = true;
				case 2:
					#if PSYCH_WATERMARKS
					createCoolText(['Unknown Engine by'], 40);
					#else
					createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
					#end
				case 4:
					#if PSYCH_WATERMARKS
					addMoreText('LeonGamer', 15);
					addMoreText('AshishXMC', 15);
					addMoreText('Fastbreak383', 15);
					#else
					addMoreText('present');
					#end
				case 5:
					deleteCoolText();
				case 6:
					#if PSYCH_WATERMARKS
					createCoolText(['This is a stupid fork', 'of'], -40);
					#else
					createCoolText(['In association', 'with'], -40);
					#end
				case 8:
					if (!ModsMenuState.waitingToRestart)
					{
						psychSpr.x = -1500;
						psychSpr.visible = true;
						FlxTween.quadMotion(psychSpr, -700, -700, 50
							+ (textGroup.length * 130), 150
							+ (textGroup.length * 50), 100
							+ (textGroup.length * 130),
							80
							+ (textGroup.length * 50), 0.4, true, {
								ease: FlxEase.quadInOut
							});
					}
					else
					{
						psychSpr.visible = true;
					}
				case 9:
					deleteCoolText();
					psychSpr.visible = false;
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
					FlxTween.tween(FNF_Logo, {y: 150, x: 300}, 0.8, {ease: FlxEase.backOut});
				case 15:
					FlxTween.tween(UE_Logo, {y: 436, x: 307}, 0.8, {ease: FlxEase.backOut});
				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(FNF_Logo);
			remove(UE_Logo);
			
			if (playJingle) //Ignore deez
			{
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'RIVER':
						sound = FlxG.sound.play(Paths.sound('JingleRiver'));
					case 'SHADOW':
						FlxG.sound.play(Paths.sound('JingleShadow'));
					case 'BBPANZU':
						sound = FlxG.sound.play(Paths.sound('JingleBB'));

					default: //Go back to normal ugly ass boring GF
						remove(psychSpr);
						remove(FNF_Logo);
						remove(UE_Logo);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;
						playJingle = false;

						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						return;
				}

				transitioning = true;
				if(easteregg == 'SHADOW')
				{
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						remove(psychSpr);
						remove(FNF_Logo);
						remove(UE_Logo);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						transitioning = false;
					});
				}
				else if(easteregg == 'BOYFRIEND')
				{
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						remove(psychSpr);
						remove(FNF_Logo);
						remove(UE_Logo);
						remove(credGroup);
						states.PlayState.SONG = backend.Song.loadFromJson("high-x-boyfriend-hard", "high-x-boyfriend");
						states.LoadingState.loadAndSwitchState(new states.PlayState());
					});
				}
				else
				{
					remove(psychSpr);
					remove(FNF_Logo);
					remove(UE_Logo);
					remove(credGroup);
					FlxG.camera.flash(FlxColor.WHITE, 3);
					sound.onComplete = function() {
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						transitioning = false;
					};
				}
				playJingle = false;
			}
			else //Default! Edit this one!!
			{
				remove(psychSpr);
				remove(FNF_Logo);
				remove(UE_Logo);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);
				FlxTween.tween(logo, {
					x: 0,
					y: 0
				}, 1.3, {ease: FlxEase.expoInOut, startDelay: 1.3});
				FlxTween.tween(gfDance, {y: 36}, 2.3, {ease: FlxEase.expoInOut, startDelay: 0.8});

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'SHADOW')
				{
					FlxG.sound.music.fadeOut();
					if(FreeplayState.vocals != null)
					{
						FreeplayState.vocals.fadeOut();
					}
				}
				#end
			}
			skippedIntro = true;
		}
	}
}
