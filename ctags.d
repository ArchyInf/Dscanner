//          Copyright Brian Schott (Sir Alaran) 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module ctags;

import stdx.d.parser;
import stdx.d.lexer;
import stdx.d.ast;
import std.algorithm;
import std.range;
import std.stdio;
import std.array;
import std.conv;

void printCtags(File output, string[] fileNames)
{
	void doNothing(string, size_t, size_t, string, bool) {}
	string[] tags;
	LexerConfig config;
	shared(StringCache)* cache = new shared StringCache(StringCache.defaultBucketCount);
	foreach (fileName; fileNames)
	{
		File f = File(fileName);
		auto bytes = uninitializedArray!(ubyte[])(to!size_t(f.size));
		f.rawRead(bytes);
		auto tokens = byToken(bytes, config, cache);
		Module m = parseModule(tokens.array, fileName, null, &doNothing);
		auto printer = new CTagsPrinter;
		printer.fileName = fileName;
		printer.visit(m);
		tags ~= printer.tagLines;
	}
	output.write("!_TAG_FILE_FORMAT\t2\n"
			~ "!_TAG_FILE_SORTED\t1\n"
			~ "!_TAG_FILE_AUTHOR\tBrian Schott\n"
			~ "!_TAG_PROGRAM_URL\thttps://github.com/Hackerpilot/Dscanner/\n");
	tags.sort().copy(output.lockingTextWriter);
}

class CTagsPrinter : ASTVisitor
{
	override void visit(const ClassDeclaration dec)
	{
		tagLines ~= "%s\t%s\t%d;\"\tc%s\n".format(dec.name.text, fileName, dec.name.line, context);
		auto c = context;
		context = "\tclass:" ~ dec.name.text;
		dec.accept(this);
		context = c;
	}

	override void visit(const StructDeclaration dec)
	{
		tagLines ~= "%s\t%s\t%d;\"\ts%s\n".format(dec.name.text, fileName, dec.name.line, context);
		auto c = context;
		context = "\tstruct:" ~ dec.name.text;
		dec.accept(this);
		context = c;
	}

	override void visit(const InterfaceDeclaration dec)
	{
		tagLines ~= "%s\t%s\t%d;\"\ti%s\n".format(dec.name.text, fileName, dec.name.line, context);
		auto c = context;
		context = "\tclass:" ~ dec.name.text;
		dec.accept(this);
		context = c;
	}

	override void visit(const TemplateDeclaration dec)
	{
		tagLines ~= "%s\t%s\t%d;\"\tT%s\n".format(dec.name.text, fileName, dec.name.line, context);
		auto c = context;
		context = "\ttemplate:" ~ dec.name.text;
		dec.accept(this);
		context = c;
	}

	override void visit(const FunctionDeclaration dec)
	{
		tagLines ~= "%s\t%s\t%d;\"\tf\tarity:%d%s\n".format(dec.name.text, fileName,
			dec.name.line, dec.parameters.parameters.length, context);
		auto c = context;
		context = "\tfunction:" ~ dec.name.text;
		dec.accept(this);
		context = c;
	}

	override void visit(const EnumDeclaration dec)
	{
		if (dec.name == tok!"")
		{
			dec.accept(this);
			return;
		}
		tagLines ~= "%s\t%s\t%d;\"\tg%s\n".format(dec.name.text, fileName,
			dec.name.line, context);
		auto c = context;
		context = "\tenum:" ~ dec.name.text;
		dec.accept(this);
		context = c;
	}

	override void visit(const UnionDeclaration dec)
	{
		if (dec.name == tok!"")
		{
			dec.accept(this);
			return;
		}
		tagLines ~= "%s\t%s\t%d;\"\tu%s\n".format(dec.name.text, fileName,
			dec.name.line, context);
		auto c = context;
		context = "\tunion:" ~ dec.name.text;
		dec.accept(this);
		context = c;
	}

	override void visit(const EnumMember mem)
	{
		tagLines ~= "%s\t%s\t%d;\"\te%s\n".format(mem.name.text, fileName,
			mem.name.line, context);
	}

	override void visit(const VariableDeclaration dec)
	{
		foreach (d; dec.declarators)
		{
			tagLines ~= "%s\t%s\t%d;\"\tv%s\n".format(d.name.text, fileName,
				d.name.line, context);
		}
		dec.accept(this);
	}

	alias visit = ASTVisitor.visit;

	string fileName;
	string[] tagLines;
	int suppressDepth;
	string context;
}
