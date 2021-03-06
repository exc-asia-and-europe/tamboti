xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";

<div xmlns="http://www.w3.org/1999/xhtml">
    <h4>Search syntax</h4>
    <p> Tamboti performs a search with the exact term you enter. A search for "Chin" does not
        retrieve all words beginning with "Chin" ("China", "Chinese" …), but only the word "Chin"
        itself.</p>
    <p> You can use <em>wildcards</em> to perform broader searches. "?" can be used as a wildcard
        for a single character and "*" for zero, one or more characters: "China" is thus found with
        "Ch?na" and "C*a", and "China" and "Chine" are found with "Chin?", just as "China", "Chine"
        and "Chinese" are all found with "Chin*". Note that "*" and "?" cannot occur in the
        beginning of a word.</p>
    <p>
        <em>Fuzzy searches</em> can be performed by putting "~" at the end of a word. To find
        "Chine", enter "China~". You can quantify the fuzziness, by appending a number between 0.0
        and 1.0, "complete fuzziness" (finding everything) being 0.0 and complete identity being
        "1.0". If you append a "~" with no number, the default value 0.5 is applied.</p>
    <p>
        <em>Phrases</em> can be searched for by putting them in quotation marks. Use "straight"
        double quotation marks only.</p>
    <p> Tamboti searches for the exact word order you enter. If you enter "Reform and Progress", you
        will only find records in which the three words occur in that exact sequence. Tamboti does
        not display records containing, for example, "Progress and Reform".</p>
    <p> Note that Chinese, Japanese and Korean characters are indexed as separate words, so a search
        for "日本" (without quotation marks) will find records with the two characters in the opposite
        order, that is, it will find records with "本日" as well. However, if you enclose "日本" in
        quotation marks, you only retrieve records with the two characters in that specific
        sequence.</p>
    <p> You can use the <em>boolean operators</em> "AND" and "OR". If you search for "China AND
        Japan", you will find only records containing both terms. If you search for "China OR
        Japan", you will find records in which either one or both the two terms occur. A search with
        "AND" normally results in fewer records than a search with "OR". "NOT" can also be used. If
        you search for "China NOT Japan", you will only find records that have "China" but not
        "Japan". </p>
    <p> You can also make boolean searches using Advanced Search.</p>
    <p> You can use more advanced search functions by using parentheses: "(China OR Japan) NOT
        Korea" will find records in which the words "China" or "Japan" occur, but only those in
        which "Korea" does not occur.</p>
    <p> "AND", "OR" and "NOT" must be written with uppercase letters. Otherwise, searches are made
        using lower-case letters only, so writing "China" with initial lower-case "C" (as "china")
        has the exact same effect as using an initial upper-case "C". This means that there is no
        way you can search for e.g. "Bush" without finding "bush" as well. </p>
    <p>Search results can be sorted according to different criteria. <ul>
            <li>Score: A score is calculated according to how many times the search terms occur and
                how many times search terms occur together. By default, the hits with the highest
                score (the most relevant hits) are presented first. When there is no search term,
                that is, when all the contents of a folder are listed, the notion of score does not
                make sense, so even though Score is selected, the results are sorted according to
                Title.</li>
            <li>Author: The hits are ordered according to the last and first names of the first
                person who has a role of author or creator of the resource. The order is by default
                ascending. Records with no name that fit an author role occur last. This way of
                sorting is fairly time-consuming.</li>
            <li>Title: Hits are ordered, by default ascending, according to their title. Since
                nearly all records have a title, this is a fairly dependable sort option. </li>
            <li>Year: Hits are ordered, by default ascending, according to their year of
                publication. Since many records do not employ the required date format (2013 or
                2013-12-31), this way of sorting is often not dependable.</li>
        </ul>
    </p>
</div>
