module dragonov.db.Mysql;

public import dragonov.db.Database;
public import dragonov.sys.DynamicLib;

import std.string, std.conv, std.stdio;

class Mysql : Database
{
	DynamicLib loader;
	DbConfig config;
	
    this()
    {
    	loader = DynamicLib("libmysqlclient");
    	
		loader.LoadSymbol("mysql_init", mysql_init);
		loader.LoadSymbol("mysql_real_connect", mysql_real_connect);
		loader.LoadSymbol("mysql_real_query", mysql_real_query);
		loader.LoadSymbol("mysql_query", mysql_query);
		loader.LoadSymbol("mysql_store_result", mysql_store_result);
		loader.LoadSymbol("mysql_fetch_field", mysql_fetch_field);
		loader.LoadSymbol("mysql_num_fields", mysql_num_fields);
		loader.LoadSymbol("mysql_close", mysql_close);
		loader.LoadSymbol("mysql_fetch_row", mysql_fetch_row);
		loader.LoadSymbol("mysql_fetch_lengths", mysql_fetch_lengths);
		loader.LoadSymbol("mysql_num_rows", mysql_num_rows);
		loader.LoadSymbol("mysql_data_seek", mysql_data_seek);
		loader.LoadSymbol("mysql_affected_rows", mysql_affected_rows);
		loader.LoadSymbol("mysql_escape_string", mysql_escape_string);
		loader.LoadSymbol("mysql_error", mysql_error);
		loader.LoadSymbol("mysql_errno", mysql_errno);
		
    	conn = mysql_init(null);
    	config = DbConfig("default");
    }
    
    this(string name)
    {
    	config = DbConfig(name);
    	this();
    }
    
    void Connect()
    {
    	if (config.Param("host") is null)
        {
            throw new DatabaseConfigException(config.PackageName ~ "host");
        }
        else
        {
        	Connect(config.Param("host"), config.Param("username"), 
        		    config.Param("password"), config.Param("db"));
        }
    }
    
    void Connect(string host, string username, string password, string dbname)
    {
    	mysql_real_connect(
    		conn, 
    		toStringz(host),
    		toStringz(username),
    		toStringz(password),
    		toStringz(dbname),
    		0,null,0);
    		
    	string err = to!(string)(mysql_error(conn));
    	if ( err != "")
		{
			throw new DatabaseConnectionException("Unable to connect MySQL database.", err, 
												  mysql_errno(conn));
		}
    }
    
    void Disconnect()
    {
    	if (conn !is null)
    	{
    		mysql_close(conn);
    		
			string err = to!(string)(mysql_error(conn));
	    	if ( err != "")
			{
				throw new DatabaseConnectionException("Unable to disconnect from MySQL database.", 
													  err, mysql_errno(conn));
			}
		}
    }
    
    override Result Query(string sql, string file = __FILE__, size_t line = __LINE__ )
    {
    	auto errcode = mysql_real_query(conn, toStringz(sql), cast(uint) sql.length);
    	MYSQL_RES* res;
    	
    	if (errcode)
    	{
    		throw new DatabaseQueryException("Couldn't execute MySQL query", sql,   
    			                             to!(string)(mysql_error(conn)), errcode);
    	}
    	
    	
    	res  = mysql_store_result(conn);
    	if (res is null)
    	{
    		throw new DatabaseQueryException("Couldn't execute MySQL query", sql, 
    			                             to!(string)(mysql_error(conn)), mysql_errno(conn));
    	}
    	
    	return new MysqlResult(res);
    }
    
    override Statement Prepare(string sql)
    {
    	return new Statement(sql, this);
    }
    
    override int Execute(string sql, string file = __FILE__, size_t line = __LINE__ ) 
    { 
    	auto errcode = mysql_real_query(conn, toStringz(sql), cast(uint) sql.length);
    	
    	if (errcode)
    	{
    		throw new DatabaseQueryException("Couldn't execute MySQL query", sql, 
    			                             to!(string)(mysql_error(conn)), mysql_errno(conn));
    	}
    	return cast(int) mysql_affected_rows(conn);
    }

	override string Escape(string input)
	{ 
		size_t len = (input.length * 2) + 1;
		char[] buff = new char[len];
		
		mysql_escape_string(buff.ptr, toStringz(input), cast(ulong) input.length);
		return to!string(buff); 
	}
	    
    MYSQL* conn;
}

class MysqlResult : Result 
{
	this(MYSQL_RES* res)
	{
		_res = res;
		_count = mysql_num_rows(_res);
		_fieldCount = mysql_num_fields(_res);
		
		MYSQL_FIELD* field;
		for (uint i = 0; i < _fieldCount; i++)
		{
			field = mysql_fetch_field(_res);
			fields ~= to!(string)(field.name);
		}
	}
	
	string[] fields;
	
	override Row Fetch()
	{
		MYSQL_ROW row = mysql_fetch_row(_res);
		
		string[] keys;
		string[] values;
		
		
		if ( row is null ) return Row.init;
		
		for (uint i = 0; i < _fieldCount; i++)
		{
			keys ~= fields[i];
			values ~= to!(string)(row[i]);
		}
		
		writeln(values);
		Row rowx = Row(keys, values);
		return rowx;
	}
	
	override Row[] FetchAll()
	{
		Row[] rows;
		Row row;
		
		while ( (row = Fetch()) != Row.init )
		{
			rows ~= row;
		}
		
		return rows;
	}
	
	@property bool Valid() const
	{
		return _count > _counter;
	}
	
	bool Next() 
	{
		if ( _counter == _count )
		{
			return false;
		}
		++_counter;
		
		return _counter != _count;
	}
	
	void Reset() { }
	void Finalize() { }
	
	const ulong _count;
	ulong _counter;
	uint _fieldCount;
	MYSQL_FIELD* _field;
	MYSQL_RES* _res;
}

/*****************************************
 *                                       *
 * C Headers                             * 
 *                                       *
 *****************************************/
struct MYSQL {}
struct MYSQL_RES {}
struct MYSQL_FIELD 
{
	const(char)* name;
}
alias char** MYSQL_ROW;

extern (C)
{
	MYSQL* function(MYSQL*) mysql_init;
	
	MYSQL* function(
		MYSQL*,  
		const(char)*,
        const(char)*,
        const(char)*,
        const(char)*,
     	uint,
        char*,
       	uint
   	) mysql_real_connect;
   	
   	int function(
   		MYSQL*,
   		const(char)*,
        uint
    ) mysql_real_query;
    
    int function(
   		MYSQL*,
   		const(char)*
    ) mysql_query;
    
    void function(MYSQL*) mysql_close;
    
    MYSQL_RES* function(MYSQL*) mysql_store_result;
    MYSQL_FIELD* function(MYSQL_RES*) mysql_fetch_field;
    uint function(MYSQL_RES*) mysql_num_fields;
    
    MYSQL_ROW function(MYSQL_RES*) mysql_fetch_row;
    uint* function(MYSQL_RES*) mysql_fetch_lengths;
    ulong function(MYSQL_RES*) mysql_num_rows;
    void function(MYSQL_RES*, ulong) mysql_data_seek;
    ulong function(MYSQL*) mysql_affected_rows;
    
    ulong function(char*, const(char)*, ulong) mysql_escape_string;
    
    uint function(MYSQL*) mysql_errno;
    const(char)* function(MYSQL*) mysql_error;
}