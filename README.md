Testing an idea to have a unix queue, i.e. a replacement for Gearman or RabbitMQ, but in bash. Early days, just playing.

Sending a message is simply appending a line to the end of a spool file. inotify alerts us to file changes, and we chop the first line of the file and pass that to the script that wants to receive those messages.

Here's a setup example assuming you wanted to write ids to the queue which are database primary keys of website who's thumbnail you want to fetch.

**Create the queues**

- Create a /var/spool/isqueue/ directory, and give yourself permissions.
- Make one file for each queue you want, where the file is <queue_name>.queue. e.g. fetch_thumb.queue, recalculate.queue, etc.

**Send a message**

`./produce.sh fetch_thumb 34` or `echo 34 > /var/spool/isqueue/fetch_thumb.queue` or the equivalent in the language of your choice.

The queue is just a text file, so you can put strings, JSON, whatever, as long as it's one message per line.

**Receive messages**

Make a program to fetch the thumbnail (using shrinktheweb?). Your program should be runnable from the command line, and expect the message as it's last (or only) argument.

- Install incron: `sudo apt-get install libnotify-bin incron`
- `incrontab -e` - add something like:

    /var/spool/isqueue/fetch_thumb.queue IN_MODIFY /<correct_path_here>/consume.sh -l -p 4 -q fetch_thumb /<other_path>/thumbnail_fetcher.py

The _-l_ means to control access to the queue via a lock file. The _-p 4_ means allow up to four processes to run. _-q fetch_thumb_ means listen to a queue called fetch_thumb. The next param after that is the script to run.

**Monitor**

The beauty of your queues being just files is that `wc -l /var/spool/isqueue/fetch_thumb.queue` will tell you how many messages are waiting.


