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

{проверка синтаксиса программы языка на основе форм Бэкуса-Наура}
program uni_parser(input, output);
uses token_utils, sym_scanner, rbnf_scanner, rbnf_gen;

var
    prg_table,token_table:t_token_table;
    prg_symbols_num,tokens_num:integer;
    cur_sym:integer;

//считывание очередного символа программы
function getsym:t_token;
var sym:t_token;
begin
  sym.s_name:='';
  sym.kind_sym:=nul;
  if cur_sym<=prg_symbols_num then
  begin
    cur_sym:=skip_nul(cur_sym,prg_symbols_num,prg_table);
    sym:=prg_table[cur_sym]
  end else sym.s_name:='OUT';
  cur_sym:=cur_sym+1;
  if cur_sym>prg_symbols_num then cur_sym:=prg_symbols_num+1;
  getsym:=sym;
end; {getsym}

//разбор соответствия входного потока символов правилам языка
function parse(goal:integer; var sym:t_token):boolean;
var s:integer; match:boolean; flag:boolean;
begin
    match:=false;
    s:=token_table[goal].entry;
    repeat
        flag:=false;
        if (token_table[s].kind_toc=terminal) then
        begin
           if (token_table[s].s_name=sym.s_name) then
           begin
             match:=true; sym:=getsym;
           end else
           begin
             match:=token_table[s].alt=-1;
             flag:=match;
           end;
        end;
        if (token_table[s].kind_toc=non_term) then
           begin
             match:=parse(token_table[s].entry,sym);
           end;
        if match then s:=token_table[s].suc else s:=token_table[s].alt;
    until (s=0) or flag;
    parse:=match;
end; {parse}

//=========================================================================

var
  i,goal:integer;
  flag:boolean;
  sym:t_token;

begin {main}
  //Построение структуры языка на основе порождающих правил Бэкуса-Наура
  tokens_num:=symbols_from_file('lang.rbnf',token_table);

  mark_tokens(tokens_num,token_table);
  for i:=1 to tokens_num do
  begin
    token_table[i].suc:=0;
    token_table[i].alt:=0;
    token_table[i].entry:=0;
  end;

  writeln('RBNF tokens: ',tokens_num);
  for i:=1 to tokens_num do
      writeln(i:3,
              ': ',token_table[i].kind_sym:5,
              '  ',token_table[i].kind_toc:8,
              ' "',token_table[i].s_name,'"');
  writeln('===============================');

  gen_tokens_links(tokens_num,token_table);

  writeln('RBNF links');
  for i:=1 to tokens_num do
      writeln(i:3,
              ': entry=',token_table[i].entry:3,
              ', suc=',token_table[i].suc:3,
              ', alt=',token_table[i].alt:3,
              ' ',token_table[i].kind_sym:5,
              ' ',token_table[i].kind_toc:8,
              ' "',token_table[i].s_name,'"');
  writeln('===============================');

  //загрузка транслируемой программы
  prg_symbols_num:=symbols_from_file('test_program.xxx',prg_table);

  writeln('tokens of test program: ',prg_symbols_num);
  for i:=1 to prg_symbols_num do
      writeln(i,
              ': ',prg_table[i].kind_sym:5,
              ' "',prg_table[i].s_name,'"');
  writeln('===============================');

  //проверка синтаксиса программы (точка входа - первое правило РБНФ)
  goal:=1; while token_table[goal].kind_toc<>head do goal:=goal+1;
  writeln('goal: ',token_table[goal].s_name,', address=',goal);

  flag:=true; cur_sym:=1;
  sym:=getsym;
  flag:=parse(goal,sym);
  if flag then writeln('CORRECT') else writeln('INCORRECT');

end.
