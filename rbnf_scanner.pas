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

procedure parse(goal:integer; var match:boolean);

implementation

var sym:t_sym;

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
