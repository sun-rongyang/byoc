#*****************************
# Send an email to users
# usage: python send_email.py SERVER PASSWORD FROM TO[list file] MESSAGE [SUBJECT]
# usage: python send_email.py ${MailServer} "${MailPassword}" ${FROM} ${TO} "${MESSAGE}" "${SUBJECT}" "${MailSignature}"
#*****************************

## Import packages
import smtplib
import sys
import os

## Define some funcitons
# Send the mail
def send_mail(SERVER, PASSWORD, FROM, TO, message):
    """
    Send a  mail to a list of email addresses
    :TO: a list of email addresses
    :message: formatted message you want to send
    """
    server = smtplib.SMTP(SERVER, 587)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(FROM, PASSWORD)
    server.sendmail(FROM, TO, message)
    server.quit()

## Arguments
SERVER = sys.argv[1]
PASSWORD = sys.argv[2]
FROM = sys.argv[3]
TO = []
if os.path.isfile(sys.argv[4]):
    with open(sys.argv[4]) as file_obj:
        for line in file_obj:
            user_name, user_mail_address = line.split(' ')
            user_mail_address = user_mail_address[:-1] #remove '\n' at tail
            TO.append(user_mail_address)
else:
    TO.append(sys.argv[4])
if os.path.isfile(sys.argv[5]):
    with open(sys.argv[5]) as file_obj:
        TEXT = file_obj.read()
else:
    TEXT = sys.argv[5]
SUBJECT = sys.argv[6]
SIGNATURE = sys.argv[7]

## Generate mail text
TEXT += SIGNATURE
# Prepare actual message
message = """From: %s\r\nTo: %s\r\nSubject: %s\r\n\

%s
""" % (FROM, ", ".join(TO), SUBJECT, TEXT)

## Send the email
send_mail(SERVER, PASSWORD, FROM, TO, message)
