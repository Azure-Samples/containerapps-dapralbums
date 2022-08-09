# Build and run solution

- [Build and run with VS Code](#build-and-run-with-vs-code)
- [Build and run manually](#build-and-run-manually)

## Pre-requisites

- [VS Code](https://code.visualstudio.com/)
- [Node.js](https://nodejs.org/en/download/)
- [Dapr](https://docs.dapr.io/getting-started/install-dapr-cli/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)

### Build and run with VS Code

1. Fork the sample repo
1. Clone the repo: `git clone https://github.com/{username}/containerapps-dapralbums`
1. Open the cloned repo in VS Code
1. Follow the prompt to install recommended extensions
1. Select the debug **All services** and run the sample locally

> NOTE: You may need to modify your VS Code configuration or some of the tasks depending on where you have node and dotnet installed on your local machine.

Any changes made to the project and checked into your GitHub repo will trigger a GitHub action to build and deploy

### Build and run manually

#### Steps

1. Fork the sample repo
1. Clone the repo: `git clone https://github.com/{username}/containerapps-dapralbums`
1. Build the sample:

```bash
cd album-viewer
npm install
cd ../album-api
dotnet restore
```

1. Run the sample

#### Local run and debug

The Dapr CLI will launch our application and dapr alongside one another. In the below commands we provide important information Dapr needs in order to interact with our microservices. The `app-id` is the unique value assigned to a given dapr app and is used in things like Dapr service-to-service calls and for scoping components to specific dapr apps. The `app-port` should match the exposed port in an application's dockerfile. This is the port which Dapr uses to establish a localhost communication path to our application services. The `dapr-http-port` represents the port on which our app talks to dapr and the `components-path` directs the dapr runtime to load all components specified in this directory.

For local debugging and development, the component used by the album api to manage state is a containerized redis instance running on Docker. Once deployed to Azure, this component is swapped for an Azure Storage account and because of the pluggability Dapr provides, no code changes are required in order to make this change.

Now, it's time to run the `album-api` in a new terminal window- ensure you are sitting in the directory which holds the app code.

```bash
cd album-api
dapr run --app-id album-api --app-port 80 --dapr-http-port 3500 --components-path ../dapr-components/local -- dotnet run
```

Once the api is up and running, launch a new terminal to run the frontend application.

```bash
cd album-viewer
dapr run --app-id album-viewer --app-port 3000 --dapr-http-port 3501 --components-path ../dapr-components/local -- npm run start
```

Validate the applications are up and running by navigating to localhost:3000!
