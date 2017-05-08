MAZI Portal
=================

This repository contains the Portal of the MAZI toolkit. It is comprised of the user interface which enables users to interact with the available applications and the admin interface which enables the administrator of the Mazizone to customize the appearance of the Portal, configure important networking parameters (network name, SSID etc.), observe statistics of the Mazizone and much more.

You can find a detailed documentation for the usage of the Portal in the wiki of this repository https://github.com/mazi-project/portal/wiki.

Or in the MAZI guides repository https://github.com/mazi-project/guides/wiki.

Prerequirements
---------------

Install the following packages:

    $ apt-get update
    $ apt-get install build-essential git-core libsqlite3-dev ruby ruby-dev

Also install the following gems:

    $ gem install sinatra sequel sqlite3 rake thin rubyzip --no-ri --no-rdoc

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


Execution
---------

    $ ruby -I lib -I database mazi_portal_server.rb

Update
-------

Since version 1.6.4 there is an update function to the admin menu. 
In order to update using the command line, you need to execute the following commands:

    $ sudo su
    $ cd /root/portal
    $ git pull origin master
    $ rake db:migrate
    $ cp /etc/mazi/config.yml /etc/mazi/config.yml.bu
    $ cp etc/config.yml /etc/mazi/config.yml
    $ cd /root/back-end
    $ git pull origin master
    $ service mazi-portal restart

## License

See the [LICENSE] (https://github.com/mazi-project/portal/blob/master/LICENSE) file for license rights and limitations (MIT).
