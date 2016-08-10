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

//unit rbnf_scanner;

//interface
uses sym_scanner;

const
  max_nodes_table_size=10000;

type
  t_node_type=(empty,terminal,non_terminal,meta,head);
  t_node=record
    sym:t_sym;
    kind:t_node_type; {тип узла}
    suc:integer; {номера символов в таблице символов для перехода "совпало"}
    alt:integer; {номера символов в таблице символов для перехода "не совпало"}
  end;

  t_nodes_table=array[1..max_nodes_table_size] of t_node;

var
  sym_table:array[1..max_sym_table_size] of t_sym;
  symbols_num:integer;

  nodes_table:t_nodes_table;
  nodes_num:integer;

//implementation

procedure error;
begin
   writeln;
   writeln('ERROR');
   halt(-1);
end; {error}

function term(in_addr:integer):integer; forward;
// factor ::= <symbol> | [<term>]
function factor(in_addr:integer):integer;
var k:integer;
begin
  k:=in_addr;
  if nodes_table[k].sym.s_name='[' then
  begin
    nodes_table[k].kind:=meta;
    k:=k+1;
    if nodes_table[k].sym.s_name<>']' then k:=term(k);
    if nodes_table[k].sym.s_name=']' then
    begin
      nodes_table[k].kind:=meta;
      k:=k+1;
    end else error;
  end else k:=k+1;
  factor:=k;
end {factor};

// term ::= <factor> {<factor>}
function term(in_addr:integer):integer;
var k:integer;
begin
   k:=in_addr;
   repeat
     k:=factor(k);
   until (nodes_table[k].sym.s_name='.')or
         (nodes_table[k].sym.s_name=',')or
         (nodes_table[k].sym.s_name=']');
   term:=k;
end {term};

// expression ::= <term> {,<term>} 
function expression(in_addr:integer):integer;
var k:integer;
begin
   k:=term(in_addr);
   while nodes_table[k].sym.s_name=',' do
   begin
      nodes_table[k].kind:=meta;
      k:=term(k+1);
   end;
   expression:=k;
end {expression};

procedure mark_non_terminal_and_meta_nodes(nodes_num:integer;
                                       var nodes_table:t_nodes_table);
var i,k:integer;
    s:string;
begin
  //просмотр с целью нахождения всех нетерминальных и мета символов правил.
  //одновременно проводится проверка синтаксиса порождающих правил.
  k:=1;
  while k<=nodes_num do
  begin
    if nodes_table[k].sym.kind=ident then
    begin
      nodes_table[k].kind:=head; k:=k+1;
    end else error;
    if nodes_table[k].sym.s_name='=' then nodes_table[k].kind:=meta else error;
    k:=expression(k);
    if nodes_table[k].sym.s_name<>'.' then error;
    nodes_table[k].kind:=meta;
    k:=k+1;
  end;

  for i:=1 to nodes_num do
    if nodes_table[i].kind=head then
    begin
       s:=nodes_table[i].sym.s_name;
       for k:=1 to nodes_num do
         if nodes_table[k].sym.s_name=s then nodes_table[k].kind:=non_terminal;
       nodes_table[i].kind:=head;
    end;
end; {mark_non_terminal_and_meta_nodes}

//=========================================================================

function term_gen(in_addr:integer):integer; forward;
// factor ::= <symbol> | [<term>]
function factor_gen(in_addr:integer):integer;
var k:integer;
begin
  k:=in_addr;
  if nodes_table[k].sym.s_name='[' then
  begin
    k:=k+1;
    if nodes_table[k].sym.s_name<>']' then k:=term_gen(k);
    if nodes_table[k].sym.s_name=']' then k:=k+1;
  end else k:=k+1;
  factor_gen:=k;
end {factor_gen};

// term ::= <factor> {<factor>}
function term_gen(in_addr:integer):integer;
var k:integer;
begin
   k:=in_addr;
   repeat
     k:=factor_gen(k);
   until (nodes_table[k].sym.s_name='.')or
         (nodes_table[k].sym.s_name=',')or
         (nodes_table[k].sym.s_name=']');
   term_gen:=k;//node;
end {term_gen};

// expression ::= <term> {,<term>} 
function expression_gen(in_addr:integer):integer;
var k:integer;
begin
   k:=term_gen(in_addr);
   while nodes_table[k].sym.s_name=',' do
   begin
      nodes_table[k].kind:=meta;
      k:=term_gen(k+1);
   end;
   expression_gen:=k;
end {expression_gen};

procedure gen_nodes_links(nodes_num:integer; var nodes_table:t_nodes_table);
var k:integer;
begin
  k:=1;
  while k<=nodes_num do
  begin
      if nodes_table[k].kind=head then
      begin
        nodes_table[k].suc:=k+2;
        nodes_table[k].alt:=0;
        k:=expression_gen(nodes_table[k].suc)+1;
      end;
  end
end; {gen_nodes_links}

//=========================================================================

var i:integer;
begin
sym_table_read_from_file('rbnf_rules.bnf',sym_table,symbols_num);
for i:=1 to symbols_num do
    writeln('kind: ',sym_table[i].kind, ', symbol: ',sym_table[i].s_name);
writeln('Symbols table OK');
writeln('================');

nodes_num:=symbols_num;
for i:=1 to nodes_num do
begin
  nodes_table[i].kind:=terminal;
  nodes_table[i].suc:=i+1;
  nodes_table[i].alt:=0;
  nodes_table[i].sym:=sym_table[i];
end;
mark_non_terminal_and_meta_nodes(nodes_num,nodes_table);

//gen_nodes_links(nodes_num,nodes_table);

for i:=1 to nodes_num do
    writeln(i,
            ': kind: ',nodes_table[i].kind,
            ', node: ',nodes_table[i].sym.s_name,
            ', suc=',nodes_table[i].suc,
            ', alt=',nodes_table[i].alt);
writeln('non-terminal, meta and head symbols OK');
writeln('===============================');

end.
