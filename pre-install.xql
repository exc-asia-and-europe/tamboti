xquery version "3.1";

(:
    TODO KISS - This file should be removed in favour of a convention based approach + some small metadata for users/groups/permissions (added by AR)
:)

import module namespace security = "http://exist-db.org/mods/security" at "modules/search/security.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "modules/config.xqm";
import module namespace installation = "http://hra.uni-heidelberg.de/ns/tamboti/installation/" at "modules/installation/installation.xqm";

declare variable $home external;
declare variable $dir external;
declare variable $target external;

declare variable $log-level := "INFO";
declare variable $db-root := "/db";
declare variable $config-collection := "/system/config/db";

(:~ Collection names :)
declare variable $temp-collection-name := "temp";
declare variable $samples-collection-name := "Samples";

(:~ Collection paths :)
declare variable $temp-collection := $config:content-root || $temp-collection-name;

declare function local:strip-prefix($str as xs:string, $prefix as xs:string) as xs:string? {
    replace($str, $prefix, "")
};


util:log($log-level, "Script: Running pre-install script ..."),
util:log($log-level, concat("...Script: using $home '", $home, "'")),
util:log($log-level, concat("...Script: using $dir '", $dir, "'")),

(: create $config:data-collection-name collection :)
if (not(xmldb:collection-available($config:content-root)))
then
    (
        xmldb:create-collection("/db", $config:data-collection-name)
        ,
        security:set-resource-permissions(xs:anyURI($config:content-root), "admin", "dba", $config:public-collection-mode)
    )
else ()
,
(: Create users and groups :)
util:log($log-level, concat("Security: Creating user '", $config:biblio-admin-user, "' and group '", $config:biblio-users-group, "' ..."))
,
if (xmldb:group-exists($config:biblio-users-group))
then ()
else xmldb:create-group($config:biblio-users-group)
,
if (xmldb:exists-user($config:biblio-admin-user))
then ()
else xmldb:create-user($config:biblio-admin-user, $config:biblio-admin-user, $config:biblio-users-group, ())
,
sm:passwd("guest", "guest")
,
util:log($log-level, "Security: Done.")
,

(: Load collection.xconf documents:)
util:log($log-level, "Config: Loading collection configuration ...")
,
installation:mkcol($config-collection, $config:content-root, $config:public-collection-mode)
,
if (doc-available($config-collection || $config:content-root || "collection.xconf"))
then ()
else xmldb:store-files-from-pattern($config-collection || $config:content-root, $dir, "data/xconf/data/*.xconf")
,
(: installation:mkcol($config-collection, $mads-collection),:)
(:xmldb:store-files-from-pattern(concat($config-collection, $mads-collection), $dir, "data/xconf/mads/*.xconf"),:) 
util:log($log-level, "Config: Done.=========================================================")
,

(: Create temp collection :)
util:log($log-level, concat("Config: Creating temp collection '", $temp-collection, "'..."))
,
installation:mkcol($db-root, local:strip-prefix($temp-collection, concat($db-root, "/")), $config:temp-collection-mode)
,
util:log($log-level, "Config: Done.")
,

(: Create "commons" collections :)
util:log($log-level, concat("Config: Creating commons collection '", $config:mods-commons, "'..."))
,
(: Create samples collection :)
installation:mkcol($db-root, xs:anyURI($config:mods-commons || "/Samples"), $config:public-collection-mode)
,
installation:mkcol($db-root, local:strip-prefix($config:mods-commons, concat($db-root, "/")), $config:public-collection-mode)
,

(: Create users collection :)
util:log($log-level, concat("Config: Creating users '", $config:users-collection, "' collections"))
,
installation:mkcol($db-root, local:strip-prefix($config:users-collection, concat($db-root, "/")), $config:public-collection-mode)
,
(: make admin:dba as owner of $config:users-collection :)
sm:chown($config:users-collection, 'admin')
,
sm:chgrp($config:users-collection, $config:biblio-users-group)
,
util:log($log-level, "Config: Done.")

