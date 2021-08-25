from model.testing import get_result, get_result_info
import config as cfg
import xlsxwriter
import datetime
import os.path
#import win32api
#import win32print
from datetime import date, timedelta

module_result_path = ''


def print_result_test(id_registration):
    print('++++ print_result_test: ' + str(id_registration))
    now = datetime.datetime.now()
    # today = datetime.date.today()
    id_reg, iin, time_beg, time_end, fio = get_result_info(id_registration)

    if iin is None:
        return ''

    file_name = 'result ' + str(id_reg) + '.xlsx'
    if not module_result_path:
        file_path = cfg.REPORTS_PATH + file_name
    else:
        file_path = module_result_path + file_name

    if os.path.isfile(file_path):
        return file_name

    workbook = xlsxwriter.Workbook(file_path)
    worksheet = workbook.add_worksheet()
    worksheet.set_column(0, 0, 1)
    worksheet.set_column(1, 1, 5)
    worksheet.set_column(2, 2, 22)
    worksheet.set_column(3, 3, 16)
    worksheet.set_column(4, 4, 10)
    worksheet.set_column(5, 5, 8)
    worksheet.set_column(6, 6, 10)
    worksheet.set_column(7, 7, 8)

    cursor = get_result(id_registration)

    # print("Провели расчет и формируем Excel: " + datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S"))

    title1_cell_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'size': 18})
    worksheet.merge_range('B1:H1', "", title1_cell_format)
    worksheet.set_row(0, 32)
    worksheet.set_row(1, 24)
    worksheet.set_row(2, 16)

    title2_cell_format = workbook.add_format({'align': 'left', 'bold': True, 'valign': 'vcenter', 'size': 14, 'underline': True})
    title3_cell_format = workbook.add_format({'align': 'left', 'bold': True, 'valign': 'vcenter', 'size': 12})
    title3_1_cell_format = workbook.add_format({'align': 'left', 'valign': 'vcenter', 'size': 12})
    theme_name_format = workbook.add_format({'align': 'left', 'valign': 'vcenter', 'border': 1, 'text_wrap': True})

    worksheet.merge_range('B2:H2', "", title2_cell_format)
    worksheet.merge_range('B5:C5', "", title3_cell_format)
    worksheet.merge_range('B6:C6', "", title3_cell_format)
    worksheet.merge_range('C8:D8', "", theme_name_format)

    common_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'border': 1})
    common_format.set_text_wrap()
    common_format_2 = workbook.add_format({'align': 'center', 'bold': True, 'border': 1})
    common_format_2.set_align('vcenter')
    common_format_2.set_text_wrap()
    sum_pay_format = workbook.add_format({'num_format': '#,###,##0.00', 'font_color': 'black', 'align': 'vcenter'})
    # date_format = workbook.add_format({'num_format':'dd/mm/yy', 'align': 'vcenter'})

    worksheet.write('B1', 'РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ', title1_cell_format)
    worksheet.write('B2', fio, title2_cell_format)
    worksheet.write('B3', 'Ид:', title3_cell_format)
    worksheet.write('C3', id_reg, title3_1_cell_format)
    worksheet.write('B4', 'ИИН:', title3_cell_format)
    worksheet.write('C4', iin, title3_1_cell_format)

    ft_beg = time_beg.strftime('%d.%m.%Y  %H:%M:%S')
    ft_end = time_end.strftime('%d.%m.%Y  %H:%M:%S')

    worksheet.write('B5', 'Начало тестирования:', title3_cell_format)
    worksheet.write('D5', ft_beg, title3_1_cell_format)
    worksheet.write('B6', 'Окончание тестирования:', title3_cell_format)
    worksheet.write('D6', ft_end, title3_1_cell_format)

    worksheet.write('B8', '№', common_format_2)
    worksheet.write('C8', 'Задание', common_format_2)
    worksheet.write('E8', 'Вопросов', common_format_2)
    # worksheet.write('F8', 'Порог', common_format_2)
    # worksheet.write('G8', 'Верных ответов', common_format_2)
    # worksheet.write('H8', 'Ошибок', common_format_2)
    worksheet.write('F8', 'Верных ответов', common_format_2)
    worksheet.write('G8', 'Ошибок', common_format_2)
    row = 0
    for record in cursor:
        merge_format = 'C'+str(row+8+1)+':D'+str(row+8+1) + ''

        worksheet.merge_range(merge_format, "", theme_name_format)
        if record.theme_number != 100:
            worksheet.write(row + 8, 1, record.theme_number, common_format)
        else:
            worksheet.write(row + 8, 1, None, common_format)
        worksheet.write(row + 8, 2, record.theme_name, theme_name_format)
        worksheet.write(row + 8, 4, record.count_question, common_format)
        # worksheet.write(row + 8, 5, record.count_success, common_format)
        # worksheet.write(row + 8, 6, record.true_score, common_format)
        # worksheet.write(row + 8, 7, record.false_score, common_format)
        worksheet.write(row + 8, 5, record.true_score, common_format)
        worksheet.write(row + 8, 6, record.false_score, common_format)
        row += 1

    worksheet.write(row + 8 + 1, 1, now.strftime("%d.%m.%Y %H:%M:%S"))
    workbook.close()

    # print("Завершен расчет: " + datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S"))
    if cfg.print_at_once:
       None
#        my_printer = win32print.GetDefaultPrinter()
#        win32api.ShellExecute(
#            0,
#            "print",
#            file_name,
#            my_printer,
#            ".",
#            0
#        )
    return file_name


if __name__ == "__main__":
    module_result_path = './'
    my_id_reg = 1022
    print('Testing app Print Result for: ' + str(my_id_reg))
    print_result_test(my_id_reg)
