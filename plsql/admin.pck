create or replace package admin is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 23.06.2021 17:37:04
  -- Purpose : 
  
  -- Public type declarations
  function add_question( iid_theme in number, iorder_num in number, iquestion in nvarchar2) return varchar2;
  procedure add_test(iid_person in number, iid_task in number);  
  procedure program_add(iperiod_for_testing in number, iname_task in nvarchar2);
  procedure program_upd(iid_task in number, iperiod_for_testing in number, iname_task in nvarchar2);
  procedure program_delete(iid_task in number);
  function get_name_program(iid_task in number) return nvarchar2;
  function theme_new(iid_task in number, theme_name in nvarchar2) return pls_integer;
  procedure theme_update(iid_task in number, iid_theme in number, itheme_name in varchar2, itheme_number in number, 
            icount_question in number, icount_success in number );
  procedure theme_delete(iid_theme in number);
  procedure load_person(iid_task in number, iiin in varchar2, ifio in nvarchar2, idepart in nvarchar2);
  procedure clean_all;

end admin;
/
create or replace package body admin is

  procedure log(imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into protocol(event_date, message) values(systimestamp, imess);
    commit;
  end;
    
  function add_question( iid_theme in number, iorder_num in number, iquestion in nvarchar2)
           return varchar2
  is
    id pls_integer;
  begin
    id := seq_quest.nextval;
    insert into questions q (id_question, id_theme, order_num_question, question)
           values ( id, iid_theme, iorder_num, iquestion);
    return id;
  end;

  function get_name_program(iid_task in number) return nvarchar2
  is
    v_name_task tasks.name_task%type;
  begin
    select t.name_task into v_name_task from tasks t where t.id_task=iid_task;
    return v_name_task;
  end; 
    
  procedure program_add(iperiod_for_testing in number, iname_task in nvarchar2)
  is
    max_id_task pls_integer;
  begin
    select max(id_task) into max_id_task from tasks t;
    insert into tasks(id_task, period_for_testing, name_task) values(max_id_task+1, iperiod_for_testing, iname_task);
    commit;
  end; 

  procedure program_upd(iid_task in number, iperiod_for_testing in number, iname_task in nvarchar2)
  is
  begin
    update tasks t
    set    t.period_for_testing=iperiod_for_testing,
           t.name_task=iname_task
    where  t.id_task=iid_task;
    commit;
  end; 

  procedure program_delete(iid_task in number)
  is
  begin
    for cur in (select bt.id_theme from bundle_themes bt where bt.id_task=iid_task)
    loop
      theme_delete(cur.id_theme);
    end loop;
    delete from tasks t where t.id_task=iid_task;
    commit;
  end; 
  
  function theme_new(iid_task in number, theme_name in nvarchar2) return pls_integer
  is
    v_id_theme pls_integer;
    v_num_theme pls_integer;
  begin
    select max(id_theme) into v_id_theme from themes t;
    v_id_theme := coalesce(v_id_theme, 0)+1;
    select count(id_theme) into v_num_theme from bundle_themes t where t.id_task=iid_task;
    
    insert into themes(id_theme, descr) values(v_id_theme, theme_name);
    insert into bundle_themes(id_task, id_theme, theme_number, count_question, count_success)
                values(iid_task, v_id_theme, v_num_theme+1, 0, 0);
    commit;
    return v_id_theme;                 
  end;
  
  procedure theme_update(iid_task in number, iid_theme in number, itheme_name in varchar2, 
            itheme_number in number, 
            icount_question in number , icount_success  in number )
  is
  begin
    update bundle_themes bt
    set    bt.theme_number=itheme_number,
           bt.count_question=icount_question,
           bt.count_success=icount_success
    where  bt.id_task=iid_task
    and    bt.id_theme=iid_theme;
    
    update themes t
    set    t.descr=itheme_name
    where  t.id_theme=iid_theme;
    commit;
  end;
  

  procedure theme_delete(iid_theme in number)
  is
    v_exist_testing pls_integer default 0;
  begin
    select count(id_theme) into v_exist_testing
    from themes_for_testing tft
    where tft.id_theme=iid_theme
    and rownum=1;

    log('1. THEME DELETE. count used theme: '||v_exist_testing||', id_theme: '||iid_theme);
    
    if v_exist_testing=0 then
       log('2. THEME DELETE. delete from answers. id_theme: '||iid_theme);
       delete from answers a
       where a.id_question in ( select id_question from questions q where q.id_theme=iid_theme);
       
       log('3. THEME DELETE. delete from questions. id_theme: '||iid_theme);
       delete from questions q where q.id_theme=iid_theme;

       log('3. THEME DELETE. delete from themes_for_testing. id_theme: '||iid_theme);
       delete from themes_for_testing tft where tft.id_theme=iid_theme;
    end if;
    
    log('4. THEME DELETE. delete from bundle_themes. id_theme: '||iid_theme);
    delete from bundle_themes bt where bt.id_theme=iid_theme;
    log('5. THEME DELETE. delete from themes. id_theme: '||iid_theme);
    delete from themes t where t.id_theme=iid_theme;
    commit;
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
    v_count_registr   pls_integer;
    
    type id_question_table is table of questions.id_question%type index by pls_integer;
    input_array_questions id_question_table;    

    type id_answer_table is table of answers.id_answer%type index by pls_integer;
    input_array_answers id_answer_table;    
  begin
    /* Проверим наличие регистрации на тестирование */
    select count(id_registration) into v_count_registr 
    from testing t 
    where t.status='Active' 
    and t.id_person=iid_person
    and t.status_testing!='Completed';
    
    if v_count_registr>0 then
       log('ADD TEST. Person with id_person:  '||iid_person||' has an outstanding task');
      return;
    end if;
    
    v_id_registration:=seq_registration.nextval;
    log('ADD TEST. Person id_person:  '||iid_person||' got id_registration: '||v_id_registration);
--  Подготовим таблицу учета прохождения тем     
    for cur in ( select bt.* 
                 from bundle_themes bt
                 where bt.id_task=iid_task)
    loop
      insert into themes_for_testing(id_registration, id_theme, theme_number, count_question, 
                                     count_success, scores, used_time, status_testing)
      values ( v_id_registration, cur.id_theme, cur.theme_number, cur.count_question, cur.count_success,
               0, 0, 0);
    end loop;

    log('ADD TEST. Themes for testing loaded. Person id_person:  '||iid_person||', id_registration: '||v_id_registration);
/* Загрузим вопросы для каждой темы */
    for cur in ( select * from themes_for_testing tt where tt.id_registration=v_id_registration)
    loop
        select q.id_question
        bulk collect into input_array_questions
        from questions q
        where q.id_theme=cur.id_theme;
        
        random_size:=input_array_questions.count;
        if random_size=0 THEN 
           log('ADD TEST. THEME with id_theme: '||cur.id_theme||' has an outstanding questions');
           return; 
        end if;
        target_size := cur.count_question;
        
        order_number:=0;
        l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF');
        DBMS_RANDOM.seed (val => l_seed);

        while order_number<target_size and target_size<=random_size
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
                     v_id_registration, cur.id_theme, order_number, v_id_question, 0, null);
          end if;
        end loop;
    end loop;
        
    log('ADD TEST. Question for testing loaded. Person id_person:  '||iid_person||', id_registration: '||v_id_registration);
/* Загрузим варианты ответов  */
--/*
    for cur in ( select * from questions_for_testing qt where qt.id_registration=v_id_registration order by qt.id_theme, qt.order_num_question )
    loop
        select a.id_answer
        bulk collect into input_array_answers
        from answers a
        where a.id_question=cur.id_question;
        
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
                         order_num_answer)
             values( cur.id_question_for_testing,
                     v_id_answer, 
                     order_number);
          end if;
        end loop;
    end loop;

    log('ADD TEST. Answers in testing loaded. Person id_person:  '||iid_person||', id_registration: '||v_id_registration);
    /* Отправим в архив предыдущие тестирования */
    update testing t
    set    t.status='Archived'
    where  t.id_person=iid_person;
    /* Добавми новое тестирование */    
    insert into testing(id_registration, id_person, category, id_organization, date_registration, 
                id_pc, id_current_theme, current_num_question, language, date_testing, period_for_testing,
                beg_time_testing, end_time_testing, last_time_access, end_day_testing, 
                key_access, signature, status, status_testing )
           values( v_id_registration, iid_person, '', 1, sysdate, 0, 
                   (select id_theme from bundle_themes bt where bt.id_task=iid_task and theme_number=1 ),
                   1, '', sysdate, 
                   (select period_for_testing from tasks t where t.id_task=iid_task ),
                   null, null, null, null, null, null, 'Active', 'Готов к тестированию' );
    commit;
     
  end;

  procedure load_person(iid_task in number, iiin in varchar2, ifio in nvarchar2, idepart in nvarchar2)
  is
    v_id_person persons.id_person%type;
  begin
    log('1. Load Person: '||iiin||' : '||ifio);

    if iiin is null then return; end if;
    if ifio is null then return; end if;

    log('2. Load Person: '||iiin||' : '||ifio);

    select p.id_person into v_id_person from persons p where p.iin=iiin;
    add_test(iid_person => v_id_person, iid_task =>iid_task );
    exception when no_data_found then 
      begin
        select coalesce(max(id_person),0) into v_id_person from persons;
        log('Insert new Person: '||iiin||' : '||ifio);
        insert into persons(id_person, iin, fio, depart) values(v_id_person+1, iiin, ifio, idepart);
        commit;
        add_test(iid_person => v_id_person+1, iid_task =>iid_task );
      end;
  end;
  
  procedure clean_all
  is
  begin
    delete from testing;
    delete from answers_in_testing;
    delete from questions_for_testing;
    delete from themes_for_testing;
    commit;
  end;

begin
  -- Initialization
  null;
end admin;
/
