docker run -it --rm --name rrr-app \
	-v `pwd`/app:/home/app \
	-v `pwd`/bundle:/usr/local/bundle \
	--network rrr-net \
	-p 127.0.0.1:3000:3000 \
	-p 127.0.0.1:3035:3035 \
	rrr-work

