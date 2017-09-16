@echo off
set PARAMETERS=0
for %%x in (%*) do set /A PARAMETERS+=1

REM %1=axction, %2=container,%3=tzddockerhostname
REM ADD container tzddockerhostname
REM REMOVE container tzddockerhostname

if ["%1"] == ["ADD"] (
	call :DELETE %2 %3
	call :ADD %2 %3
	
) 
if ["%1"] == ["DELETE"] (
	call :DELETE %2 %3
)

if ["%1"] == ["PURGE"] (
	call :PURGE %2
)
goto :EOF

:DELETE
	REM %1=container name
	if EXIST newrdp del newrdp
	echo %1.%2.rdp
	if EXIST c:\users\public\Desktop\%1.%2.rdp del c:\users\public\Desktop\%1.%2.rdp
goto :EOF

:ADD
	type "c:\program files\openssh\bin\rdptemplate.txt" > "c:\program files\openssh\bin\newrdp" 
	echo full address:s:%1 >> "c:\program files\openssh\bin\newrdp"
	copy "c:\program files\openssh\bin\newrdp"  c:\users\public\Desktop\%1.%2.rdp
	del /f "c:\program files\openssh\bin\newrdp"
goto :EOF

:PURGE
	REM %1=tzddockerhostname
	del c:\users\public\Desktop\*.%1.rdp
goto :EOF
:EOF