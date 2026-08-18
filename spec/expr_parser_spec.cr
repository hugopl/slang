require "./spec_helper"

private def parse(source : String)
  Slang::Expr::Parser.parse(source)
end

describe Slang::Expr::Parser do
  it "parses a plain identifier" do
    node = parse("user").as(Slang::Expr::Var)
    node.name.should eq("user")
  end

  it "parses dotted access" do
    node = parse("user.name").as(Slang::Expr::Access)
    node.member.should eq("name")
    node.base.as(Slang::Expr::Var).name.should eq("user")
  end

  it "parses indexing" do
    node = parse("items[0]").as(Slang::Expr::Index)
    node.base.as(Slang::Expr::Var).name.should eq("items")
    node.index.as(Slang::Expr::Literal).value.should eq(0_i64)
  end

  it "parses literals" do
    parse("42").as(Slang::Expr::Literal).value.should eq(42_i64)
    parse("4.5").as(Slang::Expr::Literal).value.should eq(4.5)
    parse("\"hi\"").as(Slang::Expr::Literal).value.should eq("hi")
    parse("true").as(Slang::Expr::Literal).value.should eq(true)
    parse("false").as(Slang::Expr::Literal).value.should eq(false)
    parse("nil").as(Slang::Expr::Literal).value.should be_nil
  end

  it "parses comparisons" do
    node = parse("user.age >= 18").as(Slang::Expr::BinaryOp)
    node.op.should eq(">=")
    node.left.as(Slang::Expr::Access).member.should eq("age")
    node.right.as(Slang::Expr::Literal).value.should eq(18_i64)
  end

  it "parses equality, and/or with correct precedence" do
    node = parse("a == 1 && b == 2 || c").as(Slang::Expr::BinaryOp)
    node.op.should eq("||")
    left = node.left.as(Slang::Expr::BinaryOp)
    left.op.should eq("&&")
    node.right.as(Slang::Expr::Var).name.should eq("c")
  end

  it "parses unary negation" do
    node = parse("!user.active").as(Slang::Expr::UnaryOp)
    node.op.should eq("!")
    node.operand.as(Slang::Expr::Access).member.should eq("active")
  end

  it "parses parenthesized sub-expressions" do
    node = parse("(a == 1)").as(Slang::Expr::BinaryOp)
    node.op.should eq("==")
  end

  it "parses a bare function call" do
    node = parse("form_for(record)").as(Slang::Expr::Call)
    node.callee.should eq("form_for")
    node.receiver.should be_nil
    node.args.size.should eq(1)
    node.args[0].as(Slang::Expr::Var).name.should eq("record")
  end

  it "parses a method call on a receiver" do
    node = parse("helpers.form_for(record, 1)").as(Slang::Expr::Call)
    node.callee.should eq("form_for")
    node.receiver.should be_a(Slang::Expr::Var)
    node.receiver.as(Slang::Expr::Var).name.should eq("helpers")
    node.args.size.should eq(2)
  end

  it "raises on trailing garbage" do
    expect_raises(Slang::Expr::ParseError) { parse("a b") }
  end

  it "raises on unterminated string" do
    expect_raises(Slang::Expr::ParseError) { parse("\"unterminated") }
  end
end
