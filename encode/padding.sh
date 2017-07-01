#!/bin/bash

right_pad()
{
    rpadhexstr "$1" "$((${2} - ${#1}))"
}

left_pad()
{
    lpadhexstr "$1" "$((${2} - ${#1}))"
}
