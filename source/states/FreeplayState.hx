package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.ModifiersState;
import states.editors.ChartingState;

import substates.ResetScoreSubState;

import flixel.util.FlxStringUtil;
import flixel.util.FlxGradient;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

@:access(flixel.sound.FlxSound)
class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	var lerpList:Array<Bool> = [];

	var selector:FlxText;
	var selectedSomethin:Bool = false;
	var selectable:Bool = false;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();
	
	private var camGame:FlxCamera;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	
	var songBG:FlxSprite;
	var songTxt:FlxText;
	var timeTxt:FlxText;

	var icon:HealthIcon;

	var curTime:Float;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(95, 80, 190, 160, true, 0x33FFFFFF, 0x0));
	//var checker:FlxBackdrop = new FlxBackdrop(Paths.image('Free_Checker'), 0.2, 0.2, true, true);
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 300, 0xFFAA00AA);
	var intendedColor:Int;
	var intendedColor2:Int;
	var colorTween:FlxTween;
	
	var rankTable:Array<String> = [
		'P-small', 'X-small', 'X--small', 'SS+-small', 'SS-small', 'SS--small', 'S+-small', 'S-small', 'S--small', 'A+-small', 'A-small', 'A--small',
		'B-small', 'C-small', 'D-small', 'E-small', 'NA'
	];
	
	var rank:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('rankings/NA'));

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;
	
	var leText:String = "";

	var playingMusic:Bool;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		PlayState.isEndless = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Freeplay Menu", null);
		#end
		
		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxCamera.defaultCameras = [camGame];
		
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

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.alpha = 1;
		bg.screenCenter();
		
		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x55FFBDF8, 0xAAFFFDF3], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);

		grid.velocity.set(10, 25);
		add(grid);
		grid.alpha = 1;

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
			add(icon);
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
		
		rank.scale.x = rank.scale.y = 80 / rank.height;
		rank.updateHitbox();
		rank.antialiasing = true;
		rank.scrollFactor.set();
		rank.y = 105;
		rank.x = 1150;
		add(rank);
		rank.antialiasing = ClientPrefs.data.antialiasing;

		songBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 75, 0xFF000000);
		songBG.alpha = 0.6;
		add(songBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);
		diffText.alpha = 1;

		add(scoreText);

		songTxt = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		songTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		songTxt.visible = false;
		add(songTxt);
		songTxt.alpha = 1;

		timeTxt = new FlxText(FlxG.width * 0.7, songTxt.y + 32, 0, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		timeTxt.visible = false;
		add(timeTxt);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		grid.color = songs[curSelected].color;
		intendedColor = bg.color;
		intendedColor2 = grid.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		if(playingMusic)
			iconArray[instPlaying].canBounce = true;
		
		changeSelection();

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		leText = "Press SPACE to listen to the Song. / Press CTRL to open the Modifier Menu. / Press RESET to Reset your Score, Rank, and Accuracy.";
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
		bottomText.alpha = 1;
		
		#if desktop
		MusicBeatState.windowNameSuffix = " - Freeplay Menu";
		#end
		
		//updateTexts();
		super.create();
		
		new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			selectable = true;
		});
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
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

		if (!playingMusic)
		{
			scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
			positionHighscore();
			
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
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
		}
		else 
		{
			if (FlxG.sound.music._paused)
				songTxt.text = 'PLAYING: ' + songs[curSelected].songName + ' (PAUSED)';
			else
				songTxt.text = 'PLAYING: ' + songs[curSelected].songName;

			positionSong();
			
			var timee:Float = FlxG.sound.music.time;
			
			if (controls.UI_LEFT_P)
			{			
				pauseOrResume();

				curTime = FlxG.sound.music.time - 1000;
				holdTime = 0;

				if (curTime < 0)
					curTime = 0;

				FlxG.sound.music.time = curTime;
				vocals.time = curTime;
			}
			if (controls.UI_RIGHT_P)
			{
				pauseOrResume();

				curTime = FlxG.sound.music.time + 1000;
				holdTime = 0;

				if (curTime > FlxG.sound.music.length)
					curTime = FlxG.sound.music.length;

				FlxG.sound.music.time = curTime;
				vocals.time = curTime;
			}
			updateTimeTxt();
			
			if(controls.UI_LEFT || controls.UI_RIGHT)
			{
				holdTime += elapsed;
				if(holdTime > 0.5)
				{
					curTime += 40000 * elapsed * (controls.UI_LEFT ? -1 : 1);
				}

				var difference:Float = Math.abs(curTime - FlxG.sound.music.time);
				if(curTime + difference > FlxG.sound.music.length) curTime = FlxG.sound.music.length;
				else if(curTime - difference < 0) curTime = 0;

				FlxG.sound.music.time = curTime;
				vocals.time = curTime;
			}
			updateTimeTxt();
			if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
			{
				FlxG.sound.music.time = curTime;
				vocals.time = curTime;
			}
			updateTimeTxt();
		}

		if (controls.BACK)
		{
			if (playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				playingMusic = false;
				switchPlayMusic();
				
				Mods.loadTopMod();
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
			else 
			{
				selectedSomethin = true;
				persistentUpdate = false;
				if(colorTween != null) {
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				TitleState.isPlaying = true;
				ModifiersState.fromFreeplay = false;
				MusicBeatState.switchState(new GamemodesMenuState());
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !playingMusic)
		{
			selectedSomethin = true;
			persistentUpdate = false;
			FlxG.sound.music.stop();
			MusicBeatState.switchState(new ModifiersState());
			ModifiersState.fromFreeplay = true;
		}
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected && !playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;
				Conductor.set_bpm(PlayState.SONG.bpm);		
				for (i in 0...iconArray.length)
					iconArray[i].canBounce = false;
				iconArray[instPlaying].canBounce = true;
				playingMusic = true;
				curTime = 0;
				
				switchPlayMusic();
			}
			else if (instPlaying == curSelected && playingMusic)
			{
				if (FlxG.sound.music._paused)
				{
					pauseOrResume(true);
				}
				else 
				{
					pauseOrResume(false);
				}
			}
		}
		
		else if (FlxG.keys.pressed.R && playingMusic)
		{
			FlxG.sound.music.time = 0;
			vocals.time = 0;
		}

		else if (controls.ACCEPT && !playingMusic && !selectedSomethin && selectable)
		{
			selectedSomethin = true;
			persistentUpdate = false;
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
				PlayState.isEndless = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				if(colorTween != null) {
					colorTween.cancel();
				}
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

			FlxG.sound.play(Paths.sound('confirmMenu'));
			TitleState.isPlaying = true;
			
			FlxTween.tween(bg, {alpha: 0}, 0.6, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(grid, {alpha: 0}, 0.6, {ease: FlxEase.quartInOut});
			FlxTween.tween(gradientBar, {alpha: 0}, 0.6, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(scoreText, {y: 750, alpha: 0}, 0.8, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(rank, {y: 750, alpha: 0}, 0.8, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(diffText, {y: 750, alpha: 0}, 0.8, {ease: FlxEase.quartInOut});
			FlxTween.tween(songBG, {y: 750, alpha: 0}, 0.8, {ease: FlxEase.quartInOut});
			FlxTween.tween(bottomText, {y: 750, alpha: 0}, 0.8, {ease: FlxEase.quartInOut});
			FlxTween.tween(bottomBG, {y: 750, alpha: 0}, 0.8, {ease: FlxEase.quartInOut});
			for (i in 0...iconArray.length)
				FlxTween.tween(iconArray[i], {alpha: 0}, 0.6, {ease: FlxEase.quartInOut, startDelay: 0.3});
			
			for (item in grpSongs.members)
			{
				FlxTween.tween(item, {alpha: 0}, 0.9, {ease: FlxEase.quartInOut});
			}
		

			new FlxTimer().start(0.9, function(tmr:FlxTimer)
			{
				openSubState(new substates.ChartSubstate());
			});
			
			/*
			if (FlxG.keys.pressed.SHIFT){
				LoadingState.loadAndSwitchState(new ChartingState());
			}else{
				LoadingState.loadAndSwitchState(new PlayState());
			}

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
			#if (MODS_ALLOWED && cpp)
			DiscordClient.loadModRPC();
			#end
			*/
		}
		else if(controls.RESET && !playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		//updateTexts(elapsed);
		super.update(elapsed);
	}
	
	/*
	override function beatHit() 
	{
		super.beatHit();
		
        if(curBeat % 1 == 0) 
		{
        	camGame.zoom += 0.01;
			iconArray[instPlaying].bounce();
		}
	}
	*/

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function pauseOrResume(resume:Bool = false) {
		if (resume)
		{
			FlxG.sound.music.resume();

			if (vocals != null)
				vocals.resume();
		}
		else 
		{
			FlxG.sound.music.pause();

			if (vocals != null)
				vocals.pause();
		}
	}

	function changeDiff(change:Int = 0)
	{
		if (playingMusic)
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);

		rank.loadGraphic(Paths.image('rankings/' + rankTable[Highscore.getRank(songs[curSelected].songName, curDifficulty)]));
		rank.scale.x = rank.scale.y = 80 / rank.height;
		rank.updateHitbox();
		rank.antialiasing = ClientPrefs.data.antialiasing;
		rank.scrollFactor.set();
		rank.y = 105;
		rank.x = 1150;
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = lastDifficultyName.toUpperCase();

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playingMusic)
			return;

		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		var newColor2:Int = songs[curSelected].color;
		if(newColor != intendedColor && newColor2 != intendedColor2) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			intendedColor2 = newColor2;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
			
			colorTween = FlxTween.color(grid, 1, grid.color, intendedColor2, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}
		
		#if !switch
		rank.loadGraphic(Paths.image('rankings/' + rankTable[Highscore.getRank(songs[curSelected].songName, curDifficulty)]));
		rank.scale.x = rank.scale.y = 80 / rank.height;
		rank.updateHitbox();
		rank.antialiasing = ClientPrefs.data.antialiasing;
		rank.scrollFactor.set();
		rank.y = 105;
		rank.x = 1150;
		#end

		// selector.y = (70 * curSelected) + 30;

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

	private function positionSong() {
		songTxt.x = FlxG.width - songTxt.width - 6;
		songBG.scale.x = FlxG.width - songTxt.x + 12;
		songBG.x = FlxG.width - (songBG.scale.x / 2);
		timeTxt.x = Std.int(songBG.x + (songBG.width / 2));
		timeTxt.x -= timeTxt.width / 2;
	}

	private function switchPlayMusic() {
		@:privateAccess
		if (playingMusic)
		{
			scoreBG.visible = false;
			diffText.visible = false;
			scoreText.visible = false;

			songTxt.visible = true;
			timeTxt.visible = true;
			songBG.visible = true;

			bottomText.text = "Press SPACE to Pause the Song. / Press ESCAPE to Exit the Music Player. / Press R to Restart the Song.";
			positionSong();
		}
		else
		{	
			scoreBG.visible = true;
			diffText.visible = true;
			scoreText.visible = true;

			songTxt.visible = false;
			timeTxt.visible = false;
			songBG.visible = false;

			bottomText.text = bottomString;
			positionHighscore();
		}
	}

	function updateTimeTxt()
	{
		var text = FlxStringUtil.formatTime(FlxG.sound.music.time / 1000, false) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, false);
		timeTxt.text = '< ' + text + ' >';
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var gridColor:String = "";
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		//this.gridColor = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
