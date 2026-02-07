#!/bin/bash

echo "Building AWS infrastructure for production..."
cd aws
./build-prod.sh
cd ..
echo "AWS infrastructure for production successfully built."

echo "Building GitHub infrastructure for production..."
cd github
./build-prod.sh
cd ..
echo "GitHub infrastructure for production successfully built."
