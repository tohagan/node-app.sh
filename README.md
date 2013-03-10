# node-app.sh #

Handy Swiss army knife shell script for NodeJS development.

##Usage:##
	 app [dev|prod] [db|run|runs|debug|test|env|freeze|refreeze|build|deploy|help]*


## Selects Environment: ##
	dev        Development environment
	test       Test environment
	prod       Production environment

## Runs one or more commands: ##
	unlock     Removes mongo database lock file
	db         Restart mongo database
	run        Run app.js
	runs       Run app.js in supervised. Restarts app if files change in ...  $watch (customised in this script) 
	debug      Run app.js in debugger (non supervised)
	data       Runs fixtures.js to install test fixtures in database
	data-debug Runs fixtures.js in debugger
	mock       Run mocha tests
	env		   Display server environment (if enabled) paginated output to 'less'
	freeze     Freeze npm package versions
	refreeze   Reapply freeze and report version changes (can undo)
	build      Run's build (Use prior to running 'prod' mode)
	deploy     Deploy latest build.
	help       Displays this usage message.
