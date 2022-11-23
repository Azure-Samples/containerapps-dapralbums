# Build and run solution

- [Build and run with VS Code](#build-and-run-with-vs-code)
- [Build and run manually](#build-and-run-manually)

## Pre-requisites

- [VS Code](https://code.visualstudio.com/)
- [Node.js](https://nodejs.org/en/download/)
- [Dapr](https://docs.dapr.io/getting-started/install-dapr-cli/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)

## Initialize Dapr
Dapr is a developer API that powers a number of microservices features like service invoke and state management.  Dapr must be initialized just once in this 
dev container to enable these features, APIs, and dependencies like the local Redis container.

1. Initialize Dapr and depenencies.  

```bash
dapr init
```

### Build and run with VS Code

1. Fork the sample repo
1. Clone the repo: `git clone https://github.com/{username}/containerapps-dapralbums`
1. Open the cloned repo in VS Code
1. Follow the prompt to install recommended extensions
1. Select the debug **All services** and run the sample locally

> NOTE: You may need to modify your VS Code configuration or some of the tasks depending on where you have node and dotnet installed on your local machine.

Any changes made to the project and checked into your GitHub repo will trigger a GitHub action to build and deploy

### Build and run 

#### Steps

1. Fork the sample repo
2. Clone the repo: `git clone https://github.com/{username}/containerapps-dapralbums`
3. Build the sample and install local dev cert:

No steps are needed here since it's already taken care of by the `deploy/local-dev/localinit.sh` and `build.sh` scripts.

4. Run the sample

```bash
tye run
```

Browse to port 3000 for the running application and port 8000 for the Tye dashboard to see errors

(Note if you see errors or recycle of Tye, make sure you did a `dapr init` first)

#### Local run and debug

The Dapr CLI will launch our application and dapr alongside one another. In the below commands we provide important information Dapr needs in order to interact with our microservices. The `app-id` is the unique value assigned to a given dapr app and is used in things like Dapr service-to-service calls and for scoping components to specific dapr apps. The `app-port` should match the exposed port in an application's dockerfile. This is the port which Dapr uses to establish a localhost communication path to our application services. The `dapr-http-port` represents the port on which our app talks to dapr and the `components-path` directs the dapr runtime to load all components specified in this directory.

For local debugging and development, the component used by the album api to manage state is a containerized redis instance running on Docker. Once deployed to Azure, this component is swapped for an Azure Storage account and because of the pluggability Dapr provides, no code changes are required in order to make this change.

##### Using Tye

Once the projects are restored and built, the easiest way to start the microservices application is using Tye.  Simply do this in the main folder:

```bash
tye run
```

##### Using individual `dapr run` commands

Alternatively you can `dapr run` each microservice to start the app and its respective sidecar as follows:

The init scripts ensure each application is restored and built before running.  You can do this manually by: 

```bash
cd albumviewer
npm install
cd ../albumapi
dotnet restore
dotnet dev-certs https
```

Now, it's time to run the `albumapi` in a new terminal window- ensure you are sitting in the directory which holds the app code.

```bash
cd albumapi
dapr run --app-id albumapi --app-port 5007 --dapr-http-port 3500 --components-path ../dapr-components/local -- dotnet run
```

Once the api is up and running, launch a new terminal to run the frontend application.

```bash
cd albumviewer
dapr run --app-id albumviewer --app-port 3000 --dapr-http-port 3501 --components-path ../dapr-components/local -- npm run start
```

Validate the applications are up and running by navigating to localhost:3000!
