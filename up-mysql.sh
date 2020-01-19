docker run -d --rm --name rrr-db \
	-v `pwd`/data:/var/lib/mysql \
	-e "MYSQL_ALLOW_EMPTY_PASSWORD=yes" \
	--network rrr-net
	--log-opt max-size=10m --log-opt max-file=3 \
	mysql:8
