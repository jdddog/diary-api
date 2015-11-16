http = require "http"

class UoACalendarClient

  ###*
  * The default host used by the client as authentication server if no `host` variable is specified during
  * UoACalendarClient instantiation.
  *
  * @name UoACalendarClient#DEFAULT_HOST
  * @type String
  * @default sitcalprd01.its.auckland.ac.nz
  ###

  DEFAULT_HOST: 'sitcalprd01.its.auckland.ac.nz'

  ###*
  * The default TCP port used by the client if no `port` variable is specified during UoACalendarClient instantiation.
  *
  * @name UoACalendarClient#DEFAULT_PORT
  * @type Number
  * @default 345
  ###

  DEFAULT_PORT: 345

  ###*
  * This class allows you to interact with the calendar backend for creating, retrieving and modifying calendar and
  * event objects. To initialize the library you need to call the constructor, which takes as input a configuration object
  * that can contain one or more of the following fields.
  *
  * @class
  * @param {String} apiToken - Sets the user's API token used for authentication purposes.
  * @param {String=} host - Authentication server to which the client will connect. Should *NOT* include the URL schema as it defaults to `http`. Defaults to `DEFAULT_HOST`.
  * @param {Number=} port - TCP port from the host to which the client will connect. Defaults to `DEFAULT_PORT`.
  * @alias UoACalendarClient
  ###

  constructor: (apiToken, host, port) ->
    { @host, @port, @apiToken } = config if config?
    @host ?= @DEFAULT_HOST
    @port ?= @DEFAULT_PORT

  ###*
  * Return host used by UoACalendarClient instance.
  *
  * @returns {String}
  ###

  getHost: () ->
    return @host

  ###*
  * Return port used by UoACalendarClient instance.
  *
  * @returns {Number}
  ###

  getPort: () ->
    return @port

  ###*
  * Return apiToken used by UoACalendarClient instance.
  *
  * @returns {string}
  ###

  getApiToken: () ->
    return @apiToken

  ###*
  * Sends http request to calendar backend
  *
  * @param {String} path
  * @param {String} method
  * @param {String} data
  * @param {String} onSuccess
  * @param {String} onError
  * @private
  ###

  sendRequest: (path, method, data, onSuccess, onError) ->
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
        'Accept': 'application/json'
        'Content-Type': 'application/json'
        'Authorization': 'JWT ' + @apiToken
        }
      else
        return {
        'Accept': 'application/json'
        'Content-Type': 'application/json'
        'X-CSRFToken': getCookie('csrftoken')
        }

    makeRequest = (path, method, data) =>
      return {
      host: @host
      port: @port
      scheme: 'http'
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
          if onSuccess then onSuccess(res, if data.length != 0 then JSON.parse(data) else {})
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

  ###*
  * Retrieve full list of calendars
  *
  * @param {UoACalendarClient~listCalendarsSuccess} onSuccess - Success callback function
  * @param {UoACalendarClient~listCalendarsError} onError - Error callback function
  ###

  listCalendars: (onSuccess, onError) ->
    @sendRequest('/calendars/', 'GET', 0, onSuccess, onError)

  ###*
  * @callback UoACalendarClient~listCalendarsSuccess
  * @param {res} Response
  * @param {data} Deserialized data
  ###

  ###*
  * @callback UoACalendarClient~listCalendarsError
  * @param {res} Response
  * @param {data} ?
  ###

  ###*
  * Retrieve a particular calendar
  * @param {Number} id - id of the calendar
  * @param {UoACalendarClient~getCalendarSuccess} onSuccess - Success callback function
  * @param {UoACalendarClient~getCalendarError} onError - Error callback function
  ###

  getCalendar: (id, onSuccess, onError) ->
    @sendRequest('/calendars/' + id + '/', 'GET', 0, onSuccess, onError)

  ###*
  * @callback UoACalendarClient~getCalendarSuccess
  * @param {res} Response
  * @param {data} Deserialized data
  ###

  ###*
  * @callback UoACalendarClient~getCalendarError
  * @param {res} Response
  * @param {data} ?
  ###

  ###*
  * Add a new calendar providing the new calendar's name
  * @param {String} name - Name of calendar
  * @param {UoACalendarClient~addCalendarSuccess} onSuccess - Success callback function
  * @param {UoACalendarClient~addCalendarError} onError - Error callback function
  ###

  addCalendar: (name, onSuccess, onError) ->
    @sendRequest('/calendars/', 'POST', {name: name}, onSuccess, onError)

  ###*
  * @callback UoACalendarClient~addCalendarSuccess
  * @param {res} Response
  * @param {data} Deserialized data
  ###

  ###*
  * @callback UoACalendarClient~addCalendarError
  * @param {res} Response
  * @param {data} ?
  ###

  ###*
  * Delete an existing calendar given its id
  * @param {Number} id - id of calendar
  * @param {UoACalendarClient~deleteCalendarSuccess} onSuccess - Success callback function
  * @param {UoACalendarClient~deleteCalendarError} onError - Error callback function
  ###

  deleteCalendar: (id, onSuccess, onError) ->
    @sendRequest('/calendars/' + id + '/', 'DELETE', {}, onSuccess, onError)

  ###*
  * @callback UoACalendarClient~deleteCalendarSuccess
  * @param {res} Response
  * @param {data} Deserialized data
  ###

  ###*
  * @callback UoACalendarClient~deleteCalendarError
  * @param {res} Response
  * @param {data} ?
  ###

  ###*
  * Retrieve the full list of events of an existing calendar given its id
  * @param {Number} calendarId - Id of calendar
  * @param {UoACalendarClient~listEventsSuccess} onSuccess - Success callback function
  * @param {UoACalendarClient~listEventsError} onError - Error callback function
  ###

  listEvents: (calendarId, onSuccess, onError) ->
    @sendRequest('/calendars/' + calendarId + '/events/', 'GET', 0, onSuccess, onError)

  ###*
  * @callback UoACalendarClient~listEventsSuccess
  * @param {res} Response
  * @param {data} Deserialized events dictionary
  ###

  ###*
  * @callback UoACalendarClient~listEventsError
  * @param {res} Response
  * @param {data} ?
  ###

  ###*
  * Add an event to a particular calendar. Your own data fields can be added to the JSON event object, for
  * example, if you wanted to add an 'exercise' type to an event do the following: {"title": "My calendar", "exercise": "Run"}
  *
  * @param {Number} calendarId - Id of calendar
  * @param {Object} event - Event JSON object
  * @param {String} event.title - Event title
  * @param {String=} event.description - Event description
  * @param {String=} event.location - Event location
  * @param {String=} event.summary - Event summary
  * @param {Date=} event.start - Event start date & time
  * @param {Date=} event.end - Event end date & time
  * @param {String=} event.status - Event status
  * @param {String=} event.reminder - Event reminder
  * @param {Boolean=} event.todo - Whether event still to be done
  * @param {Boolean=} event.allDay - Whether event occurs all day
  * @param {String=} event.url - Event url
  * @param {UoACalendarClient~addEventSuccess} onSuccess - Success callback function
  * @param {UoACalendarClient~addEventError} onError - Error callback function
  ###

  addEvent: (calendarId, event, onSuccess, onError) ->
    @sendRequest('/calendars/' + calendarId + '/events/', 'POST', event, onSuccess, onError)

  ###*
  * Event object
  *
  * @class Event
  ###

  ###*
  * @callback UoACalendarClient~addEventSuccess
  * @param {res} Response
  * @param {data} Deserialized events dictionary
  ###

  ###*
  * @callback UoACalendarClient~addEventError
  * @param {res} Response
  * @param {data} ?
  ###

  ###*
  * Delete an existing event from a calendar giving their ids
  *
  * @param {Number} calendarId - id of calendar
  * @param {Number} eventId - id of event
  * @param {UoACalendarClient~deleteEventSuccess} onSuccess - Success callback function
  * @param {UoACalendarClient~deleteEventError} onError - Error callback function
  ###

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
