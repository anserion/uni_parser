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

// last version: https://github.com/anserion/uni_parser.git

{проверка синтаксиса программы языка на основе форм Бэкуса-Наура}
program uni_parser(input, output);
uses sym_scanner, rbnf_scanner;

var sym:t_sym;

procedure term_gen(var term_in1,term_in2,term_out:integer); forward;
procedure factor_gen(var p,q:integer);
var a,b:integer;
begin
  if sym.s_name='[' then
  begin
    sym_table[cur_sym_address].kind:=meta;
    sym:=getsym_table;
    if sym.s_name<>']' then
    begin
      term_gen(p,a,b);
      sym_table[b].suc:=p;
      sym_table[a].alt:=b;
      q:=b;
    end;
    if sym.s_name=']' then
    begin
      sym_table[cur_sym_address].kind:=meta;
      sym:=getsym_table
    end else error;
  end else
  begin
    p:=cur_sym_address; q:=cur_sym_address;
    sym:=getsym_table;
  end;
end {factor_gen};

procedure term_gen(var term_in1,term_in2,term_out:integer);
var a,b:integer;
begin
   factor_gen(term_in1,a); term_in2:=a;
   repeat
     factor_gen(sym_table[a].suc,b);
     sym_table[b].alt:=0;
     a:=b;
   until (sym.s_name='.')or(sym.s_name=',')or(sym.s_name=']');
   term_out:=a;
end {term_gen};

procedure expression_gen(var expr_in_addr,expr_out_addr:integer);
var a,b,c:integer;
begin
   term_gen(expr_in_addr,a,c);
   sym_table[c].suc:=0;
   while sym.s_name=',' do
   begin
      sym_table[cur_sym_address].kind:=meta;
      sym:=getsym_table;
      term_gen(sym_table[a].alt,b,c);
      sym_table[c].suc:=0;
      a:=b;
   end;
   expr_out_addr:=a;
end {expression_gen};

var i,start_sym_address,end_sym_address:integer;
    start_sym:t_sym;
    flag:boolean;

begin {main}

  //Построение структуры языка на основе порождающих правил Бэкуса-Наура
  start_sym:=getsym;
  start_sym_address:=find_symbol_by_name(start_sym);
//  expression_gen(start_sym_address,end_sym_address);
  sym_table[end_sym_address].alt:=0;

  //проверка все ли нетерминальные символы определены
  flag:=false;
  for i:=1 to symbols_num do
  if (sym_table[i].kind=non_terminal) and (sym_table[i].suc=0) then
  begin
    writeln('UNDEFINED SYMBOL: ',sym_table[i].sym.s_name);
    flag:=true;
  end;
  if flag then halt(-1);
  
  //проверка синтаксиса текстового файла по правилам, разобранным выше
  flag:=true;
  repeat
    write(' ');
    sym:=getsym;
    parse(start_sym_address,flag);
    if flag and (sym.s_name='.') then writeln('CORRECT')
                                 else writeln('INCORRECT');
  until end_of_file;
end.
