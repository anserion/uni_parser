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

// factor ::= <symbol> | [<term>]
// term ::= <factor> {<factor>}
// expression ::= <term> {,<term>}
function factor(k,tockens_num:integer;var tocken_table:t_tocken_table):integer;
function term(k,tockens_num:integer;var tocken_table:t_tocken_table):integer;
function expression(k,tockens_num:integer;var tocken_table:t_tocken_table):integer;
function skip_nul(k,tockens_num:integer;var tocken_table:t_tocken_table):integer;
procedure mark_tockens(tockens_num:integer;var tocken_table:t_tocken_table);

implementation

procedure error;
begin
   writeln;
   writeln('ERROR');
   halt(-1);
end; {error}

function skip_nul(k,tockens_num:integer;var tocken_table:t_tocken_table):integer;
begin
    while (k<tockens_num)and(tocken_table[k].kind_sym=nul) do k:=k+1;
    skip_nul:=k;
end;

// factor ::= <symbol> | [<term>]
function factor(k,tockens_num:integer;var tocken_table:t_tocken_table):integer;
begin
  if tocken_table[k].s_name='[' then
  begin
    tocken_table[k].kind_toc:=meta;
    k:=skip_nul(k+1,tockens_num,tocken_table);
    if tocken_table[k].s_name<>']' then k:=term(k,tockens_num,tocken_table);
    if tocken_table[k].s_name=']' then
    begin
      tocken_table[k].kind_toc:=meta;
      k:=skip_nul(k+1,tockens_num,tocken_table);
    end else error;
  end else k:=skip_nul(k+1,tockens_num,tocken_table);
  factor:=k;
end {factor};

// term ::= <factor> {<factor>}
function term(k,tockens_num:integer;var tocken_table:t_tocken_table):integer;
begin
   repeat
     k:=factor(k,tockens_num,tocken_table);
   until (tocken_table[k].s_name='.')or
         (tocken_table[k].s_name=',')or
         (tocken_table[k].s_name=']');
   term:=k;
end {term};

// expression ::= <term> {,<term>} 
function expression(k,tockens_num:integer;var tocken_table:t_tocken_table):integer;
begin
   k:=term(k,tockens_num,tocken_table);
   while tocken_table[k].s_name=',' do
   begin
      tocken_table[k].kind_toc:=meta;
      k:=term(skip_nul(k+1,tockens_num,tocken_table),tockens_num,tocken_table);
   end;
   expression:=k;
end {expression};

procedure mark_tockens(tockens_num:integer;var tocken_table:t_tocken_table);
var i,k:integer;
    s:string;
begin
  //просмотр с целью нахождения всех нетерминальных и мета символов правил.
  //одновременно проводится проверка синтаксиса порождающих правил.
  for i:=1 to tockens_num do tocken_table[i].kind_toc:=terminal;

  k:=skip_nul(1,tockens_num,tocken_table);
  while k<tockens_num do
  begin
    if tocken_table[k].kind_sym=ident then
    begin
      tocken_table[k].kind_toc:=head;
      k:=skip_nul(k+1,tockens_num,tocken_table);
    end else error;
    if tocken_table[k].s_name='=' then tocken_table[k].kind_toc:=meta else error;
    k:=expression(k,tockens_num,tocken_table);
    if tocken_table[k].s_name<>'.' then error;
    tocken_table[k].kind_toc:=meta;
    k:=skip_nul(k+1,tockens_num,tocken_table);
  end;

  for i:=1 to tockens_num do
    if tocken_table[i].kind_sym=nul then tocken_table[i].kind_toc:=empty;

  for i:=1 to tockens_num do
    if tocken_table[i].kind_toc=head then
    begin
       s:=tocken_table[i].s_name;
       for k:=1 to tockens_num do
         if tocken_table[k].s_name=s then tocken_table[k].kind_toc:=non_term;
       tocken_table[i].kind_toc:=head;
    end;
end; {mark_tockens}

begin
end.
