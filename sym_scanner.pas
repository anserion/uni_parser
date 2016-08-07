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
type
t_sym=record 
    kind: (nul,oper,num,ident); {тип идентификатора}
    tag:integer;   {вспомогательный элемент число-метка (зарезервировано)}
    i_name:integer;  {числовое имя-код идентификатора для быстрой обработки}
    s_name:string;   {строковое имя идентификатора}
end;

const max_sym_table_size=100;

type
t_sym_node=record
    sym:t_sym;
    kind: (terminal,non_terminal,meta);
    suc:integer; {номера символов в таблице символов для перехода "совпало"}
    alt:integer; {номера символов в таблице символов для перехода "не совпало"}
end;

const digits=['0'..'9'];
      eng_letters=['A'..'Z','a'..'z'];
      spec_letters=[',',';','!','%','?','#','$','@','&','^',
                    '/','\','|','=','<','>','(',')','{','}',
                    '[',']','+','-','*','.','''','"','`',':','~'];
//локализация не работает на 2 байта/символ UTF8
//      rus_letters=['А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й'];,
//                   'К','Л','М','Н','О','П','Р','С','Т','У','Ф',
//                   'Х','Ц','Ч','Ш','Щ','Ы','Ь','Ъ','Э','Ю','Я',
//                   'а','б','в','г','д','е','ё','ж','з','и','й',
//                   'к','л','м','н','о','п','р','с','т','у','ф',
//                   'х','ц','ч','ш','щ','ы','ь','ъ','э','ю','я'];

procedure error;
procedure getch;
function getsym:t_sym;
function find_symbol_by_name(sym:t_sym):integer;
function find_non_terminal_symbol_by_name(sym:t_sym):integer;
procedure add_symbol_to_table(sym:t_sym);
function getsym_table:t_sym;


var sym_table:array[1..max_sym_table_size] of t_sym_node;
    symbols_num:integer;
    cur_sym_address:integer;
    start_of_file, end_of_file:boolean;

implementation

var ch,ch2: char; {последний прочитанный входной символ и следующий за ним}

procedure error;
begin
   writeln;
   writeln('ERROR');
   halt(-1);
end; {error}

function find_symbol_by_name(sym:t_sym):integer;
var i,res:integer;
begin
    res:=0;
    for i:=1 to symbols_num do
        if sym_table[i].sym.s_name=sym.s_name then res:=i;
    find_symbol_by_name:=res;
end; {find_symbol_by_name}

function find_non_terminal_symbol_by_name(sym:t_sym):integer;
var i,res:integer;
begin
    res:=0;
    for i:=1 to symbols_num do
        if (sym_table[i].sym.s_name=sym.s_name) and
           (sym_table[i].kind=non_terminal) then res:=i;
    find_non_terminal_symbol_by_name:=res;
end; {find_non_terminal_symbol_by_name}

procedure add_symbol_to_table(sym:t_sym);
begin
    if symbols_num<max_sym_table_size then
    begin
        symbols_num:=symbols_num+1;
        sym_table[symbols_num].sym:=sym;
        sym_table[symbols_num].kind:=terminal;
        sym_table[symbols_num].suc:=0;
        sym_table[symbols_num].alt:=0;
    end;
end; {add_symbol_to_table}

function getsym_table:t_sym;
var sym:t_sym;
begin
    sym.s_name:='OUT';
    sym.kind:=nul;
    if cur_sym_address<symbols_num then
    begin
        cur_sym_address:=cur_sym_address+1;
        sym:=sym_table[cur_sym_address].sym;
    end else cur_sym_address:=symbols_num+1;
    getsym_table:=sym;
//    writeln('symbol: ',sym.s_name);    
end; {getsym_table}

{прочитать из потока ввода два символа и поместить их в ch, ch2}
procedure getch;
begin
  if end_of_file then begin write('UNEXPECTED END OF FILE'); halt(-1); end;
  if eof(input) then end_of_file:=true;
  if start_of_file then begin ch:=' '; ch2:=' '; end;
  if end_of_file then begin ch:=ch2; ch2:=' '; end;

  if not(end_of_file) and not(start_of_file) then
  begin ch:=ch2; read(ch2); end;

  if not(end_of_file) and start_of_file then
  begin
     read(ch); start_of_file:=false;
     if not(eof(input)) then read(ch2) else ch2:=' ';
  end;
end {getch};

{найти во входном потоке терминальный символ}
function getsym:t_sym;
var id: t_sym;
begin {getsym}
  {пропускаем возможные пробелы и концы строк}
  while (ch=' ')or(ch=chr(10))or(ch=chr(13)) do getch;

  id.s_name:='';
  id.kind:=nul;

  {если ch - буква или знак подчеркивния, то это - начало имени}
  //локализация не работает на 2-х байтовых символах UTF8
  if ch in ['_']+eng_letters{+rus_letters} then
  begin
    id.kind:=ident;
    {читаем посимвольно имя id[], состоящее из букв A-Z, цифр, подчеркивания}
    repeat
      id.s_name:=id.s_name+ch;
      getch;
    until not(ch in ['_']+eng_letters+digits{+rus_letters}) or end_of_file;
    if (ch in ['_']+eng_letters+digits{+rus_letters}) and end_of_file then
       id.s_name:=id.s_name+ch;
  end
    else
  if ch in digits then {если ch - цифра, то это - начало числа}
  begin
    id.kind:=num;
    repeat
      id.s_name:=id.s_name+ch;
      getch;
    until not(ch in digits) or end_of_file;
    if (ch in digits) and end_of_file then id.s_name:=id.s_name+ch;
    if (ch='.')and(ch2 in digits) then
    begin
      id.s_name:=id.s_name+ch;
      getch;
      repeat
        id.s_name:=id.s_name+ch;
        getch;
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
    if (ch='-')and(ch2='>') then begin id.s_name:='->'; getch; end;
    if (ch='<')and(ch2='-') then begin id.s_name:='<-'; getch; end;
    if (ch='<')and(ch2='>') then begin id.s_name:='<>'; getch; end;
    if (ch='!')and(ch2='=') then begin id.s_name:='!='; getch; end;
    if (ch='=')and(ch2='=') then begin id.s_name:='=='; getch; end;
    if (ch=':')and(ch2='=') then begin id.s_name:=':='; getch; end;
    if (ch='<')and(ch2='=') then begin id.s_name:='<='; getch; end;
    if (ch='>')and(ch2='=') then begin id.s_name:='>='; getch; end;
    if (ch='(')and(ch2='*') then begin id.s_name:='(*'; getch; end;
    if (ch='*')and(ch2=')') then begin id.s_name:='*)'; getch; end;
    if (ch='+')and(ch2='+') then begin id.s_name:='++'; getch; end;
    if (ch='-')and(ch2='-') then begin id.s_name:='--'; getch; end;
    if (ch='*')and(ch2='*') then begin id.s_name:='**'; getch; end;
    if (ch='.')and(ch2='.') then begin id.s_name:='..'; getch; end;
    if (ch=':')and(ch2=':') then begin id.s_name:='::'; getch; end;
    if (ch='/')and(ch2='/') then begin id.s_name:='//'; getch; end;
    if (ch='|')and(ch2='|') then begin id.s_name:='||'; getch; end;
    if (ch='&')and(ch2='&') then begin id.s_name:='&&'; getch; end;
    if (ch='^')and(ch2='^') then begin id.s_name:='^^'; getch; end;
    {смайлики :) }
    if (ch=':')and(ch2=')') then begin id.s_name:=':)'; getch; end;
    if (ch=':')and(ch2='(') then begin id.s_name:=':('; getch; end;
    if (ch=':')and(ch2=']') then begin id.s_name:=':]'; getch; end;
    if (ch=':')and(ch2='[') then begin id.s_name:=':['; getch; end;

    if not(end_of_file) then getch;
  end
    else
  begin
    id.s_name:=ch;
    id.kind:=nul;
    if not(end_of_file) then getch;
  end;
  getsym:=id;
//  writeln('symbol: ',id.s_name);
end {getsym};
//==================================================================

var i:integer; sym:t_sym;
begin
  //инициализация
  start_of_file:=true; end_of_file:=false;
  symbols_num:=0; cur_sym_address:=0;
  getch; sym:=getsym;
  
  //читаем все символы из файла в таблицу символов
  while(sym.s_name<>'$') do
  begin
    add_symbol_to_table(sym);
    sym:=getsym;
  end;

for i:=1 to symbols_num do
    writeln('kind: ',sym_table[i].kind, ', symbol: ',sym_table[i].sym.s_name);
writeln('Symbols table OK');
writeln('================');
end.
