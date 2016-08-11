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
uses sym_scanner, rbnf_scanner, rbnf_gen;

var 
    prg_table:t_sym_table;
    prg_symbols_num:integer;
    cur_sym:integer;

//считывание очередного символа программы
function getsym:t_sym;
var sym:t_sym;
begin
  sym.s_name:='';
  sym.kind:=nul;
  if cur_sym<=prg_symbols_num then
  begin
    cur_sym:=cur_sym+1;
    sym:=prg_table[cur_sym];
  end else
  begin
    sym.s_name='OUT';
    cur_sym:=prg_symbols_num+1;
  end;
  getsym:=sym;
end; {getsym}

//разбор соответствия входного потока символов правилам языка
function parse(goal:integer; sym:t_sym):boolean);
var s:integer; match:boolean;
begin
    match:=false;
    s:=nodes_table[goal].suc;
    repeat
        if (nodes_table[s].kind=terminal)and
           (nodes_table[s].s_name=sym.s_name) then match:=true;
        if (nodes_table[s].kind=non_terminal) then
           match:=parse(nodes_table[s].alt,getsym);
        if match then s:=nodes_table[s].suc else s:=nodes_table[s].alt;
    until s=0;
    parse:=match;
end; {parse}

//=========================================================================

var i,goal:integer;
    flag:boolean;

begin {main}

  //Построение структуры языка на основе порождающих правил Бэкуса-Наура
  sym_table_read_from_file('rbnf_rules.bnf',sym_table,symbols_num);
  nodes_num:=symbols_num;
  for i:=1 to nodes_num do
  begin
    nodes_table[i].kind:=terminal;
    nodes_table[i].suc:=0;
    nodes_table[i].alt:=0;
    nodes_table[i].s_name:=sym_table[i].s_name;
    nodes_table[i].kind_sym:=sym_table[i].kind;
  end;
  mark_non_terminal_and_meta_nodes(nodes_num,nodes_table);

  //gen_nodes_links(nodes_num,nodes_table);

  for i:=1 to nodes_num do
      writeln(i,
              ': ',nodes_table[i].s_name,
              '  ',nodes_table[i].kind,
              ' ',nodes_table[i].kind_sym,
              ', suc=',nodes_table[i].suc,
              ', alt=',nodes_table[i].alt);
  writeln('===============================');

  //проверка все ли нетерминальные символы определены
  flag:=false;
  for i:=1 to nodes_num do
  if (nodes_table[i].kind=non_terminal) and (nodes_table[i].alt=0) then
  begin
    writeln('UNDEFINED SYMBOL: ',nodes_table[i].s_name);
    flag:=true;
  end;
  if flag then halt(-1);

  //загрузка транслируемой программы
  sym_table_read_from_file('test_program.xxx',prg_table,prg_symbols_num);

  //проверка синтаксиса программы (точка входа - первое правило РБНФ)
  flag:=true;
  goal:=1; while nodes_table[goal].kind<>head do goal:=goal+1;
  flag:=parse(goal,getsym);
  if flag then writeln('CORRECT') else writeln('INCORRECT');
end.
