Inventory
=========

This is a very simple system I use for managing a complete inventory of my
possessions.

* The backend is CouchDB, to allow arbitrary attributes for items
* The frontend is written in Ruby using Sinatra, and making use of HAML.
* There's also some JQuery scattered throughout the views.

Installation
------------
Install the gems using the Gemfile, and upload the design documents in couch.json
to CouchDB. Start up the server with ruby inventory.rb, and you should be able
to navigate to localhost:4567 and begin adding things.

Inventory assumes every item in the database has a "name" and "category"
attribute, and the navigation list also recognises "subcategory" if it is
present. Otherwise, attributes are free-form.
