//          Copyright Brian Schott 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module analysis.fish;

import stdx.d.ast;
import stdx.d.lexer;
import analysis.base;

/**
 * Checks for use of the deprecated floating point comparison operators.
 */
class FloatOperatorCheck : BaseAnalyzer
{
	alias visit = BaseAnalyzer.visit;

	this(string fileName)
	{
		super(fileName);
	}

	override void visit(const RelExpression r)
	{
		if (r.operator == tok!"<>"
			|| r.operator == tok!"!<>"
			|| r.operator == tok!"!>"
			|| r.operator == tok!"!<"
			|| r.operator == tok!"!<>="
			|| r.operator == tok!"!>="
			|| r.operator == tok!"!<=")
		{
			addErrorMessage(r.line, r.column, "Avoid using the deprecated floating-point operators");
		}
		r.accept(this);
	}
}
