#!/usr/bin/python

import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email import Encoders
import os
import sys
import ConfigParser

def readconfig(configfile):
        cparser = ConfigParser.RawConfigParser()
        cparser.read(configfile)

        options = {}
        dataoptions = cparser.items( "config" )
        for key, value in dataoptions:
            print key
            options[key] = value

        return options

def mail(to, subject, text, attach):
   msg = MIMEMultipart()

   msg['From'] = gmail_user
   msg['To'] = to
   msg['Subject'] = subject

   msg.attach(MIMEText(text))

   part = MIMEBase('application', 'octet-stream')
   part.set_payload(open(attach, 'rb').read())
   Encoders.encode_base64(part)
   part.add_header('Content-Disposition',
           'attachment; filename="%s"' % os.path.basename(attach))
   msg.attach(part)

   mailServer = smtplib.SMTP("smtp.gmail.com", 587)
   mailServer.ehlo()
   mailServer.starttls()
   mailServer.ehlo()
   mailServer.login(gmail_user, gmail_pwd)
   mailServer.sendmail(gmail_user, to, msg.as_string())
   # Should be mailServer.quit(), but that crashes...
   mailServer.close()

to = str(sys.argv[1])
file = str(sys.argv[2])
cpath = "./config/web2scan.conf"
options = readconfig(cpath)
print options['email_account']
gmail_user = options['email_account']
gmail_pwd = options['email_pass']

title = "PDF"
mail(to,
   title,
   "This is a email sent by Digital Illusion",
   file)
