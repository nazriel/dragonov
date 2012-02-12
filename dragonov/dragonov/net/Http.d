/**
 * 
 * Http Client
 * 
 * Basic HTTP Client functionality.
 * 
 * Authors: $(WEB dzfl.pl, Damian "nazriel" Ziemba)
 * Copyright: 2012, Damian Ziemba
 * License: BSD
 * 
 * Example:
 * 
 * The hard way:
 * ----
 * import dragonov.io.Console;  
 * import dragonov.net.Http;
 * 
 * Http http = new Http("http://www.google.com/search?hl=en&q=%20D%20Programming%20Language&btnI=I%27m+Feeling+Lucky");
 * 
 * http.Connect();
 * Console(http.Get());
 * http.Disconnect();
 * ----
 * 
 * 
 * The simple way:
 * ----
 * 
 * import dragonov.io.Console;
 * import dragonov.net.Http;
 * 
 * Console( Http.SimpleGet("http://google.com");
 * 
 * ----
 * 
 * 
 */
 
/**
 * 
 * TODO: Http over SSL, (Head, Put, Delete etc), Resuming transfers.
 * 
 */
module dragonov.net.Http;

import std.socket;
import std.socketstream;
import std.string;
import std.conv;

import dragonov.net.Uri;
import dragonov.crypt.Base64;

class HttpException : Exception
{
	public this(string msg)
	{
		super(msg);
	}
}

class HttpHeaders
{
	private string[string] _header;
	public HttpCookies Cookies;
	
	void opIndexAssign(T)(T headerValue, string headerName)
	{
		_header[headerName] = to!(string)(headerValue);
	}
	
	string opIndex(string headerName)
	{
		foreach (name, value; _header)
		{
			if (toLower(name) == toLower(headerName))
			{
				return value;
			}
		}
		
		return null;
	}
	
    int opApply (int delegate(string, string) dg)
    {
        int      result = 0;
		
        foreach (name, value; _header)
        {
            result = dg(name, value);
            
            if (result)
                break;
        }

        return result;
    }
    
    void Remove(string headerName)
    {
   		foreach (name, value; _header)
		{
			if (toLower(name) == toLower(headerName))
			{
				_header.remove(name);
			}
		}
    }
}

struct HttpCookies
{
	private string[string] _cookie;
	
	void opIndexAssign(T)(T cookieValue, string cookieName)
	{
		_cookie[cookieName] = to!(string)(cookieValue);
	}
	
	string opIndex(const(char)[] cookieName)
	{
		foreach (name, value; _cookie)
		{
			if (toLower(name) == toLower(cookieName))
			{
				return value;
			}
		}
		
		return null;
	}
	
    int opApply (int delegate(string, string) dg)
    {
        int      result = 0;
		
        foreach (name, value; _cookie)
        {
            result = dg(name, value);
            
            if (result)
                break;
        }

        return result;
    }
}

struct HttpPostData
{
	private string[string] _field;
	
	public this(const(char)[] input)
	{
		auto splitedInput = split(input, "&");
		
		foreach (set; splitedInput)
		{
			auto fieldSet = split(set, "=");
			
			this[fieldSet[0]] = fieldSet[1];
		}
	}
	void opIndexAssign(T)(T fieldValue, const(char)[] fieldName)
	{
		foreach (name, ref value; _field)
		{
			if (toLower(name) == toLower(fieldName))
			{
				value = to!(string)(fieldValue);
				return;
			}
		}
		
		_field[fieldName] = to!(string)(fieldValue);
	}
	
	string opIndex(const(char)[] fieldName)
	{
		foreach (name, value; _field)
		{
			if (toLower(name) == toLower(fieldName))
			{
				return value;
			}
		}
		
		return null;
	}
	
    int opApply (int delegate(string, string) dg)
    {
        int      result = 0;
		
        foreach (name, value; _field)
        {
            result = dg(name, value);
            
            if (result)
                break;
        }

        return result;
    }
	
	public size_t DataLength()
	{	
		size_t totalLength = 0;
		
		foreach (name, value; _field)
		{
			totalLength += name.length;
			totalLength += 1; // = 
			totalLength += Uri.Encode(value).length;
			totalLength += 1; // &
		}
		
		totalLength -= 1;
		
		return totalLength;
	}
}

private struct HttpResponseStatus
{
	ushort Code;
	const(char)[] Message;
	ushort Version;
}
	
class Http
{
	private enum DefaultUserAgent = "Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1";
	private enum RedirectLimit = 10;
	Uri _uri;
	private RequestMethod _requestMethod;
	private uint _redirectsCount = 0;
	private Socket _socket;
	private SocketStream _stream;
	private AddressFamily _family;
	private uint _responseCode;
	private HttpPostData _postData;
	public HttpHeaders RequestHeaders;
	public HttpHeaders ResponseHeaders;
	public HttpResponseStatus ResponseStatus;
	public bool FollowLocation = true;
	
	private string _username;
	private string _password;
	
	enum RequestMethod : string
	{
		Get = "GET",
		Post = "POST",
		Head = "HEAD",
	}
	
	this()
	{
		RequestHeaders = new HttpHeaders;
		ResponseHeaders = new HttpHeaders;
		
		if (_uri.User != "")
		{
			_username = _uri.User;
		}
		
		if (_uri.Password != "")
		{
			_password = _uri.Password;
		}
	}
	
	this(Uri uri, RequestMethod requestMethod = RequestMethod.Get)
	{
		_uri = uri;
		_requestMethod = requestMethod;
		this();
	}
	
	this (string url, RequestMethod requestMethod = RequestMethod.Get)
	{
		_requestMethod = requestMethod;
		_uri = new Uri(url);
		this();
	}
	
	public ~this()
	{
		Disconnect();
	}
	
	public void Auth(string username, string password)
	{
		_username = username;
		_password = password;
	}
	
	private void ParseResponseHeaders()
	{
		char[4096] lineBuffer;
		size_t colonPosition;
		
		while (!_stream.eof)
		{
			char[] line = _stream.readLine(lineBuffer);
			
			if (line == "")
			{
				break;
			}
			
			colonPosition = indexOf(line, ": ");
			char[] headerName;
			char[] headerValue;
			
			if (colonPosition != -1)
			{
				headerName = line[0.. colonPosition];
				headerValue = line[colonPosition+2..$];
				
				if (toLower(headerName) == "set-cookie")
				{
					char[][] cookies = splitLines(line[12..$]);
					
					foreach (cookieSet; cookies)
					{
						auto cookieSet2 = split(cookieSet, "; ");
						foreach (cookie_; cookieSet2)
						{
							char[][] cookieNameValueSet = split(cookie_, "=");
							if (cookieNameValueSet.length < 2) continue;
							ResponseHeaders.Cookies[cookieNameValueSet[0].idup] = cookieNameValueSet[1]; 
							continue;
						}
					}
				}
				
				ResponseHeaders[headerName.idup] = headerValue;
			}
			else
			{
				if ( line.length > 5 )
                {
                	if ( line[0..4] == _uri.Scheme.Http)
                    {
                    	char[][] responseSplited = split(line, " ");
                        ResponseStatus = HttpResponseStatus(to!(ushort)(responseSplited[1]), responseSplited[2], to!(ushort)(responseSplited[0][$-1..$]));
                    }
                }
			}
		}
		
	}
	
	public void Connect()
	{
		try 
		{
			auto aa = new InternetAddress(_uri.Host, _uri.Port);
			_socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
			_socket.connect(aa);
		}
		catch (SocketOSException e)
		{
			throw new HttpException("Unable to connect " ~ _uri.Host ~ ": " ~ e.toString());
			
		}
		_stream = new SocketStream(_socket);
		
		if (RequestHeaders["Host"] is null)
		{
			RequestHeaders["Host"] =  _uri.Host;
		}
		
		if (RequestHeaders["User-Agent"] is null)
		{
			RequestHeaders["User-Agent"] = DefaultUserAgent;
		}
		
		if (RequestHeaders["Accept-Charset"] is null)
		{
			RequestHeaders["Accept-Charset"] = "UTF-8, *";
		}
		
		if (_requestMethod == RequestMethod.Post)
		{
			if (RequestHeaders["Content-Type"] is null)
			{
				RequestHeaders["Content-Type"] =  "application/x-www-form-urlencoded";
			}
			
			if (RequestHeaders["Content-Length"] is null)
			{
				RequestHeaders["Content-Length"] = _postData.DataLength();
			}
		}
		
		if (_username != "" && _password != "")
		{
			ubyte[] auth = cast(ubyte[])( _username ~ ":" ~ _password);
			RequestHeaders["Authorization"] = "Basic " ~ cast(string) Base64.Encode(auth);
		}
		
		if (KeepAlive) 
		{
			RequestHeaders["Connection"] = "keep-alive";
		}
		else
		{
			RequestHeaders["Connection"] = "close";
		}
		
		string request = _requestMethod ~ " " ~ _uri.Path;
		request ~= (_uri.RawQuery.length > 0 ? "?" ~ _uri.RawQuery : "") ~ " " ~ _uri.Protocol() ~ "/1.0\r\n";
		request ~= "Host: " ~ RequestHeaders["Host"] ~ "\r\n";
		
		foreach (headerName, headerValue; RequestHeaders)
		{
			if (toLower(headerName) != "host")
			{
				request ~= headerName ~ ": " ~ headerValue ~ "\r\n";
			}
		}
		
		request ~= "\r\n";
		
		Write(cast(void[]) request);
		
		if (_requestMethod == RequestMethod.Post)
		{
			request = "";
		
			foreach (name, value; _postData)
			{
				request ~= name ~ "=" ~ value ~ "&";
			}
			
			Write(cast(void[]) Uri.Encode(request[0..$-1]) ~ "\r\n");
		}
		
		ParseResponseHeaders();
		
		if ( (ResponseStatus.Code == 301 || ResponseStatus.Code == 302 || ResponseStatus.Code == 303)
			&& FollowLocation && ResponseHeaders["Location"] != "")
		{
			if (++_redirectsCount > RedirectLimit)
			{
				return;
			}
			Disconnect();
			Reset();
			_uri.Parse(ResponseHeaders["Location"]);
			Connect();
		}
	}
	
	public void Disconnect()
	{
		if (!ConnectionAlive)
		{
			return;
		}
		
		_stream.close();
	}
	
	public bool KeepAlive() const @property
	{
		return false;
	}
	
	public bool ConnectionAlive() const @property
	{
		if (_socket is null)
		{
			return false;
		}
		
		if (!_socket.isAlive())
		{
			return false;
		}
		
		return true;
	}
	
	void Read(scope void delegate(void[]) sink)
	{
		while (!_stream.eof)
		{
			char[4096] buff;
			auto buffer = _stream.readLine(buff);
			sink(cast(void[])buffer);
		}
	}
	
	void Write(void[] data)
	{
		_stream.writeExact(data.ptr, data.length);
	}
	
	public size_t Download(string localFile)
	{
		
		return 0;
	}
	
	public char[] Get(char[] buffer = null)
	{
		if (!ConnectionAlive)
			Connect();
		
		if (buffer is null)
		{
			buffer = new char[4096];
		}
		size_t totalLen = 0;
		
		Read((void[] data)
			{
				if (buffer.length < totalLen + data.length)
				{
					if (buffer.length * 2 < totalLen + data.length)
					{
						//Console("Resizing 1");
						buffer.length = (totalLen + data.length) * 2;
					}
					else
					{
						//Console("resizing 2", data.length);
						buffer.length = buffer.length * 2;
					}
				}
				buffer[totalLen .. totalLen + data.length] = cast(string) data[0..$];
				totalLen += data.length;
			});
			
		return buffer[0..totalLen];
	}
	
	public char[] Post(HttpPostData data, char[] buffer = null)
	{
		_requestMethod = RequestMethod.Post;
		_postData = data;
		
		Connect();
		
		if (buffer is null)
		{
			buffer = new char[4096];
		}
		size_t totalLen = 0;
		
		Read(
			(void[] data)
			{
				if (buffer.length < totalLen + data.length)
				{
					if (buffer.length * 2 < totalLen + data.length)
					{
						//Console("Resizing 1");
						buffer.length = (totalLen + data.length) * 2;
					}
					else
					{
						//Console("resizing 2", data.length);
						buffer.length = buffer.length * 2;
					}
				}
				buffer[totalLen .. totalLen + data.length] = cast(string) data[0..$];
				totalLen += data.length;
			});
			
		return buffer[0..totalLen];
	}
	
	public void Reset()
	{
		_uri.Reset();
		ResponseStatus = HttpResponseStatus();
		RequestHeaders.Remove("Host");
	}
	
	public static char[] SimpleGet(string url)
	{
		scope Http http = new Http(url);
		return http.Get();
	}
	
	public static char[] SimpleGet(Uri url)
	{
		scope Http http = new Http(url);
		return http.Get();
	}
	
	public static char[] SimplePost(string url, HttpPostData data)
	{
		scope Http http = new Http(url);
		return http.Post(data);
	}
	
	public static char[] SimplePost(Uri url, HttpPostData data)
	{
		scope Http http = new Http(url);
		return http.Post(data);
	}
}
/+
import std.socket 		: Socket, TcpSocket, InternetAddress, SocketOptionLevel, SocketOption;
import std.stream       : Stream, BufferedFile, FileMode;
import std.string 		: strip, toLower, indexOf, splitLines;
import std.conv 		: to, parse;
import std.traits 		: isSomeString, isMutable, Unqual;

import core.time;

import dragonov.net.Uri;
import dragonov.io.Console;

import std.zlib;

// debug
debug(Http)
{
    import std.stdio;
}
   
/**
 * HTTP request method
 */
enum RequestMethod : string
{
    Get 	= "GET",
    Post 	= "POST",
    Put		= "PUT",
    Delete  = "DELETE",
    Trace	= "TRACE",
    Head	= "HEAD",
    Options	= "OPTIONS",
    Connect = "CONNECT"
}

private enum bufferSize = 1024;

/**
 * Represents single HTTP header
 */
struct Header
{
    string name;
    string value;
}

/**
 * Represents HTTP headers
 */
struct Headers
{
    protected 
    {
        /// Response Code
        ushort _code;
        
        /// Headers
        Header[] _headers;
    }
    
    /**
     * Sets header value
     * 
     * Params:
     *  name    =   Header name
     *  value   =   Value to set
     */
    void set(V)(string name, V value)
    {
        add(name, to!(string)(value));
    }

    /**
     * Checks if header exists
     * 
     * Params:
     *  name    =   Header name to check
     * 
     * Returns:
     *  True if header exists, false otherwise
     */
    bool exist(string name)
    {
        foreach ( cur; _headers )
        {
            if ( toLower(cur.name) == toLower(name) )
            {
                return true;
            }
        }

        return false;
    }

    /**
     * Adds new header
     * 
     * Params:
     *  name    =   Header name
     *  value   =   Value to set
     */
    void add(string name, string value)
    {
        foreach (ref cur; _headers )
        {
            if ( toLower(cur.name) == toLower(name) )
            {
                cur.value = value;
                return;
            }
        }

        _headers ~= Header(name, value);
    }
    
    /**
     * Returns header value
     * 
     * Params:
     *  name    =   Header name to get
     * 
     * Returns:
     *  Header value, as string
     */
    string get(string name)
    {
        foreach (_value; _headers)
        {
            if ( toLower(_value.name) == toLower(name) )
            {
                return _value.value;
            }
        }

        // Throw exception?
        
        return null;
    }
    
    /**
     * Returns HTTP response code
     * 
     * Returns:
     *  HTTP response code
     */
    ushort code()
    {
        return _code;
    }
    
    string opIndex(string name)
    {
        return get(name);
    }
	
	void opIndexAssign(string value, string name) {
		set(name, value);
	}
	
    int opApply (int delegate(ref Header) dg)
    {
        Header   cur;
        int      result = 0;

        foreach (Header header; _headers)
        {
            cur.name = header.name;
            cur.value = header.value;
            result = dg(cur);
            
            if (result)
                break;
        }

        return result;
    }
    
    void parseStream(Socket _ss)
    {
        char[bufferSize] buffer;
        char[1] Char;
        size_t len = 0;
        size_t totalLen = 0;
        
        while (true)
        {
            len = _ss.receive(Char);
            if ( len < 1 ) break;
            
            buffer[totalLen++] = Char[0];
            
            if ( totalLen > 8 )
            {
                if ( buffer[totalLen - 8 .. totalLen - 4] == "\r\n\r\n" )
                {
                    break;
                }
            }
        }
        
        sizediff_t pos;
        
        foreach (line; buffer[0..totalLen].splitLines())
        {
            pos = line.indexOf(": ");
            
            if ( pos != -1 )
            {
                set(line[0..pos].idup, line[pos+2..$].idup);
            }
            else
            {
                if ( line.length > 4 )
                {
                    if ( line[0..4] == "HTTP")
                    {
                        _code = to!(ushort)(line[9..12]);
                    }
                }
            }
        }
    }
}


 
/**
 * HTTP client class 
 * 
 * Example:
 * ---------
 * auto http = new Http("http://google.com");
 * http.get(new BufferedFile("googlecontents.html", FileMode.Out));
 * ---------
 */
class HttpClient
{
    	
        Socket _sock;  
        RequestMethod _method;
        Uri _uri;
        
        /// HTTP protocol version
        ushort _httpVersion = 1;
        
        /// Server response headers
        Headers _responseHeaders;
        alias _responseHeaders responseHeaders;
        
        /// Server request headers
        Headers _requestHeaders;
        alias _requestHeaders requestHeaders;
        long _timeout = 3000;
        
    bool FollowLocation = true;
    
    /**
     * Creates new HTTPClient object from URL
     * 
     * Params:
     * 	url	=	Web site URL, http(s):// can be omitted
     * 	method	=	Request method
     * 
     * 
     */
    this(Uri uri, RequestMethod method = RequestMethod.Get)
    {
        _uri = uri;
        _method = method;
        _responseHeaders = Headers();
        _requestHeaders  = Headers();        
    }
    
    /**
     * Creates new HTTPClient object from domain, port and url
     * 
     * Params:
     * 	domain	=	Domain to connect to
     * 	port	=	Port to connect on
     * 	url		=	URL to send request to
     * 
     * Example:
     * --------
     * auto http = new Http("http://google.com", 80);
     * --------
     */
    this(string uri, RequestMethod method = RequestMethod.Get)
    {
		this(Uri(uri));
	}
    
    /**
     * Opens connection to server
     */
    void open()
    {
        _sock = new TcpSocket(new InternetAddress(_uri.Domain, _uri.Port));
        _sock.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, dur!("msecs")(_timeout));
        _sock.send(buildRequest());
        getResponse();
    }
    
    /**
     * Closes connection
     */
    void close()
    {
        _sock.close();
    }
    
    /**
     * Creates request
     * 
     * Returns:
     * 	Request as string
     */
    string buildRequest()
    {
        string request;
  
		/// HTTP method
        request ~= to!string(_method) ~ " ";
        
        /// URL and Protocol version
        request ~= _uri.Path ~ " " ~ ["HTTP/1.0", "HTTP/1.1"][_httpVersion];
        
        /// Host
        request ~= "\r\nHost: " ~ _uri.Domain ~ "\r\n";
        
        foreach ( currentHeader; _requestHeaders )
        {
            request ~= currentHeader.name ~ ": " ~ currentHeader.value ~ "\r\n";
        }
        
        request ~= "\r\n";
        
        return request;                       
    }
    
    /**
     * Gets server response: headers and content
     */    
    protected void getResponse()
    {
        _responseHeaders.parseStream(_sock); 
        
        int length = -1;
        
        if( _responseHeaders.exist("Content-Length") )
            length = to!int(_responseHeaders["Content-Length"]);

       
        if ( (_responseHeaders.code == 301 || _responseHeaders.code == 302 || _responseHeaders.code == 303 ) && 
                FollowLocation == true && _responseHeaders.exist("Location") )
        {
            _uri.Parse(_responseHeaders["Location"]);
            close();
            open();
        }
    }

	size_t get()(scope void delegate(void[] data) func)
	{
		if ( responseHeaders.code() != 200 ) 
        {
            return 0;
        }
        
        void[bufferSize] _char = void;
        
        sizediff_t len;
        size_t totalLen = 0;
        
        while (true)
        {
            len = _sock.receive(_char);
            if (len < 1) break;
           
            func(_char);
            
            totalLen += len;
           
            //if ( len < bufferSize ) break;
        }
        
        return totalLen;
	}
	
    T[] get(T = immutable(char))()
    {
		if ( responseHeaders.code() != 200 ) 
        {
            return null;
        }
        
        T[] buffer;
        char[bufferSize] _char;
        
        sizediff_t len;
        
        while (true)
        {
            len = _sock.receive(_char);
            if (len < 1) break;
           
            buffer ~= cast(T[]) _char[0..len];
        }
        
        return buffer[0..$];
    }
    
    /**
     * Returns contents with operating on specified buffer
     * 
     * Params:
     *  buffer  =   Buffer to work on
     * 
     * Returns:
     *  Contents
     */
    size_t get(T)(ref T buffer)
    if (isMutable!(T) && ( is(Unqual!(typeof(T[0])) : char) ||
         is(Unqual!(typeof(T[0])) : ubyte) || is(Unqual!(typeof(T[0])) : void)))
    {
        if ( responseHeaders.code() != 200 ) 
        {
            return 0;
        }
        
        typeof(T[0])[bufferSize] _char = void;
        
        sizediff_t len;
        size_t totalLen = 0;
        
        while (true)
        {
            len = _sock.receive(_char);
            if (len < 1) break;
           
            if (totalLen + len > buffer.length) {
                buffer[totalLen..$] = _char[0..buffer.length - totalLen];
                return totalLen;
            } else {
                buffer[totalLen..totalLen+len] = _char[0..len];
            }
            
            totalLen += len;
           
            if ( len < bufferSize ) break;
        }
        
        return totalLen;
    }   
    
    /**
     * Returns: Request method
     */
    RequestMethod method() const
    {
        return _method;
    }
    
    /**
     * Sets HTTP request method
     * 
     * Params:
     * 	method = Request method
     */
    void method(RequestMethod method)
    {
        _method = method;
    }
    
    /**
     * Returns: HTTP version
     */
    ushort httpVersion() const
    {
        return _httpVersion;
    }
    
    /**
     * Sets HTTP version
     * 
     * Params:
     * 	ver =	HTTP version, 0 - HTTP/1.0, 1 - HTTP/1.1
     */
    void httpVersion(ushort ver)
    {
        _httpVersion = ver ? 1 : 0;
    }
    
    long timeOut() const {
        return _timeout;
    }
    
    void timeOut(long msecs) {
        _timeout = msecs;
    }
}



debug(Http)
{
    void main()
    {
        auto http = new Http("http://google.com/");
        
        http.requestHeaders["Accept-Charset"] = "UTF-8,*";
        //http.requestHeaders.set("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1");
        http.requestHeaders["Accept-Language"] = "en-us,en;q=0.5";
        //http.requestHeaders.set("Accept-Encoding", "gzip");
        http.requestHeaders["Connection"] = "keep-alive";
        
        
        http.open();
        
        
        writeln("\nRequest headers are: ");
        foreach( header; http.requestHeaders() )
        {
            writeln("Name: ", header.name, " -> Value: ", header.value);
        }
       
        
        writeln("\nResponse code: ", http.responseHeaders.code);
        writeln("Response headers are: ");
        foreach( header; http.responseHeaders() )
            writeln("Name: ", header.name, " -> Value: ", header.value);
        
        writeln("Content-Type will be: ", http.responseHeaders["Content-Type"]);
        
        writeln("\nPage content:");
        http.get(new BufferedFile("webpaage.html", FileMode.Out));
        
        http.close();
    }
}
/// Ditto
alias HttpClient Http;
+/