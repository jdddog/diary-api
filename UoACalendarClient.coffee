http = require "http"

class UoACalendarClient

  ###*
  * The default host used by the client as authentication server if no `host` variable is specified during
  * UoACalendarClient instantiation.
  *
  * @name UoACalendarClient#DEFAULT_HOST
  * @type string
  * @default sitcalprd01.its.auckland.ac.nz
  ###

  DEFAULT_HOST: 'sitcalprd01.its.auckland.ac.nz'

  ###*
  * The default TCP port used by the client if no `port` variable is specified during UoACalendarClient instantiation.
  *
  * @name UoACalendarClient#DEFAULT_PORT
  * @type number
  * @default 345
  ###

  DEFAULT_PORT: 345

  ###*
  * This class allows you to interact with the calendar backend for creating, retrieving and modifying calendar and
  * event objects. To initialize the library you need to call the constructor, which takes as input a configuration object
  * that can contain one or more of the following fields.
  *
  * @class
  * @param {string} apiToken - Sets the user's API token used for authentication purposes.
  * @param {string=} host - Authentication server to which the client will connect. Should *NOT* include the URL schema as it defaults to `http`. Defaults to `DEFAULT_HOST`.
  * @param {number=} port - TCP port from the host to which the client will connect. Defaults to `DEFAULT_PORT`.
  * @alias UoACalendarClient
  *
  * @example <caption>Minimal example of how to instantiate a UoACalendarClient. Default host and port used.</caption>
  * var client = new UoACalendarClient("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJvcmlnX2lhdCI6MTQyMjQ5ODk0OSwiZXhwIjoxNDI" +
  *                                     "yNDk5MjQ5LCJ1c2VyX2lkIjoyLCJ1c2VybmFtZSI6ImRldmVsb3BlciIsImVtYWlsIjoidGVzdEBhdWN" +
  *                                     "rbGFuZC5hYy5ueiJ9.7jLkEBovT2HvT2noL4xdIhddaY8wpZpEVYEDHnnNm1Y");
  *
  * @example <caption>Example where host and port specified.</caption>
  * var client = new UoACalendarClient("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJvcmlnX2lhdCI6MTQyMjQ5ODk0OSwiZXhwIjoxNDI" +
  *                                     "yNDk5MjQ5LCJ1c2VyX2lkIjoyLCJ1c2VybmFtZSI6ImRldmVsb3BlciIsImVtYWlsIjoidGVzdEBhdWN" +
  *                                     "rbGFuZC5hYy5ueiJ9.7jLkEBovT2HvT2noL4xdIhddaY8wpZpEVYEDHnnNm1Y",
  *                                     "sitcalprd01.its.auckland.ac.nz", 345);
  ###

  constructor: (apiToken, host, port) ->
    if apiToken?
      @apiToken = apiToken
    else
      console.error('UoACalendarClient constructor: please specify an apiToken')

    if host?
      @host = host
    else
      @host = @DEFAULT_HOST

    if port?
      @port = port
    else
      @port = @DEFAULT_PORT


  ###*
  * Return host used by UoACalendarClient instance.
  *
  * @returns {string}
  *
  * @example
  * var host = client.getHost();
  ###

  getHost: () ->
    return @host

  ###*
  * Return port used by UoACalendarClient instance.
  *
  * @returns {number}
  *
  * @example
  * var host = client.getPort();
  ###

  getPort: () ->
    return @port

  ###*
  * Return apiToken used by UoACalendarClient instance.
  *
  * @returns {string}
  *
  * @example
  * var apiToken = client.getApiToken();
  ###

  getApiToken: () ->
    return @apiToken

  ###*
  * Sends http request to calendar backend
  *
  * @param {string} path
  * @param {string} method
  * @param {string} data
  * @param {string} onSuccess
  * @param {string} onError
  * @private
  ###

  sendRequest: (path, method, data, resolve, reject) ->
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
        if (('' + res.statusCode).match(/^2\d\d$/)) # Request handled, happy
          parsed = {}
          if data.length != 0
            parsed = JSON.parse(data)

          if parsed.constructor is Array
            for k,v of parsed
              if v.hasOwnProperty('start')
                v.start = new Date(v.start)

              if v.hasOwnProperty('end')
                v.end = new Date(v.end)

              if v.hasOwnProperty('lastUpdate')
                v.lastUpdate = new Date(v.lastUpdate)
          else
            if parsed.hasOwnProperty('start')
              parsed.start = new Date(parsed.start)

            if parsed.hasOwnProperty('end')
              parsed.end = new Date(parsed.end)

            if parsed.hasOwnProperty('lastUpdate')
              parsed.lastUpdate = new Date(parsed.lastUpdate)

          resolve({res: res, data: parsed})
        else
          # Server error, I have no idea what happend in the backend
          # but server at least returned correctly (in a HTTP protocol
          # sense) formatted response
          reject({res: res, data: data})
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
  * @param {onListCalendarsSuccess} onSuccess - Success callback function
  * @param {onListCalendarsError} onError - Error callback function
  * @example
  * client.listCalendars(
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  listCalendars: () ->
      action = (resolve, reject) -> @sendRequest('/calendars/', 'GET', 0, resolve, reject)
      new Promise(action.bind(@))

  ###*
  * Callback, returns an array of calendars.
  *
  * @callback onListCalendarsSuccess
  * @param {HttpResponse} res - HTTP response object.
  * @param {ErrorMessage} data - An array of calendar JSON objects, with name and id key value pairs.
  *
  * @example <caption>Example output</caption>
  * res: {"offset":5216,"readable":true,"_events":{},"statusCode":200,"headers":{"content-type":"application/json"}}
  * data: [{"name":"Public holidays","id":1},{"name":"CompSci exam dates","id":2},{"name":"Movie release dates","id":3}]
  ###

  ###*
  * Callback function, executed when adding calendar failed.
  *
  * @callback onListCalendarsError
  * @param {HttpResponse} res - HTTP response
  * @param {ErrorMessage} data - Error message.
  *
  * @example <caption>Example output</caption>
  * todo: insert example
  ###

  ###*
  * Retrieve a particular calendar
  * @param {number} id - id of the calendar
  * @param {onGetCalendarSuccess} onSuccess - Success callback function
  * @param {onGetCalendarError} onError - Error callback function
  * @example
  * var calendarId = 1;
  * client.getCalendar(calendarId,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  getCalendar: (id) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + id + '/', 'GET', 0, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Callback, returns particular calendar including its name and id. TODO: return custom fields here.
  *
  * @callback onGetCalendarSuccess
  * @param {HttpResponse} res - HTTP response
  * @param {Object.<{name: string, id: number}>} data - calendar with name and id
  *
  * @example <caption>Example output</caption>
  * res: {"offset":5216,"readable":true,"_events":{},"statusCode":200,"headers":{"content-type":"application/json"}}
  * data: {"name":"My Calendar","id":84}
  ###

  ###*
  * @callback onGetCalendarError
  * @param {HttpResponse} res - HTTP response
  * @param {ErrorMessage} data - detail of what went wrong
  *
  * @example <caption>Item doesn't exist</caption>
  * res: {"offset":22,"readable":true,"_events":{},"statusCode":404,"headers":{"content-type":"application/json"}}
  * data: {detail: "Not found"}
  *
  * @example <caption>No permission to access item</caption>
  * res: {"offset":63,"readable":true,"_events":{},"statusCode":403,"headers":{"content-type":"application/json"}}
  * data: {detail: "You do not have permission to perform this action."}
  ###

  ###*
  * Add a new calendar providing the new calendar's name
  * @param {string} name - Name of calendar
  * @param {onAddCalendarSuccess} onSuccess - Success callback function
  * @param {onAddCalendarError} onError - Error callback function
  *
  * @example
  * var name = "My calendar";
  * client.addCalendar(name,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  addCalendar: (name) ->
    action = (resolve, reject) -> @sendRequest('/calendars/', 'POST', {name: name}, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Callback function, executed when calendar successfully added.
  *
  * @callback onAddCalendarSuccess
  * @param {HttpResponse} res - HTTP response
  * @param {Array.<{name: string, id: number}>} data - An array of calendar JSON objects, with name and id key value pairs.
  *
  * @example <caption>Example output</caption>
  * res: {"offset":26,"readable":true,"_events":{},"statusCode":201,"headers":{"content-type":"application/json"}}
  * data: {"name":"My calendar","id":194}
  ###

  ###*
  * Callback function, executed when adding calendar failed.
  *
  * @callback onAddCalendarError
  * @param {HttpResponse} res - HTTP response.
  * @param {ErrorMessage} data - Error message.
  *
  * @example <caption>Example output</caption>
  * todo: insert example
  ###

  ###*
  * Delete an existing calendar given its id
  * @param {number} id - id of calendar
  * @param {onDeleteCalendarSuccess} onSuccess - Success callback function
  * @param {onDeleteCalendarError} onError - Error callback function
  *
  * @example
  * var calendarId = 1;
  * client.deleteCalendar(calendarId,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  deleteCalendar: (id) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + id + '/', 'DELETE', {}, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Callback, executed when calendar successfully deleted.
  *
  * @callback onDeleteCalendarSuccess
  * @param {HttpResponse} res - HTTP response
  * @param {Object.<{}>} data - Empty JSON object
  *
  * @example <caption>Example output</caption>
  * res: {"offset":0,"readable":true,"_events":{},"statusCode":204,"headers":{"content-type":"text/plain; charset=UTF-8"}}
  * data: {}
  ###

  ###*
  * Callback function, executed when delete calendar failed.
  *
  * @callback onDeleteCalendarError
  * @param {HttpResponse} res - HTTP response
  * @param {ErrorMessage} data - Error message.
  *
  * @example <caption>Example output</caption>
  * todo: insert example
  ###

  ###*
  * Retrieve the full list of events of an existing calendar given its id
  * @param {number} calendarId - Id of calendar
  * @param {onListEventsSuccess} onSuccess - Success callback function
  * @param {onListEventsError} onError - Error callback function
  *
  * @example
  * var calendarId = 1;
  * client.listEvents(calendarId,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  listEvents: (calendarId) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/events/', 'GET', 0, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Callback, executed when list events successful, data parameter contains list of events.
  *
  * @callback onListEventsSuccess
  * @param {HttpResponse} res - HTTP response
  * @param {Array.<{id:number, title: string, description: string, start: string, end: string, allDay: boolean, url: string, status: string, reminder: string, todo: boolean, location: string, summary: string, lastUpdate: string}>} data - An array of events
  *
  * @example <caption>Example output</caption>
  * res: {"offset":2,"readable":true,"_events":{},"statusCode":200,"headers":{"content-type":"application/json"}}
  * data: [{"id":3,"title":"The Force Awakens","description":"","start":"2014-12-18T21:40:00Z","end":"2014-12-18T22:00:00Z",
  *   "allDay":false,"url":"http://www.starwars.com/the-force-awakens/trailers/","status":null,"reminder":null,
  *   "todo":false,"location":null,"summary":null,"lastUpdate":"2014-12-16T21:26:04Z"},
  *  {"id":5,"title":"HoloLens","description":"","start":"2014-12-17T04:00:00Z","end":"2014-12-17T05:00:00Z",
  *   "allDay":false,"url":"http://www.microsoft.com/microsoft-hololens/en-us","status":null,"reminder":null,
  *   "todo":false,"location":null,"summary":null,"lastUpdate":"2014-12-18T20:54:58Z"}]
  ###

  ###*
  * Callback function, executed when list events failed.
  *
  * @callback onListEventsError
  * @param {HttpResponse} res - HTTP response
  * @param {ErrorMessage} data - Error message.
  *
  * @example <caption>Example output</caption>
  * todo: insert example
  ###

  ###*
  * Add an event to a particular calendar. Your own data fields can be added to the JSON event object, for
  * example, if you wanted to add an 'exercise' type to an event do the following: {"title": "My calendar", "exercise": "Run"}
  *
  * @param {number} calendarId - Id of calendar
  * @param {Object} event - Event JSON object
  * @param {string} event.title - Event title
  * @param {string=} event.description - Event description
  * @param {string=} event.location - Event location
  * @param {string=} event.summary - Event summary
  * @param {Date} event.start - Event start date & time
  * @param {Date=} event.end - Event end date & time
  * @param {string=} event.status - Event status
  * @param {string=} event.reminder - Event reminder
  * @param {boolean=} event.todo - Whether event still to be done
  * @param {boolean=} event.allDay - Whether event occurs all day
  * @param {string=} event.url - Event url
  * @param {onAddEventSuccess} onSuccess - Success callback function
  * @param {onAddEventError} onError - Error callback function
  *
  * @example <caption>Minimal example of how to add an event to a calendar, only title is mandatory.</caption>
  * var calendarId = 1;
  * var event = {"title": "Auckland Marathon", "start": new Date(2016, 11, 1, 6, 0, 0)};
  * client.addEvent(calendarId, event,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  *
  * @example <caption>Complete example of how to add an event to a calendar.</caption>
  * var calendarId = 1;
  * var event = {"title": "Auckland Marathon", "description": "Running marathon today",
  *              "location": "King Edward Parade, Devonport", "summary": "Marathon",
  *              "start": new Date(2016, 11, 1, 6, 0, 0), "end": new Date(2016, 11, 1, 8, 30, 0),
  *              "status": "active", "todo": true, "addDay": false, "url": "https://www.aucklandmarathon.co.nz/"};
  * client.addEvent(calendarId, event,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  *
  * @example <caption>Example of adding an event with a custom data field. The data field 'exercise' is custom.</caption>
  * var calendarId = 1;
  * var event = {"title": "Auckland Marathon", "start": new Date(2016, 11, 1, 6, 0, 0), "exercise": "run"};
  * client.addEvent(calendarId, event,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  addEvent: (calendarId, event) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/events/', 'POST', event, resolve, reject)
    new Promise(action.bind(@))

  addEvents: (calendarId, events) ->
    action = (resolve, reject) ->
      numEvents = events.length
      count = 0
      i = 0
      while i < numEvents
        @addEvent(calendarId, events[i])
        .then (args) ->
          count++
          if count >= numEvents
            resolve()
        , (err) ->
          count++
          if count >= numEvents
            reject()
        i++
      return
    new Promise(action.bind(@))

  ###*
  * Callback, executed when event added successfully.
  *
  * @callback onAddEventSuccess
  * @param {HttpResponse} res - HTTP response
  * @param {Object.<{id:number, title: string, description: string, start: string, end: string, allDay: boolean, url: string, status: string, reminder: string, todo: boolean, location: string, summary: string, lastUpdate: string}>} data - JSON object with event id
  *
  * @example <caption>Example output</caption>
  * res: {"offset":243,"readable":true,"_events":{},"statusCode":201,"headers":{"content-type":"application/json"}}
  * data: {"id":2699,"title":"cool event","description":null,"start":"2015-11-17T23:49:18.747000Z","end":null,
  *        "allDay":false,"url":null,"status":null,"reminder":null,"todo":false,"location":null,"summary":null,
  *        "lastUpdate":"2015-11-17T23:49:18.899897Z"}
  ###

  ###*
  * Callback function, executed when adding an event failed.
  *
  * @callback onAddEventError
  * @param {HttpResponse} res - HTTP response
  * @param {ErrorMessage} data - Error message.
  *
  * @example <caption>Example output when title and start date not specified</caption>
  * res: {"offset":73,"readable":true,"_events":{},"statusCode":400,"headers":{"content-type":"application/json"}}
  * data: {"title":"This field is required.", "start":"This field is required."} todo: remove arrays from
  *
  * @example <caption>Example output when calendar doesn't exist</caption>
  * res: {"offset":73,"readable":true,"_events":{},"statusCode":400,"headers":{"content-type":"application/json"}}
  * data: {detail: "Calendar with id -1 doesn't exist"} todo: chang error message
  *
  * @example <caption>Example where date has wrong format</caption>
  * res: {"offset":122,"readable":true,"_events":{},"statusCode":400,"headers":{"content-type":"application/json"}}
  * data: {"start":"Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]"}
  ###

  #add event success
  #{"offset":37,"readable":true,"_events":{},"statusCode":400,"headers":{"content-type":"application/json"}}
  #"{\"start\":[\"This field is required.\"]}"

  ###*
  * Delete an existing event from a calendar giving their ids
  *
  * @param {number} calendarId - id of calendar
  * @param {number} eventId - id of event
  * @param {onDeleteEventSuccess} onSuccess - Success callback function
  * @param {onDeleteEventError} onError - Error callback function
  *
  * @example
  * var calendarId = 1;
  * var eventId = 2;
  * client.deleteEvent(calendarId, eventId,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  deleteEvent: (calendarId, eventId) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/events/' + eventId + '/', 'DELETE', 0, resolve, reject)
    new Promise(action.bind(@))

  deleteEvents: (calendarId, eventIds) ->
    action = (resolve, reject) ->
      numEvents = eventIds.length
      count = 0
      i = 0
      while i < numEvents
        eventId = eventIds[i]
        @deleteEvent(calendarId, eventId)
        .then (args) ->
          count++
          if count >= numEvents
            resolve()
        , (err) ->
          count++
          if count >= numEvents
            reject()
        i++
      return
    new Promise(action.bind(@))

  ###*
  * Callback, executed when event successfully deleted.
  *
  * @callback onDeleteEventSuccess
  * @param {HttpResponse} res - HTTP response
  * @param {Array} data - empty array
  *
  * @example <caption>Example output</caption>
  * res: {"offset":2,"readable":true,"_events":{},"statusCode":200,"headers":{"content-type":"application/json"}}
  * data: []
  ###

  ###*
  * Callback function, executed when deleting an event failed.
  *
  * @callback onDeleteEventError
  * @param {HttpResponse} res - HTTP response
  * @param {ErrorMessage} data - Error message.
  *
  * @example <caption>Example output</caption>
  * todo: insert example
  ###


  ###*
  *  Update an existing event from a calendar giving their IDs
  *
  * @param {number} calendarId - id of calendar
  * @param {number} eventId - id of event
  * @param {Object} event - Event JSON object
  * @param {string} event.title - Event title
  * @param {string=} event.description - Event description
  * @param {string=} event.location - Event location
  * @param {string=} event.summary - Event summary
  * @param {Date} event.start - Event start date & time
  * @param {Date=} event.end - Event end date & time
  * @param {string=} event.status - Event status
  * @param {string=} event.reminder - Event reminder
  * @param {boolean=} event.todo - Whether event still to be done
  * @param {boolean=} event.allDay - Whether event occurs all day
  * @param {string=} event.url - Event url
  * @param {onUpdateEventSuccess} onSuccess - Success callback function
  * @param {onUpdateEventError} onError - Error callback function
  *
  * @example
  * var calendarId = 1;
  * var eventId = 2;
  * var event = {"title": "Auckland Marathon", "description": "Running the marathon now!"};
  * client.updateEvent(calendarId, eventId, event,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  updateEvent: (calendarId, eventId, event) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/events/' + eventId + '/', 'PATCH', event, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Callback, when event updated.
  *
  * @callback onUpdateEventSuccess
  * @param {HttpResponse} res - HTTP response
  * @param {Array.<{}>} data - ?
  *
  * @example <caption>Example output</caption>
  * res: {"offset":0,"readable":true,"_events":{},"statusCode":204,"headers":{"content-type":"text/plain; charset=UTF-8"}}
  * data: [{},
  *        {}]
  ###

  ###*
  * Callback function, executed event update failed.
  *
  * @callback onUpdateEventError
  * @param {HttpResponse} res - HTTP response
  * @param {ErrorMessage} data - Error message.
  *
  * @example <caption>Example output</caption>
  * todo: insert example
  ###

  ###*
  *  Find events from an existing calendar within a given time range
  *
  * @param {number} calendarId - id of calendar
  * @param {Date} startDate - date to begin searching
  * @param {Date} endDate - date to stop searching
  * @param {onFindEventsSuccess} onSuccess - Success callback function
  * @param {onFindEventsError} onError - Error callback function
  *
  * @example <caption>Find all events in calendar 1 between the day star wars first screened and now.</caption>
  * var calendarId = 1;
  * var startDate = new Date(1977, 5, 25); //date star wars first screened!
  * var endDate = new Date(); //current date and time
  * client.findEvents(calendarId, startDate, endDate,
  *   function(res, data) // onSuccess callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   },
  *   function(res, data) // onError callback
  *   {
  *     console.log(res);
  *     console.log(data);
  *   }
  * );
  ###

  findEvents: (calendarId, startDate, endDate) ->
    toUTCString = (date) ->
      return (new Date(date.getTime() + date.getTimezoneOffset() * 60000)).toISOString()

    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/find_events/', 'GET',
      {startDate: toUTCString(startDate), endDate: toUTCString(endDate)}, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Callback, returns events from a particular calendar within a date range.
  *
  * @callback onFindEventsSuccess
  * @param {HttpResponse} res - HTTP response
  * @param {Array.<{}>} data - Array of events
  *
  * @example <caption>Example output</caption>
  * res: {"offset":0,"readable":true,"_events":{},"statusCode":204,"headers":{"content-type":"text/plain; charset=UTF-8"}}
  * data: [{},
  *        {}]
  ###

  ###*
  * Callback function, executed when finding events failed.
  *
  * @callback onFindEventsError
  * @param {HttpResponse} res - HTTP response
  * @param {ErrorMessage} data - Error message.
  *
  * @example <caption>Example output</caption>
  * todo: insert example
  ###

  ###*
  * @typedef {Object} HttpResponse
  * @property {number} offset -
  * @property {boolean} readable -
  * @property {number} statusCode - See [HTTP status codes]{@link https://en.wikipedia.org/wiki/List_of_HTTP_status_codes}
  * @property {Object} headers -
  * @property {string} headers.content-type -
  *
  * @example
  * {"offset":30,"readable":true,"_events":{},"statusCode":200,"headers":{"content-type":"application/json"}}
  ###

  ###*
  *
  * @typedef {Object} ErrorMessage
  * @property {string} detail - Reason for error.
  *
  * @example
  * {detail: "You do not have permission to perform this action."}
  ###

exports.UoACalendarClient = UoACalendarClient

module.exports = (apiToken, host, port) ->
  return new UoACalendarClient(apiToken, host, port)
