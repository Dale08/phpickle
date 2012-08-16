OP: MARK	// ( push special markobject on stack)
-- read:
$stack->push_mark();
--write:

OP: STOP	// ( every pickle ends with STOP)
-- read:
throw new Exception("STOP");
--write:

OP: POP	// ( discard topmost stack item)
-- read:
$stack->pop();
--write:

OP: POP_MARK	// ( discard stack top through topmost markobject)
-- read:
$stack->pop_until_mark();
--write:

OP: DUP	// ( duplicate top stack item)
-- read:
$stack->push($stack->get_top());
--write:

OP: FLOAT	// ( push float object; decimal string argument)
-- read:
$stack->push(floatval($stream->get_line()));
--write:

OP: INT	// ( push integer or bool; decimal string argument)
-- read:
$line = trim($stream->get_line());
if ($line === "01")
{
	$stack->push(true);
}
else
if ($line === "00")
{
	$stack->push(false);
}
else
{
	$stack->push(intval(trim($line)));
}
--write:

OP: BININT	// ( push four-byte signed int)
-- read:
$av = unpack("lint", $stream->get_bytes(4));
$stack->push($av["int"]);
--write:

OP: BININT1	// ( push 1-byte unsigned int)
-- read:
$av = unpack("Cint", $stream->get_byte());
$stack->push($av["int"]);
if ($debug)
{
	echo "BININT1: val: $av[int] \r\n";
}
--write:

OP: LONG	// ( push long; decimal string argument)
-- read:
$line = trim($stream->get_line());
if (substr($line, -1) == "L")
{
	$line = substr($line, 0, -1);
}
$stack->push(intval(trim($line)));
--write:

OP: BININT2	// ( push 2-byte unsigned int)
-- read:
$av = unpack("lint", $stream->get_bytes(2)."\x00\x00");
$stack->push($av["int"]);
--write:

OP: NONE	// ( push None)
-- read:
$stack->push(null);
--write:

OP: PERSID	// ( push persistent object; id is taken from string arg)
-- read:
// TODO: we are not handling persistent load handlers
$stream->get_line();
$stack->push(NULL);
--write:

OP: BINPERSID	// (  "       "         "  ;  "  "   "     "  stack)
-- read:
$stack->pop();
$stack->push(null);
--write:

OP: REDUCE	// ( apply callable to argtuple, both on stack)
-- read:
// TODO: not supported
$d1 = $stack->pop();
$d2 = $stack->pop();
$stack->push(null);
if ($debug)
{
	echo "REDUCE: arg1(",var_dump($d1),"), arg2(",var_dump($d2),") \r\n";
}
--write:

OP: STRING	// ( push string; NL-terminated string argument)
-- read:
// TODO: almost
$s = trim($stream->get_line());
if ($s[0] == substr($s, -1))
{
	$s = substr($s, 1, -1);
}
else
{
	throw new Exception("incorrectly quoted string in pickle: $s");
}
$stack->push($s);
--write:

OP: BINSTRING	// ( push string; counted binary string argument)
-- read:
$av = unpack("Lval", $stream->get_bytes(4));
$len = $av["val"];
$stack->push($stream->get_bytes($len));
--write:

OP: SHORT_BINSTRING	//  "     "   ;    "      "       "      " < 256 bytes
-- read:
$len = ord($stream->get_char());
$stack->push($stream->get_bytes($len));
if ($debug)
{
	echo "SHORT_BINSTRING: len: $len, str: ".$stack->get_top()." \r\n";
}
--write:

OP: UNICODE	// ( push Unicode string; raw-unicode-escaped'd argument)
-- read:
// TODO: not quite
$stack->push($stream->get_line());
--write:

OP: BINUNICODE	// (   "     "       "  ; counted UTF-8 string argument)
-- read:
$av = unpack("Lval", $stream->get_bytes(4));
$len = $av["val"];
$stack->push($stream->get_bytes($len));
--write:

OP: APPEND	// ( append stack top to list below it)
-- read:
$item = $stack->pop();
$list = $stack->pop();
$list[] = $item;
$stack->push($list);
--write:

OP: BUILD	// ( call __setstate__ or __dict__.update())
-- read:
// TODO: not complete
$stack->pop();
--write:

OP: GLOBAL	// ( push self.find_class(modname, name); 2 string args)
-- read:
$module = $stream->get_line();
$name = $stream->get_line();
$stack->push($module."::".$name);
if ($debug)
{
	echo "GLOBAL: module($module), name($name) \r\n";
}
--write:

OP: DICT	// ( build a dict from stack items)
-- read:
$vals = $stack->pop_until_mark();
$d = array();
$len = count($vals);
for ($i = 0; $i < $len; $i+=2)
{
	$d[$vals[$i]] = $vals[$i+1];
}
$stack->push($d);
--write:

OP: EMPTY_DICT	// ( push empty dict)
-- read:
$stack->push(array());
--write:

OP: APPENDS	// ( extend list on stack by topmost stack slice)
-- read:
$items = $stack->pop_until_mark();
$list = $stack->pop();
foreach($items as $item)
{
	$list[] = $item;
}
$stack->push($list);
--write:

OP: GET	// ( push item from memo on stack; index is string arg)
-- read:
$index = intval(trim($stream->get_line()));
$stack->push($memo->get($index));
--write:

OP: BINGET	// (   "    "    "    "   "   "  ;   "    " 1-byte arg)
-- read:
$index = ord($stream->get_byte());
$stack->push($memo->get($index));
--write:

OP: INST	// ( build & push class instance)
-- read:
$module = $stream->get_line();
$name = $stream->get_line();
$cl = new stdClass;
$cl->module = $module;
$cl->name = $name;
$stack->push($cl);
--write:

OP: LONG_BINGET	// ( push item from memo on stack; index is 4-byte arg)
-- read:
$av = unpack("Lval", $stream->get_bytes(4));
$index = $av["val"];
$stack->push($memo->get($index));

--write:

OP: LIST	// ( build list from topmost stack items)
-- read:
$vals = $stack->pop_until_mark();
$stack->push($vals);
--write:

OP: EMPTY_LIST	// ( push empty list)
-- read:
$stack->push(array());
--write:

OP: OBJ	// ( build & push class instance)
-- read:
// TODO: not quite
$d = $stack->pop_until_mark();
$stack->push(new stdClass);
--write:

OP: PUT	// ( store stack top in memo; index is string arg)
-- read:
$index = intval(trim($stream->get_line()));
$memo->set($index, $stack->get_top());
--write:

OP: BINPUT	// (   "     "    "   "   " ;   "    " 1-byte arg)
-- read:
$index = ord($stream->get_byte());
$memo->set($index, $stack->get_top());
if ($debug)
{
	echo "BINPUT: setting memo index($index) to ",var_dump($stack->get_top())," \r\n";
}
--write:

OP: LONG_BINPUT	// (   "     "    "   "   " ;   "    " 4-byte arg)
-- read:
$av = unpack("Lval", $stream->get_bytes(4));
$index = $av["val"];
$memo->set($index, $stack->get_top());
--write:

OP: SETITEM	// ( add key+value pair to dict)
-- read:
$value = $stack->pop();
$key = $stack->pop();
$dict = $stack->pop();
$dict[$key] = $value;
$stack->push($dict);
if ($debug)
{
	echo "SETITEM: adding key($key) => value($value) to dict ",var_dump($dict)," \r\n";
}
--write:

OP: TUPLE	// ( build tuple from topmost stack items)
-- read:
// find mark from stack, make numbered array from items until that
$vals = $stack->pop_until_mark();
$stack->push($vals);
--write:

OP: EMPTY_TUPLE	// ( push empty tuple)
-- read:
$stack->push(array());
--write:

OP: SETITEMS	// ( modify dict by adding topmost key+value pairs)
-- read:
$vals = $stack->pop_until_mark();
$d = $stack->pop();
$len = count($vals);
for ($i = 0; $i < $len; $i+=2)
{
	$d[$vals[$i]] = $vals[$i+1];
}
$stack->push($d);
--write:

OP: BINFLOAT	// ( push float; arg is 8-byte float encoding)
-- read:
$av = unpack("dval", $stream->get_bytes(8));
$stack->push($av["val"]);
--write:

OP: PROTO	// identify pickle protocol
-- read:
$stack->proto = ord($stream->get_byte());
if ($debug)
{
	echo "read protocol version as ".$stack->proto." \r\n";
}
--write:

OP: NEWOBJ	// build object by applying cls.__new__ to argtuple
-- read:
// TODO: not quite
$cl = new stdClass;
$cl->args = $stack->pop();
$cl->class = $stack->pop();
$stack->push($cl);
--write:

OP: EXT1	// push object from extension registry; 1-byte index
-- read:
// TODO: not quite
$code = $stream->get_byte();
$stack->push(new stdClass);
--write:

OP: EXT2	// ditto, but 2-byte index
-- read:
// TODO: not quite
$code = $stream->get_bytes(2);
$stack->push(new stdClass);
--write:

OP: EXT4	// ditto, but 4-byte index
-- read:
// TODO: not quite
$code = $stream->get_bytes(4);
$stack->push(new stdClass);
--write:

OP: TUPLE1	// build 1-tuple from stack top
-- read:
if ($debug)
{
	echo "TUPLE1: making tuple: array(".$stack->get_top().") \r\n";
}
$stack->push(array($stack->pop()));
--write:

OP: TUPLE2	// build 2-tuple from two topmost stack items
-- read:
$stack->push(array($stack->pop(), $stack->pop()));
--write:

OP: TUPLE3	// build 3-tuple from three topmost stack items
-- read:
$stack->push(array($stack->pop(), $stack->pop(), $stack->pop()));
--write:

OP: NEWTRUE	// push True
-- read:
$stack->push(true);
--write:

OP: NEWFALSE	// push False
-- read:
$stack->push(false);
--write:

OP: LONG1	// push long from < 256 bytes
-- read:
// TODO: not exact
$len = ord($stream->get_char());
$data = $stream->get_bytes($len);
// push as string, because we can't handle long numbers
$str = "";
for($i = 0; $i < $len; $i++)
{
	$str .= chr($data[$i]);
}
$stack->push($str);
--write:

OP: LONG4	// push really big long
-- read:
$av = unpack("Lval", $stream->get_bytes(4));
$len = $av["val"];
$data = $stream->get_bytes($len);
// push as string, because we can't handle long numbers
$str = "";
for($i = 0; $i < $len; $i++)
{
	$str .= chr($data[$i]);
}
$stack->push($str);
--write:


// Protocol 3 (Python 3.x)

OP: BINBYTES	// ( push bytes; counted binary string argument)
-- read:
$av = unpack("Lval", $stream->get_bytes(4));
$len = $av["val"];
$stack->push($stream->get_bytes($len));
--write:

OP: SHORT_BINBYTES	// (  "     "   ;    "      "       "      " < 256 bytes)
-- read:
$len = ord($stream->get_char());
$stack->push($stream->get_bytes($len));
--write:
