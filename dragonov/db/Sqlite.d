module dragonov.db.Sqlite;

public import dragonov.db.Database;
public import dragonov.sys.Loader;

import std.string, std.conv;

class Sqlite : Database
{
	Loader loader;
	DynamicLib config;
	
    this(string name)
    {
    	config = DbConfig(name);
    	loader = DynamicLib("libsqlite3");
    	
		loader.LoadSymbol("sqlite3_open", sqlite3_open);
		loader.LoadSymbol("sqlite3_close", sqlite3_close);
    	loader.LoadSymbol("sqlite3_exec", sqlite3_exec);
    	loader.LoadSymbol("sqlite3_changes", sqlite3_changes);
		loader.LoadSymbol("sqlite3_errmsg", sqlite3_errmsg);
		loader.LoadSymbol("sqlite3_mprintf", sqlite3_mprintf);
		loader.LoadSymbol("sqlite3_prepare_v2", sqlite3_prepare_v2);
		//loader.loadSymbol("sqlite3_finalize", sqlite3_finalize);
		loader.LoadSymbol("sqlite3_column_count", sqlite3_column_count);
		loader.LoadSymbol("sqlite3_column_text", sqlite3_column_text);
		loader.LoadSymbol("sqlite3_column_name", sqlite3_column_name);
		loader.LoadSymbol("sqlite3_reset", sqlite3_reset);
		loader.LoadSymbol("sqlite3_step", sqlite3_step);
		
    	//super(name);
    }

    override public void Connect()
    {
        if (config.Param("host") is null)
        {
            throw new DatabaseConfigException(config.PackageName ~ "host");
        }
        else
        {
        	int res = sqlite3_open(toStringz(config.Param("host")), &this.db);
        	
			if ( res != 0 )
				throw new DatabaseConnectionException("Can't connect", to!(string)(sqlite3_errmsg(db)), res); // TODO: make sure its working :-D
        }
    }
    
    override public void Disconnect()
    {
    	if (this.db ! is null)
    	{
    		sqlite3_close(this.db);
    		this.db = null;
		}
    }
    
    override public int Execute( string sql, string file = __FILE__, size_t line = __LINE__ )
    {
    	int res = sqlite3_exec(db, toStringz(sql), null, null, null);
    	
    	if ( res != 0 )
    	{
    		throw new Exception(
    			to!(string)(res) ~ to!(string)(sqlite3_errmsg(db)),file, line);
    	
    		/*throw new Exception("Woot666");*/
    	}
    	return sqlite3_changes(db);
    }
    
    override public string Escape( string sql )
    {
    	return to!(string)( sqlite3_mprintf("%q", toStringz( sql ) ) );
    }
    
    override public Result Query( string sql, string file = __FILE__, size_t line = __LINE__ )
    {
    	int res = sqlite3_prepare_v2(this.db, toStringz(sql), sql.length, &this.stmt, null);
    	
    	if ( res != 0 )
    	{
    		//throw new Exception("Whoot " ~ file ~  to!string(line));
    		throw new Exception(to!(string)(res) ~ to!(string)(sqlite3_errmsg(db)), file, line );
        }
        
        SqliteResult result = new SqliteResult(this);
        result.Next();
        
        return result;
    }
    
    override public Statement Prepare(string sql)
    {
    	return new Statement(sql, this);
    }
    
    package sqlite3_stmt* stmt;
	
    package sqlite3* db;    
    
	private ~this()
	{
		Disconnect();
	}
}

class SqliteResult : Result 
{
	Sqlite _db;
	this(Sqlite db)
	{
		_db = db;
	}
	
	Row[] FetchAll(){ return [Row()]; }
	
	Row Fetch() 
	{ 
		string[] values;
		string[] keys;
		
		for ( int i = 0; i < sqlite3_column_count(_db.stmt); i++ )
		{
			keys ~= to!(string)(sqlite3_column_name(_db.stmt, i));
			values ~= to!(string)(sqlite3_column_text(_db.stmt, i));
		}
		
		Row row = Row(keys, values);
		
		return row;
	}
	
	@property public bool Valid() const
	{
		return _valid;
	}
	
	public bool Next() 
	{
		int state = sqlite3_step(_db.stmt);
		
		if ( state == 100 )
		{
			_valid = true;
			return true;
		}
		else
		{
			if ( state == 101 )
				Finalize();
			
			_valid = false;
			return false;
		}
	}
	
	public void Reset() { }
	public void Finalize() { }
}



//alias int function (const char *, sqlite3**) sqlite3_openType;
alias int function (sqlite3*) sqlite3_closeType;

//alias int function (sqlite3*, const(char)*, size_t, sqlite3_stmt**, const(char*)*)
//sqlite3_prepare_v2Type;

alias char* function( sqlite3* ) sqlite3_errmsgType;
alias int function (sqlite3_stmt* ) sqlite3_resetType;

shared extern (C)
{struct sqlite3;
struct sqlite3_stmt;

    //sqlite3_openType sqlite3_open;
    int function (const(char)*, sqlite3**)  sqlite3_open;
    sqlite3_closeType sqlite3_close;
   
    int function (sqlite3*, const(char)*, size_t, sqlite3_stmt**, char**) sqlite3_prepare_v2;
   //sqlite3_prepare_v2Type sqlite3_prepare_v2;
    
    sqlite3_errmsgType sqlite3_errmsg;
    char* function(const(char)*,...) sqlite3_mprintf;
    int function (sqlite3*, const(char)*, int function (void*,int, const(char*)*,const(char*)*), void*, const(char*)* ) sqlite3_exec;
    int function (sqlite3*) sqlite3_changes;
    int function (sqlite3_stmt*) sqlite3_column_count;
    char* function (sqlite3_stmt*, int) sqlite3_column_text;
    char* function (sqlite3_stmt*, int) sqlite3_column_name;
    int function (sqlite3_stmt*) sqlite3_step;
   // int function ( sqlite3_stmt* ) sqlite3_finalize;
    //sqlite3_resetType sqlite3_reset;
    int function (sqlite3_stmt* ) sqlite3_reset;
    
}
