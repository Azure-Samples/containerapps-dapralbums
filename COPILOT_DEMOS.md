<!-- Generate a focumentation with a list of sample prompt to demo github copilot capacities -->

# Github Copliot demo (Fork from Azure Container Apps: Dapr Albums Sample)

This a list of prompts xith explaination you can use to demo or simply discover Github Copilot capacities.

1. To see this demos you can watch the **Azure Insider's Café replay** on Github Copilot on Youtube

2. You can find out more on the official **Github Copilot Demos repo** here: https://github.com/gh-msft-innersource/Copilot-demo-templates/ [`Microsoft Internal`]

<br>

# Quickstart

WIP

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


## Code Generation

**Generate code from pormpt**

- Create a new `album-viewer/utils/validators.ts` file and start with the prompt:
```ts
// validate date from text input in french format and convert it to a date object
```

- Continue on the same file with:
```ts
// validate phone number from text input and extract the country code
```
*For this one it will probably give you proposal that call some methods not defined here and needed to be defined. It's a good topportunity to explore the alternatives. You can choose one that uses something that looks like coming for an external library and use copilot to import it showinf that the tool helps you discover new things.*

- Copilot can help you also to write `RegExp patterns`. Try these:
```ts
// function that validates the format of a GUID string

// function that validates the format of a IPV6 address string
```
<br>

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
*You can try to add details when typing by adding it or following copilot's suggestions and see what happens*

- Another prompt that is totally decorrelated with the codebase but interesting as the prompt can be very long if you follow all suggestion by copilot is the following one:
```ts
// I need a function that finds the way out of a labyrinth. The labyrinth is a matrix of 0 and 1 and 1 represente a wall
```
*I used to show this one in another language like C for example. As it's a common algorithm problem, you can let copilot complete this one for 4 to 5 line to show how precise can be the tools and when you reach the limit to generate something usable*

## Code Documentation 

*Copilot can understand a natural language prompt and generate code and because it's just language to it, it can also `understand code and explain it in natural language` to help you document your code.*

## Code Translation

*Copilot can understand and generate natural languages and code language in both way so by combining everything you can use it to `translate code pieces from a language to another one`*

Try

## Code completion

- Add a new property to the `Album` class

## Documentation

- Add a new section to the `README.md` file to explain how to deploy the application to Azure

## Comments

- Add a new comment to the `AlbumController` class to explain what it does

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
