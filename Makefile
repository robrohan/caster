
start:
	npm run start

build: clean
	npm run build
	cp src/index.html dist/index.html

clean:
	rm -rf dist