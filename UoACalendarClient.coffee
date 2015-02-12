# uoacalendar-js
# ============================================

http = require "http"

# The UoACalendarClient class
# ----------------
#
# This class provides with all the necessary functionality to
# interact with the calendar backend for creating, retrieving
# and modifying calendar and event objects.
#
class UoACalendarClient

    # Client settings
    # ----------------

    # `DEFAULT_HOST` specifies the default host used by the
    # client as authentication server if no `host` configuration
    # is specified during the library initialization. By default,
    # the host points to the Gipsy-Danger API web server.
    #
    DEFAULT_HOST : 'sitcalprd01.its.auckland.ac.nz'

    # `DEFAULT_PORT` specifies the default TCP port in the
    # authentication server used by the client if no `port` configuration
    # is specified during the library initialization.
    #
    DEFAULT_PORT : 80

    # Initializing the client library
    # ----------------------------------------------------
    #
    # To initialize the library you need to call the constructor,
    # method, which takes as input a configuration object that
    # can contain zero or more of the following fields:
    #
    # |Name|Value|Description|
    # |----|-----|-----------|
    # |`apiToken`|`String`|Sets the user's API token used for authentication pruposes. Required.|
    # |`host`|`String`|Authentication server to which the client will connect. Should *NOT* include the URL schema as it defaults to `http`. Defaults to `DEFAULT_HOST`.|
    # |`port`|TCP port number|TCP port from the host to which the client will connect. Defaults to `DEFAULT_PORT`|
    #
    #
    # Example of initialization from a JavaScript client:
    #
    # ```javascript
    # var client = new UoACalendarClient({ apiToken: "<YOUR_API_TOKEN>"} );
    # ```
    #
    # Your API token can be retrieved from the server as follows:
    #
    # ```bash
    # $ curl -X POST -d "username=$USERNAME&password=$PASSWORD" http://sitcalprd01.its.auckland.ac.nz:8000/api-token-auth
    # {"token":"<YOUR_API_TOKEN>"}
    # ```
    #
    # Specific host and port values can also be provided:
    #
    # ```javascript
    # var client = UoACalendarClient({ host: "example.org", port: 80, apiToken: "<YOUR_API_TOKEN>"});
    # ```
    #
    constructor: (config) ->
        { @host, @port, @apiToken } = config if config?
        @host       ?= @DEFAULT_HOST
        @port       ?= @DEFAULT_PORT


    # Accessing the client settings
    # ----------------------------------------------------

    # By calling `getHost()` the caller can retrieve the
    # configured `host` used by the library
    #
    # ```javascript
    # var host = client.getHost();
    # ```
    #
    getHost: () ->
      return @host

    # By calling `getPort()` the caller can retrieve the
    # configured `host` used by the library
    #
    # ```javascript
    # var port = client.getPort();
    # ```
    #
    getPort: () ->
      return @port

    # By calling `getApiToken()` the caller can retrieve the
    # API token that the client uses for authenticating
    #
    # ```javascript
    # var apiToken = client.getApiToken();
    # ```
    #
    getApiToken: () ->
      return @apiToken

    #
    # Interacting with the backend
    # ----------------------------------------------------
    #

    # Generic method for sending a request to the calendar backend
    #
    sendRequest : (path, method, data, onSuccess, onError) ->

        getCookie = (name) ->
            nameEQ = name + "="
            ca = document.cookie.split(";")
            i = 0
            while i < ca.length
                c = ca[i]
                c = c.substring(1, c.length)  while c.charAt(0) is " "
                return c.substring(nameEQ.length, c.length).replace(/"/g, '')  if c.indexOf(nameEQ) is 0
                i++
            ca

        getHeaders = () =>
            if @apiToken
                return {
                      'Content-Type': 'application/json'
                      'Authorization': 'JWT ' + @apiToken
                } 
            else
                return {
                      'Content-Type': 'application/json'
                      'X-CSRFToken': getCookie('csrftoken')
                } 

        makeRequest = (path, method, data) =>
            return {
                host: @host
                port: @port
                headers: getHeaders()
                path: path
                method: method
                withCredentials: false
            }

        req = http.request(makeRequest(path, method, data), (res) ->
                data = ''
                res.on('data', (chunk) ->
                    data += chunk
                )
                res.on('end', () ->
                    if (('' + res.statusCode).match(/^2\d\d$/))
                        # Request handled, happy
                        if onSuccess then onSuccess(res, if data.length!=0 then JSON.parse(data) else {})
                    else
                        # Server error, I have no idea what happend in the backend
                        # but server at least returned correctly (in a HTTP protocol
                        # sense) formatted response
                        if onError then onError(res, data) else console.error(res)
                )
            )

        req.on('error', (e) -> console.error(e))

        req.on('timeout', () -> req.abort())

        if data
            req.write(JSON.stringify(data))

        # Send request
        req.end()

    #
    # Calendar objects management
    # ===========================
    #

    # Retrieve my full list of calendars
    #
    # ```javascript
    # client.listCalendars(
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized calendars dictionary
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    listCalendars : (onSuccess, onError) ->
        @sendRequest('/calendars/', 'GET', 0, onSuccess, onError)

    # Retrieve my full list of calendars
    #
    # ```javascript
    # client.getCalendar(calendarId
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized calendar data
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    getCalendar : (id, onSuccess, onError) ->
        @sendRequest('/calendars/' + id + '/', 'GET', 0, onSuccess, onError)

    # Add a new calendar providing the new calendar's name
    #
    # ```javascript
    # client.addCalendar("Your Calendar Name",
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized new calendar data
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    addCalendar: (name, onSuccess, onError) ->
        @sendRequest('/calendars/', 'POST', {name: name}, onSuccess, onError)

    # Delete an existing calendar given its ID
    #
    # ```javascript
    # client.deleteCalendar(calendarId,
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized response data
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    deleteCalendar: (id, onSuccess, onError) ->
        @sendRequest('/calendars/' + id + '/', 'DELETE', {}, onSuccess, onError)

    #
    # Event objects management
    # ===========================
    #

    # Retrieve the full list of events of an existing calendar given its ID
    #
    # ```javascript
    # client.listEvents(calendarId,
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized events dictionary
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    listEvents: (calendarId, onSuccess, onError) ->
        @sendRequest('/calendars/' + calendarId + '/events/', 'GET', 0, onSuccess, onError)

    # Add a new event to an existing calendar given its ID
    #
    # ```javascript
    # client.listEvents(calendarId, { title: "Event Title", ... }
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized new event object data
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    addEvent: (calendarId, event, onSuccess, onError) ->
        @sendRequest('/calendars/' + calendarId + '/events/', 'POST', event, onSuccess, onError)

    # Delete an existing event from a calendar giving their IDs
    #
    # ```javascript
    # client.deleteEvent(calendarId, eventId,
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized response data
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    deleteEvent: (calendarId, eventId, onSuccess, onError) ->
        @sendRequest('/calendars/' + calendarId + '/events/' + eventId + '/', 'DELETE', 0, onSuccess, onError)

    # Update an existing event from a calendar giving their IDs
    #
    # ```javascript
    # client.updateEvent(calendarId, eventId, { title: "Event Title", ... }
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized updated event object data
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    updateEvent: (calendarId, eventId, event, onSuccess, onError) ->
        @sendRequest('/calendars/' + calendarId + '/events/' + eventId + '/', 'PATCH', event, onSuccess, onError)

    # Find events from an existing calendar within a given time range
    #
    # ```javascript
    # client.updateEvent(calendarId, new Date(1977, 5, 25), Date.now(),
    #   // onSuccess callback
    #   function(res, data) {
    #       // response
    #       console.log(res);
    #       // deserialized events dictionary
    #       console.log(data);
    #   },
    #   // onError callback
    #   function(res, data) {
    #       ...
    #   }
    # );
    # ```
    #
    findEvents: (calendarId, startDate, endDate, onSuccess, onError) ->
        toUTCString = (date) ->
            return (new Date(date.getTime() + date.getTimezoneOffset() * 60000)).toISOString()

        @sendRequest('/calendars/' + calendarId + '/find_events/', 'GET',
            {startDate: toUTCString(startDate), endDate: toUTCString(endDate)},
            onSuccess, onError
            )

exports.UoACalendarClient = UoACalendarClient

module.exports = (config) ->
     return new UoACalendarClient(config)
