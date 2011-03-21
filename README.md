A unix only queue, i.e. a replacement for Gearman or RabbitMQ, but in bash. Early days, not tested in production.

Sending a message is simply appending a line to the end of a spool file. inotify alerts us to file changes, and we chop the first line of the file and pass that to the script that wants to receive those messages.

Add a bit of locking (_mkdir_ would work, but we use tools from lockfile-progs package), and you have a functional queueing system.

Here's a setup example assuming you want to put urls on your queue - say you want to fetch thumbnails for those urls.

**Dependencies**

    sudo apt-get install libnotify-bin incron lockfile-progs

**Create the queues**

- Create a /var/spool/isqueue/ directory, and give yourself permissions.
- Make one file for each queue you want, where the file is <queue_name>.queue. e.g. fetch_thumb.queue, recalculate.queue, etc.

**Send a message**

     ./produce.sh fetch_thumb google.com
     ./produce.sh fetch_thumb yahoo.com
     ./produce.sh fetch_thumb darkcoding.net

The queue is just a text file, so you can put strings, JSON, whatever, as long as it's one message per line.

Peek at your queue: `cat /var/spool/isqueue/fetch_thumb.queue`

**Receive messages**

Make a program to receive and act upon the messages. Your program should be runnable from the command line, and expect the message as it's last (or only) argument.

`incrontab -e` and add something like:

    /var/spool/isqueue/fetch_thumb.queue IN_MODIFY /<correct_path_here>/consume.sh -p 4 -q fetch_thumb /<other_path>/thumby.sh

The _-p 4_ means allow up to four processes to run. _-q fetch_thumb_ means listen to a queue called fetch_thumb. The next param after that is the script to run.

Now the next time your queue is modified, your listener will wake up.

**Monitor**

The beauty of your queues being just files is that `wc -l /var/spool/isqueue/fetch_thumb.queue` will tell you how many messages are waiting.

**Test**

To see it in action, use this script as your `thumby.sh`. It prints the Server header line, assuming you have curl.

    #!/bin/bash
    url=$1
    S_TYPE=`curl -s --head $url | grep Server`
    echo $url $S_TYPE >> /tmp/out.log

Setup incron as mentioned above, `tail -f /tmp/out.log` in one window, and `produce.sh` away in another.

**Credit**

Inspired by reading [Ted](http://teddziuba.com/2011/03/monitoring-theory.html) [Dziuba](http://teddziuba.com/2011/02/the-case-against-queues.html), and [Eric Raymond](http://www.faqs.org/docs/artu/).

