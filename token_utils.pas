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

      rus_cp1251_letters=['À','Á','Â','Ã','Ä','Å','¨','Æ','Ç','È','É',
                          'Ê','Ë','Ì','Í','Î','Ï','Ğ','Ñ','Ò','Ó','Ô',
                          'Õ','Ö','×','Ø','Ù','Û','Ü','Ú','İ','Ş','ß',
                          'à','á','â','ã','ä','å','¸','æ','ç','è','é',
                          'ê','ë','ì','í','î','ï','ğ','ñ','ò','ó','ô',
                          'õ','ö','÷','ø','ù','û','ü','ú','ı','ş','ÿ'];

      rus_cp866_letters=['€','','‚','ƒ','„','…','ğ','†','‡','ˆ','‰',
                         'Š','‹','Œ','','','','','‘','’','“','”',
                         '•','–','—','˜','™','›','œ','š','','','Ÿ',
                         ' ','¡','¢','£','¤','¥','ñ','¦','§','¨','©',
                         'ª','«','¬','­','®','¯','à','á','â','ã','ä',
                         'å','æ','ç','è','é','ë','ì','ê','í','î','ï'];

      rus_koi8r_letters=['á','â','÷','ç','ä','å','³','ö','ú','é','ê',
                         'ë','ì','í','î','ï','ğ','ò','ó','ô','õ','æ',
                         'è','ã','ş','û','ı','ù','ø','ÿ','ü','à','ñ',
                         'Á','Â','×','Ç','Ä','Å','£','Ö','Ú','É','Ê',
                         'Ë','Ì','Í','Î','Ï','Ğ','Ò','Ó','Ô','Õ','Æ',
                         'È','Ã','Ş','Û','İ','Ù','Ø','ß','Ü','À','Ñ'];

type
  t_charfile=file of char;
  t_sym=(nul,oper,num,ident);
  t_toc=(empty,terminal,non_term,meta,head);

  t_token=record
    suc:integer; {Ğ½Ğ¾Ğ¼ĞµÑ€Ğ° ÑĞ¸Ğ¼Ğ²Ğ¾Ğ»Ğ¾Ğ² Ğ² Ñ‚Ğ°Ğ±Ğ»Ğ¸Ñ†Ğµ ÑĞ¸Ğ¼Ğ²Ğ¾Ğ»Ğ¾Ğ² Ğ´Ğ»Ñ Ğ¿ĞµÑ€ĞµÑ…Ğ¾Ğ´Ğ° "ÑĞ¾Ğ²Ğ¿Ğ°Ğ»Ğ¾"}
    alt:integer; {Ğ½Ğ¾Ğ¼ĞµÑ€Ğ° ÑĞ¸Ğ¼Ğ²Ğ¾Ğ»Ğ¾Ğ² Ğ² Ñ‚Ğ°Ğ±Ğ»Ğ¸Ñ†Ğµ ÑĞ¸Ğ¼Ğ²Ğ¾Ğ»Ğ¾Ğ² Ğ´Ğ»Ñ Ğ¿ĞµÑ€ĞµÑ…Ğ¾Ğ´Ğ° "Ğ½Ğµ ÑĞ¾Ğ²Ğ¿Ğ°Ğ»Ğ¾"}
    entry:integer; {Ğ°Ğ´Ñ€ĞµÑ Ğ²Ñ…Ğ¾Ğ´Ğ° (Ñ€Ğ°ÑÑˆĞ¸Ñ„Ñ€Ğ¾Ğ²ĞºĞ¸) Ğ½ĞµÑ‚ĞµÑ€Ğ¼Ğ¸Ğ½Ğ°Ğ»ÑŒĞ½Ğ¾Ğ³Ğ¾ ÑĞ¸Ğ¼Ğ²Ğ¾Ğ»Ğ°}
    kind_toc:t_toc; {Ñ‚Ğ¸Ğ¿ ÑƒĞ·Ğ»Ğ°: empty, terminal, non_terminal, meta, head}
    kind_sym:t_sym; {Ñ‚Ğ¸Ğ¿ ÑĞ¸Ğ¼Ğ²Ğ¾Ğ»Ğ°: nul, oper, num, ident}
    s_name:string;
  end;

  t_token_table=array[1..max_symbols] of t_token;

function skip_nul(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_prev_good_token(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_next_good_token(k,tokens_num:integer;var token_table:t_token_table):integer;
function find_start_of_expression(s:string;tokens_num:integer;var token_table:t_token_table):integer;
function find_end_of_expression(k,tokens_num:integer;var token_table:t_token_table):integer;


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

function find_end_of_expression(k,tokens_num:integer;
                              var token_table:t_token_table):integer;
var flag:boolean;
begin
  if k>0 then
  begin
    repeat k:=k+1; until (token_table[k].kind_toc=head)or(k=tokens_num);
    flag:=false;
    repeat
      if k=0 then flag:=true;
      if (k>0) then if token_table[k].s_name='.' then flag:=true else k:=k-1;
    until flag;
  end;
  find_end_of_expression:=k;
end; {find_end_of_expression}

begin
end.
