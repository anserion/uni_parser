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

//разбор соответствия входного потока символов правилам языка
procedure parse(goal:integer; var cur_sym:integer; var match:boolean);
var s:integer; exclude,parse_flag,alternate_flag,empty_flag:boolean;
    exclude_off_flag:boolean;
begin
  writeln('"',token_table[goal].s_name,'"-->',goal);
  exclude:=false;
  s:=token_table[goal].entry;
  repeat
    writeln('"',token_table[goal].s_name,'":',s,
            ' ',token_table[s].kind_toc,
            ' ',token_table[s].kind_sym,
            ' "',token_table[s].s_name,
            '", test sym="',prg_table[cur_sym].s_name,'":',cur_sym);

    parse_flag:=false;
    alternate_flag:=false;
    empty_flag:=false;
    exclude_off_flag:=false;
    if token_table[s].s_name='EXCLUDE_ON' then
    begin
      exclude:=true; s:=token_table[s].suc;
      writeln('  EXCLUDE_ON, s=',s);
    end;

    if token_table[s].s_name='EXCLUDE_OFF' then
    begin
      exclude:=false; s:=token_table[s].suc;
      exclude_off_flag:=true;
      writeln('  EXCLUDE_OFF, s=',s);
    end;

    if s<>0 then
    begin
      if (token_table[s].kind_toc=terminal) then
      begin
        if token_table[s].s_name='ANY' then
        begin
          match:=not(exclude);
          writeln('  ANY "',prg_table[cur_sym].s_name,'" ',match,': ',s);
        end else
        if token_table[s].s_name='ONE_ANY_CHAR' then
        begin
          if length(prg_table[cur_sym].s_name)=1 then
          begin
            match:=not(exclude);
            writeln('  ONE_ANY_CHAR "',prg_table[cur_sym].s_name,'" ',match,': ',s);
          end;
        end else
        if token_table[s].s_name='EMPTY' then
        begin
          match:=not(exclude); empty_flag:=true;
          if match then writeln('  EMPTY ',match,': ',s);
        end else
        if (token_table[s].s_name=prg_table[cur_sym].s_name) then
        begin
          match:=not(exclude);
          writeln('  "',prg_table[cur_sym].s_name,'" ',match,': ',s);
        end else
        if exclude and (token_table[s].s_name<>prg_table[cur_sym].s_name) then
        begin
          match:=true;
          writeln('  "',prg_table[cur_sym].s_name,'" ',match,': ',s);
        end else
        begin
          alternate_flag:=true;
          match:=(token_table[s].alt=-1);
          //if exclude then match:=not(match);
          writeln('  Alternate exit=',match);
        end;
      end else
      begin
        parse_flag:=true;
        parse(token_table[s].entry,cur_sym,match);
        if exclude then match:=not(match);
        writeln('  back addr=',s,' <--',match);
      end;

      if not(empty_flag or alternate_flag or parse_flag or (s<=0)) then
         cur_sym:=skip_nul(cur_sym+1,prg_symbols_num,prg_table);

      if match then
      begin
        s:=token_table[s].suc;
        writeln('  suc=',s);
      end else
      begin
        s:=token_table[s].alt;
        writeln('  alt=',s);
      end;

    end; {if s<>0}
  until s<=0;
//  if s=-1 then match:=not(exclude);
  if exclude_off_flag then cur_sym:=skip_nul(cur_sym+1,prg_symbols_num,prg_table);
  writeln('"',token_table[goal].s_name,'"<--',match);
end; {parse}

//=========================================================================

var
  i,goal,address:integer;
  match:boolean;

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

//  writeln('RBNF tokens: ',tokens_num);
//  for i:=1 to tokens_num do
//      writeln(i:3,
//              ': ',token_table[i].kind_sym:5,
//              '  ',token_table[i].kind_toc:8,
//              ' "',token_table[i].s_name,'"');
//  writeln('===============================');

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

  //поиск точки входа: первое правило РБНФ
  goal:=1; while token_table[goal].kind_toc<>head do goal:=goal+1;
  writeln('goal: ',token_table[goal].s_name,', address=',goal);

  //проверка синтаксиса программы
  address:=1; match:=true;
  parse(goal,address,match);
  writeln('"',prg_table[address].s_name,'"');
  if match then writeln('CORRECT') else writeln('INCORRECT');
end.
