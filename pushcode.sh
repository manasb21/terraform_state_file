#!/bin/bash -xv


git add .

git commit -m "terraform integration commit version $1"

git push origin master
