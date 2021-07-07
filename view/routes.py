from flask import render_template, flash, request, redirect, g
from flask_login import LoginManager, login_required, logout_user, login_user, current_user
from db_oracle.UserLogin import User
from reports.print_result_test import print_result_test
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
        # password = request.form['password']
        if cfg.debug_level > 0:
            print("Login: " + str(username))
        try:
            if username:
                user = User().get_user_by_name(username)
                print("Первая регистрация прошла....")
                if user is not None:
                    print("Повторная регистрация....")
                    login_user(user)
                    print("Зарегистрировались....")
                    global remain_test_sec
                    # remain_test_sec = have_test()
                    remain_test_sec = 10
                    print("Проверяем оставшееся время....")
                    if remain_test_sec and int(remain_test_sec) > 0:
                        print("Идем на тестироавние")
                        return redirect("/testing")
            flash("Пользователь в системе не существует")
            print("Возвращаемся на регистрацию ...")
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
    if cfg.debug_level > 1:
        print("VIEW FINISH. Finish testing show page. Id user: "+str(g.user.id_user)+" : "+g.user.username)
    return render_template("finish.html")


@app.route('/finish/part')
@login_required
def view_finish_part():
    if cfg.debug_level > 3:
        print("VIEW FINISH PART. Finish testing show page. Id user: "+str(g.user.id_user)+" : "+g.user.username)
    mess = finish_part(0)
    if mess == 'Completed':
        return redirect(url_for('view_result'))
    return render_template("finish.html")


@app.route('/testing')
@login_required
def view_test():
    global remain_test_sec
    if cfg.debug_level > 1:
        print("+++ Testing show page. Id user: "+str(g.user.id_user)+" : "+g.user.username + ', remain_time: ' + str(remain_test_sec))
    return render_template("testing.html", remain_time=remain_test_sec, theme=get_theme(), questions=get_quest(), answers=get_answers())


@app.route('/testing/<int:command>')
@login_required
def view_change_question(command):
    if cfg.debug_level > 3:
        print("Change question. Id user: "+str(g.user.id_user)+" : "+str(command))
    global remain_test_sec
    remain_test_sec = navigate_question(command)
    if int(remain_test_sec) == -100:
        return redirect(url_for('view_finish_part'))
    if int(remain_test_sec) < 0:
        finish_force()
        return redirect(url_for('view_result'))
    return redirect(url_for('view_test'))


@app.route('/testing/save/<int:order_num_answer>')
@login_required
def view_save_answer(order_num_answer):
    if cfg.debug_level > 3:
        print("Save answer. Id user: "+str(g.user.id_user)+" : "+str(order_num_answer))
    save_answer(order_num_answer)
    return redirect(url_for('view_change_question', command=3))


@app.route('/result')
@login_required
def view_result():
    id_reg, iin, time_beg, time_end, fio = get_result_info()
    ft_beg = time_beg.strftime('%d.%m.%Y  %H:%M:%S')
    ft_end = time_end.strftime('%d.%m.%Y  %H:%M:%S')
    result_file = print_result_test(id_reg)
    if cfg.debug_level > 1:
        print("+++ VIEW RESULT. Id REG: "+str(id_reg)+" : " + fio + ', remain_time: ' + remain_test_sec)
    return render_template("result.html", result_file=result_file, fio=fio, iin=iin, id_reg=id_reg, time_beg=ft_beg, time_end=ft_end,  cursor=get_result(id_reg))
