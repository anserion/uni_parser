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
uses token_utils, sym_scanner;

procedure mark_tokens(tokens_num:integer;var token_table:t_token_table);

implementation

function term(k,tokens_num:integer;var token_table:t_token_table):integer; forward;

procedure error;
begin
   writeln;
   writeln('ERROR');
   halt(-1);
end; {error}

// factor ::= <symbol> | [<term>]
function factor(k,tokens_num:integer;var token_table:t_token_table):integer;
begin
  if token_table[k].s_name='[' then
  begin
    token_table[k].kind_toc:=meta;
    k:=skip_nul(k+1,tokens_num,token_table);
    if token_table[k].s_name<>']' then k:=term(k,tokens_num,token_table);
    if token_table[k].s_name=']' then
    begin
      token_table[k].kind_toc:=meta;
      k:=skip_nul(k+1,tokens_num,token_table);
    end else error;
  end else k:=skip_nul(k+1,tokens_num,token_table);
  factor:=k;
end {factor};

// term ::= <factor> {<factor>}
function term(k,tokens_num:integer;var token_table:t_token_table):integer;
begin
   repeat
     k:=factor(k,tokens_num,token_table);
   until (token_table[k].s_name='.')or
         (token_table[k].s_name=',')or
         (token_table[k].s_name=']');
   term:=k;
end {term};

// expression ::= <term> {,<term>} 
function expression(k,tokens_num:integer;var token_table:t_token_table):integer;
begin
   k:=term(k,tokens_num,token_table);
   while token_table[k].s_name=',' do
   begin
      token_table[k].kind_toc:=meta;
      k:=term(skip_nul(k+1,tokens_num,token_table),tokens_num,token_table);
   end;
   expression:=k;
end {expression};

procedure mark_tokens(tokens_num:integer;var token_table:t_token_table);
var i,k:integer;
    s:string;
begin
  //просмотр с целью нахождения всех нетерминальных и мета символов правил.
  //одновременно проводится проверка синтаксиса порождающих правил.
  for i:=1 to tokens_num do token_table[i].kind_toc:=terminal;

  k:=skip_nul(1,tokens_num,token_table);
  while k<tokens_num do
  begin
    if token_table[k].kind_sym=ident then
    begin
      token_table[k].kind_toc:=head;
      k:=skip_nul(k+1,tokens_num,token_table);
    end else error;
    if token_table[k].s_name='=' then token_table[k].kind_toc:=meta else error;
    k:=expression(k,tokens_num,token_table);
    if token_table[k].s_name<>'.' then error;
    token_table[k].kind_toc:=meta;
    k:=skip_nul(k+1,tokens_num,token_table);
  end;

  for i:=1 to tokens_num do
    if token_table[i].kind_sym=nul then token_table[i].kind_toc:=empty;

  for i:=1 to tokens_num do
    if token_table[i].kind_toc=head then
    begin
       s:=token_table[i].s_name;
       for k:=1 to tokens_num do
         if token_table[k].s_name=s then token_table[k].kind_toc:=non_term;
       token_table[i].kind_toc:=head;
    end;
end; {mark_tokens}

begin
end.
