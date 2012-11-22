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
    
   
// Complains about not being able to use external type (type[value]?)
public test bool testLoadDump(Node n) {
  yaml = dumpYAML(n);
  return n == loadYAML(n);
}