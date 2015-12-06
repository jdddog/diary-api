# uoacalendar-js

This project contains the Javascript UoACalendar REST API client library.

## Documentation

The complete documentation for developing with uoacalendar-js is available on the [project website](http://uoa-compsci.github.io/uoacalendar-js/).

## Development

uoacalendar-js is implemented with [Coffeescript](http://coffeescript.org/), it has several dependencies which are used to manage the project and compile `UoACalendarClient.coffee` into a standalone browser library.

* [Node.js](https://nodejs.org/en/): npm is used to install dependencies.
* [browserify](http://browserify.org/): Used to compile `UoACalendarClient.coffee` into standalone browser JavaScript.
* [coffeeify](https://www.npmjs.com/package/coffeeify): Used to compile `UoACalendarClient.coffee` into standalone browser JavaScript.

The following instructions explain how to setup your development environment. [WebStorm](https://www.jetbrains.com/webstorm/) has been tested with uoacalendar-js, a file watcher is included in the project which compiles Coffeescript into JavaScript.

### Install Node.js

Download and install [Node.js](https://nodejs.org/en/). Once Node.js is installed you should be able to run the following from a terminal:

```bash
C:\Users\user>node -h
Usage: node [options] [ -e script | script.js ] [arguments]
...
```
If you get the following error restart your computer.

```bash
'C:\Users\user>node -h' is not recognized as an internal or external command,
operable program or batch file.
```

### Clone project
Open a terminal in the desired location and clone the uoacalendar-js project.

```bash
C:\Users\user> git clone https://github.com/UoA-CompSci/uoacalendar-js.git
```

### Download dependencies
In the uoacalendar-js folder run the following command to download the dependencies:

```bash
C:\Users\user\uoacalendar-js>npm install
```

### Compile Coffee into JavaScript

There are two ways to compile `UoACalendarClient.coffee` into JavaScript, in both cases the generated JavaScript file is saved to: `dist/uoacalendar.js`.

1) If using WebStorm, when UoACalendarClient.coffee is saved it is automatically converted into JavaScript via a file watcher. 

If you opened the project in WebStorm before running `npm install` then you will receive the following error: `An exception occurred while executing watcher 'Compile CoffeeScript'. Watcher has been disabled. Fix it.: Invalid exe`. In this case make sure you have installed the dependnencies with `npm install` and then re-enable the file watcher: File -> Settings -> Tools -> File Watchers -> Tick `Compile CoffeeScript`.

2) If not using WebStorm run the following command (this has only been tested on Linux).

```bash
$ make
```




