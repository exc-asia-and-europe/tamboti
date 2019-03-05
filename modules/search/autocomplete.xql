xquery version "3.1";

import module namespace biblio="http://exist-db.org/xquery/biblio" at "application.xql";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace svg = "http://www.w3.org/2000/svg";

declare option exist:serialize "media-type=text/json";

declare function local:key($key, $options) {
    concat('"', $key, '"')
};

let $collection := xmldb:encode-uri(request:get-parameter("collection", $config:content-root))
let $term := request:get-parameter("term", "wang")
let $field := request:get-parameter("field", "any Field (MODS, TEI, VRA, Wiki)")
let $qnames :=
    for $target in $biblio:FIELDS/field[@name eq $field]//target
    
    return xs:QName($target/string())
let $callback := util:function(xs:QName("local:key"), 2)
let $autocompletes := 
    if (contains($term, (' ', '*', '?', '-'))) 
    then () 
    else string-join(collection($collection)/util:index-keys-by-qname($qnames, $term, $callback, 20, "lucene-index"),', ')
    
    
return concat("[", $autocompletes, "]")
    