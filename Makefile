all:
	./node_modules/.bin/browserify --standalone=DiaryClient -t coffeeify DiaryClient.coffee --outfile=dist/diary-api.js

