module dragonov.sys.Process;
	
import core.sys.posix.sys.types;

class Process
{
	private string _command;
		
	version(Posix) {
		private	pid_t _pid;
	}
	
	
	this(string command)
	{
		_command = command;	
	}
	
	void Execute()
	{
	}
	
	void Create()
	{
	
	}
	
	public int Pid() @property
	{
		version (Posix) {
			return cast(int) _pid;
		}
	}
}