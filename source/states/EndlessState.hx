package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import states.ModifiersState;
import states.PlayState;

import substates.ResetScoreSubState;
import substates.EndlessSubstate;

import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;
import flixel.util.FlxGradient;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

using StringTools;

class EndlessState extends MusicBeatState
{
	public static var songs:Array<EndlessSongMetadata> = [];
	var lerpList:Array<Bool> = [];

	var bg:FlxSprite = new FlxSprite(-89).loadGraphic(Paths.image('EndBG_Main'));
	var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(95, 80, 190, 160, true, 0x333495EB, 0x0));
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 300, 0xFFAA00AA);
	var side:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('End_Side'));

	private static var curSelected:Int = 0;
	
	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	private var camMenu:FlxCamera;

	var camLerp:Float = 0.1;
	var selector:FlxText;
	var selectedSomethin:Bool = false;
	var selectable:Bool = false;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	public static var substated:Bool = false;
	public static var no:Bool = false;
	public static var goingBack:Bool = false;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	
	var icon:HealthIcon;
	
	private var iconArray:Array<HealthIcon> = [];

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;
	
	var leText:String = "";

	private var grpSongs:FlxTypedGroup<Alphabet>;

	override function create()
	{
		substated = false;
		no = false;
		goingBack = false;
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		PlayState.isEndless = true;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Endless Menu", null);
		#end
		
		camMenu = initPsychCamera();

		FlxCamera.defaultCameras = [camMenu];
		
		if (!TitleState.isPlaying)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.03;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x5576D3FF, 0xAAFFDCFF], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);

		grid.velocity.set(10, 25);
		add(grid);
		
		side.scrollFactor.x = 0;
		side.scrollFactor.y = 0;
		side.antialiasing = true;
		side.screenCenter();
		add(side);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true);
			songText.targetY = i;
			lerpList.push(true);
			grpSongs.add(songText);

			Mods.currentModDirectory = songs[i].folder;
			icon = new HealthIcon(songs[i].songCharacter);
			//icon.bopMult = 0.95;
			icon.sprTracker = songText;
			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			//add(icon);
			//icon.copyState = true;
			icon.alpha = 1;

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);
		
		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);
		diffText.alpha = 1;

		add(scoreText);

		side.screenCenter(Y);
		side.x = 500 - side.width;
		FlxTween.tween(side, {x: 0}, 0.6, {ease: FlxEase.quartInOut});

		FlxTween.tween(bg, {alpha: 1}, 0.8, {ease: FlxEase.quartInOut});
		camMenu.zoom = 0.6;
		camMenu.alpha = 0;
		FlxTween.tween(camMenu, {zoom: 1, alpha: 1}, 0.7, {ease: FlxEase.quartInOut});

		FlxTween.tween(scoreText, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});

		changeSelection();
		
		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		leText = "Press RESET to Reset your Score and Accuracy.";
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
		bottomText.alpha = 1;

		new FlxTimer().start(0.7, function(tmr:FlxTimer)
		{
			selectable = true;
		});

		#if desktop
		MusicBeatState.windowNameSuffix = " - Endless Menu";
		#end

		super.create();
	}
	
	function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new EndlessSongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var holdTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		FlxG.watch.addQuick("beatShit", curBeat);
		
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}
		
		final lerpVal:Float = CoolUtil.clamp(elapsed * 9.6, 0, 1);
		for (i=>song in grpSongs.members) {
			@:privateAccess {
				if (lerpList[i]) {
					song.y = FlxMath.lerp(song.y, (song.scaledY * song.yMult) + (FlxG.height * 0.48) + song.yAdd, lerpVal);
					if(song.forceX != Math.NEGATIVE_INFINITY) {
						song.x = song.forceX;
					} else {
						switch (song.targetY) {
							case 0:
								song.x = FlxMath.lerp(song.x, (song.targetY * 20) + 90 + song.xAdd, lerpVal);
							default:
								song.x = FlxMath.lerp(song.x, (song.targetY * (song.targetY < 0 ? 20 : -20)) + 90 + song.xAdd, lerpVal);
						}
					}
				} else {
					song.y = ((song.scaledY * song.yMult) + (FlxG.height * 0.48) + song.yAdd);
					if(song.forceX != Math.NEGATIVE_INFINITY) {
						song.x = song.forceX;
					} else {
						switch (song.targetY) {
							case 0:
								song.x = ((song.targetY * 20) + 90 + song.xAdd);
							default:
								song.x = ((song.targetY * (song.targetY < 0 ? 20 : -20)) + 90 + song.xAdd);
						}
					}
				}
			}
		}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;
		
		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		if (!substated && selectable && !goingBack && !substated)
		{
			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}
			
				if (controls.UI_LEFT_P)
				{
					changeDiff(-1);
					_updateSongLastDifficulty();
				}
				
				if (controls.UI_RIGHT_P)
				{
					changeDiff(1);
					_updateSongLastDifficulty();
				}
				
				if (controls.BACK)
				{
					MusicBeatState.switchState(new GamemodesMenuState());
					TitleState.isPlaying = true;
					
					goingBack = true;
					
					FlxTween.tween(camMenu, {zoom: 0.6}, 0.7, {ease: FlxEase.quartInOut});
					FlxTween.tween(camMenu, {alpha: -0.6}, 0.7, {ease: FlxEase.quartInOut});
					FlxTween.tween(bg, {alpha: 0}, 0.7, {ease: FlxEase.quartInOut});
					FlxTween.tween(grid, {alpha: 0}, 0.3, {ease: FlxEase.quartInOut});
					FlxTween.tween(gradientBar, {alpha: 0}, 0.3, {ease: FlxEase.quartInOut});
					FlxTween.tween(side, {x: -500 - side.width}, 0.3, {ease: FlxEase.quartInOut});
					FlxTween.tween(scoreText, {alpha: 0}, 0.3, {ease: FlxEase.quartInOut});

					#if sys
					DiscordClient.changePresence("Going back!", null);
					#end

					FlxG.sound.play(Paths.sound('cancelMenu'));
				}

				if (controls.ACCEPT)
				{
					var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
					var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
					/*#if MODS_ALLOWED
					if(!FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
					#else
					if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
					#end
						poop = songLowercase;
						curDifficulty = 1;
						trace('Couldnt find file');
					}*/
					trace(poop);

					try
					{
						PlayState.SONG = Song.loadFromJson(poop, songLowercase);
						PlayState.isStoryMode = false;
						PlayState.isEndless = true;
						PlayState.storyDifficulty = curDifficulty;

						trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					}
					catch(e:Dynamic)
					{
						trace('ERROR! $e');

						var errorStr:String = e.toString();
						if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length-1); //Missing chart
						missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
						missingText.screenCenter(Y);
						missingText.visible = true;
						missingTextBG.visible = true;
						FlxG.sound.play(Paths.sound('cancelMenu'));

						//updateTexts(elapsed);
						super.update(elapsed);
						return;
					}
				
					TitleState.isPlaying = true;
			
					FlxG.sound.play(Paths.sound('confirmMenu'));

					EndlessSubstate.song = songs[curSelected].songName.toLowerCase();

					substated = true;
					FlxG.state.openSubState(new EndlessSubstate());
				}
				else if(controls.RESET)
				{
					//persistentUpdate = false;
					//openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
					//FlxG.sound.play(Paths.sound('scrollMenu'));
				}
		}

		if (no)
		{
			bg.kill();
			side.kill();
			gradientBar.kill();
			grid.kill();
			scoreText.kill();
			grpSongs.clear();
			icon.kill();
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = lastDifficultyName.toUpperCase();

		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].visible = true;
			iconArray[i].active = true;
			iconArray[i].alpha = 0.6;
			iconArray[i].animation.curAnim.curFrame = 0;
		}

		iconArray[curSelected].alpha = 1;

		for (i=>item in grpSongs.members)
		{
			item.active = item.visible = lerpList[i] = true;
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class EndlessSongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
