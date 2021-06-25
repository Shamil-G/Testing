create or replace package test is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 22.06.2021 16:13:21
  -- Purpose : Процедура тестирования
  
  -- Public type declarations
  function get_theme(iid_person in number) return nvarchar2;
  function navigate_question(iid_person in number, icommand in number)
    return nvarchar2;
  procedure set_answer(iid_person in number, iorder_num_answer in number);

  
  function get_question(iid_person in number) return nvarchar2;

end test;
/
create or replace package body test is

  function get_theme(iid_person in number) return nvarchar2
  is
  omess nvarchar2(128);
  begin
    select th.descr
    into omess
    from themes th, 
         testing t
    where th.id_theme=t.id_current_theme
    and t.status='Active'
    and t.id_person=iid_person;
    
    return omess;
  end;
  
  procedure set_answer(iid_person in number, iorder_num_answer in number)
  is
    v_question_for_testing questions_for_testing.id_question_for_testing%type;
  begin

    select q.id_question_for_testing
          into v_question_for_testing
    from testing t, questions_for_testing q
    where q.id_registration=t.id_registration
    and q.id_theme=t.id_current_theme
    and q.order_num_question=t.current_num_question
    and t.status='Active'
    and t.id_person=id_person;
          
    update answers_in_testing at
    set at.selected=''
    where at.id_question_for_testing=v_question_for_testing;
         
    update answers_in_testing at
    set at.selected='y'
    where at.id_question_for_testing=v_question_for_testing
    and   at.order_num_answer=iorder_num_answer;

    insert into protocol(event_date,message) 
           values(SYSTIMESTAMP, 'Сохраняем результат, id_person: '||iid_person||', num_answer: '||iorder_num_answer||', question_for_testing: '||v_question_for_testing);
    commit;
  end;
  
  function navigate_question(iid_person in number, icommand in number)
    return nvarchar2
  is
   v_count_question pls_integer;
   v_cur_num_question pls_integer;
  begin
--    insert into protocol(event_date,message) values(SYSTIMESTAMP, 'ПОлучена команда '|| icommand|| ', id_person: '||iid_person);
--    commit;
    /* Идем в начало*/
    if icommand=0 then
       update testing t
       set    t.current_num_question=1
       where  t.status='Active'       
       and    t.id_person=iid_person;
       commit;
       return '';
    end if;

    /*Вытащим общее количество вопросов*/
     select tft.count_question, t.current_num_question 
            into v_count_question, v_cur_num_question
     from themes_for_testing tft, testing t
     where tft.id_registration=t.id_registration
     and   tft.id_theme=t.id_current_theme
     and   t.status='Active'       
     and   t.id_person=iid_person;
    /* Идем в конец*/
    if icommand=4 then
       update testing t
       set    t.current_num_question=v_count_question
       where  t.status='Active'       
       and    t.id_person=iid_person;
       commit;
       return '';
    end if;
    if icommand=3 then
       if v_cur_num_question=v_count_question then
         return 'Завершить тестирование?';
       end if;
       update testing t
       set    t.current_num_question=current_num_question+1
       where  t.status='Active'       
       and    t.id_person=iid_person;
       commit;
       return '';
    end if;
    if icommand=1 then
       if v_cur_num_question=1 then
         return 'Мы в начале тестирования';
       end if;
       update testing t
       set    t.current_num_question=current_num_question-1
       where  t.status='Active'       
       and    t.id_person=iid_person;
       commit;
       return '';
    end if;
  commit;
  end;

  function get_question(iid_person in number) return nvarchar2
  is
  omess nvarchar2(128);
  begin
    select q.question
    into omess
    from questions q, 
         questions_for_testing qft,
         testing t
    where qft.id_question=q.id_question
    and qft.id_registration=t.id_registration 
    and q.id_theme=t.id_current_theme
    and qft.order_num_question=t.current_num_question
    and t.status='Active'
    and t.id_person=iid_person;
   
    return omess;
  end;

begin
  null;
end test;
/
