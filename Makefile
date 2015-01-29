all:
	./node_modules/.bin/browserify -t coffeeify UoACalendarClient.coffee > dist/uoacalendar.js

