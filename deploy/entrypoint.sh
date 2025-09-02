#!/bin/sh

APP=/app
DATA=/data

# Fix ownership on volumes as root (this is crucial for named volumes)
chown -R user:user $DATA $APP/dist
chown -R user:spj $DATA/test_case

mkdir -p $DATA/log $DATA/config $DATA/ssl $DATA/test_case $DATA/public/upload $DATA/public/avatar $DATA/public/website

if [ ! -f "$DATA/config/secret.key" ]; then
    echo $(cat /dev/urandom | head -1 | md5sum | head -c 32) > "$DATA/config/secret.key"
fi

if [ ! -f "$DATA/public/avatar/default.png" ]; then
    cp $APP/data/public/avatar/default.png $DATA/public/avatar
fi

if [ ! -f "$DATA/public/website/favicon.ico" ]; then
    cp $APP/data/public/website/favicon.ico $DATA/public/website
fi

SSL="$DATA/ssl"
if [ ! -f "$SSL/server.key" ]; then
    openssl req -x509 -newkey rsa:2048 -keyout "$SSL/server.key" -out "$SSL/server.crt" -days 1000 \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=Beijing OnlineJudge Technology Co., Ltd./OU=Service Infrastructure Department/CN=`hostname`" -nodes
fi

cd $APP/deploy/nginx
ln -sf locations.conf https_locations.conf
if [ -z "$FORCE_HTTPS" ]; then
    ln -sf locations.conf http_locations.conf
else
    ln -sf https_redirect.conf http_locations.conf
fi

if [ ! -z "$LOWER_IP_HEADER" ]; then
    sed -i "s/__IP_HEADER__/\$http_$LOWER_IP_HEADER/g" api_proxy.conf;
else
    sed -i "s/__IP_HEADER__/\$remote_addr/g" api_proxy.conf;
fi

if [ -z "$MAX_WORKER_NUM" ]; then
    export CPU_CORE_NUM=$(grep -c ^processor /proc/cpuinfo)
    if [ $CPU_CORE_NUM -lt 2 ]; then
        export MAX_WORKER_NUM=2
    else
        export MAX_WORKER_NUM=$(($CPU_CORE_NUM))
    fi
fi

cd $APP/dist
if [ ! -z "$STATIC_CDN_HOST" ]; then
    find . -name "*.*" -type f -exec sed -i "s/__STATIC_CDN_HOST__/\/$STATIC_CDN_HOST/g" {} \;
else
    find . -name "*.*" -type f -exec sed -i "s/__STATIC_CDN_HOST__\///g" {} \;
fi

cd $APP

n=0
while [ $n -lt 5 ]
do
    # python manage.py migrate --no-input --fake-initial &&
    python manage.py inituser --username=root --password=rootroot --action=create_super_admin &&
    echo "from options.options import SysOptions; SysOptions.judge_server_token='${JUDGE_SERVER_TOKEN:-default_token}'" | python manage.py shell &&
    echo "from conf.models import JudgeServer; JudgeServer.objects.update(task_number=0)" | python manage.py shell &&
    break
    n=$(($n+1))
    echo "Failed to migrate, going to retry..."
    sleep 8
done

# User creation is now handled in Dockerfile
# Ensure proper permissions
# Create log directory and files with proper permissions
mkdir -p /data/log/nginx /data/log
touch /data/log/supervisord.log /data/log/gunicorn.log /data/log/dramatiq.log
touch /data/log/nginx/nginx_access.log /data/log/nginx/nginx_error.log
chmod 666 /data/log/*.log /data/log/nginx/*.log
chmod 777 /data/log /data/log/nginx
ls -la /data/log/
find $DATA/test_case -type d -exec chmod 710 {} \; 2>/dev/null || true
find $DATA/test_case -type d -exec chmod g+s {} \; 2>/dev/null || true  
find $DATA/test_case -type f -exec chmod 640 {} \; 2>/dev/null || true
# Ensure nginx temp dirs exist and are writable
mkdir -p /tmp/nginx/client_body /tmp/nginx/proxy /tmp/nginx/fastcgi /tmp/nginx/uwsgi /tmp/nginx/scgi
# Run supervisord directly
exec supervisord -c /app/deploy/supervisord.conf