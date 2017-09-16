@echo off
set PARAMETERS=0
for %%x in (%*) do set /A PARAMETERS+=1


REM ADD ipaddress,container name,owner
REM REMOVE container name

REM ADD if container name there, ignore
set HOSTSFILE="c:\windows\system32\drivers\etc\hosts"


if ["%1"] == ["ADD"] (
	call :DELETE %3
	call :ADD %2 %3 %4
	
) 
if ["%1"] == ["DELETE"] (
	call :DELETE %2
)

if ["%1"] == ["PURGE"] (
	call :PURGE %2
)
goto :EOF

:DELETE
	REM %1=container name
	if EXIST newhosts rm newhosts
	for /f "tokens=1,2,3,4*" %%a in ('type c:\windows\system32\drivers\etc\hosts') do (
		if NOT "%%b" == "%1" (
				if "%%a" == "#" (
					echo %%a %%b %%c %%d %%e>> newhosts
				) else (
					echo %%a	%%b	%%c>> newhosts
				)
		)
	)
	if NOT EXIST newhosts echo # > newhosts
	copy newhosts %HOSTSFILE%
	del /f newhosts
	echo %2 removed from hosts.
goto :EOF

:ADD
	type %HOSTSFILE% > newhosts 
	echo adding %2 to HOSTS
	echo %1	%2	#%3# >> newhosts
	copy newhosts %HOSTSFILE%
	del /f newhosts
	echo %3 appended to hosts.

goto :EOF

:PURGE
	REM %1=container name
	if EXIST newhosts rm newhosts
	for /f "tokens=1,2,3,4*" %%a in ('type c:\windows\system32\drivers\etc\hosts') do (
		if NOT "%%c" == "#%1#" (
			echo %%a %%b %%c %%d %%e >> newhosts
		) 
	)
	if NOT EXIST newhosts echo # > newhosts
	copy newhosts %HOSTSFILE%
	del /f newhosts
	echo %2 removed from hosts.
goto :EOF
:EOF