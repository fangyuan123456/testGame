set /p isbase = "(y/n):"
set /p version = ""
node makeDownLoad.js -b %isbase% -v %version%
pause