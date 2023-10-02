#!/bin/bash

source  myfuctions.sh

PS3="Select your workspace [ 1-3 ] and press enter: "

Select env in dev stage uat #( it let you to pick the work space you want to work on calling #rerraform.sh)

do 
 case $env in
    "dev")
       evironment;
       workspace;
       creds;
       test;
       break;;
    "stage")
       evironment;
       workspace;
       apply;
       break;;
    "uat")
      evironment;
      workspace;
      test;
      break;;
    *)
 esac
done
