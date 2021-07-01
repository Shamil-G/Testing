create or replace package test is

  -- Author  : ��������_�
  -- Created : 22.06.2021 16:13:21
  -- Purpose : ��������� ������������
  
  -- Public type declarations
  function get_theme(iid_person in number) return nvarchar2;
  function navigate_question(iid_person in number, icommand in number) return number;
  procedure set_answer(iid_person in number, iorder_num_answer in number);
  function finish_part(iid_person in number) return nvarchar2;
  function have_test(iid_person in number) return number;
  
  
  function get_question(iid_person in number) return nvarchar2;

end test;
/
create or replace package body test is


  procedure log(imess in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into protocol(event_date, message) values(systimestamp, imess);
    commit;
  end;
  
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
    v_id_question_for_testing questions_for_testing.id_question_for_testing%type;
    v_id_registration testing.id_registration%type;
    v_id_answer  pls_integer;
  begin
    select t.id_registration, id_question_for_testing
    into   v_id_registration, v_id_question_for_testing    
    from questions_for_testing qft, testing t
    where qft.id_registration=t.id_registration
    and   qft.id_theme=t.id_current_theme
    and   qft.order_num_question=t.current_num_question
    and   t.id_person=iid_person
    and   t.status='Active';
    
    select id_answer
    into v_id_answer
    from answers_in_testing ait
    where ait.order_num_answer=iorder_num_answer
    and   ait.id_question_for_testing = v_id_question_for_testing;
     
    update questions_for_testing qft
    set    qft.id_answer=v_id_answer
    where qft.id_question_for_testing=v_id_question_for_testing;

    insert into protocol(event_date,message) 
           values(SYSTIMESTAMP, '��������� ���������, id_person: '||iid_person||', num_answer: '||iorder_num_answer||', question_for_testing: '||v_id_question_for_testing);
    commit;
    exception when others then 
      log('--- ERROR SET_ANSWER. id_person: '||iid_person||', iorder_num_answer: '||iorder_num_answer||
               ', id_registration: '||v_id_registration||
               ', id_question_for_testing: '||v_id_question_for_testing||
               ', v_id_answer: '||v_id_answer||' : '||sqlerrm);
      raise_application_error(-20000, sqlerrm);
  end;
  
  function next_theme(iid_person in number, icommand in number, iid_registration in pls_integer, itheme_number in pls_integer) return pls_integer
  is
    row_tft         themes_for_testing%rowtype;
  begin
    log('NEXT_THEME. id_person: '||iid_person||' : '||icommand);  
    if icommand=1 and itheme_number>1 then
      begin
        select tft.* into row_tft
        from themes_for_testing tft 
        where tft.id_registration=iid_registration
        and   tft.theme_number=itheme_number-1;

        update testing t 
        set    t.id_current_theme=row_tft.id_theme,
               t.current_num_question=row_tft.count_question
        where t.id_registration=row_tft.id_registration;
        
        exception when no_data_found then return -50;
      end;
    end if;
    if icommand=3 then
      begin
        select tft.* into row_tft
        from themes_for_testing tft 
        where tft.id_registration=iid_registration
        and   tft.theme_number=itheme_number+1;

        update testing t 
        set    t.id_current_theme=row_tft.id_theme,
               t.current_num_question=1
        where t.id_registration=row_tft.id_registration;

        exception when no_data_found then return -100;
      end;
    end if;
--    log('NEXT_THEME. ROW_TFT. id_person: '||iid_person||' : '||icommand||', v_theme_number: '||v_theme_number);  
    commit;
    return 0;
  end;
  
  function navigate_question(iid_person in number, icommand in number)
    return number
  is
   v_count_question pls_integer;
   v_cur_num_question pls_integer;
   v_remain_time      pls_integer;
   v_id_registration  pls_integer;
   v_theme_number     pls_integer;
  begin
--    insert into protocol(event_date,message) values(SYSTIMESTAMP, '�������� ������� '|| icommand|| ', id_person: '||iid_person);
--    commit;
    /*������� ����� ���������� �������� � ���������� ����� ��� �����������*/
    log('1. navigate_question. id_person: '||iid_person||' : COMMAND: '||icommand);
     select tft.id_registration, tft.theme_number, tft.count_question, t.current_num_question
            ,
            ( extract(second from t.beg_time_testing - systimestamp) + 
              extract(minute from t.beg_time_testing - systimestamp)*60 + 
              extract(hour from t.beg_time_testing - systimestamp)*3600 + 
              t.period_for_testing 
            )
            into v_id_registration, v_theme_number, v_count_question, v_cur_num_question, v_remain_time
     from themes_for_testing tft, testing t
     where tft.id_registration=t.id_registration
     and   tft.id_theme=t.id_current_theme
     and   t.status='Active'       
     and   t.id_person=iid_person;

    log('2. navigate_question. id_person: '||iid_person||' : '||icommand||' id_registration: '||v_id_registration||', theme_number: '||v_theme_number);

    /* ���� � ������*/
    if icommand=0 then
       update testing t
       set    t.current_num_question=1,
              t.last_time_access=systimestamp
       where  t.status='Active'       
       and    t.id_person=iid_person;
    end if;
    /* ���� � �����*/
    if icommand=4 then
       update testing t
       set    t.current_num_question=v_count_question,
              t.last_time_access=systimestamp
       where  t.status='Active'       
       and    t.id_person=iid_person;
    end if;
    /* */
    if icommand=3 then
       if v_cur_num_question=v_count_question then
          if next_theme(iid_person, icommand, v_id_registration, v_theme_number)=-100 then
            return -100;
          end if;
       else 
          update testing t
          set    t.current_num_question=current_num_question+1,
                t.last_time_access=systimestamp
          where  t.status='Active'       
          and    t.id_person=iid_person;
       end if;
    end if;

    if icommand=1 then
       if v_cur_num_question=1 then
         if next_theme(iid_person, icommand, v_id_registration, v_theme_number)=-50 then
           return -50;
         end if;
       else
         update testing t
         set    t.current_num_question=current_num_question-1,
                t.last_time_access=systimestamp
         where  t.status='Active'       
         and    t.id_person=iid_person;
       end if;
    end if;

    commit;
    return v_remain_time;
  end;

  function finish_part(iid_person in number) return nvarchar2
  is
    cnt_selected      pls_integer;
    v_count_question  pls_integer;
    v_unanswered       pls_integer;
  begin
    select count(q.id_question) 
    into v_unanswered
    from testing t, questions_for_testing q
    where q.id_registration=t.id_registration
    and   q.id_theme=t.id_current_theme
    and t.status='Active'
    and t.id_person=iid_person
    and q.id_answer is null;
              
    if v_unanswered>0 then
       insert into protocol(event_date,message) 
              values(SYSTIMESTAMP, '������� ������������ ������� '|| cnt_selected|| ' �� ' ||v_count_question|| ', id_person: '||iid_person);
       commit;
      return '������� ������������ �������!';
    end if;
    update testing t
    set   t.status='Completed',
          t.status_testing='������������ ���������',
          t.end_time_testing=systimestamp
    where t.status='Active'
    and t.id_person=iid_person;
    commit;
    return 'Completed';
  end;


  function have_test(iid_person in number) return number
  is
    v_cnt        pls_integer;
  begin
    select t.period_for_testing into v_cnt
    from testing t
    where t.status='Active'
    and   t.id_person=iid_person;
    
    update testing t
    set t.beg_time_testing=systimestamp,
        t.last_time_access=systimestamp,
        t.status_testing='���� ������������'
    where t.status='Active'
    and   t.id_person=iid_person;
    commit;
    return v_cnt;
    exception when no_data_found then return '';
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
  
  procedure get_result(iid_person in number)
  is 
  begin
    log('Get Result for: '||iid_person);
  end;

begin
  null;
end test;
/
