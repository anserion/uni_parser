#!/bin/sh
fpc token_utils.pas
fpc sym_scanner.pas
fpc rbnf_scanner.pas
fpc rbnf_gen.pas
fpc uni_parser.pas
./uni_parser > report.txt
