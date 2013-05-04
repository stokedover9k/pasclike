#!/bin/bash

for f in `seq 1 8` ; do 
	../src/parser test${f}.pas 
	mv rule.out test${f}_rule.out
	 mv symtable.out test${f}_symtable.out; 
done
