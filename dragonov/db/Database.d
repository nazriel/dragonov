module dragonov.db.Database;


import std.string, std.conv, std.array, std.algorithm;
import std.stdio;

class Database 
{
	abstract void Connect();
	abstract void Disconnect();
	abstract Result Query(string, string file = __FILE__, size_t line = __LINE__ );
	abstract int Execute(string, string file = __FILE__, size_t line = __LINE__ );
	abstract string Escape(string);
	abstract Statement Prepare(string);
}

class Statement
{
	this (string sql, Database db)
	{
		_sql = sql;
		_parent = db;
	}
	
	string toString()
	{
		return _sql;
	}
	
	Result Query(string file = __FILE__, size_t line = __LINE__)
	{
		Compile();
		
		return _parent.Query(_sql, file, line);
	}
	
	int Execute(string file = __FILE__, size_t line = __LINE__)
	{
		Compile();
		
		return _parent.Execute(_sql, file, line);
	}
	
	Statement Bind(T)(string key, T val)
	{
		_binds[ key ] = to!(string)(val); 
		
		return this;
	}
	
	Statement Bind(T)(T val)
	{
		_binds2 ~= to!(string)(val);
		
		return this;
	}
	
	private string[] _binds2;
	private string[ string ] _binds;
	private string _sql;
	private Database _parent;
	
	void Compile()
	{
		foreach (key, value; _binds)
		{
			value = _parent.Escape(value);
			_sql = replace(_sql, key, value);
		}
	} 
	
}

abstract class Result
{
	alias Fetch Current;
	abstract Row[] FetchAll();
	abstract Row Fetch();
	abstract bool Valid() const;
	abstract bool Next();
	abstract void Reset();
	abstract void Finalize();
	
	protected bool _valid = false;
}


unittest
{
	Statement stmt = new Statement("SELECT * FROM {} {:id} {} {:id2} {}", null);
	stmt.Bind("val").Bind("val2").Bind("val3").
	Bind("id", ":D").Bind("id2", ":>").
	Compile(null);
}


class DbConfig
{	
	this (string name, string param)
	{
		Generate(param);
		PackageName = name;
	}
	
	static DbConfig opCall(string name) /// getter
	{
		if (!(name in DbConfig._configs))
		{
			throw new DatabaseConfigException(name);
		}
		
		return DbConfig._configs[ name ];
	}
	
	static DbConfig opCall(string name, string param)
	{
		param = replace(param, "\n", "");
		
		if (!(name in DbConfig._configs))
		{
			DbConfig._configs[name] = new DbConfig(name, param);
		}
		else
		{
			DbConfig._configs[name].Generate(param);
		}
		
		return DbConfig._configs[name];
	}
	
	string Param(string name)
	{
		if (!(name in _configVars))
		{
			return null;
		}
		
		return _configVars[name];
	}
	
	string Param(string key, string value)
	{
		_configVars[key] = value;
		
		if (key == "backend")
		{
			_backendName = value;
		}
		
		return _configVars[key];
	}
	
	string GetBackend()
	{
		return _backendName;
	}
	
	private void Generate(string parametrs)
	{
        if ( parametrs != "" )
        {
            string[] splitted  = split(parametrs, ";");
            string[] parArr;

            foreach (par; splitted)
            {
                parArr = split(par, "=");

                if ( parArr.length == 2 )
                {
                	_configVars[ parArr[0] ] = parArr[1];

                	if ( parArr[0] == "backend" )
                		_backendName = parArr[1];
            	}
            }
        }
    }

    string PackageName = "default";
    static private DbConfig[ string ] _configs;
    private string[ string ] _configVars;
    private string _backendName = "none";
}

class DatabaseConfigException: Exception
{
	this(string msg)
	{	
		super(msg);
	}
}

class DatabaseConnectionException : Exception
{
	this(string msg, string errMsg, uint errCode)
	{
		string _ret = 
			msg ~ "\n" ~
			"Database response: ("~ to!(string)(errCode) ~") " ~
			errMsg ~ "\n";
			
		super(_ret);			
	}
}

class DatabaseQueryException : Exception
{
	this (string msg, string sql, string errMsg, uint errCode)
	{
		string _ret = 
			msg ~ "\n" ~
			"SQL: " ~ sql ~ "\n" ~ 
			"Database response: ("~ to!(string)(errCode) ~") " ~
			errMsg ~ "\n";
		super(_ret);
	}
}

unittest
{
    DbConfig config = DbConfig("DBALunittest", "backend=mysql;host=localhost;username=nazriel;password=Tajne Haśło");

    assert(config.getBackend() == "mysql");
    assert(config.param("host") == "localhost");
    assert(config.param("username") == "nazriel");
    assert(config.param("password") == "Tajne Haśło");
    assert(config.param("nonExistingOption") is null);

    assert(config.param("username", "naz") == "naz");

    assert(Config("DBALunittest").param("username") == "naz");

    Config("DBALunittest").param("backend", "sqlite");
    assert(Config("DBALunittest").getBackend() == "sqlite");
    assert(config.getBackend() == "sqlite");

    assert(config == Config("DBALunittest") );
    assert(config is Config("DBALunittest") );
}


struct Row
{
	this ( ref string[] keys, ref string[] values )
	{
		dalRowSpecialPrivateDataKeys = keys;
		dalRowSpecialPrivateDataValues = values;		
	}

	string toString()
	{
		string result = "  ";
		
		foreach ( i, key; dalRowSpecialPrivateDataKeys )
		{
			result ~= format( "%s:%s ", key, dalRowSpecialPrivateDataValues[ i ] );
		}
		result = result[0..$-1];
		return result;
	}
	
	string opDispatch( string key )( string val = null )
	if ( key != "popFront" )
	{	
		sizediff_t pos = -1;
		foreach ( i, name; dalRowSpecialPrivateDataKeys )
		{
			if ( name == key )
			{
				pos = i;
				break;
			}
		}

		if ( pos == -1 && val is null )
		{
			throw new Exception( "There is no key " ~ key );
		}
		
		if ( val !is null )
		{
			if ( pos != -1 )
			{
				dalRowSpecialPrivateDataValues[ pos ] = val;
			}
			else
			{
				dalRowSpecialPrivateDataKeys ~= key;
				dalRowSpecialPrivateDataValues ~= val;
				pos = dalRowSpecialPrivateDataKeys.length - 1;
			}
		}
		
		return dalRowSpecialPrivateDataValues[ pos ];
	}
	
	string opIndex( size_t key )
	{
		if ( findKeyPositionInPrivateDataKeys( key ) == -1 )
		{
			throw new Exception( text("There is no value with index ", key) );
		}
		
		return dalRowSpecialPrivateDataValues[ key ];
	}
	
	string opIndex( string key )
	{
		sizediff_t pos = findKeyPositionInPrivateDataKeys(key);
		
		if ( pos == -1 )
		{
			throw new Exception( "There is no value with index " ~ key );
		}
		
		return dalRowSpecialPrivateDataValues[ pos ];
	}
	
	string opIndexAssign(T)( T value, size_t key )
	{
		sizediff_t pos = findKeyPositionInPrivateDataKeys(key);
		
		if ( pos == -1 )
		{
			dalRowSpecialPrivateDataKeys ~= "";
			dalRowSpecialPrivateDataValues ~= value;
			pos = dalRowSpecialPrivateDataKeys.length - 1;
		}
		else
		{
			dalRowSpecialPrivateDataValues[ pos ] = value;
		}
		
		return dalRowSpecialPrivateDataValues[ pos ];
	}
	
	string opIndexAssign(T)( T value, string key )
	{
		try
		{
			value = to!(string)(chomp(value));
		}
		catch ( Exception e )
		{
			value = "";
		}
		
		sizediff_t pos = findKeyPositionInPrivateDataKeys(key);
		
		if ( pos == -1 )
		{
			dalRowSpecialPrivateDataKeys ~= key;
			dalRowSpecialPrivateDataValues ~= value;
			pos = dalRowSpecialPrivateDataKeys.length - 1;
			
		}
		else
		{
			dalRowSpecialPrivateDataValues[ pos ] = value;
		}
		
		return dalRowSpecialPrivateDataValues[ pos ];
	}
	
	int opApply( int delegate( ref string, ref string ) dg ) 
	{ 
		int result = 0;
		foreach ( i, key; dalRowSpecialPrivateDataKeys )
		{
			result = dg( dalRowSpecialPrivateDataKeys[ i ], dalRowSpecialPrivateDataValues[ i ] );
			
			if ( result != 0 ) 
			{
				return result;
			}
		}
		
		return 0;
	}
	
	private ptrdiff_t findKeyPositionInPrivateDataKeys( string key )
	{
		sizediff_t pos = -1;
		
		foreach ( i, name; dalRowSpecialPrivateDataKeys )
		{
			if ( name == key )
			{
				pos = i;
				break;
			}
		}
		
		return pos;
	}

	private ptrdiff_t findKeyPositionInPrivateDataKeys( size_t key )
	{
		sizediff_t pos = -1;
		
		if ( key <= dalRowSpecialPrivateDataKeys.length )
		{
			pos = key;
		}
		
		return pos;
	}
	
	private string[] dalRowSpecialPrivateDataKeys;
	private string[] dalRowSpecialPrivateDataValues;
}

unittest
{
	auto keys = ["key1", "key2", "key3"];
	auto values = ["value1", "value2", "value3"];
	
	Row row = Row(keys, values);
	assert(row.key1 == "value1");
	assert(row["key1"] == "value1");
	
	row.key1 = "value1changed";
	assert(row.key1 == "value1changed");
	assert(row["key1"] == "value1changed");
	
	foreach ( key, ref value; row )
	{
		value = "valueChangedByForeach";
	}
	
	assert(row.key1 == "valueChangedByForeach");
	assert(row.key2 == "valueChangedByForeach");
}

