#!/bin/bash

rsync -Parhvx --progress services-docker/monitoring/* alfredo@13.77.144.158:/home/alfredo/monitoring

ssh alfredo@13.77.144.158 "rsync -Parhvx --progress ~/monitoring/* server@devops-vm-monitoring:/home/server/monitoring"