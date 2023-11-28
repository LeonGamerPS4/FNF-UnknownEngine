package substates;

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Section;
import backend.Rating;

#if desktop
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;

import states.StoryMenuState;
import states.FreeplayState;
import states.TitleState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

class RankingSubstate extends MusicBeatSubstate
{
	var pauseMusic:FlxSound;

	var rank:FlxSprite = new FlxSprite(-200, 730);
	var combo:FlxSprite = new FlxSprite(-200, 730);
	public static var hint:FlxText;
	public static var comboRank:String = "NA";
	public static var ranking:String = "NA";
	var rankingNum:Int = 15;

	public function new(x:Float, y:Float)
	{
		super();

		generateRanking();

		#if desktop
		var image = lime.graphics.Image.fromFile('assets/images/iconOG.png');
		lime.app.Application.current.window.setIcon(image);
		#end

		if (!ClientPrefs.getGameplaySetting('botplay'))
			Highscore.saveRank(PlayState.SONG.song, rankingNum, PlayState.storyDifficulty);

		pauseMusic = new FlxSound().loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		rank = new FlxSprite(-20, 40).loadGraphic(Paths.image('rankings/$ranking'));
		rank.scrollFactor.set();
		add(rank);
		rank.antialiasing = true;
		rank.setGraphicSize(0, 450);
		rank.updateHitbox();
		rank.screenCenter();

		combo = new FlxSprite(-20, 40).loadGraphic(Paths.image('rankings/$comboRank'));
		combo.scrollFactor.set();
		combo.screenCenter();
		combo.x = rank.x - combo.width / 2;
		combo.y = rank.y - combo.height / 2;
		add(combo);
		combo.antialiasing = true;
		combo.setGraphicSize(0, 130);

		var press:FlxText = new FlxText(20, 15, 0, "Press any key to continue.", 32);
		press.scrollFactor.set();
		press.setFormat(Paths.font("vcr.ttf"), 32);
		press.setBorderStyle(OUTLINE, 0xFF000000, 5, 1);
		press.updateHitbox();
		add(press);

		hint = new FlxText(20, 15, 0, "You passed. Try getting under 10 misses for SDCB", 32);
		hint.scrollFactor.set();
		hint.setFormat(Paths.font("vcr.ttf"), 32);
		hint.setBorderStyle(OUTLINE, 0xFF000000, 5, 1);
		hint.updateHitbox();
		add(hint);
		
		if (comboRank == "MFC")
			hint.text = "Congrats! You're perfect!";
		else if (comboRank == "GFC")
			hint.text = "You're doing great! Try getting only sicks for MFC";
		else if (comboRank == "FC")
			hint.text = "Good job. Try getting goods at minimum for GFC.";
		else if (comboRank == "SDCB")
			hint.text = "Nice. Try not missing at all for FC.";

		if (ClientPrefs.getGameplaySetting('botplay'))
		{
			hint.y -= 35;
			comboRank = "FC";
			hint.text = "If you wanna gather that rank, disable botplay.";
		}

		if (PlayState.deathCounter >= 30)
		{
			hint.text = "skill issue\nnoob";
		}

		hint.screenCenter(X);

		hint.alpha = press.alpha = 0;

		press.screenCenter();
		press.y = 670 - press.height;

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(press, {alpha: 1, y: 690 - press.height}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(hint, {alpha: 1, y: 645 - hint.height}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01;

		super.update(elapsed);

		if (FlxG.keys.justPressed.ANY || ClientPrefs.getGameplaySetting('practice'))
		{
			if (PlayState.isStoryMode) 
			{
				if (PlayState.storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					TitleState.isPlaying = true;
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if desktop DiscordClient.resetClientID(); #end
					
					PlayState.cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());
					PlayState.changedDifficulty = false;
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				TitleState.isPlaying = true;
				#if desktop DiscordClient.resetClientID(); #end

				PlayState.cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.changedDifficulty = false;
			}
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function generateRanking():String
	{	

		// WIFE TIME :)))) (based on Wife3)

		var wifeConditions:Array<Bool> = [
			PlayState.accPercent >= 99.9935, // P
			PlayState.accPercent >= 99.980, // X
			PlayState.accPercent >= 99.950, // X-
			PlayState.accPercent >= 99.90, // SS+
			PlayState.accPercent >= 99.80, // SS
			PlayState.accPercent >= 99.70, // SS-
			PlayState.accPercent >= 99.50, // S+
			PlayState.accPercent >= 99, // S
			PlayState.accPercent >= 96.50, // S-
			PlayState.accPercent >= 93, // A+
			PlayState.accPercent >= 90, // A
			PlayState.accPercent >= 85, // A-
			PlayState.accPercent >= 80, // B
			PlayState.accPercent >= 70, // C
			PlayState.accPercent >= 60, // D
			PlayState.accPercent < 60 // E
		];

		for (i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				rankingNum = i;
				switch (i)
				{
					case 0:
						ranking = "P";
					case 1:
						ranking = "X";
					case 2:
						ranking = "X-";
					case 3:
						ranking = "SS+";
					case 4:
						ranking = "SS";
					case 5:
						ranking = "SS-";
					case 6:
						ranking = "S+";
					case 7:
						ranking = "S";
					case 8:
						ranking = "S-";
					case 9:
						ranking = "A+";
					case 10:
						ranking = "A";
					case 11:
						ranking = "A-";
					case 12:
						ranking = "B";
					case 13:
						ranking = "C";
					case 14:
						ranking = "D";
					case 15:
						ranking = "E";
				}

				if (PlayState.deathCounter >= 30 || PlayState.accPercent == 0)
					ranking = "F";
				break;
			}
		}
		return ranking;
	}
}
