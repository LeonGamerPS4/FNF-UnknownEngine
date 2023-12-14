package options;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import flixel.util.FlxGradient;

import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	
	var menuMusic:FlxSound;
	
	var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(95, 80, 190, 160, true, 0x33FFE100, 0x0));
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 300, 0xFFAA00AA);
	
	var ExplainText:FlxText = new FlxText(20, 69, FlxG.width / 2, "", 48);

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Music':
				openSubState(new options.MusicSettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end
		
		menuMusic = new FlxSound();
		menuMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), true, true);
		menuMusic.volume = 0;
		menuMusic.play(false, FlxG.random.int(0, Std.int(menuMusic.length / 2)));

		FlxG.sound.list.add(menuMusic);
		
		if (!FlxG.sound.music.playing && !onPlayState && ClientPrefs.data.pauseMusic != 'None')
		{
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), menuMusic.volume);
			FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
		}
		else if (!FlxG.sound.music.playing && !onPlayState && ClientPrefs.data.pauseMusic == 'None')
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('oBG_Main'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		
		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x558DE7E5, 0xAAE6F0A9], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		gradientBar.scrollFactor.set(0, 0);
		
		grid.velocity.set(21, 51);
		grid.alpha = 0;
		grid.scrollFactor.set(0, 0.07);
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});		

		var side:FlxSprite = new FlxSprite(0).loadGraphic(Paths.image('Options_Side'));
		side.scrollFactor.x = 0;
		side.scrollFactor.y = 0;
		side.antialiasing = true;
		side.x = 0;
		
		ExplainText.scrollFactor.x = 0;
		ExplainText.scrollFactor.y = 0;
		ExplainText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER);
		ExplainText.alignment = LEFT;
		ExplainText.x = 20;
		ExplainText.y = 624;
		ExplainText.setBorderStyle(OUTLINE, 0xFF000000, 5, 1);
		ExplainText.alpha = 0;

		bg.screenCenter();
		add(bg);
		add(gradientBar);
		add(grid);
		add(side);
		add(ExplainText);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);
		
		FlxG.camera.zoom = 3;
		FlxTween.tween(FlxG.camera, {zoom: 1}, 1.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(ExplainText, {alpha: 1}, 0.15, {ease: FlxEase.expoInOut});

		changeSelection();
		
		ClientPrefs.saveSettings();
		
		#if desktop
		MusicBeatState.windowNameSuffix = " - Options Menu";
		#end

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) 
	{
		super.update(elapsed);

		if (controls.UI_UP_P) 
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) 
		{
			changeSelection(1);
		}

		if (controls.BACK) 
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxTween.tween(FlxG.camera, {zoom: 3}, 1, {ease: FlxEase.expoInOut});
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.globeTrans = false;
				LoadingState.loadAndSwitchState(new PlayState());
				FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.4);
			}
			else 
			{
				MusicBeatState.switchState(new MainMenuState());
				FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.4);
			}
		}
		
		updateTexts();
		
		if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function updateTexts()
	{
		switch (options[curSelected])
		{
			case "Note Colors":
				ExplainText.text = "NOTE COLORS:\nChange the colors of the funny notes.";
			case "Controls":
				ExplainText.text = "CONTROLS:\nChange your keybinds, however you want.";
			case "Adjust Delay and Combo":
				ExplainText.text = "ADJUST DELAY AND COMBO:\nChange the offset of the combo popup or the audio.";
			case "Graphics":
				ExplainText.text = "GRAPHICS:\nChange how the graphics work in game.";
			case "Visuals and UI":
				ExplainText.text = "VISUALS AND UI:\nChange the UI, menus, or audio of the game.";
			case "Gameplay":
				ExplainText.text = "GAMEPLAY: \nChange how in song gameplay works.";
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		FlxG.sound.music.stop();
		
		super.destroy();
	}
}