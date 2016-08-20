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
procedure parse(level,goal:integer; var cur_sym:integer; var match:boolean);
var s:integer; exclude,alter_exit:boolean;
begin
  exclude:=false;
  s:=token_table[goal].entry;
  writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,' entry ',s);
  repeat
    alter_exit:=false;
    if token_table[s].s_name='EXCLUDE_ON' then
    begin
      writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,
              ' ',s,':EXCLUDE_ON:',token_table[s].suc,':',token_table[s].alt);
      exclude:=true; s:=token_table[s].suc;
    end;

    if token_table[s].s_name='EXCLUDE_OFF' then
    begin
      writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,
              ' ',s,':EXCLUDE_OFF:',token_table[s].suc,':',token_table[s].alt);
      exclude:=false; s:=token_table[s].suc;
      cur_sym:=skip_nul(cur_sym+1,prg_symbols_num,prg_table);
    end;

    if (s>0)and(cur_sym<=prg_symbols_num) then
    begin
      if (token_table[s].kind_toc=terminal) then
      begin
        write('LEVEL_',level,':',token_table[goal].s_name,':',goal,
              ' ',s,':"',token_table[s].s_name,'":',token_table[s].suc,':',token_table[s].alt);
        if token_table[s].s_name<>'EMPTY' then write(' = "',prg_table[cur_sym].s_name,'":',cur_sym);
        if exclude then match:=(token_table[s].s_name<>prg_table[cur_sym].s_name)
        else
        begin
          if (token_table[s].s_name='ANY')or
             ((token_table[s].s_name='ONE_ANY_CHAR')and(length(prg_table[cur_sym].s_name)=1))or
             (token_table[s].s_name='EMPTY')or
             (token_table[s].s_name=prg_table[cur_sym].s_name) then
          begin
            match:=true;
            if token_table[s].s_name<>'EMPTY' then
               cur_sym:=skip_nul(cur_sym+1,prg_symbols_num,prg_table);
          end else
          if token_table[s].alt=-1 then
          begin
            match:=true; alter_exit:=true;
          end else match:=false;
        end;
        if not(alter_exit) then writeln(' ',match) else writeln(' ALTER_EXIT');
      end else
      begin
        writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,
                ' ',s,':"',token_table[token_table[s].entry].s_name,'"-->',token_table[s].entry,' NON_TERMINAL');
        parse(level+1,token_table[s].entry,cur_sym,match);
        if exclude then match:=not(match);
      end;
      if match then s:=token_table[s].suc else s:=token_table[s].alt;
      if s=-1 then s:=0;
    end;
  until (s=0)or(alter_exit)or(cur_sym>prg_symbols_num);
  writeln('LEVEL_',level,':',token_table[goal].s_name,':',goal,' ',match);
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
  parse(1,goal,address,match);
  if match then writeln('CORRECT') else writeln('INCORRECT');
end.
