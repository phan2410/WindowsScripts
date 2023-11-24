::Usage: refresh_aws_mfa_session.bat <OTP-CODE> [force]
@echo off
set MfaDeviceArn='arn:aws:iam::298080379523:mfa/FanPhone'
set DurationInSeconds=129600

set otp=%1
set force=%2

if [%otp%] == [] (
    echo Missing OTP-CODE.
    goto EndWithError
)

if ["%force%"] == ["force"] goto GetSessionToken

aws s3 ls 1>NUL 2>NUL && (
    echo Do nothing. The current session is still active
    echo If you persist, please rerun the command with "force" at the end.
    goto End
)

:GetSessionToken
    setlocal enabledelayedexpansion
    set count=1
    for /F "tokens=* USEBACKQ" %%F in (`powershell -Command "$Env:AWS_ACCESS_KEY_ID='';$Env:AWS_SECRET_ACCESS_KEY='';$Env:AWS_DEFAULT_REGION='';$TempCredentials=aws sts get-session-token --serial-number %MfaDeviceArn% --token-code %otp% --duration-seconds %DurationInSeconds% --profile default | ConvertFrom-Json;echo ($TempCredentials).Credentials.AccessKeyId;echo ($TempCredentials).Credentials.SecretAccessKey;echo ($TempCredentials).Credentials.SessionToken;echo ($TempCredentials).Credentials.Expiration"`) do (
        set awskey!count!=%%F
        set /a count=!count!+1
    )
    if not ["%awskey4%"] == [""] echo Token Expire Time: %awskey4%
    endlocal & set "AWS_ACCESS_KEY_ID=%awskey1%" & set "AWS_SECRET_ACCESS_KEY=%awskey2%" & set "AWS_SESSION_TOKEN=%awskey3%"

    set not_good=
    if ["%AWS_ACCESS_KEY_ID%"] == [""] set not_good=1
    if ["%AWS_SECRET_ACCESS_KEY%"] == [""] set not_good=1
    if ["%AWS_SESSION_TOKEN%"] == [""] set not_good=1
    if defined not_good (
        echo Failed to get session token.
        goto EndWithError
    ) else echo OK. Token Obtained.

    setx AWS_ACCESS_KEY_ID "%AWS_ACCESS_KEY_ID%"
    setx AWS_SECRET_ACCESS_KEY "%AWS_SECRET_ACCESS_KEY%"
    setx AWS_SESSION_TOKEN "%AWS_SESSION_TOKEN%"
goto End

:EndWithError
    exit /b 1

:End