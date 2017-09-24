#!/bin/bash
docker build --build-arg REPOSITORY_HOST=http://master:8181 -t sumit/oracle:latest .
