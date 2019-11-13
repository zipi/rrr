docker run -it --rm --name rrr-app \
	-v `pwd`/app:/home/app \
	-v `pwd`/bundle:/usr/local/bundle \
	--link rrr-db  \
	-p 3000 \
	rrr-work

