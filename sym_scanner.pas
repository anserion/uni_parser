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

const max_sym_table_size=100;
      digits=['0'..'9'];
      eng_letters=['A'..'Z','a'..'z'];
      spec_letters=[',',';','!','%','?','#','$','@','&','^',
                    '/','\','|','=','<','>','(',')','{','}',
                    '[',']','+','-','*','.','''','"','`',':','~'];
//локализация не работает на 2 байта/символ UTF8
      rus_cp1251_letters=['�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�',
                          '�','�','�','�','�','�','�','�','�','�','�'];

      rus_cp866_letters=['�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�'];

      rus_koi8r_letters=['�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�',
                         '�','�','�','�','�','�','�','�','�','�','�'];

type
t_charfile=file of char;

t_sym=record 
    kind: (nul,oper,num,ident); {тип идентификатора}
    tag:integer;   {вспомогательный элемент число-метка (зарезервировано)}
    i_name:integer;  {числовое имя-код идентификатора для быстрой обработки}
    s_name:string;   {строковое имя идентификатора}
end;

t_sym_table=array[1..max_sym_table_size] of t_sym;

procedure sym_table_read_from_file(filename: string;
                                   var sym_table:t_sym_table;
                                   var symbols_num:integer);

implementation

var ch,ch2: char; {последний прочитанный входной символ и следующий за ним}
    start_of_file, end_of_file:boolean;

{прочитать из потока ввода два символа и поместить их в ch, ch2}
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

{найти во входном потоке терминальный символ}
function getsym(var f:t_charfile):t_sym;
var id: t_sym;
begin {getsym}
  {пропускаем возможные пробелы и концы строк}
  while (ch=' ')or(ch=chr(10))or(ch=chr(13)) do getch(f,ch,ch2);

  id.s_name:='';
  id.kind:=nul;

  {если ch - буква или знак подчеркивния, то это - начало имени}
  //локализация не работает на 2-х байтовых символах UTF8
  if (ch in ['_']+eng_letters+rus_cp1251_letters) then
  begin
    id.kind:=ident;
    {читаем посимвольно имя id[], состоящее из букв A-Z, цифр, подчеркивания}
    repeat
      id.s_name:=id.s_name+ch;
      getch(f,ch,ch2);
    until not(ch in ['_']+eng_letters+digits+rus_cp1251_letters) or end_of_file;
    if (ch in ['_']+eng_letters+digits+rus_cp1251_letters) and end_of_file then
       id.s_name:=id.s_name+ch;
  end
    else
  if ch in digits then {если ch - цифра, то это - начало числа}
  begin
    id.kind:=num;
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
  begin {односимвольный и некоторые двусимвольные идентификаторы}
    id.kind:=oper;
    {односимвольные спецсимволы}
    id.s_name:=ch;
    {разбор случаев двусимвольных спецкомбинаций}
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
    if (ch=':')and(ch2=':') then begin id.s_name:='::'; getch(f,ch,ch2); end;
    if (ch='/')and(ch2='/') then begin id.s_name:='//'; getch(f,ch,ch2); end;
    if (ch='|')and(ch2='|') then begin id.s_name:='||'; getch(f,ch,ch2); end;
    if (ch='&')and(ch2='&') then begin id.s_name:='&&'; getch(f,ch,ch2); end;
    if (ch='^')and(ch2='^') then begin id.s_name:='^^'; getch(f,ch,ch2); end;
    {смайлики :) }
    if (ch=':')and(ch2=')') then begin id.s_name:=':)'; getch(f,ch,ch2); end;
    if (ch=':')and(ch2='(') then begin id.s_name:=':('; getch(f,ch,ch2); end;
    if (ch=':')and(ch2=']') then begin id.s_name:=':]'; getch(f,ch,ch2); end;
    if (ch=':')and(ch2='[') then begin id.s_name:=':['; getch(f,ch,ch2); end;

    if not(end_of_file) then getch(f,ch,ch2);
  end
    else
  begin
    id.s_name:=ch;
    id.kind:=nul;
    if not(end_of_file) then getch(f,ch,ch2);
  end;
  writeln('symbol: ',id.s_name);
  getsym:=id;
end {getsym};
//==================================================================

procedure sym_table_read_from_file(filename: string;
                                   var sym_table:t_sym_table;
                                   var symbols_num:integer);
var f:t_charfile; sym:t_sym;
begin
  start_of_file:=true; end_of_file:=false;
  symbols_num:=0; 
  assign(f,filename);
  reset(f);
  getch(f,ch,ch2); sym:=getsym(f);
  //читаем все символы из файла в таблицу символов
  while (sym.s_name<>'end_of_file') do
  begin
    symbols_num:=symbols_num+1;
    sym_table[symbols_num]:=sym;
    sym:=getsym(f);
  end;
  close(f);
end;

var i:integer;
    sym_table:array[1..max_sym_table_size] of t_sym;
    symbols_num:integer;

begin
sym_table_read_from_file('rbnf_rules.bnf',sym_table,symbols_num);
for i:=1 to symbols_num do
    writeln('kind: ',sym_table[i].kind, ', symbol: ',sym_table[i].s_name);
writeln('Symbols table OK');
writeln('================');
end.
