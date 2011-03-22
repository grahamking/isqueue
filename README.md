A unix only queue, i.e. a replacement for Gearman or RabbitMQ, but in bash. Early days, not tested in production.

Sending a message is simply appending a line to the end of a spool file. inotify alerts us to file changes, and we chop the first line of the file and pass that to the script that wants to receive those messages.

Add a bit of locking (_mkdir_ would work, but we use tools from lockfile-progs package), and you have a functional queueing system.

**Dependencies**

    sudo apt-get install libnotify-bin incron lockfile-progs

**Install**

    sudo cp isq-*.sh /usr/local/bin/
    sudo chmod a+x /usr/local/bin/isq-*

**Create the queues**

- Create a /var/spool/isqueue/ directory, and give yourself permissions.
- Make one file for each queue you want, where the file is <queue_name>.queue. e.g. server_type.queue, fetch_thumb.queue, recalculate.queue, etc.

**Send a message**

     /usr/local/bin/isq-produce.sh server_type google.com
     /usr/local/bin/isq-produce.sh server_type yahoo.com
     /usr/local/bin/isq-produce.sh server_type darkcoding.net

The first parameters is the name of the queue, the next the message to put on that queue. The queue is just a text file, so you can put strings, JSON, whatever, as long as it's one message per line. All isq-produce.sh is doing is locking access to the queue, appending to it, and releasing the lock.

Peek at your queue: `cat /var/spool/isqueue/server_type.queue`

**Receive messages**

Make a program to receive and act upon the messages. Your program should be runnable from the command line, and expect the message as it's last (or only) argument.

`incrontab -e` and add something like:

    /var/spool/isqueue/server_type.queue IN_MODIFY /usr/local/bin/isq-consume.sh -p 4 -q server_type /<other_path>/identify.sh

The _-p 4_ means allow up to four processes to run. _-q server_type_ means listen to a queue called server_type. The next param after that is the script to run.

Now the next time your queue is modified, your listener will wake up.

**Monitor**

The beauty of your queues being just files is that `wc -l /var/spool/isqueue/server_type.queue` will tell you how many messages are waiting.

**Test**

To see it in action, use this script as your `identify.sh`. It writes the Server header line to /tmp/out.log, assuming you have curl.

    #!/bin/bash
    url=$1
    S_TYPE=`curl -s --head $url | grep Server`
    echo $url $S_TYPE >> /tmp/out.log

 1. Setup incron as mentioned above
 2. `tail -f /tmp/out.log` in one window
 3. `isq-produce.sh server_type <url>` away in another.

**Network**

Most likely you want to run your background jobs on a different machine to your website or foreground tasks. We wire a TCP port to the isq-produce script using netcat, and use upstart to make it a daemon. The upstart config is included.

    sudo cp isq-produce-server.conf /etc/init/
    sudo start isq-produce-server

Putting a message on the queue is simply writing text to the socket:

    echo "server_type github.com" | nc 127.0.0.1 1234

Or in Python:

    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 1234))
    s.send('server_type gs.com')
    s.close()

You should see the result appear in /tmp/out.log

**Credit**

Inspired by reading [Ted](http://teddziuba.com/2011/03/monitoring-theory.html) [Dziuba](http://teddziuba.com/2011/02/the-case-against-queues.html), and [Eric Raymond](http://www.faqs.org/docs/artu/).

