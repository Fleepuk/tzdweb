@echo off
if ["%1"] == ["PURGE"] (
        call :PURGE %2
)
if ["%1"] == ["ADD"] (
        call :ADD %2 %3
)
if ["%1"] == ["REMOVE"] (
        call :REMOVE %2
)

goto EOF

:PURGE
	for /f "tokens=1*" %%a in ('reg query HKLM\SOFTWARE\WOW6432Node\Intersystems\Cache\Servers') do (
		for /f "delims=\ tokens=1-8*" %%n in ('echo %%a') do (
			if NOT "%%t" == "" (
				for /f "tokens=2*" %%k in ('reg query HKLM\SOFTWARE\WOW6432Node\Intersystems\Cache\Servers\%%t /v "Comment"') do (
					if "%%l" == "%1" (
						reg delete HKLM\SOFTWARE\WOW6432Node\Intersystems\Cache\Servers\%%t /f 
					)
				)
			) 
		)
	)

goto EOF

:ADD
	set REGADD="HKLM\SOFTWARE\WOW6432Node\Intersystems\Cache\Servers\%1"
	reg query %REGADD% 2>nul 1>nul
	if NOT %errorlevel%==1 goto EOF
	echo %1,%2,%REGADD%
	reg add %REGADD% /v Address /t REG_SZ /d %1 > NUL
	reg add %REGADD% /v Port /t REG_SZ /d 1972 > NUL
	reg add %REGADD% /v Telnet /t REG_SZ /d 23 > NUL
	if [%2]==[] (
		reg add %REGADD% /v Comment /t REG_SZ > NUL
	) else (
		reg add %REGADD% /v Comment /t REG_SZ /d %2 > NUL
	)

	reg add %REGADD% /v AuthenticationMethod /t REG_SZ /d 0 > NUL
	reg add %REGADD% /v ConnectionSecurityLevel /t REG_SZ > NUL
	reg add %REGADD% /v ServicePrincipalName /t REG_SZ > NUL
	reg add %REGADD% /v ServerType /t REG_SZ > NUL
	reg add %REGADD% /v WebServerPort /t REG_SZ /d 57772 > NUL
	reg add %REGADD% /v WebServerAddress /t REG_SZ /d %1 > NUL
	reg add %REGADD% /v WebServerInstanceName /t REG_SZ > NUL

goto EOF

:REMOVE
	
	reg delete HKLM\SOFTWARE\WOW6432Node\Intersystems\Cache\Servers\%1 /f > NUL
:EOF