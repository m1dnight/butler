MIX_ENV := prod 

release: 
	docker run --rm -it -w /src -v ${CURDIR}:/src --platform linux/amd64 elixir /src/scripts/release.sh