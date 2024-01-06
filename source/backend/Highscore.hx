package backend;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();
	public static var songRanks:Map<String, Int> = new Map<String, Int>();
	
	public static var endlessScores:Map<String, Int> = new Map<String, Int>();
	public static var endlessRating:Map<String, Float> = new Map<String, Float>();

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
	}
	
	public static function resetRank(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		setRank(formatSong(song, diff), 16);
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				if(rating >= 0) setRating(daSong, rating);
			}
		}
		else {
			setScore(daSong, score);
			if(rating >= 0) setRating(daSong, rating);
		}
	}

	public static function saveRank(song:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songRanks.exists(daSong))
		{
			if (songRanks.get(daSong) > score)
				setRank(daSong, score);
		}
		else
			setRank(daSong, score);
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else
			setWeekScore(daWeek, score);
	}
	
	public static function saveEndlessScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void
	{
		var daSong:String = formatSong(song, diff);

		if (endlessScores.exists(daSong))
		{
			if (endlessScores.get(daSong) < score)
				setEndlessScore(daSong, score);
		}
		else
			setEndlessScore(daSong, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}
	static function setWeekScore(week:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}
	
	static function setRank(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRanks.set(song, score);
		FlxG.save.data.songRanks = songRanks;
		FlxG.save.flush();
	}
	
	static function setEndlessScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		endlessScores.set(song, score);
		FlxG.save.data.endlessScores = endlessScores;
		FlxG.save.flush();
	}
	
	static function setEndlessRating(song:String, rating:Float):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		endlessRating.set(song, rating);
		FlxG.save.data.endlessRating = endlessRating;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	public static function getScore(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong))
			setScore(daSong, 0);

		return songScores.get(daSong);
	}
	
	public static function getEndlessScore(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		if (!endlessScores.exists(daSong))
			setEndlessScore(daSong, 0);

		return endlessScores.get(daSong);
	}

	public static function getRating(song:String, diff:Int):Float
	{
		var daSong:String = formatSong(song, diff);
		if (!songRating.exists(daSong))
			setRating(daSong, 0);

		return songRating.get(daSong);
	}
	
	public static function getRank(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		if (!songRanks.exists(daSong))
			setRank(formatSong(song, diff), 16);

		return songRanks.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek))
			setWeekScore(daWeek, 0);

		return weekScores.get(daWeek);
	}
	
	public static function getEndlessRating(song:String, diff:Int):Float
	{
		var daSong:String = formatSong(song, diff);
		if (!endlessRating.exists(daSong))
			setEndlessRating(daSong, 0);

		return endlessRating.get(daSong);
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
		{
			weekScores = FlxG.save.data.weekScores;
		}
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
		}
		if (FlxG.save.data.endlessScores != null)
		{
			endlessScores = FlxG.save.data.endlessScores;
		}
		if (FlxG.save.data.endlessRating != null)
		{
			endlessRating = FlxG.save.data.endlessRating;
		}
		if (FlxG.save.data.songRating != null)
		{
			songRating = FlxG.save.data.songRating;
		}
		if (FlxG.save.data.songRanks != null)
		{
			songRanks = FlxG.save.data.songRanks;
		}
	}
}