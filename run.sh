#!/bin/bash

docker run -it -d -p 49160:22 -p 49161:1521 -p 49162:8080 --name oracle sumit/oracle
