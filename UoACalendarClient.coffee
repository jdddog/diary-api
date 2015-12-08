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

  DEFAULT_HOST: 'diaryapi.auckland.ac.nz'

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
  * @param {Object} data
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

          resolve(parsed)
        else
          # Server error, I have no idea what happend in the backend
          # but server at least returned correctly (in a HTTP protocol
          # sense) formatted response

          data.statusCode = res.statusCode;
          reject(data)
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
  * @returns {Promise.<Array.<{name: string, id: number}>, {statusCode: number, reason: Object}>} A promise that returns an array of calendar JSON objects with name and id key value pairs if resolved or an error if rejected.
  * @example <caption>Example code</caption>
  * client.listCalendars().then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Example output when calendars successfully received.</caption>
  * [{"name":"Public holidays","id":1},{"name":"CompSci exam dates","id":2},{"name":"Movie release dates","id":3}]
  *
  * @example <caption>Example output when an error has occurred.</caption>
  * [{"name":"asdasdasdasdasdasd","id":1}]
  ###

  listCalendars: () ->
      action = (resolve, reject) -> @sendRequest('/calendars/', 'GET', 0, resolve, reject)
      new Promise(action.bind(@))

  ###*
  * Retrieve a particular calendar. TODO: return custom fields here.
  * @param {number} id - id of the calendar
  * @returns {Promise.<Object.<{name: string, id: number}>, Object.<{statusCode: number, reason: Object}>>} A promise that returns calendar with name and id if resolved or an error if rejected.
  *
  * @example <caption>Example code</caption>
  * var calendarId = 1;
  * client.getCalendar(calendarId).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Example output when a calendar successfully retrieved.</caption>
  * {"name":"My Calendar","id":84}
  *
  * @example <caption>Example output when item doesn't exist.</caption>
  * {"statusCode":404, "detail": "Not found"}
  *
  * @example <caption>Example output when don't have permission to access item.</caption>
  * {"statusCode":403, "detail": "You do not have permission to perform this action."}

  ###

  getCalendar: (id) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + id + '/', 'GET', 0, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Add a new calendar providing the new calendar's name
  * @param {string} name - Name of calendar
  * @returns {Promise.<Object.<{name: string, id: number}>, Object.<{statusCode: number, reason: Object}>>} A promise that returns calendar with name and id if resolved or an error if rejected.
  *
  * @example <caption>Example code</caption>
  * var name = "My new calendar";
  * client.addCalendar(name).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Example output when calendar successfully added.</caption>
  * {"name":"My new calendar","id":194}
  *
  ###

  addCalendar: (name) ->
    action = (resolve, reject) -> @sendRequest('/calendars/', 'POST', {name: name}, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Delete an existing calendar given its id
  * @param {number} id - id of calendar
  * @returns {Promise.<Object, Object.<{statusCode: number, reason: Object}>>} A promise with an empty object if resolved or an error if rejected.
  *
  * @example <caption>Example code</caption>
  * var calendarId = 1;
  * client.deleteCalendar(calendarId).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Example output when calendar successfully deleted.</caption>
  * {}
  ###

  deleteCalendar: (id) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + id + '/', 'DELETE', {}, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Retrieve the full list of events of an existing calendar given its id
  * @param {number} calendarId - Id of calendar
  * @returns {Promise.<Array.<{id:number, title: string, description: string, start: Date, end: Date, allDay: boolean, url: string, status: string, reminder: string, todo: boolean, location: string, summary: string, lastUpdate: Date}>, Object.<{statusCode: number, reason: Object}>>} A promise that an array of events if resolved or an error if rejected.
  *
  * @example
  * var calendarId = 1;
  * client.listEvents(calendarId).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Example output when events successfully listed.</caption>
  * [{"id":3,"title":"The Force Awakens","description":"","start":"2014-12-18T21:40:00Z","end":"2014-12-18T22:00:00Z",
  *   "allDay":false,"url":"http://www.starwars.com/the-force-awakens/trailers/","status":null,"reminder":null,
  *   "todo":false,"location":null,"summary":null,"lastUpdate":"2014-12-16T21:26:04Z"},
  *  {"id":5,"title":"HoloLens","description":"","start":"2014-12-17T04:00:00Z","end":"2014-12-17T05:00:00Z",
  *   "allDay":false,"url":"http://www.microsoft.com/microsoft-hololens/en-us","status":null,"reminder":null,
  *   "todo":false,"location":null,"summary":null,"lastUpdate":"2014-12-18T20:54:58Z"}]
  ###

  listEvents: (calendarId) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/events/?format=json', 'GET', 0, resolve, reject)
    new Promise(action.bind(@))

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
  * @returns {Promise.<Object.<{id:number, title: string, description: string, start: Date, end: Date, allDay: boolean, url: string, status: string, reminder: Date, todo: boolean, location: string, summary: string, lastUpdate: string}>, Object.<{statusCode: number, title: string, start: string, detail: string}>>} A promise that contains an event if resolved or an error if rejected.
  *
  * @example <caption>Minimal example of how to add an event to a calendar, only title and start date are mandatory.</caption>
  * var calendarId = 1;
  * var event = {"title": "Auckland Marathon", "start": new Date(2016, 11, 1, 6, 0, 0)};
  * client.addEvent(calendarId, event).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Complete example of how to add an event to a calendar.</caption>
  * var calendarId = 1;
  * var event = {"title": "Auckland Marathon", "description": "Running marathon today",
  *              "location": "King Edward Parade, Devonport", "summary": "Marathon",
  *              "start": new Date(2016, 11, 1, 6, 0, 0), "end": new Date(2016, 11, 1, 8, 30, 0),
  *              "status": "active", "todo": true, "addDay": false, "url": "https://www.aucklandmarathon.co.nz/"};
  * client.addEvent(calendarId, event).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Example of adding an event with a custom data field. The data field 'exercise' is custom.</caption>
  * var calendarId = 1;
  * var event = {"title": "Auckland Marathon", "start": new Date(2016, 11, 1, 6, 0, 0), "exercise": "run"};
  * client.addEvent(calendarId, event).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Example output when event added successfully</caption>
  * {"id":2699,"title":"cool event","description":null,"start":"2015-11-17T23:49:18.747000Z","end":null,
  *     "allDay":false,"url":null,"status":null,"reminder":null,"todo":false,"location":null,"summary":null,
  *     "lastUpdate":"2015-11-17T23:49:18.899897Z"}
  *
  * @example <caption>Example output when title and start date not specified</caption>
  * {"statusCode":400, "title":"This field is required.", "start":"This field is required."} todo: remove arrays from
  *
  * @example <caption>Example output when calendar doesn't exist</caption>
  * {"statusCode":400, "detail": "Calendar with id -1 doesn't exist"} todo: chang error message
  *
  * @example <caption>Example output where date format wrong</caption>
  * {"statusCode":400, "start":"Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]"}
  ###

  addEvent: (calendarId, event) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/events/', 'POST', event, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Add multiple events to a calendar.
  * @param {number} calendarId - id of calendar
  * @param {Array.<{Event}>} eventIds - an array of numeric event ids
  * @returns {Promise.<Array.<Event>, Array.<{statusCode: number, detail: string}>>} A promise that contains an array of events objects if resolved or an array of errors if rejected.
  *
  * @example
  * var calendarId = 1;
  * var events = [{title: "Run", start: new Date(2013, 1, 1), end: new Date(2013, 1, 1)},
                  {title: "Eat", start: new Date(2015, 1, 1), end: new Date(2015, 1, 1)}];
  * client.addEvents(calendarId, events).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  ###

  addEvents: (calendarId, events) ->
    action = (resolve, reject) ->
      dataAddEvents = []
      errorAddEvents = []
      numEvents = events.length
      count = 0
      i = 0
      while i < numEvents
        @addEvent(calendarId, events[i])
        .then (data) ->
          dataAddEvents.push data
          count++
          if count >= numEvents
            resolve(dataAddEvents)
        , (error) ->
          errorAddEvents.push error
          count++
          if count >= numEvents
            reject(errorAddEvents)
        i++
      return
    new Promise(action.bind(@))

    ###*
  * Delete an existing event from a calendar giving their ids
  *
  * @param {number} calendarId - id of calendar
  * @param {number} eventId - id of event
  * @returns {Promise.<Array, Array.<{statusCode: number, detail: string}>>} A promise that contains an empty object if resolved or an error if rejected.
  *
  * @example
  * var calendarId = 1;
  * var eventId = 2;
  * client.deleteEvent(calendarId, eventId).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  *
  * @example <caption>Example output when event deleted successfully</caption>
  * {}
  ###

  deleteEvent: (calendarId, eventId) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/events/' + eventId + '/', 'DELETE', 0, resolve, reject)
    new Promise(action.bind(@))

  ###*
  * Delete multiple events from a calendar.
  * @param {number} calendarId - id of calendar
  * @param {number[]} eventIds - an array of numeric event ids
  * @returns {Promise.<Object, Object.<{statusCode: number, detail: string}>>} A promise that contains an array of empty objects if resolved or an array of errors if rejected.
  *
  * @example
  * var calendarId = 1;
  * var eventIds = [1,2,3,4];
  * client.deleteEvents(calendarId, eventIds).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  ###

  deleteEvents: (calendarId, eventIds) ->
    action = (resolve, reject) ->
      dataAddEvents = []
      errorAddEvents = []
      numEvents = eventIds.length
      count = 0
      i = 0
      while i < numEvents
        eventId = eventIds[i]
        @deleteEvent(calendarId, eventId)
        .then (data) ->
          dataAddEvents.push data
          count++
          if count >= numEvents
            resolve(dataAddEvents)
        , (error) ->
          errorAddEvents.push error
          count++
          if count >= numEvents
            reject(errorAddEvents)
        i++
      return
    new Promise(action.bind(@))

  ###*
  *  Update an existing event from a calendar given its id.
  *
  * @param {number} calendarId - id of calendar
  * @param {number} eventId - id of event
  * @param {Object} event - Event JSON object
  * @param {string} event.title - Event title
  * @param {string=} event.description - Event description
  * @param {string=} event.location - Event location
  * @param {string=} event.summary - Event summary
  * @param {Date} event.start - Event start date & time
  * @param {Date} event.end - Event end date & time
  * @param {string=} event.status - Event status
  * @param {string=} event.reminder - Event reminder
  * @param {boolean=} event.todo - Whether event still to be done
  * @param {boolean=} event.allDay - Whether event occurs all day
  * @param {string=} event.url - Event url
  * @returns {Promise.<Object.<{id:number, title: string, description: string, start: Date, end: Date, allDay: boolean, url: string, status: string, reminder: Date, todo: boolean, location: string, summary: string, lastUpdate: string}>, Object.<{statusCode: number, title: string, start: string, end: string, detail: string}>>} A promise that contains an event if resolved or an error if rejected.
  *
  * @example
  * var calendarId = 1;
  * var eventId = 2;
  * var event = {"title": "Auckland Marathon", "description": "Running the marathon now!"};
  * client.updateEvent(calendarId, eventId, event).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  ###

  updateEvent: (calendarId, eventId, event) ->
    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/events/' + eventId + '/', 'PATCH', event, resolve, reject)
    new Promise(action.bind(@))

  ###*
  *  Find events from an existing calendar within a given time range
  *
  * @param {number} calendarId - id of calendar
  * @param {Date} startDate - date to begin searching
  * @param {Date} endDate - date to stop searching
  * @returns {Promise.<Array.<{id:number, title: string, description: string, start: Date, end: Date, allDay: boolean, url: string, status: string, reminder: Date, todo: boolean, location: string, summary: string, lastUpdate: string}>, Object.<{statusCode: number, detail: string}>>} A promise that contains an array of events if resolved or an error if rejected.
  *
  * @example <caption>Find all events in calendar 1 between the day star wars first screened and now.</caption>
  * var calendarId = 1;
  * var startDate = new Date(1977, 5, 25); //date star wars first screened!
  * var endDate = new Date(); //current date and time
  * client.findEvents(calendarId, startDate, endDate).then(function(data){
  *     console.log(JSON.stringify(data));
  * }).catch(function(error){
  *     console.log(JSON.stringify(error));
  * });
  ###

  findEvents: (calendarId, startDate, endDate) ->
    toUTCString = (date) ->
      return (new Date(date.getTime() + date.getTimezoneOffset() * 60000)).toISOString()

    action = (resolve, reject) -> @sendRequest('/calendars/' + calendarId + '/find_events/', 'GET',
      {startDate: toUTCString(startDate), endDate: toUTCString(endDate)}, resolve, reject)
    new Promise(action.bind(@))

exports.UoACalendarClient = UoACalendarClient

module.exports = (apiToken, host, port) ->
  return new UoACalendarClient(apiToken, host, port)
