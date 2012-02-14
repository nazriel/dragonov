/**
 * Uri parser
 *
 * Parse URI (Uniform Resource Identifiers) into parts described in RFC, based on tango.net.uri and GIO
 *
 * Authors: $(WEB github.com/robik, Robert 'Robik' Pasiński), $(WEB driv.pl/, Damian 'nazriel' Ziemba)
 * Copyright: Robert 'Robik' Pasiński, Damian 'nazriel' Ziemba 2011
 * License: $(WEB http://www.boost.org/users/license.html, Boost license)
 *
 * Source: $(REPO std/net/uri.d)
 */
module dragonov.net.Uri;

import std.string : indexOf;
import std.conv   : to;
import std.array  : split;

//** TEMPORARY
static import std.uri;

/** 
 * Represents query parameter
 */
struct QueryParam
{
    /**
     * Creates new QueryParam object
     * 
     * Params:
     *  n   =   Query param name
     *  v   =   Query param value
     */
    this(string name, string value)
    {
        Name = name;
        Value = value;
    }
    
    /// Query param name
    string Name;
    
    /// Query param value
    string Value;
}

/**
 * Represents URI query
 */
struct UriQuery
{
    /**
     * Array of params
     */
    private QueryParam[55] _params;
    private size_t _count = 0;
    
    /**
     * Returns query param value with specified name
     * 
     * Params:
     *  name    =   Query param name
     * 
     * Throws:
     *  Exception if not exists
     * 
     * Return:
     *  String with contents
     */
    string opIndex(string name)
    {
        foreach(param; _params)
        {
            if(param.Name == name)
                return param.Value;
        }
        
        throw new Exception("Param with name '"~name~"' does not exists");
    }
    
    size_t Length() const
    {
        return _count;
    }
    
    /**
     * Returns QueryParam with specified index
     * 
     * Params:
     *  i   =   Query param index
     * 
     * Returns:
     *  QueryParam
     * 
     * Throws:
     *  Exception if index is out of bounds
     */
    QueryParam opIndex(int i)
    {
        if(i >= _count)
            throw new Exception("Trying to get index that does not exits");
        
        return _params[i];
    }
    
    /**
     * Adds new QueryParam
     * 
     * Params:
     *  param   =   Param to add
     */
    void Add(QueryParam param)
    {
        _params[_count++] = param;
    }
}


/**
 * Represents URI
 * 
 * Examples:
 * ---------
 * auto uri = new Uri("http://domain.com/path"); 
 * assert(uri.domain == "domain.com");
 * assert(uri.path == "/path");
 * ---------
 */
class Uri
{
    /**
     * URI schemes
     */
    enum Scheme : string
    {
        Http     = "HTTP",
        Https    = "HTTPS",
        Ftp      = "FTP",
        Ftps     = "FTPS",
        Irc      = "IRC",
        Smtp     = "SMTP",        
        Unknown  = "",          
    }
    protected
    {        
        Scheme   _scheme;
        string   _domain;
        ushort   _port;
        string   _path;
        UriQuery _query;
        string   _user;
        string   _password;
        string   _fragment;
        string   _rawUri;
    	string   _rawquery;
    }
    
    /**
     * Creates new Uri object
     * 
     * Params:
     *  uri =   Uri to parse
     */
    this(string uri)
    {
        Parse(uri);
    }
    
    /**
     * Creates new Uri object
     * 
     * Params:
     *  uri =   Uri to parse
     *  port    =   Port
     */
    this(string uri, ushort port)
    {
        Parse(uri, port);
    }
    
    /**
     * Parses Uri
     * 
     * Params:
     *  uri =   Uri to parse
     *  port    = Port
     */
    void Parse(string uri, ushort port = 0)
    {
        Reset();
        
        size_t i, j;
        _port = port;
        _rawUri = uri;
        /* 
         * Scheme
         */
        i = indexOf(uri, "://");
        if(i != -1)  
        {
            switch(uri[0 .. i])
            {
                case "http":
                    _scheme = Scheme.Http;
                    break;
                case "https":
                    _scheme = Scheme.Https;
                    break;
                case "ftp":
                    _scheme = Scheme.Ftp;
                    break;
                case "ftps":
                    _scheme = Scheme.Ftps;
                    break;
                case "irc":
                    _scheme = Scheme.Irc;
                    break;
                case "smtp":
                    _scheme = Scheme.Smtp;
                    break;
                default:
                    _scheme = Scheme.Unknown;
                    break;
            }
            
            uri = uri[i + 3 .. $];
        } 
        else
        {
            _scheme = Scheme.Unknown;
            i = indexOf(uri, ":");
        }
        
        /* 
         * Username and Password
         */ 
        i = indexOf(uri, "@");
        if(i != -1) 
        {
            j = indexOf(uri[0..i+1], ":");
            
            if(j != -1) 
            {
                _user = uri[0 .. j];
                _password = uri[j+1 .. i];
            } 
            else 
            {
                _user = uri[0 .. i];
            }
            
            uri = uri[i+1 .. $]; 
        }
        
        /* 
         * Host and port
         */
        i = indexOf(uri, "/");
        if(i == -1) i = uri.length;
        
        j = indexOf(uri[0..i], ":");
        if(j != -1)
        {
            _domain = uri[0..j];
            _port = to!(ushort)(uri[j+1..i]);
        } 
        else
        {
            _domain = uri[0..i];
        }
        
        if ( _port != 0 && _scheme == Scheme.Unknown )
        {
            GetDefaultScheme();
        }
        else if ( _port == 0 && _scheme != Scheme.Unknown )
        {
            GetDefaultPort();
        }
            
        uri = uri[i .. $];   
        
        
        /*
         * Fragment
         */
        i = indexOf(uri, "#");
        if(i != -1)
        {
            _fragment = uri[i+1..$];
            uri = uri[0..i];
        }
        
        
        /*
         * Path and Query
         */
        i = indexOf(uri, "?");
        if(i != -1)
        {
            _rawquery = uri[i+1 .. $];
            _path = uri[0 .. i];
            ParseQuery();  
        }
        else
            _path = uri[0..$];
            
        if ( _path == "" )
        {
            _path = "/";
        }
    }
    
    // TODO: Parse to Query
    void ParseQuery()
    {
        auto parts = split(_rawquery, "&");
        
        foreach(part; parts)
        {
            auto i = indexOf(part, "=");
            _query.Add(QueryParam(part[0 .. i], part[i+1..$]));
        }
                
    }
    
    /**
     * Gets default scheme depending on port
     */
    protected void GetDefaultScheme()
    {
        switch(_port)
        {
            case 80:
            case 8080:
                _scheme = Scheme.Http;
                break;
            case 443:
                _scheme = Scheme.Https;
                break;
            case 21:
                _scheme = Scheme.Ftp;
                break;
            case 990:
                _scheme = Scheme.Ftps;
                break;
            case 6667:
                _scheme = Scheme.Irc;
                break;
            case 25:
                _scheme = Scheme.Smtp;
                break;
            default:
                _scheme = Scheme.Unknown;
                break;
        }
    }
    
    
    /**
     * Gets default port depending on scheme
     */
    protected void GetDefaultPort()
    {
        final switch (cast(string) _scheme)
        {
            case Scheme.Http:
                _port = 80;
                break;
            case Scheme.Https:
                _port = 443;
                break;
            case Scheme.Ftp:
                _port = 21;
                break;
            case Scheme.Ftps:
                _port = 990;
                break;
            case Scheme.Irc:
                _port = 6667;
                break;
            case Scheme.Smtp:
                _port = 25;
                break;
        }
    }
    
    /**
     * Resets Uri Data
     * 
     * Example:
     * --------
     * uri.parse("http://domain.com");
     * assert(uri.domain == "domain.com");
     * uri.reset;
     * assert(uri.domain == null);
     * --------
     */
    void Reset()
    {
        _scheme = Scheme.Unknown;
        _port = 0;
        _domain = null;
        _path = null;
        _rawquery = null;
        _query = UriQuery();
        _user = null;
        _password = null;
        _fragment = null;
    }
    
    /**
     * Builds Uri string
     * 
     * Returns:
     *  Uri
     */
    alias Build toString;
    
    /// ditto
    string Build()
    {
        string uri;
        
        uri ~= cast(string)_scheme ~ "://";
        
        if(_user)
        {
            uri ~= _user;
            if(_password)
                uri ~= ":"~ _password;
            
            uri ~= "@";   
        }
        
        uri ~= _domain;
        
        if(_port != 0)
            uri ~= ":" ~ to!(string)(_port);
            
        uri ~= _path;
        
        if(_rawquery)
            uri ~= "?" ~ RawQuery();
        
        if(_fragment)
            uri ~= "#" ~ Fragment();
        
        return uri;
    }
    
    /**
     * Returns: Uri scheme
     */
    @property Scheme Protocol() const
    {
        return _scheme;
    }
    
    /**
     * Returns: Uri domain
     */    
    @property string Domain() const
    {
        return _domain;
    }
    
    /// ditto
    alias Domain Host;
    
    /**
     * Returns: Uri port
     */
    @property ushort Port() const
    {
        return _port;
    }
    
    @property Uri Port(ushort port_)
    {
        _port = port_;
        
        return this;
    }
    
    @property string RawUri() const
    {
        return _rawUri;
    }
    
    /**
     * Returns: Uri path
     */
    @property string Path() const
    {
        return _path;
    }
    
    @property Uri Path(string path_)
    {
        _path = path_;
        return this;
    }
    /**
     * Returns: Uri query (raw)
     */
    @property string RawQuery() const
    {
        return _rawquery;
    }
    
    @property UriQuery Query() const
    {
        return _query;
    }
    
    /**
     * Returns: Uri username
     */
    @property string User() const
    {
        return _user;
    }
    
    @property Uri User(string username)
    {
        _user = username;
        
        return this;
    }
    
    /**
     * Returns: Uri password
     */
    @property string Password() const
    {
        return _password;
    }
    
    @property Uri Password(string pass)
    {
        _password = pass;
        
        return this;
    }
    /**
     * Returns: Uri fragment
     */
    @property string Fragment() const
    {
        return _fragment;
    }
    
    /**
     * Parses Uri and returns new Uri object
     * 
     * Params:
     *  uri =   Uri to parse
     *  port    =  Port
     * 
     * Returns:
     *  Uri
     * 
     * Example:
     * --------
     * auto uri = Uri.parseUri("http://domain.com", 80);
     * --------
     */
    static Uri ParseUri(string uri, ushort port)
    {
        return new Uri(uri, port);
    }
    
    /**
     * Parses Uri and returns new Uri object
     * 
     * Params:
     *  uri =   Uri to parse
     * 
     * Returns:
     *  Uri
     * 
     * Example:
     * --------
     * auto uri = Uri.parseUri("http://domain.com");
     * --------
     */
    static Uri ParseUri(string uri)
    {
        return new Uri(uri);
    }
    
    static string Encode(string uri) 
    {
        return std.uri.encode(uri);
    }
    
    static string Decode(string uri) 
    {
        return std.uri.decode(uri);
    }
}

unittest
{
    auto uri = new Uri("http://user:pass@domain.com:80/path/a?q=query#fragment");
    
    assert(uri.scheme() == uri.Http);
    assert(uri.scheme() == uri.Scheme.Http);
    assert(uri.scheme() == Uri.Scheme.Http);
    assert(uri.scheme() == Uri.Http);
    
    assert(uri.host == "domain.com");
    assert(uri.port == 80);
    assert(uri.user == "user");
    assert(uri.password == "pass");
    assert(uri.path == "/path/a");
    assert(uri.rawquery == "q=query");
    assert(uri.query["q"] == "query");
    assert(uri.fragment == "fragment");   
    
    uri.parse("http://google.com");
    assert(uri.port() == 80);
    assert(uri.scheme() == uri.Http);
    
    uri.parse("google.com", 80);
    assert(uri.scheme() == uri.Http);
    
    uri.parse("google.com", 8080);
    assert(uri.scheme() == uri.Http);
    
    uri.parse("publicftp.com", 21);
    assert(uri.scheme() == uri.Ftp);
    
    uri.parse("ftp://google.com");
    assert(uri.scheme() == uri.Ftp, uri.scheme);
    
    uri.parse("smtp://gmail.com");
    assert(uri.scheme() == uri.Smtp);
    assert(uri.host() == "gmail.com");
    
    uri.parse("http://google.com:666");
    assert(uri.scheme() == uri.Http);
    assert(uri.port() == 666);
    
    assert(Uri.parseUri("http://google.com").scheme() == Uri.Http);
    
    UriQuery query = UriQuery();
    query.add(QueryParam("key", "value"));
    query.add(QueryParam("key1" ,"value1"));
    assert(query.length() == 2);
}
