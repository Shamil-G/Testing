create or replace package admin is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 23.06.2021 17:37:04
  -- Purpose : 
  
  -- Public type declarations
  function add_question( iid_theme in number, iorder_num in number, iquestion in nvarchar2) return varchar2;
  procedure add_test(iid_person in number, iid_task in number);  

end admin;
/
create or replace package body admin is

  function add_question( iid_theme in number, iorder_num in number, iquestion in nvarchar2)
           return varchar2
  is
    id pls_integer;
  begin
    id := seq_quest.nextval;
    insert into questions q (id_question, id_theme, active, order_num_question, question)
           values ( id, iid_theme, 'Y', iorder_num, iquestion);
    return id;
  end;
  
  procedure add_test(iid_person in number, iid_task in number)
  is
    v_id_registration pls_integer;
    random_number     pls_integer;
    random_size       pls_integer;
    target_size       pls_integer;
    order_number      pls_integer;
    l_seed            VARCHAR2(100);
    v_id_question     questions.id_question%type;
    v_id_answer       answers.id_answer%type;
    
    type id_question_table is table of questions.id_question%type index by pls_integer;
    input_array_questions id_question_table;    

    type id_answer_table is table of answers.id_answer%type index by pls_integer;
    input_array_answers id_answer_table;    
  begin
    v_id_registration:=seq_registration.nextval;
--  Подготовим таблицу учета прохождения тем     
    for cur in ( select * from bundle_themes bt where bt.id_task=iid_task)
    loop
      insert into themes_for_testing(id_registration, id_theme, theme_number, count_question, 
                                     count_success, period_for_testing, 
                                     scores, used_time, status_testing)
      values ( v_id_registration, cur.id_theme, cur.theme_number, cur.count_question, cur.count_success, cur.period_for_testing,
               0, 0, 0);
    end loop;

/* Загрузим вопросы для каждой темы */
    for cur in ( select * from themes_for_testing tt where tt.id_registration=v_id_registration)
    loop
        select q.id_question
        bulk collect into input_array_questions
        from questions q
        where q.id_theme=cur.id_theme
        and   q.active='Y';
        
        random_size:=input_array_questions.count;
        if random_size=0 THEN return; end if;
        target_size := cur.count_question;
        
        order_number:=0;
        l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF');
        DBMS_RANDOM.seed (val => l_seed);

        while order_number<target_size
        loop
          select dbms_random.value(1,random_size) into random_number from dual;
          if input_array_questions.exists(random_number)
          then
             v_id_question:=input_array_questions(random_number);
             input_array_questions.delete(random_number);
             order_number:=order_number+1;

             insert into questions_for_testing( id_question_for_testing, 
                         id_registration, id_theme, 
                         order_num_question, id_question, 
                         id_answer, time_reply)
             values( seq_question_testing.nextval, 
                     v_id_registration, cur.id_theme, order_number, v_id_question, null, null);
          end if;
        end loop;
    end loop;
        
/* Загрузим варианты ответов  */
--/*
    for cur in ( select * from questions_for_testing qt where qt.id_registration=v_id_registration order by qt.id_theme, qt.order_num_question )
    loop
        select a.id_answer
        bulk collect into input_array_answers
        from answers a
        where a.id_question=cur.id_question
        and   a.active='Y';
        
        random_size:=input_array_answers.count;
        if random_size=0 THEN return; end if;
        target_size := random_size;
        
        order_number:=0;
        l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF');
        DBMS_RANDOM.seed (val => l_seed);

        while order_number<target_size
        loop
          select dbms_random.value(1,random_size) into random_number from dual;
          if input_array_answers.exists(random_number)
          then
             v_id_answer:=input_array_answers(random_number);
             input_array_answers.delete(random_number);
             order_number:=order_number+1;

             insert into answers_in_testing( id_question_for_testing, 
                         id_answer, 
                         order_num_answer,
                         selected)
             values( cur.id_question_for_testing,
                     v_id_answer, 
                     order_number, '');
          end if;
        end loop;
    end loop;
    
    insert into testing(id_registration, id_person, category, id_organization, date_registration, 
                id_pc, id_current_theme, current_num_question, language, date_testing, beg_time_testing,
                end_time_testing, last_time_access, end_day_testing, key_access, signature, status, status_testing )
           values( v_id_registration, iid_person, '', 1, sysdate, 0, 
                   (select id_theme from bundle_themes bt where bt.id_task=iid_task and theme_number=1 ),
                   1, '', sysdate, null, null, null, null, null, null, 'Active', 'Готов к тестированию' );
                   
    commit;
--*/        
            
  end;

begin
  -- Initialization
  null;
end admin;
/
