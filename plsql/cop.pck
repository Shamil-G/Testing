create or replace package cop is

  -- Author  : Гусейнов_Ш
  -- Created : 21.06.2021 14:06:15
  -- Purpose :

  -- Public type declarations
  procedure login(uname in nvarchar2, oid_user out number, oremain_time out number);
  procedure login_admin(uname in nvarchar2, upass out nvarchar2, oid_user out number);
  procedure new_user2(uname in nvarchar2, upass in nvarchar2, iid_creator in number, imess out nvarchar2);

  
end cop;
/
create or replace package body cop is

  procedure login(uname in nvarchar2, oid_user out number, oremain_time out number)
  is
    r_testing  testing%rowtype;
    
--  PRAGMA AUTONOMOUS_TRANSACTION
  begin
    insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'COP.LOGIN for: '||uname);
    commit;
    select u.id_person into oid_user
    from persons u where u.iin=uname;

    begin
      select * 
      into r_testing 
      from testing t 
      where t.id_person=oid_user and t.status='Active';

      oremain_time := ( extract(second from coalesce(r_testing.beg_time_testing,systimestamp) - systimestamp) + 
                        extract(minute from coalesce(r_testing.beg_time_testing,systimestamp) - systimestamp)*60 + 
                        extract(hour from coalesce(r_testing.beg_time_testing,systimestamp) - systimestamp)*3600 + 
                        r_testing.period_for_testing  );
      
      if r_testing.beg_time_testing is null then
         update testing t
         set    t.beg_time_testing=systimestamp,
                t.status_testing='Идет тестирование'
         where  t.id_registration=r_testing.id_registration;
         commit;
      end if;
      exception when no_data_found then 
      begin
          insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, '--- Тестируемый отсутствует в тестах: '||uname);
          commit;
          oremain_time:=-100;
      end;
    end;

    insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'COP.LOGIN Success: '||uname||' : '||oid_user);
    commit;
    exception when no_data_found then 
      begin
          insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, '--- Тестируемый отсутствует в справочнике: '||uname);
          commit;
          oremain_time:=-200;
      end;
  end;

--/*
  function is_admin(iid_user in number) return pls_integer
  as
    v_admin pls_integer default 0;
  begin
    select count(*) into v_admin
    from users u, users_roles ur, roles r
    where u.id_user=iid_user
    and   ur.id_user=iid_user
    and   r.id_role=ur.id_role
    and   r.name='Admin';
    return v_admin;
  end is_admin;

  procedure new_user2(uname in nvarchar2, upass in nvarchar2, iid_creator in number, imess out nvarchar2)
  is
    v_id_user    number(9);
    v_name_creator nvarchar2(64);
  begin
    imess:='';
    select u.name into v_name_creator from users u where u.id_user=iid_creator;
    select max(id_user) into v_id_user from users;
    insert into users(id_user, name, password, active) values(v_id_user+1, uname, upass, 'Y');
    insert into protocol(event_date, message)
           values(sysdate, 'New User: '||uname||', created by: '||v_name_creator);
    commit;
    exception
      when no_data_found then
        begin
          insert into protocol(event_date, message) values(sysdate, 'Not found iid_creator: '||iid_creator);
          imess:='Mistake '||iid_creator;
          commit;
        end;
      when dup_val_on_index then
      begin
        if is_admin(iid_creator)>0 or
           v_name_creator=uname
          then
            update users u
            set u.password=upass
            where u.name=uname;
            commit;
            insert into protocol(event_date, message) values(sysdate, 'Update password for user name: '||uname||' by: '||v_name_creator);
            commit;
        else
          insert into protocol(event_date, message) values(sysdate, 'New User duplicate user name: '||uname);
          imess:='Duplicated user name';
          commit;
        end if;
      end;
  end;

  procedure login_admin(uname in nvarchar2, upass out nvarchar2, oid_user out number)
  is
  begin
    insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'Login Admin. Login for: '||uname||', '||upass);
    commit;
    select u.id_user, u.password into oid_user, upass
    from users u 
    where u.name=uname
    and  u.active='Y';
    insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'Login Admin. Success: '||uname||', id_user: '||oid_user );
    commit;

    exception when no_data_found then 
      OID_USER := -100;
      insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'Not Found: '||uname||', id_user: '||oid_user );
      commit;
  end;

--*/
begin
  null;
end cop;
/
