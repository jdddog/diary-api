# uoacalendar-js

This project contains the Javascript UoACalendar REST API client library.

## Setup

You may use [Bower](http://bower.io/) to install the library:

```bash
$ bower install uoacalendar-js
```

Then just include the script into your HTML code:

```html
<script src='bower_components/uoacalendar-js/dist/uoacalendar.js'></script>
```

## Obtain an API token

Before getting started you should obtain an API token, which can be retrieved using your UPI credentials:

```bash
$ curl -X POST -d "username=$USERNAME&password=$PASSWORD" http://diaryapi.auckland.ac.nz:8000/api-token-auth
{"token":"<YOUR_API_TOKEN>"}
```

Copy *JUST* the value of the token returned by the server. 

> Make sure you keep this token safe as it is used by the server to determine the user that sends the requests as means of authentication, so you don't want other users to mess up with your calendars, or do you?

## Interacting with the server

Now, in your Javascript code you may instantiate a client object:

```Javascript
var client = new UoACalendarClient({ apiToken: "<YOUR_API_TOKEN>"});
```

At this point you are ready to interact with the calendar backend.

Let's create our first calendar:

```Javascript
client.addCalendar("My Calendar", 
	// onSuccess callback
    function(res, data) {
    	// response
        console.log(res);
        // deserialized new calendar data
        // { name: "My Calendar", id: 1 }
        console.log(data);
    },
    // onError callback
    function(res, data) {
        ...
    }
);
```

> Note: All functions take `onSuccess` and `onError` callbacks as optional parameters, so you don't need to provide them if not needed.

Make sure you keep the calendar ID, as you'll need it to add new events to it:

 ```Javascript
client.addEvent(calendarId, { name: "Star Wars Release Date", ...} 
	// onSuccess callback
    function(res, data) {
    	// response
        console.log(res);
        // deserialized new event data
        // { name: "Star Wars Release Date", id: 1 }
        console.log(data);
    },
    // onError callback
    function(res, data) {
        ...
    }
);
```

Now you can query the events from your calendar from a specifc date range:

 ```Javascript
client.findEvents(calendarId, new Date(1977, 5, 25), Date.now(),
	// onSuccess callback
    function(res, data) {
    	// response
        console.log(res);
        // deserialized events dictionary
        // { name: "Star Wars Release Date", id: 1 }
        console.log(data);
    },
    // onError callback
    function(res, data) {
        ...
    }
);
```

> Note: You may find complete documentation of all available methods in `UoACalendarClient.coffee`

## Advanced requests

For the full list of the calendar API endpoints, please refer to the online documentation [here](http://diaryapi.auckland.ac.nz/docs).

If the client does not provide a method specific to the endpoint that you want to use, you can use the `sendRequest` method:

```Javascript
client.sendRequest('/resource/', 'POST', { myData: 1});
```

## Development

The client is implemented using [Coffeescript](http://coffeescript.org/) and compiled into an standalone browser library using [Browserify](http://browserify.org/).

To build a new version of the distributable library (`dist/uoacalendar.js`) run:

```bash
$ make
```


