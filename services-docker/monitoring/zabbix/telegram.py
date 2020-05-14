#!/usr/bin/env python

import telebot,sys

BOT_TOKEN='864218369:AAELCFsOI-GFVZvph0_JN8ZCPnLzyC2hb3w'
DESTINATION=sys.argv[1]
SUBJECT=sys.argv[2]
MESSAGE=sys.argv[3]

MESSAGE = MESSAGE.replace('/n','\n')
tb = telebot.TeleBot(BOT_TOKEN)
tb.send_message(DESTINATION,SUBJECT + '\n' + MESSAGE)