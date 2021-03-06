xquery version "3.1";

(:~
    Returns the list of distinct title words, names, dates, and subjects occurring in the result set.
    The query is called via AJAX when the user expands one of the headings in the
    "filter" box.
    The title words are derived from the Lucene index. The names rely on names:format-name() and are therefore expensive.
:)
import module namespace names="http://exist-db.org/xquery/biblio/names" at "names.xql";
import module namespace mods-common="http://exist-db.org/mods/common" at "../mods-common.xql";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace json="http://www.json.org";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";

declare variable $local:MAX_RECORD_COUNT := 13000;
declare variable $local:MAX_RESULTS_TITLES := 1500;
declare variable $local:MAX_TITLE_WORDS := 1000;
declare variable $local:MAX_RESULTS_DATES := 1300;
declare variable $local:MAX_RESULTS_NAMES := 1500;
declare variable $local:MAX_RESULTS_SUBJECTS := 750;
declare variable $local:SEARCH-COLLECTION := session:get-attribute('query');

declare function local:key($key, $options) {
    let $advanced-search-data :=
        <data>
            <filter>Title</filter>
            <value>{$key}</value>
            <default-operator>and</default-operator>
            <collection>{$local:SEARCH-COLLECTION//collection/string()}</collection>
        </data>
        
    return
        <li><a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">{$key} ({$options[1]})</a></li>
};

declare function local:keywords($results as element()*, $record-count as xs:integer) {
    let $max-terms := 
        if ($record-count ge $local:MAX_RESULTS_TITLES) 
        then $local:MAX_TITLE_WORDS 
        else ()
    let $prefixParam := request:get-parameter("prefix", "")
    let $prefix := if (empty($max-terms)) then "" else $prefixParam
    let $callback := util:function(xs:QName("local:key"), 2)
return
    (: NB: Is there any way to get the number of title words? :)
    if ($record-count gt $local:MAX_RECORD_COUNT) 
    then
        <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
    else
        <ul class="{if (empty($max-terms)) then 'complete' else $max-terms}">
        { util:index-keys($results//(mods:titleInfo | vra:titleSet), $prefix, $callback, $max-terms, "lucene-index") }
        </ul>
};

let $type := request:get-parameter("type", ())
let $record-count := count(session:get-attribute("tamboti:cache"))
(: There is a load problem with setting this variable to the cache each time a facet button is clicked. 
10,000 records amount to about 20 MB and several people could easily access this function at the same time. 
Even if the cache contains too many items and we do not allow it to be processed, it still takes up memory. 
The size has been set to 13,000, to accommodate the largest collection. 
If the result set is larger than that, a message is shown. :)
let $cached := 
    if ($record-count lt $local:MAX_RECORD_COUNT) 
    then ()
    else session:get-attribute("tamboti:cache")
return
    if ($type eq 'name') 
    then
        <ul>
        {
            let $names := $cached//(mods:name | vra:agentSet)
            let $names-count := count(distinct-values($names))
            return
                if ($names-count gt $local:MAX_RESULTS_NAMES) 
                then
                    <li>There are too many names ({$names-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_NAMES}.</li>
                else
                    if ($record-count gt $local:MAX_RECORD_COUNT)
                    then
                        <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                    else
                        let $authors :=
                            for $author in $names
                            return 
                                names:format-name($author)
                                    let $distinct := distinct-values($authors)
                                    for $name in $distinct
                                    let $advanced-search-data :=
                                        <data>
                                            <filter>Name</filter>
                                            <value>{$name}</value>
                                            <default-operator>and</default-operator>
                                            <collection>{$local:SEARCH-COLLECTION//collection/string()}</collection>
                                        </data>                                    
                                    order by upper-case($name) empty greatest
                                    return
                                        <li><a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">{$name}</a></li>
            }
            </ul>
    else
        if ($type eq 'date') 
        then
            <ul>
            {
                let $dates :=
                    distinct-values(
                    (
                        $cached/mods:originInfo/mods:dateIssued,
                        $cached/mods:originInfo/mods:dateCreated,
                        $cached/mods:originInfo/mods:copyrightDate,
                        $cached/mods:relatedItem/mods:originInfo/mods:copyrightDate,
                        $cached/mods:relatedItem/mods:originInfo/mods:dateIssued,
                        $cached/mods:relatedItem/mods:part/mods:date
                    )
                    )
                let $dates-count := count($dates)
                return
                    if ($dates-count gt $local:MAX_RESULTS_DATES) 
                    then
                        <li>There are too many dates ({$dates-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_DATES}.</li>
                    else
                        if ($record-count gt $local:MAX_RECORD_COUNT) 
                        then
                            <li>There are too many records ({$record-count})to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                        else
                            for $date in $dates
                            let $advanced-search-data :=
                                <data>
                                    <filter>Date</filter>
                                    <value>{$date}</value>
                                    <default-operator>and</default-operator>
                                    <collection>{$local:SEARCH-COLLECTION//collection/string()}</collection>
                                </data>                            
                            order by $date descending
                            return
                                <li><a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">{$date}</a></li>
             }
             </ul>
        else
            if ($type eq 'subject') 
            then
                <ul>
                {
                    let $all-subjects := $cached/(mods:subject | vra:work/vra:subjectSet/vra:subject/vra:term)
                    let $subjects := distinct-values($all-subjects)
                    let $subjects-map :=
                        map:new(
                            for $subject in distinct-values($all-subjects) return map:entry($subject, count(index-of($all-subjects, $subject))), "?strength=primary"
                            
                        )
                    let $subjects-count := count($subjects)
                    return
                        if ($subjects-count gt $local:MAX_RESULTS_SUBJECTS)
                        then
                            <li>There are too many subjects ({$subjects-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_SUBJECTS}.</li>
                        else
                            if ($record-count gt $local:MAX_RECORD_COUNT)
                            then
                                <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                            else
                                (:No distinction is made between different kinds of subjects - topics, temporal, geographic, etc.:)
                                for $subject in $subjects
                                let $advanced-search-data :=
                                    <data>
                                        <filter>Subject</filter>
                                        <value>{replace($subject, '-', '')}</value>
                                        <default-operator>and</default-operator>
                                        <collection>{$local:SEARCH-COLLECTION//collection/string()}</collection>
                                    </data>                                
                                order by upper-case($subject) ascending
                                return
                                    (:LCSH have '--', so they have to be replaced.:)
                                    <li><a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">{($subject, "[" || $subjects-map($subject) || "]")}</a></li>
                 }
                 </ul>
             else
                 if ($type eq 'language')
                 then 
                     <ul>
                     {
                        let $languages := distinct-values($cached/(mods:language/mods:languageTerm))
                        let $languages-count := count($languages)
                        return
                            if ($languages-count gt $local:MAX_RESULTS_SUBJECTS)
                            then
                                <li>There are too many languages ({$languages-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_SUBJECTS}.</li>
                            else
                                if ($record-count gt $local:MAX_RECORD_COUNT)
                                then
                                    <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                                else
                                    for $language in $languages
                                        let $label := mods-common:get-language-label($language)
                                        let $label := 
                                            if ($label eq $language) 
                                            then ()
                                            else
                                                if ($label)
                                                then concat(' (', $label, ')') 
                                                else ()
                                        let $advanced-search-data :=
                                            <data>
                                                <filter>Language</filter>
                                                <value>{replace($language, '-', '')}</value>
                                                <default-operator>and</default-operator>
                                                <collection>{$local:SEARCH-COLLECTION//collection/string()}</collection>
                                            </data>                                                
                                        order by upper-case($language) ascending
                                        return
                                            <li><a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">{$language}{$label}</a></li>
                     }
                     </ul>
                 else
                     if ($type eq 'genre')
                     then 
                         <ul>
                         {
                            let $genres := distinct-values($cached/(mods:genre))
                            let $genres-count := count($genres)
                            return
                                if ($genres-count gt $local:MAX_RESULTS_SUBJECTS)
                                then
                                    <li>There are too many genres ({$genres-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_SUBJECTS}.</li>
                                else
                                    if ($record-count gt $local:MAX_RECORD_COUNT)
                                    then
                                        <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                                    else
                                        for $genre in $genres
                                            let $label-1 := doc(concat($config:db-path-to-mods-editor-home, '/code-tables/genre-local.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $genre]/mods-editor:label
                                            let $label-2 := doc(concat($config:db-path-to-mods-editor-home, '/code-tables/genre-marcgt.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $genre]/mods-editor:label
                                            let $label := 
                                                if ($label-1)
                                                then $label-1
                                                else 
                                                    if ($label-2)
                                                    then $label-2
                                                    else $genre
                                            let $label := 
                                                if ($label eq $genre) 
                                                then ()
                                                else
                                                    if ($label)
                                                    then concat(' (', $label, ')') 
                                                    else ()
                                            let $advanced-search-data :=
                                                <data>
                                                    <filter>Genre</filter>
                                                    <value>{$genre}</value>
                                                    <default-operator>and</default-operator>
                                                    <collection>{$local:SEARCH-COLLECTION//collection/string()}</collection>
                                                </data>                                                    
                                            order by upper-case($genre) ascending
                                            return
                                                <li><a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">{$genre}{$label}</a></li>
                         }
                         </ul>
                 else
                     if ($type eq 'keywords')
                     then local:keywords($cached, $record-count)
                     else ()
