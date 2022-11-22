# restore and build .NET project
cd album-api
dotnet restore
dotnet build
cd ..

# npm install Node.js app
cd album-viewer
npm install
cd ..
