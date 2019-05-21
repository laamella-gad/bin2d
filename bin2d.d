/*
	Copyright (C) 2006 Christopher E. Miller
	
	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.
	
	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:
	
	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgment in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
*/


import std.file;
import std.stdio;
import std.path;
import std.uni;
import std.conv;

int main(char[][] args) {
    char[] infn, outfn;
    bool createNew = false, preserveIdCase = false, nextNewLine = false, useVar = false,
    nextId = false;
    char[] newline;
    char[]  argid;

    newline ~= lineSep;

    foreach (char[] arg; args[1 .. args.length]) {
        if (!arg.length)
            continue ;

        if (nextNewLine) {
            nextNewLine = false;
            switch (arg) {
                case "lf": newline = "\n".dup; break ;
                case "cr": newline = "\r".dup; break ;
                case "crlf": newline = "\r\n".dup; break ;
                default: 
                string msg = to!string("Unknown line ending; expected lf, cr or crlf, not " ~ arg);
                throw new Exception(msg);
            }
            continue ;
        }

        if (nextId) {
            nextId = false;
            argid = arg;
            continue ;
        }

        if ('-' == arg[0] || '/' == arg[0]) {
            switch (arg[1 .. arg.length]) {
                case"n":
                createNew = true;
                break ;
                case"p":
                preserveIdCase = true;
                break ;
                case"l":
                nextNewLine = true;
                break ;
                case"var":
                useVar = true;
                break ;
                case"id":
                nextId = true;
                break ;

                case"h", "?", "help":
                break ;

                default:
                throw new Exception(to!string("Unrecognized switch " ~ arg));
            }
        }
        else {
            if (!infn.length){
                infn = arg;
            }
            else if (!outfn.length){
                outfn = arg;
            }
            else {
                throw new Exception("Too many arguments");
            }
        }
    }

    if (!infn.length){
        writef("Binary to D 1.0 written by Christopher E. Miller
Usage:
   bintod [<switches>] <infile> [<outfile>]
Switches:
   -n     New output file; do not append
   -p     Preserve case of identifier; do not force uppercase
   -l     Next argument is line ending: lf, cr or crlf
   -var   Make a variable instead of const
   -id    Next argument is identifier name
Example:
   bintod -l crlf -var -id clownPicture clown.jpg clown.d
");
        return 0;
    }

    size_t iw;

    char[] safename;
    safename = new char[infn.length];
    iw = 0;
    foreach (char ch; infn){
        if (isAlphaNum(ch) || '_' == ch)
            safename[iw++] = ch;
        else if ('.' == ch)
            safename[iw++] = '_';
    }
    safename = safename[0 .. iw];

    if (!outfn.length){
        outfn = safename ~ ".d";
    }

    if (argid.length){
        safename = argid; // Not necessarily safe; trust the user.
    }else if (!useVar){
        if (!preserveIdCase){
            safename = "BINARY_" ~ toUpper(safename);
        }else {
            safename = "binary_" ~ safename; // ?
        }
    }else {
        safename = "binary_" ~ safename;
    }

    File sin, sout;
    int existed = false;

    sin = File(to!string(infn));
    if (createNew){
        sout = File(outfn, "w");
    }else {
        existed = exists(outfn);
        sout = File(outfn, "a");

        if (existed){
            sout.writeln();
        }
    }

    sout.writef("%subyte[%d] %s =%s[%s\t", useVar ? "" : "const ", sin.size(), safename, newline, newline);

    ubyte[1] ub;
    for (iw = 0;; iw++){
        ubyte[] r=sin.rawRead(ub);
        if (1 != r.length)
            break ;
        if (16 == iw){
            iw = 0;
            sout.writef("%s\t", newline);
        }
        sout.writef("0x%0.2X, ", r[0]);
    }

    sout.writef("%s];%s%s", newline, newline, newline);

    writefln("Successfully created identifier %s in file '%s'", safename, outfn);

    return 0;
}


