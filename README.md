Mazizone Portal
=================

This repository contains 

Prerequirements
---------------

Install the following packages:

    $ apt-get update
    $ apt-get install build-essential git-core libsqlite3-dev ruby ruby-dev

Also install the following gems:

    $ gem install sinatra sequel sqlite3 rake thin --no-ri --no-rdoc

And download the back-end scripts

    $ sudo su
    $ cd /root
    $ git clone git@github.com:mazi-project/back-end.git

Installation
------------

    $ sudo su
    $ cd /root
    $ git clone git@github.com:mazi-project/portal.git
    $ cd portal
    $ rake init
    $ rake db:migrate

Configuration
-------------

Edit the configuration file (/etc/mazi/config.yml) with an editor

    $ nano /etc/mazi/config.yml

Execution
---------

    $ ruby -I lib -I database mazi_portal_server.rb

Update
-------

In order to update, you need to execute the following commands:

    $ cd /root/portal
    $ git pull origin master
    $ rake db:migrate
    $ cp /etc/mazi/config.yml /etc/mazi/config.yml.bu
    $ cp etc/config.yml /etc/mazi/config.yml

And open the configuration file (/etc/mazi/config.yml) with an editor

    $ nano /etc/mazi/config.yml
