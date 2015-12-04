describe("test calendar", function () {
    var client = new UoACalendarClient(
        {apiToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0NDQxMDE3MjcsInVzZXJuYW1lIjoiamRpcDAwNEBhdWNrbGFuZC5hYy5ueiIsInVzZXJfaWQiOjIwLCJlbWFpbCI6IiJ9.jXRkx0b9jniWwbJ7mAaLkIzUWvaffAYWvsRfPKAK2H0"}
    );

    var calendar = {id: null, name: null};
    var calName = 'test';

    describe("Checks calendar", function () {
        beforeEach(function (done) {
            client.addCalendar(calName,
                function (res, data) {
                    calendar = data;
                    done();
                },

                function (res, data) {
                    done();
                });
        });

        it("Calendar id should be greater than 0", function () {
            expect(calendar.id).toBeGreaterThan(0);
        });

        it("Calendar name should equal 'test'", function () {
            expect(calendar.name).toBe(calName);
        });
    });

    describe("Checks events", function(){
        var event1 = {title: 'event1', start: new Date(1, 11, 2015), end: new Date(1, 11, 2015)};
        var event2 = {title: 'event2', start: new Date(2, 11, 2015), end: new Date(2, 11, 2015)};
        var event3 = {title: 'event3', start: new Date(3, 11, 2015), end: new Date(3, 11, 2015)};
        var events = [];

        beforeEach(function (done) {
            client.addEvent(calendar.id, event1,
                function (res, data) {
                    event1.id = data.id;
                    done();
                },

                function (res, data) {
                    done();
                });
        });

        beforeEach(function (done) {
            client.addEvent(calendar.id, event2,
                function (res, data) {
                    event2.id = data.id;
                    done();
                },

                function (res, data) {
                    done();
                });
        });

        beforeEach(function (done) {
            client.addEvent(calendar.id, event3,
                function (res, data) {
                    event3.id = data.id;
                    done();
                },

                function (res, data) {
                    done();
                });
        });

        beforeEach(function (done) {
            client.findEvents(calendar.id, new Date(2,11,2015), new Date(2,11,2015),
                function (res, data) {
                    events = data;
                    done();
                },

                function (res, data) {
                    done();
                })
        });

        describe("Checks findEvents results", function(){
            it("should have a length of 1", function () {
                expect(events.length).toEqual(1);
            });

            it("should be event 2", function () {
                expect(events[0].id).toEqual(event2.id);
            });
        });
    });
});
