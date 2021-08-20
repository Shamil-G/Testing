from flask import send_from_directory, session, redirect, url_for, request, g
from db_oracle.connect import get_connection
import cx_Oracle
import config as cfg


class QuestionF(object):
    def __init__(self, order_num_question, question):
        self.order_num = order_num_question
        self.question = question


class AnswerF(object):
    def __init__(self, order_num_answer, selected, answer):
        self.order_num_answer = order_num_answer
        self.selected = selected
        self.answer = answer


class ResultF(object):
    def __init__(self, theme_number, theme_name, count_question, count_success, true_score, false_score):
        self.theme_number = theme_number
        self.theme_name = theme_name
        self.count_question = count_question
        self.count_success = count_success
        self.true_score = true_score
        self.false_score = false_score


def have_test():
    if cfg.debug_level > 2:
        print('Check have test for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    mess = cursor.callfunc("test.have_test", str, [g.user.id_user])
    cursor.close()
    con.close()
    return mess


def get_theme():
    if cfg.debug_level > 2:
        print('Get questions for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    theme = cursor.callfunc("test.get_theme", str, [g.user.id_user])
    if cfg.debug_level > 3:
        print("Got theme: " + theme)
    cursor.close()
    con.close()
    return theme


def navigate_question(command):
    if cfg.debug_level > 2:
        print('1. Navigate Guestion: command: ' + str(command) + ' : ' + str(g.user.username)  )
    con = get_connection()
    cursor = con.cursor()
    remain_time = cursor.callfunc("test.navigate_question", str, [g.user.id_user, command])
    if cfg.debug_level > 3 and remain_time:
        print("Remain time: " + str(remain_time))
    cursor.close()
    con.close()
    return remain_time


def finish_info():
    if cfg.debug_level > 2:
        print('1. FINISH PART. command: ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    mess = cursor.callfunc("test.finish_info", str, [g.user.id_user])
    if cfg.debug_level > 3 and mess:
        print("Having unanswered question: " + mess)
    cursor.close()
    con.close()
    return mess


def finish():
    if cfg.debug_level > 2:
        print('1. TESTING FINISHED. command: ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc("test.finish", [g.user.id_user])
    cursor.close()
    con.close()


def save_answer(order_num_question):
    if cfg.debug_level > 2:
        print('1. Navigate Guestion: order_num_question: ' + str(order_num_question) + ' : ' + str(g.user.username)  )
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc("test.set_answer", [g.user.id_user, order_num_question])
    cursor.close()
    con.close()
    return


def get_quest():
    if cfg.debug_level > 2:
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
    if cfg.debug_level > 2:
        print('Get answer for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    cmd = "select aft.order_num_answer, " \
          "case when coalesce(q.id_answer,0)=aft.id_answer then 'Y' else 'N' end as selected, " \
          "a.answer " \
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


def get_result_info():
    if cfg.debug_level > 2:
        print('Get Result Info: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    id_reg = cursor.var(cx_Oracle.DB_TYPE_NUMBER)
    iin = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
    time_beg = cursor.var(cx_Oracle.DB_TYPE_DATE)
    time_end = cursor.var(cx_Oracle.DB_TYPE_DATE)
    fio = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
    cursor.callproc('test.get_personal_info', (g.user.id_user, id_reg, iin, time_beg, time_end, fio))
    print('Got result info ' + fio.getvalue() + ', time_end: ' + str(time_end.getvalue()))
    return id_reg.getvalue(), iin.getvalue(), time_beg.getvalue(), time_end.getvalue(), fio.getvalue()


def get_result(id_registration):
    if cfg.debug_level > 2:
        print('Get answer for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select theme_number, descr as theme_name, count_question, count_success, ' \
          'sum(true_result) true_score, sum(false_result) false_score ' \
          'from ( ' \
          'select th.id_theme, theme_number, th.descr, tft.count_question, tft.count_success, ' \
          'case when correctly=\'Y\' then 1 else 0 end true_result, ' \
          'case when correctly != \'Y\' then 1 else 0 end false_result ' \
          'from questions_for_testing qft, answers a, ' \
          'themes_for_testing tft, themes th ' \
          'where qft.id_registration=tft.id_registration ' \
          'and qft.id_theme=th.id_theme ' \
          'and a.id_answer(+) = qft.id_answer ' \
          'and tft.id_registration = :id ' \
          'and tft.id_theme = th.id_theme ' \
          ') ' \
          'group by theme_number, count_question, count_success, descr'
    cursor.execute(cmd, [id_registration])
    cursor.rowfactory = ResultF
    return cursor
