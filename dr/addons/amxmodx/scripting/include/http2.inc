#if defined _http2_included
	#endinput
#endif
#define _http2_included

#include <sockets>
#include <engine>
#include <regex>

/*
* HTTP2
* v2.40
* By [ --{-@ ] Black Rose
*
* Based on HTTP v0.4 by Bugsy
*/

#if !defined HTTP2_MAX_DOWNLOAD_SLOTS
	#define HTTP2_MAX_DOWNLOAD_SLOTS	4
#endif

#if !defined HTTP2_BUFFER_SIZE
	#define HTTP2_BUFFER_SIZE			32768
#endif

#if !defined HTTP2_THINK_INTERVAL
	#define HTTP2_THINK_INTERVAL		0.01
#endif

#if !defined HTTP2_QUE_INTERVAL
	#define HTTP2_QUE_INTERVAL			1.0
#endif

#if !defined HTTP2_Version
	#define HTTP2_Version				2.40
#endif

#if !defined HTTP2_VersionNum
	#define HTTP2_VersionNum			240
#endif

#if !defined HTTP2_VersionString
	#define HTTP2_VersionString			"2.40"
#endif

#define _HTTP2_STATUS_ACTIVE			(1<<0)
#define _HTTP2_STATUS_FIRSTRUN			(1<<1)
#define _HTTP2_STATUS_CHUNKED_TRANSFER	(1<<2)
#define _HTTP2_STATUS_LARGE_SIZE		(1<<3)

#define _HTTP2_ishex(%0) ( ( '0' <= %0 <= '9' || 'a' <= %0 <= 'f' || 'A' <= %0 <= 'F' ) ? true : false)
#define _HTTP2_isurlsafe(%0) ( ( '0' <= %0 <= '9' || 'a' <= %0 <= 'z' || 'A' <= %0 <= 'Z' || %0 == '-' || %0 == '_' || %0 == '.' || %0 == '~' || %0 == '%' || %0 == ' ' ) ? true : false)
#define _HTTP2_ctod(%0) ( '0' <= %0 <= '9' ? %0 - '0' : 'A' <= %0 <= 'Z' ? %0 -'A' + 10 : 'a' <= %0 <= 'z' ? %0 -'a' + 10 : 0 )
#define _HTTP2_dtoc(%0) ( 0 <= %0 <= 9 ? %0 + '0' : 10 <= %0 <= 35 ? %0 + 'A' - 10 : 0 )

#define REQUEST_GET		0
#define REQUEST_POST	1
#define REQUEST_HEAD	2

new const _HTTP2_RequestTypes[][] = {
	"GET",
	"POST",
	"HEAD"
};

new const _HTTP2_Base64Table[] =
/*
*0000000000111111111122222222223333333333444444444455555555556666
*0123456789012345678901234567890123456789012345678901234567890123*/
"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

enum _HTTP2_ItemDataEnum {
	_FileName[128],
	_BytesReceived,
	_BytesReceivedLarge[16],
	_Filesize,
	_FilesizeLarge[16],
	_hFile,
	_hSocket,
	_hProgressHandler,
	_hCompleteHandler,
	_Port,
	_Status,
	_RequestType,
	_EndOfChunk,
	_PostVars[1024]
}

enum _HTTP2_URLDataEnum {
	_Scheme[10],
	_Host[128],
	_URLPort,
	_User[128],
	_Pass[128],
	_Path[128],
	_Query[256],
	_Fragment[128]
};

enum _HTTP2_QueDataEnum {
	_QueURL[512],
	_QueFilename[128],
	_QueCompleteHandler[33],
	_QueProgressHandler[33],
	_QuePort,
	_QueRequestType,
	_QueUsername[128],
	_QuePassword[128],
	_QuePostVars[1024]
};

new _gHTTP2_Information[HTTP2_MAX_DOWNLOAD_SLOTS][_HTTP2_ItemDataEnum];
new _gHTTP2_URLParsed[HTTP2_MAX_DOWNLOAD_SLOTS][_HTTP2_URLDataEnum];
new _gHTTP2_QueData[_HTTP2_QueDataEnum];
new _gHTTP2_DataBuffer[HTTP2_BUFFER_SIZE];
new _gHTTP2_BufferLen;

new _gHTTP2_ReturnDummy;
new _gHTTP2_DownloadEntity;
new _gHTTP2_BufferSizeLarge[16];
new _gHTTP2_OneLarge[1];
new bool:_gHTTP2_Initialized;

new _gHTTP2_PostVars[1024];

new Array:_gHTTP2_Que_hArray;

new _gHTTP2_QueEntity;
new bool:_gHTTP2_QueInitialized;

/*
* HTTP2_isFilesizeLarge(Index)
*
* If the filesize in bytes is beyond the limitations of integers the function will return true.
*/
stock bool:HTTP2_isFilesizeLarge(Index)
	return _gHTTP2_Information[Index][_Status] & _HTTP2_STATUS_LARGE_SIZE ? true : false;

/*
* HTTP2_getBytesReceived(Index)
*
* Returns total ammount of bytes received for Index.
*/
stock HTTP2_getBytesReceived(Index)
	return _gHTTP2_Information[Index][_BytesReceived];

/*
* HTTP2_getBytesReceivedLarge(Index, string[], len)
*
* Formats total ammount of bytes received for Index in string form.
*/
stock HTTP2_getBytesReceivedLarge(Index, string[], len)
	_HTTP2_large_tostring(_gHTTP2_Information[Index][_BytesReceivedLarge], sizeof _gHTTP2_Information[][_BytesReceivedLarge], string, len);

/*
* HTTP2_getNewBytesReceived()
*
* Returns the ammount of bytes that was received in this chunk.
*/
stock HTTP2_getNewBytesReceived()
	return _gHTTP2_BufferLen;

/*
* HTTP2_getFilesize(Index)
*
* Returns the filesize of Index.
* If unknown it will return -1.
*/
stock HTTP2_getFilesize(Index)
	return _gHTTP2_Information[Index][_Filesize];

/*
* HTTP2_getFilesizeLarge(Index, string[], len)
*
* Formats the large filesize of Index in string form.
*/
stock HTTP2_getFilesizeLarge(Index, string[], len)
	_HTTP2_large_tostring(_gHTTP2_Information[Index][_FilesizeLarge], sizeof _gHTTP2_Information[][_FilesizeLarge], string, len);

/*
* HTTP2_getFilename(Index)
*
* Returns the filename of Index.
*/
stock HTTP2_getFilename(Index, name[], len)
	copy(name, len, _gHTTP2_Information[Index][_FileName]);

/*
* HTTP2_getData(Data[], len, &datalen)
*
* Fills variable Data[] with the last chunk downloaded.
* len decides the maximum size of Data[].
* datalen will return the ammount of bytes that was received in this chunk.
*
* For performance reasons HTTP2_getData2() should be used whenever possible.
*/
stock HTTP2_getData(Dest[], len, &datalen) {
	
	static _HTTP2_getData_i, _HTTP2_getData_max;
	
	_HTTP2_getData_max = min(len, _gHTTP2_BufferLen);
	
	Dest[len] = 0;
	datalen = _gHTTP2_BufferLen;
	
	for ( _HTTP2_getData_i = 0 ; _HTTP2_getData_i <= _HTTP2_getData_max ; _HTTP2_getData_i++ )
		Dest[_HTTP2_getData_i] = _gHTTP2_DataBuffer[_HTTP2_getData_i];
}

/*
* HTTP2_getDataUnsafe()
* HTTP2_getData2()
*
* This is a direct connection to the data buffer.
* This will be faster because you don't need to spend time copying data between 2 buffers just to read it.
*
* Since the forward is called after the data has been written you don't need to worry about corrupting it.
* So it's not really unsafe.
*/
#define HTTP2_getDataUnsafe() _gHTTP2_DataBuffer
#define HTTP2_getData2() _gHTTP2_DataBuffer

/*
* HTTP2_UpdatePlugin(const URL[])
*
* Updates current plugin with binary from chosen URL.
*/
stock HTTP2_UpdatePlugin(const URL[]) {
	new tempfile[14];
	do
		formatex(tempfile, charsmax(tempfile), "temp%d.amxx", random_num(1000,9999));
	while ( file_exists(tempfile) )
	HTTP2_Download(URL, tempfile, "_HTTP2_PluginUpdater_Complete");
}

/*
* HTTP2_Abort(Index, bool:DeleteFile = true)
*
* Aborts the transfer of selected download index.
* If DeleteFile is set to true the partially downloaded file will be deleted.
*/
stock HTTP2_Abort(Index, bool:DeleteFile = true) {
	_HTTP2_TransferDone(Index, 0, false);
	
	if ( DeleteFile && _gHTTP2_Information[Index][_FileName] && file_exists(_gHTTP2_Information[Index][_FileName]) )
		delete_file(_gHTTP2_Information[Index][_FileName]);
}

/*
* HTTP2_AddPostVar(const variable[], const value[])
*
* Adds a POST variable to the header.
* This function is used before HTTP2_Download() or HTTP_AddToQue(), similar to set/show hudmessage.
* It can be used multiple times before each download.
*/
stock HTTP2_AddPostVar(const variable[], const value[]) {
	
	static _HTTP2_var[1024], _HTTP2_val[1024];
	new len = strlen(_gHTTP2_PostVars);
	
	copy(_HTTP2_var, charsmax(_HTTP2_var), variable);
	copy(_HTTP2_val, charsmax(_HTTP2_val), value);
	
	_HTTP2_URLEncode(_HTTP2_var, charsmax(_HTTP2_var));
	_HTTP2_URLEncode(_HTTP2_val, charsmax(_HTTP2_val));
	
	formatex(_gHTTP2_PostVars[len], charsmax(_gHTTP2_PostVars) - len, "%s%s=%s", len ? "&" : "", _HTTP2_var, _HTTP2_val);
}

/*
* Number of parameters for the callbacks are 1 (Index) for the progress event and 2 (Index, Error) for the complete event.
* Error codes:
*     0   Download done. No problems encountered.
* Positive returns is unhandled HTTP return codes. For example 404.
* Negative is internal errors.
*    -1   No response code was found in the HTTP response header or it was outside the accepted range (200-307).
*    -2   Server is sending bad data or sizes for a chunked transfer or HTTP2 has problems reading them.
*    -3   Nothing received in last packet. Most likely due to an error.
*    -4   HTTP2 was redirected but could not follow due to a socket error.
*/

/*
* HTTP2_Download(const URL[], const Filename[] = "", const CompleteHandler[] = "", const ProgressHandler[] = "", Port = (80<<443), RequestType = REQUEST_GET, const Username[] = "", const Password[] = "", ...)
*
* Begins download of a URL. Read parameters for information.
*
*
* Parameters:
*
*   const URL[]
*      URL that you want to download.
*
*   (Optional) const Filename[]
*      Where should the information be stored? If no filename is entered it will download as a "stream".
*      This means the data will be thrown away after it passes the buffer.
*      You can read the data on progress forward and make use of it there.
*
*   (Optional) const CompleteHandler[] = ""
*      The function you want called when the download is complete.
*
*   (Optional) const ProgressHandler[] = ""
*      The function you want called when the download is in progress.
*      This will be called every downloaded chunk
*
*   (Optional) Port = (80<<443)
*      The port that should be used.
*      If this is left at default it will use 80 for http.
*
*   (Optional) RequestType = REQUEST_GET
*      What type of request should be used.
*      If this is left at default it will use GET.
*      Possible values so far are REQUEST_GET and REQUEST_POST.
*
*   (Optional) const Username[] = ""
*   (Optional) const Password[] = ""
*      These are used to login to sites that require you to.
*      It's only used for Basic authentication, not POST for example.
*
* Returns an index of the download that may be used to abort the download.
*/
stock HTTP2_Download(const URL[], const Filename[] = "", const CompleteHandler[] = "", const ProgressHandler[] = "", Port = (80<<443), RequestType = REQUEST_GET, const Username[] = "", const Password[] = "", ... /* For possible future use */) {
	
	if ( ! Filename[0] && ! ProgressHandler[0] ) {
		log_amx("[HTTP2] Filename or progress handler is missing.");
		return -1;
	}
	
	new i;
	while ( i < HTTP2_MAX_DOWNLOAD_SLOTS && ( _gHTTP2_Information[i][_Status] & _HTTP2_STATUS_ACTIVE ) ) { i++; }
	
	if ( i == HTTP2_MAX_DOWNLOAD_SLOTS ) {
		log_amx("[HTTP2] Out of free download slots.");
		_gHTTP2_PostVars[0] = 0;
		return -1;
	}
	
	_HTTP2_ParseURL(URL,
	_gHTTP2_URLParsed[i][_Scheme], charsmax(_gHTTP2_URLParsed[][_Scheme]),
	_gHTTP2_URLParsed[i][_User], charsmax(_gHTTP2_URLParsed[][_User]),
	_gHTTP2_URLParsed[i][_Pass], charsmax(_gHTTP2_URLParsed[][_Pass]),
	_gHTTP2_URLParsed[i][_Host], charsmax(_gHTTP2_URLParsed[][_Host]),
	_gHTTP2_URLParsed[i][_URLPort],
	_gHTTP2_URLParsed[i][_Path], charsmax(_gHTTP2_URLParsed[][_Path]),
	_gHTTP2_URLParsed[i][_Query], charsmax(_gHTTP2_URLParsed[][_Query]),
	_gHTTP2_URLParsed[i][_Fragment], charsmax(_gHTTP2_URLParsed[][_Fragment]));
	
	_gHTTP2_Information[i][_Port] = _gHTTP2_URLParsed[i][_URLPort] ? _gHTTP2_URLParsed[i][_URLPort] : Port == (80<<443) ? equali(_gHTTP2_URLParsed[i][_Scheme], "https") ? 443 : 80 : Port;
	
	if ( ! _gHTTP2_URLParsed[i][_User] )
		copy(_gHTTP2_URLParsed[i][_User], charsmax(_gHTTP2_URLParsed[][_User]), Username);
	
	if ( ! _gHTTP2_URLParsed[i][_Pass] )
		copy(_gHTTP2_URLParsed[i][_Pass], charsmax(_gHTTP2_URLParsed[][_Pass]), Password);
	
	if ( ! Filename[0] )
	_gHTTP2_Information[i][_hFile] = 0;
	else if ( ! ( _gHTTP2_Information[i][_hFile] = fopen(Filename, "wb") ) ) {
		log_amx("[HTTP2] Error creating local file.");
		_gHTTP2_PostVars[0] = 0;
		return -1;
	}
	
	static _HTTP2_Plugin[64];
	get_plugin(-1 , _HTTP2_Plugin, charsmax(_HTTP2_Plugin), "", 0, "", 0, "", 0, "", 0);
	new ResultNum = find_plugin_byfile(_HTTP2_Plugin, 0);
	
	if ( ProgressHandler[0] )
		_gHTTP2_Information[i][_hProgressHandler] = CreateOneForward(ResultNum, ProgressHandler, FP_CELL);
	if ( CompleteHandler[0] )
		_gHTTP2_Information[i][_hCompleteHandler] = CreateOneForward(ResultNum, CompleteHandler, FP_CELL, FP_CELL);
	
	_gHTTP2_Information[i][_hSocket] = socket_open(_gHTTP2_URLParsed[i][_Host], _gHTTP2_Information[i][_Port], SOCKET_TCP, ResultNum);
	
	if ( ResultNum ) {
		switch ( ResultNum ) {
			case 1: log_amx("[HTTP2] Socket error: Error while creating socket.");
			case 2: log_amx("[HTTP2] Socket error: Couldn't resolve hostname. (%s)", _gHTTP2_URLParsed[i][_Host]);
			case 3: log_amx("[HTTP2] Socket error: Couldn't connect to host. (%s:%d)", _gHTTP2_URLParsed[i][_Host], _gHTTP2_Information[i][_Port]);
		}
		_gHTTP2_PostVars[0] = 0;
		return -1;
	}
	
	static _HTTP2_Request[2048], _HTTP2_Auth[256], _HTTP2_TempStr[256], _HTTP2_TempScheme[10];
	
	copy(_HTTP2_TempScheme, charsmax(_HTTP2_TempScheme), _gHTTP2_URLParsed[i][_Scheme]);
	strtoupper(_HTTP2_TempScheme);
	
	new RequestLen = formatex(_HTTP2_Request, charsmax(_HTTP2_Request), "%s /%s%s%s%s%s %s/1.1^r^nHost: %s", _HTTP2_RequestTypes[RequestType], _gHTTP2_URLParsed[i][_Path], _gHTTP2_URLParsed[i][_Query] ? "?" : "", _gHTTP2_URLParsed[i][_Query], _gHTTP2_URLParsed[i][_Fragment] ? "#" : "", _gHTTP2_URLParsed[i][_Fragment], _HTTP2_TempScheme, _gHTTP2_URLParsed[i][_Host]);
	
	if ( _gHTTP2_URLParsed[i][_User] || _gHTTP2_URLParsed[i][_Pass] ) {
		formatex(_HTTP2_TempStr, charsmax(_HTTP2_TempStr), "%s:%s", _gHTTP2_URLParsed[i][_User], _gHTTP2_URLParsed[i][_Pass]);
		_HTTP2_Encode64(_HTTP2_TempStr, _HTTP2_Auth, charsmax(_HTTP2_Auth));
	
		RequestLen += formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^nAuthorization: Basic %s", _HTTP2_Auth);
	}
	
	if ( RequestType == REQUEST_POST && _gHTTP2_PostVars[0] ) {
		RequestLen += formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^nContent-Length: %d", strlen(_gHTTP2_PostVars));
		RequestLen += formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^nContent-Type: application/x-www-form-urlencoded");
		RequestLen += formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^n^r^n%s", _gHTTP2_PostVars);
		copy(_gHTTP2_Information[i][_PostVars], charsmax(_gHTTP2_Information[][_PostVars]), _gHTTP2_PostVars);
		_gHTTP2_PostVars[0] = 0;
	}
	
	formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^n^r^n");
	
	socket_send(_gHTTP2_Information[i][_hSocket], _HTTP2_Request, strlen(_HTTP2_Request));
	
	if ( ! _gHTTP2_DownloadEntity ) {
		_gHTTP2_DownloadEntity = create_entity("info_target");
		
		if ( ! _gHTTP2_DownloadEntity ) {
			log_amx("[HTTP2] Failed to create entity.");
			_gHTTP2_PostVars[0] = 0;
			return -1;
		}
		
		entity_set_string(_gHTTP2_DownloadEntity, EV_SZ_classname, "http2_downloadentity");
		entity_set_float(_gHTTP2_DownloadEntity, EV_FL_nextthink, get_gametime() + HTTP2_THINK_INTERVAL);
	}
	
	if ( ! _gHTTP2_Initialized ) {
		register_think("http2_downloadentity", "_HTTP2_DownloadThread");
		_HTTP2_large_fromint(_gHTTP2_BufferSizeLarge, sizeof _gHTTP2_BufferSizeLarge, HTTP2_BUFFER_SIZE);
		_gHTTP2_Initialized = true;
	}
	
	copy(_gHTTP2_Information[i][_FileName], charsmax(_gHTTP2_Information[][_FileName]), Filename);
	_gHTTP2_Information[i][_Status] = _HTTP2_STATUS_ACTIVE;
	_gHTTP2_Information[i][_Status] |= _HTTP2_STATUS_FIRSTRUN;
	_gHTTP2_Information[i][_RequestType] = RequestType;
	
	return i;
}

/*
* HTTP2_AddToQue(const URL[], const Filename[] = "", const CompleteHandler[] = "", const ProgressHandler[] = "", Port = (80<<443), RequestType = REQUEST_GET, const Username[] = "", const Password[] = "", ...)
*
* Ques up an item to be downloaded. Formatted exactly like HTTP2_Download().
* Use this when you're looping through a lot of downloads to avoid filling up the download slots.
* This function will not generate a direct error. The errors will occur at HTTP2_Download().
*
* Returns position in que.
*/
stock HTTP2_AddToQue(const URL[], const Filename[] = "", const CompleteHandler[] = "", const ProgressHandler[] = "", Port = (80<<443), RequestType = REQUEST_GET, const Username[] = "", const Password[] = "", ... /* For possible future use */) {
	
	if ( ! _gHTTP2_QueInitialized ) {
		_gHTTP2_Que_hArray = ArrayCreate(sizeof _gHTTP2_QueData, 10);
		register_think("http2_queentity", "_HTTP2_QueThread");
		_gHTTP2_QueInitialized = true;
	}
	
	copy(_gHTTP2_QueData[_QueURL], charsmax(_gHTTP2_QueData[_QueURL]), URL);
	copy(_gHTTP2_QueData[_QueFilename], charsmax(_gHTTP2_QueData[_QueFilename]), Filename);
	copy(_gHTTP2_QueData[_QueCompleteHandler], charsmax(_gHTTP2_QueData[_QueCompleteHandler]), CompleteHandler);
	copy(_gHTTP2_QueData[_QueProgressHandler], charsmax(_gHTTP2_QueData[_QueProgressHandler]), ProgressHandler);
	copy(_gHTTP2_QueData[_QueUsername], charsmax(_gHTTP2_QueData[_QueUsername]), Username);
	copy(_gHTTP2_QueData[_QuePassword], charsmax(_gHTTP2_QueData[_QuePassword]), Password);
	
	_gHTTP2_QueData[_QuePort] = Port;
	_gHTTP2_QueData[_QueRequestType] = RequestType;
	
	if ( RequestType == REQUEST_POST && _gHTTP2_PostVars[0] ) {
		copy(_gHTTP2_QueData[_QuePostVars], charsmax(_gHTTP2_QueData[_QuePostVars]), _gHTTP2_PostVars);
		_gHTTP2_PostVars[0] = 0;
	}
	
	ArrayPushArray(_gHTTP2_Que_hArray, _gHTTP2_QueData);
	
	if ( ! _gHTTP2_QueEntity ) {
		_gHTTP2_QueEntity = create_entity("info_target");
		
		if ( ! _gHTTP2_QueEntity ) {
			log_amx("[HTTP2] Failed to create entity.");
			return -1;
		}
		
		entity_set_string(_gHTTP2_QueEntity, EV_SZ_classname, "http2_queentity");
		entity_set_float(_gHTTP2_QueEntity, EV_FL_nextthink, get_gametime() + HTTP2_QUE_INTERVAL);
	}
	
	return ArraySize(_gHTTP2_Que_hArray);
}

public _HTTP2_DownloadThread(ent) {
	
	static _HTTP2_Index;
	
	for ( _HTTP2_Index = 0 ; _HTTP2_Index < HTTP2_MAX_DOWNLOAD_SLOTS ; _HTTP2_Index++ ) {
		
		if ( ! ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_ACTIVE ) )
			continue;
		
		if ( ! socket_change(_gHTTP2_Information[_HTTP2_Index][_hSocket], 1000) )
			continue;
		
		if ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_CHUNKED_TRANSFER &&
			_gHTTP2_Information[_HTTP2_Index][_BytesReceived] == _gHTTP2_Information[_HTTP2_Index][_EndOfChunk] ) {
			
			new tempdata[1], strHex[6], i, bool:error;
			
			while ( ! error ) {
				socket_recv(_gHTTP2_Information[_HTTP2_Index][_hSocket], tempdata, 2);
				
				switch ( tempdata[0] ) {
					case '^n' : {
						if ( i )
							break;
					}
					case '^r' : {}
					default : {
						if ( _HTTP2_ishex(tempdata[0]) )
							strHex[i++] = tempdata[0];
						else
							error = true;
					}
				}
			}
			
			if ( error ) {
				_HTTP2_TransferDone(_HTTP2_Index, -2, true);
				continue;
			}
			
			_HTTP2_GetChunkSize(strHex, _gHTTP2_Information[_HTTP2_Index][_EndOfChunk]);
			
			if ( ! _gHTTP2_Information[_HTTP2_Index][_EndOfChunk] ) {
				_gHTTP2_Information[_HTTP2_Index][_Filesize] = _gHTTP2_Information[_HTTP2_Index][_BytesReceived];
				_HTTP2_TransferDone(_HTTP2_Index, 0, true);
				continue;
			}
			
			_gHTTP2_Information[_HTTP2_Index][_EndOfChunk] += _gHTTP2_Information[_HTTP2_Index][_BytesReceived];
		}
		
		static HTTP2_tempLarge[16];
		new tempsize;
		
		if ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_FIRSTRUN )
			tempsize = 2048;
		else {
			if ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_CHUNKED_TRANSFER )
				tempsize = min(_gHTTP2_Information[_HTTP2_Index][_EndOfChunk] - _gHTTP2_Information[_HTTP2_Index][_BytesReceived] + 1, HTTP2_BUFFER_SIZE);
			else {
				if ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_LARGE_SIZE ) {
					
					_HTTP2_large_add(HTTP2_tempLarge, sizeof HTTP2_tempLarge, _gHTTP2_Information[_HTTP2_Index][_FilesizeLarge], sizeof _gHTTP2_Information[][_FilesizeLarge]);
					_HTTP2_large_sub(HTTP2_tempLarge, sizeof HTTP2_tempLarge, _gHTTP2_Information[_HTTP2_Index][_BytesReceivedLarge], sizeof _gHTTP2_Information[][_BytesReceivedLarge]);
					_HTTP2_large_add(HTTP2_tempLarge, sizeof HTTP2_tempLarge, _gHTTP2_OneLarge, sizeof _gHTTP2_OneLarge);
					
					if ( _HTTP2_large_comp(HTTP2_tempLarge, sizeof HTTP2_tempLarge, _gHTTP2_BufferSizeLarge, sizeof _gHTTP2_BufferSizeLarge) == 1 )
						tempsize = HTTP2_BUFFER_SIZE;
					else
						tempsize = _HTTP2_large_toint(HTTP2_tempLarge, sizeof HTTP2_tempLarge);
				}
				else
					tempsize = min(_gHTTP2_Information[_HTTP2_Index][_Filesize] - _gHTTP2_Information[_HTTP2_Index][_BytesReceived] + 1, HTTP2_BUFFER_SIZE);
			}
		}
		
		if ( ! (  _gHTTP2_BufferLen = socket_recv(_gHTTP2_Information[_HTTP2_Index][_hSocket], _gHTTP2_DataBuffer, tempsize) ) ) {
			_HTTP2_TransferDone(_HTTP2_Index, -3, true);
			continue;
		}
		
		if ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_FIRSTRUN ) {
			_gHTTP2_Information[_HTTP2_Index][_Status] &= ~_HTTP2_STATUS_FIRSTRUN;
			
			static _HTTP2_ReturnCodeExtended[32], _HTTP2_Location[512];
			new ReturnCode;
			
			_gHTTP2_BufferLen -= _HTTP2_ParseHeader(_HTTP2_Index, ReturnCode, _HTTP2_ReturnCodeExtended, charsmax(_HTTP2_ReturnCodeExtended), _HTTP2_Location, charsmax(_HTTP2_Location));
			
			if ( 300 <= ReturnCode <= 307 ) {
				if ( _HTTP2_FollowLocation(_HTTP2_Index, _HTTP2_Location) )
					continue;
				else {
					_HTTP2_TransferDone(_HTTP2_Index, -4, true);
					continue;
				}
			}
			else if ( ! ( 200 <= ReturnCode <= 299 ) ) {
				if ( ! ReturnCode )
					ReturnCode = -1;
				
				_HTTP2_TransferDone(_HTTP2_Index, ReturnCode, true);
				continue;
			}
			if ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_CHUNKED_TRANSFER ) {
				new Shift = _HTTP2_GetChunkSize(_gHTTP2_DataBuffer, _gHTTP2_Information[_HTTP2_Index][_EndOfChunk]);
				_gHTTP2_BufferLen = _HTTP2_ShiftData(_gHTTP2_DataBuffer, Shift, _gHTTP2_BufferLen);
			}
		}
		
		if ( _gHTTP2_Information[_HTTP2_Index][_hFile] )
			fwrite_blocks(_gHTTP2_Information[_HTTP2_Index][_hFile], _gHTTP2_DataBuffer, _gHTTP2_BufferLen, BLOCK_BYTE);
		
		_gHTTP2_Information[_HTTP2_Index][_BytesReceived] += _gHTTP2_BufferLen;
		
		if ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_LARGE_SIZE ) {
			_HTTP2_large_fromint(HTTP2_tempLarge, sizeof HTTP2_tempLarge, _gHTTP2_BufferLen);
			_HTTP2_large_add(_gHTTP2_Information[_HTTP2_Index][_BytesReceivedLarge], sizeof _gHTTP2_Information[][_BytesReceivedLarge], HTTP2_tempLarge, sizeof HTTP2_tempLarge);
			
		}
		
		if ( _gHTTP2_Information[_HTTP2_Index][_hProgressHandler] ) {
			
			ExecuteForward(_gHTTP2_Information[_HTTP2_Index][_hProgressHandler], _gHTTP2_ReturnDummy, _HTTP2_Index);
			
			if ( _gHTTP2_ReturnDummy == PLUGIN_HANDLED ) {
				_HTTP2_TransferDone(_HTTP2_Index, 0, false);
				continue;
			}
		}
		
		if ( ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_LARGE_SIZE
			&& ! _HTTP2_large_comp(_gHTTP2_Information[_HTTP2_Index][_BytesReceivedLarge], sizeof _gHTTP2_Information[][_BytesReceivedLarge], _gHTTP2_Information[_HTTP2_Index][_FilesizeLarge], sizeof _gHTTP2_Information[][_FilesizeLarge]) )
		||
			( ! ( _gHTTP2_Information[_HTTP2_Index][_Status] & _HTTP2_STATUS_LARGE_SIZE )
			&& _gHTTP2_Information[_HTTP2_Index][_BytesReceived] == _gHTTP2_Information[_HTTP2_Index][_Filesize] )
		) {
			_HTTP2_TransferDone(_HTTP2_Index, 0, true);
			continue;
		}
	}
	
	entity_set_float(_gHTTP2_DownloadEntity, EV_FL_nextthink, get_gametime() + HTTP2_THINK_INTERVAL);
}

public _HTTP2_QueThread() {
	new count;
	
	for ( new i = 0 ; i < HTTP2_MAX_DOWNLOAD_SLOTS ; i++ ) {
		if ( ! ( _gHTTP2_Information[i][_Status] & _HTTP2_STATUS_ACTIVE ) )
			count++;
	}
	
	new Arraysize = ArraySize(_gHTTP2_Que_hArray);
	if ( count > Arraysize )
		count = Arraysize;
	
	while ( count-- ) {
		ArrayGetArray(_gHTTP2_Que_hArray, 0, _gHTTP2_QueData);
		ArrayDeleteItem(_gHTTP2_Que_hArray, 0);
		
		if ( _gHTTP2_QueData[_QueRequestType] == REQUEST_POST )
			copy(_gHTTP2_PostVars, charsmax(_gHTTP2_PostVars), _gHTTP2_QueData[_QuePostVars]);
		
		HTTP2_Download(_gHTTP2_QueData[_QueURL], _gHTTP2_QueData[_QueFilename], _gHTTP2_QueData[_QueCompleteHandler], _gHTTP2_QueData[_QueProgressHandler], _gHTTP2_QueData[_QuePort], _gHTTP2_QueData[_QueRequestType], _gHTTP2_QueData[_QueUsername], _gHTTP2_QueData[_QuePassword]);
	}
	
	if ( ! ArraySize(_gHTTP2_Que_hArray) ) {
		entity_set_int(_gHTTP2_QueEntity, EV_INT_flags, FL_KILLME);
		call_think(_gHTTP2_QueEntity);
		
		_gHTTP2_QueEntity = 0;
		return;
	}
	
	entity_set_float(_gHTTP2_QueEntity, EV_FL_nextthink, get_gametime() + HTTP2_QUE_INTERVAL);
}

_HTTP2_TransferDone(Index, Error, bool:CallHandler) {
	
	if ( _gHTTP2_Information[Index][_hFile] )
		fclose(_gHTTP2_Information[Index][_hFile]);
	
	socket_close(_gHTTP2_Information[Index][_hSocket]);
	
	if ( CallHandler && _gHTTP2_Information[Index][_hCompleteHandler] )
		ExecuteForward(_gHTTP2_Information[Index][_hCompleteHandler], _gHTTP2_ReturnDummy, Index, Error);
	
	DestroyForward(_gHTTP2_Information[Index][_hProgressHandler]);
	DestroyForward(_gHTTP2_Information[Index][_hCompleteHandler]);
	
	_gHTTP2_Information[Index][_BytesReceived] = 0;
	_gHTTP2_Information[Index][_Filesize] = 0;
	_gHTTP2_Information[Index][_EndOfChunk] = 0;
	_gHTTP2_Information[Index][_hProgressHandler] = 0;
	_gHTTP2_Information[Index][_hCompleteHandler] = 0;
	_gHTTP2_Information[Index][_hFile] = 0;
	_gHTTP2_Information[Index][_Status] = 0;
	_gHTTP2_Information[Index][_PostVars] = 0;
	
	for ( new i = 0 ; i < sizeof _gHTTP2_Information ; i++ ) {
		if ( _gHTTP2_Information[i][_Status] & _HTTP2_STATUS_ACTIVE )
			return;
	}
	
	entity_set_int(_gHTTP2_DownloadEntity, EV_INT_flags, FL_KILLME);
	call_think(_gHTTP2_DownloadEntity);
	
	_gHTTP2_DownloadEntity = 0;
}

_HTTP2_FollowLocation(Index, const Location[]) {
	
	socket_close(_gHTTP2_Information[Index][_hSocket]);
	new bool:Relative = true;
	
	static _HTTP2_Follow_TempURLParsed[_HTTP2_URLDataEnum];
	
	arrayset(_HTTP2_Follow_TempURLParsed, 0, sizeof _HTTP2_Follow_TempURLParsed);
	_HTTP2_ParseURL(Location,
	_HTTP2_Follow_TempURLParsed[_Scheme], charsmax(_HTTP2_Follow_TempURLParsed[_Scheme]),
	_HTTP2_Follow_TempURLParsed[_User], charsmax(_HTTP2_Follow_TempURLParsed[_User]),
	_HTTP2_Follow_TempURLParsed[_Pass], charsmax(_HTTP2_Follow_TempURLParsed[_Pass]),
	_HTTP2_Follow_TempURLParsed[_Host], charsmax(_HTTP2_Follow_TempURLParsed[_Host]),
	_HTTP2_Follow_TempURLParsed[_URLPort],
	_HTTP2_Follow_TempURLParsed[_Path], charsmax(_HTTP2_Follow_TempURLParsed[_Path]),
	_HTTP2_Follow_TempURLParsed[_Query], charsmax(_HTTP2_Follow_TempURLParsed[_Query]),
	_HTTP2_Follow_TempURLParsed[_Fragment], charsmax(_HTTP2_Follow_TempURLParsed[_Fragment]));
	
	if ( _HTTP2_Follow_TempURLParsed[_Scheme] )
		copy(_gHTTP2_URLParsed[Index][_Scheme], charsmax(_gHTTP2_URLParsed[][_Scheme]), _HTTP2_Follow_TempURLParsed[_Scheme]);
	if ( _HTTP2_Follow_TempURLParsed[_Host] ) {
		copy(_gHTTP2_URLParsed[Index][_Host], charsmax(_gHTTP2_URLParsed[][_Host]), _HTTP2_Follow_TempURLParsed[_Host]);
		Relative = false;
	}
	if ( _HTTP2_Follow_TempURLParsed[_URLPort] )
		_gHTTP2_Information[Index][_Port] = _HTTP2_Follow_TempURLParsed[_URLPort];
	if ( _HTTP2_Follow_TempURLParsed[_User] )
		copy(_gHTTP2_URLParsed[Index][_User], charsmax(_gHTTP2_URLParsed[][_User]), _HTTP2_Follow_TempURLParsed[_User]);
	if ( _HTTP2_Follow_TempURLParsed[_Pass] )
		copy(_gHTTP2_URLParsed[Index][_Pass], charsmax(_gHTTP2_URLParsed[][_Pass]), _HTTP2_Follow_TempURLParsed[_Pass]);
	if ( _HTTP2_Follow_TempURLParsed[_Path] ) {
		if ( Relative )
			add(_gHTTP2_URLParsed[Index][_Path], charsmax(_gHTTP2_URLParsed[][_Path]), _HTTP2_Follow_TempURLParsed[_Path]);
		else
			copy(_gHTTP2_URLParsed[Index][_Path], charsmax(_gHTTP2_URLParsed[][_Path]), _HTTP2_Follow_TempURLParsed[_Path]);
	}
	if ( _HTTP2_Follow_TempURLParsed[_Query] )
		copy(_gHTTP2_URLParsed[Index][_Query], charsmax(_gHTTP2_URLParsed[][_Query]), _HTTP2_Follow_TempURLParsed[_Query]);
	if ( _HTTP2_Follow_TempURLParsed[_Fragment] )
		copy(_gHTTP2_URLParsed[Index][_Fragment], charsmax(_gHTTP2_URLParsed[][_Fragment]), _HTTP2_Follow_TempURLParsed[_Fragment]);
	
	new ResultNum;
	_gHTTP2_Information[Index][_hSocket] = socket_open(_gHTTP2_URLParsed[Index][_Host], _gHTTP2_Information[Index][_Port], SOCKET_TCP, ResultNum);
	
	if ( ResultNum ) {
		switch ( ResultNum ) {
		case 1: log_amx("[HTTP2] Socket error: Error while creating socket.");
		case 2: log_amx("[HTTP2] Socket error: Couldn't resolve hostname.");
		case 3: log_amx("[HTTP2] Socket error: Couldn't connect to given hostname:port.");
		}
		return 0;
	}
	
	static _HTTP2_Request[2048], _HTTP2_Auth[256], _HTTP2_TempStr[256], _HTTP2_TempScheme[10];
	
	copy(_HTTP2_TempScheme, charsmax(_HTTP2_TempScheme), _gHTTP2_URLParsed[Index][_Scheme]);
	strtoupper(_HTTP2_TempScheme);
	
	new RequestLen = formatex(_HTTP2_Request, charsmax(_HTTP2_Request), "%s /%s%s%s%s%s %s/1.1^r^nHost: %s", _HTTP2_RequestTypes[_gHTTP2_Information[Index][_RequestType]], _gHTTP2_URLParsed[Index][_Path], _gHTTP2_URLParsed[Index][_Query] ? "?" : "", _gHTTP2_URLParsed[Index][_Query], _gHTTP2_URLParsed[Index][_Fragment] ? "#" : "", _gHTTP2_URLParsed[Index][_Fragment], _HTTP2_TempScheme, _gHTTP2_URLParsed[Index][_Host]);
	
	if ( _gHTTP2_URLParsed[Index][_User] || _gHTTP2_URLParsed[Index][_Pass] ) {
		formatex(_HTTP2_TempStr, charsmax(_HTTP2_TempStr), "%s:%s", _gHTTP2_URLParsed[Index][_User], _gHTTP2_URLParsed[Index][_Pass]);
		_HTTP2_Encode64(_HTTP2_TempStr, _HTTP2_Auth, charsmax(_HTTP2_Auth));
		
		RequestLen += formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^nAuthorization: Basic %s", _HTTP2_Auth);
	}
	
	if ( _gHTTP2_Information[Index][_RequestType] == REQUEST_POST && _gHTTP2_Information[Index][_PostVars] ) {
		RequestLen += formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^nContent-Length: %d", strlen(_gHTTP2_Information[Index][_PostVars]));
		RequestLen += formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^nContent-Type: application/x-www-form-urlencoded");
		RequestLen += formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^n^r^n%s", _gHTTP2_Information[Index][_PostVars]);
	}
	
	formatex(_HTTP2_Request[RequestLen], charsmax(_HTTP2_Request) - RequestLen, "^r^n^r^n");
	
	socket_send(_gHTTP2_Information[Index][_hSocket], _HTTP2_Request, strlen(_HTTP2_Request));
	
	_gHTTP2_Information[Index][_Status] = _HTTP2_STATUS_ACTIVE;
	_gHTTP2_Information[Index][_Status] |= _HTTP2_STATUS_FIRSTRUN;
	
	return 1;
}

_HTTP2_ParseHeader(Index, &ReturnCode, ReturnCodeExtended[], ReturnCodeExtendedLen, Location[], LocationLen) {
	
	static _HTTP2_TempStr[256];
	new HeaderLen, iPos, c;
	
	HeaderLen = containi(_gHTTP2_DataBuffer, "^r^n^r^n") + 1;
	
	if ( HeaderLen ) {
		HeaderLen += 3;
		
		iPos = containi(_gHTTP2_DataBuffer, "HTTP/1.1 ") + 9;
		
		if ( iPos != 8 && iPos < HeaderLen ) {
			while ( _gHTTP2_DataBuffer[iPos + c] != '^r' && c < charsmax(_HTTP2_TempStr) )
				_HTTP2_TempStr[c] = _gHTTP2_DataBuffer[iPos + c++];
			
			_HTTP2_TempStr[c] = 0;
			ReturnCode = str_to_num(_HTTP2_TempStr);
			
			iPos += c + 1;
			c = 0;
			while ( _gHTTP2_DataBuffer[iPos + c] != '^r' && _gHTTP2_DataBuffer[iPos + c] != '^n' && c < ReturnCodeExtendedLen )
				ReturnCodeExtended[c] = _gHTTP2_DataBuffer[iPos + c++];
			ReturnCodeExtended[c] = 0;
		}
		
		iPos = containi(_gHTTP2_DataBuffer, "Transfer-Encoding: ") + 19;
		c = 0;
		
		if ( iPos != 18 && iPos < HeaderLen ) {
			while ( _gHTTP2_DataBuffer[iPos + c] != '^r' && c < charsmax(_HTTP2_TempStr) )
				_HTTP2_TempStr[c] = _gHTTP2_DataBuffer[iPos + c++];
			
			_HTTP2_TempStr[c] = 0;
			
			if ( equali(_HTTP2_TempStr, "chunked") )
				_gHTTP2_Information[Index][_Status] |= _HTTP2_STATUS_CHUNKED_TRANSFER;
		}
		
		if ( 300 <= ReturnCode <= 399 ) {
			iPos = containi(_gHTTP2_DataBuffer, "Location: ") + 10;
			c = 0;
			
			if ( iPos != 9 && iPos < HeaderLen ) {
				while ( _gHTTP2_DataBuffer[iPos + c] != '^r' && c < LocationLen )
					Location[c] = _gHTTP2_DataBuffer[iPos + c++];
				
				Location[c] = 0;
			}
		}
		
		iPos = containi(_gHTTP2_DataBuffer, "Content-Length: ") + 16;
		c = 0;
		
		if ( iPos != 15 && iPos < HeaderLen ) {
			while ( _gHTTP2_DataBuffer[iPos + c] != '^r' && c < charsmax(_HTTP2_TempStr) )
				_HTTP2_TempStr[c] = _gHTTP2_DataBuffer[iPos + c++];
			
			_HTTP2_TempStr[c] = 0;
			_gHTTP2_Information[Index][_Filesize] = str_to_num(_HTTP2_TempStr);
			_HTTP2_large_fromstring(_gHTTP2_Information[Index][_FilesizeLarge], sizeof _gHTTP2_Information[][_FilesizeLarge], _HTTP2_TempStr);
			
			static HTTP2_tempLarge[16];
			_HTTP2_large_fromint(HTTP2_tempLarge, sizeof HTTP2_tempLarge, _gHTTP2_Information[Index][_Filesize]);
			
			if ( _HTTP2_large_comp(_gHTTP2_Information[Index][_FilesizeLarge], sizeof _gHTTP2_Information[][_FilesizeLarge], HTTP2_tempLarge, sizeof HTTP2_tempLarge) != 0 )
				_gHTTP2_Information[Index][_Status] |= _HTTP2_STATUS_LARGE_SIZE;
		}
		else
			_gHTTP2_Information[Index][_Filesize] = -1;
		
		_HTTP2_ShiftData(_gHTTP2_DataBuffer, HeaderLen, _gHTTP2_BufferLen);
	}
	
	return HeaderLen;
}

_HTTP2_ParseURL(const URL[], Scheme[]="", Schemelen=0, User[]="", Userlen=0, Pass[]="", Passlen=0, Host[]="", Hostlen=0, &Port, Path[]="", Pathlen=0, Query[]="", Querylen=0, Fragment[]="", Fragmentlen=0) {
	
	new temp;
	static Regex:_HTTP2_ParseURL_hRegex;
	
	if ( ! _HTTP2_ParseURL_hRegex )
		_HTTP2_ParseURL_hRegex = regex_compile("(?:(\w+):///?)?(?:([\w&\$\+\,/\.;=\[\]\{\}\|\\\^^\~%?#\-]+):([\w&\$\+\,/\.;=\[\]\{\}\|\\\^^\~%?#\-]+)@)?((?:[\w-]+\.)*[\w-]+\.[\w-]+)?(?::(\d+))?(?:/?([\w&\$\+\,/\.;=@\[\]\{\}\|\\\^^\~%\-]*))?(?:\?([\w&\$\+\,/\.;=@\[\]\{\}\|\\\^^\~%:\-]*))?(?:#([\w&\$\+\,/\.;=@\[\]\{\}\|\\\^^\~%:\-]*))?", temp, "", 0);
	/*
	Scheme		(?:(\w+):///?)?
	Auth		(?:([\w&\$\+\,/\.;=\[\]\{\}\|\\\^^\~%?#\-]+):([\w&\$\+\,/\.;=\[\]\{\}\|\\\^^\~%?#\-]+)@)?
	Host		((?:[\w-]+\.)*[\w-]+\.[\w-]+)?
	Port		(?::(\d+))?
	Path		(?:/?([\w&\$\+\,/\.;=@\[\]\{\}\|\\\^^\~%\- ]*))?
	Query		(?:\?([\w&\$\+\,/\.;=@\[\]\{\}\|\\\^^\~%:\- ]*))?
	Fragment	(?:#([\w&\$\+\,/\.;=@\[\]\{\}\|\\\^^\~%:\- ]*))?
	*/
	new TempPort[8];
	
	regex_match_c(URL, _HTTP2_ParseURL_hRegex, temp);
	
	regex_substr(_HTTP2_ParseURL_hRegex, 1, Scheme, Schemelen);
	if ( ! Scheme[0] || equali(Scheme, "https") )
		copy(Scheme, Schemelen, "http");
	regex_substr(_HTTP2_ParseURL_hRegex, 2, User, Userlen);
	regex_substr(_HTTP2_ParseURL_hRegex, 3, Pass, Passlen);
	regex_substr(_HTTP2_ParseURL_hRegex, 4, Host, Hostlen);
	regex_substr(_HTTP2_ParseURL_hRegex, 5, TempPort, charsmax(TempPort));
	Port = str_to_num(TempPort);
	regex_substr(_HTTP2_ParseURL_hRegex, 6, Path, Pathlen);
	regex_substr(_HTTP2_ParseURL_hRegex, 7, Query, Querylen);
	regex_substr(_HTTP2_ParseURL_hRegex, 8, Fragment, Fragmentlen);
}

_HTTP2_GetChunkSize(const Data[], &ChunkSize) {
	
	new i, c, Hex[6];
	
	while ( Data[i] == '^r' || Data[i] == '^n' )
		i++;
	
	while ( _HTTP2_ishex(Data[i]) )
		Hex[c++] = Data[i++];
	
	while ( Data[i] == '^r' || Data[i] == '^n' )
		i++;
	
	ChunkSize = _HTTP2_HexToDec(Hex);
	
	return i;
}

_HTTP2_ShiftData(Data[], Amt, Len) {
	
	static _HTTP2_ShiftData_i;
	
	for ( _HTTP2_ShiftData_i = Amt ; _HTTP2_ShiftData_i < Len ; _HTTP2_ShiftData_i++ )
		Data[_HTTP2_ShiftData_i - Amt] = Data[_HTTP2_ShiftData_i];
	
	for ( _HTTP2_ShiftData_i = Len - Amt ; _HTTP2_ShiftData_i < Len ; _HTTP2_ShiftData_i++ )
		Data[_HTTP2_ShiftData_i] = 0;
	
	return Len - Amt;
}

stock _HTTP2_URLEncode(string[], len) {
	new what[2], with[4] = "^%";
	
	replace_all(string, len, "^%", "^%25");
	
	for ( new i = 0 ; i < len ; i++ ) {
		
		if ( ! string[i] )
			break;
		
		if ( ! _HTTP2_isurlsafe(string[i]) ) {
			what[0] = string[i];
			_HTTP2_DecToHex(what[0], with[1], charsmax(with) - 1);
			replace_all(string, len, what, with);
		}
	}
	replace_all(string, len, " ", "+");
}

stock _HTTP2_URLDecode(string[], len) {
	
	replace_all(string, len, "+", " ");
	
	new what[4] = "^%", with[2];
	
	for ( new i = 0 ; i < len ; i++ ) {
		
		if ( ! string[i] )
			break;
		
		if ( string[i - 2] == '^%' && _HTTP2_ishex(string[i - 1]) && _HTTP2_ishex(string[i]) ) {
			what[1] = string[i - 1];
			what[2] = string[i];
			with[0] = _HTTP2_HexToDec(what);
			if ( ! _HTTP2_isurlsafe(with[0]) )
				replace_all(string, len, what, with);
		}
	}
	replace_all(string, len, "^%25", "^%");
}

public _HTTP2_PluginUpdater_Complete(Index, Error) {
	
	new pluginfile[320], tempfile[14], temp[1], len;
	
	if ( Error ) {
		get_plugin (-1, pluginfile, charsmax(pluginfile), temp, 0, temp, 0, temp, 0, temp, 0);
		log_amx("Error(%d) while autoupdating plugin: %s", pluginfile);
		return;
	}
	
	HTTP2_getFilename(Index, tempfile, charsmax(tempfile));
	
	len = get_localinfo("amxx_pluginsdir", pluginfile, charsmax(pluginfile));
	pluginfile[len++] = '/';
	get_plugin (-1, pluginfile[len], charsmax(pluginfile) - len, temp, 0, temp, 0, temp, 0, temp, 0);
	
	delete_file(pluginfile);
	rename_file(tempfile, pluginfile, 1);
}

_HTTP2_HexToDec(string[]) {
	
	new result, mult = 1;
	
	for ( new i = strlen(string) - 1 ; i >= 0 ; i-- ) {
		result += _HTTP2_ctod(string[i]) * mult;
		mult *= 16;
	}

	return result;
}

stock _HTTP2_DecToHex(val, out[], len) {
	
	setc(out, len, 0);
	
	for ( new i = len - 1 ; val && i > -1 ; --i, val /= 16 )
		out[len - i - 1] = _HTTP2_dtoc(val % 16);
	
	new len2 = strlen(out);
	out[len2] = 0;
	new temp;
	
	for ( new i = 0 ; i < len2 / 2 ; i++ ) {
		temp = out[i];
		out[i] = out[len2 - i - 1];
		out[len2 - i - 1] = temp;
	}
}

/* Encodes a string to Base64 */
stock _HTTP2_Encode64(const InputString[], OutputString[], len) {
	
	new nLength, resPos, nPos, cCode, cFillChar = '=';
	setc(OutputString, len, 0);
	
	for ( nPos = 0, resPos = 0, nLength = strlen(InputString) ; nPos < nLength ; nPos++ ) {
		
		cCode = (InputString[nPos] >> 2) & 0x3f;
		
		resPos += formatex(OutputString[resPos], len, "%c", _HTTP2_Base64Table[cCode]);
		
		cCode = (InputString[nPos] << 4) & 0x3f;
		if ( ++nPos < nLength )
			cCode |= (InputString[nPos] >> 4) & 0x0f;
		resPos += formatex(OutputString[resPos], len, "%c", _HTTP2_Base64Table[cCode]);
		
		if ( nPos < nLength ) {
			cCode = (InputString[nPos] << 2) & 0x3f;
			if ( ++nPos < nLength )
				cCode |= (InputString[nPos] >> 6) & 0x03;
			
			resPos += formatex(OutputString[resPos], len, "%c", _HTTP2_Base64Table[cCode]);
		}
		else {
			nPos++;
			resPos += formatex(OutputString[resPos], len, "%c", cFillChar);
		}
		
		if(nPos < nLength) {
			cCode = InputString[nPos] & 0x3f;
			resPos += formatex(OutputString[resPos], len, "%c", _HTTP2_Base64Table[cCode]);
		}
		else
			resPos += formatex(OutputString[resPos], len, "%c", cFillChar);
	}
}

stock _HTTP2_reverse_string(string[]) {
	
	new temp, len = strlen(string);
	
	for ( new i = 0 ; i < len / 2 ; i++ ) {
		temp = string[i];
		string[i] = string[len - i - 1];
		string[len - i - 1] = temp;
	}
}

stock _HTTP2_large_add(large[], const large_size, const add_what[], const add_size) {
	
	new carry;
	
	for ( new i = 0 ; i < large_size ; i++ ) {
	
		if ( carry ) {
			large[i] += carry;
			carry = large[i] / 10;
			large[i] %= 10;
		}
		
		if ( i < add_size ) {
			large[i] += add_what[i];
			carry += large[i] / 10;
			large[i] %= 10;
		}
	}
}

stock _HTTP2_large_sub(large[], const large_size, const sub_what[], const sub_size) {
	
	new carry;
	
	for ( new i = 0 ; i < large_size ; i++ ) {
		
		if ( i + 1 > large_size ) {
			large[i + 1]--;
			large[i] += 10;
		}
		
		if ( carry ) {
			large[i] += carry;
			carry = large[i] / 10;
			large[i] %= 10;
		}
		
		if ( i < sub_size ) {
			large[i] -= sub_what[i];
			carry += large[i] / 10;
			large[i] %= 10;
		}
	}
}

stock _HTTP2_large_fromstring(large[], const large_size, string[]) {
	
	arrayset(large, 0, large_size);
	
	new len = strlen(string);
	_HTTP2_reverse_string(string);
	
	for ( new i = 0 ; i < large_size && string[i] && i < len ; i++ )
		large[i] = _HTTP2_ctod(string[i]);
	
	_HTTP2_reverse_string(string);
}

stock _HTTP2_large_tostring(large[], const large_size, string[], const len) {
	
	for ( new i = 0 ; i < large_size && i < len ; i++ )
		string[i] = _HTTP2_dtoc(large[i]);
	
	new pos = strlen(string);
	while ( pos > 1 && string[pos - 1] == '0' )
		pos--;
	string[pos] = 0;
	
	_HTTP2_reverse_string(string);
}

stock _HTTP2_large_fromint(large[], const large_size, const int) {
	
	arrayset(large, 0, large_size);
	new int2 = int;
	
	for ( new i = 0 ; i < large_size && int2 ; i++ ) {
		large[i] = int2 % 10;
		int2 /= 10;
	}
}

stock _HTTP2_large_toint(large[], large_size) {
	
	new retval, mult = 1;
	
	for ( new i = 0 ; i < large_size ; i++ ) {
		retval += large[i] * mult;
		mult *= 10;
	}
	
	return retval;
}

stock _HTTP2_large_comp(large1[], const large1_size, large2[], const large2_size) {
	new len1 = large1_size;
	new len2 = large2_size;
	
	while ( --len1 > 0 && large1[len1] ) { }
	while ( --len2 > 0 && large2[len2] ) { }
	
	if ( len1 > len2 )
		return 1;
	
	if ( len2 > len1 )
		return -1;
	
	for ( new i = len1 ; i >= 0 ; i-- ) {
	
		if ( large1[i] > large2[i] )
			return 1;
		
		if ( large2[i] > large1[i] )
			return -1;
	}
	
	return 0;
}
