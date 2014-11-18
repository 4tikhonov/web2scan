#!/usr/bin/env python
#
# Very basic example of using Python and IMAP to iterate over emails in a
# gmail folder/label.  This code is released into the public domain.
#
# RKI July 2013
# http://www.voidynullness.net/blog/2013/07/25/gmail-email-with-python-via-imap/
#
import sys
import imaplib
import getpass
import email
import email.header
import datetime
import codecs
from subprocess import Popen, PIPE, STDOUT
import hashlib

def hashfile(afile, hasher, blocksize=65536):
    buf = afile.read(blocksize)
    while len(buf) > 0:
        hasher.update(buf)
        buf = afile.read(blocksize)
    return hasher.digest()

def md5sum(filename, blocksize=65536):
    hash = hashlib.md5()
    with open(filename, "r+b") as f:
        for block in iter(lambda: f.read(blocksize), ""):
            hash.update(block)
    return hash.hexdigest()

def process_mailbox(M):
    """
    Do something with emails messages in the folder.  
    For the sake of this example, print some headers.
    """

    rv, messages = M.search(None, "ALL")
    if rv != 'OK':
        print "No messages found!"
        return

    id = 0
    for item in messages:
	for num in messages[0].split():
	    rv, data = M.fetch(num, '(RFC822)')
	    msg = email.message_from_string(data[0][1])
	    frommail = str(msg['From'])
	    decode = email.header.decode_header(msg['Subject'])[0]
	    try:
	        subject = unicode(decode[0])
	    except:
	   	subject = 'Default'

	    fname = dir + "/mail/inbox." + str(id)
	    file = codecs.open(fname, "w", "utf-8")
	    file.write(subject + "\n")
	    file.write(frommail + "\n")
	    file.write(str(msg))
	    file.close()

	    #md5 = md5sum(fname)

	    #cmd = dir + "/screen2pdf.pl -H " + dir + "/mail/inbox." + str(id)
	    #print cmd
    	    #p = Popen(cmd, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
    	    #html = p.communicate()[0]

	    id = id + 1

            print 'Message %s: %s' % (num, subject)
	    #print md5
	    #print msg
	    #for index in msg:
		#print msg[index]	
    return 0

    for num in data[0].split():
        rv, data = M.fetch(num, '(RFC822)')
        if rv != 'OK':
            print "ERROR getting message", num
            return

	i = 0
	for item in data[0]:
	    i = i + 1
	    print str(i) + ' ' + item

        msg = email.message_from_string(data[0][1])
	#print msg
	#from = str(msg['From'])
	text = msg['Content-Type']
	print text
	return 0
        decode = email.header.decode_header(msg['Subject'])[0]
        subject = unicode(decode[0])
        #print 'Message %s: %s' % (num, subject)
        #print 'Raw Date:', msg['Date']

        # Now convert to local date-time
        date_tuple = email.utils.parsedate_tz(msg['Date'])
        if date_tuple:
            local_date = datetime.datetime.fromtimestamp(
                email.utils.mktime_tz(date_tuple))
            print "Local Date:", \
                local_date.strftime("%a, %d %b %Y %H:%M:%S")


M = imaplib.IMAP4_SSL('imap.gmail.com')

try:
    rv, data = M.login(EMAIL_ACCOUNT, EMAIL_PASS)
except imaplib.IMAP4.error:
    print "LOGIN FAILED!!! "
    sys.exit(1)

print rv, data

rv, mailboxes = M.list()
if rv == 'OK':
    success = 1
else:
    print "Login failed\n"

rv, data = M.select(EMAIL_FOLDER)
if rv == 'OK':
    process_mailbox(M)
    M.close()
else:
    print "ERROR: Unable to open mailbox ", rv

M.logout()

