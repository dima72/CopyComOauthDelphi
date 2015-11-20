# CopyComOauthDelphi
Example of Oauth with CopyCom in Delphi

Entry point is function DoAuth, please start from there in order to see where problem happens.

AppKey and AppSecret provided is just for test purpose.

Please help me to get auth_token. Few mouhts ago CopyCom stopped to work, starting to
get exception oauth_problem=timestamp_refusedoauth_error_code=2000

Please note if param
oauth_timestamp=  Now  then Oauth request returns
oauth_problem=timestamp_refusedoauth_error_code=2000

if param
oauth_timestamp=  NowUTC then server response is
oauth_problem=signature_invalid&debug_sbs=GET&https%3A%2F%2Fapi.copy.com%2Foauth%2Frequest&oauth_callback%3D%2522https%253A%252F%252Flocalhost%253A8080%2522%26oauth_consumer_key%3DFnQFwRZnBHZt1DmcHAaeVotL2Us5p5VV%26oauth_nonce%3DF4E9C5781F018A48182268045496F008.209665312%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1447867039%26oauth_version%3D1.0oauth_error_code=2000


oauth_signature in my view implemented correctly because it is used for other projects and works fine.
