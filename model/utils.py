from main_app import app
from view.i18n import I18N
from db_oracle.connect import get_connection
from flask import send_from_directory, session, redirect, url_for, request
import config as cfg

i18n = I18N()

@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    if cfg.debug_level > 0:
        print("file for upload: "+cfg.REPORTS_PATH + filename)
    return send_from_directory(cfg.REPORTS_PATH, filename)


@app.route('/language/<string:lang>')
def set_language(lang):
    if cfg.debug_level > 0:
        print("Set code language: " + lang + ', предыдущий язык: '+session['language'])
    session['language'] = lang
    # Получим предыдущую страницу, чтобы на неё вернуться
    current_page = request.referrer
    if cfg.debug_level > 1:
        print("Set code language current_page: " + str(current_page))
    if current_page is not None:
        return redirect(current_page)
    else:
        return redirect(url_for('view_models'))


@app.context_processor
def utility_processor():
    if cfg.debug_level > 1:
        print("Context processor: " + get_i18n_value('APP_NAME'))
    return dict(res_value=get_i18n_value)


def get_i18n_value(res_name):
    try:
        lang = session['language']
    except KeyError:
        lang = cfg.language
        session['language'] = lang
    if cfg.debug_level > 3:
        print('Get i18N request: ' + str(lang) + ' : ' + str(res_name))
    if cfg.src_lang == 'db':
        con = get_connection()
        cursor = con.cursor()
        return_value = cursor.callfunc("i18n.get_value", str, [code, res_name])
        cursor.close()
        con.close()
    if cfg.src_lang == 'file':
        return_value = i18n.get_resource(lang, res_name)
        # if lang == 'ru':
        #     file = open('i18n.'+lang, "r")
        #     read = file.read()
        #
        #     for line in read.splitlines():
        #         if res_name in line:
        #             return_value = line.split('=', 1)[1]
        #     file.close()
    if cfg.debug_level > 3:
        print('Get i18N request value: ' + return_value)
    return return_value

