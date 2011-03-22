A unix only queue, i.e. a replacement for Gearman or RabbitMQ, but in bash. Early days, not tested in production.

Sending a message is simply appending a line to the end of a spool file. inotify alerts us to file changes, and we chop the first line of the file and pass that to the script that wants to receive those messages. Add a bit of locking and you have a functional queueing system.

##Install##

Dependencies:

    sudo apt-get install libnotify-bin incron lockfile-progs

Install:

    git clone git://github.com/grahamking/isqueue.git
    cd isqueue
    sudo cp isq /usr/local/bin/ ; sudo chmod a+x /usr/local/bin/isq
    sudo mkdir /var/spool/isqueue ; sudo chmod a+w /var/spool/isqueue
    sudo cp isq-put-server.conf /etc/init/

##Usage##

**Send some messages**

     isq put server_type google.com
     isq put server_type yahoo.com
     isq put server_type darkcoding.net

This creates a queue called 'server_type', and add those three urls to it. Take a look: `cat /var/spool/isqueue/server_type.queue`.

The first parameters to _put_ is the name of the queue, the next the message to put on that queue. The queue is just a text file, so you can put strings, JSON, whatever, as long as it's one message per line. All `isq put` does is lock access to the queue file, append to it, then release the lock.

**Setup a message consumer**

We have some messages waiting in our queue, now we need to pick them up and process them. A message consumer is simply a program that expects the queue message as it's last or only argument.

Here's an example consumer for testing. Create an identify.sh with the contents below, and make it executable. It uses _curl_ to fetch a URL's headers, and display the Server line, so you can see if that website runs nginx, apache, etc.

    #!/bin/bash
    URL=$1
    S_TYPE=`curl -s --head $URL | grep Server`
    echo $URL $S_TYPE >> /tmp/out.log


Read from the queue: `isq get server_type ./identify.sh`

Watch the log file: `tail -f /tmp/out.log`. You should see output, and your queue should now be empty.

**Watch the queue with inotify**

We don't want to run _get_ manually, so use inotify to watch the queue and call us when something gets added.

First make sure you have permissions to use incron:

    ME=$(whoami)
    sudo bash -c "echo $ME >> /etc/incron.allow"

Now edit the incron crontab: `incrontab -e`

Add this line: `/var/spool/isqueue/server_type.queue IN_MODIFY /usr/local/bin/isq get server_type /home/<you>/identify.sh`

The next time your queue is modified, your listener will wake up. Whilst still tailing /tmp/out.log, do `isq put server_type mozilla.org`

If you don't see any output in /tmp/out.log, check syslog. incron logs the command it tries to run in there. `sudo tail -f /var/log/syslog`.

**Network**

Most likely you want to run your background jobs on a different machine to your website or foreground tasks. We wire a TCP port (1550 by default) to the `isq put` script using netcat, and use upstart to make it a daemon. We copied the upstart config in the Install step above, so just start the server: 

    sudo start isq-put-server

Putting a message on the queue is simply writing text to the socket:

    echo "server_type github.com" | nc 127.0.0.1 1550

Or in Python:

    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 1550))
    s.send('server_type gs.com')
    s.close()

In both cases you should see the result appear in /tmp/out.log

**Monitor**

The beauty of your queues being just files is that `wc -l /var/spool/isqueue/server_type.queue` will tell you how many messages are waiting.

##Misc.##

**Performance**

On my home machine, `isq put` can do about 100 puts a second.

**Credit**

Inspired by reading [Ted](http://teddziuba.com/2011/03/monitoring-theory.html) [Dziuba](http://teddziuba.com/2011/02/the-case-against-queues.html), and [Eric Raymond](http://www.faqs.org/docs/artu/).

