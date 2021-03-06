xquery version "3.1";

module namespace vra-common="http://exist-db.org/vra/common";

import module namespace config="http://exist-db.org/mods/config" at "config.xqm";
import module namespace functx = "http://www.functx.com";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace mods-common="http://exist-db.org/mods/common";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace mads="http://www.loc.gov/mads/v2";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace ext="http://exist-db.org/mods/extension";

declare variable $vra-common:given-name-first-languages := ('eng', 'fre', 'ger', 'ita', 'por', 'spa');
declare variable $vra-common:no-word-space-languages := ('chi', 'jpn', 'kor');

