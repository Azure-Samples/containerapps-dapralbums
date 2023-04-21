<!-- Generate a focumentation with a list of sample prompt to demo github copilot capacities -->

# Github Copliot demo (Fork from Azure Container Apps: Dapr Albums Sample)

This a list of prompts xith explaination you can use to demo or simply discover Github Copilot capacities.

1. To see this demos you can watch the **Azure Insider's Café replay** on Github Copilot: 
- [Sharepoint Link](https://teams.microsoft.com/l/message/19:9e3c0d7097f34928b16f28d5ccc34b5a@thread.skype/1681479717297?tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47&groupId=98c78e40-e3a1-43ab-9891-7fdc081c6136&parentMessageId=1679658115567&teamName=Club%20Azure%20Insiders&channelName=%F0%9F%92%BB%20AppDev&createdTime=1681479717297) [`Microsoft Internal`]
- [External sharing link](https://info.microsoft.com/FR-DevOps-VDEO-FY23-04Apr-19-Replay-Cafe-Insiders-GitHub-Copilot-SRGCM9963_LP01-Registration---Form-in-Body.html)

2. You can find out more on the official **Github Copilot Demos repo** here: https://github.com/gh-msft-innersource/Copilot-demo-templates/ [`Microsoft Internal`]

<br>

# Quickstart

## Install & Activate

TBD

## VSCode Shortcuts

Once you start typing a prompt and copilot generate proposals, you can use the following shortcuts to interact with Copilot:

- `tab` to accept the current suggestion entirely (`most common`)
- `ctrl + right arrow` to accept word by word the suggestion (`for partial use`)
- `alt + ^` to move to next suggestion	
- `shift + tab` to go back to the previous suggestion	
- `ctrl+enter` to display the copilot pane

If you can't remember it, just hover your pointer on top of a suggestion to make them appear.
<br>

# Demos

## Natural Language Translations

**Automate text translation**

- Open file `album-viewer/lang/translations.json`
```json
[
    {
        "language": "en",
        "values": {
            "main-title": "Welcome to the world of the future",
            "main-subtitle": "The future is now with copilot",
            "main-button": "Get started"
        }
    }
]
```

- Start adding a new block by adding a "," after the last "}" and press enter

<br>

## Code Generation

**Generate code from prompt**

- Create a new `album-viewer/utils/validators.ts` file and start with the prompt:
```ts
// validate date from text input in french format and convert it to a date object
```

- Copilot can help you also to write `RegExp patterns`. Try these:
```ts
// function that validates the format of a GUID string

// function that validates the format of a IPV6 address string
```

<br>

**Discover new tool and library on the job with Copilot**

- Still on the same `album-viewer/utils/validators.ts` file add the following prompt:
```ts
// validate phone number from text input and extract the country code
```
>For this one it will probably give you proposal that call some methods not defined here and needed to be defined. It's a good opportunity to explore the alternatives using the `ctrl+enter` shortcut to display the copilot pane. 
<br>You can choose one that uses something that looks like coming for an external library and use copilot to import it showing that the tool helps you discover new things.


**Complex algoritms generation**

- In the `albums-api/Controllers/AlbumController.cs` file try to complete the `GetByID` method by replace the current return:

```cs
// GET api/<AlbumController>/5
[HttpGet("{id}")]
public IActionResult Get(int id)
{
    //here
}
```

- In the same file you can show other prompts like:
```cs
// function that search album by name, artist or genre

// function that sort albums by name, artist or genre
```

## Big Prompts and Short Prompts

Copilot will probably will always more effective with prompt to generate small but precisely described pieces of code rather than a whole class with a unique multiple lines prompt.

The best strategy i experimented to generate big piece of code, is starting by the basic shell of your code with a simple prompt and then adding small pieces one by one.

**Big prompts that works**

- Back in the `albums-viewer/utils` add a new file `viz.ts` to create a function that generates a graphe. Here is a sample of prompt to do that:

```ts
// generate a plot with d3js of the selling price of the album by year
// x-axis are the month series and y-axis show the numbers of album selled
```
>You can try to add details when typing by adding it or following copilot's suggestions and see what happens

- Once you achieved to generate the code for the chart you probably see that your IDE warn you about the d3 object that is unknow. For that also Copilot helps.
Return on top of the file and start typing `import d3` to let copilot autocomplete

```ts
import d3 from "d3";
```


<!-- Stopped working reccently don't know why
- Another prompt that is totally decorrelated with the codebase but interesting as the prompt can be very long if you follow all suggestion by copilot is the following one:
```ts
// I need a function that finds the way out of a labyrinth. The labyrinth is a matrix of 0 and 1 and 1 represent a wall
```
*I used to show this one in another language like C for example. As it's a common algorithm problem, you can let copilot complete this one for 4 to 5 line to show how precise can be the tools and when you reach the limit to generate something usable* -->

## Code Documentation 

Copilot can understand a natural language prompt and generate code and because it's just language to it, it can also `understand code and explain it in natural language` to help you document your code.

### simple documentation comment

To see that just put you pointer on top of a Class, a method or any line of code and start typing the comment handler for the selected language to trigger copilot. In language like Java, C# or TS for example, just type `// `and let the magic happen.

Here is an example in the `albums-viewer/routes/index.js` file. Insert a line and start typing on line 13 inside the `try block`

```js
router.get("/", async function (req, res, next) {
  try {
    // Invoke the album-api via Dapr
    const url = `http://127.0.0.1:${DaprHttpPort}/v1.0/invoke/${AlbumService}/method/albums`;

```

Continue to play with it and see what happens on other pieces of code.

### standardized documentation comment (JavaDoc, JsDoc, etc...)

For this one, to trigger the documentation comment generation, you need to respect the specific comment format:
-  `/**` (for JS/TS) in the index.js file for example
- `///` for C# in the AlbumController.cs of the AlbumApi file for example

```cs
/// <summary>
/// function that returns a single album by id
/// </summary>
/// <param name="id"></param>
/// <returns></returns>
[HttpGet("{id}")]
public IActionResult Get(int id)
```


## Code Translation

*Copilot can understand and generate natural languages and code language in both way so by combining everything you can use it to `translate code pieces from a language to another one`*

Try


## Tests

- Add a new test to the `AlbumController` class to test the new method you added

## Refactoring

- Refactor the `AlbumController` class to use the new method you added


# Concepts

WIP

# Extra: Copilot Labs

WIP

# Extra: Copilot X - Preview

`More to come...`
