# restore and build .NET project
cd albumapi
dotnet restore
dotnet build
cd ..

# npm install Node.js app
cd albumviewer
npm install
cd ..
