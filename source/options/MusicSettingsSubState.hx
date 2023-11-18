package options;

import objects.Alphabet;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class MusicSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Music Settings';
		rpcTitle = 'Music Settings Menu'; //for Discord Rich Presence
		
		var option:Option = new Option('Main Menu Song:',
			"What song do you prefer for the Main Menu?",
			'pauseMusic',
			'string',
			['None', 'Gettin\' Freaky', 'Gettin\' Freaky (Hydra Remix)', 'Gettin\' Freaky (B-Side Remix)']);
		addOption(option);
		option.onChange = onChangeMenuMusic;
		
		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			['None', 'Breakfast', 'Tea Time', 'Flying High', 'Thrillseeker']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}
	
	function onChangeMenuMusic()
	{
		if(ClientPrefs.data.menuMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.menuMusic)));

		changedMusic = true;
	}

	override function destroy()
	{
		if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.menuMusic)), 1, true);
		super.destroy();
	}
}
