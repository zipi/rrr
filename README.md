# Ruby on Rails with React Development Container
## November 2019

This is like a starter project, from this you can build your own. I'm naming this rrr-work for reasons that
seem obvious to me. You'll want your project to have a name that describes it, so where I use rrr in this project
substitute a real name that describes your application instead of the technology.

### Objectives

It's been a couple of years since I started a new rails project, there's new stuff to use,
and lately I'm like "use Docker for everything", so
I wanted an image for a greenfield, state of the art, Ruby on Rails with React project.
My objectives for development containers are to 
avoid environment alias wranglers like **rbenv** or **rvm**, avoid loading up my actual computer with multiple versions
of backported and home-brewed packages, hide away any networking complexity, and last, and least, maximize portability so that, maybe, you can use it on Windows.

I wanted a real Linux environment with a good colorized bash shell, command history, a strong vim based IDE, and 
still let the youngsters use their proprietary GUI IDEs if they need to. If you do want a slick editor I have found
VSC to be excellent, it has many plugins and the syntax checking and code completion work very well.

I also wanted removable containers with all work artifacts stored in bound volumes so I could rebuild the image as needed and
just start up again where I left off.

### What's Here

The procedure in this Readme will start your Ruby on Rails with React project and leave you with a project directory containing
3 sub directories, one for your home directory, one for gems, and one for MySQL data.
You also have several scripts that are just Docker commands, I do it this way because it's quick to fire up
with all the right options.
up-net.sh starts a Docker network with a dependable subnet.
up-work.sh will bring you to a bash prompt in the app user's home directory with all the good tools at your fingertips.
You may never need up-root.sh but it's good to know how to get a root prompt. And up-mysql.sh just launches an official MySQL:8
container with data saved in a bound volume.

What I've got running now is ruby 2.6.5, rails 6.0.1, nodejs 12, yarn 19.1, python 3.5, lua 5.3,
and the latest versions the gems that are required for Rails with React. Oh, and SpaceVim!

All my scripts and the commands in this readme assume bash, if you're on Windows these will not work.
I've tried Git bash (cygwin), and WSL bash both have problems. As usual the intentional incompatibilities
of Windows file systems and end-of-line characters are show stoppers.

If you're not willing to replace Windows with a nice Ubuntu install, or at least dual boot, you'll have to figure
out for yourself how to change the code and invoke these scripts and commands, hopefully the intent is clear enough to get 
you where you need to be.

### How to Get It Running 

You've got to have Docker running on your computer, but that's the only prerequisite,
and that's a big reason why I'm all "use Docker for everything", just install Docker and then run just about anything. Make sure you are able to run docker commands as a user. Usually that's just
add your user to the docker group.

Clone or copy this rrr project directory into your normal directory for work, but give it the name of the project
you want to build.  Run a terminal window and change directory into this new project directory.

#### Rename

The first thing to do is fix the name, you could keep rrr, but really, you should edit all the scripts and replace rrr with the name you want for your project. Keep in mind as you follow these directions,
rrr shows up in a few commands, always replace it with your project's name. Also edit the Docker file and replace the maintainer label with your own name and email address.

When run, the containers will create the directories they need for binding /home/app, /usr/local/bundle, and /var/lib/mysql.  These are specified in the up* scripts. I like keeping the bound volumes in the project directory, there it's easy to edit outside of the docker container, or erase everything and
start over.

The Next thing to do is make sure your dev container's app user has the same UID and GID as you do so that
you can edit outside of the container. Do a *ls -ln* to identify your user id numbers and then edit the
Dockerfile's addgroup and adduser commands to match. This is the main reason to build your own image
instead of just downloading one from dockerhub.

#### Build and run the containers

Now run the network before you start any containers, or there will be errors.

	./up-net.sh

Then you can start up MySQL, unless you have another preference. I'm running MySQL 8, there are issues
that need be worked around, version 5.7 is easier to get running, and PostreSQL has some great plugins.
Change the script if required.

	./up-mysql.sh

Build your development image, remember to use your project's name instead of rrr.

	docker build -t rrr-work .

Since you need the app and bundle directories to be writable by the app user in the container you 
need to create them first before you run up-work for the first time, otherwise they will be owned by
root, so make directories like this:

	mkdir app bundle

Now you can start a container with the up-work script.

	./up-work.sh

That should bring you to a prompt inside the container, but because we mount the app user's home
directory it's empty,
so we don't have an initialized shell, correct environment variables, or SpaceVim.
In the container run:

	/tmp/newhome.sh

And when it's all done type *exit* then run up-work again. This also add the path that allows
you to run bundler installed gems without bundle exec.

Now we have an initialized bash shell, and fresh SpaceVim. Run *vim* (twice?) to get it to install all it's plugins.

#### Start a rails project

When SpaceVim is ready, edit a Gemfile

	:e Gemfile
	
The official Ruby image we used to build our image has a basic set of gems including bundler. We want gems specific to our app to be saved
so that we don't have to bundle install every time we restart the container. That's what the bundle sub-directory does.  After these next steps you can
see gems saved into that directory by bundler. This is all you should have in this temporary Gemfile:

	source 'https://rubygems.org'	

	gem "rails"

Use ZZ or :wq to get out of vim, if you don't know it, you should, it works everywhere and it's awesome. And SpaceVim looks very nice.

Now install some gems with bundler.

	bundle install

This works for me with no missing dependencies or other problems, but it didn't the first time,
everything required should be built into the image,
if not, the right approach is to fix that in the Dockerfile and rebuild the image.
Once you've initialized your home directory you can rebuild the image as much as you want and you
won't have to run newhome again. Just run up-work again and your home directory will be just as you left it.

When you have rails installed it'll be saved in your bundler volume, so you don't need to install it again, and
you can get rid of that Gemfile

	rm Gemfile Gemfile.lock

Now you can create a rails project.

	rails new rrr --webpack=react --database=mysql --skip-coffee --skip-turbolinks

You may know rails options better than me, feel free to change what I've done to suit your objectives.
You may see some warnings about 'unmet peer dependency "webpack@^4.0.0"', but it installs webpack 4.41.2,
so I expect we're good.

Yarn saves information in the app user's home directory, so if you remove your rails project directory and run **rails new** again
you might see a yarn error. Follow the instructions to run

	yarn install --check-files

And that will fix it.

The rails new process is not fast, but
when it's done you'll have a new sub-directory named rrr and in it a real rails project ready to run, almost.
Rails creates a project suited to run on your computer, not in a container, so there are a few config changes to make.

#### Configure Rails for Docker

By default puma binds to 127.0.0.1:3000, but nobody runs a browser in a container, so that's not going to work.

For a minute I had a problem with Docker on my MacBook where I had to map to the containers IP, but after
an update from Docker I tried again and now it's working the way I thought it should. You shouldn't need to worry 
about the specific IP of your container. 

Edit config/puma.rb, comment out the port line and add a bind line,
that part should look like this when you're done.

	# port        ENV.fetch("PORT") { 3000 }
	bind      "tcp://0.0.0.0:3000"

It's real nice to have the webpacker dev server running and updating your pages as you make changes, saves a lot of time.
Edit config/webpacker.yml and change these lines as shown.

    host: 0.0.0.0
    port: 3035
    public: 127.0.0.1:3035

Now just pay attention to the two port expose options in the up-work script. They map the container's ports 3000 and 3035 to 
the same ports on localhost. This nice as the URLs for development are exactly the same as you'd see if the server was running 
without Docker.

You'll want to use web console, or at least suppress the error messages so
edit confg/environments/development.rb and add this line inside the Rails.application.configure block.

	config.web_console.permissions = "172.28.5.0/24"

If you've changed the up-net script you'll know if you need a different subnet here.

Of course before we run the server we need to edit config/database.yml.
All you really need to change is the host.

	host: rrr-db

Now lets make sure the connection to the database is working by creating our databases

	rails db:create

If you are running MySQL 8 like I am you'll see errors

#### Manage MySQL 8

The up-mysql.sh script launches MySQL:8 with options that allow root login from any host,
nice and easy for me inside my development computer, but don't do that in production.
MySQL:8 has new authentication plugins. I have not seen anything that is compatible with default plugin, except mysql-client.
So that has to be fixed before we can connect.

To get a MySQL prompt open another terminal window and run *exec-mysql.sh* Or type in the command
yourself

	Docker container exec -it rrr-db mysql

Now you're root with a mysql prompt, run this:

	ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY ''; 

In production you'll want actual passwords and a secure database server, and remember either create users with the mysql_native_password authentication plugin, or change the mysql configuration like this:

	[mysqld]
	default-authentication-plugin = mysql_native_password

A database Docker image with a customized configuration is an exercise left to the reader who finds it necessary. 

You can could your database in the mysql terminal with

	CREATE DATABASE rrr_development
	CREATE DATABASE rrr_test

Better to exit MySQL and run it from the command line so you can verify rails can control the database server.

	rails db:create

#### Yea! You're on Rails

Now your application is finally ready, run the server

	rails s

Load http://localhost:3000 in your browser and enjoy the pretty "Yay! You're on Rails!" page. But not too long, now the real work
of building a Ruby on Rails with React web application can begin.

### How to Accomplish Work

On your computer list the directory where you started and now you should see an app home directory, inside that is the directory you created with rails new. List hidden files and you'll see lots of things that are
hidden for good reasons. If you want to edit the project with an IDE on your 
computer just point it at the rails project, you can run **rails s** in the container at the same time.

I'll be using SpaceVim running in the container, and VSC natively. You can run other terminals in the container with Docker exec and run the server, command line, bin/dev-webpack-server,
continuous testing, or anything else you'd like, all at the same time. If you do that often write a script
to make if fast and easy.

I keep these containers running all the time and just put my computer to sleep when I step away. When I do need to restart my computer I'll get the dev environment started up again by opening three tabs in Terminal or Konsole, in the first I run:

	cd rrr            // the base directory for the rrr image
	./up-net.sh
	./up-mysql.sh
	./up-work.sh
	cd rrr            // the rails project inside the app user's home directory  

Here I'll be at a prompt in my project directory inside the development container, then in the second tab I run:

	./exec-wds

This runs webpack-dev-server and will refresh the page in my browser as I save any little change to the CSS or JavaScript.

In the third tab I'll run:

	./exec-server

This runs the rails development server. Now I can see the web site at http://localhost:3000 see the server log in the third tab, see the webpack log in the second tab, and run commands in the first tab like 

	rails generate model user name age sex
	rails db:migrate
	vim app/models/user.rb

I also typically run VCS natively and open the "folder" rrr/app/rrr.

### Resources

Many of these  tutorials go over setup steps, but since you're using this rrr image you can
skip ahead to actual application coding.

https://www.youtube.com/watch?v=5F_JUvPq410

https://www.youtube.com/watch?v=B0SxxHAImhc

https://www.digitalocean.com/community/tutorials/how-to-set-up-a-ruby-on-rails-project-with-a-react-frontend


### Deployment

coming eventually

##### MySQL Users
##### Secrets
##### Capistrano



