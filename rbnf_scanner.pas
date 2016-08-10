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

unit rbnf_scanner;

interface
uses sym_scanner;

t_sym_node=record
    sym:t_sym;
    kind: (terminal,non_terminal,meta);
    suc:integer; {номера символов в таблице символов для перехода "совпало"}
    alt:integer; {номера символов в таблице символов для перехода "не совпало"}
end;


procedure error;
function find_symbol_by_name(sym:t_sym):integer;
function find_non_terminal_symbol_by_name(sym:t_sym):integer;
procedure add_symbol_to_table(sym:t_sym);
function getsym_table:t_sym;

var sym_table:array[1..max_sym_table_size] of t_sym_node;
    symbols_num:integer;
    cur_sym_address:integer;
    start_of_file, end_of_file:boolean;

procedure parse(goal:integer; var match:boolean);

implementation

var sym:t_sym;

procedure error;
begin
   writeln;
   writeln('ERROR');
   halt(-1);
end; {error}


function find_symbol_by_name(sym:t_sym):integer;
var i,res:integer;
begin
    res:=0;
    for i:=1 to symbols_num do
        if sym_table[i].sym.s_name=sym.s_name then res:=i;
    find_symbol_by_name:=res;
end; {find_symbol_by_name}

function find_non_terminal_symbol_by_name(sym:t_sym):integer;
var i,res:integer;
begin
    res:=0;
    for i:=1 to symbols_num do
        if (sym_table[i].sym.s_name=sym.s_name) and
           (sym_table[i].kind=non_terminal) then res:=i;
    find_non_terminal_symbol_by_name:=res;
end; {find_non_terminal_symbol_by_name}

procedure add_symbol_to_table(sym:t_sym);
begin
    if symbols_num<max_sym_table_size then
    begin
        symbols_num:=symbols_num+1;
        sym_table[symbols_num].sym:=sym;
        sym_table[symbols_num].kind:=terminal;
        sym_table[symbols_num].suc:=0;
        sym_table[symbols_num].alt:=0;
    end;
end; {add_symbol_to_table}

function getsym_table:t_sym;
var sym:t_sym;
begin
    sym.s_name:='OUT';
    sym.kind:=nul;
    if cur_sym_address<symbols_num then
    begin
        cur_sym_address:=cur_sym_address+1;
        sym:=sym_table[cur_sym_address].sym;
    end else cur_sym_address:=symbols_num+1;
    getsym_table:=sym;
//    writeln('symbol: ',sym.s_name);    
end; {getsym_table}

//=========================================================================

procedure term; forward;
// factor ::= <symbol> | [<term>]
procedure factor;
begin
  if sym.s_name='[' then
  begin
    sym_table[cur_sym_address].kind:=meta;
    sym:=getsym_table;
    if sym.s_name<>']' then term;
    if sym.s_name=']' then
    begin
      sym_table[cur_sym_address].kind:=meta;
      sym:=getsym_table
    end else error;
  end else sym:=getsym_table;
end {factor};

// term ::= <factor> {<factor>}
procedure term;
begin
   repeat
     factor;
   until (sym.s_name='.')or(sym.s_name=',')or(sym.s_name=']');
end {term};

// expression ::= <term> {,<term>} 
procedure expression;
begin
   term;
   while sym.s_name=',' do
   begin
      sym_table[cur_sym_address].kind:=meta;
      sym:=getsym_table;
      term;
   end;
end {expression};

//разбор соответствия входного потока символов правилам языка
procedure parse(goal:integer; var match:boolean);
var s:integer;
begin
    s:=sym_table[goal].suc;
    repeat
        if sym_table[s].kind=terminal then
        begin
            if sym_table[s].sym.s_name=sym.s_name then
            begin
                match:=true;
                sym:=getsym;
            end //else match:=(sym_table[s].sym.s_name=empty);
        end else parse(sym_table[s].alt,match);
        if match then s:=sym_table[s].suc else s:=sym_table[s].alt;
    until s=0;
end; {parse}

var i,sym_address:integer;
begin
  //просмотр с целью нахождения всех нетерминальных и мета символов правил.
  //одновременно проводится проверка синтаксиса порождающих правил.
  cur_sym_address:=0;
  sym:=getsym_table;
  while cur_sym_address<=symbols_num do  
  begin 
      if sym.kind=ident then
      begin
        sym_table[cur_sym_address].kind:=non_terminal;
        sym:=getsym_table;
      end else error;
      if sym.s_name='=' then
      begin
        sym_table[cur_sym_address].kind:=meta;
        sym:=getsym_table
      end else error;
      expression;
      if sym.s_name<>'.' then error;
      sym_table[cur_sym_address].kind:=meta;
     sym:=getsym_table;
  end;

  for i:=1 to symbols_num do
  begin
    sym_address:=find_non_terminal_symbol_by_name(sym_table[i].sym);
    if sym_address<>0 then sym_table[i].kind:=non_terminal;
  end;

for i:=1 to symbols_num do
    writeln('kind: ',sym_table[i].kind, ', symbol: ',sym_table[i].sym.s_name);
writeln('non-terminal and meta symbols OK');
writeln('===============================');
end.

