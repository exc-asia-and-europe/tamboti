xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

let $cluster-publications-collection-name := "Cluster Publications"    
let $cluster-publications-db-path := xmldb:encode-uri($config:mods-commons || "/" || $cluster-publications-collection-name || "/")
let $credentials := "editor:" || $config:dba-credentials[2]

let $http-headers :=
    <headers>
        <header name="Authorization" value="Basic {util:string-to-binary($credentials)}"/>
        <header name="X-target-collection" value="{$cluster-publications-db-path}"/>
        <header name="X-resource-name" value="headers.xml"/>
    </headers>
    
let $api-url := xs:anyURI("http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/api/resources")
let $resources := httpclient:put($api-url, $http-headers, false(), $http-headers)


return $resources