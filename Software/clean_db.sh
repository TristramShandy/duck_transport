#!/bin/bash

rm duck_movement.db
sqlite3 duck_movement.db < create_db.sql
