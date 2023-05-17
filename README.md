# Azure Container Apps: Dapr Albums Sample

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=self-deploying-at-once&repo=568924714&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json&location=EastUs)

This repository was created to help users quickly deploy Dapr-enabled microservices to Azure Container Apps.

## Solution Overview

The solution is composed of two microservices: the album API and the album viewer.

![architecture](./assets/architecture.png)

#### Album API (`albumapi`)

The [`albumapi`](./albumapi/) is an .NET 7 minimal Web API that retrieves a list of Albums from Azure Storage using the Dapr State Store API. Upon running the application for the first time the state store will be initialized with data. For subsequent calls, the list of albums will be retrieved from the backing state store.

#### Album Viewer (`python-app`)

The [`albumviewer`](./albumviewer/) is a Node.js client application through which the albums retrieved by the API are surfaced. In order to display the repository of albums, the album viewer microservice uses the Dapr Service invocation API to contact the backend album API.

## Run locally

### Run in Visual Studio

1. Load the `albumapi.sln` solution in VS 2022 for any editing
2. To run, we'll still use a Terminal

```bash
cd ./albumapi/
dotnet build
dapr run --app-id albumapi --app-port 5007 --dapr-http-port 3500 --components-path ../dapr-components/local -- dotnet run --urls "http://localhost:5007"
```

The API service is started on http://localhost:5007 and can be called with the http://localhost:5007/albums route.  

```bash
cd ./albumviewer/
npm install
dapr run --app-id albumviewer --app-port 3000 --dapr-http-port 3501 --components-path ../dapr-components/local -- npm run start --urls "http://localhost:3000"
```

The Web client app will be running on http://localhost:3000

### Run in VS Code

1. Load this folder in VS Code

```bash
code .
```

2. In the Run and Debug menu, selected "All services", and Press `Start Debugging (F5)`
3. In the PORTS window, right click on the endpoint running on port 3000, Open in Browser


### Run in CodeSpaces

1. Load this repo in a CodeSpace clicking this button

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=self-deploying-at-once&repo=568924714&machine=standardLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json&location=EastUs)

2. In the Run and Debug menu, selected "All services", and Press `Start Debugging (F5)`
3. In the ports window, right click on the endpoint running on port 3000, Open in Browser

### Run in the Terminal

1. Start the `albumapi` app in a new Terminal window

```bash
dotnet build
dapr run --app-id albumapi --app-port 5007 --dapr-http-port 3500 --components-path ../dapr-components/local -- dotnet run --urls "http://localhost:5007"
```

The API service is started on http://localhost:5007 and can be called with the http://localhost:5007/albums route.  


2. Open another Terminal window, restore and start the `albumviewer` app

```bash
cd ./albumviewer/
npm install
dapr run --app-id albumviewer --app-port 3000 --dapr-http-port 3501 --components-path ../dapr-components/local -- npm run start --urls "http://localhost:3000"
```

The Web client app will be running on http://localhost:3000

## Deploy using the Azure Developer CLI

Provision and deploy the entire application and dependencies using [Azure Developer CLI](https://aka.ms/azd)
```bash
azd up
```

## Deploy via GitHub Actions

The entire solution is configured with [GitHub Actions](https://github.com/features/actions) and [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/overview) for CI/CD

1. Fork the sample repo
2. Create the following required [encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) for the sample
   | Name | Value |
   | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | AZURE_CREDENTIALS | The JSON credentials for an Azure subscription. Replace the placeholder values and run the following command to generate the Azure authentication information for this GitHub secret `az ad sp create-for-rbac --name INSERT_SP_NAME --role contributor --scopes /subscriptions/INSERT_SUBSCRIPTION_ID --sdk-auth`. For guidance on adding a secret, [see here](https://docs.microsoft.com/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#create-a-service-principal-and-add-it-as-a-github-secret) |
   | RESOURCE_GROUP | The name of the resource group to create |
   | GH_PAT | [Generate a GitHub personal access token with `write:packages` permission](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) and store as a pipeline secret. This PAT will be used to push images to your private GitHub Package Registry.  |

3. Open the Actions tab, select the **Build and Deploy** action and choose to run the workflow. The workflow will build the necessary container images, push them to your private Github Package Registry and deploy the necessary Azure services along with two Container Apps for the respective services.

4. Once the GitHub Actions have completed successfully, navigate to the [Azure Portal](https://portal.azure.com) and select the resource group you created. Open the `albumviewer` container app and browse to the FQDN displayed on the overview blade. You should see the sample application up and running.

