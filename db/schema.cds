namespace com.dk.mycapapp;

using { cuid } from '@sap/cds/common';

entity Students : cuid{
name : String(100);
age : Integer
};

