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

const
  max_nodes_table_size=10000;

type
  t_node_type=(empty,terminal,non_terminal,meta,head);
  t_node=record
    suc:integer; {номера символов в таблице символов для перехода "совпало"}
    alt:integer; {номера символов в таблице символов для перехода "не совпало"}
    kind:t_node_type; {тип узла: empty, terminal, non_terminal, meta, head}
    kind_sym:t_sym_type; {тип символа: nul, oper, num, ident}
    s_name:string;
  end;

  t_nodes_table=array[1..max_nodes_table_size] of t_node;

// factor ::= <symbol> | [<term>]
// term ::= <factor> {<factor>}
// expression ::= <term> {,<term>}
function factor(in_addr:integer; var nodes_table:t_nodes_table):integer;
function term(in_addr:integer; var nodes_table:t_nodes_table):integer;
function expression(in_addr:integer; var nodes_table:t_nodes_table):integer;

procedure mark_non_terminal_and_meta_nodes(nodes_num:integer;
                                       var nodes_table:t_nodes_table);

implementation

procedure error;
begin
   writeln;
   writeln('ERROR');
   halt(-1);
end; {error}

// factor ::= <symbol> | [<term>]
function factor(in_addr:integer; var nodes_table:t_nodes_table):integer;
var k:integer;
begin
  k:=in_addr;
  if nodes_table[k].s_name='[' then
  begin
    nodes_table[k].kind:=meta;
    nodes_table[k].suc:=k+1; nodes_table[k].alt:=0;
    k:=k+1;
    if nodes_table[k].s_name<>']' then k:=term(k,nodes_table);
    if nodes_table[k].s_name=']' then
    begin
      nodes_table[k].kind:=meta;
      nodes_table[k].suc:=k+1; nodes_table[k].alt:=0;
      k:=k+1;
    end else error;
  end else k:=k+1;
  factor:=k;
end {factor};

// term ::= <factor> {<factor>}
function term(in_addr:integer; var nodes_table:t_nodes_table):integer;
var k:integer;
begin
   k:=in_addr;
   repeat
     k:=factor(k,nodes_table);
   until (nodes_table[k].s_name='.')or
         (nodes_table[k].s_name=',')or
         (nodes_table[k].s_name=']');
   term:=k;
end {term};

// expression ::= <term> {,<term>} 
function expression(in_addr:integer; var nodes_table:t_nodes_table):integer;
var k:integer;
begin
   k:=term(in_addr,nodes_table);
   while nodes_table[k].s_name=',' do
   begin
      nodes_table[k].kind:=meta;
      nodes_table[k].suc:=k+1; nodes_table[k].alt:=0;
      k:=term(k+1,nodes_table);
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
    if nodes_table[k].kind_sym=ident then
    begin
      nodes_table[k].kind:=head;
      nodes_table[k].suc:=k+1; nodes_table[k].alt:=0;
      k:=k+1;
    end else error;
    if nodes_table[k].s_name='=' then
    begin
      nodes_table[k].kind:=meta;
      nodes_table[k].suc:=k+1; nodes_table[k].alt:=0;
    end else error;
    k:=expression(k,nodes_table);
    if nodes_table[k].s_name<>'.' then error;
    nodes_table[k].kind:=meta;
    nodes_table[k].suc:=0; nodes_table[k].alt:=0;
    k:=k+1;
  end;

  for i:=1 to nodes_num do
    if nodes_table[i].kind=head then
    begin
       s:=nodes_table[i].s_name;
       for k:=1 to nodes_num do
         if nodes_table[k].s_name=s then nodes_table[k].kind:=non_terminal;
       nodes_table[i].kind:=head;
    end;
end; {mark_non_terminal_and_meta_nodes}

begin
end.
