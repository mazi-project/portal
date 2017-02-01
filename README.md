Mazizone Portal
=================

This repository contains 

Prerequirements
---------------

Install the following packages:

    $ apt-get install build-essentials git-core libsqlite3-dev ruby-dev

Also install the following gems:

    $ gem install sinatra sequel sqlite3 rake thin

Installation
------------

    $ git clone git@github.com:mazi-project/portal.git
    $ cd mazizone_portal
    $ rake db:init

Execution
---------

    $ ruby -I lib -I database mazi_portal_server.rb

