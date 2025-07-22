#!/bin/bash

echo "🔧 Installing Git + configuring global settings..."

sudo apt install -y git

git config --global user.name "seanGSISG"
git config --global user.email "sswanson@gsisg.com"
git config --global init.defaultBranch main
git config --global core.editor "nano"
