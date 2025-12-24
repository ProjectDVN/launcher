:: Clear output
cls

:: Sets the names of the projects
set CLIENT_OUTPUT="DVN.exe"

cd source
cd client

:: Shuts down the client if it's running
taskkill /F /IM %CLIENT_OUTPUT%

:: Builds the client project
dub test

:: Moves the path to the server output
cd ..
cd ..
