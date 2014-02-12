#!/bin/bash
source <%= node[:ownerhome] %>/envs/<%= node[:virtualenv_name] %>/bin/activate 
celery flower