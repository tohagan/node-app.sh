#!/bin/bash

# NodeJS, MongoDb app development tool

BROWSER="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

BUILD_DIR="./build"
BUILD_NUM_FILE="$BUILD_DIR/buildnum.txt"
buildnum=`cat "$BUILD_NUM_FILE"`
BUILD_LATEST="$BUILD_DIR/$buildnum"

APPTEMP="`pwd`/tmp"
mkdir -p "$APPTEMP"

# File & directories to watch in supervised mode
# which auto restarts node server if they change.
watch="app.js,config.js,models,routes,locales,fixtures"

usage="Usage: app [dev|prod] [db|run|runs|debug|test|env|freeze|refreeze|build|deploy|help]*

Select Environment:
	dev        Development environment
	prod       Production environment
	
Run one or more commands:	
	db         Restart mongo database
	run        Run app.js
	runs       Run app.js in supervised. Restarts app if files change in ... 
	              $watch 
	debug      Run app.js in debugger (non supervised)
	data       Runs fixtures.js to install test fixtures in database
	data-debug Runs fixtures.js in debugger
	test       Run mocka tests
	env		   Display server environment (if enabled) paginated output to 'less'
	freeze     Freeze npm package versions
	refreeze   Reapply freeze and report version changes (can undo)
	build      Run's build (Use prior to running 'prod' mode)
	deploy     Deploy latest build.
	help       Displays this usage message."

[ $# -eq 0 ] && { echo "$usage"; exit 1; }

# Development environment is default
env=development
mongo="mongod -v --config mongo-dev.config --rest"
client_url="http://localhost:9001"
app_dir=`pwd`
mongodir=db-dev

# Refs:
# win7 start cmd
#   http://www.computerhope.com/starthlp.htm
# Bash
#   http://linuxsig.org/files/bash_scripting.html

while [ $# -gt 0 ]
do
	case "$1" in
		help) echo "$usage" ;;
		
		dev)
			# Development settings (set by default above)
			;;
			
		prod)
			# Production settings
			env=production
			mongo="mongod --config mongo-prod.config --rest"
			mongodir=db-prod
			client_url="http://localhost:9000"
			app_dir="$DEPLOY_DIR"
			;;

		db) 
			[ -d "$mongodir" ] || mkdir "$mongodir" 
			# Restart Mongo Database
			kill `cat $APPTEMP/mongo.pid`
			$mongo &
			echo $! > $APPTEMP/mongo.pid
			;;

		run)
			start "" "$BROWSER" "$client_url" &
			( cd "$app_dir"; NODE_ENV="$env" node app.js )
			;;

		runs)
			start "" "$BROWSER" "$client_url" &
			# npm install supervisor
			echo "Watching: $watch ..."
			( cd "$app_dir"; NODE_ENV="$env" supervisor --watch "$watch" -- app.js )
			sleep 1
			;;

		debug)
			kill `cat $APPTEMP/debug.pid`
			(cd ../../res/node-inspector-windows/node_modules/node-inspector/bin && node inspector) &			
			echo $! > $APPTEMP/debug.pid
			sleep 2
			
			# Start debugger in Chrome (Win7)
			start "" "$BROWSER" "http://localhost:8080?port=5858" &
			
			# Start Client app in Chrome (Win7)
			start "" "$BROWSER" "$client_url" &
			
			# Start Server app in foreground 
			NODE_ENV="$env" node --debug-brk app.js			
			;;
		
		data)
			node load_fixtures.js
			;;

		data-debug)
			kill `cat $APPTEMP/debug.pid`
			(cd ../../res/node-inspector-windows/node_modules/node-inspector/bin && node inspector) &			
			echo $! > $APPTEMP/debug.pid
			sleep 2
			
			# Start debugger in Chrome (Win7)
			start "" "$BROWSER" "http://localhost:8080?port=5858" &
			
			node --debug-brk load_fixtures.js
			;;

		test)
			# http://visionmedia.github.com/mocha/
			# Requires: npm install -g mocha
			# Add to test/mocha.opts
			#  --require should
			#  --reporter spec
			#  --ui bdd
			mocha --reporter list --growl
			;;
			
		build)
			# Build production files 
			./build.sh
			# Update $BUILD_LATEST in case we run deploy
			buildnum=`cat "$BUILD_NUM_FILE"`
			BUILD_LATEST="$BUILD_DIR/$buildnum"
			;;
			
		deploy)
			echo Deploying build ... 
			ls -l "$BUILD_LATEST"
			# AppFog.com deployment
			( cd "$BUILD_LATEST"; af update dbm )
			start "" "$BROWSER" "http://dbm.aws.af.cm/" &
			;;

		env)
			# Display environment of running server - enabled if (config.dev || config.diag)
			curl "$client_url/env" | prettyjson | less
			;;

		install)
			npm install
			;;

		freeze)
			# Freeze current package versions
			# https://npmjs.org/doc/shrinkwrap.html
			npm shrinkwrap
			;;

		refreeze)
			rm -f npm-shrinkwrap.json-prev
			mv npm-shrinkwrap.json npm-shrinkwrap.json-prev
			npm install
			npm shrinkwrap
			echo Version differences since last freeze ...
			echo diff npm-shrinkwrap.json npm-shrinkwrap.json-prev
			diff npm-shrinkwrap.json npm-shrinkwrap.json-prev
			;;
			
		*) echo "$usage" >&2; exit 1;;
	esac
	shift
done

exit 0