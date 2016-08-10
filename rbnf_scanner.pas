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

var cur_node_address: integer;

procedure error;
begin
   writeln;
   writeln('ERROR');
   halt(-1);
end; {error}

function getnode:t_node;
var node:t_node;
begin
    if (cur_node_address>=0)and(cur_node_address<nodes_num) then
    begin
        cur_node_address:=cur_node_address+1;
        node:=nodes_table[cur_node_address];
    end else
    begin
      cur_node_address:=nodes_num+1;
      node.sym.s_name:='';
      node.sym.kind:=nul;
      node.kind:=empty;
    end;
    getnode:=node;
end; {getnode}

function term(value:t_node):t_node; forward;
// factor ::= <symbol> | [<term>]
function factor(value:t_node):t_node;
var node:t_node;
begin
  node:=value;
  if node.sym.s_name='[' then
  begin
    nodes_table[cur_node_address].kind:=meta;
    node:=getnode;
    if node.sym.s_name<>']' then node:=term(node);
    if node.sym.s_name=']' then
    begin
      nodes_table[cur_node_address].kind:=meta;
      node:=getnode;
    end else error;
  end else node:=getnode;
  factor:=node;
end {factor};

// term ::= <factor> {<factor>}
function term(value:t_node):t_node;
var node:t_node;
begin
   node:=value;
   repeat
     node:=factor(node);
   until (node.sym.s_name='.')or(node.sym.s_name=',')or(node.sym.s_name=']');
   term:=node;
end {term};

// expression ::= <term> {,<term>} 
function expression(value:t_node):t_node;
var node:t_node;
begin
   node:=value;
   node:=term(node);
   while node.sym.s_name=',' do
   begin
      nodes_table[cur_node_address].kind:=meta;
      node:=getnode;
      node:=term(node);
   end;
   expression:=node;
end {expression};

procedure mark_non_terminal_and_meta_nodes(nodes_num:integer;
                                       var nodes_table:t_nodes_table);
var i,k:integer;
    node:t_node;
    s:string;
begin
  //просмотр с целью нахождения всех нетерминальных и мета символов правил.
  //одновременно проводится проверка синтаксиса порождающих правил.
  cur_node_address:=0;
  node:=getnode;
  while cur_node_address<=nodes_num do
  begin
      if node.sym.kind=ident then
      begin
        nodes_table[cur_node_address].kind:=head;
        node:=getnode;
      end else error;
      if node.sym.s_name='=' then
      begin
        nodes_table[cur_node_address].kind:=meta;
        node:=getnode;
      end else error;
      node:=expression(node);
      if node.sym.s_name<>'.' then error;
      nodes_table[cur_node_address].kind:=meta;
      node:=getnode;
  end;

  for i:=1 to nodes_num do
    if nodes_table[i].kind=head then
    begin
       s:=nodes_table[i].sym.s_name;
       for k:=1 to nodes_num do
         if nodes_table[k].sym.s_name=s then nodes_table[k].kind:=non_terminal;
       nodes_table[i].kind:=head;
    end;
end;

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
  nodes_table[i].sym:=sym_table[i];
end;
mark_non_terminal_and_meta_nodes(nodes_num,nodes_table);

for i:=1 to nodes_num do
    writeln('kind: ',nodes_table[i].kind, ', node: ',nodes_table[i].sym.s_name);
writeln('non-terminal, meta and head symbols OK');
writeln('===============================');

end.
