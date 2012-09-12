Aeolus Conductor
================


Build Status
------------
[![Build
Status](https://secure.travis-ci.org/aeolusproject/conductor.png?branch=master)](http://travis-ci.org/aeolusproject/conductor)

About
-----
Aeolus Conductor is a Ruby-based web application for cloud management.  It
is one component of the [Aeolus Project](http://www.aeolusproject.org/).
For a chart of how Conductor fits with the other components, see:
[Aeolus Components](https://www.aeolusproject.org/redmine/projects/aeolus/wiki/Aeolus_Components)

Just Want To Try It Out?
------------------------

If you just want to try it out, start here:
[Get It](https://www.aeolusproject.org/get_it.html)

Otherwise, if you are a developer who wants to set up a development
environment using the latest upstream code, this document is for you.

Setting Up a Development Environment Using Bundler
--------------------------------------------------

All ruby gems that our project relies on are installed locally in a
sandbox via bundler (gem and bundler must already be
installed).  Of course, if other system-wide gems are installed that
is fine too-- "bundle install" will pull in the version-specific
dependencies it needs locally.

### System Prerequisites ###

There are a few things that need to be done as root or a sudo-enabled
user before we check out the Conductor repository and fire up the
development server.

We rely on the system to provide some development libraries, ruby,
gem, bundler and a database.  Specifically for RHEL 6 or Fedora Core
16 or 17, we can grab these dependencies with:

  yum install -y postgresql-server postgresql postgresql-devel ruby
    ruby-devel ruby-rdoc git libxml2 libxml2-devel libxslt
    libxslt-devel gcc gcc-c++

  ^^assumes using postgres as our back-end database, but we could
    just as well use sqlite or mysql.

This set of requirements is not unusual and should look familiar to
the experienced Ruby developer.  Of course, installing these libraries
for another flavor of OS should also be relatively straightforward.

As previously mentioned, gem and bundler also should be available on
your system but no other system-wide gems are necessary.

If you happen to be running RHEL6 or Fedora 16/17, you can download
the script conductor-dev-root-prep.sh from
https://gist.github.com/3178181 which installs the needed system
dependencies and sets up postgres.

Otherwise, you will need to adapt the steps in the script for your
particular OS.

### Setting Up a Development Workspace ###

With the above prerequisites met, setting up a development environment
is as easy as cloning the repository, bundle-installing the needed
gems locally, and running a few rake commands.  See the OS-agnostic
script conductor-dev-setup.sh from https://gist.github.com/3178181
which does just that.  This script should *not* be run as root, rather
as the non-privileged user you are going to do development with.

Happy coding!

Contact
-------

IRC: Team members can be found in #aeolus on [Freenode](http://freenode.net/using_the_network.shtml)

Mailing List:  We also make heavy use of the mailing list
[aeolus-devel@lists.fedorahosted.org](https://fedorahosted.org/mailman/listinfo/aeolus-devel).
You may also find the [aeolus-devel list archives](https://fedorahosted.org/pipermail/aeolus-devel/) helpful.
