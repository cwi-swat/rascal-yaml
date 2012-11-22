@license{
  Copyright (c) 2009-2012 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Tijs van der Storm - Tijs.van.der.Storm@cwi.nl}
module lang::yaml::Model

import Type;
import IO;

/*
 * loosely Based on the Serialization Model of http://www.yaml.org/spec/1.2/spec.html
 */
 

// Tagging will be used to do typed 
// serialization for ADTs in the future.
 
// in valid YAML anchors always occur before any references
// this should also hold in our YAML data type 
// dumping will throw index out of bound exception.

data Node
  = sequence(list[Node] \list)
  | scalar(value \value)
  | reference(int anchor)
  | mapping(map[Node, Node] \map)
  ;
  
// Anchors are only currently valid on seq/map nodes.
// and should be unique.
anno int Node@anchor;
anno type[value] Node@\tag;

@javaClass{lang.yaml.RascalYAML}
@reflect{Uses type reifier}
public java Node loadYAML(str src);

@javaClass{lang.yaml.RascalYAML}
@reflect{Uses type reifier (TODO)}
public java str dumpYAML(Node yaml);

public str TEST_YAML = 
"default: &DEFAULT
  URL:          stooges.com
  throw_pies?:  true  
  stooges:  &stooge_list
    larry:  first_stooge
    moe:    second_stooge
    nuther:  *stooge_list
    curly:  third_stooge
    cycle:  *DEFAULT";
    
   
public Node BAD_YAML =
  mapping((
   scalar(3)[@anchor=3]:
   sequence([
      scalar("abc")[@\tag=#int],
      scalar("cde")[@\tag=#str],
      reference(4),
      sequence([])[@anchor=4]
   ])[@anchor=2]))[@anchor=2];
   
// Complains about not being able to use external type (type[value]?)
public test bool testLoadDump(Node n) {
  yaml = dumpYAML(n);
  return n == loadYAML(n);
}


public set[str] checkYAML(Node n) 
  = { "Scalar/reference <x> cannot be anchored" | x <- badAnchors(n) }
  + { "Duplicate anchor <i>" | i <- duplicateAnchors(n) }
  + { "Forward reference <x>" | x <- undefinedRefs(n, {}, {})[1] }
  + { "Untagged scalar <x>" | x <- untaggedScalars(n) }
  + { "Wrongly typed scalar <x>" | x <- wronglyTypedScalars(n) };

public set[Node] badAnchors(Node n)
  = { s | /s:scalar(_) <- n, (s@anchor)? }
  + { r | /r:reference(_) <- n, (r@anchor)? };


public set[Node] wronglyTypedScalars(Node n)
  = { s | /s:scalar(value v) <- n, s@\tag?, type[&T] t := s@\tag, !okValue(t, v) };

// Doesn't work: always succeeds.
public bool okValue(type[&T <: value] t, value v) = (&T _ := v);

public set[Node] untaggedScalars(Node n) 
  = { s | /s:scalar(_) <- n, !(s@\tag?) }
  ;

public set[int] duplicateAnchors(Node n) {
  seen = {};
  duplicate = {};

  void record(Node s) {
   if (!(s@anchor?)) return;
   if (s@anchor in seen) 
     duplicate += {s@anchor};
   else 
     seen += {s@anchor};
  }
  
  visit (n) {
    case s:sequence(_): record(s);
    case m:mapping(_): record(m);
  }
  return duplicate;
}


public tuple[set[int], set[int]] undefinedRefs(reference(i), set[int] seen, set[int] dupl) 
  = <seen, dupl + {i}>
  when i notin seen;
  
public tuple[set[int], set[int]] undefinedRefs(s:sequence(ns), set[int] seen, set[int] dupl) {
  undefs = {};
  if (s@anchor?) {
    seen += {s@anchor};
  }
  for (n <- ns) 
    <seen, dupl> = undefinedRefs(n, seen, dupl);
  return <seen, dupl>;
}

public tuple[set[int], set[int]] undefinedRefs(nod:mapping(m), set[int] seen, set[int] dupl) {
  undefs = {};
  if (nod@anchor?) {
    seen += {nod@anchor};
  }
  for (Node n <- m) {
    <seen, dupl> = undefinedRefs(n, seen, dupl);
    <seen, dupl> = undefinedRefs(m[n], seen, dupl);
  }
  return <seen, dupl>;
}

public default tuple[set[int], set[int]] undefinedRefs(Node n, set[int] seen, set[int] dupl) 
  = <seen, dupl>;








