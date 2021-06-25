from flask import render_template, flash, request, redirect, g
from flask_login import LoginManager, login_required, logout_user, login_user, current_user
from db_oracle.UserLogin import User
from model.utils import *
from model.testing import *
from main_app import app

import cx_Oracle
import config as cfg

remain_test_sec = 0

if cfg.debug_level > 0:
    print("Routes стартовал...")

@app.route('/about')
def about():
    return render_template("about.html")

@app.route('/', methods=['POST', 'GET'])
def view_models():
    if request.method == "POST":
        username = request.form['username']
        password = request.form['password']
        if cfg.debug_level > 0:
            print("Login: " + str(username)+' : '+str(password))
        try:
            if username:
                user = User().get_user_by_name(username)
                if user is not None:
                    login_user(user)
                    global remain_test_sec
                    remain_test_sec = have_test()
                    if remain_test_sec and int(remain_test_sec) > 0:
                        return redirect("/testing")
            flash("Пользователь в системе не существует")
            return redirect("/")
        except cx_Oracle.IntegrityError as e:
            errorObj, = e.args
            print("Error Code:", errorObj.code)
            print("Error Message:", errorObj.message)
            print("Ошибка при регистрации в системе "+str(username))
            return redirect("/")
    return render_template("login_page.html")


@app.route('/finish')
@login_required
def view_finish():
    if cfg.debug_level > 3:
        print("Finish testing show page. Id user: "+str(g.user.id_user)+" : "+g.user.username)
    return render_template("finish.html")


@app.route('/finish/part')
@login_required
def view_finish_part():
    if cfg.debug_level > 3:
        print("Finish testing show page. Id user: "+str(g.user.id_user)+" : "+g.user.username)
    mess = finish_part()
    if mess == 'Completed':
        return redirect("/")
    return render_template("finish.html")


@app.route('/testing')
@login_required
def view_test():
    global remain_test_sec
    if cfg.debug_level > 1:
        print("+++ Testing show page. Id user: "+str(g.user.id_user)+" : "+g.user.username + ', remain_time: ' + remain_test_sec)
    return render_template("testing.html", remain_time=remain_test_sec, theme=get_theme(), questions=get_quest(), answers=get_answers())


@app.route('/testing/<int:command>')
@login_required
def view_change_question(command):
    if cfg.debug_level > 3:
        print("Change question. Id user: "+str(g.user.id_user)+" : "+str(command))
    global remain_test_sec
    remain_test_sec = navigate_question(command)
    if int(remain_test_sec) <= 0:
        return redirect("/finish")
    return redirect("/testing")


@app.route('/testing/save/<int:order_num_answer>')
@login_required
def view_save_answer(order_num_answer):
    if cfg.debug_level > 3:
        print("Save answer. Id user: "+str(g.user.id_user)+" : "+str(order_num_answer))
    save_answer(order_num_answer)
    return redirect("/testing/3")
