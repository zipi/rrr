# Ruby on Rails with React Development Container
## November 2019

This is like a starter project, from this you can build your own. I'm naming this rrr-work for reasons that
seem obvious to me. You'll want your project to have a name that describes it, so where I use rrr in this document
substitute a real name that describes the application instead of the technology.

### Objectives
It's been a couple of years since I started a new rails project, there's new stuff to use, and now I'm like "use docker for everything", so
I needed a container for a greenfield, state of the art, Rails with React project. My objective for development containers is to 
avoid environment alias wranglers like **rbenv** or **rvm**, avoid loading up my actual computer with multiple versions
of backported and home-brewed packages, and maximize portability so even a Windows user can use it.

I wanted a real Linux environment with a good colorized bash shell, command history, and strong vim based IDE, and 
still let the youngsters use their proprietary GUI IDEs if they need to.

I wanted volatile containers with all work artifacts stored in bound volumes so I could rebuild the image as needed and
just start up again where I left off.

### What's Here
The procedure in this Readme to start your React on Rails project will leave you with a project directory that contains 3 sub directories, 
one for your home directory, one for gems, and one for MySQL data. You also have 3 scripts that are just docker run commands, I do it 
this way because it's what works for me. up-work will bring you to a bash prompt in the home directory with all the good tools at your fingertips.
up-root you may never need but it's good to know how to get a root prompt. up-mysql is just to launch an official MySQL8 container with 
data saved in a bound volume.

What I've got now is ruby 2.6.5, rails 6.0.1, nodejs 12, yarn 19.1, python3.5, lua5.3, and the latest versions the gems that are required for 
Rails with React. And SpaceVim!

All my scripts and the commands in this readme assume bash, if you're on Windows these will probably not work.
 If you're not willing to install Linux over your Windows you'll have to figure
out for yourself how to change the code and invoke these scripts and commands, hopefully the intent is clear enough to get 
you where you need to be.

### How to Get It Running 

You've got to have docker running on your computer, but that's the only prerequisite, and that's why I'm all "use docker for everything".

Clone or copy this project into your normal directory for work. Run a terminal window and change directory into this project.

To run the containers you'll need directories to bind at /home/app, /usr/local/bundle, and /var/lib/mysql

	mkdir app data bundle

The application container depends on a database container, so get that up first. If you don't have the official MySQL8 image you'll see it download
and then run daemonized.

	./up-mysql.sh

I recommend building the application container yourself, it should work fine with an image from a registry, but building gives you a chance to 
get any updated packages.

	Docker build -t rrr-work .

Now you can start a container with the up-work script

	./up-work.sh

That should bring you to a prompt inside the container, but because of the build process the home directory is bare,
we don't have the nice bash prompt, correct environment, or SpaceVim.
So in the container run:

	/tmp/newhome.sh

And when it's all done exit to stop and remove the container, then start it up again.

	exit
	./up-work.sh

Now we have an initialized bash shell, and fresh SpaceVim. Run that to get it to install all it's plugins.

	vim

When SpaceVim is ready, edit a Gemfile

	:e Gemfile
	
The official Ruby image we used to build our image has a basic set of gems including bundler. We want gems specific to our app to be saved
so that we don't have to bundle install every time we restart the container. That's what the bundle sub-directory does.  After these next steps you can
see gems being saved into that directory by bundler. Create a Gemfile like this:

	source 'https://rubygems.org'	

	gem "rails"

Use ZZ or :wq to get out of vim, if you don't know it, you should, it works everywhere and it's awesome. And SpaceVim looks very nice.

Now install some gems with bundler.

	bundle install

Go get a cup of coffee.
This works for me with no missing dependencies or other problems, but it didn't the first time, everything required should be in the image,
if not, the right approach is to fix that in the Dockerfile and rebuild the image.
Once you've initialized your home directory you can rebuild the image as much as you want and you
won't have to run newhome again. Just run up-work again and your home directory will be just as you left it.

When you have rails installed it'll be saved in your bundler volume, so you don't need to install it again, and
you can get rid of that Gemfile

	rm Gemfile Gemfile.lock

And now you can create a rails project. As I heard it, yarn or webpack or something has a problem if it's not running in a project that already 
has git initialized. You are of course welcome to try using rails new with the name of a project directory to create, but this worked for me:

	mkdir rrr
	cd rrr
	rails new . --webpack=react --skip-coffee --database=mysql --skip-turbolinks

You may know rails options better than me, feel free to change what I've done to suit your objectives.
You may see some warnings about 'unmet peer dependency "webpack@^4.0.0"', but it installs webpack 4.41.2, so I expect we're good.

You might see a yarn error. Follow the instructions to 

	yarn install --check-files

And that seems to fix it.

The rails new process is not fast, but
when it's done you'll have a new sub-directory named rrr and in it a real rails project ready to run, almost.
Rails creates a project suited to run on your computer, not in a container, so there are a few config changes to make.
By default puma binds to 127.0.0.1:3000, but nobody runs a browser in a container, so that doesn't work.

Get the IP of your container.

	ip a | grep inet

The second one should not be a loopback, for me it was 172.17.0.3.

Edit config/puma.rb, comment out the port line and add a bind line,
that part should look like this when you're done.

	# port        ENV.fetch("PORT") { 3000 }
	bind      "tcp://172.17.0.3:3000"

The IP address may be a problem spot, I'd like to use 0.0.0.0 there, but it does not connect.  I'm not sure if this a problem with puma or docker port mapping.
Normally I have no problem binding to 0.0.0.0. You don't have to do this now, but you can prevent the container from changing IP on a restart
by adding a line like this to the up-work script. Just remember the last line in that script must be the name of the image "rrr-work",
because it's all just one command with escaped newlines to make it easier to read and edit.

	--ip="172.17.0.3" \

It occurs to me a better solution, if I can't get the zeros address to bind, is to pass the IP to puma in the ENV.

In another terminal window run

	docker port rrr-work

You should see the containers port 3000 mapped to the hosts port 3030. This is specified in up-work and you can change it to suit your needs.

Now you can run 

	rails s

And see something in your browser. Go to http://localhost:3030 use the mapped host port.
It's possible to run more than server at a time, but they'll each need their own port on the host computer.

Now, if your app is like mine, you'll see errors. We need to get the database working.

Ctrl-C will stop the server. Edit config/database.yml, change the host under default from localhost to rrr-db.

The up-mysql.sh script launches MySQL8 with options that allow root login from any host, ok for me inside my development computer, but don't do that in production.
MySQL8 has new authentication plugins. I have not seen anything that is compatible with default plugin, except mysql-client.
So that has to be fixed before we can connect.  You might find it easier to use MySQL5.7 or postgress or whatever you prefer, I wanted MySQL8.

To get a MySQL prompt run this in another terminal window, if you do this often put it in a script or an alias.

	docker container exec -it rrr-db mysql

Now at you're at a mysql prompt, run this:

	ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY ''; 
    CREATE DATABASE rrr_development;

In production you'll want actual passwords and a secure database server, and remember either create users with the mysql_native_password authentication plugin, or change the mysql configuration like this:

	[mysqld]
	default-authentication-plugin = mysql_native_password

A database image with a customized configuration is an exercise left to the reader who finds it necessary. 

Now the database should be ready to go. Refresh the browser and enjoy the pretty "Yay! You're on Rails!" page. But not too long, now the real work
of building a Rails and React web application can begin.

The first problem you'll notice is an error from web console, this can be useful during development, so to fix it edit confg/environments/development.rb and 
add this line inside the Rails.application.configure block.

	config.web_console.permissions = "172.17.0.0/24"

That network might not be the same for your docker engine, but that should be easy enough to get right.

### How to Work

On your computer list the directory where you started and now you should see your app directory, inside that just the directory you created with rails new.
But if you list the hidden files with -a you'll see lots of things that are hidden for good reasons. If you want to edit the project with an IDE on your 
computer just point it at the rails project, you can run **rails s** in the container at the same time.

I'll be using SpaceVim running in the container. Other terminals can attach to the container with docker exec and run the server or continuous testing.

### Resources







