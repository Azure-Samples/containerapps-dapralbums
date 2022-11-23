
# install Azure CLI extension for Container Apps
az config set extension.use_dynamic_install=yes_without_prompt
az extension add --name containerapp --yes

# install Node.js and NPM LTS
nvm install v18.12.1

# initialize Dapr
dapr init

# install Tye
dotnet tool install -g Microsoft.Tye --version "0.11.0-alpha.22111.1"

# add developer cert for .NET project
cd albumapi
dotnet dev-certs https
cd ..

# restore and build apps
chmod +x ./deploy/local-dev/build.sh
./deploy/local-dev/build.sh
