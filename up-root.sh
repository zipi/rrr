docker run -it --rm --name rrr-app \
	-v `pwd`/app:/home/app \
	-v `pwd`/bundle:/usr/local/bundle \
	--link rrr-db \
	--user root \
	rrr-work

