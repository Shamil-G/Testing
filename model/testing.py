from flask import send_from_directory, session, redirect, url_for, request, g
from db_oracle.connect import get_connection
import config as cfg


def get_theme():
    if cfg.debug_level > 1:
        print('Get questions for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    theme = cursor.callfunc("testing.get_theme", str, [g.user.id_user])
    print("Got theme: "+theme)
    cursor.close()
    con.close()
    return theme


def get_quest():
    if cfg.debug_level > 1:
        print('Get questions for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    question = cursor.callfunc("testing.get_question", str, [g.user.id_user])
    print("Got question: "+question)
    cursor.close()
    con.close()
    return question
