[![Build Status](https://github.com/cruessler/exrss/workflows/build/badge.svg)](https://github.com/cruessler/exrss/actions?query=workflow%3Abuild)

# ExRss

ExRss is a web-based RSS feed reader, optimized for use on mobile devices. It
is already usable, but lacks features and polish.

The backend is developed in [Elixir](http://elixir-lang.org), using
[Phoenix](http://www.phoenixframework.org/), while the frontend is written in
[Elm](http://elm-lang.org).

# Setup

## Database setup

```
# connect to a Postgres server
psql …

postgres=# create role ex_rss password 'ex_rss' login;
CREATE ROLE
postgres=# create database ex_rss_test owner ex_rss;
CREATE DATABASE
postgres=# create database ex_rss_dev owner ex_rss;
CREATE DATABASE

# to quit the session
postgres=# \q
```
