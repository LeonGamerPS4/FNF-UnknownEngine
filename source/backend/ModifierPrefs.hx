package backend;

import haxe.Json;

import states.PlayState;

typedef ModiVariables =
{
	var HealthMult:Float;
	var HealthLoss:Float;
	var KillOnMiss:Bool;
    var Practice:Bool;
	var Botplay:Bool;
}

class ModifierPrefs
{
    public static var _modifiers:ModiVariables;

    #if desktop
    public static var subtractValue:Int = 0;
    #else
    public static var subtractValue:Int = 1;
    #end

    public static function updateModifiers():Void
    {
        _modifiers = {
			HealthMult: ClientPrefs.getGameplaySetting('healthgain'),
			
			HealthLoss: ClientPrefs.getGameplaySetting('healthloss'),
			
			KillOnMiss: ClientPrefs.getGameplaySetting('instakill'),
		
            Practice: ClientPrefs.getGameplaySetting('practice'),
			
			Botplay: ClientPrefs.getGameplaySetting('botplay'),
        };
    }

    public static function saveCurrent():Void
    {
        #if sys
        if (!FileSystem.isDirectory('assets/presets/modifiers'))
            FileSystem.createDirectory('assets/presets/modifiers');

        File.saveContent(('assets/presets/modifiers/current'), Json.stringify(_modifiers, null, '    '));
        #else
        FlxG.save.data.Modifiers = Json.stringify(_modifiers, null, '    ');
        FlxG.save.flush();
        #end
    }

    public static function savePreset(input:String):Void
        {
            #if sys
            File.saveContent(('assets/presets/modifiers/'+input), Json.stringify(_modifiers, null, '    ')); //just an example for now
            #end
        }

    public static function loadPreset(input:String):Void
    {
        #if sys
        var data:String = File.getContent('assets/presets/modifiers/'+input);
        _modifiers = Json.parse(data);
        
        //replaceValues();
        #end
    }

    public static function loadCurrent():Void
    {
        #if sys
        if (FileSystem.exists('assets/presets/modifiers/current'))
        {
            var data:String = File.getContent('assets/presets/modifiers/current');
            _modifiers = Json.parse(data);
        }
        #else
        if (ClientPrefs.saveSettings == null)
        {
            updateModifiers();
            saveCurrent();
        }
        else
            _modifiers = Json.parse(ClientPrefs.saveSettings);
        #end

        //replaceValues();
    }

    public static function replaceValues():Void
    {
		_modifiers.HealthMult = ClientPrefs.getGameplaySetting('healthgain');
			
		_modifiers.HealthLoss = ClientPrefs.getGameplaySetting('healthloss');
			
		_modifiers.KillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		
        _modifiers.Practice = ClientPrefs.getGameplaySetting('practice');
			
		_modifiers.Botplay = ClientPrefs.getGameplaySetting('botplay');
    }
}