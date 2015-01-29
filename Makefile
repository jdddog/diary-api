all:
	./node_modules/.bin/browserify --standalone=UoACalendarClient -t coffeeify UoACalendarClient.coffee --outfile=dist/uoacalendar.js

