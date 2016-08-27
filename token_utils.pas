//Copyright 2016 Andrey S. Ionisyan (anserion@gmail.com)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

unit token_utils;

interface

const
      max_symbols=10000;

      digits=['0'..'9'];
      eng_letters=['A'..'Z','a'..'z'];
      spec_letters=[',',';','!','%','?','#','$','@','&','^',
                    '/','\','|','=','<','>','(',')','{','}',
                    '[',']','+','-','*','.','''','"','`',':','~'];

      rus_cp1251_letters=['�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�'];

      rus_cp866_letters=['�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�'];

      rus_koi8r_letters=['�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�'];

type
  t_charfile=file of char;
  t_sym=(nul,oper,num,ident);
  t_toc=(empty,terminal,non_term,meta,head);

  t_token=record
    suc:integer; {номера символов в таблице символов для перехода "совпало"}
    alt:integer; {номера символов в таблице символов для перехода "не совпало"}
    entry:integer; {адрес входа (расшифровки) нетерминального символа}
    kind_toc:t_toc; {тип узла: empty, terminal, non_terminal, meta, head}
    kind_sym:t_sym; {тип символа: nul, oper, num, ident}
    s_name:string;
  end;

  t_token_table=array[1..max_symbols] of t_token;

function skip_nul(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_prev_good_token(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_next_good_token(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_start_of_expression(s:string;tokens_num:integer;var token_table:t_token_table):integer;
procedure find_ends_of_expression(k,tokens_num:integer;
                              var token_table:t_token_table;
                              var start_address,end_address:integer);


implementation

function skip_nul(k,tokens_num:integer;var token_table:t_token_table):integer;
begin
    while (k<tokens_num)and(token_table[k].kind_sym=nul) do k:=k+1;
    skip_nul:=k;
end; {skip_nul}

function find_prev_good_token(k,tokens_num:integer;
                              var token_table:t_token_table):integer;
begin
  while (k>0)and(token_table[k].kind_toc<>head)and
        ((token_table[k].kind_toc=meta)or(token_table[k].kind_toc=empty))
        do k:=k-1;
  find_prev_good_token:=k;
end; {find_prev_good_token}

function find_next_good_token(k,tokens_num:integer;
                              var token_table:t_token_table):integer;
begin
  while (k<tokens_num)and
        ((token_table[k].kind_toc=meta)or(token_table[k].kind_toc=empty))
        do k:=k+1;
  find_next_good_token:=k;
end; {find_next_good_token}

function find_start_of_expression(s:string;tokens_num:integer;
                              var token_table:t_token_table):integer;
var start_address,k:integer;
begin
  start_address:=0;
  for k:=1 to tokens_num do
      if (token_table[k].s_name=s)and
         (token_table[k].kind_toc=head) then start_address:=k;
  find_start_of_expression:=start_address;
end; {find_start_of_expression}

procedure find_ends_of_expression(k,tokens_num:integer;
                              var token_table:t_token_table;
                              var start_address,end_address:integer);
var flag:boolean;
begin
  if k>0 then
  begin
    start_address:=k;
    flag:=false;
    repeat
      if start_address=0 then flag:=true;
      if (token_table[start_address].kind_toc=head) then flag:=true
                                                    else start_address:=start_address-1;
    until flag;

    end_address:=k;
    repeat
      end_address:=end_address+1;
    until (token_table[end_address].kind_toc=head)or
          (end_address=tokens_num);

    flag:=false;
    repeat
      if end_address=0 then flag:=true;
      if (end_address>0) then
         if (token_table[end_address].s_name='.')and
            (token_table[end_address].kind_toc=meta) then flag:=true
                                                     else end_address:=end_address-1;
    until flag;
  end else
  begin
    start_address:=0;
    end_address:=0;
  end;
end; {find_end_of_expression}

begin
end.
