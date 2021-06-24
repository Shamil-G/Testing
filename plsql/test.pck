create or replace package test is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 22.06.2021 16:13:21
  -- Purpose : Процедура тестирования
  
  -- Public type declarations
  function get_theme(iid_person in number) return nvarchar2;
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
