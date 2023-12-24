package macros;

#if macro
import sys.io.Process;
#end

class GitCommitMacro 
{
	/**
	 * Returns the current commit number
	 */
	public static var commitNumber(get, null):Int;
	/**
	 * Returns the current commit hash
	 */
	public static var commitHash(get, null):String;

	// GETTERS
	private static inline function get_commitNumber()
		return __getCommitNumber();

	private static inline function get_commitHash()
		return __getCommitHash();

	// INTERNAL MACROS
	private static macro function __getCommitHash() {
		try {
			var proc = new Process('git', ['rev-parse', '--short', 'HEAD'], false);
			proc.exitCode(true);

			return macro $v{proc.stdout.readLine()};
		} catch(e) {}
		return macro $v{"-"}
	}

	private static macro function __getCommitNumber() {
		try {
			var proc = new Process('git', ['rev-list', 'HEAD', '--count'], false);
			proc.exitCode(true);

			return macro $v{Std.parseInt(proc.stdout.readLine())};
		} catch(e) {}
		return macro $v{0}
	}
}