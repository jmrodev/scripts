#!/bin/bash
httpdir=/srv/http/
	echo "Creando nuevo proyecto Laravel: $1"
	mkdir $1
	cd $1
	echo "$2" > index.html
	cd ..
	sudo mv $1 $httpdir
