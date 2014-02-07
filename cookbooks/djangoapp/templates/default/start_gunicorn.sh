#!/bin/bash
#set -e
LOGFILE=<%= node[:gunicorn][:log_root] %>/<%= node[:gunicorn][:project_name] %>.log
LOGDIR=$(dirname $LOGFILE)
NUM_WORKERS=3

# user/group to run as
USER=<%= node[:owner] %>
GROUP=<%= node[:group] %>

cd <%= node[:project_dir] %>
source /home/<%= node[:owner] %>/envs/<%= node[:virtualenv_name] %>/bin/activate
touch $LOGFILE
# chown $USER:$GROUP $LOGFILE
gunicorn djangotests.wsgi:application -b 0.0.0.0:8000 -w $NUM_WORKERS \
--user=vagrant --group=vagrant \
--log-file=/var/log/gunicorn/djangotests.log --log-level=debug