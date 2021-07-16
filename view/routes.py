from flask import render_template, flash, request, redirect, g
from flask_login import LoginManager, login_required, logout_user, login_user, current_user
from db_oracle.UserLogin import User
from reports.print_result_test import print_result_test
from model.utils import *
from model.testing import *
from main_app import app

import cx_Oracle
import config as cfg


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
                if cfg.debug_level > 2:
                    print("Первая регистрация прошла....")
                if user is not None:
                    if cfg.debug_level > 2:
                        print("Повторная регистрация....")
                    login_user(user)
                    if user.remain_time and user.remain_time > 0:
                        if cfg.debug_level > 2:
                            print("Идем на тестирование")
                        return redirect("/testing")
                    if user.remain_time and user.remain_time <= 0:
                        if cfg.debug_level > 2:
                            print("!!!!  Тестирование завершено")
                        return redirect("/result")
            flash("Пользователь в системе не существует")
            print("Пользователь в системе не существует. Возвращаемся на регистрацию ...")
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
    mess = finish_info()
    if mess != '':
        flash(mess)
    #     return redirect(url_for('view_result'))
    return render_template("finish.html")


@app.route('/testing')
@login_required
def view_test():
    if cfg.debug_level > 3:
        print("+++ Testing show page. Id user: "+str(g.user.id_user)+" : "+g.user.username + ', remain_time: ' + str(g.user.remain_time))
    if g.user.remain_time == 0:
        return redirect(url_for('view_result'))
    return render_template("testing.html", remain_time=g.user.remain_time, theme=get_theme(), questions=get_quest(), answers=get_answers())


@app.route('/testing/<int:command>')
@login_required
def view_change_question(command):
    g.user.remain_time = navigate_question(command)
    if cfg.debug_level > 3:
        print("Change question. Id user: "+str(g.user.id_user)+" : "+str(command) + ', remain_time: ' + str(g.user.remain_time))
    # Время истекло полностью на все темы
    if int(g.user.remain_time) == 0:
        return redirect(url_for('view_result'))
    # Закончилась одна тема
    if int(g.user.remain_time) == -100:
        return redirect(url_for('view_finish_part'))
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
    finish()
    id_reg, iin, time_beg, time_end, fio = get_result_info()
    ft_beg = time_beg.strftime('%d.%m.%Y  %H:%M:%S')
    ft_end = time_end.strftime('%d.%m.%Y  %H:%M:%S')
    result_file = print_result_test(id_reg)
    if cfg.debug_level > 1:
        print("+++ VIEW RESULT. Id REG: "+str(id_reg)+" : " + fio + ', remain_time: ' + str(ft_end))
    return render_template("result.html", result_file=result_file, fio=fio, iin=iin, id_reg=id_reg, time_beg=ft_beg, time_end=ft_end,  cursor=get_result(id_reg))
