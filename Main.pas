unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, DateUtils,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Winapi.WinInet, IdGlobal, IdHash, IdHashMessageDigest, IdHMACSHA1,
  IdCoderMIME;

type
  TCoreCloudHeader = record
    header: String;
    value: String;
  end;

  TCoreCloudHeaders = array of TCoreCloudHeader;

  TMainFrm = class(TForm)
    Button1: TButton;
    AppKeyEdit: TEdit;
    SecterKeyEdit: TEdit;
    Label1: TLabel;
    Token_AuthEdit: TEdit;
    Label2: TLabel;
    Token_AccessEdit: TEdit;
    Label3: TLabel;
    Token_RefreshEdit: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    FOauthToken : string;
    FOauthSecret : string;
    FOAuthForm : TForm;
    procedure DoAuth;
    { Private declarations }
  public
    constructor Create( Owner : TComponent ); override;
    { Public declarations }
  end;
  function HttpsPost(const ServerName, Resource: String;Headers: TCoreCloudHeaders;
      const  PostData : AnsiString;Var Response:AnsiString): Integer;
  function HttpError(ErrorCode:Cardinal): string;
  function URLEncode(const Url: string): string;
  function UrlDecode(const S : String) : String;
  function HttpsGet(const Url: String; Headers: TCoreCloudHeaders) : AnsiString;

var
  MainFrm: TMainFrm;

const
  Agent = 'PECL-OAuth/1.2.3';//'Mozilla/5.001 (windows; U; NT4.0; en-US; rv:1.0) Gecko/25250101';
  CallBackURL = 'https://localhost:8080';//'';

implementation


{$R *.dfm}

const
  GAgent = 'Mozilla/5.001 (windows; U; NT4.0; en-US; rv:1.0) Gecko/25250101';

procedure CheckError( ACase : Boolean; const ErrorMsg : String );
begin
  if not ACase then
   raise Exception.Create( ErrorMsg );
end;

procedure AddHeader(var AHeaders: TCoreCloudHeaders; Header: String; Value: String);
begin
  SetLength(AHeaders, Length(AHeaders) + 1);
  AHeaders[Length(AHeaders) - 1].header := Header;
  AHeaders[Length(AHeaders) - 1].value := Value;
end;

procedure TMainFrm.Button1Click(Sender: TObject);
begin
   DoAuth;
end;


constructor TMainFrm.Create( Owner : TComponent );
begin
  inherited;
  FOAuthForm := TForm.CreateNew( Self );
  FOAuthForm.Width := 800;
  FOAuthForm.Height := 600;
  FOAuthForm.Caption := 'OAuth authorization';
  FOAuthForm.Position := poScreenCenter;
end;
function DateTimeToUnix(dtDate: TDateTime): Longint;
const
  UnixStartDate: TDateTime = 25569.0; // 01/01/1970
begin
  Result := Round((dtDate - UnixStartDate) * 86400);
end;

function GenerateNonce: string;
var
  md5: TIdHashMessageDigest;
  s: string;
begin
  s := IntToStr(GetTickCount);
  md5 := TIdHashMessageDigest5.Create;
  Result := md5.HashStringAsHex(s);
  md5.Free;
end;

function EncryptHMACSha1(Input, AKey: string): TIdBytes;
begin
  with TIdHMACSHA1.Create do
    try
      Key := ToBytes(AKey);
      Result := HashValue(ToBytes(Input));
    finally
      Free;
    end;
end;

function OAuthEncryptHMACSha1(const value,key: string): string;
begin
  Result := TIdEncoderMIME.EncodeBytes((EncryptHMACSha1(Value, Key)));
end;

function NowUTC:TDateTime;
begin
  Result:=Now-OffsetFromUTC;
end;

function OffsetFromUTC: TDateTime;
var
  iBias: Integer;
  tmez: TTimeZoneInformation;
begin
  Case GetTimeZoneInformation(tmez) of
    TIME_ZONE_ID_INVALID:
    begin
      Result:=0;
      Exit;
    end;
    TIME_ZONE_ID_UNKNOWN  :
       iBias := tmez.Bias;
    TIME_ZONE_ID_DAYLIGHT :
      iBias := tmez.Bias + tmez.DaylightBias;
    TIME_ZONE_ID_STANDARD :
      iBias := tmez.Bias + tmez.StandardBias;
    else
    begin
      Result:=0;
      Exit;
    end;
  end;
  Result := EncodeTime(Abs(iBias) div 60, Abs(iBias) mod 60, 0, 0);
  if iBias > 0 then begin
    Result := 0 - Result;
  end;
end;

procedure TMainFrm.DoAuth;
var
  baseurl,params, consec,url,sigbase, signature, oauthtoken: string;
  res : ansistring;
  headers: TCoreCloudHeaders;
begin

    baseurl:='https://api.copy.com/oauth/request';

    params :=
        'oauth_callback=' + URLEncode( '"'+ CallBackURL +'"' )
      + '&oauth_consumer_key=' + URLEncode( AppKeyEdit.Text )
      + '&oauth_nonce=' + GenerateNonce +'.'+ IntToStr(GetTickCount)
      + '&oauth_signature_method=HMAC-SHA1'
      + '&oauth_timestamp=' + IntToStr( DateTimeToUnix( Now ) )  //NowUTC
      + '&oauth_version=1.0';
    
    sigbase:='GET&'+URLEncode(baseurl)+'&'+URLEncode(params);

    consec := URLEncode(SecterKeyEdit.Text + '&' );

    signature := OAuthEncryptHMACSha1(sigbase, consec );

    url:=baseurl+'?'+params + '&oauth_signature=' + signature;

   Token_AuthEdit.Text := HttpsGet( url, headers );
 // oauth_problem=signature_invalid&debug_sbs=GET&https%3A%2F%2Fapi.copy.com%2Foauth%2Frequest&oauth_callback%3D%2522http%253A%252F%252F127.0.0.1%253A8889%252F%2522%26oauth_consumer_key%3D5znMJPQpLOY1PnEyG34Zb9lpSNcqqwoi%26oauth_nonce%3D333D5355281463D82DF5ED7D155DFE6B.324990112%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1394901745%26oauth_version%3D1.0%26scope%3D%257B%2522profile%2522%253A%257B%2522read%2522%253A%2520true%252C%2522write%2522%253A%2520true%257D%257Doauth_error_code=2000'

end;



////////////////////////////////////////////////////////////////////////////////
/////////////////////////Details////////////////////////////////////////////////
function HttpError(ErrorCode:Cardinal): string;
const
   winetdll = 'wininet.dll';
var
  Len: Integer;
  Buffer: PChar;
begin
  Len := FormatMessage(
  FORMAT_MESSAGE_FROM_HMODULE or FORMAT_MESSAGE_FROM_SYSTEM or
  FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_IGNORE_INSERTS or  FORMAT_MESSAGE_ARGUMENT_ARRAY,
  Pointer(GetModuleHandle(winetdll)), ErrorCode, 0, @Buffer, SizeOf(Buffer), nil);
  try
    while (Len > 0) and {$IFDEF UNICODE}(CharInSet(Buffer[Len - 1], [#0..#32, '.'])) {$ELSE}(Buffer[Len - 1] in [#0..#32, '.']) {$ENDIF} do Dec(Len);
    SetString(Result, Buffer, Len);
  finally
    LocalFree(HLOCAL(Buffer));
  end;
end;

procedure SetTimeouts(const AHandle:HInternet);
var
  dwTimeout: DWORD;
begin
  dwTimeout:=60000;
  InternetSetOption(AHandle,INTERNET_OPTION_CONNECT_TIMEOUT,@dwTimeout,sizeof(dwTimeout));
  InternetSetOption(AHandle,INTERNET_OPTION_RECEIVE_TIMEOUT,@dwTimeout,sizeof(dwTimeout));
  InternetSetOption(AHandle,INTERNET_OPTION_SEND_TIMEOUT,@dwTimeout,sizeof(dwTimeout));
  end;

function HttpsGet(const Url: String; Headers: TCoreCloudHeaders) : AnsiString;
var
  NetHandle: HINTERNET;
  UrlHandle: HINTERNET;
  Buffer: array[0..1024] of AnsiChar;
  BytesRead: dWord;
  Header: string;
  I: Integer;
begin


  header := '';
  if Assigned(headers) then
  begin
    for I := 0 to Length(headers) - 1 do
      header := header + Headers[I].header + ': ' + headers[I].value;
  end;

  //Result := '';
  NetHandle := InternetOpen(PChar(GAgent), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);

  if Assigned(NetHandle) then
  begin
    SetTimeouts(NetHandle);
    if Header <> '' then
      UrlHandle := InternetOpenUrl(NetHandle, PChar(Url), PChar(Header), Length(Header), INTERNET_FLAG_RELOAD, 0)
    else
      UrlHandle := InternetOpenUrl(NetHandle, PChar(Url), nil, 0, INTERNET_FLAG_RELOAD, 0);

    if Assigned(UrlHandle) then
    begin
      repeat
        BytesRead := 0;
        //fillchar( buffer, sizeof( buffer ), #0 );
        InternetReadFile(UrlHandle, @Buffer, SizeOf(Buffer) - 1, BytesRead);
        buffer[BytesRead] := #0;
        Result := Result + Copy( buffer, 1, BytesRead );//Copy( buffer, 0, BytesRead -1 );
      until (BytesRead = 0);
      InternetCloseHandle(UrlHandle);

    end
    else
      raise Exception.CreateFmt('Cannot open URL %s', [Url]);

    InternetCloseHandle(NetHandle);
  end
  else
    raise Exception.Create('Unable to initialize Wininet');
end;


function HttpsPost(const ServerName, Resource: String;Headers: TCoreCloudHeaders;const  PostData : AnsiString;Var Response:AnsiString): Integer;
const
  BufferSize = 1024*64;
var
  hInet: HINTERNET;
  hConnect: HINTERNET;
  hRequest: HINTERNET;
  ErrorCode: Integer;
  lpdwBufferLength: DWORD;
  lpdwReserved: DWORD;
  dwBytesRead: DWORD;
  Flags: DWORD;
  Buffer: array[0..1024] of AnsiChar;
  Header: string;
  I: Integer;
begin
  header := '';
  if Assigned(headers) then
  begin
    for I := 0 to Length(headers) - 1 do
      header := header + Headers[I].header + ': ' + headers[I].value;
  end;

  Result := 0;
  Response := '';
  hInet := InternetOpen(PChar(Agent), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);

  if hInet = nil then
  begin
    ErrorCode := GetLastError;
    raise Exception.Create(Format('InternetOpen Error %d Description %s',[ErrorCode,HttpError(ErrorCode)]));
  end;

  try
    hConnect := InternetConnect(hInet, PChar(ServerName), INTERNET_DEFAULT_HTTPS_PORT, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
    if hConnect=nil then
    begin
      ErrorCode := GetLastError;
      raise Exception.Create(Format('InternetConnect Error %d Description %s',[ErrorCode,HttpError(ErrorCode)]));
    end;

    try
      Flags := INTERNET_FLAG_SECURE;
      Flags := Flags or INTERNET_FLAG_PASSIVE;
      Flags := Flags or INTERNET_FLAG_KEEP_CONNECTION;
      hRequest := HttpOpenRequest(hConnect, 'POST', PChar(Resource), HTTP_VERSION, '', nil, Flags, 0);
      if hRequest=nil then
      begin
        ErrorCode := GetLastError;
        raise Exception.Create(Format('HttpOpenRequest Error %d Description %s',[ErrorCode,HttpError(ErrorCode)]));
      end;

      try
        //send the post request
        if not HTTPSendRequest(hRequest, PChar(Header), Length(Header), @PostData[1], Length(PostData)) then
        begin
          ErrorCode := GetLastError;
          raise Exception.Create(Format('HttpSendRequest Error %d Description %s',[ErrorCode,HttpError(ErrorCode)]));
        end;

          lpdwBufferLength := SizeOf(Result);
          lpdwReserved := 0;
          //get the response code
          if not HttpQueryInfo(hRequest, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER, @Result, lpdwBufferLength, lpdwReserved) then
          begin
            ErrorCode := GetLastError;
            raise Exception.Create(Format('HttpQueryInfo Error %d Description %s',[ErrorCode,HttpError(ErrorCode)]));
          end;

         //OutputDebugString(pchar(IntToStr(Result)));
         //if the response code = 200 then get the body
         if (Result in [200,201]) or (Result = 401) then
         begin
           Response := '';
           dwBytesRead := 0;
           FillChar(Buffer, SizeOf(Buffer), 0);
           repeat
             Response := Response + Copy(Buffer, 1, dwBytesRead);
//             outputdebugstring(pchar(inttostr(Length(Response))));
             FillChar(Buffer, SizeOf(Buffer), 0);
             InternetReadFile(hrequest, @Buffer, SizeOf(Buffer), dwBytesRead);
           until dwBytesRead = 0;
         end;

      finally
        InternetCloseHandle(hRequest);
      end;
    finally
      InternetCloseHandle(hConnect);
    end;
  finally
    InternetCloseHandle(hInet);
  end;
end;

function URLEncode(const Url: string): string;
var
  i: Integer;
  UrlA: ansistring;
  res: ansistring;
begin
  res := '';
  UrlA := ansistring(UTF8Encode(Url));

  for i := 1 to Length(UrlA) do
  begin
    case UrlA[i] of
      'A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.':
        res := res + UrlA[i];
    else
        res := res + '%' + ansistring(IntToHex(Ord(UrlA[i]), 2));
    end;
  end;

  Result := string(res);
end;

function XDigit(Ch : Char) : Integer;
begin
    case Ch of
        '0'..'9' : Result := Ord(Ch) - Ord('0');
    else
        Result := (Ord(Ch) and 15) + 9;
    end;
end;


function htoi2(const S1,S2:Char):Integer;
begin
  Result:=XDigit(S1)*16+XDigit(S2);
  end;

function UrlDecode(const S : String) : String;
var
    I, J, L : Integer;
    U8Str   : AnsiString;
    Ch      : AnsiChar;
begin
    L := Length(S);
    SetLength(U8Str, L);
    I := 1;
    J := 0;
    while (I <= L) do begin
        Ch := AnsiChar(S[I]);
        if Ch = '%' then begin
            Ch := AnsiChar(htoi2(S[I + 1],S[I + 2]));
            Inc(I, 2);
        end
        else if Ch = '+' then
            Ch := ' ';
        Inc(J);
        U8Str[J] := Ch;
        Inc(I);
    end;
    SetLength(U8Str, J);
    Result := U8Str;
  end;


end.

