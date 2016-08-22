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

unit sym_scanner;

interface
uses token_utils;

function symbols_from_file(f: string;var token_table:t_token_table):integer;

implementation

var ch,ch2: char;
    start_of_file, end_of_file:boolean;

procedure getch(var f:t_charfile; var ch,ch2:char);
begin
  if end_of_file then begin write('UNEXPECTED END OF FILE'); halt(-1); end;
  if eof(f) then end_of_file:=true;
  if start_of_file then begin ch:=' '; ch2:=' '; end;
  if end_of_file then begin ch:=ch2; ch2:=' '; end;

  if not(end_of_file) and not(start_of_file) then
  begin ch:=ch2; read(f,ch2); end;

  if not(end_of_file) and start_of_file then
  begin
     read(f,ch); start_of_file:=false;
     if not(eof(f)) then read(f,ch2) else ch2:=' ';
  end;
end {getch};

function getsym(var f:t_charfile):t_token;
var id: t_token;
begin {getsym}
  while (ch=chr(10))or(ch=chr(13)) do getch(f,ch,ch2);

  id.s_name:='';
  id.kind_sym:=nul;

  if ch='"' then
  begin
    id.kind_sym:=ident;
    id.s_name:='';
    repeat
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
    until (ch='"')or end_of_file;
    id.s_name:=id.s_name+'"';
    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  if ch=':' then
  begin
    id.kind_sym:=oper;
    id.s_name:=':';
    if ch2=':' then
    begin
      id.s_name:='::';
      if not(end_of_file) then getch(f,ch,ch2);
      if ch2='=' then
      begin
        id.s_name:='::=';
        if not(end_of_file) then getch(f,ch,ch2);
      end;
    end;
    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  if (ch in ['_']+eng_letters+rus_cp1251_letters) then
  begin
    id.kind_sym:=ident;
    repeat
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
    until not(ch in ['_']+eng_letters+digits+rus_cp1251_letters) or end_of_file;
    if (ch in ['_']+eng_letters+digits+rus_cp1251_letters) and end_of_file then
       id.s_name:=id.s_name+ch;
  end
    else
  if ch in digits then
  begin
    id.kind_sym:=num;
    repeat
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
    until not(ch in digits) or end_of_file;
    if (ch in digits) and end_of_file then id.s_name:=id.s_name+ch;
    if (ch='.')and(ch2 in digits) then
    begin
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
      repeat
        id.s_name:=id.s_name+ch;
        getch(f,ch,ch2);
      until not(ch in digits) or end_of_file;
      if (ch in digits) and end_of_file then id.s_name:=id.s_name+ch
    end;
  end
    else
  if ch in spec_letters then
  begin
    id.kind_sym:=oper;
    id.s_name:=ch;
    if (ch='-')and(ch2='>') then begin id.s_name:='->'; getch(f,ch,ch2); end;
    if (ch='<')and(ch2='-') then begin id.s_name:='<-'; getch(f,ch,ch2); end;
    if (ch='<')and(ch2='>') then begin id.s_name:='<>'; getch(f,ch,ch2); end;
    if (ch='!')and(ch2='=') then begin id.s_name:='!='; getch(f,ch,ch2); end;
    if (ch='=')and(ch2='=') then begin id.s_name:='=='; getch(f,ch,ch2); end;
    if (ch=':')and(ch2='=') then begin id.s_name:=':='; getch(f,ch,ch2); end;
    if (ch='<')and(ch2='=') then begin id.s_name:='<='; getch(f,ch,ch2); end;
    if (ch='>')and(ch2='=') then begin id.s_name:='>='; getch(f,ch,ch2); end;
    if (ch='(')and(ch2='*') then begin id.s_name:='(*'; getch(f,ch,ch2); end;
    if (ch='*')and(ch2=')') then begin id.s_name:='*)'; getch(f,ch,ch2); end;
    if (ch='+')and(ch2='+') then begin id.s_name:='++'; getch(f,ch,ch2); end;
    if (ch='-')and(ch2='-') then begin id.s_name:='--'; getch(f,ch,ch2); end;
    if (ch='*')and(ch2='*') then begin id.s_name:='**'; getch(f,ch,ch2); end;
    if (ch='.')and(ch2='.') then begin id.s_name:='..'; getch(f,ch,ch2); end;
//    if (ch=':')and(ch2=':') then begin id.s_name:='::'; getch(f,ch,ch2); end;
    if (ch='/')and(ch2='/') then begin id.s_name:='//'; getch(f,ch,ch2); end;
    if (ch='|')and(ch2='|') then begin id.s_name:='||'; getch(f,ch,ch2); end;
    if (ch='&')and(ch2='&') then begin id.s_name:='&&'; getch(f,ch,ch2); end;
    if (ch='^')and(ch2='^') then begin id.s_name:='^^'; getch(f,ch,ch2); end;
    if (ch='''')and(ch2='''') then begin id.s_name:=''''''; getch(f,ch,ch2); end;
//    if (ch='"')and(ch2='"') then begin id.s_name:='""'; getch(f,ch,ch2); end;
//    if (ch='[')and(ch2=']') then begin id.s_name:='[]'; getch(f,ch,ch2); end;

    if (ch='\')and(ch2='.') then begin id.s_name:='.'; getch(f,ch,ch2); end;
    if (ch='\')and(ch2=',') then begin id.s_name:=','; getch(f,ch,ch2); end;
    if (ch='\')and(ch2='[') then begin id.s_name:='['; getch(f,ch,ch2); end;
    if (ch='\')and(ch2=']') then begin id.s_name:=']'; getch(f,ch,ch2); end;
    if (ch='\')and(ch2=' ') then begin id.s_name:=' '; getch(f,ch,ch2); end;
    if (ch='\')and(ch2='\') then begin id.s_name:='\'; getch(f,ch,ch2); end;

    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  begin
    id.s_name:=ch;
    id.kind_sym:=nul;
    if not(end_of_file) then getch(f,ch,ch2);
  end;
//  writeln('symbol: ',id.s_name);
  getsym:=id;
end {getsym};
//==================================================================

function symbols_from_file(f: string;var token_table:t_token_table):integer;
var ff:t_charfile; sym:t_token; symbols_num:integer;
begin
  start_of_file:=true; end_of_file:=false; ch:=' '; ch2:=' ';
  symbols_num:=0; 
  assign(ff,f);
  reset(ff);
  getch(ff,ch,ch2); sym:=getsym(ff);

  while (sym.s_name<>'end_of_file') do
  begin
    symbols_num:=symbols_num+1;
    token_table[symbols_num]:=sym;
    sym:=getsym(ff);
  end;
  close(ff);
  symbols_from_file:=symbols_num;
end;

begin
end.

