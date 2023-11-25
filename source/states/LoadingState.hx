package states;

import lime.app.Promise;
import lime.app.Future;

import flixel.FlxState;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

import backend.StageData;

import haxe.io.Path;

import backend.MusicBeatState;

class LoadingState extends MusicBeatState
{
	inline static final MIN_TIME = 1.0;

	// Browsers will load create(), you can make your song load a custom directory there
	// If you're compiling to desktop (or something that doesn't use NO_PRELOAD_ALL), search for getNextState instead
	// I'd recommend doing it on both actually lol
	
	// TO DO: Make this easier
	
	var target:FlxState;
	var stopMusic = false;
	var directory:String;
	public static var globeTrans:Bool = true;
	public static var silentLoading:Bool = false;
	var callbacks:MultiCallback;
	var targetShit:Float = 0;

	function new(target:FlxState, stopMusic:Bool, directory:String)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}
	
	var loadBar:FlxSprite;
	var loadingCirc:FlxSprite;
	var loadingCircSpeed = FlxG.random.int(50,200);
	var tipTxt:FlxText;
	var tips:Array<String> = [
		"Don't spam, it won't work.",
		"psych engine port\nfree clout yay",
		"why am i wasting my\ntime making this fork",
		"unknown",
		"Null Object Reference",
		"This isn't a kids game.",
		"This is Psych Engine\nbut content overload.",
		"No tip here.",
		"I miss FNF's peak.",
		"https://github.com/LeonGamerPS4/FunkinRedux",
		"discord light mode\nbrighter than the fucking sun",
		"ALT + Enter for free Week 8 /j",
		"Funk all the way.",
		"Friday Night Funkin'\nMic'd Up.",
		"before psych engine there was kade engine\nthose were the days",
		"You're currently playing FNF Redux v2.5.",
		"Do people actually read these?",
		"Skill issue.",
		"Cock joke.",
		"WHAT",
		"As long as there's 2 people left on the planet,\nsomeone is gonna want someone dead.",
		"His name isn't Keith.",
		"One arrow is enough.",
		"THERE AREN'T COUGARS IN MISSIONS",
		"Disingenuous dense motherfucker.",
		"My father is dying.\nPlease stop beatboxing.",
		"pico funny\nbig ol' bunny",
		"Gettin freaky' on a friday night yeah",
		"Psych Engine Fork.\nMake fun of me.",
		"Worjdjhewndjaiqkkwbdjkwqodbdjwoen&:’eked&3rd!2’wonenksiwnwihqbdibejwjebdjjejwjenfjdjejejjwkwiwjnensjsiieejjsjskikdjdnnwjwiwjejdjdjwiejdbdiwjdhehhrifjdnwoqnd",
		"Oo0ooOoOOo000OOO!!!",
		"Witness the might\nof the seas!",
		"DENPA ENGINE SUPREMACY",
		"CARAMEL ARROW SUPREMACY",
		"I will rip your intestines out.",
		"flippity floppity",
		"i'm surprised people might actually\nbe reading this at this point",
		"potato\nwaterslide",
		"GingerBrave\nMore like",
		"flopknown engine",
		"I love to smash my keyboard.",
		"there might be someone out there that's thinking about making a mod about you.\nkeep that in mind.",
		"Funkin' Forever.",
		"How to piss off the Psych Discord\nStep 1: make a psych fork and dump wacky ass content into it /j",
		"WENT BACK TO FREEPLAY??",
		"Ugh",
		"Bop beep be be skdoo bep"
	];
	var silent:Bool = false;
	
	override function create()
	{
		Paths.clearUnusedMemory();
		silent = silentLoading;
		silentLoading = false;

		flixel.addons.transition.FlxTransitionableState.skipNextTransIn = false;
		flixel.addons.transition.FlxTransitionableState.skipNextTransOut = false;
		if (!globeTrans) {
			flixel.addons.transition.FlxTransitionableState.skipNextTransIn = true;
			flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
		}
		globeTrans = true;

		if (!silent) {
			var loading:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('loadBG_Main'));
			loading.active = false;
			loading.setGraphicSize(0, FlxG.height);
			loading.updateHitbox();
			loading.x = FlxG.width - loading.width;
			add(loading);
		
			loadingCirc = new FlxSprite(0, 0).loadGraphic(Paths.image('loadingicon'));
			loadingCirc.scale.set(0.45,0.45);
			loadingCirc.updateHitbox();
			loadingCirc.screenCenter(Y);
			loadingCirc.active = false;
			add(loadingCirc);
	
			loadBar = new FlxSprite(10, 0).makeGraphic(10, FlxG.height - 150, 0xffffffff);
			loadBar.screenCenter(Y);
			loadBar.color = 0xffff00ff;
			loadBar.active = false;
			add(loadBar);
	
			final loadColors:Array<flixel.util.FlxColor> = [0xffff0000, 0xffff7b00, 0xffffff00, 0xff00ff00, 0xff0000ff, 0xffff00ff];
			var loadIncrement:Int = 0;
			clrBarTwn(loadIncrement, loadBar, loadColors, 1);
	
			tipTxt = new FlxText(0, FlxG.height - 48, 0, tips[FlxG.random.int(0,tips.length-1)]);
			tipTxt.scrollFactor.set();
			tipTxt.setFormat("VCR OSD Mono", 16, 0xffffffff, LEFT);
			tipTxt.active = false;
			add(tipTxt);
	
			var timer = new FlxTimer().start(4, function(tmr:FlxTimer) {
				tipTxt.text = tips[FlxG.random.int(0,tips.length-1)];
			}, 0);
		}
		
		initSongsManifest().onComplete
		(
			function (lib)
			{
				callbacks = new MultiCallback(onLoad);
				var introComplete = callbacks.add("introComplete");
				if (PlayState.SONG != null) {
					checkLoadSong(getSongPath());
					if (PlayState.SONG.needsVoices)
						checkLoadSong(getVocalPath());
				}
				if(directory != null && directory.length > 0 && directory != 'shared') {
					checkLibrary('week_assets');
				}

				var fadeTime = 0.5;
				FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
				new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
			}
		);
	}
	
	function checkLoadSong(path:String)
	{
		if (!Assets.cache.hasSound(path))
		{
			var library = Assets.getLibrary("songs");
			final symbolPath = path.split(":").pop();
			var callback = callbacks.add("song:" + path);
			Assets.loadSound(path).onComplete(function (_) { callback(); });
		}
	}
	
	function checkLibrary(library:String) {
		trace(Assets.hasLibrary(library));
		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw new haxe.Exception("Missing library: " + library);

			var callback = callbacks.add("library:" + library);
			Assets.loadLibrary(library).onComplete(function (_) { callback(); });
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (silent) return;

		loadingCirc.angle += elapsed*loadingCircSpeed;

		if(callbacks != null) {
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.y += 0.5 * (targetShit - loadBar.scale.y);
		}
	}

	function clrBarTwn(incrementor:Int, sprite:FlxSprite, clrArray:Array<flixel.util.FlxColor>, duration:Int) {
		flixel.tweens.FlxTween.color(sprite, duration, sprite.color, clrArray[incrementor], {onComplete: function(_) {
			incrementor++;
			if (incrementor > 5) incrementor = 0;
			clrBarTwn(incrementor, sprite, clrArray, duration);
		}});
	}
	
	inline function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
			
		MusicBeatState.switchState(target);
	}

	static function getSongPath()
	{
		return Paths.inst(PlayState.SONG.song);
	}
	
	static function getVocalPath()
	{
		return Paths.voices(PlayState.SONG.song);
	}
	
	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		//trace('Setting asset folder to ' + directory);

		#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (PlayState.SONG != null) {
			loaded = isSoundLoaded(getSongPath()) && (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath())) isLibraryLoaded('week_assets');
		}
		
		if (!loaded)
			return new LoadingState(target, stopMusic, directory);
		#end
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		return target;
	}
	
	#if NO_PRELOAD_ALL
	inline static function isSoundLoaded(path:String):Bool
	{
		trace(path);
		return Assets.cache.hasSound(path);
	}
	
	inline static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}
	#end
	
	override function destroy()
	{
		super.destroy();
		
		callbacks = null;
	}
	
	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;
	
	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();
	
	public function new (callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}
	
	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = null;
		func = function ()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;
				
				if (logId != null)
					log('fired $id, $numRemaining remaining');
				
				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}
	
	inline function log(msg):Void
	{
		if (logId != null)
		{
			trace('$logId: $msg');
		}
	}
	
	public function getFired() return fired.copy();
	public function getUnfired() return [for (id in unfired.keys()) id];
}