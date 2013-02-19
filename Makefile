
compile:
	node_modules/coffee-script/bin/coffee -c -o lib src/image_headers.coffee

test: compile
	npm test