module dragonov.net.im.GaduGadu;
/+
import dragonov.sys.DynamicLib;
import dragonov.io.Console;

import core.thread;
import std.string;
import std.socket;

class GaduGadu
{
	enum
	{
		Avaible = 0x0002,
		Busy,
		Invisible = 0x0014,
		Disconnected,
	}
	private uint _number;
	private string _password;
	private gg_session* _session;
	//private Loader _loader;
	
	this()
    {
    	/*_loader = Loader("libgadu");
    	
    	//
		_loader.LoadSymbol("gg_login", gg_login);
		_loader.LoadSymbol("gg_ping", gg_ping);
		_loader.LoadSymbol("gg_notify", gg_notify);
		_loader.LoadSymbol("gg_send_message", gg_send_message);
		_loader.LoadSymbol("gg_logoff", gg_logoff);
		_loader.LoadSymbol("gg_free_session", gg_free_session);
		
		Console.Write(&gg_ping);*/
	}
	
	this(uint number, string password)
	{
		_number = number;
		_password = password;
		
		this();
	}
	
	void Connect()
	{
		auto loginData = gg_login_params(_number, toStringz(_password));
		loginData.status = Avaible;
		loginData.async = true;
		
		_session = gg_login(&loginData);
		
		if (_session is null)
		{
			throw new GaduGaduException("Can't login to");
		}
		
		gg_notify(_session, null, 0);
	}
	
	void Disconnect()
	{
		gg_logoff(_session);
        gg_free_session(_session);
	}
	
	void Status(int status, string description)
	{
	
	}
	
	void Run()
	{
		while (true)
		{
			gg_ping(_session);
			Thread.sleep(dur!("seconds")(5));
		}
	}
	
	void SendMessage(uint number, string message)
	{
		gg_ping(_session);
		gg_send_message(_session, 0x0008, number, toStringz(message));
		gg_ping(_session);
	}
}

class GaduGaduException : Exception
{
	this(string message)
	{
		super(message);
	}
}
/+
private:
	alias ubyte uint8_t;
	alias ushort uint16_t;
	alias uint uint32_t;
	alias byte int8_t;
	alias short int16_t;
	alias int int32_t;
	alias uint32_t uin_t;


struct gg_login_params
{
    uin_t uin;
    const char* password;
    int async;
    int status;
    const char *status_descr;
    uint32_t server_addr;
    uint16_t server_port;
    uint32_t client_addr;
    uint16_t client_port;
    int protocol_version;
    char *client_version;
    int has_audio;
    int last_sysmsg;
    uint32_t external_addr;
    uint16_t external_port;
    int tls;
    int image_size;
    int era_omnix;
    int hash_type;
    int encoding;
    int resolver;
    int protocol_features;
    int status_flags;
    char [4]dummy;
}


struct gg_event;

struct gg_session;

extern(C)
{
	gg_session* function(gg_login_params*) gg_login;
	int function(gg_session*) gg_ping;
	int function(gg_session*, uint*, int) gg_notify;
	int function(gg_session*, int, uint, const char*) gg_send_message;
	void function(gg_session*) gg_logoff;
	void function(gg_session*) gg_free_session;
	
}

 

import std.c.time;

extern (C):

alias ubyte uint8_t;
alias ushort uint16_t;
alias uint uint32_t;
alias byte int8_t;
alias short int16_t;
alias int int32_t;

alias uint32_t uin_t;

struct gg_dcc7_id_t
{
    uint8_t [8]id;
}

struct gg_multilogon_id_t
{
    uint8_t [8]id;
}

struct in_addr
{
        int s_addr;
}

struct gg_common
{
    int fd;
    int check;
    int state;
    int error;
    int type;
    int id;
    int timeout;
    int  function(gg_common *)callback;
    void  function(gg_common *)destroy;
}

enum
{
    GG_RESOLVER_DEFAULT,
    GG_RESOLVER_FORK,
    GG_RESOLVER_PTHREAD,
    GG_RESOLVER_CUSTOM,
    GG_RESOLVER_INVALID = -1,
}
alias int gg_resolver_t;

enum
{
    GG_ENCODING_CP1250,
    GG_ENCODING_UTF8,
    GG_ENCODING_INVALID = -1,
}
alias int gg_encoding_t;

struct gg_session
{
    int fd;
    int check;
    int state;
    int error;
    int type;
    int id;
    int timeout;
    int  function(gg_session *)callback;
    void  function(gg_session *)destroy;
    int async;
    int pid;
    int port;
    int seq;
    int last_pong;
    int last_event;
    gg_event *event;
    uint32_t proxy_addr;
    uint16_t proxy_port;
    uint32_t hub_addr;
    uint32_t server_addr;
    uint32_t client_addr;
    uint16_t client_port;
    uint32_t external_addr;
    uint16_t external_port;
    uin_t uin;
    const char *password;
    int initial_status;
    int status;
    char *recv_buf;
    int recv_done;
    int recv_left;
    int protocol_version;
    char *client_version;
    int last_sysmsg;
    char *initial_descr;
    void *resolver;
    char *header_buf;
    uint header_done;
    void *ssl;
    void *ssl_ctx;
    int image_size;
    char *userlist_reply;
    int userlist_blocks;
    gg_image_queue *images;
    int hash_type;
    char *send_buf;
    int send_left;
    gg_dcc7 *dcc7_list;
    int soft_timeout;
    int protocol_flags;
    gg_encoding_t encoding;
    gg_resolver_t resolver_type;
    int  function(int *fd, void **private_data, char *hostname)resolver_start;
    void  function(void **private_data, int force)resolver_cleanup;
    int protocol_features;
    int status_flags;
    int recv_msg_count;
}

struct gg_http
{
    int fd;
    int check;
    int state;
    int error;
    int type;
    int id;
    int timeout;
    int  function(gg_http *)callback;
    void  function(gg_http *)destroy;
    int async;
    int pid;
    int port;
    char *query;
    char *header;
    int header_size;
    //char* body;
    uint body_size;
    void *data;
    char *user_data;
    void *resolver;
    uint body_done;
    gg_resolver_t resolver_type;
    int  function(int *fd, void **private_data, char *hostname)resolver_start;
    void  function(void **private_data, int force)resolver_cleanup;
}

const GG_MAX_PATH = 276;

struct gg_file_info
{
    uint32_t mode;
    uint32_t [2]ctime;
    uint32_t [2]atime;
    uint32_t [2]mtime;
    uint32_t size_hi;
    uint32_t size;
    uint32_t reserved0;
    uint32_t reserved1;
    ubyte [262]filename;
    ubyte [14]short_filename;
}

struct gg_dcc
{
    int fd;
    int check;
    int state;
    int error;
    int type;
    int id;
    int timeout;
    int  function(gg_dcc *)callback;
    void  function(gg_dcc *)destroy;
    gg_event *event;
    int active;
    int port;
    uin_t uin;
    uin_t peer_uin;
    int file_fd;
    uint offset;
    uint chunk_size;
    uint chunk_offset;
    gg_file_info file_info;
    int established;
    char *voice_buf;
    int incoming;
    char *chunk_buf;
    uint32_t remote_addr;
    uint16_t remote_port;
}


const GG_DCC7_HASH_LEN = 20;
const GG_DCC7_FILENAME_LEN = 255;
const GG_DCC7_INFO_LEN = 32;
const GG_DCC7_INFO_HASH_LEN = 32;

struct gg_dcc7
{
    int fd;
    int check;
    int state;
    int error;
    int type;
    int id;
    int timeout;
    int  function(gg_dcc7 *)callback;
    void  function(gg_dcc7 *)destroy;
    gg_dcc7_id_t cid;
    gg_event *event;
    uin_t uin;
    uin_t peer_uin;
    int file_fd;
    uint offset;
    uint size;
    ubyte [256]filename;
    ubyte [20]hash;
    int dcc_type;
    int established;
    int incoming;
    int reverse;
    uint32_t local_addr;
    uint16_t local_port;
    uint32_t remote_addr;
    uint16_t remote_port;
    gg_session *sess;
    gg_dcc7 *next;
    int soft_timeout;
    int seek;
    void *resolver;
    int relay;
    int relay_index;
    int relay_count;
    void* elay_list;
  //  gg_dcc7_relay *relay_list; // TODO zmienione
}

enum gg_session_t
{
    GG_SESSION_GG = 1,
    GG_SESSION_HTTP,
    GG_SESSION_SEARCH,
    GG_SESSION_REGISTER,
    GG_SESSION_REMIND,
    GG_SESSION_PASSWD,
    GG_SESSION_CHANGE,
    GG_SESSION_DCC,
    GG_SESSION_DCC_SOCKET,
    GG_SESSION_DCC_SEND,
    GG_SESSION_DCC_GET,
    GG_SESSION_DCC_VOICE,
    GG_SESSION_USERLIST_GET,
    GG_SESSION_USERLIST_PUT,
    GG_SESSION_UNREGISTER,
    GG_SESSION_USERLIST_REMOVE,
    GG_SESSION_TOKEN,
    GG_SESSION_DCC7_SOCKET,
    GG_SESSION_DCC7_SEND,
    GG_SESSION_DCC7_GET,
    GG_SESSION_DCC7_VOICE,
    GG_SESSION_USER0 = 256,
    GG_SESSION_USER1,
    GG_SESSION_USER2,
    GG_SESSION_USER3,
    GG_SESSION_USER4,
    GG_SESSION_USER5,
    GG_SESSION_USER6,
    GG_SESSION_USER7,
}

enum gg_state_t
{
    GG_STATE_IDLE,
    GG_STATE_RESOLVING,
    GG_STATE_CONNECTING,
    GG_STATE_READING_DATA,
    GG_STATE_ERROR,
    GG_STATE_CONNECTING_HUB,
    GG_STATE_CONNECTING_GG,
    GG_STATE_READING_KEY,
    GG_STATE_READING_REPLY,
    GG_STATE_CONNECTED,
    GG_STATE_SENDING_QUERY,
    GG_STATE_READING_HEADER,
    GG_STATE_PARSING,
    GG_STATE_DONE,
    GG_STATE_LISTENING,
    GG_STATE_READING_UIN_1,
    GG_STATE_READING_UIN_2,
    GG_STATE_SENDING_ACK,
    GG_STATE_READING_ACK,
    GG_STATE_READING_REQUEST,
    GG_STATE_SENDING_REQUEST,
    GG_STATE_SENDING_FILE_INFO,
    GG_STATE_READING_PRE_FILE_INFO,
    GG_STATE_READING_FILE_INFO,
    GG_STATE_SENDING_FILE_ACK,
    GG_STATE_READING_FILE_ACK,
    GG_STATE_SENDING_FILE_HEADER,
    GG_STATE_READING_FILE_HEADER,
    GG_STATE_GETTING_FILE,
    GG_STATE_SENDING_FILE,
    GG_STATE_READING_VOICE_ACK,
    GG_STATE_READING_VOICE_HEADER,
    GG_STATE_READING_VOICE_SIZE,
    GG_STATE_READING_VOICE_DATA,
    GG_STATE_SENDING_VOICE_ACK,
    GG_STATE_SENDING_VOICE_REQUEST,
    GG_STATE_READING_TYPE,
    GG_STATE_TLS_NEGOTIATION,
    GG_STATE_REQUESTING_ID,
    GG_STATE_WAITING_FOR_ACCEPT,
    GG_STATE_WAITING_FOR_INFO,
    GG_STATE_READING_ID,
    GG_STATE_SENDING_ID,
    GG_STATE_RESOLVING_GG,
    GG_STATE_RESOLVING_RELAY,
    GG_STATE_CONNECTING_RELAY,
    GG_STATE_READING_RELAY,
    GG_STATE_DISCONNECTING,
}

enum gg_check_t
{
    GG_CHECK_NONE,
    GG_CHECK_WRITE,
    GG_CHECK_READ,
}

enum
{
    GG_SSL_DISABLED,
    GG_SSL_ENABLED,
    GG_SSL_REQUIRED,
}
alias int gg_ssl_t;

struct gg_login_params
{
        this (int number, const char* pass )
        {
                uin = number;
                password = pass;
        }
    uin_t uin;
    const char* password;
    int async;
    int status;
    const char *status_descr;
    uint32_t server_addr;
    uint16_t server_port;
    uint32_t client_addr;
    uint16_t client_port;
    int protocol_version;
    char *client_version;
    int has_audio;
    int last_sysmsg;
    uint32_t external_addr;
    uint16_t external_port;
    int tls;
    int image_size;
    int era_omnix;
    int hash_type;
    gg_encoding_t encoding;
    gg_resolver_t resolver;
    int protocol_features;
    int status_flags;
    char [4]dummy;
}

gg_session * gg_login(gg_login_params *p);
void  gg_free_session(gg_session *sess);
void  gg_logoff(gg_session *sess);
int  gg_change_status(gg_session *sess, int status);
int  gg_change_status_descr(gg_session *sess, int status, const char *descr);
int  gg_change_status_descr_time(gg_session *sess, int status, char *descr, int time);
int  gg_change_status_flags(gg_session *sess, int flags);
int  gg_send_message(gg_session *sess, int msgclass, uin_t recipient, const char *message);
int  gg_send_message_richtext(gg_session *sess, int msgclass, uin_t recipient, ubyte *message, ubyte *format, int formatlen);
int  gg_send_message_confer(gg_session *sess, int msgclass, int recipients_count, uin_t *recipients, ubyte *message);
int  gg_send_message_confer_richtext(gg_session *sess, int msgclass, int recipients_count, uin_t *recipients, ubyte *message, ubyte *format, int formatlen);
int  gg_send_message_ctcp(gg_session *sess, int msgclass, uin_t recipient, ubyte *message, int message_len);
int  gg_ping(gg_session *sess);
int  gg_userlist_request(gg_session *sess, char type, char *request);
int  gg_userlist100_request(gg_session *sess, char type, uint version_, char format_type, char *request);
int  gg_image_request(gg_session *sess, uin_t recipient, int size, uint32_t crc32);
int  gg_image_reply(gg_session *sess, uin_t recipient, char *filename, char *image, int size);
int  gg_typing_notification(gg_session *sess, uin_t recipient, int length);

uint32_t  gg_crc32(uint32_t crc, ubyte *buf, int len);
int  gg_session_set_resolver(gg_session *gs, gg_resolver_t type);
gg_resolver_t  gg_session_get_resolver(gg_session *gs);
int  gg_session_set_custom_resolver(gg_session *gs, int  function(int *, void **, char *)resolver_start, void  function(void **, int )resolver_cleanup);

int  gg_http_set_resolver(gg_http *gh, gg_resolver_t type);
gg_resolver_t  gg_http_get_resolver(gg_http *gh);
int  gg_http_set_custom_resolver(gg_http *gh, int  function(int *, void **, char *)resolver_start, void  function(void **, int )resolver_cleanup);

int  gg_global_set_resolver(gg_resolver_t type);
gg_resolver_t  gg_global_get_resolver();
int  gg_global_set_custom_resolver(int  function(int *, void **, char *)resolver_start, void  function(void **, int )resolver_cleanup);

int  gg_multilogon_disconnect(gg_session *gs, gg_multilogon_id_t conn_id);

enum gg_event_t
{
    GG_EVENT_NONE,
    GG_EVENT_MSG,
    GG_EVENT_NOTIFY,
    GG_EVENT_NOTIFY_DESCR,
    GG_EVENT_STATUS,
    GG_EVENT_ACK,
    GG_EVENT_PONG,
    GG_EVENT_CONN_FAILED,
    GG_EVENT_CONN_SUCCESS,
    GG_EVENT_DISCONNECT,
    GG_EVENT_DCC_NEW,
    GG_EVENT_DCC_ERROR,
    GG_EVENT_DCC_DONE,
    GG_EVENT_DCC_CLIENT_ACCEPT,
    GG_EVENT_DCC_CALLBACK,
    GG_EVENT_DCC_NEED_FILE_INFO,
    GG_EVENT_DCC_NEED_FILE_ACK,
    GG_EVENT_DCC_NEED_VOICE_ACK,
    GG_EVENT_DCC_VOICE_DATA,
    GG_EVENT_PUBDIR50_SEARCH_REPLY,
    GG_EVENT_PUBDIR50_READ,
    GG_EVENT_PUBDIR50_WRITE,
    GG_EVENT_STATUS60,
    GG_EVENT_NOTIFY60,
    GG_EVENT_USERLIST,
    GG_EVENT_IMAGE_REQUEST,
    GG_EVENT_IMAGE_REPLY,
    GG_EVENT_DCC_ACK,
    GG_EVENT_DCC7_NEW,
    GG_EVENT_DCC7_ACCEPT,
    GG_EVENT_DCC7_REJECT,
    GG_EVENT_DCC7_CONNECTED,
    GG_EVENT_DCC7_ERROR,
    GG_EVENT_DCC7_DONE,
    GG_EVENT_DCC7_PENDING,
    GG_EVENT_XML_EVENT,
    GG_EVENT_DISCONNECT_ACK,
    GG_EVENT_TYPING_NOTIFICATION,
    GG_EVENT_USER_DATA,
    GG_EVENT_MULTILOGON_MSG,
    GG_EVENT_MULTILOGON_INFO,
    GG_EVENT_USERLIST100_VERSION,
    GG_EVENT_USERLIST100_REPLY,
}

alias void* GG_EVENT_SEARCH50_REPLY;

enum gg_failure_t
{
    GG_FAILURE_RESOLVING = 1,
    GG_FAILURE_CONNECTING,
    GG_FAILURE_INVALID,
    GG_FAILURE_READING,
    GG_FAILURE_WRITING,
    GG_FAILURE_PASSWORD,
    GG_FAILURE_404,
    GG_FAILURE_TLS,
    GG_FAILURE_NEED_EMAIL,
    GG_FAILURE_INTRUDER,
    GG_FAILURE_UNAVAILABLE,
    GG_FAILURE_PROXY,
    GG_FAILURE_HUB,
}

enum gg_error_t
{
    GG_ERROR_RESOLVING = 1,
    GG_ERROR_CONNECTING,
    GG_ERROR_READING,
    GG_ERROR_WRITING,
    GG_ERROR_DCC_HANDSHAKE,
    GG_ERROR_DCC_FILE,
    GG_ERROR_DCC_EOF,
    GG_ERROR_DCC_NET,
    GG_ERROR_DCC_REFUSED,
    GG_ERROR_DCC7_HANDSHAKE,
    GG_ERROR_DCC7_FILE,
    GG_ERROR_DCC7_EOF,
    GG_ERROR_DCC7_NET,
    GG_ERROR_DCC7_REFUSED,
    GG_ERROR_DCC7_RELAY,
}

struct gg_pubdir50_entry
{
    int num;
    char *field;
    char *value;
}

struct gg_pubdir50_s
{
    int count;
    uin_t next;
    int type;
    uint32_t seq;
    gg_pubdir50_entry *entries;
    int entries_count;
}

alias gg_pubdir50_s *gg_pubdir50_t;

struct gg_event_msg
{
    uin_t sender;
    int msgclass;
    time_t time;
    ubyte *message;
    int recipients_count;
    uin_t *recipients;
    int formats_length;
    void *formats;
    uint32_t seq;
    char *xhtml_message;
}

struct gg_event_notify_descr
{
    gg_notify_reply *notify;
    char *descr;
}

struct gg_event_status
{
    uin_t uin;
    uint32_t status;
    char *descr;
}

struct gg_event_status60
{
    uin_t uin;
    int status;
    uint32_t remote_ip;
    uint16_t remote_port;
    int version_;
    int image_size;
    char *descr;
    time_t time;
}

struct gg_event_notify60
{
    uin_t uin;
    int status;
    uint32_t remote_ip;
    uint16_t remote_port;
    int version_;
    int image_size;
    char *descr;
    time_t time;
}

struct gg_event_ack
{
    uin_t recipient;
    int status;
    int seq;
}

struct gg_event_userlist
{
    char type;
    char *reply;
}

struct gg_event_dcc_voice_data
{
    uint8_t *data;
    int length;
}

struct gg_event_image_request
{
    uin_t sender;
    uint32_t size;
    uint32_t crc32;
}

struct gg_event_image_reply
{
    uin_t sender;
    uint32_t size;
    uint32_t crc32;
    char *filename;
    char *image;
}

struct gg_event_xml_event
{
    char *data;
}

struct gg_event_dcc7_connected
{
    gg_dcc7 *dcc7;
}

struct gg_event_dcc7_pending
{
    gg_dcc7 *dcc7;
}

struct gg_event_dcc7_reject
{
    gg_dcc7 *dcc7;
    int reason;
}

struct gg_event_dcc7_accept
{
    gg_dcc7 *dcc7;
    int type;
    uint32_t remote_ip;
    uint16_t remote_port;
}

struct gg_event_dcc7_done
{
    gg_dcc7 *dcc7;
}

struct gg_event_typing_notification
{
    uin_t uin;
    int length;
}

struct gg_event_user_data_attr
{
    int type;
    char *key;
    char *value;
}

struct gg_event_user_data_user
{
    uin_t uin;
    size_t attr_count;
    gg_event_user_data_attr *attrs;
}

struct gg_event_user_data
{
    int type;
    size_t user_count;
    gg_event_user_data_user *users;
}

struct gg_multilogon_session
{
    gg_multilogon_id_t id;
    char *name;
    uint32_t remote_addr;
    int status_flags;
    int protocol_features;
    time_t logon_time;
}

struct gg_event_multilogon_info
{
    int count;
    gg_multilogon_session *sessions;
}

struct gg_event_userlist100_version
{
    uint32_t version_;
}

struct gg_event_userlist100_reply
{
    char type;
    uint32_t version_;
    char format_type;
    char *reply;
}

union gg_event_union
{
    gg_failure_t failure;
    gg_notify_reply *notify;
    gg_event_notify_descr notify_descr;
    gg_event_status status;
    gg_event_status60 status60;
    gg_event_notify60 *notify60;
    gg_event_msg msg;
    gg_event_ack ack;
    gg_event_image_request image_request;
    gg_event_image_reply image_reply;
    gg_event_userlist userlist;
    gg_pubdir50_t pubdir50;
    gg_event_xml_event xml_event;
    gg_dcc *dcc_new;
    gg_error_t dcc_error;
    gg_event_dcc_voice_data dcc_voice_data;
    gg_dcc7 *dcc7_new;
    gg_error_t dcc7_error;
    gg_event_dcc7_connected dcc7_connected;
    gg_event_dcc7_pending dcc7_pending;
    gg_event_dcc7_reject dcc7_reject;
    gg_event_dcc7_accept dcc7_accept;
    gg_event_dcc7_done dcc7_done;
    gg_event_typing_notification typing_notification;
    gg_event_user_data user_data;
    gg_event_msg multilogon_msg;
    gg_event_multilogon_info multilogon_info;
    gg_event_userlist100_version userlist100_version;
    gg_event_userlist100_reply userlist100_reply;
}

struct gg_event
{
    int type;
    gg_event_union event;
}

gg_event * gg_watch_fd(gg_session *sess);
void  gg_event_free(gg_event *e);

int  gg_notify_ex(gg_session *sess, uin_t *userlist, char *types, int count);
int  gg_notify(gg_session *sess, uin_t *userlist, int count);
int  gg_add_notify_ex(gg_session *sess, uin_t uin, char type);
int  gg_add_notify(gg_session *sess, uin_t uin);
int  gg_remove_notify_ex(gg_session *sess, uin_t uin, char type);
int  gg_remove_notify(gg_session *sess, uin_t uin);

gg_http * gg_http_connect(char *hostname, int port, int async, char *method, char *path, char *header);
int  gg_http_watch_fd(gg_http *h);
void  gg_http_stop(gg_http *h);
void  gg_http_free(gg_http *h);

uint32_t  gg_pubdir50(gg_session *sess, gg_pubdir50_t req);
gg_pubdir50_t  gg_pubdir50_new(int type);
int  gg_pubdir50_add(gg_pubdir50_t req, char *field, char *value);
int  gg_pubdir50_seq_set(gg_pubdir50_t req, uint32_t seq);
char * gg_pubdir50_get(gg_pubdir50_t res, int num, char *field);
int  gg_pubdir50_type(gg_pubdir50_t res);
int  gg_pubdir50_count(gg_pubdir50_t res);
uin_t  gg_pubdir50_next(gg_pubdir50_t res);
uint32_t  gg_pubdir50_seq(gg_pubdir50_t res);
void  gg_pubdir50_free(gg_pubdir50_t res);

struct gg_pubdir
{
    int success;
    uin_t uin;
}

int  gg_pubdir_watch_fd(gg_http *f);
void  gg_pubdir_free(gg_http *f);

struct gg_token_
{
    int width;
    int height;
    int length;
    char *tokenid;
}

gg_http* gg_token(int async);
int  gg_token_watch_fd(gg_http *h);
void  gg_token_free(gg_http *h);

gg_http * gg_register3(char *email, char *password, char *tokenid, char *tokenval, int async);
alias gg_pubdir_watch_fd gg_register_watch_fd;
alias gg_pubdir_free gg_register_free;

gg_http * gg_unregister3(uin_t uin, char *password, char *tokenid, char *tokenval, int async);
alias gg_pubdir_watch_fd gg_unregister_watch_fd;
alias gg_pubdir_free gg_unregister_free;

gg_http * gg_remind_passwd3(uin_t uin, char *email, char *tokenid, char *tokenval, int async);
alias gg_pubdir_watch_fd gg_remind_passwd_watch_fd;
alias gg_pubdir_free gg_remind_passwd_free;

gg_http * gg_change_passwd4(uin_t uin, char *email, char *passwd, char *newpasswd, char *tokenid, char *tokenval, int async);
alias gg_pubdir_watch_fd gg_change_passwd_watch_fd;
alias gg_pubdir_free gg_change_passwd_free;

extern int gg_dcc_port;
extern uint gg_dcc_ip;

int  gg_dcc_request(gg_session *sess, uin_t uin);

gg_dcc * gg_dcc_send_file(uint32_t ip, uint16_t port, uin_t my_uin, uin_t peer_uin);
gg_dcc * gg_dcc_get_file(uint32_t ip, uint16_t port, uin_t my_uin, uin_t peer_uin);
gg_dcc * gg_dcc_voice_chat(uint32_t ip, uint16_t port, uin_t my_uin, uin_t peer_uin);
void  gg_dcc_set_type(gg_dcc *d, int type);
int  gg_dcc_fill_file_info(gg_dcc *d, char *filename);
int  gg_dcc_fill_file_info2(gg_dcc *d, char *filename, char *local_filename);
int  gg_dcc_voice_send(gg_dcc *d, char *buf, int length);

const GG_DCC_VOICE_FRAME_LENGTH = 195;
const GG_DCC_VOICE_FRAME_LENGTH_505 = 326;
gg_dcc * gg_dcc_socket_create(uin_t uin, uint16_t port);
alias gg_dcc_free gg_dcc_socket_free;
alias gg_dcc_watch_fd gg_dcc_socket_watch_fd;

gg_event * gg_dcc_watch_fd(gg_dcc *d);

void  gg_dcc_free(gg_dcc *c);

gg_event * gg_dcc7_watch_fd(gg_dcc7 *d);
gg_dcc7 * gg_dcc7_send_file(gg_session *sess, uin_t rcpt, char *filename, char *filename1250, char *hash);
gg_dcc7 * gg_dcc7_send_file_fd(gg_session *sess, uin_t rcpt, int fd, size_t size, char *filename1250, char *hash);
int  gg_dcc7_accept(gg_dcc7 *dcc, uint offset);
int  gg_dcc7_reject(gg_dcc7 *dcc, int reason);
void  gg_dcc7_free(gg_dcc7 *d);

extern int gg_debug_level;
extern void  function(int level, char *format,...)gg_debug_handler;
extern void  function(gg_session *sess, int level, char *format,...)gg_debug_handler_session;

extern int FILE;

const GG_DEBUG_NET = 1;
const GG_DEBUG_TRAFFIC = 2;
const GG_DEBUG_DUMP = 4;
const GG_DEBUG_FUNCTION = 8;
const GG_DEBUG_MISC = 16;

void  gg_debug(int level, char *format,...);
void  gg_debug_session(gg_session *sess, int level, char *format,...);
char * gg_libgadu_version();

enum
{
    GG_LIBGADU_FEATURE_SSL,
    GG_LIBGADU_FEATURE_PTHREAD,
    GG_LIBGADU_FEATURE_USERLIST100,
}
alias int gg_libgadu_feature_t;

int  gg_libgadu_check_feature(gg_libgadu_feature_t feature);

extern int gg_proxy_enabled;
extern char *gg_proxy_host;
extern int gg_proxy_port;
extern char *gg_proxy_username;
extern char *gg_proxy_password;
extern int gg_proxy_http_only;

extern uint gg_local_ip;

const GG_LOGIN_HASH_GG32 = 0x01;

const GG_LOGIN_HASH_SHA1 = 0x02;
const GG_PUBDIR50_WRITE = 0x01;
const GG_PUBDIR50_READ = 0x02;
const GG_PUBDIR50_SEARCH = 0x03;
alias GG_PUBDIR50_SEARCH GG_PUBDIR50_SEARCH_REQUEST;

const GG_PUBDIR50_SEARCH_REPLY = 0x05;


alias gg_event_free gg_free_event;
alias gg_http_free gg_free_http;
alias gg_pubdir_free gg_free_pubdir;
alias gg_pubdir_free gg_free_register;
alias gg_pubdir_free gg_free_remind_passwd;
alias gg_dcc_free gg_free_dcc;

alias gg_pubdir_free gg_free_change_passwd;

struct gg_search_request
{
    int active;
    uint start;
    char *nickname;
    char *first_name;
    char *last_name;
    char *city;
    int gender;
    int min_birth;
    int max_birth;
    char *email;
    char *phone;
    uin_t uin;
}

struct gg_search_
{
    int count;
    gg_search_result *results;
}

struct gg_search_result
{
    uin_t uin;
    char *first_name;
    char *last_name;
    char *nickname;
    int born;
    int gender;
    char *city;
    int active;
}

const GG_GENDER_NONE = 0;
const GG_GENDER_FEMALE = 1;

const GG_GENDER_MALE = 2;
gg_http * gg_search(gg_search_request *r, int async);
int  gg_search_watch_fd(gg_http *f);
void  gg_free_search(gg_http *f);

alias gg_free_search gg_search_free;
gg_search_request * gg_search_request_mode_0(char *nickname, char *first_name, char *last_name, char *city, int gender, int min_birth, int max_birth, int active, int start);
gg_search_request * gg_search_request_mode_1(char *email, int active, int start);
gg_search_request * gg_search_request_mode_2(char *phone, int active, int start);
gg_search_request * gg_search_request_mode_3(uin_t uin, int active, int start);
void  gg_search_request_free(gg_search_request *r);

gg_http * gg_register(char *email, char *password, int async);
gg_http * gg_register2(char *email, char *password, char *qa, int async);

gg_http * gg_unregister(uin_t uin, char *password, char *email, int async);
gg_http * gg_unregister2(uin_t uin, char *password, char *qa, int async);

gg_http * gg_remind_passwd(uin_t uin, int async);
gg_http * gg_remind_passwd2(uin_t uin, char *tokenid, char *tokenval, int async);

gg_http * gg_change_passwd(uin_t uin, char *passwd, char *newpasswd, char *newemail, int async);
gg_http * gg_change_passwd2(uin_t uin, char *passwd, char *newpasswd, char *email, char *newemail, int async);
gg_http * gg_change_passwd3(uin_t uin, char *passwd, char *newpasswd, char *qa, int async);

struct gg_change_info_request
{
    char *first_name;
    char *last_name;
    char *nickname;
    char *email;
    int born;
    int gender;
    char *city;
}

gg_change_info_request * gg_change_info_request_new(char *first_name, char *last_name, char *nickname, char *email, int born, int gender, char *city);
void  gg_change_info_request_free(gg_change_info_request *r);

gg_http * gg_change_info(uin_t uin, char *passwd, gg_change_info_request *request, int async);
alias gg_pubdir_watch_fd gg_change_pubdir_watch_fd;
alias gg_pubdir_free gg_change_pubdir_free;

alias gg_pubdir_free gg_free_change_pubdir;
gg_http * gg_userlist_get(uin_t uin, char *password, int async);
int  gg_userlist_get_watch_fd(gg_http *f);
void  gg_userlist_get_free(gg_http *f);

gg_http * gg_userlist_put(uin_t uin, char *password, char *contacts, int async);
int  gg_userlist_put_watch_fd(gg_http *f);
void  gg_userlist_put_free(gg_http *f);

gg_http * gg_userlist_remove(uin_t uin, char *password, int async);
int  gg_userlist_remove_watch_fd(gg_http *f);
void  gg_userlist_remove_free(gg_http *f);

int  gg_pubdir50_handle_reply(gg_event *e, char *packet, int length);

int  gg_file_hash_sha1(int fd, uint8_t *result);

char * gg_saprintf(char *format,...);

char * gg_vsaprintf(char *format,...);

alias gg_saprintf gg_alloc_sprintf;
char * gg_get_line(char **ptr);

int  gg_connect(void *addr, int port, int async);
in_addr * gg_gethostbyname(char *hostname);
char * gg_read_line(int sock, char *buf, int length);
void  gg_chomp(char *line);
char * gg_urlencode(char *str);
int  gg_http_hash(char *format,...);
void  gg_http_free_fields(gg_http *h);
int  gg_read(gg_session *sess, char *buf, int length);
int  gg_write(gg_session *sess, char *buf, int length);
void * gg_recv_packet(gg_session *sess);
int  gg_send_packet(gg_session *sess, int type,...);
uint  gg_login_hash(ubyte *password, uint seed);
void  gg_login_hash_sha1(char *password, uint32_t seed, uint8_t *result);
uint32_t  gg_fix32(uint32_t x);
uint16_t  gg_fix16(uint16_t x);
alias gg_fix16 fix16;
alias gg_fix32 fix32;
char * gg_proxy_auth();
char * gg_base64_encode(char *buf);
char * gg_base64_decode(char *buf);
int  gg_image_queue_remove(gg_session *s, gg_image_queue *q, int freeq);

struct gg_image_queue
{
    uin_t sender;
    uint32_t size;
    uint32_t crc32;
    char *filename;
    char *image;
    uint32_t done;
    gg_image_queue *next;
}

int  gg_dcc7_handle_id(gg_session *sess, gg_event *e, void *payload, int len);
int  gg_dcc7_handle_new(gg_session *sess, gg_event *e, void *payload, int len);
int  gg_dcc7_handle_info(gg_session *sess, gg_event *e, void *payload, int len);
int  gg_dcc7_handle_accept(gg_session *sess, gg_event *e, void *payload, int len);
int  gg_dcc7_handle_reject(gg_session *sess, gg_event *e, void *payload, int len);

const GG_APPMSG_PORT = 80;
const GG_PUBDIR_PORT = 80;
const GG_REGISTER_PORT = 80;
const GG_REMIND_PORT = 80;

const GG_RELAY_PORT = 80;
const GG_DEFAULT_PORT = 8074;
const GG_HTTPS_PORT = 443;

const GG_DEFAULT_PROTOCOL_VERSION = 0x2e;
const GG_DEFAULT_TIMEOUT = 30;
const GG_HAS_AUDIO_MASK = 0x40000000;
const GG_HAS_AUDIO7_MASK = 0x20000000;
const GG_ERA_OMNIX_MASK = 0x04000000;

const GG_FEATURE_MSG77 = 0x0001;
const GG_FEATURE_STATUS77 = 0x0002;
const GG_FEATURE_UNKNOWN_4 = 0x0004;
const GG_FEATURE_UNKNOWN_8 = 0x0008;
const GG_FEATURE_DND_FFC = 0x0010;
const GG_FEATURE_IMAGE_DESCR = 0x0020;
const GG_FEATURE_UNKNOWN_40 = 0x0040;
const GG_FEATURE_UNKNOWN_80 = 0x0080;
const GG_FEATURE_UNKNOWN_100 = 0x0100;
const GG_FEATURE_USER_DATA = 0x0200;
const GG_FEATURE_MSG_ACK = 0x0400;
const GG_FEATURE_UNKNOWN_800 = 0x0800;
const GG_FEATURE_UNKNOWN_1000 = 0x1000;
const GG_FEATURE_TYPING_NOTIFICATION = 0x2000;

const GG_FEATURE_MULTILOGON = 0x4000;
const GG_FEATURE_MSG80 = 0;
const GG_FEATURE_STATUS80 = 0;

const GG_FEATURE_STATUS80BETA = 0;

const GG_DEFAULT_DCC_PORT = 1550;
struct gg_header
{
    uint32_t type;
    uint32_t length;
}

const GG_WELCOME = 0x0001;

const GG_NEED_EMAIL = 0x0014;

struct gg_welcome
{
    uint32_t key;
}

const GG_LOGIN = 0x000c;

struct gg_login_
{
    uint32_t uin;
    uint32_t hash;
    uint32_t status;
    uint32_t version_;
    uint32_t local_ip;
    uint16_t local_port;
}

const GG_LOGIN_EXT = 0x0013;

struct gg_login_ext
{
    uint32_t uin;
    uint32_t hash;
    uint32_t status;
    uint32_t version_;
    uint32_t local_ip;
    uint16_t local_port;
    uint32_t external_ip;
    uint16_t external_port;
}

const GG_LOGIN60 = 0x0015;

struct gg_login60
{
    uint32_t uin;
    uint32_t hash;
    uint32_t status;
    uint32_t version_;
    uint8_t dunno1;
    uint32_t local_ip;
    uint16_t local_port;
    uint32_t external_ip;
    uint16_t external_port;
    uint8_t image_size;
    uint8_t dunno2;
}

const GG_LOGIN70 = 0x0019;

struct gg_login70
{
    uint32_t uin;
    uint8_t hash_type;
    uint8_t [64]hash;
    uint32_t status;
    uint32_t version_;
    uint8_t dunno1;
    uint32_t local_ip;
    uint16_t local_port;
    uint32_t external_ip;
    uint16_t external_port;
    uint8_t image_size;
    uint8_t dunno2;
}

const GG_LOGIN_OK = 0x0003;

const GG_LOGIN_FAILED = 0x0009;

const GG_PUBDIR50_REQUEST = 0x0014;

struct gg_pubdir50_request
{
    uint8_t type;
    uint32_t seq;
}

const GG_PUBDIR50_REPLY = 0x000e;

struct gg_pubdir50_reply
{
    uint8_t type;
    uint32_t seq;
}

const GG_NEW_STATUS = 0x0002;
const GG_STATUS_NOT_AVAIL = 0x0001;
const GG_STATUS_NOT_AVAIL_DESCR = 0x0015;
const GG_STATUS_FFC = 0x0017;
const GG_STATUS_FFC_DESCR = 0x0018;
const GG_STATUS_AVAIL = 0x0002;
const GG_STATUS_AVAIL_DESCR = 0x0004;
const GG_STATUS_BUSY = 0x0003;
const GG_STATUS_BUSY_DESCR = 0x0005;
const GG_STATUS_DND = 0x0021;
const GG_STATUS_DND_DESCR = 0x0022;
const GG_STATUS_INVISIBLE = 0x0014;
const GG_STATUS_INVISIBLE_DESCR = 0x0016;

const GG_STATUS_BLOCKED = 0x0006;
const GG_STATUS_IMAGE_MASK = 0x0100;
const GG_STATUS_DESCR_MASK = 0x4000;

const GG_STATUS_FRIENDS_MASK = 0x8000;
const GG_STATUS_FLAG_UNKNOWN = 0x00000001;
const GG_STATUS_FLAG_VIDEO = 0x00000002;
const GG_STATUS_FLAG_MOBILE = 0x00100000;

const GG_STATUS_FLAG_SPAM = 0x00800000;

const GG_STATUS_VOICE_MASK = 0x20000;
const GG_STATUS_DESCR_MAXSIZE = 255;

const GG_STATUS_DESCR_MAXSIZE_PRE_8_0 = 70;

const GG_STATUS_MASK = 0xff;

struct gg_new_status
{
    uint32_t status;
}

const GG_NOTIFY_FIRST = 0x000f;

const GG_NOTIFY_LAST = 0x0010;

const GG_NOTIFY = 0x0010;

struct gg_notify_
{
    uint32_t uin;
    uint8_t dunno1;
}

const GG_USER_OFFLINE = 0x01;
const GG_USER_NORMAL = 0x03;
const GG_USER_BLOCKED = 0x04;
const GG_LIST_EMPTY = 0x0012;

const GG_NOTIFY_REPLY = 0x000c;

struct gg_notify_reply
{
    uint32_t uin;
    uint32_t status;
    uint32_t remote_ip;
    uint16_t remote_port;
    uint32_t version_;
    uint16_t dunno2;
}
const GG_NOTIFY_REPLY60 = 0x0011;

struct gg_notify_reply60
{
    uint32_t uin;
    uint8_t status;
    uint32_t remote_ip;
    uint16_t remote_port;
    uint8_t version_;
    uint8_t image_size;
    uint8_t dunno1;
}

const GG_STATUS60 = 0x000f;

struct gg_status60
{
    uint32_t uin;
    uint8_t status;
    uint32_t remote_ip;
    uint16_t remote_port;
    uint8_t version_;
    uint8_t image_size;
    uint8_t dunno1;
}

const GG_NOTIFY_REPLY77 = 0x0018;

struct gg_notify_reply77
{
    uint32_t uin;
    uint8_t status;
    uint32_t remote_ip;
    uint16_t remote_port;
    uint8_t version_;
    uint8_t image_size;
    uint8_t dunno1;
    uint32_t dunno2;
}

const GG_STATUS77 = 0x0017;

struct gg_status77
{
    uint32_t uin;
    uint8_t status;
    uint32_t remote_ip;
    uint16_t remote_port;
    uint8_t version_;
    uint8_t image_size;
    uint8_t dunno1;
    uint32_t dunno2;
}

const GG_ADD_NOTIFY = 0x000d;

const GG_REMOVE_NOTIFY = 0x000e;

struct gg_add_remove
{
    uint32_t uin;
    uint8_t dunno1;
}

const GG_STATUS = 0x0002;
struct gg_status
{
    uint32_t uin;
    uint32_t status;
}

const GG_SEND_MSG = 0x000b;
const GG_CLASS_QUEUED = 0x0001;
alias GG_CLASS_QUEUED GG_CLASS_OFFLINE;
const GG_CLASS_MSG = 0x0004;
const GG_CLASS_CHAT = 0x0008;
const GG_CLASS_CTCP = 0x0010;
const GG_CLASS_ACK = 0x0020;

alias GG_CLASS_ACK GG_CLASS_EXT;

const GG_MSG_MAXSIZE = 1989;

struct gg_send_msg
{
    uint32_t recipient;
    uint32_t seq;
    uint32_t msgclass;
}

struct gg_msg_richtext
{
    uint8_t flag;
    uint16_t length;
}

struct gg_msg_richtext_format
{
    uint16_t position;
    uint8_t font;
}

const GG_FONT_BOLD = 0x01;
const GG_FONT_ITALIC = 0x02;
const GG_FONT_UNDERLINE = 0x04;
const GG_FONT_COLOR = 0x08;
const GG_FONT_IMAGE = 0x80;

struct gg_msg_richtext_color
{
    uint8_t red;
    uint8_t green;
    uint8_t blue;
}

struct gg_msg_richtext_image
{
    uint16_t unknown1;
    uint32_t size;
    uint32_t crc32;
}

struct gg_msg_recipients
{
    uint8_t flag;
    uint32_t count;
}

struct gg_msg_image_request
{
    uint8_t flag;
    uint32_t size;
    uint32_t crc32;
}

struct gg_msg_image_reply
{
    uint8_t flag;
    uint32_t size;
    uint32_t crc32;
}

const GG_SEND_MSG_ACK = 0x0005;
const GG_ACK_BLOCKED = 0x0001;
const GG_ACK_DELIVERED = 0x0002;
const GG_ACK_QUEUED = 0x0003;
const GG_ACK_MBOXFULL = 0x0004;

const GG_ACK_NOT_DELIVERED = 0x0006;

struct gg_send_msg_ack
{
    uint32_t status;
    uint32_t recipient;
    uint32_t seq;
}

const GG_RECV_MSG = 0x000a;

struct gg_recv_msg
{
    uint32_t sender;
    uint32_t seq;
    uint32_t time;
    uint32_t msgclass;
}

const GG_PING = 0x0008;
const GG_PONG = 0x0007;
const GG_DISCONNECTING = 0x000b;
const GG_USERLIST_REQUEST = 0x0016;
const GG_XML_EVENT = 0x0027;
const GG_USERLIST_PUT = 0x00;
const GG_USERLIST_PUT_MORE = 0x01;
const GG_USERLIST_GET = 0x02;

struct gg_userlist_request_
{
    uint8_t type;
}

const GG_USERLIST_REPLY = 0x0010;
const GG_USERLIST_PUT_REPLY = 0x00;
const GG_USERLIST_PUT_MORE_REPLY = 0x02;
const GG_USERLIST_GET_REPLY = 0x06;
const GG_USERLIST_GET_MORE_REPLY = 0x04;

struct gg_userlist_reply
{
    uint8_t type;
}

const GG_USERLIST100_PUT = 0x00;
const GG_USERLIST100_GET = 0x02;
const GG_USERLIST100_FORMAT_TYPE_NONE = 0x00;
const GG_USERLIST100_FORMAT_TYPE_GG70 = 0x01;
const GG_USERLIST100_FORMAT_TYPE_GG100 = 0x02;
const GG_USERLIST100_REPLY_LIST = 0x00;
const GG_USERLIST100_REPLY_ACK = 0x10;

const GG_USERLIST100_REPLY_REJECT = 0x12;

struct gg_dcc_tiny_packet
{
    uint8_t type;
}

struct gg_dcc_small_packet
{
    uint32_t type;
}

struct gg_dcc_big_packet
{
    uint32_t type;
    uint32_t dunno1;
    uint32_t dunno2;
}

const GG_DCC_WANT_FILE = 0x0003;
const GG_DCC_HAVE_FILE = 0x0001;
const GG_DCC_HAVE_FILEINFO = 0x0003;
const GG_DCC_GIMME_FILE = 0x0006;
const GG_DCC_CATCH_FILE = 0x0002;
const GG_DCC_FILEATTR_READONLY = 0x0020;
const GG_DCC_TIMEOUT_SEND = 1800;
const GG_DCC_TIMEOUT_GET = 1800;
const GG_DCC_TIMEOUT_FILE_ACK = 300;

const GG_DCC_TIMEOUT_VOICE_ACK = 300;

const GG_DCC7_INFO = 0x1f;

struct gg_dcc7_info
{
    uint32_t uin;
    uint32_t type;
    gg_dcc7_id_t id;
    char [32]info;
    char [32]hash;
}

const GG_DCC7_NEW = 0x20;

struct gg_dcc7_new
{
    gg_dcc7_id_t id;
    uint32_t uin_from;
    uint32_t uin_to;
    uint32_t type;
    ubyte [255]filename;
    uint32_t size;
    uint32_t size_hi;
    ubyte [20]hash;
}


const GG_DCC7_ACCEPT = 0x21;

struct gg_dcc7_accept_
{
    uint32_t uin;
    gg_dcc7_id_t id;
    uint32_t offset;
    uint32_t dunno1;
}

const GG_DCC7_TYPE_P2P = 0x00000001;

const GG_DCC7_TYPE_SERVER = 0x00000002;

const GG_DCC7_REJECT = 0x22;

struct gg_dcc7_reject_
{
    uint32_t uin;
    gg_dcc7_id_t id;
    uint32_t reason;
}

const GG_DCC7_REJECT_BUSY = 0x00000001;
const GG_DCC7_REJECT_USER = 0x00000002;
const GG_DCC7_REJECT_VERSION = 0x00000006;

const GG_DCC7_ID_REQUEST = 0x23;

struct gg_dcc7_id_request
{
    uint32_t type;
}

const GG_DCC7_TYPE_VOICE = 0x00000001;
const GG_DCC7_TYPE_FILE = 0x00000004;

const GG_DCC7_ID_REPLY = 0x23;

struct gg_dcc7_id_reply
{
    uint32_t type;
    gg_dcc7_id_t id;
}

const GG_DCC7_DUNNO1 = 0x24;

struct gg_dcc7_dunno1
{
}

const GG_DCC7_TIMEOUT_CONNECT = 10;
const GG_DCC7_TIMEOUT_SEND = 1800;
const GG_DCC7_TIMEOUT_GET = 1800;
const GG_DCC7_TIMEOUT_FILE_ACK = 300;

const GG_DCC7_TIMEOUT_VOICE_ACK = 300;
 +/