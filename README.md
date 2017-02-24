Mazizone Portal
=================

This repository contains 

Prerequirements
---------------

Install the following packages:

    $ apt-get update
    $ apt-get install build-essential git-core libsqlite3-dev ruby ruby-dev

Also install the following gems:

    $ gem install sinatra sequel sqlite3 rake thin

Installation
------------

    $ git clone git@github.com:mazi-project/portal.git
    $ cd portal
    $ rake db:migrate

Execution
---------

    $ ruby -I lib -I database mazi_portal_server.rb

