xquery version "3.1";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace apis = "http://hra.uni-heidelberg.de/ns/tamboti/apis/" at "../../modules/apis/apis.xqm";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace session="http://exist-db.org/xquery/session";

declare variable $exist:controller external;
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:root external;
declare variable $exist:prefix external;

declare variable $local:app-root := concat($exist:controller, "/../..");

declare function local:set-user() {
    session:create(),
    let $user :=
        if(request:get-parameter("user",()))then
            config:rewrite-username(request:get-parameter("user",()))
        else()
    let $password := request:get-parameter("password", ())
    let $session-user-credential := security:get-user-credential-from-session()
    return
        if ($user) then (
            security:store-user-credential-in-session($user, $password),
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$user}"/>,
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$password}"/>
        ) else if ($session-user-credential != '') then (
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$session-user-credential[1]}"/>,
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$session-user-credential[2]}"/>
        ) else (
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$security:GUEST_CREDENTIALS[1]}"/>,
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$security:GUEST_CREDENTIALS[2]}"/>
        )
};

if ($exist:path eq '/')
then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<redirect url="index.html"/>
	</dispatch>
    
(:  Main page: index.xml is a template, which is passed through
    search.xql and the db2xhtml stylesheet. search.xql will run
    the actual search and expand the index.xml template.
:)
else if (ends-with($exist:resource, '.html')) then

    if(request:get-parameter("logout",()))
    then
	    (
	        session:clear(),
	        session:invalidate(),
	        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
	            <redirect url="index.html"/>
	        </dispatch>
	    )
    else
	    (
	        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
	            <forward url="../../themes/tamboti/{$exist:resource}">
	                { local:set-user() }
	            </forward>
	            <view>
	                <forward url="../view.xql">
	                    <!-- Errors should be passed through instead of terminating the request -->
	                    { local:set-user() }
	            		<set-attribute name="xquery.report-errors" value="yes"/>
	            		<set-attribute name="exist:root" value="{$exist:root}"/>
	                    <set-attribute name="exist:path" value="{$exist:path}"/>
	                    <set-attribute name="exist:prefix" value="{$exist:prefix || "/" || $config:app-id}"/>
	                </forward>
	    		</view>
	    	</dispatch>,
	    	
	    	response:set-header("Last-Modified", fn:current-dateTime() cast as xs:string) (: TODO the XQueryURLRewrite filter should be able to infer that a static resource has been pre-procesed and this should be set:)
		)
else if ($exist:resource eq 'retrieve') then

    (:  Retrieve an item from the query results stored in the HTTP session. The
    	format of the URL will be /sandbox/results/X, where X is the number of the
    	item in the result set :)

	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
	   { local:set-user() }
		<forward url="/modules/session.xql">
		</forward>
	</dispatch>
	
else if ($exist:path eq '/search/') then apis:search($exist:prefix)

else if ($exist:path eq '/search/advanced/') then apis:search-advanced()

else if ($exist:path = "/history/") then apis:search-history()
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/apps/shared-resources/{substring-after($exist:path, '/$shared/')}" absolute="yes"/>
    </dispatch>

else if (starts-with($exist:path, "/images/")) then
        let $real-resources-path := substring-after($exist:path, "/images")
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="/images/scale/{$real-resources-path}" absolute="yes"/>
            </dispatch>
        
else if (starts-with($exist:path, "/resources")) then
    let $real-resources-path := fn:concat(substring-before($exist:controller, "/modules/"), $exist:path) return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$real-resources-path}">
            </forward>
        </dispatch>
        
else if (starts-with($exist:path, "/core")) then
    let $real-resources-path := fn:concat(substring-before($exist:controller, "/modules/"), $exist:path) return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$real-resources-path}">
            </forward>
        </dispatch>        

else if (starts-with($exist:path, "/db")) then
    let $resource := concat("/rest", $exist:path)
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$resource}" absolute="yes"/>
        </dispatch>
        
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        { local:set-user() }
        <cache-control cache="yes"/>
    </dispatch>
