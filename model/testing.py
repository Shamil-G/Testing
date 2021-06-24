from flask import send_from_directory, session, redirect, url_for, request, g
from db_oracle.connect import get_connection
import config as cfg


class QuestionF(object):
    def __init__(self, order_num_question, question):
        self.order_num = order_num_question
        self.question = question


class AnswerF(object):
    def __init__(self, id_answer, answer):
        self.id = id_answer
        self.answer = answer


def get_theme():
    if cfg.debug_level > 1:
        print('Get questions for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    theme = cursor.callfunc("test.get_theme", str, [g.user.id_user])
    print("Got theme: " + theme)
    cursor.close()
    con.close()
    return theme


def get_quest():
    if cfg.debug_level > 1:
        print('Get questions for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select qft.order_num_question, q.question ' \
          'from questions q, ' \
          'questions_for_testing qft, ' \
          'testing t ' \
          'where qft.id_question=q.id_question ' \
          'and qft.id_registration=t.id_registration ' \
          'and q.id_theme=t.id_current_theme ' \
          'and qft.order_num_question=t.current_num_question ' \
          'and t.status=\'Active\' ' \
          'and t.id_person='+str(g.user.id_user)
    cursor.execute(cmd)
    cursor.rowfactory = QuestionF
    return cursor


def get_answers():
    if cfg.debug_level > 1:
        print('Get answer for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    cmd = "select a.id_answer, a.answer " \
          "from answers a, answers_in_testing aft, " \
          "testing t, questions_for_testing q " \
          "where a.id_question=q.id_question " \
          "and aft.id_answer=a.id_answer " \
          "and aft.id_question_for_testing=q.id_question_for_testing " \
          "and q.id_registration=t.id_registration " \
          "and q.id_theme=t.id_current_theme " \
          "and q.order_num_question=t.current_num_question " \
          "and t.status='Active' " \
          "and t.id_person="+str(g.user.id_user)+" " \
          "order by aft.order_num_answer"
    cursor.execute(cmd)
    cursor.rowfactory = AnswerF
    return cursor
